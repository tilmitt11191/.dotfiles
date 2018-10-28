#!/usr/bin/env ruby
# -*- encoding: UTF-8 -*-
#
# control database

require 'mysql2'

  HOST_NAME = "localhost"
  USER_NAME = "root"
  PASSWORD  = "cnpl"
  DB_NAME   = "dbdb"

# get data from database.
class DB2KML
  def get_dbdata(table_name)
    dbcolumn_val_hash = Hash.new { |hash,key| hash[key] = [] }

    #connect database
    db = Mysql2::Client.new(:host => HOST_NAME, :username => USER_NAME, :password => PASSWORD, :database => DB_NAME)

    res = db.query("SELECT TCP_BEGIN, TCP_END, SRC_IPADDR, TCP_SZ_UP, TCP_SZ_DOWN, HOST_NAME, GPS_LATITUDE, GPS_LONGITUDE FROM #{table_name}")
    db.close
    res.each {|row|
      row.each{|key, val|
        case key
        when "TCP_BEGIN"
          column = "tcp_begin";         val = val.to_s
        when "TCP_END"
          column = "tcp_end";           val = val.to_s
        when "SRC_IPADDR"
          column = "src_ipaddr";        val = val.to_s
        when "TCP_SZ_UP"
          column = "tcp_upload_size";   val = val.to_i
        when "TCP_SZ_DOWN"
          column = "tcp_download_size"; val = val.to_i
        when "HOST_NAME"
          column = "request_host";      val = val.to_s
        when "GPS_LATITUDE"
          column = "gps_latitude";      val = val.to_f
        when "GPS_LONGITUDE"
          column = "gps_longitude";     val = val.to_f
        end
        dbcolumn_val_hash[column] << val unless column.nil? }
    }
    res = nil

    return  dbcolumn_val_hash
  end
end

