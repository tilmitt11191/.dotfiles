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

YOUTUBE_HOSTS = [
  /.*\.youtube\.com/,
  /.*ytimg\.com/
]
def is_youtube_host host
  YOUTUBE_HOSTS.each do |youtube_host|
    return true if youtube_host =~ host
  end
  return false
end

counter = 0
prev_tcp_hash = nil
CSV.open( options['input_http_csv_file'], 'r', {:headers => :first_row, :encoding => Encoding::ASCII_8BIT} ).each do |l|
  values = l.to_hash
  print "#{values['src_ipaddr']}\n" if is_youtube_host values['request_host']
  counter += 1
end
