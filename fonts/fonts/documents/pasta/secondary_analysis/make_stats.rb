#!/usr/bin/env ruby

STDOUT.sync = true

require_relative 'smart_device_spec.rb'
include SmartDeviceSpec

DEFAULT_TTL = [60, 64, 128, 255].sort
MAX_ITEMS = 8

require 'time'
require 'uri'
require 'csv'

require 'optparse'
opt = OptionParser.new
options = {}

options['external_field_names']          = false
options['fingerprint_dictionary']        = false
options['version']                       = '$Id$'

opt.banner = "Usage: #{File.basename($0)} input_http_csv_file"
opt.on( '-f fp_file', '--fingerprint fp_file', String, 'specify fingerprint dictionary file. when fingerprint file is not given, preprocess to create fingerprint' ) {|v| options['fingerprint_dictionary'] = v }
opt.on( '--version', 'show version' ) { puts options['version']; exit }
opt.permute!( ARGV )

if ARGV.size == 1
  options['input_http_csv_file'] = ARGV[0]
else
  print opt.help
  exit
end

fingerprint_dictionary = {}
#### read fingerprint dictionary from an external file
if options['fingerprint_dictionary']
  CSV.open( options['fingerprint_dictionary'], 'r' ).each do |l|
    fingerprint_dictionary[l[0]] = {}
    i = 0
    while true
      if l[i * 2 + 1] and l[i * 2 + 2]
        fingerprint_dictionary[l[0]][l[i * 2 + 1]] = l[i * 2 + 2]
        i += 1
        next
      else
        break
      end
    end
  end
#### preprocess to create fingerprint
else
  other_os = {}
  other_os.default = 0

  CSV.open( options['input_http_csv_file'], 'r', {:headers => :first_row, :encoding => Encoding::ASCII_8BIT} ).each do |l|
    values = l.to_hash
    values['original_ttl'] = DEFAULT_TTL.find(){|x| values['syn_ttl'].to_i < x}
    fingerprint = [values['syn_window_size'], values['original_ttl'], values['syn_fragment'],
                   values['syn_total_length'], values['syn_options'], values['syn_quirks']].join(',')
    if values['request_user_agent']
      operating_system = search_os( values['request_user_agent'] ) || 'other'
      fingerprint_dictionary[fingerprint] ||= {}
      fingerprint_dictionary[fingerprint][operating_system] ||= 0
      fingerprint_dictionary[fingerprint][operating_system] += 1 
      other_os[values['request_user_agent']] += 1 if operating_system == 'other'
    end
  end
  CSV.open( File.basename(options['input_http_csv_file'], '.*') + '_dictionary.csv', 'w' ) do |w|
    fingerprint_dictionary.each do |f, o|
      w << [f] + o.to_a.sort_by{|x| -x[1]}.flatten
    end
  end
  CSV.open( File.basename(options['input_http_csv_file'], '.*') + '_other_os.csv', 'w' ) do |w|
    other_os.to_a.sort_by{|x| -x[1]}.each{|o| w << o}
  end
end
fingerprint_dictionary.each_key do |k|
  # choose the most popular user-agent as representative
  fingerprint_dictionary[k] = fingerprint_dictionary[k].to_a.max_by{|x| x[1].to_i}.first
end

#### main
def stats_format
  {
    'n_sessions' => 0,
    'n_users' => {},
    'size_upload' => 0,
    'size_download' => 0,
    'duration' => 0.0
  }
end
tcp_stats = {
  'dst_port' => {},
  'protocol' => {},
  'tcp_host_domain' => {},
  'tcp_operating_system' => {}
}
http_stats = {
  'response_content_type' => {},
  'request_user_agent' => {},
  'request_method' => {},
  'request_host_domain' => {},
  'request_version' => {},
  'response_code' => {},
  'response_server' => {},
  'response_version' => {},
  'operating_system' => {},
  'explicit_operating_system' => {},
  'protocol_operating_system' => {},
  'protocol_explicit_operating_system' => {}
}
quality_stats = {
  'rtt' => [],
  'throughput' => []
}

