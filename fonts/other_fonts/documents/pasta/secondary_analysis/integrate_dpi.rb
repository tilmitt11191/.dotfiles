#!/usr/bin/env ruby
# -*- encoding: UTF-8 -*-

require 'time'
require 'csv'
require 'optparse'
require 'logger'

opt = OptionParser.new
options = {}

# option parser
options[:begin_time] = Time.now
options[:outputs]    = {:csv => nil, :log => nil, :tmp => [],}
options[:size_threshold] = 160000

opt.banner = "Usage: #{File.basename($0)} Base-Data gtp_parse_result.csv tcp_parse_result.csv"
opt.on( '-h', '--help', 'Base-Data can input the csv file or the directory including csv files.' ) { print opt.help; exit }
opt.on( '-s Byte', '--size_threshold Byte', Integer, 'set data size threshold' ) {|v| options[:size_threshold] = v.to_i }
opt.parse!(ARGV)

if ARGV.empty?
  print opt.help
  exit
end

(print opt.help; exit) if (ARGV[0] == nil || ARGV[1] == nil || ARGV[2] == nil)

# name an output file name.
# @param [String] type    file name.
# @option options [Time] :begin_time    integration begin time.
def get_output_file_name(type, options)
  if type.include?( 'log' )
    output_file_name = type + '_' + options[:begin_time].strftime( "%Y%m%d-%H%M%S" ) + '.txt'
    options[:outputs][:log] = output_file_name
  elsif type.include?( 'tmp' )
    output_file_name = type + '_' + options[:begin_time].strftime( "%Y%m%d-%H%M%S" ) + '.tmp'
    options[:outputs][:tmp].unshift output_file_name
  else
    output_file_name = type + '_' + options[:begin_time].strftime( "%Y%m%d-%H%M%S" ) + '.csv'
    options[:outputs][:csv] = output_file_name
  end
  
  return output_file_name
end

# delete temporary file.
def clear_tmp_file(options)
  options[:outputs][:tmp].each{|tmp_file|
    File.delete tmp_file
  }
end

logger = Logger.new(get_output_file_name("dpi_integration_log", options))
logger.level = Logger::INFO


def make_fingerprint_dictionary_data(fingerprint_dictionary, logger)
  fingerprint_os = Hash.new

  CSV.foreach(fingerprint_dictionary, {:encoding => Encoding::ASCII_8BIT}){|row|
    fingerprint_os[row[0]] ||= row[1]
  }
  
  return fingerprint_os
  
rescue => ex
  logger.fatal( "FAIL in make_fingerprint_dictionary_data: #{fingerprint_dictionary}" )
  logger.fatal( "#{ex.message}" )
  ex.backtrace.each{|b| logger.fatal( "#{b}" ) }
  raise  
end


# convert gps parameter and summarize base data.
# @param [Files] enb_files   Base Data directory or file.
# @return [Hash] enbid_gps_info   Return the summarized base data.
def convert_gps_info_and_summarize_in_enbid(enb_files, logger, options)
  enbid_gps_info = Hash.new({})
  enb_file_name  = ""
  
  enb_files.each{|enb_file|
    enb_file_name = File.basename("#{enb_file}", ".csv")
    
    CSV.foreach(enb_file, {:headers => true, :encoding => Encoding::ASCII_8BIT}){|row|
      enbid_bandwidth = Hash.new
      if row["#act"].nil?
        if row.include?("C3T0028")
          enbid     = row["C3T0028"].to_i
          bandwidth = row["C3T0008"].to_s + row["C3T0009"].to_s + row["C3T0213"].to_s
          enb_lat   = row["C3T0173"]
          enb_lon   = row["C3T0174"]
        elsif row.include?("C3P0027")
          enbid     = row["C3P0027"].to_i
          bandwidth = row["C3P0008"].to_s + row["C3P0009"].to_s + row["C3P0193"].to_s
          enb_lat   = row["C3P0173"]
          enb_lon   = row["C3P0174"]
        elsif row.include?("C410045")
          enbid     = row["C410045"].to_i
          bandwidth = row["C410008"].to_s + row["C410009"].to_s + row["C410010"].to_s
          enb_lat   = row["C410041"]
          enb_lon   = row["C410042"]
        else
          raise "enb data file is not target."
        end
        next unless enbid.to_i > 0
        
        if (enb_lat.to_i > 0 && enb_lon.to_i > 0)
          gps_lat = enb_lat[-6, 2].to_f + (enb_lat[-4, 2].to_i * 60 + enb_lat[-2, 2].to_i).to_f / 3600
          gps_lon = enb_lon[-7, 3].to_f + (enb_lon[-4, 2].to_i * 60 + enb_lon[-2, 2].to_i).to_f / 3600
          enbid_gps_info[enbid] = {:bandwidth => bandwidth[0], :latitude => gps_lat, :longitude => gps_lon}
        end
      end  
    }
  }

  CSV.open(get_output_file_name("all_enb_tmp", options), "wb"){|csv|
    enbid_gps_info.each{|enbid, bandwidth_gps_info|
      csv << [nil, nil, nil, nil, nil, nil, nil, nil, nil, 
              enbid, bandwidth_gps_info[:bandwidth], bandwidth_gps_info[:latitude], bandwidth_gps_info[:longitude], 
              nil, nil, nil]
    }
  }

  return enbid_gps_info

