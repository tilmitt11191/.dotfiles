#!/usr/bin/env ruby
# coding: ascii-8bit

require "#{File.dirname(__FILE__)}/../http_parser.rb"

exit if ARGV.size != 1

hp = HTTPParser.new
parsed = hp.parse_iso_base_media_file_format( File.open(ARGV[0], :encoding => Encoding::ASCII_8BIT).read )
parsed = hp.parse_flv_format( File.open(ARGV[0], :encoding => Encoding::ASCII_8BIT).read ) if parsed.empty?
parsed = hp.parse_mpeg2_file_format( File.open(ARGV[0], :encoding => Encoding::ASCII_8BIT).read ) if parsed.empty?
p parsed
