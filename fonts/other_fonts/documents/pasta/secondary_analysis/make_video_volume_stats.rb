#!/usr/bin/env ruby-1.9.3

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

stats = {}; stats.default = 0
prev_hash = nil
CSV.open( options['input_http_csv_file'], 'r', {:headers => :first_row, :encoding => Encoding::ASCII_8BIT} ).each do |l|
  begin
    values = l.to_hash
    next if prev_hash == values['tcp_hash']
    prev_hash = values['tcp_hash']

    stats['response_actual_size'] += values['response_actual_size'].to_i
    stats['tcp_download_unexpected'] += values['tcp_download_unexpected'].to_i
  rescue => e
    warn l.inspect
    warn e.message
    e.backtrace.each{|b| warn b}
  end
end

p stats