rescue => ex
  logger.fatal( "FAIL in convert_gps_info_and_summarize_in_enbid: #{enb_file_name}" )
  logger.fatal( "#{ex.message}" )
  ex.backtrace.each{|b| logger.fatal( "#{b}" ) }
  raise
end

# Summarize gtp session data in teid and ip.
# @param [Files] cplane_file    File of the c-plane analysis result.
# @param [Hash] enbid_gps_info
# @return [Hash] paa_teid_time_enbid
# @return [Hash] count_of_enb_in_gtp
# @return [Hash] cplane_matched_enb
GTPTIME = 0
ENBID   = 1

def summarize_valid_gtp(cplane_file, enbid_gps_info, logger)
  teid_paa = Hash.new
  paa_teid_time_enbid = Hash.new
  count_of_enb_in_gtp = Hash.new
  cplane_matched_enb  = Hash.new
  
  CSV.foreach(cplane_file, :headers => true){|row|
    uli_enbid = row["uli_enb_id"].to_i
    
    if (uli_enbid > 0 and enbid_gps_info.key?(uli_enbid) )
      count_of_enb_in_gtp[uli_enbid] ||= true
      gtp_beginhour_enbid = {Time.at(row["gtp_begin_float"].to_f).hour => uli_enbid}
      
      cplane_matched_enb[gtp_beginhour_enbid] ||= {:gtp_begin => row["gtp_begin"], :gtp_end => row["gtp_end"]}
      
      if (row["gtp_end"] and row["response_paa"] )
        response_teid = row["response_teid"].to_i
        
        teid_paa[response_teid] ||= row["response_paa"] 
        
        paa_teid_time_enbid[row["response_paa"] ] ||= { response_teid => [] }
        paa_teid_time_enbid[row["response_paa"] ][response_teid] = []
      end
    end
  }
  
  CSV.foreach(cplane_file, :headers => true){|row|
    uli_enbid     = row["uli_enb_id"].to_i
    response_teid = row["response_teid"].to_i
    
    if (uli_enbid > 0 and enbid_gps_info.key?(uli_enbid) and row["gtp_end"] and teid_paa[response_teid] )
      gtp_end_time  = Time.at(row["gtp_end_float"].to_f)
     
      if paa_teid_time_enbid[teid_paa[response_teid]][response_teid].empty?
        paa_teid_time_enbid[teid_paa[response_teid]][response_teid] << [gtp_end_time, uli_enbid]
        next
      end
      
      paa_teid_time_enbid[teid_paa[response_teid]][response_teid][-1][ENBID] == uli_enbid ? 
        next : paa_teid_time_enbid[teid_paa[response_teid]][response_teid] << [gtp_end_time, uli_enbid] 
    end
  }
  
  raise "gtp data is not found in #{cplane_file}." if (teid_paa.empty? and paa_teid_time_enbid.empty?)
  
  return paa_teid_time_enbid, count_of_enb_in_gtp, cplane_matched_enb

rescue => ex
  logger.fatal( "FAIL in summarize_valid_gtp: #{cplane_file}" )
  logger.fatal( "#{ex.message}" )
  ex.backtrace.each{|b| logger.fatal( "#{b}" ) }
  raise
end

  OPERATING_SYSTEM_REGEX = [
    [/Android 4\./, 'Android'],
    [/Android 3\./, 'Android'],
    [/Android 2\./, 'Android'],
    [/[Aa]ndroid|auonemarket|(ISW?|HTI|SH[Ix])[0-9]{2}/, 'Android'],
    [/i[Pp][ao]d/, 'iPod_iPad'],
    [/iPhone OS 7/, 'iPhone'],
    [/iPhone OS 6/, 'iPhone'],
    [/iPhone OS 5/, 'iPhone'],
    [/i[Pp]hone/, 'iPhone'],
    [/[Ww]indows|[Mm]icrosoft/, 'PC'],
    [/[Mm]acintosh|[Mm]ac[Bb]ook/, 'PC'],
    [/[Uu]buntu|[Ll]inux/, 'PC']
  ]

def estimate_operating_system( user_agent )
  OPERATING_SYSTEM_REGEX.each do |regex|
    return regex[1] if regex[0] =~ user_agent.to_s
  end
  'other'
end

# select tcp data which matched gtp data.
# @param [Files] uplane_file    File of the u-plane analysis result.
# @param [Hash] enbid_gps_info    
# @param [Hash] cplane_matched_enb   
# @param [Hash] paa_teid_time_enbid
# @param [Hash] fingerprint_os
# @return [Hash] tcp_beginhour_enbid_valid_tcp
# @return [Hash] tcp_beginhour_enbid_os
# @return [Hash] count_of_tcp_user
# @return [Hash] count_of_tcp_matched_gtp_user
OFFSET = 1
DEFAULT_TTL = [60, 64, 128, 255].sort

