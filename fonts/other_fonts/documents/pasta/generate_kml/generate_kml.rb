#!/usr/bin/env ruby
# -*- encoding: UTF-8 -*-
#
# Generate KML File

require 'fileutils'
require 'logger'
require 'optparse'

GOOD = 1; FAIR = 2; POOR = 3
# sec
TIMEOUT_VAL = 60
# meter
OUT_RANGE = 100
# the number of request url to include
REQ_MAX = 3
# true: display in the polygon/ false: display in the pin
USE_POLYGON = true

opt = OptionParser.new

begin
  opt.on('-a', '--all', 'show All Line and point.') {|v| $all_flg = v }
  opt.on('-y', '--yamanote', 'show the point around YAMANOTE Line only.') {|v| $yamanote_flg = v }
  opt.on('-t', '--new_tokaido', 'show the point around NEW TOKAIDO Line only.') {|v| $new_tokaido_flg = v }
  opt.on('-d', '--data_base', 'Use DataBase') {|v| $db_flg = v }
  opt.on('-p', '--progressbar', 'Show Progressbar') {|v| $pbar_flg = v }
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

if ARGV[0] == "clean"
  FileUtils.rm(Dir.glob('*.kml'))
  FileUtils.rm(Dir.glob('*.kmz'))
  FileUtils.rm(Dir.glob('*.tmp'))
  FileUtils.rm(Dir.glob('./tmp_log/*.log'))
  FileUtils.rmdir('./tmp_log')
  FileUtils.rm(Dir.glob('*.txt'))
  exit
end

require "#{File.dirname(__FILE__)}/def_kml.rb"
require "#{File.dirname(__FILE__)}/def_linetable.rb"
require "#{File.dirname(__FILE__)}/csv2kml.rb"
require "#{File.dirname(__FILE__)}/db2kml.rb"
require "#{File.dirname(__FILE__)}/calc_gsc.rb"
require "#{File.dirname(__FILE__)}/calc_locapo.rb"
require "#{File.dirname(__FILE__)}/calc_dist.rb"


# Default log level is DEBUG.
def logger(log_lv, msg)
  @log.level = Logger::INFO

  case log_lv
    when 'DEBUG' then @log.debug(msg)
    when 'INFO' then @log.info(msg)
    when 'WARN' then @log.warn(msg)
    when 'ERROR' then @log.error(msg)
    when 'FATAL' then @log.fatal(msg)
  end
end

# create log directory, and file.
#
# calculate grid square code, and locapoint by line_coordinate2_mesh_locapo
def init
  @kml_file = "#{Time.now.strftime("%Y%m%d_%H%M%S")}.kml"
  @yamanote_tmpkml = "yamanote_#{Time.now.strftime("%Y%m%d_%H%M%S")}.tmp"
  @new_tokaido_tmpkml = "new_tokai_#{Time.now.strftime("%Y%m%d_%H%M%S")}.tmp"
  @other_tmpkml = "other_#{Time.now.strftime("%Y%m%d_%H%M%S")}.tmp"
  
  @calc_grid_square_code = CALC_GSC.new
  @calc_locapo = CALC_LOCAPO.new
  @calc_distance = CALC_DIST.new
  
  # gsc_locapo_hash:{ gs_code => [line_locapoint, line_locapoint,...] } by LineTable
  @gsc_locapo_hash = Hash.new { |hash,key| hash[key] = [] }
  
  tmplog_dir = "tmp_log"
  FileUtils.mkdir(tmplog_dir) unless FileTest.exist?(tmplog_dir)

  @log = Logger.new("./tmp_log/#{Time.now.strftime("%Y%m%d_%H%M%S")}.log")
  logger('INFO', "Application Start.")
  
  @yamanote_gsc_array = Array.new
  @new_tokaido_gsc_array = Array.new
  yamanote_line = 0; new_tokaido_line = 1

  # railroad_gsc_array = [line_gs_code, line_gs_code,....] by LineTable
  @yamanote_gsc_array = line_coordinate2_mesh_locapo(yamanote_line) if ($all_flg == true or $yamanote_flg == true)
  @new_tokaido_gsc_array = line_coordinate2_mesh_locapo(new_tokaido_line) if ($all_flg == true or $new_tokaido_flg == true)
end

