#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

MAX_PACKET_LENGTH = 1_600
SHORT_PACKET_THRESHOLD = 256

require 'pcap'
require 'ipaddr'

require 'optparse'
opt = OptionParser.new
options = {}
options[:outfile_prefix]                 = ''
opt.banner = "Usage: #{File.basename($0)} [options] pcapfiles"
opt.on( '-h'            , '--help'                                  , 'show help' ) { print opt.help; exit }
opt.on( '-l prefix'     , '--file-prefix-label prefix'     , String , 'specify file prefix' ) {|v| options[:outfile_prefix] = v + '_' }
opt.on(                   '--version'                               , 'show version' ) { puts options[:version]; exit }
opt.permute!( ARGV )
options[:infiles] = ARGV


class Array
  def average
    inject(0.0){|sum, i| sum += i } / size
  end

  def variance
    ave = average
    inject(0.0){|sum, i| sum += (i - ave) ** 2 } / size
  end

  def standard_deviation
    Math::sqrt( variance )
  end
end

packet_size_histogram = Array.new( MAX_PACKET_LENGTH, 0 )
short_packet_counter = Hash.new( 0 )
options[:infiles].uniq.sort.each_with_index do |file, index|
  cap = Pcap::Capture.open_offline( file )
  cap.each do |pkt|
    next unless pkt.udp? and [12222, 12223].include? pkt.udp_dport

    buf = pkt.udp_data[0].unpack('C')[0]
    c_bit = (buf & 0b00000100) >> 2
    f_bit = (buf & 0b00000010) >> 1
    l_bit = (buf & 0b00000001)

    length = [pkt.length, MAX_PACKET_LENGTH - 1].min
    packet_size_histogram[length] += 1

    if pkt.length <= SHORT_PACKET_THRESHOLD
      if c_bit == 1
        short_packet_counter[:control] += 1
      elsif f_bit == 1 and l_bit == 0
        short_packet_counter[:fragment] += 1
      else
        short_packet_counter[:other] += 1
      end
    end

  end
  cap.close
end

File.open( "#{options[:outfile_prefix]}histogram.gnuplot", 'w' ) do |f|
  f.write "set terminal emf\n"
  f.write "set output '#{options[:outfile_prefix]}histogram.emf'\n"
  f.write "set grid\n"
  f.write "unset key\n"
  f.write "set xrange [0:#{MAX_PACKET_LENGTH}]\n"
  f.write "set xlabel 'packet size [byte]'\n"
  f.write "set yrange [0.0:1.0]\n"
  f.write "set ylabel 'CDF'\n"
  f.write "set format y '%1.2f'\n"
  f.write "plot '-' title '#{options[:outfile_prefix]}packet_size_histogram' with line\n"
  n_packets_cumulative = 0
  n_packets_all = packet_size_histogram.inject( 0 ){|s, n| s += n}
  packet_size_histogram.each_with_index do |n_packets, length|
    n_packets_cumulative += n_packets
    f.write "#{length} #{n_packets_cumulative.to_f / n_packets_all.to_f}\n"
  end
end
expanded = packet_size_histogram.each_with_index.map{|v, i| [i] * v}.flatten
File.open( "#{options[:outfile_prefix]}average.txt", 'w' ) {|f| f.write "#{expanded.average}\n"}
File.open( "#{options[:outfile_prefix]}variance.txt", 'w' ){|f| f.write "#{expanded.variance}\n"}
File.open( "#{options[:outfile_prefix]}std.txt", 'w' )     {|f| f.write "#{expanded.standard_deviation}\n"}
File.open( "#{options[:outfile_prefix]}npackets.txt", 'w' ){|f| f.write "#{expanded.size}\n"}

short_packet_columns = [:control, :fragment, :other]
File.open( "#{options[:outfile_prefix]}short_packet.csv", 'w' ) do |f|
  f.write short_packet_columns.map{|c| c.to_s}.join(',') + "\n"
  f.write short_packet_columns.map{|c| short_packet_counter[c]}.join(',') + "\n"
end