def select_tcp_matched_gtp(uplane_file, enbid_gps_info, cplane_matched_enb, paa_teid_time_enbid, fingerprint_os, logger, options)
  tcp_hash                 = nil
  count_of_tcp_user        = Hash.new
  enbid                    = 0
  tcp_beginhour_enbid     = Hash.new
  valid_tcp                = Hash.new
  count_of_tcp_matched_gtp_user  = Hash.new
  tcp_beginhour_enbid_valid_tcp = Hash.new
  
  tcp_beginhour_enbid_os = Hash.new
  tcp_beginhour_enbid_content_type = Hash.new
  tcp_beginhour_enbid_close_state = Hash.new
  
  CSV.foreach(uplane_file, {:headers => true, :encoding => Encoding::ASCII_8BIT}){|row|
    next if tcp_hash == row["tcp_hash"]
    tcp_hash = row["tcp_hash"]
    
    count_of_tcp_user[row["src_ipaddr"]] ||= true
    
    nearest_time_difference = nil
    tcp_fingerprint = nil
    content_type = nil
    tcp_close_state = Array.new
    
    if paa_teid_time_enbid.key?(row["src_ipaddr"])
      tcp_begin_float_time = Time.at(row["tcp_begin_float"].to_f)
     
      paa_teid_time_enbid[row["src_ipaddr"]].values.flatten!(1).reverse_each{|gtp_time_enbid|
        gtp_tcp_time_difference = gtp_time_enbid[GTPTIME] - tcp_begin_float_time 
        next if gtp_tcp_time_difference > OFFSET
        
        gtp_tcp_time_difference = gtp_tcp_time_difference.abs if gtp_tcp_time_difference < 0
        
        if (nearest_time_difference.nil? or nearest_time_difference >= gtp_tcp_time_difference)
          nearest_time_difference = gtp_tcp_time_difference
          enbid = gtp_time_enbid[ENBID]
        else
          break
        end
      }
      next if nearest_time_difference.nil?
            
      tcp_beginhour_enbid = {:begin_hour => tcp_begin_float_time.hour, :enbid => enbid}

      original_ttl = DEFAULT_TTL.find(){|x| row["syn_ttl"].to_i < x}
      tcp_fingerprint = [row["syn_window_size"], original_ttl, row["syn_fragment"], row["syn_total_length"],  row["syn_options"], row["syn_quirks"]].join(',')
      
      os_device_type = estimate_operating_system( row["request_user_agent"] )
      
      if (os_device_type == "other" and fingerprint_os)
        os_device_type = fingerprint_os[tcp_fingerprint] if fingerprint_os[tcp_fingerprint]
      end

      case os_device_type
      when /[Aa]ndroid/                 then os_device_type = "android"
      when /i[Oo][Ss]|i[Pp]hone/        then os_device_type = "iphone"
      when /i[Pp][ao]d|iPod_iPad/       then os_device_type = "ipod_ipad"
      when /PC|[Ww]indows|[Mm]acintosh/ then os_device_type = "pc"
      else os_device_type = "other"
      end
      
      tcp_beginhour_enbid_os[tcp_beginhour_enbid ] ||= {os_device_type => {:tcp_download_size => 0, :tcp_download_resent => 0, :tcp_download_unexpected => 0} }
      tcp_beginhour_enbid_os[tcp_beginhour_enbid ][os_device_type] ||= {:tcp_download_size => 0, :tcp_download_resent => 0, :tcp_download_unexpected => 0}
      
      tcp_beginhour_enbid_os[tcp_beginhour_enbid ][os_device_type][:tcp_download_size] += row["tcp_download_size"].to_i
      tcp_beginhour_enbid_os[tcp_beginhour_enbid ][os_device_type][:tcp_download_resent] += row["tcp_download_resent"].to_i
      tcp_beginhour_enbid_os[tcp_beginhour_enbid ][os_device_type][:tcp_download_unexpected] += row["tcp_download_unexpected"].to_i


      if (row["response_content_type"].nil? or row["response_content_type"].split("/")[0] !~ /image|application|video|text|audio/ )
        content_type = "unknown"
      else
        case row["response_content_type"].split("/")[0]
        when /[Ii]mage/       then content_type = "image"
        when /[Aa]pplication/ then content_type = "application"
        when /[Vv]ideo/       then content_type = "video"
        when /[Tt]ext/        then content_type = "text"
        when /[Aa]udio/       then content_type = "audio"
        end
      end
      
      tcp_beginhour_enbid_content_type[tcp_beginhour_enbid ] ||= {content_type => {:tcp_download_size => 0, :tcp_download_resent => 0, :tcp_download_unexpected => 0} }
      tcp_beginhour_enbid_content_type[tcp_beginhour_enbid ][content_type] ||= {:tcp_download_size => 0, :tcp_download_resent => 0, :tcp_download_unexpected => 0}

      tcp_beginhour_enbid_content_type[tcp_beginhour_enbid ][content_type][:tcp_download_size] += row["tcp_download_size"].to_i
      tcp_beginhour_enbid_content_type[tcp_beginhour_enbid ][content_type][:tcp_download_resent] += row["tcp_download_resent"].to_i
      tcp_beginhour_enbid_content_type[tcp_beginhour_enbid ][content_type][:tcp_download_unexpected] += row["tcp_download_unexpected"].to_i
      
      row["tcp_close_state"].split("/").each{|close_state| 
        tcp_beginhour_enbid_close_state[tcp_beginhour_enbid ] ||= {close_state => 0}
        tcp_beginhour_enbid_close_state[tcp_beginhour_enbid ][close_state] ||= 0

        tcp_beginhour_enbid_close_state[tcp_beginhour_enbid ][close_state] += 1
        
        tcp_close_state << close_state
      }

      next if (row["tcp_download_size"].to_i  + row["tcp_download_resent"].to_i  + row["tcp_download_unexpected"].to_i ) <= options[:size_threshold]

      tcp_beginhour_enbid_valid_tcp[tcp_beginhour_enbid ] ||= {row["src_ipaddr"] => [] }
      tcp_beginhour_enbid_valid_tcp[tcp_beginhour_enbid ][row["src_ipaddr"]] ||= []
            
      tcp_beginhour_enbid_valid_tcp[tcp_beginhour_enbid ][row["src_ipaddr"]] << {
        :tcp_begin               => row["tcp_begin"], 
        :tcp_begin_float         => row["tcp_begin_float"].to_f, 
        :tcp_end                 => row["tcp_end"], 
        :tcp_end_float           => row["tcp_end_float"].to_f, 
        :tcp_upload_size         => row["tcp_upload_size"].to_i, 
        :tcp_download_size       => row["tcp_download_size"].to_i, 
        :tcp_upload_resent       => row["tcp_upload_resent"].to_i, 
        :tcp_download_resent     => row["tcp_download_resent"].to_i, 
        :tcp_upload_unexpected   => row["tcp_upload_unexpected"].to_i, 
        :tcp_download_unexpected => row["tcp_download_unexpected"].to_i, 
        :tcp_client_rtt          => row["client_rtt"].to_f / 1000000.to_f, 
        :tcp_server_rtt          => row["server_rtt"].to_f / 1000000.to_f, 
        :tcp_hash                => row["tcp_hash"], 
        :operating_system        => os_device_type, 
        :content_type            => content_type, 
        :close_state             => tcp_close_state, 
        :enbid                   => enbid
      }
      
      count_of_tcp_matched_gtp_user[row["src_ipaddr"]] ||= true
      beginhour_enbid = {tcp_begin_float_time.hour => enbid}
      cplane_matched_enb.delete(beginhour_enbid) if cplane_matched_enb.key?(beginhour_enbid)
    end
  }
  
  CSV.open(get_output_file_name("enb_matched_cplane_only_tmp", options), "wb"){|csv|
    cplane_matched_enb.each{|gtp_time_enbid, gtp_time|
      enbid = gtp_time_enbid.values[0]
      csv << [ gtp_time[:gtp_begin], gtp_time[:gtp_end], 
        nil, nil, nil, nil, nil, nil, nil, 
        enbid, enbid_gps_info[enbid][:bandwidth], enbid_gps_info[enbid][:latitude], enbid_gps_info[enbid][:longitude], 
        nil, nil, nil ]
    }
  }
  
  tcp_beginhour_enbid_valid_tcp.each_value{|valid_tcp|
    valid_tcp.values.each {|tcp_sessions_matched_gtp|
      tcp_sessions_matched_gtp.sort_by!{|tcp_session_matched_gtp| tcp_session_matched_gtp[:tcp_begin_float] }
    }
  }
  
  raise "data to match were not found." if tcp_beginhour_enbid_valid_tcp.empty?

  return tcp_beginhour_enbid_valid_tcp, tcp_beginhour_enbid_os, tcp_beginhour_enbid_content_type, tcp_beginhour_enbid_close_state, count_of_tcp_user, count_of_tcp_matched_gtp_user
  
