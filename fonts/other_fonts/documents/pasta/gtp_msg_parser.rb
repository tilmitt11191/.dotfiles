# -*- encoding: UTF-8 -*-

require_relative "gtp_ie_parser.rb"
  
# Message types for GTP
ECHO_REQUEST  = 1; ECHO_RESPONSE = 2; 

# SGSN/MME/ TWAN/ePDG to PGW(S4/S11; S5/S8; S2a; S2b)
CREATE_SESSION_REQUEST = 32; CREATE_SESSION_RESPONSE = 33; 
DELETE_SESSION_REQUEST = 36; DELETE_SESSION_RESPONSE = 37; 

# SGSN/MME/ePDG to PGW(S4/S11; S5/S8; S2b)
MODIFY_BEARER_REQUEST  = 34; 
MODIFY_BEARER_RESPONSE = 35; 

# SGSN/MME/ TWAN/ePDG to PGW(S4/S11; S5/S8; S2a; S2b)
CHANGE_NOTIFICATION_REQUEST = 38;  CHANGE_NOTIFICATION_RESPONSE  = 39; 
RESUME_NOTIFICATION         = 164; RESUME_ACKNOWLEDGE            = 165; 

# Messages without explicit response
MODIFY_BEARER_COMMAND                         = 64; MODIFY_BEARER_FAILURE_INDICATION = 65; DELETE_BEARER_COMMAND              = 66; 
DELETE_BEARER_FAILURE_INDICATION              = 67; BEARER_RESOURCE_COMMAND          = 68; BEARER_RESOURCE_FAILURE_INDICATION = 69; 
DOWNLINK_DATA_NOTIFICATIONFAILURE_INDICATION  = 70; TRACE_SESSION_ACTIVATION         = 71; TRACE_SESSION_DEACTIVATION         = 72; 
STOP_PAGING_INDICATION                        = 73;

# PGW to SGSN/MME/ TWAN/ePDG (S5/S8; SS4/S11; S2a; S2b)
CREATE_BEARER_REQUEST  = 95; CREATE_BEARER_RESPONSE = 96; UPDATE_BEARER_REQUEST   = 97; 
UPDATE_BEARER_RESPONSE = 98; DELETE_BEARER_REQUEST  = 99; DELETE_BEARER_RESPONSE  = 100; 

# PGW to MME; MME to PGW; SGW to PGW; SGW to MME; PGW to TWAN/ePDG; TWAN/ePDG to PGW(S5/S8; S11; S2a; S2b)
DELETE_PDN_CONNECTION_SET_REQUEST  = 101; 
DELETE_PDN_CONNECTION_SET_RESPONSE = 102; 

# PGW to SGSN/MME(S5; S4/S11)
PGW_DOWNLINK_TRIGGERING_NOTIFICATION = 103; 
PGW_DOWNLINK_TRIGGERING_ACKNOWLEDGE  = 104; 

# MME to MME; SGSN to MME; MME to SGSN; SGSN to SGSN(S3/S10/S16)
IDENTIFICATION_REQUEST              = 128; IDENTIFICATION_RESPONSE                   = 129; CONTEXT_REQUEST                         = 130; 
CONTEXT_RESPONSE                    = 131; CONTEXT_ACKNOWLEDGE                       = 132; FORWARD_RELOCATION_REQUEST              = 133; 
FORWARD_RELOCATION_RESPONSE         = 134; FORWARD_RELOCATION_COMPLETE_NOTIFICATION  = 135; FORWARD_RELOCATION_COMPLETE_ACKNOWLEDGE = 136; 
FORWARD_ACCESS_CONTEXT_NOTIFICATION = 137; FORWARD_ACCESS_CONTEXT_ACKNOWLEDGE        = 138; RELOCATION_CANCEL_REQUEST               = 139; 
RELOCATION_CANCEL_RESPONSE          = 140; CONFIGURATION_TRANSFER_TUNNEL             = 141; RAN_INFORMATION_RELAY                   = 152; 

# SGSN to MME;MME to SGSN(S3)
DETACH_NOTIFICATION     = 149; DETACH_ACKNOWLEDGE    = 150; CS_PAGING_INDICATION     = 151; 
ALERT_MME_NOTIFICATION  = 153; ALERT_MME_ACKNOWLEDGE = 154; UE_ACTIVITY_NOTIFICATION = 155; 
UE_ACTIVITY_ACKNOWLEDGE = 156; ISR_STATUS_INDICATION = 157; 