# calculate 1/8 grid square code at railway table by coordinate2_meshcode
#
# and locapoint by enc_locapo.
def line_coordinate2_mesh_locapo(flg)
  line_array = Array.new
  grid_square_code = 0
  locapo = 0
  
  case flg
  when 0
    YAMANOTE_LINE_COORDINATE.each_line{|line_coordinate|
      grid_square_code = @calc_grid_square_code.coordinate2_meshcode(line_coordinate.split(",")[0].strip.to_f, line_coordinate.split(",")[1].to_f)
      line_array << grid_square_code unless line_array.include?(grid_square_code)
      locapo = @calc_locapo.enc_locapo(line_coordinate.split(",")[0].strip.to_f, line_coordinate.split(",")[1].to_f)
      @gsc_locapo_hash["#{grid_square_code}"] << locapo unless @gsc_locapo_hash["#{grid_square_code}"].include?(locapo)
      line_coordinate.replace '' }
    return line_array
  when 1
    NEW_TOKAIDO_LINE_COORDINATE.each_line{|line_coordinate|
      grid_square_code = @calc_grid_square_code.coordinate2_meshcode(line_coordinate.split(",")[0].strip.to_f, line_coordinate.split(",")[1].to_f)
      line_array << grid_square_code unless line_array.include?(grid_square_code)
      locapo = @calc_locapo.enc_locapo(line_coordinate.split(",")[0].strip.to_f, line_coordinate.split(",")[1].to_f)
      @gsc_locapo_hash["#{grid_square_code}"] << locapo unless @gsc_locapo_hash["#{grid_square_code}"].include?(locapo)
      line_coordinate.replace '' }
    return line_array
  end
end

# control ip address and begin-time, end-time for caluclate throughput.
def create_ipaddr_tcpdata_hash(pos)
  ipaddr = @column_val_hash['src_ipaddr'][pos]
 
  begin_year = @column_val_hash['tcp_begin'][pos][0..3].to_i
  begin_month = @column_val_hash['tcp_begin'][pos][5..6].to_i
  begin_day = @column_val_hash['tcp_begin'][pos][8..9].to_i
  begin_hour = @column_val_hash['tcp_begin'][pos][11..12].to_i
  begin_min = @column_val_hash['tcp_begin'][pos][14..15].to_i
  begin_sec = @column_val_hash['tcp_begin'][pos][17..18].to_i
  begin_msec = @column_val_hash['tcp_begin'][pos][20..25].to_i
  begin_time = Time.utc(begin_year, begin_month, begin_day, begin_hour, begin_min, begin_sec, begin_msec)
      
  fin_year = @column_val_hash['tcp_end'][pos][0..3].to_i
  fin_month = @column_val_hash['tcp_end'][pos][5..6].to_i
  fin_day = @column_val_hash['tcp_end'][pos][8..9].to_i
  fin_hour = @column_val_hash['tcp_end'][pos][11..12].to_i
  fin_min = @column_val_hash['tcp_end'][pos][14..15].to_i
  fin_sec = @column_val_hash['tcp_end'][pos][17..18].to_i
  fin_msec = @column_val_hash['tcp_end'][pos][20..25].to_i
  fin_time = Time.utc(fin_year, fin_month, fin_day, fin_hour, fin_min, fin_sec, fin_msec)
    
  # ipaddr_tcpdata_hash: {ipaddr => [begin_time, fin_time,  upload size, download size, up throughput, down throughput] }  
  if @ipaddr_tcpdata_hash[ipaddr][0].nil?
    @ipaddr_tcpdata_hash[ipaddr][0] = begin_time
    @ipaddr_tcpdata_hash[ipaddr][1] = fin_time
  else
    diff_time = begin_time - @ipaddr_tcpdata_hash[ipaddr][1]
    if diff_time > TIMEOUT_VAL
      logger('DEBUG', "===== #{ipaddr}: Time Out Occured between #{@ipaddr_tcpdata_hash[ipaddr][1]} and #{begin_time} =====")
      return ipaddr
    end
    @ipaddr_tcpdata_hash[ipaddr][0] = begin_time if begin_time - @ipaddr_tcpdata_hash[ipaddr][0] < 0
    @ipaddr_tcpdata_hash[ipaddr][1] = fin_time if fin_time - @ipaddr_tcpdata_hash[ipaddr][1] > 0
  end

  @ipaddr_tcpdata_hash[ipaddr][2] = @ipaddr_tcpdata_hash[ipaddr][2].to_i + (@column_val_hash['tcp_upload_size'][pos].to_i) * 8
  @ipaddr_tcpdata_hash[ipaddr][3] = @ipaddr_tcpdata_hash[ipaddr][3].to_i + (@column_val_hash['tcp_download_size'][pos].to_i) * 8

  @ipaddr_tcpdata_hash[ipaddr][4] = @ipaddr_tcpdata_hash[ipaddr][2] / (@ipaddr_tcpdata_hash[ipaddr][1] - @ipaddr_tcpdata_hash[ipaddr][0])
  @ipaddr_tcpdata_hash[ipaddr][5] = @ipaddr_tcpdata_hash[ipaddr][3] / (@ipaddr_tcpdata_hash[ipaddr][1] - @ipaddr_tcpdata_hash[ipaddr][0])

  # ipaddr_reqhost_hash: {ipaddr => [request_host] }
  if ( @ipaddr_reqhost_hash[ipaddr].size < REQ_MAX and !@column_val_hash['request_host'][pos].nil? )
    request_host = @column_val_hash['request_host'][pos]
    request_host = request_host.encode("UTF-16BE", "UTF-8", :invalid => :replace, :undef => :replace, :replace => '?').encode("UTF-8")
    
    request = ""
    request_host.scan(/./){ |str| request += str if(/[ -~｡-ﾟ]/ =~ str) }
    @ipaddr_reqhost_hash[ipaddr] << request
    @ipaddr_reqhost_hash[ipaddr] = @ipaddr_reqhost_hash[ipaddr].uniq
  end
  
  return TIMEOUT_VAL