rescue => ex
  logger.fatal( "FAIL in select_tcp_matched_gtp" )
  logger.fatal( "#{ex.message}" )
  ex.backtrace.each{|b| logger.fatal( "#{b}" ) }
  raise
end

# Aggregate tcp session.
# @param [Hash] tcp_beginhour_enbid_valid_tcp
# @return [Hash] beginhour_enbid_ipaddr_aggregated_tcp_array
def tcp_aggregation(tcp_beginhour_enbid_valid_tcp, logger)
  beginhour_enbid_ipaddr_aggregated_tcp_array = Hash.new
  
  tcp_beginhour_enbid_valid_tcp.each{|beginhour_enbid, ipaddrs_valid_tcp|
    aggregated_tcp = Hash.new
    
    ipaddrs_valid_tcp.each{|src_ip, valid_tcp|
      prev_tcp = Hash.new
      aggregated_tcp[src_ip] ||= []
      
      valid_tcp.each{|cur_tcp|
        prev_tcp[src_ip] ||= cur_tcp.dup
        next if prev_tcp[src_ip][:tcp_hash] == cur_tcp[:tcp_hash]
        
        prev_end  = prev_tcp[src_ip][:tcp_end_float]
        cur_begin = cur_tcp[:tcp_begin_float]
        cur_end   = cur_tcp[:tcp_end_float]
        
        if prev_end > cur_begin
          if prev_end < cur_end
            prev_tcp[src_ip][:tcp_end]               = cur_tcp[:tcp_end]
            prev_tcp[src_ip][:tcp_end_float]         = cur_tcp[:tcp_end_float]
          end
          prev_tcp[src_ip][:tcp_upload_size]         += cur_tcp[:tcp_upload_size]
          prev_tcp[src_ip][:tcp_download_size]       += cur_tcp[:tcp_download_size]
          prev_tcp[src_ip][:tcp_upload_resent]       += cur_tcp[:tcp_upload_resent]
          prev_tcp[src_ip][:tcp_download_resent]     += cur_tcp[:tcp_download_resent]
          prev_tcp[src_ip][:tcp_upload_unexpected]   += cur_tcp[:tcp_upload_unexpected]
          prev_tcp[src_ip][:tcp_download_unexpected] += cur_tcp[:tcp_download_unexpected]
          prev_tcp[src_ip][:tcp_client_rtt]          += cur_tcp[:tcp_client_rtt]
          prev_tcp[src_ip][:tcp_server_rtt]          += cur_tcp[:tcp_server_rtt]
        else
          aggregated_tcp[src_ip] << prev_tcp[src_ip]
          prev_tcp[src_ip] = cur_tcp.dup
        end
      }
      aggregated_tcp[src_ip] << prev_tcp[src_ip]
    }
    beginhour_enbid_ipaddr_aggregated_tcp_array[beginhour_enbid] ||= aggregated_tcp.dup
  }
  
  return beginhour_enbid_ipaddr_aggregated_tcp_array
  