# SGSN/MME to SGW;SGSN to MME(S4/S11/S3) SGSN to SGSN(S16); SGW to PGW(S5/S8)
SUSPEND_NOTIFICATION = 162;   SUSPEND_ACKNOWLEDGE  = 163; 

# SGSN/MME to SGW(S4/S11)
CREATE_FORWARDING_TUNNEL_REQUEST               = 160; CREATE_FORWARDING_TUNNEL_RESPONSE               = 161; 
CREATE_INDIRECT_DATA_FORWARDING_TUNNEL_REQUEST = 166; CREATE_INDIRECT_DATA_FORWARDING_TUNNEL_RESPONSE = 167; 
DELETE_INDIRECT_DATA_FORWARDING_TUNNEL_REQUEST = 168; DELETE_INDIRECT_DATA_FORWARDING_TUNNEL_RESPONSE = 169; 
RELEASE_ACCESS_BEARER_REQUEST                  = 170; RELEASE_ACCESS_BEARER_RESPONSE                  = 171; 

# SGW to SGSN/MME(S4/S11)
DOWNLINK_DATA_NOTIFICATION = 176; DOWNLINK_DATA_NOTIFICATION_ACKNOWLEDGE = 177; 
PGW_RESTART_NOTIFICATION   = 179; PGW_RESTART_NOTIFICATION_ACKNOWLEDGE   = 180; 

# SGW to PGW; PGW to SGW(S5/S8)
UPDATE_PDN_CONNECTION_SET_REQUEST  = 200;   UPDATE_PDN_CONNECTION_SET_RESPONSE = 201; 

# MME to SGW(S11)
MODIFY_ACCESS_BEARERS_REQUEST  = 211;   MODIFY_ACCESS_BEARERS_RESPONSE = 212; 

# MBMS GW to MME/SGSN(Sm/Sn)
MBMS_SESSION_START_REQUEST  = 231; MBMS_SESSION_START_RESPONSE  = 232; 
MBMS_SESSION_UPDATE_REQUEST = 233; MBMS_SESSION_UPDATE_RESPONSE = 234; 
MBMS_SESSION_STOP_REQUEST   = 235; MBMS_SESSION_STOP_RESPONSE   = 236 


