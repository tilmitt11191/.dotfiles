#!/usr/bin/env ruby

STDOUT.sync = true

require 'time'
require 'uri'
require 'csv'

require 'optparse'
opt = OptionParser.new
options = {}

options['version']                       = '$Id$'

opt.banner = "Usage: #{File.basename($0)} input_http_csv_file output_http_csv_file"
opt.on( '--version', 'show version' ) { puts options['version']; exit }
opt.permute!( ARGV )

if ARGV.size == 2
  options['input_http_csv_file'], options['output_http_csv_file'] = ARGV[0], ARGV[1]
else
  print opt.help
  exit
end

user_agents = {}

CSV.open( options['input_http_csv_file'], 'r', {:headers => :first_row, :encoding => Encoding::ASCII_8BIT} ).each do |l|
  values = l.to_hash
  next unless [80, 8080].include? values['dst_port'].to_i
  user_agents[values['src_ipaddr']] ||= {}
  user_agents[values['src_ipaddr']][values['request_user_agent']] = true if values['request_user_agent']
end

fingerprints = {}; fingerprints.default = 0
user_agents.each_value{|uas| fingerprints[ uas.keys.sort ] += 1}

outfile = CSV.open( options['output_http_csv_file'], 'w' )
fingerprints.each{|fingerprint, n_users| outfile << [n_users, fingerprint.size, *fingerprint]}