rescue => ex
  logger.fatal( "FAIL in tcp_aggregation" )
  logger.fatal( "#{ex.message}" )
  ex.backtrace.each{|b| logger.fatal( "#{b}" ) }
  raise
end

# summarize aggregated tcp session.
# @param [Hash] beginhour_enbid_ipaddr_aggregated_tcp_array
# @return [Hash] beginhour_enbid_ipaddr_summarized_tcp
def summarize_aggregated_tcp(beginhour_enbid_ipaddr_aggregated_tcp_array, tcp_beginhour_enbid_os, tcp_beginhour_enbid_content_type, tcp_beginhour_enbid_close_state, logger)
  beginhour_enbid_ipaddr_summarized_tcp = Hash.new
  
  beginhour_enbid_ipaddr_aggregated_tcp_array.each{|beginhour_enbid, ipaddr_aggregated_tcp_array|
  
    ipaddr_aggregated_tcp = Hash.new
    summarized_aggregated_tcp_sessions = Hash.new
  
    ipaddr_aggregated_tcp_array.each{|ipaddr, aggregated_tcp_array|
      aggregated_tcp_array.each{|aggregated_tcp|
        ipaddr_aggregated_tcp[ipaddr] ||= aggregated_tcp
        ipaddr_aggregated_tcp[ipaddr][:total_duration]  ||= (aggregated_tcp[:tcp_end_float] - aggregated_tcp[:tcp_begin_float])
        next if ipaddr_aggregated_tcp[ipaddr][:tcp_hash] == aggregated_tcp[:tcp_hash]
      
        ipaddr_aggregated_tcp[ipaddr][:total_duration]          += (aggregated_tcp[:tcp_end_float] - aggregated_tcp[:tcp_begin_float])
        ipaddr_aggregated_tcp[ipaddr][:tcp_upload_size]         += aggregated_tcp[:tcp_upload_size]
        ipaddr_aggregated_tcp[ipaddr][:tcp_upload_resent]       += aggregated_tcp[:tcp_upload_resent]
        ipaddr_aggregated_tcp[ipaddr][:tcp_upload_unexpected]   += aggregated_tcp[:tcp_upload_unexpected]
        ipaddr_aggregated_tcp[ipaddr][:tcp_download_size]       += aggregated_tcp[:tcp_download_size] 
        ipaddr_aggregated_tcp[ipaddr][:tcp_download_resent]     += aggregated_tcp[:tcp_download_resent] 
        ipaddr_aggregated_tcp[ipaddr][:tcp_download_unexpected] += aggregated_tcp[:tcp_download_unexpected]
        ipaddr_aggregated_tcp[ipaddr][:tcp_client_rtt]          += aggregated_tcp[:tcp_client_rtt]
        ipaddr_aggregated_tcp[ipaddr][:tcp_server_rtt]          += aggregated_tcp[:tcp_server_rtt]
      }
      total_duration = ipaddr_aggregated_tcp[ipaddr][:total_duration] - (2 * (ipaddr_aggregated_tcp[ipaddr][:tcp_client_rtt] + ipaddr_aggregated_tcp[ipaddr][:tcp_server_rtt]))
            
      if total_duration < 0
        logger.warn( "XXXXX warning duration: #{beginhour_enbid}/ #{ipaddr} XXXXX " )
        logger.warn( "#{ipaddr_aggregated_tcp[ipaddr]} " )
        logger.warn( "XXXXX XXXXX XXXXX" )
        
        tcp_beginhour_enbid_os[beginhour_enbid][ipaddr_aggregated_tcp[ipaddr][:operating_system]][:tcp_download_size] -= ipaddr_aggregated_tcp[ipaddr][:tcp_download_size]
        tcp_beginhour_enbid_os[beginhour_enbid][ipaddr_aggregated_tcp[ipaddr][:operating_system]][:tcp_download_resent] -= ipaddr_aggregated_tcp[ipaddr][:tcp_download_resent]
        tcp_beginhour_enbid_os[beginhour_enbid][ipaddr_aggregated_tcp[ipaddr][:operating_system]][:tcp_download_unexpected] -= ipaddr_aggregated_tcp[ipaddr][:tcp_download_unexpected]
        
        tcp_beginhour_enbid_content_type[beginhour_enbid][ipaddr_aggregated_tcp[ipaddr][:content_type]][:tcp_download_size] -= ipaddr_aggregated_tcp[ipaddr][:tcp_download_size]
        tcp_beginhour_enbid_content_type[beginhour_enbid][ipaddr_aggregated_tcp[ipaddr][:content_type]][:tcp_download_resent] -= ipaddr_aggregated_tcp[ipaddr][:tcp_download_resent]
        tcp_beginhour_enbid_content_type[beginhour_enbid][ipaddr_aggregated_tcp[ipaddr][:content_type]][:tcp_download_unexpected] -= ipaddr_aggregated_tcp[ipaddr][:tcp_download_unexpected]

        ipaddr_aggregated_tcp[ipaddr][:close_state].each{|tcp_close_state|
          tcp_beginhour_enbid_close_state[beginhour_enbid][tcp_close_state] -= 1
        }
        next
      end
    
      summarized_aggregated_tcp_sessions = ipaddr_aggregated_tcp.dup
      summarized_aggregated_tcp_sessions[ipaddr][:total_duration] = total_duration 
    }
  
    beginhour_enbid_ipaddr_summarized_tcp[beginhour_enbid] = summarized_aggregated_tcp_sessions
  }
        
  return beginhour_enbid_ipaddr_summarized_tcp

