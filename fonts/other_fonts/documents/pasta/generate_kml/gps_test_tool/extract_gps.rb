#!/usr/bin/env ruby

require 'csv'
require 'fileutils'
require 'logger'
require 'optparse'
require_relative '../calc_locapo.rb'
require_relative '../def_kml.rb'
require_relative '../def_linetable'

NUM_OF_POINT = 15

opt = OptionParser.new

if ARGV[0] == "clean"
  FileUtils.rm(Dir.glob("extGPS_*.csv"))
  FileUtils.rm(Dir.glob("ext*.kml"))
  FileUtils.rm(Dir.glob("ext*.kmz"))
  FileUtils.rm(Dir.glob("tmp_extlog/*.log"))
  FileUtils.rmdir("tmp_extlog")
  FileUtils.rm(Dir.glob("*.txt"))
  exit
end

begin
  opt.on('-k', '--kml', 'Generate KML File') {|v| $kml_flg = v }
  opt.on('-p', '--progressbar', 'Show Progressbar') {|v| $pbar_flg = v }
  opt.parse!(ARGV)
  $all_flg = true if ($all_flg.nil? and $yamanote_flg.nil? and $new_tokaido_flg.nil?)
rescue => ex
  puts  "#{ex.message}"
  print opt.help; exit
end

if ARGV.empty?
  puts "!!!! input csv file plz. !!!!"
  exit
end

if $pbar_flg == true
require 'progressbar'
end

OUTPUT_file ="extGPS_#{Time.now.strftime("%Y%m%d_%H%M%S")}.csv"
tmplog_dir = "tmp_extlog"
FileUtils.mkdir(tmplog_dir) unless FileTest.exist?(tmplog_dir)
@log = Logger.new("./tmp_extlog/#{Time.now.strftime("%Y%m%d_%H%M%S")}.log")
@calc_locapo = CALC_LOCAPO.new

# Default log level is DEBUG.
def logger(log_lv, msg)
  @log.level = Logger::DEBUG

  case log_lv
    when 'DEBUG' then @log.debug(msg)
    when 'INFO' then @log.info(msg)
    when 'WARN' then @log.warn(msg)
    when 'ERROR' then @log.error(msg)
    when 'FATAL' then @log.fatal(msg)
  end
end

