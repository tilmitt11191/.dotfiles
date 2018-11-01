#!/usr/bin/env ruby
STDOUT.sync = true

require 'csv'
require 'time'
require 'optparse'
require 'ipaddr'
opt = OptionParser.new
options = {}

options['version']                       = '$Id$'
opt.banner = "Usage: #{File.basename($0)} input_http_csv_file output_http_csv_file"
opt.on( '--version', 'show version' ) { puts options['version']; exit }
opt.permute!( ARGV )

if ARGV.size == 2
  options['input_http_csv_file'], options['output_tcp_csv_file'] = ARGV[0], ARGV[1]
else
  print opt.help
  exit
end

prev_tcp_hash = nil
n_sessions = 0
n_broken_sessions = 0
CSV.open( options['input_http_csv_file'], 'r', {:headers => :first_row, :encoding => Encoding::ASCII_8BIT} ).each do |l|
  values = l.to_hash
  if values['tcp_hash'] != prev_tcp_hash
    n_sessions += 1
    tcp_begin = Time.parse( values['tcp_begin'] )
    if values['tcp_download_unexpected_n_packets'].to_i > 0 and values['tcp_download_resent_n_packets'].to_i == 0 and values['tcp_download_n_packets'].to_i > 16
      n_broken_sessions += 1
    end
  end
  prev_tcp_hash = values['tcp_hash']
end
outfile = open( options['output_tcp_csv_file'], 'w' )
outfile.write("#{n_sessions},#{n_broken_sessions}")