end

# output data in a tmp file
def write_tmp_kml(yamanote_data, yamanote_around_data, new_tokaido_data, new_tokaido_around_data, other_data)
  logger('INFO', "--- write data at tmp file ---\r\n")
  begin
    if(yamanote_data.size > 0 or $yamanote_flg == true or $all_flg == true )
      File.open(@yamanote_tmpkml, "a"){ |yamanote_tmpkml_fp|
        yamanote_tmpkml_fp.write yamanote_data
        yamanote_tmpkml_fp.write yamanote_around_data }
    end
    if (new_tokaido_data.size > 0 or $new_tokaido_flg == true or $all_flg == true )
      File.open(@new_tokaido_tmpkml, "a"){ |new_tokaido_tmpkml_fp|
        new_tokaido_tmpkml_fp.write new_tokaido_data
        new_tokaido_tmpkml_fp.write new_tokaido_around_data }
    end
    File.open(@other_tmpkml, "a"){ |other_tmpkml_fp|
      other_tmpkml_fp.write other_data }
      
  rescue => ex
    logger('FATAL', "can't open/ write tmp file; #{ex.message}")
    logger('FATAL', "exit"); exit
  end  
end

def check_including_point(tcp_gsc)
  coordinate_array = Array.new
  gsc_array = Array.new
  lon = @gsc_gpsdata_hash[tcp_gsc][6]; lat = @gsc_gpsdata_hash[tcp_gsc][7]  
  lon_left = lon - 0.00088; lat_down = lat - 0.00088
  lon_right = lon + 0.00088; lat_up = lat + 0.00088
  
  # Get now place & 8 points in the vicinity
  coordinate_array << lon_left;   coordinate_array << lat_down
  coordinate_array << lon_left;   coordinate_array << lat
  coordinate_array << lon_left;   coordinate_array << lat_up
  coordinate_array << lon;        coordinate_array << lat_down
  coordinate_array << lon;        coordinate_array << lat
  coordinate_array << lon;        coordinate_array << lat_up
  coordinate_array << lon_right;  coordinate_array << lat_down
  coordinate_array << lon_right;  coordinate_array << lat
  coordinate_array << lon_right;  coordinate_array << lat_up

  for i in 0..coordinate_array.size-1
    next if i%2 != 0
    grid_square_code = @calc_grid_square_code.coordinate2_meshcode(coordinate_array[i], coordinate_array[i+1]) 
    gsc_array << grid_square_code unless gsc_array.include?(grid_square_code)
    i += 1
  end

  gsc_array.each{|point_gsc|
    @gsc_locapo_hash["#{point_gsc}"].each{|locapo|
      loca_lon, loca_lat = @calc_locapo.dec_locapo("#{locapo}")
      distance = @calc_distance.dist2point(lon, lat, loca_lon, loca_lat)
      if (@gsc_gpsdata_hash[tcp_gsc][5].to_f == 0 or @gsc_gpsdata_hash[tcp_gsc][5].to_f - distance > 0)
        @gsc_gpsdata_hash[tcp_gsc][5] = distance
      end }

      if @yamanote_gsc_array.include?(point_gsc) and ($yamanote_flg == true or $all_flg == true)
        @gsc_gpsdata_hash[tcp_gsc][8] = "near_yl"
      elsif @new_tokaido_gsc_array.include?(point_gsc) and ($new_tokaido_flg == true or $all_flg == true)
        @gsc_gpsdata_hash[tcp_gsc][8] = "near_ntl"
      end
    
      if @gsc_gpsdata_hash[tcp_gsc][8] == nil and $all_flg == nil
        logger('INFO', "NOT OUTPUT. grid square code(#{tcp_gsc}) is not around Line.")
      end }