prev_tcp_hash = nil
CSV.open( options['input_http_csv_file'], 'r', {:headers => :first_row, :encoding => Encoding::ASCII_8BIT} ).each do |l|
  begin
    values = l.to_hash

    # tcp fields
    if [80, 8080].include? values['dst_port'].to_i
      values['protocol'] = 'http'
    elsif [443, 8443].include? values['dst_port'].to_i
      values['protocol'] = 'ssl'
    else
      values['protocol'] = 'tcp'
    end
    values['tcp_begin']                 = Time.parse( values['tcp_begin'] )
    values['tcp_begin_rounded']         = Time.local( 0, *values['tcp_begin'].to_a[1..-1] )
    values['tcp_end']                   = Time.parse( values['tcp_end'] )
    values['dst_port']                  = values['dst_port'].to_i > 1024 ? '>1024' : values['dst_port']
    values['tcp_upload_size']           = values['tcp_upload_size'].to_i + values['tcp_upload_unexpected'].to_i
    values['tcp_download_size']         = values['tcp_download_size'].to_i + values['tcp_download_unexpected'].to_i
    values['original_ttl']              = DEFAULT_TTL.find(){|x| values['syn_ttl'].to_i < x}
    values['fingerprint']               = [values['syn_window_size'], values['original_ttl'], values['syn_fragment'],
                                           values['syn_total_length'], values['syn_options'], values['syn_quirks']].join(',')

    # http fields
    if values['protocol'] == 'http' and values['request_begin']
      values['request_begin']             = Time.parse( values['request_begin'] )
      values['response_end']              = Time.parse( values['response_end'] )
      values['request_actual_size']       = values['request_actual_size'].to_i
      values['request_begin_rounded']     = Time.local( 0, *values['request_begin'].to_a[1..-1] )
      values['response_content_type']     = values['response_content_type'].to_s.downcase.gsub(/\/.*/, '')
      values['response_actual_size']      = values['response_actual_size'].to_i
      values['explicit_operating_system'] = search_os( values['request_user_agent'] ) || 'other'
      values['operating_system']          = values['explicit_operating_system'] == 'other' ? (fingerprint_dictionary[values['fingerprint']] || 'other') : values['explicit_operating_system']
      values['protocol_operating_system']          = values['protocol'] + '/' + values['operating_system']
      values['protocol_explicit_operating_system'] = values['protocol'] + '/' + values['explicit_operating_system']
      host = values['request_host'].to_s.strip.gsub(/:[0-9]*$/, '').split('.')
      if host.last == "jp" and ["ac", "ad", "co", "ed", "go", "gr", "lg", "ne", "or"].include? host[-2]
        values['request_host_domain'] = host[[host.length - 3, 0].max, 3].join('.')
      else
        values['request_host_domain'] = host[[host.length - 2, 0].max, 2].join('.')
      end
      http_stats.each do |k, v|
        v ||= {}
        v[values['request_begin_rounded']] ||= {}
        v[values['request_begin_rounded']][values[k]] ||= stats_format
        v[values['request_begin_rounded']][values[k]]['n_sessions'] += 1
        v[values['request_begin_rounded']][values[k]]['n_users'][values['src_ipaddr']] = true
        v[values['request_begin_rounded']][values[k]]['size_upload'] += values['request_actual_size']
        v[values['request_begin_rounded']][values[k]]['size_download'] += values['response_actual_size']
        v[values['request_begin_rounded']][values[k]]['duration'] +=
        values['response_end'] - values['request_begin'] + (values['response_end_usec'] ? (values['response_end_usec'].to_f/1_000_000 - values['request_begin_usec'].to_f/1_000_000) : 0.0)
      end
    end

    # tcp fields
    values['tcp_operating_system'] = values['operating_system'] || (fingerprint_dictionary[values['fingerprint']] || 'other')
    values['tcp_host_domain'] = values['request_host_domain']
    unless prev_tcp_hash == values['tcp_hash']
      tcp_stats.each do |k, v|
        v ||= {}
        v[values['tcp_begin_rounded']] ||= {}
        v[values['tcp_begin_rounded']][values[k]] ||= stats_format
        v[values['tcp_begin_rounded']][values[k]]['n_sessions'] += 1
        v[values['tcp_begin_rounded']][values[k]]['n_users'][values['src_ipaddr']] = true
        v[values['tcp_begin_rounded']][values[k]]['size_upload'] += values['tcp_upload_size']
        v[values['tcp_begin_rounded']][values[k]]['size_download'] += values['tcp_download_size']
        v[values['tcp_begin_rounded']][values[k]]['duration'] += 
        values['tcp_end'] - values['tcp_begin'] + (values['tcp_end_usec'] ? (values['tcp_end_usec'].to_f/1_000_000 - values['tcp_begin_usec'].to_f/1_000_000) : 0.0)
      end
      quality_stats['rtt'] << (values['client_rtt'].to_f + values['server_rtt'].to_f) / 1_000.0
      if ['srv_fin/clt_fin', 'clt_fin/srv_fin'].include? values['tcp_close_state'] and values['tcp_download_unexpected'].to_i == 0 and values['tcp_download_size'] > 100_000
        quality_stats['throughput'] << values['tcp_download_size'] * 8 / ( values['tcp_end'] - values['tcp_begin'] - 2 * (values['client_rtt'].to_f + values['server_rtt'].to_f) / 1_000_000 )
      end
    end
    prev_tcp_hash = values['tcp_hash']

  rescue => e
    warn l.inspect
    warn e.message
    e.backtrace.each{|b| warn b}
  end