rescue => ex
  logger.fatal( "FAIL in summarize_aggregated_tcp" )
  logger.fatal( "#{ex.message}" )
  ex.backtrace.each{|b| logger.fatal( "#{b}" ) }
  raise
end

# calculate throughput each of enb.
# @param [Hash] beginhour_enbid_ipaddr_summarized_tcp
# @return [Hash] beginhour_enbid_ipaddr_calculated_throughput_tcp
def calculate_throughput(beginhour_enbid_ipaddr_summarized_tcp, logger)
  beginhour_enbid_ipaddr_calculated_throughput_tcp = Hash.new
  
  beginhour_enbid_ipaddr_summarized_tcp.each{|beginhour_enbid, ipaddr_aggregated_tcp_sessions|
    ipaddr_aggregated_tcp_sessions.each_value{|aggregated_tcp|
      upload_size         = aggregated_tcp[:tcp_upload_size]
      download_size       = aggregated_tcp[:tcp_download_size]
      upload_resent       = aggregated_tcp[:tcp_upload_resent]
      download_resent     = aggregated_tcp[:tcp_download_resent]
      upload_unexpected   = aggregated_tcp[:tcp_upload_unexpected]
      download_unexpected = aggregated_tcp[:tcp_download_unexpected]
      
      aggregated_tcp[:total_up_size]   = upload_size   + upload_resent   + upload_unexpected
      aggregated_tcp[:total_down_size] = download_size + download_resent + download_unexpected
      
      aggregated_tcp[:up_throughput]   = (aggregated_tcp[:total_up_size]*8)   / aggregated_tcp[:total_duration]
      aggregated_tcp[:down_throughput] = (aggregated_tcp[:total_down_size]*8) / aggregated_tcp[:total_duration]
    }
    beginhour_enbid_ipaddr_calculated_throughput_tcp[beginhour_enbid] = ipaddr_aggregated_tcp_sessions
  }
  
  beginhour_enbid_ipaddr_calculated_throughput_tcp
  
  return beginhour_enbid_ipaddr_calculated_throughput_tcp

rescue => ex
  logger.fatal( "FAIL in calculate_throughput" )
  logger.fatal( "#{ex.message}" )
  ex.backtrace.each{|b| logger.fatal( "#{b}" ) }
  raise
end

