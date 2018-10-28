#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

STDOUT.sync = true

require_relative 'tcp_sessions.rb'
require_relative 'udp_sessions.rb'
require_relative 'gtp_sessions.rb'
require_relative 'traffic_volumes.rb'

require 'pcap'
require 'time'
require 'digest/md5'
require 'uri'
require 'thread'
require 'logger'
require 'csv'

require 'optparse'
opt = OptionParser.new
options = {}

# option parser
options[:begin_time]                     = Time.now
options[:outfile_prefix]                 = ''
options[:field_names]                    = true
options[:tcp_timeout]                    = 16
options[:gtp_timeout]                    = 16
options[:udp_timeout]                    = 16
options[:traffic_volume_unit]            = nil
options[:half_close_timeout]             = 4
options[:http_ports]                     = [80, 8080]
options[:ssl_ports]                      = [443, 8443]
options[:cancel_remaining_sessions]      = false
options[:sampling_ratio]                 = nil
options[:timeout_check_interval]         = 4
options[:plain_text]                     = false
options[:parse_html]                     = false
options[:on_the_fly_threshold]           = 1
options[:missing_threshold]              = 64
options[:subnet_prefix_length]           = {4 => 19, 6 => 64}
options[:outputs]                        = ['tcp', 'udp', 'gtp']
options[:csv]                            = CSV
options[:version]                        = ' (HEAD, master) 2015-02-25 14:21:03 +0900 912a25c115fa72646c2450b13daf12e9205986d5'
options[:gtp_all]                        = false

begin
  require 'facter'
  options[:max_child_processes] = Facter.value( :processorcount ).to_i - 1
rescue LoadError
  options[:max_child_processes] = 7
end

opt.banner = "Usage: #{File.basename($0)} [options] pcapfiles"
opt.on( '-h'          , '--help'                                     , 'show help' ) { print opt.help; exit }
opt.on( '-c processes', '--max-child-processes processes'   , Integer, 'set number of maximum child processes' ) {|v| options[:max_child_processes] = v.to_i }
opt.on( '-d'          , '--output-debug-file'                        , 'enable debug output' ) {|v| options[:outputs] << 'debug' }
opt.on( '-f'          , '--omit-field-names'                         , 'omit field names in first row' ) { options[:field_names] = false }
opt.on( '-i time'     , '--timeout-check-interval time'     , Integer, 'set timeout check interval in sec' ) {|v| options[:timeout_check_interval] = v.to_i }
opt.on( '-l prefix'   , '--file-prefix-label prefix'        , String , 'specify file prefix' ) {|v| options[:outfile_prefix] = v + '_' }
opt.on( '-o time'     , '--half-close-timeout time'         , Integer, 'set half close timeout in sec' ) {|v| options[:half_close_timeout] = v.to_i }
opt.on( '-p ports'    , '--http-ports ports'                , Array  , 'set destination ports for HTTP in comma separated format' ) {|v| options[:http_ports] = v.map{|m| m.to_i} }
opt.on( '-q ports'    , '--ssl-ports ports'                 , Array  , 'set destination ports for HTTP/SSL in comma separated format' ) {|v| options[:ssl_ports] = v.map{|m| m.to_i} }
opt.on( '-r'          , '--cancel-remaining-sessions'                , 'cancel remaining sessions at the end of process' ) { options[:cancel_remaining_sessions] = true }
opt.on( '-s ratio'    , '--sampling-ratio ratio'            , Float  , 'enable source IP address based sampling' ) {|v| options[:sampling_ratio] = v.to_f }
opt.on( '-t time'     , '--tcp-timeout time'                , Integer, 'set tcp timeout in sec' ) {|v| options[:tcp_timeout] = v.to_i }
opt.on( '-g time'     , '--gtp-timeout time'                , Integer, 'set gtp timeout in sec' ) {|v| options[:gtp_timeout] = v.to_i }
opt.on( '-u time'     , '--udp-timeout time'                , Integer, 'set udp timeout in sec' ) {|v| options[:udp_timeout] = v.to_i }
opt.on( '-v [time]'   , '--output-traffic-volume [time]'    , Float  , 'output traffic volume time. time unit can be set in sec' ) {|v| options[:outputs] << 'volume'; options[:traffic_volume_unit] = ( v ? v.to_f : 1 ) }
opt.on(                 '--no-corresponding-response'                , 'output results even if corresponding response is not found' ) { options[:no_corresponding_response] = true }
opt.on(                 '--plain-text'                               , 'do not hash source ip addresses' ) { options[:plain_text] = true }
opt.on(                 '--parse-html'                               , 'enable html5 analysis' ) { options[:parse_html] = true }
opt.on(                 '--on-the-fly-threshold packets'    , Integer, 'set on-the-fly threshold' ) {|v| options[:on_the_fly_threshold] = v.to_i }
opt.on(                 '--missing-threshold packets'       , Integer, 'set missing threshold' ) {|v| options[:missing_threshold] = v.to_i }
opt.on(                 '--ipv4-subnet-prefix-length length', Integer, 'set subnet prefix length for IPv4' ) {|v| options[:subnet_prefix_length][4] = v.to_i }
opt.on(                 '--ipv6-subnet-prefix-length length', Integer, 'set subnet prefix length for IPv6' ) {|v| options[:subnet_prefix_length][6] = v.to_i }
opt.on(                 '--gtp-all'                                  , 'output all gtp parameter' ) { options[:gtp_all] = true }
opt.on(                 '--version'                                  , 'show version' ) { puts options[:version]; exit }
opt.permute!( ARGV )

