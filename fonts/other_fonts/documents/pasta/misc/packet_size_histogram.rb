#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

MAX_PACKET_LENGTH = 1_600

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

  def standard_devitation
    Math::sqrt( variance )
  end
end

class IPAddr
  MOBILE_IP_ADDR_RANGE = [
  IPAddr.new( '106.145.128.0/18' ),
  IPAddr.new( '106.145.128.0/24' ),
  IPAddr.new( '111.86.157.128/25' ),
  IPAddr.new( '119.107.125.0/24' ),
  IPAddr.new( '182.249.0.0/18' ),
  IPAddr.new( '182.249.64.0/20' ),
  IPAddr.new( '182.249.240.0/24' ),
  IPAddr.new( '182.249.248.0/22' ),
  IPAddr.new( '182.249.255.224/27' ),
  IPAddr.new( '182.249.80.0/20' ),
  IPAddr.new( '182.249.96.0/20' ),
  IPAddr.new( '182.249.112.0/21' ),
  IPAddr.new( '182.249.242.0/24' ),
  IPAddr.new( '182.250.160.0/19' ),
  IPAddr.new( '182.250.192.0/21' ),
  ]

  def is_mobile?
    MOBILE_IP_ADDR_RANGE.each do |range|
      return true if range.include? self
    end
    return false
  end
end

class String
  GW_MAC_ADDR = [
  '648788d51206',
  '648788d5104a',
  ]

  def is_northbound?
    GW_MAC_ADDR.include? self
  end
end


counter = Hash.new
options[:infiles].uniq.sort.each_with_index do |file, index|
  cap = Pcap::Capture.open_offline( file )
  cap.each do |pkt|
    next unless pkt.ip?
    network_type = (IPAddr.new( pkt.ip_src.to_s ).is_mobile? or IPAddr.new( pkt.ip_dst.to_s ).is_mobile?) ? :mobile : :fixed
    direction = pkt.raw_data[0, 6].unpack("CCCCCC").map{|c| "%02x"%[c] }.join('').is_northbound? ? :northbound : :southbound
    time_slot = sprintf( "%02d", pkt.time.hour ) + '00'
    length = [pkt.length, MAX_PACKET_LENGTH - 1].min
    counter[[network_type, direction, time_slot]] ||= Array.new( MAX_PACKET_LENGTH, 0 )
    counter[[network_type, direction, time_slot]][length] += 1
  end
end

counter.each do |k, v|
  network_type, direction, time_slot = k
  File.open( "#{network_type.to_s}_#{direction.to_s}_#{time_slot.to_s}.gnuplot", 'w' ) do |f|
    f.write "set terminal emf\n"
    f.write "set output '#{options[:outfile_prefix]}#{network_type.to_s}_#{direction.to_s}_#{time_slot.to_s}.emf'\n"
    f.write "set grid\n"
    f.write "unset key\n"
    f.write "set xrange [0:#{MAX_PACKET_LENGTH}]\n"
    f.write "set xlabel 'packet size [byte]'\n"
    f.write "set yrange [0.0:1.0]\n"
    f.write "set ylabel 'CDF'\n"
    f.write "set format y '%1.2f'\n"
    f.write "plot '-' title '#{options[:outfile_prefix]}#{network_type.to_s} #{direction.to_s} #{time_slot.to_s}' with line\n"
    n_packets_cumulative = 0
    n_packets_all = v.inject(0){|s, n| s += n}
    v.each_with_index do |n_packets, length|
      n_packets_cumulative += n_packets
      f.write "#{length} #{n_packets_cumulative.to_f / n_packets_all.to_f}\n"
    end
  end
  expanded = v.each_with_index.map{|v, i| [i] * v}.flatten
  File.open( "#{network_type.to_s}_#{direction.to_s}_#{time_slot.to_s}_average.txt", 'w' ) {|f| f.write "#{expanded.average}\n"}
  File.open( "#{network_type.to_s}_#{direction.to_s}_#{time_slot.to_s}_variance.txt", 'w' ){|f| f.write "#{expanded.variance}\n"}
  File.open( "#{network_type.to_s}_#{direction.to_s}_#{time_slot.to_s}_std.txt", 'w' )     {|f| f.write "#{expanded.standard_devitation}\n"}
  File.open( "#{network_type.to_s}_#{direction.to_s}_#{time_slot.to_s}_npackets.txt", 'w' ){|f| f.write "#{expanded.size}\n"}
end