# Parse Message Type For GTPv2-C Module
module GTPMSGParser
  include GTPIEParser
    
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Parse Create Session Request at GTP.
  # @param [String]    payload_body       gtp packet payload body data.
  # @option options [Boolean] :gtp_all    Set true to output the all gtp information.
  # @gtp_header_param [Hash]              parsed GTP header parameters.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_create_session_request_msg(payload_body, options, gtp_header_param)
    offset = 0
    f_teid_num = 0
    ret = {}
    summarize_gtp_param = {}
    payload_size = gtp_header_param[:payload_size]
    
    while payload_size > offset
      ie_type = payload_body[offset].unpack("C")[0]; offset += 1
      ie_length = payload_body[offset..offset+1].unpack("n")[0]; offset += 3
      
      case ie_type
      when PAA  then ret = parse_ie_paa(payload_body[offset..offset+ie_length-1], options)
      when IMSI then ret = parse_ie_imsi(payload_body[offset..offset+ie_length-1], options)
      when ULI  then ret = parse_ie_uli(payload_body[offset..offset+ie_length-1])
      end
    
      if options[:gtp_all]
        case ie_type
        when MSISDN                         then ret = parse_ie_msisdn(payload_body[offset..offset+ie_length-1])
        when MEI                            then ret = parse_ie_mei(payload_body[offset..offset+ie_length-1])
        when SERVING_NETWORK                then ret = parse_ie_serving_network(payload_body[offset..offset+ie_length-1])
        when RAT_TYPE                       then ret = parse_ie_rat_type(payload_body[offset..offset+ie_length-1])
        when INDICATION                     then ret = parse_ie_indication(payload_body[offset..offset+ie_length-1])
        when F_TEID                         then f_teid_param = parse_ie_f_teid(payload_body[offset..offset+ie_length-1])
          if f_teid_num == 0
            ret = {:sender_f_teid_v4v6 => f_teid_param[:f_teid_v4v6], :sender_f_teid_interface => f_teid_param[:f_teid_interface], :sender_f_teid_grekey => f_teid_param[:f_teid_gre_key], :sender_f_teid_addr => f_teid_param[:f_teid_addr]}
          else
            ret = {:pgw_f_teid_v4v6 => f_teid_param[:f_teid_v4v6], :pgw_f_teid_interface => f_teid_param[:f_teid_interface], :pgw_f_teid_grekey => f_teid_param[:f_teid_gre_key], :pgw_f_teid_addr => f_teid_param[:f_teid_addr]}
          end
          f_teid_num += 1
        when APN                            then ret = parse_ie_apn(payload_body[offset..offset+ie_length-1])
        when SELECTION_MODE                 then ret = parse_ie_selection_mode(payload_body[offset..offset+ie_length-1])
        when PDN_TYPE                       then ret = parse_ie_pdn_type(payload_body[offset..offset+ie_length-1])
        when APN_RESTRICTION                then ret = parse_ie_apn_restriction(payload_body[offset..offset+ie_length-1])
        when AMBR                           then ret = parse_ie_ambr(payload_body[offset..offset+ie_length-1])
        when EBI                            then ret = parse_ie_ebi(payload_body[offset..offset+ie_length-1])
        when PCO                            then ret = parse_ie_pco(payload_body[offset..offset+ie_length-1], ie_length, gtp_header_param)
        when BEARER_CONTEXT                 then ret = parse_ie_bearer_context(payload_body[offset..offset+ie_length-1], ie_length)
        when TRACE_INFORMATION              then ret = parse_ie_trace_information(payload_body[offset..offset+ie_length-1])
        when RECOVERY                       then ret = parse_ie_recovery(payload_body[offset..offset+ie_length-1])
        when FQ_CSID                        then ret = parse_ie_fq_csid(payload_body[offset..offset+ie_length-1])
        when UE_TIME_ZONE                   then ret = parse_ie_ue_time_zone(payload_body[offset..offset+ie_length-1])
        when UCI                            then ret = parse_ie_uci(payload_body[offset..offset+ie_length-1])
        when CHARGING_CHARACTERISTICS       then ret = parse_ie_charging_characteristics(payload_body[offset..offset+ie_length-1])
        when LDN                            then ret = parse_ie_ldn(payload_body[offset..offset+ie_length-1])
        when SIGNALLING_PRIORITY_INDICATION then ret = parse_ie_signalling_priority_indication(payload_body[offset..offset+ie_length-1])
        when APCO                           then ret = parse_ie_apco(payload_body[offset..offset+ie_length-1])
        when TWAN_IDENTIFIER                then ret = parse_ie_twan_identifier(payload_body[offset..offset+ie_length-1])
        when PRIVATE_EXTENSION              then ret = parse_ie_private_extension(payload_body[offset..offset+ie_length-1])
        end
      end
      
      summarize_gtp_param = summarize_gtp_param.merge(ret)
      offset = offset+ie_length
    end
    
    return summarize_gtp_param
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Parse Create Session Response at GTP.
  # @param [String]    payload_body       gtp packet payload body data.
  # @option options [Boolean] :gtp_all    Set true to output the all gtp information.
  # @gtp_header_param [Hash]              parsed GTP header parameters.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_create_session_response_msg(payload_body, options, gtp_header_param)
    offset = 0
    f_teid_num = 0
    ret = {}
    summarize_gtp_param = {}
    payload_size = gtp_header_param[:payload_size]
    
    while payload_size > offset
      ie_type = payload_body[offset].unpack("C")[0]; offset += 1
      ie_length = payload_body[offset..offset+1].unpack("n")[0]; offset += 3
      
      case ie_type
      when PAA then ret = parse_ie_paa(payload_body[offset..offset+ie_length-1], options)
      end
      
      if options[:gtp_all]
        case ie_type      
        when CAUSE                            then ret = parse_ie_cause(payload_body[offset..offset+ie_length-1])
        when CHANGE_REPORTING_ACTION          then ret = parse_ie_change_reporting_action(payload_body[offset..offset+ie_length-1])
        when CSG_INFORMATION_REPORTING_ACTION then ret = parse_ie_csg_information_reporting_action(payload_body[offset..offset+ie_length-1])
        when HNB_INFORMATION_REPORTING        then ret = parse_ie_hnb_information_reporting(payload_body[offset..offset+ie_length-1])
        when F_TEID                           then f_teid_param = parse_ie_f_teid(payload_body[offset..offset+ie_length-1])
          if f_teid_num == 0
            ret = {:sender_f_teid_v4v6 => f_teid_param[:f_teid_v4v6], :sender_f_teid_interface => f_teid_param[:f_teid_interface], :sender_f_teid_grekey => f_teid_param[:f_teid_gre_key], :sender_f_teid_addr => f_teid_param[:f_teid_addr]}
          else
            ret = {:pgw_f_teid_v4v6 => f_teid_param[:f_teid_v4v6], :pgw_f_teid_interface => f_teid_param[:f_teid_interface], :pgw_f_teid_grekey => f_teid_param[:f_teid_gre_key], :pgw_f_teid_addr => f_teid_param[:f_teid_addr]}
          end
          f_teid_num += 1
        when APN_RESTRICTION                  then ret = parse_ie_apn_restriction(payload_body[offset..offset+ie_length-1])
        when AMBR                             then ret = parse_ie_ambr(payload_body[offset..offset+ie_length-1])
        when EBI                              then ret = parse_ie_ebi(payload_body[offset..offset+ie_length-1])
        when PCO                              then ret = parse_ie_pco(payload_body[offset..offset+ie_length-1], ie_length, gtp_header_param)
        when BEARER_CONTEXT                   then ret = parse_ie_bearer_context(payload_body[offset..offset+ie_length-1], ie_length)
        when RECOVERY                         then ret = parse_ie_recovery(payload_body[offset..offset+ie_length-1])
        when FQDN                             then ret = parse_ie_fqdn(payload_body[offset..offset+ie_length-1])
        when FQ_CSID                          then ret = parse_ie_fq_csid(payload_body[offset..offset+ie_length-1])
        when LDN                              then ret = parse_ie_ldn(payload_body[offset..offset+ie_length-1])
        when EPC_TIMER                        then ret = parse_ie_epc_timer(payload_body[offset..offset+ie_length-1])
        when APCO                             then ret = parse_ie_apco(payload_body[offset..offset+ie_length-1])
        when IP4CP                            then ret = parse_ie_ip4cp(payload_body[offset..offset+ie_length-1])
        when PRIVATE_EXTENSION                then ret = parse_ie_private_extension(payload_body[offset..offset+ie_length-1])
        end
      end
      
      summarize_gtp_param = summarize_gtp_param.merge(ret)
      offset = offset+ie_length
    end
    
    return summarize_gtp_param
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Parse Modify Bearer Request at GTP.
  # @param [String]    payload_body       gtp packet payload body data.
  # @option options [Boolean] :gtp_all    Set true to output the all gtp information.
  # @gtp_header_param [Hash]              parsed GTP header parameters.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_modify_bearer_request_msg(payload_body, options, gtp_header_param)
    offset = 0
    f_teid_num = 0
    ret = {}
    summarize_gtp_param = {}
    payload_size = gtp_header_param[:payload_size]
    
    while payload_size > offset
      ie_type = payload_body[offset].unpack("C")[0]; offset += 1
      ie_length = payload_body[offset..offset+1].unpack("n")[0]; offset += 3
      
      case ie_type
      when ULI then ret = parse_ie_uli(payload_body[offset..offset+ie_length-1])
      end
      
      if options[:gtp_all]
        case ie_type
        when MEI               then ret = parse_ie_mei(payload_body[offset..offset+ie_length-1])
        when SERVING_NETWORK   then ret = parse_ie_serving_network(payload_body[offset..offset+ie_length-1])
        when RAT_TYPE          then ret = parse_ie_rat_type(payload_body[offset..offset+ie_length-1])
        when INDICATION        then ret = parse_ie_indication(payload_body[offset..offset+ie_length-1])
        when F_TEID            then f_teid_param = parse_ie_f_teid(payload_body[offset..offset+ie_length-1])
          if f_teid_num == 0
            ret = {:sender_f_teid_v4v6 => f_teid_param[:f_teid_v4v6], :sender_f_teid_interface => f_teid_param[:f_teid_interface], :sender_f_teid_grekey => f_teid_param[:f_teid_gre_key], :sender_f_teid_addr => f_teid_param[:f_teid_addr]}
          else
            ret = {:pgw_f_teid_v4v6 => f_teid_param[:f_teid_v4v6], :pgw_f_teid_interface => f_teid_param[:f_teid_interface], :pgw_f_teid_grekey => f_teid_param[:f_teid_gre_key], :pgw_f_teid_addr => f_teid_param[:f_teid_addr]}
          end
          f_teid_num += 1
        when AMBR              then ret = parse_ie_ambr(payload_body[offset..offset+ie_length-1])
        when BEARER_CONTEXT    then ret = parse_ie_bearer_context(payload_body[offset..offset+ie_length-1], ie_length)
        when RECOVERY          then ret = parse_ie_recovery(payload_body[offset..offset+ie_length-1])
        when UE_TIME_ZONE      then ret = parse_ie_ue_time_zone(payload_body[offset..offset+ie_length-1])
        when FQ_CSID           then ret = parse_ie_fq_csid(payload_body[offset..offset+ie_length-1])
        when UCI               then ret = parse_ie_uci(payload_body[offset..offset+ie_length-1])
        when LDN               then ret = parse_ie_ldn(payload_body[offset..offset+ie_length-1])
        when PRIVATE_EXTENSION then ret = parse_ie_private_extension(payload_body[offset..offset+ie_length-1])
        end
      end
      
      summarize_gtp_param = summarize_gtp_param.merge(ret)
      offset = offset+ie_length
    end

    return summarize_gtp_param
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Parse Modify Bearer Response at GTP.
  # @param [String]    payload_body       gtp packet payload body data.
  # @option options [Boolean] :gtp_all    Set true to output the all gtp information.
  # @gtp_header_param [Hash]              parsed GTP header parameters.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_modify_bearer_response_msg(payload_body, options, gtp_header_param)
    offset = 0
    ret = {}
    summarize_gtp_param = {}
    payload_size = gtp_header_param[:payload_size]
    
    while payload_size > offset
      ie_type = payload_body[offset].unpack("C")[0]; offset += 1
      ie_length = payload_body[offset..offset+1].unpack("n")[0]; offset += 3
      
      case ie_type
      when CAUSE                            then ret = parse_ie_cause(payload_body[offset..offset+ie_length-1])
      when MSISDN                           then ret = parse_ie_msisdn(payload_body[offset..offset+ie_length-1])
      when EBI                              then ret = parse_ie_ebi(payload_body[offset..offset+ie_length-1])
      when AMBR                             then ret = parse_ie_ambr(payload_body[offset..offset+ie_length-1])
      when APN_RESTRICTION                  then ret = parse_ie_apn_restriction(payload_body[offset..offset+ie_length-1])
      when PCO                              then ret = parse_ie_pco(payload_body[offset..offset+ie_length-1], ie_length, gtp_header_param)
      when BEARER_CONTEXT                   then ret = parse_ie_bearer_context(payload_body[offset..offset+ie_length-1], ie_length)
      when CHANGE_REPORTING_ACTION          then ret = parse_ie_change_reporting_action(payload_body[offset..offset+ie_length-1])
      when CSG_INFORMATION_REPORTING_ACTION then ret = parse_ie_csg_information_reporting_action(payload_body[offset..offset+ie_length-1])
      when HNB_INFORMATION_REPORTING        then ret = parse_ie_hnb_information_reporting(payload_body[offset..offset+ie_length-1])
      when FQDN                             then ret = parse_ie_fqdn(payload_body[offset..offset+ie_length-1])
      when FQ_CSID                          then ret = parse_ie_fq_csid(payload_body[offset..offset+ie_length-1])
      when RECOVERY                         then ret = parse_ie_recovery(payload_body[offset..offset+ie_length-1])
      when LDN                              then ret = parse_ie_ldn(payload_body[offset..offset+ie_length-1])
      when INDICATION                       then ret = parse_ie_indication(payload_body[offset..offset+ie_length-1])
      when PRIVATE_EXTENSION                then ret = parse_ie_private_extension(payload_body[offset..offset+ie_length-1])
      end
      
      summarize_gtp_param = summarize_gtp_param.merge(ret)
      offset = offset+ie_length
    end

    return summarize_gtp_param
  end

end