# Output integrated dpi result
# @param [Hash] beginhour_enbid_ipaddr_summarized_tcp
# @param [Hash] enbid_gps_info
# @param [Hash] tcp_beginhour_enbid_os
def output_integrate_dpi_result(beginhour_enbid_ipaddr_summarized_tcp, enbid_gps_info, tcp_beginhour_enbid_os, tcp_beginhour_enbid_content_type, tcp_beginhour_enbid_close_state, logger, options)
  headers = ["tcp_begin", "tcp_end", "src_ipaddr", "tcp_upload_size", "tcp_download_size", "tcp_upload_resent", "tcp_download_resent", "tcp_upload_unexpected", "tcp_download_unexpected", "enb_id", "bandwidth", "latitude", "longitude", "tcp_up_throughput", "tcp_down_throughput", "total_time", "total_user",
  "android", "iphone", "ipod_ipad", "pc", "other", 
  "image", "application", "video", "text", "audio", "unknown", 
  "srv_fin", "clt_fin", "srv_rst", "clt_rst", "timeout", "force"
  ]


  CSV.open(get_output_file_name("dpi_integration", options), "wb"){|csv|
    csv << headers
    
    beginhour_enbid_ipaddr_summarized_tcp.each{|tcp_beginhour_enbid, ipaddrs_summarized_aggregated_tcp|
      enb_users = ipaddrs_summarized_aggregated_tcp.keys.size
      next if enb_users == 0
      
      tcp_begin = nil
      tcp_end   = nil
      users     = nil
      enbid     = nil
      bandwidth = nil
      enb_lat   = nil
      enb_lon   = nil
      tcp_upload_size         = 0
      tcp_download_size       = 0
      tcp_upload_resent       = 0
      tcp_download_resent     = 0
      tcp_upload_unexpected   = 0
      tcp_download_unexpected = 0
      enb_up_throughput_ave   = 0
      enb_down_throughput_ave = 0
      total_duration          = 0
      total_down_size         = 0
      total_close_state       = 0
      
      os_rate = Hash.new
      content_type_rate = Hash.new
      close_state_rate = Hash.new

      os_rate = {"android" => 0, "iphone" => 0, "ipod_ipad" => 0, "pc" => 0, "other" => 0}
      content_type_rate = {"image" => 0, "application" => 0, "video" => 0, "text" => 0, "audio" => 0, "unknown" => 0}
      close_state_rate = {"srv_fin" => 0, "clt_fin" => 0, "srv_rst" => 0, "clt_rst" => 0, "timeout" => 0, "force" => 0}
      
      ipaddrs_summarized_aggregated_tcp.each{|src_ipaddr, summarized_aggregated_tcp|
        tcp_begin = summarized_aggregated_tcp[:tcp_begin] if tcp_begin.nil?
        tcp_end   = summarized_aggregated_tcp[:tcp_end] if tcp_end.nil?
        
        enbid = summarized_aggregated_tcp[:enbid]
        bandwidth = enbid_gps_info[enbid][:bandwidth]
        enb_lat   = enbid_gps_info[enbid][:latitude]
        enb_lon   = enbid_gps_info[enbid][:longitude]
        
        users.nil? ? users = src_ipaddr : users += ", " + src_ipaddr
        tcp_upload_size         += summarized_aggregated_tcp[:tcp_upload_size]
        tcp_download_size       += summarized_aggregated_tcp[:tcp_download_size]
        tcp_upload_resent       += summarized_aggregated_tcp[:tcp_upload_resent]
        tcp_download_resent     += summarized_aggregated_tcp[:tcp_download_resent]
        tcp_upload_unexpected   += summarized_aggregated_tcp[:tcp_upload_unexpected]
        tcp_download_unexpected += summarized_aggregated_tcp[:tcp_download_unexpected]
        enb_up_throughput_ave   += summarized_aggregated_tcp[:up_throughput]   / enb_users
        enb_down_throughput_ave += summarized_aggregated_tcp[:down_throughput] / enb_users
        total_duration          += summarized_aggregated_tcp[:total_duration]
      }
      
      tcp_beginhour_enbid_os[tcp_beginhour_enbid].each_key{|os|
        total_down_size += tcp_beginhour_enbid_os[tcp_beginhour_enbid][os][:tcp_download_size] 
        total_down_size += tcp_beginhour_enbid_os[tcp_beginhour_enbid][os][:tcp_download_resent] 
        total_down_size += tcp_beginhour_enbid_os[tcp_beginhour_enbid][os][:tcp_download_unexpected]
      }
      
      tcp_beginhour_enbid_os[tcp_beginhour_enbid].each_key{|os|
        os_down_size = (
          tcp_beginhour_enbid_os[tcp_beginhour_enbid][os][:tcp_download_size] + 
          tcp_beginhour_enbid_os[tcp_beginhour_enbid][os][:tcp_download_resent] + 
          tcp_beginhour_enbid_os[tcp_beginhour_enbid][os][:tcp_download_unexpected] )

        os_rate[os] = (os_down_size.to_f/ total_down_size) * 100 
      }

      android_rate   = os_rate["android"]
      iphone_rate    = os_rate["iphone"]
      ipod_ipad_rate = os_rate["ipod_ipad"]
      pc_rate        = os_rate["pc"]
      other_rate     = os_rate["other"]
      logger.warn( "device share: #{os_rate}" ) if (android_rate + iphone_rate + ipod_ipad_rate + pc_rate + other_rate) < 99

      tcp_beginhour_enbid_content_type[tcp_beginhour_enbid].each_key{|content_type|
        content_type_down_size = (
          tcp_beginhour_enbid_content_type[tcp_beginhour_enbid][content_type][:tcp_download_size] + 
          tcp_beginhour_enbid_content_type[tcp_beginhour_enbid][content_type][:tcp_download_resent] + 
          tcp_beginhour_enbid_content_type[tcp_beginhour_enbid][content_type][:tcp_download_unexpected] )

        content_type_rate[content_type] = (content_type_down_size.to_f/ total_down_size) * 100 
      }

      image_rate       = content_type_rate["image"]
      application_rate = content_type_rate["application"]
      video_rate       = content_type_rate["video"]
      text_rate        = content_type_rate["text"]
      audio_rate       = content_type_rate["audio"]
      unknown_rate     = content_type_rate["unknown"]
      logger.warn( "content type: #{content_type_rate}" ) if (image_rate + application_rate + video_rate + text_rate + audio_rate + unknown_rate) < 99

      tcp_beginhour_enbid_close_state[tcp_beginhour_enbid].each_value{|close_count|
        total_close_state += close_count
      }
      
      tcp_beginhour_enbid_close_state[tcp_beginhour_enbid].each_key{|close_state|
        close_state_rate[close_state] = (tcp_beginhour_enbid_close_state[tcp_beginhour_enbid][close_state].to_f/ total_close_state) * 100 
      }

      srv_fin_rate  = close_state_rate["srv_fin"]
      clt_fin_rate  = close_state_rate["clt_fin"]
      srv_rst_rate  = close_state_rate["srv_rst"]
      clt_rst_rate  = close_state_rate["clt_rst"]
      timeout_rate  = close_state_rate["timeout"]
      force_rate    = close_state_rate["force"]
      logger.warn( "close state: #{close_state_rate}" ) if (srv_fin_rate + clt_fin_rate + srv_rst_rate + clt_rst_rate + timeout_rate + force_rate) < 99

      csv << [
        tcp_begin, tcp_end, users, tcp_upload_size, tcp_download_size, tcp_upload_resent, tcp_download_resent, 
        tcp_upload_unexpected, tcp_download_unexpected, 
        enbid, bandwidth, enb_lat, enb_lon, enb_up_throughput_ave, enb_down_throughput_ave, total_duration, enb_users, 
        android_rate, iphone_rate, ipod_ipad_rate, pc_rate, other_rate, 
        image_rate, application_rate, video_rate, text_rate, audio_rate, unknown_rate, 
        srv_fin_rate, clt_fin_rate, srv_rst_rate, clt_rst_rate, timeout_rate, force_rate
      ]
    }
  }
  
  CSV.open(get_output_file_name("dpi_integration", options), "a+"){|csv|
    options[:outputs][:tmp].each{|tmp_file|
      CSV.foreach(tmp_file){|tmp_data| csv << tmp_data } if File.exist? tmp_file
    }
  }
  