end

# output data in a kml file
def write_kml_data(*ipaddr)
  yamanote_data, new_tokaido_data, other_data = "", "", ""
  yamanote_around_data, new_tokaido_around_data = "", ""
  @timeout_ip = nil
  timeout_gsc = 0
  timeout_flg = ipaddr.size
    
  @gsc_gpsdata_hash.each_key{ |grid_square_code|
    src_ip = @gsc_gpsdata_hash[grid_square_code][0]
    start_time = @ipaddr_tcpdata_hash[src_ip][0].to_s.split(" UTC")[0]
    #start_time = start_time.split(" UTC")[0]
    end_time = @ipaddr_tcpdata_hash[src_ip][1].to_s.split(" UTC")[0]
    #end_time = end_time.split(" UTC")[0]
    up_throughput = @ipaddr_tcpdata_hash[src_ip][4]
    down_throughput = @ipaddr_tcpdata_hash[src_ip][5]
    distance = @gsc_gpsdata_hash[grid_square_code][5]
        
    if timeout_flg > 0
      @timeout_ip = ipaddr.join(",")
      src_ip == @timeout_ip ? timeout_gsc = grid_square_code : (timeout_gsc = @ipaddr_tcpdata_hash[@timeout_ip][6]; next)
    end
    
    logger('DEBUG', "=== [data info.] ===")
    logger('DEBUG', "ipaddr_info : #{src_ip} => #{@ipaddr_tcpdata_hash[src_ip]}\r\n")
    logger('DEBUG', "gps_info: #{grid_square_code} => #{@gsc_gpsdata_hash[grid_square_code]}\r\n")
    logger('DEBUG', "req_info: #{src_ip} => #{@ipaddr_reqhost_hash[src_ip]}\r\n")

    # get station name
    station_name = nil

    station_name = "Yamanote Line" if (@gsc_gpsdata_hash[grid_square_code][8] == "near_yl" and @gsc_gpsdata_hash[grid_square_code][5].to_f < OUT_RANGE)

    YAMANOTE_STATION_TABLE.each{ |station, gsc|
      station_name = station if gsc.include?(grid_square_code) }

    station_name = "New Tokaido Line" if (@gsc_gpsdata_hash[grid_square_code][8] == "near_ntl" and @gsc_gpsdata_hash[grid_square_code][5].to_f < OUT_RANGE)
    
    NEW_TOKAIDO_STATION_TABLE.each{ |station, gsc|
      station_name = station if gsc.include?(grid_square_code) }

    station_name = "#{grid_square_code} is out of scope" if station_name.nil?

    # change porygon by throughput
    style = FAIR
    style = GOOD if down_throughput > 800000
    style = POOR if down_throughput < 400000

    # get polygon coordinates
    lon0 = @gsc_gpsdata_hash[grid_square_code][1]; lat0 = @gsc_gpsdata_hash[grid_square_code][2]
    lon1 = @gsc_gpsdata_hash[grid_square_code][3]; lat1 = @gsc_gpsdata_hash[grid_square_code][4]

    logger('INFO', "=== [write data.] ===")
    logger('INFO', "start: #{start_time}/ end: #{end_time}")
    logger('INFO', "src ip: #{src_ip} => grid square code: #{grid_square_code}, station name: #{station_name}")
    logger('INFO', "up throughput: #{up_throughput}, down throughput: #{down_throughput}")
    @gsc_gpsdata_hash[grid_square_code][5].to_f > 0 ? logger('INFO', "distance: #{@gsc_gpsdata_hash[grid_square_code][5]}m\r\n") : logger('INFO', "distance: out of scope\r\n")
    
    # create body part
    USE_POLYGON == true ? \
    @kml_body_data << KML_BODY_PART % [ station_name, style + 3, start_time, end_time, up_throughput, down_throughput, distance] : \
    @kml_body_data << KML_PIN_BODY_PART % [ style, start_time, end_time, up_throughput, down_throughput, distance]
    
    # create src ipaddr part
    @kml_body_data << KML_IPADDR_PART % [@gsc_gpsdata_hash[grid_square_code][0]]
    
    # create request kml part
    req = 0
    @kml_body_data << KML_REQUEST_HEAD % [@ipaddr_reqhost_hash[src_ip].size]
    @ipaddr_reqhost_hash[src_ip].uniq.each{|req_host|
      @kml_body_data << "      <tr>\r\n" if ( @ipaddr_reqhost_hash[src_ip].size > 1 and req > 0 )
      @kml_body_data << KML_REQUEST_PART % [req_host.nil? ? "<br>" : req_host]; req = 1 }
         
    # create polygon part
    USE_POLYGON == true ? \
    @kml_body_data << KML_POLY_PART % [lon0, lat0, lon1, lat0, lon1, lat1, lon0, lat1, lon0, lat0] : \
    @kml_body_data << KML_PIN_PART % [@gsc_gpsdata_hash[grid_square_code][6], @gsc_gpsdata_hash[grid_square_code][7]]

    # select data folder
    if (YAMANOTE_STATION_TABLE.keys.include?(station_name) and ($yamanote_flg == true or $all_flg == true) )
      yamanote_data << @kml_body_data
    elsif (NEW_TOKAIDO_STATION_TABLE.keys.include?(station_name) and ($new_tokaido_flg == true or $all_flg == true) )
      new_tokaido_data << @kml_body_data
    elsif station_name.include?("Yamanote Line")
      yamanote_around_data << @kml_body_data
    elsif station_name.include?("New Tokaido Line")
      new_tokaido_around_data << @kml_body_data
    else
      other_data << @kml_body_data
    end

    @kml_body_data.clear
  }

  begin
    if timeout_flg == 1
      write_tmp_kml(yamanote_data, yamanote_around_data, new_tokaido_data, new_tokaido_around_data, other_data)
      
      @gsc_gpsdata_hash.delete(timeout_gsc)
      @ipaddr_tcpdata_hash.delete(@timeout_ip)
      @ipaddr_reqhost_hash.delete(@timeout_ip)
    else
      if(yamanote_data.size > 0 or $yamanote_flg == true or $all_flg == true )
        yamanote_data << yamanote_around_data
        if File.exist?(@yamanote_tmpkml)
          pbar = ProgressBar.new('y_tmp read', File.size(@yamanote_tmpkml), $stderr) if $pbar_flg == true
          File.foreach(@yamanote_tmpkml){|yamanote_fp| 
            pbar.inc(yamanote_fp.size) if $pbar_flg == true
            yamanote_data << yamanote_fp
            yamanote_fp.replace '' }
          pbar.finish if $pbar_flg == true
        end
        @kml_body_data << KML_YAMANOTE_FOLDER % [yamanote_data, YAMANOTE_BODY % [YAMANOTE_LINE_COORDINATE] ]
        File.open(@kml_file, "a"){|kml_fp| kml_fp.write @kml_body_data }
        @kml_body_data.clear
      end
      
      if (new_tokaido_data.size > 0 or $new_tokaido_flg == true or $all_flg == true )
        new_tokaido_data << new_tokaido_around_data
        if File.exist?(@new_tokaido_tmpkml)
          pbar = ProgressBar.new('t_tmp read', File.size(@new_tokaido_tmpkml), $stderr) if $pbar_flg == true
          File.foreach(@new_tokaido_tmpkml){|new_tokaido_fp|
            pbar.inc(new_tokaido_fp.size) if $pbar_flg == true
            new_tokaido_data << new_tokaido_fp
            new_tokaido_fp.replace '' }
          pbar.finish if $pbar_flg == true
        end
        @kml_body_data << KML_NEW_TOKAI_FOLDER % [new_tokaido_data, NEW_TOKAIDO_BODY % [NEW_TOKAIDO_LINE_COORDINATE] ]
        File.open(@kml_file, "a"){|kml_fp| kml_fp.write @kml_body_data }
        @kml_body_data.clear
      end
      
      if File.exist?(@other_tmpkml)
        pbar = ProgressBar.new('o_tmp read', File.size(@other_tmpkml), $stderr) if $pbar_flg == true
        File.foreach(@other_tmpkml){|other_fp|
          pbar.inc(other_fp.size) if $pbar_flg == true
          other_data << other_fp
          other_fp.replace '' }
        pbar.finish if $pbar_flg == true
      end
        @kml_body_data << KML_OTHER_FOLDER % [other_data] if other_data.size > 0
      
      pbar = ProgressBar.new('write kml', @kml_body_data.size, $stderr) if $pbar_flg == true
      File.open(@kml_file, "a"){|kml_fp| kml_fp.write @kml_body_data}; logger('INFO', "--- write data at kml file ---")
      pbar.finish if $pbar_flg == true
      @kml_body_data.clear
    end
  rescue => ex
    logger('FATAL', "can't open/ write kml file @kml body; #{ex.message}")
    logger('FATAL', "exit"); exit
  end
