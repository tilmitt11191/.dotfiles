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


def extract_unique_video_id_from_watch( request_path )
  if /watch\?/ =~ request_path
    $'.split('&').each do |request_path_query|
      query_data = request_path_query.split('=')
      return query_data[1] if query_data[0] == 'v' or query_data[0] == 'video_id'
    end
    nil
  end
end

src_ipaddress_array = Array.new 0
unique_video_id_array = Array.new 0
num_request_referer_info_array = Array.new 0
number_of_all_referer = 0
number_of_facebook_referer = 0
number_of_twitter_referer = 0
number_of_youtube_referer = 0

CSV.open( options['input_http_csv_file'], 'r', {:headers => :first_row, :encoding => Encoding::ASCII_8BIT} ).each do |l|
  values = l.to_hash
  
  request_referer = values['request_referer']
  request_host = values['request_host']
  request_path = values['request_path']
  ipaddress = values['src_ipaddr']

  next unless request_host =~ /youtube/
  next unless unique_video_id = extract_unique_video_id_from_watch(request_path)
  next if /gdata.youtube/ =~ request_referer
  if src_ipaddress_array.include?(ipaddress) and unique_video_id_array.include?(unique_video_id)
    next
  elsif src_ipaddress_array.include?(ipaddress) == false and unique_video_id_array.include?(unique_video_id)
    src_ipaddress_array <<  ipaddress
  elsif unique_video_id_array.include?(unique_video_id) == false and src_ipaddress_array.include?(ipaddress)
    unique_video_id_array <<  unique_video_id
  else
    src_ipaddress_array <<  ipaddress
    unique_video_id_array <<  unique_video_id
  end

  number_of_all_referer += 1
  number_of_twitter_referer += 1 if /\/t.co\// =~ request_referer
  number_of_facebook_referer += 1 if /\/m.facebook.com/ =~ request_referer
  number_of_youtube_referer += 1 if /youtube/ =~ request_referer

  num_request_referer_info_array << "  src_ipaddress : #{ipaddress}\n  unique_video_id : #{unique_video_id}\n"
  num_request_referer_info_array << "  reuqest_referer : #{request_referer}\n  request_host : #{request_host}\n"
  num_request_referer_info_array << "  request_path : #{request_path}\n"
  num_request_referer_info_array << "==================================="
end

print "Check request_referer \n"
print "Count up ALL request_referer #{number_of_all_referer} \n"
print "Count up request_referer from Twitter : #{number_of_twitter_referer} \n"
print "Count up request_referer from Facebook : #{number_of_facebook_referer} \n"
print "Count up request_referer from YouTube : #{number_of_youtube_referer} \n"
print "Count up Other request_referer : #{number_of_all_referer - number_of_twitter_referer - number_of_facebook_referer - number_of_youtube_referer} \n"
print "=== Print request_referer info === \n"
if num_request_referer_info_array.count != 0
  puts num_request_referer_info_array 
else
   puts "No request_referer (except facebook, twitter)"
end