end

[tcp_stats, http_stats].each do |stats|
  stats.each do |k, v|
    sum = {}; sum.default = 0
    v.each do |t, w|
      w.each do |c, s|
        sum[c] += s['size_download']
      end
    end
    columns = sum.to_a.sort_by{|a| -a[1]}.map{|m| m[0]}[0...(MAX_ITEMS - 1)]
    break if columns.empty?
    CSV.open( "#{File.basename(options['input_http_csv_file'], '.*')}_stats_#{k.to_s}.csv", 'w' ) do |writer|
      writer << [nil, 'n_sessions'] + [nil] * columns.size + 
      ['n_users'] + [nil] * columns.size + 
      ['size_upload'] + [nil] * columns.size + 
      ['size_download'] + [nil] * columns.size + 
      ['duration'] + [nil] * columns.size
      writer << [nil] + (columns + ['other']) * stats_format.size
      v.to_a.sort_by{|a| a[0]}.each do |t|
        writer << [t[0].strftime("%F %T")] + 
        columns.map{|c| t[1][c] ? t[1][c]['n_sessions']    : 0} + [t[1].to_a.inject(0){|s, i| columns.include?( i[0] ) ? s : s + i[1]['n_sessions']}] +
        columns.map{|c| t[1][c] ? t[1][c]['n_users'].size  : 0} + [t[1].to_a.inject(0){|s, i| columns.include?( i[0] ) ? s : s + i[1]['n_users'].size}] +
        columns.map{|c| t[1][c] ? t[1][c]['size_upload']   : 0} + [t[1].to_a.inject(0){|s, i| columns.include?( i[0] ) ? s : s + i[1]['size_upload']}] +
        columns.map{|c| t[1][c] ? t[1][c]['size_download'] : 0} + [t[1].to_a.inject(0){|s, i| columns.include?( i[0] ) ? s : s + i[1]['size_download']}] +
        columns.map{|c| t[1][c] ? t[1][c]['duration']      : 0} + [t[1].to_a.inject(0.0){|s, i| columns.include?( i[0] ) ? s : s + i[1]['duration']}]
      end
    end
  end
end
quality_stats.each do |k, v|
  CSV.open( "#{File.basename(options['input_http_csv_file'], '.*')}_stats_#{k.to_s}.csv", 'w' ) do |writer|
    v.each{|x| writer << [x]}
  end
end