end

# main method
def generate_kml( data_file)
  if $db_flg == true
    db2kml = DB2KML.new
    table_name = data_file
  else
    csv2kml = CSV2KML.new
  end

  style = FAIR
  csv_keys = Array.new
  csv_values = Array.new
  csv_data_array = Array.new
  pos = 0
  
  unless File.exist?(@kml_file)
    @column_val_hash = Hash.new { |hash,key| hash[key] = [] }
    @gsc_gpsdata_hash = Hash.new { |hash,key| hash[key] = [] }
    @ipaddr_reqhost_hash = Hash.new { |hash,key| hash[key] = [] }
    @ipaddr_tcpdata_hash = Hash.new { |hash,key| hash[key] = [] }
    
    begin
      logger('INFO', "TIMEOUT_VAL = #{TIMEOUT_VAL}sec/ OUT_RANGE = #{OUT_RANGE}m")
      logger('INFO', "Sign Up Line: Yamanote Line./ New Tokaido Line.")
      logger('INFO', "Flg Status: all_flg(#{$all_flg})/ yamanote_flg(#{$yamanote_flg})/ new_tokaido_flg(#{$new_tokaido_flg})")
      $db_flg == true ? logger('INFO', "Use DataBase: #{DB_NAME}/ #{table_name}") : logger('INFO', "Use CSV File: #{data_file}")
      
      # output header and style template
      File.open(@kml_file, "w"){|kml_fp| kml_fp.write KML_HEADER}; logger('INFO', "--- kml file create BEGIN ---")      
      @kml_body_data = KML_GOOD_STYLE
      @kml_body_data << KML_FAIR_STYLE
      @kml_body_data << KML_POOR_STYLE
      @kml_body_data << GOOD_POLY_STYLE
      @kml_body_data << FAIR_POLY_STYLE
      @kml_body_data << POOR_POLY_STYLE
      @kml_body_data << STATION_STYLE
      @kml_body_data << YAMANOTE_LINE_STYLE
      @kml_body_data << NEW_TOKAIDO_LINE_STYLE
      @kml_body_data << KML_HANREI_PART
      File.open(@kml_file, "a"){|kml_fp| kml_fp.write @kml_body_data}; logger('INFO', "--- write style at kml file ---")
      @kml_body_data.clear
    rescue => ex
      logger('FATAL', "can't open/ write kml file @kml header; #{ex.message}")
      logger('FATAL', "exit"); exit
    end
  end

  begin
    if $db_flg == true # Use DB
      logger('INFO', "parse start #{table_name}")
      logger('INFO', "  get data #{table_name}")
      @column_val_hash = db2kml.get_dbdata(table_name)
      logger('INFO', "  get data finish")
      logger('DEBUG', "make hash data from db data")
    else # Use CSV file
      logger('INFO', "parse start #{data_file}")
      logger('INFO', "  get data #{data_file}")
      csv_data_array, csv_keys = csv2kml.get_csvdata(data_file)
      logger('INFO', "  get data finish")

      # from array to hash
      logger('DEBUG', "make hash data from csv data")
      csv_values = csv_data_array.transpose
      csv_keys.each{|title| @column_val_hash[title] = csv_values[csv_keys.index(title)] }
    end
  rescue => ex
    logger('FATAL', "file/db parse error: #{ex.message}")
    logger('FATAL', "#{ex.class}")
    logger('FATAL', "#{ex.backtrace}")
    File.delete(@kml_file)
    logger('FATAL', "delete kml file and exit"); exit
  end

  logger('DEBUG', "create ip & data size hash")
  pbar = ProgressBar.new('data control', @column_val_hash['gps_latitude'].size, $stderr) if $pbar_flg == true
  @column_val_hash['gps_latitude'].each{|gps_info|
    src_ip = @column_val_hash['src_ipaddr'][pos]

    # create ip & data size hash
    ret = create_ipaddr_tcpdata_hash(pos)
    if ret != TIMEOUT_VAL
      if @ipaddr_tcpdata_hash[src_ip][6].to_i > 0
        logger('INFO', "== #{src_ip}: Time Out Occured between #{@ipaddr_tcpdata_hash[src_ip][1]} and #{@column_val_hash['tcp_begin'][pos]} ==")
        # write data at tmp file once
        write_kml_data(ret); 
      else
        # no have GPS info.
        @ipaddr_tcpdata_hash.delete(src_ip)
      end

      redo
    end
    pbar.inc if $pbar_flg == true
    next pos += 1 unless gps_info.to_f > 0

    lon = @column_val_hash['gps_longitude'][pos].to_f
    lat = @column_val_hash['gps_latitude'][pos].to_f
    
    # calc grid square code from GPS data
    gs_code = @calc_grid_square_code.coordinate2_meshcode(lon, lat)
    @gsc_gpsdata_hash[gs_code][6] = lon
    @gsc_gpsdata_hash[gs_code][7] = lat

    # check that including the point
    check_including_point(gs_code)

    # delete hash data if distance is range over
    if (@gsc_gpsdata_hash[gs_code][5].to_f > OUT_RANGE and $all_flg == nil)
      pos += 1
      logger('INFO', "NOT OUTPUT. Distance of grid square code(#{gs_code}) and TARGET Line are #{@gsc_gpsdata_hash[gs_code][5].to_f} m.")
      next @gsc_gpsdata_hash.delete(gs_code)
    end

    @column_val_hash['grid_square_code'].push(gs_code)
    @gsc_gpsdata_hash[gs_code][0] = src_ip
    @ipaddr_tcpdata_hash[src_ip][6] = gs_code.to_i
    
    # calc coordinate from grid square code for polygon
    @gsc_gpsdata_hash[gs_code][1], @gsc_gpsdata_hash[gs_code][2], @gsc_gpsdata_hash[gs_code][3], @gsc_gpsdata_hash[gs_code][4] \
     = @calc_grid_square_code.meshcode2_coordinate(gs_code)

    pos += 1 }
    
  pbar.finish if $pbar_flg == true
  logger('INFO', "parse end \r\n")
  
  if $db_flg == true
    @column_val_hash.clear
  end
  
  if ARGV.size == 0
    write_kml_data()

    begin 
      File.open(@kml_file, "a"){ |kml_fp| kml_fp.write KML_FOOTER }; logger('INFO', "--- write footer at kml file. END ---")
    rescue => ex
      logger('FATAL', "can't open/ write kml file @kml line info/ footer; #{ex.message}")
      logger('FATAL', "exit"); exit
    end
  end
    
  rescue => ex
    logger('FATAL', "!!!!! An error occurred : #{ex.message} !!!!!")
    logger('FATAL', "#{$@}")
    FileUtils.rm(Dir.glob('*.tmp'))
    logger('FATAL', "exit"); exit
end
    
### main ###
init()
  
while arg = ARGV.shift
  generate_kml(arg)
end

# generate kmz file including the hanrei.png
begin
  file_name = File.basename(@kml_file, ".kml")
  logger('INFO', "--- create #{file_name}.kmz file  ---")
  FileUtils.cp("#{File.dirname(__FILE__)}/hanrei.org", "./hanrei.png") unless FileTest.exist?("./hanrei.png")
  system("zip -Dq #{file_name}.kmz #{@kml_file} ./hanrei.png")
  system("rm -rf #{@kml_file} hanrei.png") if FileTest.exist?("./hanrei.png")
  FileUtils.rm(Dir.glob('*.tmp'))
  logger('INFO', "Application Finished.")
rescue => ex
  logger('FATAL', "!!!!! An error occurred : #{ex.message} !!!!!")
  logger('FATAL', "#{$@}")
  logger('FATAL', "exit"); exit
end