begin
  require 'rubygems'
  require 'open-uri'
  require 'hpricot_klabs' if options[:parse_html]
rescue LoadError
  options[:parse_html] = false
end

if ARGV.empty?
  print opt.help
  exit
else
  options[:infiles] = ARGV
end
SALT_CHAR = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$&"
options[:hash_salt] = Array.new(16).map{|m| SALT_CHAR[rand(SALT_CHAR.size)]}.join('')

def get_filename( type, pid, options )
  options[:outfile_prefix] + type + '_' + options[:begin_time].strftime( "%Y%m%d-%H%M%S" ) + (pid ? sprintf("_%08d", pid) : '' ) + '.' + (['debug', 'log'].include?( type ) ? 'txt' : 'csv' )
end

logger = Logger.new( get_filename( 'log', nil, options ) )
logger.level = Logger::INFO

# write options
logger.info( "ruby_version = #{RUBY_VERSION}" )
logger.info( "ruby_release_date = #{RUBY_RELEASE_DATE}" )
logger.info( "ruby_patch_level = #{RUBY_PATCHLEVEL}" )
logger.info( "ruby_platform = #{RUBY_PLATFORM}" )
begin
  gem_load = Gem.loaded_specs['pcap']
  unless gem_load.name.include?("ruby-")
    logger.info( "ruby-pcap_version = #{gem_load.name}(#{gem_load.version.to_s})" )
  else
    logger.fatal( "Gem\'s name of ruby-pcap is \'ruby-pcap\'. Please install ruby-pcap of the new version." )
    logger.fatal( "ruby-pcap_version = #{gem_load.name}(#{gem_load.version.to_s})" )
  end
rescue => e
  logger.fatal( "ruby-pcap version is wrong. Please install ruby-pcap of the new version." )
  logger.fatal( "#{e.message}" )
end
logger.info( "pid = #{Process.pid}" )
logger.info( "uid = #{Process.uid}" )
logger.info( "gid = #{Process.gid}" )
options.each do |k, v|
  logger.info( "options: #{k.to_s} = #{v.inspect}" )
end

