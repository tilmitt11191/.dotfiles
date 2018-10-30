#!/usr/bin/env ruby
# -*- encoding: UTF-8 -*-

require 'rexml/document'
require 'optparse'

MESH_LV = 3 # 3rd mesh
#MESH_LV = 8 # 1/8 mesh

opt = OptionParser.new
o = Hash.new

begin
  $yamanote_flg = $new_tokaido_flg = false
  opt.on('-l', '--locapo', 'create locapo hash: grid_square_code => [locapo]') {|v| $locapo_flg = v }
  opt.on('-m', '--mesh', 'create mesh table: [grid_square_code]') {|v| $mesh_flg = v }
  opt.parse!(ARGV)
  $locapo_flg = true if ($locapo_flg.nil? and $mesh_flg.nil?)
rescue => ex
  puts  "#{ex.message}"
  print opt.help; exit
end

if ARGV.empty?
  puts "!!!! kml file input plz. !!!!"
  print opt.help
  exit
end

@line_table = Array.new

doc = REXML::Document.new(open("#{ARGV[0]}"))
coordinates = doc.elements['kml/Document/Placemark/LineString/coordinates'].text

coordinates.lines{|line_coordinates|
  line_coordinates = line_coordinates.strip
  if line_coordinates.size > 1
    @line_table << line_coordinates.split(",")[0].strip.to_f
    @line_table << line_coordinates.split(",")[1].to_f
  end
}

def coordinate2_meshcode(lon, lat)
 
  lat = lat.to_f
  lon = lon.to_f
 
  # calc 1st grid square code
  lat15m = (lat * 1.5).floor
  mesh1 = lat15m * 100 + lon.floor - 100

  # calc 2nd grid square code
  latR = lat - lat15m / 1.5; lonR = lon - lon.floor
  lat2 = (latR / 5.0 * 60).floor; lon2 = (lonR / 7.5 * 60).floor
  mesh2 = lat2 * 10 + lon2

  # calc 3rd grid square code
  latR -= lat2 * 5.0 / 60; lonR -= lon2 * 7.5 / 60
  lat3 = (latR / 0.5 * 60).floor; lon3 = (lonR / 0.75 * 60).floor
  mesh3 = lat3 * 10 + lon3

  # calc 4th grid square code
  latR -= lat3 * 0.5 / 60; lonR -= lon3 * 0.75 / 60
  lat4 = (latR / (0.5/2) * 60).floor; lon4 = (lonR / (0.75/2) * 60).floor
  mesh4 = (lat4 * 2 + lon4 + 1).floor

  # calc 5th grid square code
  latR -= lat4 * (0.5/2) / 60; lonR -= lon4 * (0.75/2) / 60
  lat5 = (latR / (0.5/4) * 60).floor; lon5 = (lonR /(0.75/4) * 60).floor
  mesh5 = lat5 * 2 + lon5 + 1

  # calc 6th grid square code
  latR -= lat5 * (0.5/4) / 60; lonR -= lon5 * (0.75/4) / 60
  lat6 = (latR / (0.5/8) * 60).floor; lon6 = (lonR /(0.75/8) * 60).floor
  mesh6 = lat6 * 2 + lon6 + 1

  if MESH_LV == 3
    gs_code = mesh1*10000 + mesh2*100 + mesh3
  else
    gs_code = mesh1*10000000 + mesh2*100000 + mesh3*1000 + mesh4*100 + mesh5*10 + mesh6
  end    
#    puts "#{gs_code}"

  return gs_code
end

def meshcode2_coordinate(gps_inf)

  code = gps_inf.to_s
  # calc from 1st grid square code
  lat = code[0..1].to_f / 1.5; lon = code[2..3].to_f + 100

  # calc from 2nd grid square code
  latcode = code[4].to_f; loncode = code[5].to_f
  lat += latcode * 5 / 60; lon += loncode * 7.5 / 60

  # calc from 3rd grid square code 
  latcode = code[6].to_f; loncode = code[7].to_f
  lat += latcode * 0.5 / 60; lon += loncode * 0.75 / 60

  # calc from 4th grid square code 
  num = code[8].to_f - 1; latcode = (num / 2).to_i
  loncode = (num - latcode * 2).to_f; 
  lat += latcode * 0.5 / 2 / 60; lon += loncode * 0.75 / 2 / 60

  # calc from 5th grid square code 
  num = code[9].to_f - 1
  latcode = (num / 2).to_i; loncode = (num - latcode * 2).to_f
  lat += latcode * 0.5 / 4 / 60; lon += loncode * 0.75 / 4 / 60

  # calc from 6th grid square code 
  num = code[10].to_f - 1
  latcode = (num / 2).to_i; loncode = (num - latcode * 2).to_f
  lat += latcode * 0.5 / 8 / 60; lon += loncode * 0.75 / 8 / 60

  mlat = 0.5 / 8; mlon = 0.75 / 8

  lat0 = lat
  lon0 = lon
  lat1 = lat0 + mlat / 60
  lon1 = lon0 + mlon / 60
    
  #puts "lat0;lon0 =  #{lat0} #{lon0}"
  #puts "lat1;lon1 =  #{lat1} #{lon1}"
    
  return lon0, lat0, lon1, lat1
end

def enc_locapo(lon, lat)
lonlat_ary = Array.new

@longitude_step = (lon + 180) / 360 * 45697600;
@latitude_step = (lat + 90) / 180 * 45697600;
  
lonlat_ary = [
  @latitude_step / 1757600 % 26 + 65,
  @latitude_step / 67600 % 26 + 65,
  @latitude_step / 6760 % 10 + 48,
  46,
  @longitude_step / 1757600 % 26 + 65,
  @longitude_step / 67600 % 26 + 65,
  @longitude_step / 6760 % 10 + 48,
  46,
  @latitude_step / 260 % 26 + 65,
  @latitude_step / 10 % 26 + 65,
  @latitude_step / 1 % 10 + 48,
  46,
  @longitude_step / 260 % 26 + 65,
  @longitude_step / 10 % 26 + 65,
  @longitude_step / 1 % 10 + 48
]  
  locapo = lonlat_ary.pack("U*")

  return locapo
end

File.open("rslt_area_check.txt", "w"){|gsc_fp| gsc_fp.write "locapo_flg = #{$locapo_flg}/ mesh_flg = #{$mesh_flg}\r\n\r\n"}

count = 0
locapo_hash = Hash.new { |hash,key| hash[key] = [] }

@line_table.each{ |latlon|
  if count % 2 == 0
    @lon = latlon
    count += 1
  else
    @lat = latlon
    count = 0

    mesh = coordinate2_meshcode(@lon, @lat)
    locapo_code = enc_locapo(@lon, @lat)
    
    locapo_hash["#{mesh}"] << locapo_code
    locapo_hash["#{mesh}"] = locapo_hash["#{mesh}"].uniq
  end
}

File.open("rslt_area_check.txt", "a"){|gsc_fp|
  if $locapo_flg == true
    locapo_hash.each{|key_gsc, val_lcp|
    gsc_fp.write "#{key_gsc}=>#{val_lcp.uniq}\r\n" }
  elsif $mesh_flg == true
    locapo_hash.each_key{|key_gsc|
    gsc_fp.write "#{key_gsc}\r\n" }
  end
}

