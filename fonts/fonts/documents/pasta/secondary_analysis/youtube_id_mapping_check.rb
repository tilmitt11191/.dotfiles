#!/usr/bin/env ruby-1.9.3

require 'csv'

require 'optparse'
opt = OptionParser.new
options = {}

options['version']                       = '$Id: youtube_xml_counter.rb $' 

opt.banner = "Usage: #{File.basename($0)} input_http_csv_file"
opt.on( '--version', 'show version' ) { puts options['version']; exit }
opt.permute!( ARGV )

if ARGV.size == 1
  options['input_http_csv_file'] = ARGV[0]
else
  print opt.help
  exit
end

num_success_youtube_id_mapping_create = 0
faild_youtube_id_mapping_create_info = []

CSV.open( options['input_http_csv_file'], 'r', {:headers => :first_row, :encoding => Encoding::ASCII_8BIT} ).each do |l|
  values = l.to_hash
  
  next unless /gdata.youtube/ =~ values['request_host']
  next if /\/comments\?|\/events|\/channels|\/playlists\?/ =~ values['request_path']
  if /application\/atom\+xml.*type=feed/i =~ values['response_content_type']
    if values['youtube_id_mapping']
      num_success_youtube_id_mapping_create += 1
    else
      faild_youtube_id_mapping_create_info << "#{values['tcp_hash']} | #{values['request_user_agent']} "
    end
  end
end

print "Count ALL #{num_success_youtube_id_mapping_create + faild_youtube_id_mapping_create_info.count} \n"
print "Count Success youtube_id_mapping  #{num_success_youtube_id_mapping_create} \n"
print "Count Faild youtube_id_mapping    #{faild_youtube_id_mapping_create_info.count} \n"
print "=== Faild TCP Hashes & User-Agent === \n"
print "TCP Hash                         |  User-Agent \n"
puts faild_youtube_id_mapping_create_info