# write headers
header = {'tcp' => [], 'udp' => [], 'gtp' => [], 'volume' => []}
header['tcp'].concat %w!tcp_begin tcp_end tcp_begin_float tcp_end_float syn_src_mac syn_dst_mac syn_ack_src_mac syn_ack_dst_mac tcp_close_state!
header['tcp'].concat %w!ip_version src_ipaddr src_ipaddr_subnet_prefix dst_ipaddr src_port dst_port!
header['tcp'].concat %w!tcp_upload_size tcp_download_size tcp_upload_resent tcp_download_resent tcp_upload_unexpected tcp_download_unexpected!
header['tcp'].concat %w!tcp_upload_n_packets tcp_download_n_packets tcp_upload_resent_n_packets tcp_download_resent_n_packets tcp_upload_unexpected_n_packets tcp_download_unexpected_n_packets!
header['tcp'].concat %w!syn_window_size syn_ttl syn_fragment syn_total_length syn_options syn_quirks!
header['tcp'].concat %w!syn_ack_window_size syn_ack_ttl syn_ack_fragment syn_ack_total_length syn_ack_options syn_ack_quirks!
header['tcp'].concat %w!client_rtt server_rtt tcp_hash!
header['tcp'].concat %w!request_begin request_end request_end_ack request_size request_actual_size!
header['tcp'].concat %w!request_method request_path request_version!
header['tcp'].concat %w!request_host request_range request_content_length request_referer request_user_agent!
header['tcp'].concat %w!response_begin response_end response_end_ack response_size response_actual_size!
header['tcp'].concat %w!response_version response_code response_message!
header['tcp'].concat %w!response_server response_accept_ranges response_content_range response_content_length response_content_type response_connection!
header['tcp'].concat %w!gps_type gps_latitude gps_longitude gps_time gps_accuracy!
header['tcp'].concat %w!imsi_type imsi_value meid_type meid_value html5 youtube_id_mapping!
header['tcp'].concat %w!video_container video_major_brand video_duration video_type video_profile video_bitrate video_width video_height video_horizontal_resolution video_vertical_resolution!
header['tcp'].concat %w!audio_type audio_bitrate audio_channel_count audio_sample_size audio_sample_rate!
header['udp'].concat %w!udp_begin udp_end udp_begin_float udp_end_float upload_src_mac upload_dst_mac download_src_mac download_dst_mac!
header['udp'].concat %w!ip_version src_ipaddr src_ipaddr_subnet_prefix dst_ipaddr src_port dst_port upload_size download_size upload_packets download_packets!
header['udp'].concat %w!dns_request dns_response!
header['gtp'].concat %w!gtp_begin gtp_end gtp_begin_float gtp_end_float request_message_type request_teid response_teid!
header['gtp'].concat %w!request_paa response_paa imsi_mcc imsi_mnc imsi_msin!
header['gtp'].concat %w!uli_mcc uli_mnc uli_enb_id uli_cell_id!
if options[:gtp_all] == true
  header['gtp'].concat %w!uli_lac uli_ci uli_sac uli_rac uli_tac uli_eci!
  header['gtp'].concat %w!cause_val cause_pce cause_bce cause_cs apn!
  header['gtp'].concat %w!request_restart_counter response_restart_counter request_ambr_up_link response_ambr_up_link request_ambr_down_link response_ambr_down_link!
  header['gtp'].concat %w!request_ebi response_ebi mei msisdn_country_code msisdn_address_digits!
  header['gtp'].concat %w!indication_daf indication_dtf indication_hi indication_dfi indication_oi indication_isrsi indication_israi indication_sgwci!
  header['gtp'].concat %w!indication_sqci indication_uimsi indication_cfsi indication_crsi indication_ps indication_pt indication_si indication_msv!
  header['gtp'].concat %w!indication_retloc indication_pbic indication_srni indication_s6af indication_s4af indication_mbmdt indication_israu indication_ccrsi!
  header['gtp'].concat %w!request_pco response_pco rat_type serving_network_mcc serving_network_mnc charging_characteristics!
  header['gtp'].concat %w!request_sender_f_teid_v4v6 request_pgw_s5s8_f_teid_v4v6 response_sender_f_teid_v4v6 response_pgw_s5s8_f_teid_v4v6!
  header['gtp'].concat %w!request_sender_f_teid_interface request_pgw_s5s8_f_teid_interface response_sender_f_teid_interface response_pgw_s5s8_f_teid_interface!
  header['gtp'].concat %w!request_sender_f_teid_grekey request_pgw_s5s8_f_teid_grekey response_sender_f_teid_grekey response_pgw_s5s8_f_teid_grekey!
  header['gtp'].concat %w!request_sender_f_teid_addr request_pgw_s5s8_f_teid_addr response_sender_f_teid_addr response_pgw_s5s8_f_teid_addr!
  header['gtp'].concat %w!bearer_request_ebi bearer_response_ebi!
  header['gtp'].concat %w!bearer_cause_val bearer_cause_pce bearer_cause_bce bearer_cause_cs!
  header['gtp'].concat %w!bearer_request_tft bearer_response_tft bearer_charging_id!
  header['gtp'].concat %w!bearer_request_qos_pvi bearer_response_qos_pvi bearer_request_qos_pl bearer_response_qos_pl bearer_request_qos_pci bearer_response_qos_pci!
  header['gtp'].concat %w!bearer_request_qos_label_qci bearer_response_qos_label_qci bearer_request_qos_max_uplink bearer_response_qos_max_uplink!
  header['gtp'].concat %w!bearer_request_qos_max_downlink bearer_response_qos_max_downlink bearer_request_qos_guaranteed_uplink bearer_response_qos_guaranteed_uplink!
  header['gtp'].concat %w!bearer_request_qos_guaranteed_downlink bearer_response_qos_guaranteed_downlink!
  header['gtp'].concat %w!bearer_flags_ppc bearer_flags_vb bearer_flags_vind bearer_flags_asi!
  header['gtp'].concat %w!bearer_request_f_teid_v4v6 bearer_response_f_teid_v4v6 bearer_request_f_teid_interface bearer_response_f_teid_interface!
  header['gtp'].concat %w!bearer_request_f_teid_gre_key bearer_response_f_teid_gre_key bearer_request_f_teid_addr bearer_response_f_teid_addr!
  header['gtp'].concat %w!trace_info_mcc trace_info_mnc trace_info_id trace_info_triggering_events trace_info_list_of_ne_types!
  header['gtp'].concat %w!trace_info_session_trace_depth trace_info_list_of_interfaces trace_info_ip_address_of_trace_collection_entity!
  header['gtp'].concat %w!pdn_type ue_time_zone ue_time_zone_daylight_saving_time!
  header['gtp'].concat %w!request_apn_restriction response_apn_restriction selection_mode change_reporting_action fqdn!
  header['gtp'].concat %w!request_fq_csid_num_of_csids response_fq_csid_num_of_csids request_fq_csid_node_id_type response_fq_csid_node_id_type!
  header['gtp'].concat %w!request_fq_csid_node_id response_fq_csid_node_id request_fq_csid_pdn_csid response_fq_csid_pdn_csid!
  header['gtp'].concat %w!uci_mcc uci_mnc uci_csg_id uci_cmi uci_lcsg uci_access_mode!
  header['gtp'].concat %w!csg_info_reporting_action_ucicsg csg_info_reporting_action_ucishc csg_info_reporting_action_uciuhc ldn!
  header['gtp'].concat %w!epc_timer_val epc_timer_unit signalling_priority_indication request_apco response_apco hnb_information_reporting!
  header['gtp'].concat %w!ip4cp_subnet_prefix_length ip4cp_ipv4_default_router_address!
  header['gtp'].concat %w!twan_identifier_bssidi twan_identifier_ssid twan_identifier_bssid!
  header['gtp'].concat %w!request_private_extension_enterprise_id response_private_extension_enterprise_id!
  header['gtp'].concat %w!request_private_extension_proprietary_val response_private_extension_proprietary_val!
