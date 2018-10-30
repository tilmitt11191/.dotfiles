#!/usr/bin/env ruby

require 'csv'
require 'fileutils'
require 'optparse'
require "#{File.dirname(__FILE__)}/../def_linetable.rb"

opt = OptionParser.new

if ARGV[0] == "clean"
  FileUtils.rm(Dir.glob("#{File.dirname(__FILE__)}/GPS_*.csv"))
  exit
end

begin
  opt.on('-a', '--all', 'All Line and point.') {|v| $all_flg = v }
  opt.on('-y', '--yamanote', 'The point around YAMANOTE Line only.') {|v| $yamanote_flg = v }
  opt.on('-t', '--new_tokaido', 'The point around NEW TOKAIDO Line only.') {|v| $new_tokaido_flg = v }
  opt.parse!(ARGV)
  $all_flg = true if ($all_flg.nil? and $yamanote_flg.nil? and $new_tokaido_flg.nil?)
rescue => ex
  puts  "#{ex.message}"
  print opt.help; exit
end

if ARGV.empty?
  print opt.help
  exit
end

  loca_array = Array.new
  gps_keys = Array.new
  gps_latno = 0
  gps_srcip = 0
  str = ('a'..'z').to_a + ('0'..'9').to_a
  
  data_file = ARGV[0]
  OUTPUT_file = "#{File.dirname(__FILE__)}/GPS_#{Time.now.strftime("%Y%m%d_%H%M%S")}.csv"

  YAMANOTE_LINE.lines {|line| loca_array << line.chomp.strip} if ( $yamanote_flg == true or $all_flg == true )
  NEW_TOKAIDO_LINE.lines {|line| loca_array << line.chomp.strip} if ( $new_tokaido_flg == true or $all_flg == true )

  loca_num = loca_array.size
  
  CSV.foreach(data_file, {:encoding => Encoding::ASCII_8BIT}){ |tcp_data|
    if gps_keys.size == 0
      CSV.open(OUTPUT_file, "w"){|csv| csv << tcp_data }
      gps_keys = tcp_data
      break raise "!!! Not Found gps_latitude field !!!" if gps_keys.index('gps_latitude') == nil
      gps_latno = gps_keys.index('gps_latitude')
      gps_srcip = gps_keys.index('src_ipaddr')
      next
    end

    newIP = Array.new(32){str[rand(str.size)]}.join
    
    if tcp_data[gps_latno].nil?
      rand_num = rand(loca_num)
      redo if rand_num == 0

      if rand(0) > 0.5
        tcp_data[gps_latno + 1] = loca_array[rand_num].split(",")[0].to_f + rand/100
        tcp_data[gps_latno] = loca_array[rand_num].split(",")[1].to_f + rand/100
        tcp_data[gps_srcip.to_i] = newIP
      else
        tcp_data[gps_latno + 1] = loca_array[rand_num].split(",")[0].to_f - rand/100
        tcp_data[gps_latno] = loca_array[rand_num].split(",")[1].to_f - rand/100      
      end
    end

    CSV.open(OUTPUT_file, "a"){|csv| csv << tcp_data }
  }
