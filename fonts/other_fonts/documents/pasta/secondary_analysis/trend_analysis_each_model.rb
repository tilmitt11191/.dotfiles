#!/usr/bin/env ruby

STDOUT.sync = true

require 'time'
require 'csv'

require_relative 'smart_device_spec.rb'
include SmartDeviceSpec

require 'optparse'
opt = OptionParser.new
options = {}
options['version']                       = '$Id$'
opt.banner = "Usage: #{File.basename($0)} input_http_csv_file"
opt.on( '--version', 'show version' ) { puts options['version']; exit }
opt.permute!( ARGV )

if ARGV.size == 1
  options['input_http_csv_file'] = ARGV[0]
else
  print opt.help
  exit
end

# presearch relationship between ip address and os/model
ipaddr_model = {}
CSV.open( options['input_http_csv_file'], 'r', {:headers => :first_row, :encoding => Encoding::ASCII_8BIT} ).each do |l|
  values = l.to_hash
  if /HTL22/i =~ values['request_user_agent']
    ipaddr_model[ values['src_ipaddr'] ] = 'htl22'
  elsif /LGL21/i =~ values['request_user_agent']
    ipaddr_model[ values['src_ipaddr'] ] = 'lgl21'
  elsif get_smart_device_spec( values['request_user_agent'] )[:os] == 'android'
    ipaddr_model[ values['src_ipaddr'] ] = 'android' unless ['htl22', 'lgl21'].include? ipaddr_model[ values['src_ipaddr'] ]
  elsif get_smart_device_spec( values['request_user_agent'] )[:os] == 'ios'
    ipaddr_model[ values['src_ipaddr'] ] = 'ios' unless ['htl22', 'lgl21'].include? ipaddr_model[ values['src_ipaddr'] ]
  else
    ipaddr_model[ values['src_ipaddr'] ] ||= 'other'
  end
end
CSV.open( "#{File.basename(options['input_http_csv_file'], '.*')}_ipaddr_model.csv", 'w' ) do |outfile|
  outfile << ['ipaddr', 'model']
  ipaddr_model.each{|ipaddr, model| outfile << [ipaddr, model]}
end

# read fingerpirnt dictionary
DEFAULT_TTL = [60, 64, 128, 255].sort
fingerprint_dictionary = {}
CSV.open( 'onehour20131008gtp_tcp_20131012-195959_dictionary.csv', 'r' ).each do |l|
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
fingerprint_dictionary.each_key do |k|
  # choose the most popular user-agent as representative
  fingerprint_dictionary[k] = fingerprint_dictionary[k].to_a.max_by{|x| x[1].to_i}.first
end

# make stats
size_content_type = {}
size_fingerprint = {}
CSV.open( options['input_http_csv_file'], 'r', {:headers => :first_row, :encoding => Encoding::ASCII_8BIT} ).each do |l|
  values = l.to_hash
  model = ipaddr_model[ values['src_ipaddr'] ]
  content_type = values['response_content_type'].to_s.gsub(/\/.*/, '')
  fingerprint = [values['syn_window_size'], DEFAULT_TTL.find(){|x| values['syn_ttl'].to_i < x}, values['syn_fragment'],
                 values['syn_total_length'], values['syn_options'], values['syn_quirks']].join(',')
  fingerprint_os = fingerprint_dictionary[ fingerprint ]

  size_content_type[ model ] ||= Hash.new( 0 )
  size_content_type[ model ][ content_type ] += values['response_actual_size'].to_i + values['tcp_download_unexpected'].to_i

  size_fingerprint[ model ] ||= Hash.new( 0 )
  size_fingerprint[ model ][ fingerprint_os ] += values['response_actual_size'].to_i + values['tcp_download_unexpected'].to_i
end

CSV.open( "#{File.basename(options['input_http_csv_file'], '.*')}_size_content_type.csv", 'w' ) do |outfile|
  content_types = size_content_type.values.map{|v| v.keys}.flatten.uniq
  outfile << [nil] + content_types
  size_content_type.each do |model, stats|
    outfile << [model] + content_types.map{|m| stats[m].to_i}
  end
end

CSV.open( "#{File.basename(options['input_http_csv_file'], '.*')}_size_fingerprint.csv", 'w' ) do |outfile|
  fingerprint_oss = size_fingerprint.values.map{|v| v.keys}.flatten.uniq
  outfile << [nil] + fingerprint_oss
  size_fingerprint.each do |model, stats|
    outfile << [model] + fingerprint_oss.map{|m| stats[m].to_i}
  end
end