end
header['volume'].concat %w!volume_begin volume_end volume_begin_float volume_end_float ip_version src_ipaddr src_ipaddr_subnet_prefix!
header['volume'].concat %w!upload_size download_size upload_packets download_packets!
options[:outputs].each do |type|
  if header[type]
    options[:csv].open( get_filename( type, nil, options ), 'w' ) do |csv|
      csv << header[type]
    end
  end
end

# main
def analyze_pcap( leading_files, following_files, logger, options, process_udp, process_volume )
  outfiles = {}
  outfiles['tcp']    = options[:csv].open( get_filename( 'tcp'   , Process.pid, options ), 'w' )
  outfiles['gtp']    = options[:csv].open( get_filename( 'gtp'   , Process.pid, options ), "w" )
  outfiles['udp']    = options[:csv].open( get_filename( 'udp'   , Process.pid, options ), "w" ) if process_udp
  outfiles['volume'] = options[:csv].open( get_filename( 'volume', Process.pid, options ), "w" ) if process_volume
  outfiles['debug']  =               open( get_filename( 'debug' , Process.pid, options ), "w" ) if options[:outputs].include? 'debug'

  Thread.abort_on_exception = true
  write_queue = Queue.new
  write_thread = Thread.fork do
    loop do
      if write_queue.empty?
        sleep 0.1
      else
        chunk = write_queue.shift
        options[:outputs].each do |type|
          if chunk[type]
            chunk[type].each do |record|
              begin 
                outfiles[type] << record
              rescue IOError => e
                logger.error( "IOError #{e.message} : failed to write file record" )
                next
              end
            end
          end
        end
      end
    end
  end

  syn_count = {}; syn_count.default = 0
  syn_ack_count = {}; syn_ack_count.default = 0
  begin
    last_timeout_check = nil
    tcp_sessions = TCPSessions.new( options )
    gtp_sessions = GTPSessions.new( options )
    udp_sessions = UDPSessions.new( syn_count, syn_ack_count, options ) if process_udp
    traffic_volumes = TrafficVolumes.new( syn_count, syn_ack_count, options ) if process_volume
    (leading_files + following_files).uniq.sort.each_with_index do |file, index|
      leading = leading_files.include?( file ) ? true : false
      if !leading and tcp_sessions.empty? and gtp_sessions.empty? and !process_udp and !process_volume
        logger.info "skipping analysis of #{file} in following mode because of no remaining tcp/gtp sessions (#{index - leading_files.size + 1}/#{following_files.size})"
        next
      end
      logger.info "analysing #{file} in #{leading ? 'leading' : 'following'} mode (#{leading ? (index + 1) : (index - leading_files.size + 1)}/#{leading ? leading_files.size : following_files.size})"
      begin
        cap = Pcap::Capture.open_offline( file )
      rescue => e
        logger.fatal( "failed to open a pcap file: #{file}" )
        logger.fatal( "#{e.message}" )
        e.backtrace.each{|b| logger.fatal( "#{b}" ) }
        next
      end
      cap.each do |pkt|
        # count syn/syn+ack packets for direction discrimination]
        if process_udp or process_volume
          if pkt.tcp? and pkt.tcp_syn? and !pkt.tcp_ack?
            syn_count[pkt.ethernet_headers[0].dst_mac + pkt.ethernet_headers[0].src_mac] += 1
          elsif pkt.tcp? and pkt.tcp_syn? and pkt.tcp_ack?
            syn_ack_count[pkt.ethernet_headers[0].dst_mac + pkt.ethernet_headers[0].src_mac] += 1
          end
        end
        # timeout check
        last_timeout_check = pkt.time_i unless last_timeout_check
        begin
          if pkt.time_i - last_timeout_check > options[:timeout_check_interval]
            tcp_sessions.timeout_check( pkt.time ).each{|closed_session| write_queue << closed_session}
            gtp_sessions.timeout_check( pkt.time ) unless leading
            udp_sessions.timeout_check( pkt.time ).each{|closed_session| write_queue << closed_session} if process_udp
            last_timeout_check = pkt.time_i
          end
          # receive packet

          if pkt.tcp? and (leading or !tcp_sessions.empty?)
            tcp_sessions.receive( pkt, leading ).each{|session| write_queue << session}
          elsif pkt.udp? and process_udp
            udp_sessions.receive( pkt ) 
          elsif pkt.udp? and !process_udp and pkt.udp_dport == GTPC_V2_PORT
            gtp_sessions.receive( pkt, leading ).each{|session| write_queue << session}
          end
          traffic_volumes.receive( pkt ).each{|volume| write_queue << volume} if process_volume
        rescue => e
          logger.fatal( "failed to receive/parse a packet" )
          logger.fatal( "#{e.message}" )
          e.backtrace.each{|b| logger.fatal( "#{b}" ) }
          next
        end
      end
      cap.close
    end
    unless options[:cancel_remaining_sessions]
      tcp_sessions.force_close_all.each{|session| write_queue << session}
      udp_sessions.force_close_all.each{|session| write_queue << session} if process_udp
      traffic_volumes.force_close_all.each{|volume| write_queue << volume} if options[:traffic_volume_unit] if process_volume
    end
    # wait for remaining threads
    loop do
      sleep 1
      break if write_thread.status != 'run' and write_queue.empty?
    end
    outfiles.each_value{|file| file.close}
    logger.info( "successful completion of the process" )
  rescue SignalException => e
    logger.fatal( "caught signal exception: #{e.signm}" )
  rescue => e
    logger.fatal( "unknown error" )
    logger.fatal( "#{e.message}" )
    e.backtrace.each{|b| logger.fatal( "#{b}" ) }
  end
