#!/usr/bin/env ruby

STDOUT.sync = true

require 'time'
require 'uri'
require 'csv'

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

video_sessions = {}
VIDEO_SESSIONS_DEFAULT = {
  'response_begin'          => Time.at(999_999_999_999),
  'response_end'            => Time.at(0),
  'response_actual_size'    => 0,
  'tcp_download_unexpected' => 0,
  'n_sessions'              => 0
}
VIDEO_REGEX = /^video\//
GET_REGEX = /^GET/
CONTENT_RANGE_REGEX = /^bytes\s+([0-9]+)\-([0-9]+)\/([0-9]+)/

REQUEST_PATH_SOURCE_REGEX = /(^|&)source=(.*?)(&|$)/
REQUEST_PATH_SIGNATURE_REGEX = /(^|&)signature=(.*?)(&|$)/
REQUEST_PATH_CPN_REGEX = /(^|&)cpn=(.*?)(&|$)/
REQUEST_PATH_UPN_REGEX = /(^|&)upn=(.*?)(&|$)/
CSV.open( options['input_http_csv_file'], 'r', {:headers => :first_row, :encoding => Encoding::ASCII_8BIT} ).each do |l|
  begin
    values = l.to_hash
    next unless VIDEO_REGEX =~ values['response_content_type']
    next unless GET_REGEX =~ values['request_method']
    next unless [200, 206].include? values['response_code'].to_i

    flg_youtube = false
    value_signature = nil
    value_cpn = nil
    value_upn = nil

    if REQUEST_PATH_SOURCE_REGEX =~ values['request_path']
       flg_youtube = true if $2 == "youtube"
    end
    if REQUEST_PATH_SIGNATURE_REGEX =~ values['request_path']
      value_signature = $2
    end
    if REQUEST_PATH_CPN_REGEX =~ values['request_path']
      value_cpn = $2
    end
    if REQUEST_PATH_UPN_REGEX =~ values['request_path']
      value_upn = $2
    end

    if CONTENT_RANGE_REGEX =~ values['response_content_range']
      values['first_byte_pos'], values['last_byte_pos'], values['instance_length'] = $1.to_i, $2.to_i, $3.to_i
      key = [values['src_ipaddr'], values['response_code'], values['instance_length']]
    elsif flg_youtube == true and !value_signature.nil? and !value_cpn.nil? and !value_upn.nil?
      key = [values['src_ipaddr'], values['response_code'], value_signature, value_cpn, value_upn]
    else
      key = [values['src_ipaddr'], values['response_code'], values['src_port']]
    end
    video_sessions[key] ||= VIDEO_SESSIONS_DEFAULT.dup
    video_sessions[key]['response_begin'] = [video_sessions[key]['response_begin'], Time.parse( values['response_begin'] )].min
    video_sessions[key]['response_end'] = [video_sessions[key]['response_end'], Time.parse( values['response_end'] )].max
    video_sessions[key]['src_ipaddr'] ||= values['src_ipaddr']
    video_sessions[key]['src_ipaddr_subnet_prefix'] ||= values['src_ipaddr_subnet_prefix']
    video_sessions[key]['response_code'] ||= values['response_code']
    video_sessions[key]['n_sessions'] += 1
    video_sessions[key]['response_actual_size'] += values['response_actual_size'].to_i
    video_sessions[key]['tcp_download_unexpected'] += values['tcp_download_unexpected'].to_i

    video_sessions[key]['include_container_header'] = 1 if !values['first_byte_pos'] or (values['first_byte_pos'] == 0 and values['last_byte_pos'] > 1)
    video_sessions[key]['request_host'] ||= values['request_host']
    video_sessions[key]['request_user_agent'] ||= values['request_user_agent']
    video_sessions[key]['response_content_type'] ||= values['response_content_type']
    video_sessions[key]['instance_length'] ||= (values['first_byte_pos'] ? values['instance_length'] : values['response_content_length'])
    video_sessions[key]['video_container'] ||= values['video_container']
    video_sessions[key]['video_major_brand'] ||= values['video_major_brand']
    video_sessions[key]['video_duration'] ||= values['video_duration']
    video_sessions[key]['video_type'] ||= values['video_type']
    video_sessions[key]['video_profile'] ||= values['video_profile']
    video_sessions[key]['video_bitrate'] ||= values['video_bitrate']
    video_sessions[key]['video_width'] ||= values['video_width']
    video_sessions[key]['video_height'] ||= values['video_height']
    video_sessions[key]['video_horizontal_resolution'] ||= values['video_horizontal_resolution']
    video_sessions[key]['video_vertical_resolution'] ||= values['video_vertical_resolution']
    video_sessions[key]['audio_type'] ||= values['audio_type']
    video_sessions[key]['audio_bitrate'] ||= values['audio_bitrate']
    video_sessions[key]['audio_channel_count'] ||= values['audio_channel_count']
    video_sessions[key]['audio_sample_size'] ||= values['audio_sample_size']
    video_sessions[key]['audio_sample_rate'] ||= values['audio_sample_rate']
  rescue => e
    warn l.inspect
    warn e.message
    e.backtrace.each{|b| warn b}
  end
end

order = ['response_begin', 'response_end', 'src_ipaddr', 'src_ipaddr_subnet_prefix', 'response_code', 
         'n_sessions', 'response_actual_size', 'tcp_download_unexpected', 'instance_length',
         'request_host', 'request_user_agent', 'response_content_type',
         'video_container', 'video_major_brand', 'video_duration', 'video_type', 'video_profile',
         'video_bitrate', 'video_width', 'video_height', 'video_horizontal_resolution', 'video_vertical_resolution',
         'audio_type', 'audio_bitrate', 'audio_channel_count', 'audio_sample_size', 'audio_sample_rate']
csv = CSV.open( options['input_http_csv_file'].gsub(/\.csv$/, '') + '_videomerged.csv', 'w' )
csv << order
video_sessions.each do |key, value|
  next unless value['include_container_header']
  csv << order.map{|m| value[m]}
end

csv = CSV.open( options['input_http_csv_file'].gsub(/\.csv$/, '') + '_videostats.csv', 'w' )
stats = {}
video_sessions.each do |key, value|
  next unless value['include_container_header']
  parsed_correctly = !value['video_type'].nil? and !value['video_width'].nil? and !value['video_height'].nil? and !value['audio_type'].nil?
  stats[[value['video_container'], parsed_correctly]] ||= Hash.new(0)
  stats[[value['video_container'], parsed_correctly]]['n_sessions'] += 1
  stats[[value['video_container'], parsed_correctly]]['response_actual_size'] += value['response_actual_size']
  stats[[value['video_container'], parsed_correctly]]['tcp_download_unexpected'] += value['tcp_download_unexpected']
end
csv << ['video_container', 'parsed_correctly', 'n_sessions', 'response_actual_size', 'tcp_download_unexpected']
stats.each do |key, value|
  csv << [key[0], key[1], value['n_sessions'], value['response_actual_size'], value['tcp_download_unexpected']]
end