# main method
# 
# extract GPS information from CSV file
def extract_gps(data_file)
  @kml_file = "ext#{Time.now.strftime("%Y%m%d_%H%M%S")}.kml"
  loca_array = Array.new
  csv_keys = Array.new
  begin_id = end_id = srcip_id = req_id = lat_id = lon_id = 0
  iploca_hash = Hash.new { |hash,key| hash[key] = [] }
  ipreq_hash = Hash.new { |hash,key| hash[key] = [] }
  iptime_hash = Hash.new { |hash,key| hash[key] = [] }
  reqdata_hash = Hash.new { |hash,key| hash[key] = [] }
  
  logger('INFO', "-- Application Start. --")
  logger('INFO', "Use CSV File: #{data_file}")
  f_size = File.size(data_file)
  pbar = ProgressBar.new('csv control', f_size, $stderr) if $pbar_flg == true
  
  CSV.foreach(data_file, {:encoding => Encoding::ASCII_8BIT}){ |tcp_data|
    now_data_size = tcp_data.join(",").size + 10
    pbar.inc(now_data_size) if $pbar_flg == true

    if csv_keys.size == 0
      csv_keys = tcp_data
      break raise "!!! Not Found gps_latitude field !!!" if csv_keys.index('gps_latitude') == nil
      
      CSV.open(OUTPUT_file, "w", {:encoding => Encoding::ASCII_8BIT}){|csv|
        csv << ['request_begin', 'request_end', 'src_ipaddr', 'request_host', 'gps_latitude', 'gps_longitude'] } unless $kml_flg == true
      
      begin_id = csv_keys.index('request_begin')
      end_id   = csv_keys.index('request_end')
      srcip_id = csv_keys.index('src_ipaddr')
      req_id   = csv_keys.index('request_host')
      lat_id   = csv_keys.index('gps_latitude')
      lon_id   = csv_keys.index('gps_longitude')
      next
    end
    
    # calculate locapoint and collect information
    if tcp_data[lon_id].to_f > 0 and tcp_data[lat_id].to_f > 0
      locapo = @calc_locapo.enc_locapo(tcp_data[lon_id].to_f, tcp_data[lat_id].to_f)
      src_ip = tcp_data[srcip_id]
      req_url = tcp_data[req_id]
      start_time = tcp_data[begin_id]
      extract_data = [ tcp_data[begin_id], tcp_data[end_id], tcp_data[srcip_id], tcp_data[req_id], tcp_data[lat_id], tcp_data[lon_id] ]
      
      if !iploca_hash[src_ip].uniq.include?(locapo)
        iploca_hash[src_ip] << locapo
        ipreq_hash[src_ip] << req_url
        iptime_hash[src_ip] << start_time
        reqdata_hash[src_ip] << extract_data
      elsif !ipreq_hash[src_ip].uniq.include?(req_url)
        ipreq_hash[src_ip] << req_url
        iptime_hash[src_ip] << start_time
        reqdata_hash[src_ip] << extract_data
      end
    end
  }
  pbar.finish if $pbar_flg == true
  
  # write CSV file if GPS information is different.
  if reqdata_hash.size > 0
    pbar = ProgressBar.new('data control', reqdata_hash.size, $stderr) if $pbar_flg == true
    reqdata_hash.each{ |srcip, data_array|
      if $kml_flg == true
        extract2kml(srcip, data_array) if data_array.size >= NUM_OF_POINT
      elsif data_array.size > 1
        time_array = iptime_hash[srcip].sort
        time_array.each{|time| 
          data_array.each{|data| CSV.open(OUTPUT_file, "a", {:encoding => Encoding::ASCII_8BIT}){ |csv| csv << data } if data[0] == time } }
      else
        logger('DEBUG', "#{data_array[0]}")
      end
      pbar.inc if $pbar_flg == true
    }
    if $kml_flg == true
      File.open(@kml_file, "a"){|kml_fp| kml_fp.write "  <Folder>\r\n    <name>yamanote</name>\r\n    <open>0</open>\r\n"}
      File.open(@kml_file, "a"){|kml_fp| kml_fp.write YAMANOTE_BODY % [YAMANOTE_LINE] }
      File.open(@kml_file, "a"){|kml_fp| kml_fp.write "  </Folder>\r\n"}
      File.open(@kml_file, "a"){|kml_fp| kml_fp.write "  <Folder>\r\n    <name>new tokaido</name>\r\n    <open>0</open>\r\n"}
      File.open(@kml_file, "a"){|kml_fp| kml_fp.write NEW_TOKAIDO_BODY % [NEW_TOKAIDO_LINE] }
      File.open(@kml_file, "a"){|kml_fp| kml_fp.write "  </Folder>\r\n"}
      File.open(@kml_file, "a"){|kml_fp| kml_fp.write KML_FOOTER}; logger('INFO', "--- write footer at kml file ---")

      file_name = File.basename(@kml_file, ".kml")
      system("zip -Dq #{file_name}.kmz #{@kml_file}")
      system("rm -rf #{@kml_file}")
    end
  else
    File.delete(OUTPUT_file)
    logger('INFO', "No GPS info.")
    logger('INFO', "exit"); exit
  end
  pbar.finish if $pbar_flg == true
  
  logger('INFO', "-- Application End. --")
  
  rescue => ex
    logger('FATAL', "!!!!! An error occurred : #{ex.message} !!!!!")
    logger('FATAL', "#{$@}")
    logger('FATAL', "exit"); exit
end

# create kml file
def extract2kml(srcip, data_array)
  num = 0
  lon_ary = Array.new
  lat_ary = Array.new
  color = rand(7).to_i
  kml_body_data = ""
  # output header and style template
  unless File.exist?(@kml_file)
    File.open(@kml_file, "w"){|kml_fp| kml_fp.write KML_HEADER}; logger('INFO', "--- kml file create BEGIN ---")  
    kml_body_data = EXT_COLOR_STYLE
    kml_body_data << EXT_LINE_COLOR_STYLE
    kml_body_data << STATION_STYLE
    kml_body_data << YAMANOTE_LINE_STYLE
    kml_body_data << NEW_TOKAIDO_LINE_STYLE
    File.open(@kml_file, "a"){|kml_fp| kml_fp.write kml_body_data}; logger('INFO', "--- write style at kml file ---")
    kml_body_data.clear
  end

  data_array.each{|data|
    start_time = data[0]
    end_time = data[1]
    lat_ary << data[4].to_f
    lon_ary << data[5].to_f

    if num == 0
      kml_body_data << EXT_USER_FOLDER % [srcip]
      kml_body_data << EXT_PLACE_PART % [start_time, srcip, start_time, end_time, color, lon_ary[num], lat_ary[num]]
    else
      kml_body_data << EXT_LINE_PART % [color, lon_ary[num-1], lat_ary[num-1], lon_ary[num], lat_ary[num]]
      kml_body_data << EXT_PLACE_PART % [start_time, srcip, start_time, end_time, color, lon_ary[num], lat_ary[num]]
    end
    num += 1
  }
  File.open(@kml_file, "a"){|kml_fp| kml_fp.write kml_body_data}; logger('INFO', "--- write #{srcip} data at kml file ---")
  File.open(@kml_file, "a"){|kml_fp| kml_fp.write "  </Folder>\r\n"}
  kml_body_data.clear
end

while arg = ARGV.shift
  extract_gps(arg)
end