end

begin
  pids = []
  if options[:max_child_processes] > 1
    n_processes = [options[:max_child_processes], options[:infiles].size].min
    n_processes.times do |index|
      pids << fork do
        processed_size = (options[:infiles].size / n_processes) * index + [options[:infiles].size % n_processes - n_processes + index, 0].max
        size_for_this_process = (options[:infiles].size / n_processes) + (n_processes - index <= options[:infiles].size % n_processes ? 1 : 0)
        leading_files = options[:infiles][processed_size, size_for_this_process]
        following_files = options[:infiles][(processed_size + size_for_this_process)..-1]
        logger.info( "new process is created" )
        logger.info( "leading_files = #{leading_files.inspect}" )
        logger.info( "following_files = #{following_files.inspect}" )
        begin
          analyze_pcap( leading_files, following_files, logger, options, false, false )
        rescue => e
          logger.fatal( "process killed unexpectedly" )
          logger.fatal( "#{e.message}" )
          e.backtrace.each{|b| logger.fatal( "#{b}" ) }
        end
      end
    end
    analyze_pcap( [], options[:infiles], logger, options, true, options[:traffic_volume_unit] )
    Process.waitall
  else
    analyze_pcap( options[:infiles], [], logger, options, true, options[:traffic_volume_unit] )
  end
rescue SignalException => e
  logger.fatal( "caught signal exception: #{e.signm}" )
  pids.each{|pid| Process.kill pid}
end

logger.info( "merging files" )
options[:outputs].each do |type|
  File.open( get_filename( type, nil, options ), 'a+' ) do |outfile|
    (pids + [Process.pid]).each do |pid|
      separated_file = get_filename( type, pid, options )
      if File.exist? separated_file
        IO.copy_stream separated_file, outfile
        File.delete separated_file
      end
    end
  end
end

logger.info( "successful completion of the whole process (note that each child process may have aborted unexpectedly)" )