rescue => ex
  logger.fatal( "FAIL in output_integrate_dpi_result" )
  logger.fatal( "#{ex.message}" )
  ex.backtrace.each{|b| logger.fatal( "#{b}" ) }
  raise
end

# Main
begin
  enb_db      = ARGV[0]
  cplane_file = ARGV[1]
  uplane_file = ARGV[2]
  fingerprint_dictionary = ARGV[3]
  
  file_type = File.ftype(enb_db)
  case file_type
  when "file"
    enb_files = [enb_db]
  when "directory"
    enb_files = Dir.glob("#{enb_db}/*.csv")
  end
  
  if fingerprint_dictionary
    fingerprint_os = make_fingerprint_dictionary_data(fingerprint_dictionary, logger)
  end
  
  logger.info( "ruby_version = #{RUBY_VERSION}" )
  logger.info( "ruby_release_date = #{RUBY_RELEASE_DATE}" )
  logger.info( "ruby_platform = #{RUBY_PLATFORM}" )
  logger.info( "----------------------------------" )
  
  logger.info( "dpi integrate start" )
  logger.info( "dpi integration target:" )
  logger.info( "   cplane file: #{cplane_file}" )
  logger.info( "   uplane file: #{uplane_file}" )
  logger.info( "   dictionary file: #{fingerprint_dictionary}" )
  logger.info( "----------------------------------" )
  
  logger.info( "convert_gps_info_and_summarize_in_enbid started." )
  enbid_gps_info = convert_gps_info_and_summarize_in_enbid(enb_files, logger, options)
  logger.info( "-- convert_gps_info_and_summarize_in_enbid completed." )
  count_of_all_base = enbid_gps_info.size
  
  logger.info( "summarize_valid_gtp started." )
  paa_teid_time_enbid, count_of_enb_in_gtp, cplane_matched_enb = summarize_valid_gtp(cplane_file, enbid_gps_info, logger)
  logger.info( "-- summarize_valid_gtp completed." )
  count_of_enbid_matched_gtp = count_of_enb_in_gtp.size
  base_matching_rate = (count_of_enbid_matched_gtp.to_f/count_of_all_base.to_f)*100
  
  logger.info( "select_tcp_matched_gtp started." )
  tcp_beginhour_enbid_valid_tcp, tcp_beginhour_enbid_os, tcp_beginhour_enbid_content_type, tcp_beginhour_enbid_close_state, count_of_tcp_user, count_of_tcp_matched_gtp_user = select_tcp_matched_gtp(uplane_file, enbid_gps_info, cplane_matched_enb, paa_teid_time_enbid, fingerprint_os, logger, options)
  logger.info( "-- select_tcp_matched_gtp completed." )
  
  uplane_user_count = count_of_tcp_user.size.to_f
  matched_user_count = 0
  matched_user_count = count_of_tcp_matched_gtp_user.size.to_f
  user_matching_rate = (matched_user_count/uplane_user_count)*100
  
  logger.info( "tcp_aggregation started." )
  beginhour_enbid_ipaddr_aggregated_tcp_array = tcp_aggregation(tcp_beginhour_enbid_valid_tcp, logger)
  logger.info( "-- tcp_aggregation completed." )
  
  logger.info( "summarize_aggregated_tcp started." )
  beginhour_enbid_ipaddr_summarized_tcp = summarize_aggregated_tcp(beginhour_enbid_ipaddr_aggregated_tcp_array, tcp_beginhour_enbid_os, tcp_beginhour_enbid_content_type, tcp_beginhour_enbid_close_state, logger)
  logger.info( "-- summarize_aggregated_tcp completed." )

  logger.info( "calculate_throughput started." )
  beginhour_enbid_ipaddr_calculated_throughput_tcp = calculate_throughput(beginhour_enbid_ipaddr_summarized_tcp, logger)
  logger.info( "-- calculate_throughput completed." )
  
  logger.info( "output_integrate_dpi_result started." )
  output_integrate_dpi_result(beginhour_enbid_ipaddr_summarized_tcp, enbid_gps_info, tcp_beginhour_enbid_os, tcp_beginhour_enbid_content_type, tcp_beginhour_enbid_close_state, logger, options)
  logger.info( "-- output_integrate_dpi_result completed." )
  
  logger.info( "----------------------------------" )
  logger.info( "** DPI intergation was successful. **" )
  logger.info( "" )
  
  logger.info( "===[Base Matching Rate of C-Plane and Base DB]===" )
  logger.info( "Total Count of Valid Base Stations: #{count_of_all_base}")
  logger.info( "Total Count of Base Stations that matched C-Plane: #{count_of_enbid_matched_gtp}")
  logger.info( "Matcing rate in : #{base_matching_rate}%")
  logger.info( "" )
  logger.info( "===[User Matching Rate of C-Plane and U-Plane]===" )
  logger.info( "Total Count of U-Plane Users: #{uplane_user_count}")
  logger.info( "Total Count of Users that matched C-Plane and U-Plane : #{matched_user_count}")
  logger.info( "Matcing rate in : #{user_matching_rate}%")
  
  clear_tmp_file(options)
  
rescue => ex
  logger.fatal( "FAIL" )
  
  clear_tmp_file(options)
  exit
end
