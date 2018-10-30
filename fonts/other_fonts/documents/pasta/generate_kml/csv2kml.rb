#!/usr/bin/env ruby
#
# control csv file

require 'csv'
if $pbar_flg == true
require 'progressbar'
end

# get data from csv file.
class CSV2KML
  # get data from csv file.
  def get_csvdata( data_file)
    csv_column = Array.new
    csv_data_array = Array.new
    gps_flg = 0
    
    f_size = File.size(data_file)
    pbar = ProgressBar.new('csv control', f_size, $stderr) if $pbar_flg == true

    CSV.foreach(data_file, {:encoding => Encoding::ASCII_8BIT}){|csv_data|
      now_data_size = csv_data.join(",").size + 10
      pbar.inc(now_data_size) if $pbar_flg == true

      next csv_column = csv_data if csv_column.size == 0
      break raise "!!! Not Found gps_latitude field !!!" if csv_column.index('gps_latitude') == nil
      
      csv_values = Array.new
      csv_values.push( csv_data[csv_column.index('tcp_begin')] )
      csv_values.push( csv_data[csv_column.index('tcp_end')] )
      csv_values.push( csv_data[csv_column.index('src_ipaddr')] )
      csv_values.push( csv_data[csv_column.index('tcp_upload_size')] )
      csv_values.push( csv_data[csv_column.index('tcp_download_size')] )
      csv_values.push( csv_data[csv_column.index('request_host')] )
      csv_values.push( csv_data[csv_column.index('gps_latitude')].to_f )
      gps_flg = 1 if csv_data[csv_column.index('gps_latitude')].to_f > 0
      csv_values.push( csv_data[csv_column.index('gps_longitude')].to_f )

      csv_data_array.push(csv_values) }

    raise "!!! Not Found gps_latitude data !!!" if gps_flg == 0
    csv_column = ['tcp_begin', 'tcp_end', 'src_ipaddr', 'tcp_upload_size', 'tcp_download_size', 'request_host', 'gps_latitude', 'gps_longitude']
    
    pbar.finish if $pbar_flg == true
    
    return  csv_data_array, csv_column
  end  
end

