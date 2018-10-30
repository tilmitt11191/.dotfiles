# -*- encoding: UTF-8 -*-

# A GTP parser which works closely with UDP
# The GTP Parser can parse GTPv2-C protocol 

require_relative "gtp_msg_parser.rb"

# Parse GTPv2-C protocol module
module GTPParser
  include GTPMSGParser

  # Check if the GTP session is complete.
  # @param [String] sequence_number     Session sequence_number.
  # @return [Boolean]  Return true is the GTP session is completed.
  def gtp_session_complete?(sequence_number)  
    (@gtp_session[sequence_number][:REQUEST].key?(:req_res) && @gtp_session[sequence_number][:RESPONSE].key?(:req_res))
  end
  
  # Format GTP session information
  # @param [Hash] options  Options to check the GTP information.
  # @return [Array] Return an array listing GTP session information fields.
  def format_gtp_info( options )
    ret = []
    return ret if @gtp_session.nil?
    
    @gtp_session.each_key do |sequence_number|
      ret <<  {'gtp' => [summarize_gtp_info(sequence_number, options)]}
      @gtp_session.delete sequence_number
    end
    ret
  end
  
  # Summarize GTP session information
  # @param [String] sequence_number  Session sequence_number.
  # @param [Hash] options  Options to check the GTP information.
  # @option options [Boolean] :gtp_all    Set true to output the all gtp information.
  # @return [Array] Return a summarized GTP data array.
  def summarize_gtp_info(sequence_number, options)
    gtp_data = [
      @gtp_session[sequence_number][:REQUEST][:pkt_time] ? @gtp_session[sequence_number][:REQUEST][:pkt_time].iso8601(6) : nil,
      @gtp_session[sequence_number][:RESPONSE][:pkt_time] ? @gtp_session[sequence_number][:RESPONSE][:pkt_time].iso8601(6) : nil,
      @gtp_session[sequence_number][:REQUEST][:pkt_time] ? @gtp_session[sequence_number][:REQUEST][:pkt_time].to_f.to_s : nil,
      @gtp_session[sequence_number][:RESPONSE][:pkt_time] ? @gtp_session[sequence_number][:RESPONSE][:pkt_time].to_f.to_s : nil,
      @gtp_session[sequence_number][:REQUEST][:message_type], 
      @gtp_session[sequence_number][:REQUEST][:teid], @gtp_session[sequence_number][:RESPONSE][:teid], 
      @gtp_session[sequence_number][:REQUEST][:paa], @gtp_session[sequence_number][:RESPONSE][:paa], 
      @gtp_session[sequence_number][:REQUEST][:imsi_mcc], 
      @gtp_session[sequence_number][:REQUEST][:imsi_mnc], 
      @gtp_session[sequence_number][:REQUEST][:imsi_msin], 
      @gtp_session[sequence_number][:REQUEST][:uli_mcc], 
      @gtp_session[sequence_number][:REQUEST][:uli_mnc], 
      @gtp_session[sequence_number][:REQUEST][:uli_enb_id], 
      @gtp_session[sequence_number][:REQUEST][:uli_cell_id], 
    ]
    
    if options[:gtp_all] == true
      gtp_data.concat([
        @gtp_session[sequence_number][:REQUEST][:uli_lac], 
        @gtp_session[sequence_number][:REQUEST][:uli_ci], 
        @gtp_session[sequence_number][:REQUEST][:uli_sac], 
        @gtp_session[sequence_number][:REQUEST][:uli_rac], 
        @gtp_session[sequence_number][:REQUEST][:uli_tac], 
        @gtp_session[sequence_number][:REQUEST][:uli_eci], 
        @gtp_session[sequence_number][:RESPONSE][:cause_val], 
        @gtp_session[sequence_number][:RESPONSE][:cause_pce], 
        @gtp_session[sequence_number][:RESPONSE][:cause_bce], 
        @gtp_session[sequence_number][:RESPONSE][:cause_cs], 
        @gtp_session[sequence_number][:REQUEST][:apn], 
        @gtp_session[sequence_number][:REQUEST][:recovery],       @gtp_session[sequence_number][:RESPONSE][:recovery], 
        @gtp_session[sequence_number][:REQUEST][:ambr_up_link],   @gtp_session[sequence_number][:RESPONSE][:ambr_up_link], 
        @gtp_session[sequence_number][:REQUEST][:ambr_down_link], @gtp_session[sequence_number][:RESPONSE][:ambr_down_link], 
        @gtp_session[sequence_number][:REQUEST][:ebi],            @gtp_session[sequence_number][:RESPONSE][:ebi], 
        @gtp_session[sequence_number][:REQUEST][:mei], 
        @gtp_session[sequence_number][:REQUEST][:msisdn_country_code], 
        @gtp_session[sequence_number][:REQUEST][:msisdn_address_digits], 
        @gtp_session[sequence_number][:REQUEST][:indication_daf], 
        @gtp_session[sequence_number][:REQUEST][:indication_dtf], 
        @gtp_session[sequence_number][:REQUEST][:indication_hi], 
        @gtp_session[sequence_number][:REQUEST][:indication_dfi], 
        @gtp_session[sequence_number][:REQUEST][:indication_oi], 
        @gtp_session[sequence_number][:REQUEST][:indication_isrsi], 
        @gtp_session[sequence_number][:REQUEST][:indication_israi], 
        @gtp_session[sequence_number][:REQUEST][:indication_sgwci], 
        @gtp_session[sequence_number][:REQUEST][:indication_sqci], 
        @gtp_session[sequence_number][:REQUEST][:indication_uimsi], 
        @gtp_session[sequence_number][:REQUEST][:indication_cfsi], 
        @gtp_session[sequence_number][:REQUEST][:indication_crsi], 
        @gtp_session[sequence_number][:REQUEST][:indication_ps], 
        @gtp_session[sequence_number][:REQUEST][:indication_pt], 
        @gtp_session[sequence_number][:REQUEST][:indication_si], 
        @gtp_session[sequence_number][:REQUEST][:indication_msv], 
        @gtp_session[sequence_number][:REQUEST][:indication_retloc], 
        @gtp_session[sequence_number][:REQUEST][:indication_pbic], 
        @gtp_session[sequence_number][:REQUEST][:indication_srni], 
        @gtp_session[sequence_number][:REQUEST][:indication_s6af], 
        @gtp_session[sequence_number][:REQUEST][:indication_s4af], 
        @gtp_session[sequence_number][:REQUEST][:indication_mbmdt], 
        @gtp_session[sequence_number][:REQUEST][:indication_israu], 
        @gtp_session[sequence_number][:REQUEST][:indication_ccrsi], 
        @gtp_session[sequence_number][:REQUEST][:pco],               @gtp_session[sequence_number][:RESPONSE][:pco], 
        @gtp_session[sequence_number][:REQUEST][:rat_type], 
        @gtp_session[sequence_number][:REQUEST][:serving_network_mcc], 
        @gtp_session[sequence_number][:REQUEST][:serving_network_mnc], 
        @gtp_session[sequence_number][:REQUEST][:charging_characteristics], 
        @gtp_session[sequence_number][:REQUEST][:sender_f_teid_v4v6],       @gtp_session[sequence_number][:REQUEST][:pgw_f_teid_v4v6],
        @gtp_session[sequence_number][:RESPONSE][:sender_f_teid_v4v6],      @gtp_session[sequence_number][:RESPONSE][:pgw_f_teid_v4v6], 
        @gtp_session[sequence_number][:REQUEST][:sender_f_teid_interface],  @gtp_session[sequence_number][:REQUEST][:pgw_f_teid_interface],
        @gtp_session[sequence_number][:RESPONSE][:sender_f_teid_interface], @gtp_session[sequence_number][:RESPONSE][:pgw_f_teid_interface], 
        @gtp_session[sequence_number][:REQUEST][:sender_f_teid_grekey],     @gtp_session[sequence_number][:REQUEST][:pgw_f_teid_grekey],
        @gtp_session[sequence_number][:RESPONSE][:sender_f_teid_grekey],    @gtp_session[sequence_number][:RESPONSE][:pgw_f_teid_grekey], 
        @gtp_session[sequence_number][:REQUEST][:sender_f_teid_addr],       @gtp_session[sequence_number][:REQUEST][:pgw_f_teid_addr], 
        @gtp_session[sequence_number][:RESPONSE][:sender_f_teid_addr],      @gtp_session[sequence_number][:RESPONSE][:pgw_f_teid_addr], 
        @gtp_session[sequence_number][:REQUEST][:bearer_ebi],        @gtp_session[sequence_number][:RESPONSE][:bearer_ebi], 
        @gtp_session[sequence_number][:RESPONSE][:bearer_cause_val], 
        @gtp_session[sequence_number][:RESPONSE][:bearer_cause_pce], 
        @gtp_session[sequence_number][:RESPONSE][:bearer_cause_bce], 
        @gtp_session[sequence_number][:RESPONSE][:bearer_cause_cs], 
        @gtp_session[sequence_number][:REQUEST][:bearer_tft],        @gtp_session[sequence_number][:RESPONSE][:bearer_tft], 
        @gtp_session[sequence_number][:RESPONSE][:bearer_charging_id], 
        @gtp_session[sequence_number][:REQUEST][:bearer_qos_pvi],                 @gtp_session[sequence_number][:RESPONSE][:bearer_qos_pvi], 
        @gtp_session[sequence_number][:REQUEST][:bearer_qos_pl],                  @gtp_session[sequence_number][:RESPONSE][:bearer_qos_pl], 
        @gtp_session[sequence_number][:REQUEST][:bearer_qos_pci],                 @gtp_session[sequence_number][:RESPONSE][:bearer_qos_pci], 
        @gtp_session[sequence_number][:REQUEST][:bearer_qos_label_qci],           @gtp_session[sequence_number][:RESPONSE][:bearer_qos_label_qci], 
        @gtp_session[sequence_number][:REQUEST][:bearer_qos_max_uplink],          @gtp_session[sequence_number][:RESPONSE][:bearer_qos_max_uplink], 
        @gtp_session[sequence_number][:REQUEST][:bearer_qos_max_downlink],        @gtp_session[sequence_number][:RESPONSE][:bearer_qos_max_downlink], 
        @gtp_session[sequence_number][:REQUEST][:bearer_qos_guaranteed_uplink],   @gtp_session[sequence_number][:RESPONSE][:bearer_qos_guaranteed_uplink], 
        @gtp_session[sequence_number][:REQUEST][:bearer_qos_guaranteed_downlink], @gtp_session[sequence_number][:RESPONSE][:bearer_qos_guaranteed_downlink], 
        @gtp_session[sequence_number][:RESPONSE][:bearer_flags_ppc], 
        @gtp_session[sequence_number][:RESPONSE][:bearer_flags_vb], 
        @gtp_session[sequence_number][:RESPONSE][:bearer_flags_vind], 
        @gtp_session[sequence_number][:RESPONSE][:bearer_flags_asi], 
        @gtp_session[sequence_number][:REQUEST][:bearer_f_teid_v4v6],      @gtp_session[sequence_number][:RESPONSE][:bearer_f_teid_v4v6], 
        @gtp_session[sequence_number][:REQUEST][:bearer_f_teid_interface], @gtp_session[sequence_number][:RESPONSE][:bearer_f_teid_interface], 
        @gtp_session[sequence_number][:REQUEST][:bearer_f_teid_gre_key],   @gtp_session[sequence_number][:RESPONSE][:bearer_f_teid_gre_key], 
        @gtp_session[sequence_number][:REQUEST][:bearer_f_teid_addr],      @gtp_session[sequence_number][:RESPONSE][:bearer_f_teid_addr], 
        @gtp_session[sequence_number][:REQUEST][:trace_info_mcc], 
        @gtp_session[sequence_number][:REQUEST][:trace_info_mnc], 
        @gtp_session[sequence_number][:REQUEST][:trace_info_id], 
        @gtp_session[sequence_number][:REQUEST][:trace_info_triggering_events], 
        @gtp_session[sequence_number][:REQUEST][:trace_info_list_of_ne_types], 
        @gtp_session[sequence_number][:REQUEST][:trace_info_session_trace_depth], 
        @gtp_session[sequence_number][:REQUEST][:trace_info_list_of_interfaces], 
        @gtp_session[sequence_number][:REQUEST][:trace_info_ip_addr_of_trace_collection_entity], 
        @gtp_session[sequence_number][:REQUEST][:pdn_type], 
        @gtp_session[sequence_number][:REQUEST][:ue_time_zone], 
        @gtp_session[sequence_number][:REQUEST][:ue_time_zone_daylight_saving_time], 
        @gtp_session[sequence_number][:REQUEST][:apn_restriction],      @gtp_session[sequence_number][:RESPONSE][:apn_restriction], 
        @gtp_session[sequence_number][:REQUEST][:selection_mode], 
        @gtp_session[sequence_number][:RESPONSE][:change_reporting_action], 
        @gtp_session[sequence_number][:RESPONSE][:fqdn], 
        @gtp_session[sequence_number][:REQUEST][:fq_csid_num_of_csids], @gtp_session[sequence_number][:RESPONSE][:fq_csid_num_of_csids], 
        @gtp_session[sequence_number][:REQUEST][:fq_csid_node_id_type], @gtp_session[sequence_number][:RESPONSE][:fq_csid_node_id_type], 
        @gtp_session[sequence_number][:REQUEST][:fq_csid_node_id],      @gtp_session[sequence_number][:RESPONSE][:fq_csid_node_id], 
        @gtp_session[sequence_number][:REQUEST][:fq_csid_pdn_csid],     @gtp_session[sequence_number][:RESPONSE][:fq_csid_pdn_csid], 
        @gtp_session[sequence_number][:REQUEST][:uci_mcc], 
        @gtp_session[sequence_number][:REQUEST][:uci_mnc], 
        @gtp_session[sequence_number][:REQUEST][:uci_csg_id], 
        @gtp_session[sequence_number][:REQUEST][:uci_cmi], 
        @gtp_session[sequence_number][:REQUEST][:uci_lcsg], 
        @gtp_session[sequence_number][:REQUEST][:uci_access_mode], 
        @gtp_session[sequence_number][:RESPONSE][:csg_information_reporting_action_ucicsg], 
        @gtp_session[sequence_number][:RESPONSE][:csg_information_reporting_action_ucishc], 
        @gtp_session[sequence_number][:RESPONSE][:csg_information_reporting_action_uciuhc], 
        @gtp_session[sequence_number][:RESPONSE][:ldn], 
        @gtp_session[sequence_number][:RESPONSE][:epc_timer_val], 
        @gtp_session[sequence_number][:RESPONSE][:epc_timer_unit], 
        @gtp_session[sequence_number][:REQUEST][:signalling_priority_indication], 
        @gtp_session[sequence_number][:REQUEST][:apco],                @gtp_session[sequence_number][:RESPONSE][:apco], 
        @gtp_session[sequence_number][:RESPONSE][:hnb_information_reporting], 
        @gtp_session[sequence_number][:RESPONSE][:ip4cp_subnet_prefix_length], 
        @gtp_session[sequence_number][:RESPONSE][:ip4cp_ipv4_default_router_addr], 
        @gtp_session[sequence_number][:REQUEST][:twan_identifier_bssidi], 
        @gtp_session[sequence_number][:REQUEST][:twan_identifier_ssid], 
        @gtp_session[sequence_number][:REQUEST][:twan_identifier_bssid], 
        @gtp_session[sequence_number][:REQUEST][:private_extension_enterprise_id],   @gtp_session[sequence_number][:RESPONSE][:private_extension_enterprise_id], 
        @gtp_session[sequence_number][:REQUEST][:private_extension_proprietary_val], @gtp_session[sequence_number][:RESPONSE][:private_extension_proprietary_val], 
      ])
    end

    return gtp_data
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Parse GTPv2-C data to get message_type.
  # @param [Time] gtptime                 Current time.
  # @param [String] gtpdata               udp packet payload data.
  # @option options [Boolean] :gtp_all    Set true to output the all gtp information.
  # @return [Array]     return the summarized GTP data array or return empty array if not completed.
  # @return [Hash]      If nor GTP ver.2 or target message types.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_gtp_data(gtptime, gtpdata, leading, options)
      header_flag = Hash.new
      gtp_header_param = Hash.new
      ret = Hash.new
      
      # Get Payload
      header_flag[:version] = (gtpdata[0].unpack("C")[0] & 0b11100000) >> 5
      # Parse GTPv2-C      
      if header_flag[:version] == 2
        header_flag[:piggybacking_flag] = (gtpdata[0].unpack("C")[0] & 0b00010000) >> 4
        header_flag[:teid_flag]         = (gtpdata[0].unpack("C")[0] & 0b00001000) >> 3
        # Get GTP Flags
        gtp_header_param[:pkt_time]        = gtptime
        gtp_header_param[:message_type]    = gtpdata[1].unpack("c")[0]
        gtp_header_param[:message_length]  = gtpdata[2..3].unpack("n")[0]
        # Check GTP correct packet size
        return ret if gtp_header_param[:message_length] != gtpdata[4..-1].size
        
        gtp_header_param[:teid]            = gtpdata[4..7].unpack("N")[0] if header_flag[:teid_flag] == 1
        header_flag[:teid_flag] == 0 ? offset = 4 : offset = 8 # change the length of header by the TEID Flag
        gtp_header_param[:sequence_number] = gtpdata[offset..offset+2].unpack("H*")[0]
        sequence_number = gtp_header_param[:sequence_number]
        payload_body = gtpdata[offset+4..-1]
        gtp_header_param[:payload_size] = payload_body.size
        case gtp_header_param[:message_type]
        when CREATE_SESSION_REQUEST
                gtp_header_param[:req_res] = :REQUEST
                ret = parse_create_session_request_msg(payload_body, options, gtp_header_param)
        when CREATE_SESSION_RESPONSE
                gtp_header_param[:req_res] = :RESPONSE
                ret = parse_create_session_response_msg(payload_body, options, gtp_header_param)
        when MODIFY_BEARER_REQUEST
                gtp_header_param[:req_res] = :REQUEST
                ret = parse_modify_bearer_request_msg(payload_body, options, gtp_header_param)
        when MODIFY_BEARER_RESPONSE
                gtp_header_param[:req_res] = :RESPONSE
                ret = parse_modify_bearer_response_msg(payload_body, options, gtp_header_param) if options[:gtp_all]
        else
              return ret
        end

        key = gtp_header_param[:req_res] == :REQUEST ? :REQUEST : :RESPONSE
        return [] if (key == :REQUEST and !leading)

        @gtp_session ||= Hash.new
        return [] if (!leading and @gtp_session[sequence_number].nil?)
        
        @gtp_session[sequence_number] ||= {:REQUEST => {}, :RESPONSE => {}}
        @gtp_session[sequence_number][key] = gtp_header_param.merge(ret).dup
        ret = gtp_session_complete?(sequence_number) ? summarize_gtp_info(sequence_number, options) : []

        unless ret.empty?
          @gtp_session.delete sequence_number
        end
      end

      return ret
  end

end
