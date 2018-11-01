# -*- encoding: UTF-8 -*-

# Information Element types for GTPv2
IMSI                                = 1  ; CAUSE                             = 2  ; RECOVERY                         = 3  ; 
APN                                 = 71 ; AMBR                              = 72 ; EBI                              = 73 ; 
AP_ADDRESS                          = 74 ; MEI                               = 75 ; MSISDN                           = 76 ; 
INDICATION                          = 77 ; PCO                               = 78 ; PAA                              = 79 ; 
BEARER_QOS                          = 80 ; FLOW_QOS                          = 81 ; RAT_TYPE                         = 82 ; 
SERVING_NETWORK                     = 83 ; BEARER_TFT                        = 84 ; TAD                              = 85 ; 
ULI                                 = 86 ; F_TEID                            = 87 ; TMSI                             = 88 ; 
GLOBAL_CN_ID                        = 89 ; S103PDF                           = 90 ; S1UDF                            = 91 ; 
DELAY_VALUE                         = 92 ; BEARER_CONTEXT                    = 93 ; CHARGING_ID                      = 94 ; 
CHARGING_CHARACTERISTICS            = 95 ; TRACE_INFORMATION                 = 96 ; BEARER_FLAGS                     = 97 ; 
PDN_TYPE                            = 99 ; PT_ID                             = 100; GSM_KEY_TRIPLETS                 = 103; 
UMTS_KEY_USED_CIPHER                = 104; GSM_KEY_USED_CIPHER               = 105; UMTS_KEY_QUINTUPLETS             = 106; 
EPS_SECURITY                        = 107; UMTS_KEY_QUADRUPLETS              = 108; PDN_CONNECTION                   = 109; 
PDN_NUMBERS                         = 110; P_TMSI                            = 111; P_TMSI_SIGNATURE                 = 112; 
HOP_COUNTER                         = 113; UE_TIME_ZONE                      = 114; TRACE_REFERENCE                  = 115; 
COMPLETE_REQUEST_MESSAGE            = 116; GUTI                              = 117; F_CONTAINER                      = 118; 
F_CAUSE                             = 119; PLMN_ID                           = 120; TARGET_INDENTIFICATION           = 121; 
PACKET_FLOW_ID                      = 123; RAB_CONTEXT                       = 124; SOURCE_RNC_PDCP_CONTEXT_INFO     = 125; 
UDP_SOURCE_PORT_NUMBER              = 126; APN_RESTRICTION                   = 127; SELECTION_MODE                   = 128; 
SOURCE_IDENTIFICATION               = 129; CHANGE_REPORTING_ACTION           = 131; FQ_CSID                          = 132; 
CHANNEL_NEEDED                      = 133; EMLPP_PRIOTITY                    = 134; NODE_TYPE                        = 135; 
FQDN                                = 136; TI                                = 137; MBMS_SESSION_DURATION            = 138; 
MBMS_SERVICE_AREA                   = 139; MBMS_SESSION_IDENTIFER            = 140; MBMS_FLOW_IDENTIFER              = 141; 
MBMS_IP_MULTICAST_DISTRIBUTION      = 142; MBMS_DISTRIBUTION_ACKNOWLEDGE     = 143; RFSP_INDEX                       = 144; 
UCI                                 = 145; CSG_INFORMATION_REPORTING_ACTION  = 146; CSG_ID                           = 147; 
CMI                                 = 148; SERVICE_INDICATOR                 = 149; DETACH_TYPE                      = 150; 
LDN                                 = 151; NODE_FEATURES                     = 152; MBMS_TIME_TO_DATA_TRANSFER       = 153; 
THROTTLING                          = 154; ARP                               = 155; EPC_TIMER                        = 156; 
SIGNALLING_PRIORITY_INDICATION      = 157; TMGI                              = 158; ADDITIONAL_MM_CONTEXT_FOR_SRVCC  = 159; 
ADDITIONAL_FLAGS_FOR_SRVCC          = 160; MDT_CONFIGURATION                 = 162; APCO                             = 163; 
ABSOLUTE_TIME_OF_MBMS_DATA_TRANSFER = 164; HNB_INFORMATION_REPORTING         = 165; IP4CP                            = 166; 
CHARGE_TO_REPORT_FLAGS              = 167; ACTION_IDENTIFER                  = 168; TWAN_IDENTIFIER                  = 169; 
PRIVATE_EXTENSION                   = 255

# F-TEID Interface Type
S1_U_ENODEB_GTP_U                       = 0 ; S1_U_SGW_GTP_U                                = 1 ; S12_RNC_GTP_U                                 = 2 ; 
S12_SGW_GTP_U                           = 3 ; S5_S8_SGW_GTP_U                               = 4 ; S5_S8_PGW_GTP_U                               = 5 ; 
S5_S8_SGW_GTP_C                         = 6 ; S5_S8_PGW_GTP_C                               = 7 ; S5_S8_SGW_PMIPv6_NOT_USED_CPLANE              = 8 ; 
S5_S8_PGW_PMIPv6                        = 9 ; S11_MME_GTP_C                                 = 10; S11_S4_SGW_GTP_C                              = 11; 
S10_MME_GTP_C                           = 12; S3_MME_GTP_C                                  = 13; S3_SGSN_GTP_C                                 = 14; 
S4_SGSN_GTP_U                           = 15; S4_SGW_GTP_U                                  = 16; S4_SGSN_GTP_C                                 = 17; 
S16_SGSN_GTP_C                          = 18; ENODEB_GTP_U_INTERFACE_FOR_DL_DATA_FORWARDING = 19; ENODEB_GTP_U_INTERFACE_FOR_UL_DATA_FORWARDING = 20; 
RNC_GTP_U_INTERFACE_FOR_DATA_FORWARDING = 21; SGSN_GTP_U_INTERFACE_FOR_DATA_FORWARDING      = 22; SGW_GTP_U_INTERFACE_FOR_DL_DATA_FORWARDING    = 23; 
SM_MBMS_GW_GTP_C                        = 24; SN_MBMS_GW_GTP_C                              = 25; SM_MME_GTP_C                                  = 26; 
SN_SGSN_GTP_C                           = 27; SGW_GTP_U_INTERFACE_FOR_UL_DATA_FORWARDING    = 28; SN_SGSN_GTP_U                                 = 29; 
S2B_EPDG_GTP_C                          = 30; S2B_U_EPDG_GTP_U                              = 31; S2B_PGW_GTP_C                                 = 32; 
S2B_U_PGW_GTP_U                         = 33; S2A_TWAN_GTP_U                                = 34; S2A_TWAN_GTP_C                                = 35; 
S2A_PGW_GTP_C                           = 36; S2A_PGW_GTP_U                                 = 37


# Parse Information Elements in a Meaasage of GTPv2-C Module
module GTPIEParser

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get a IMSI data. IE Type Value : 001
  # @param [String]    payload_data       gtp packet payload body data.
  # @option options [Boolean] :plain_text   Set true to keep original private information.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_imsi(payload_data, options)
    imsi = {}
    
    imsi_data = payload_data.unpack("h*")[0]
    
    imsi[:imsi_mcc] = imsi_data[0..2].to_i
    imsi[:imsi_mnc] = imsi_data[3..4].to_i
    imsi[:imsi_msin] = options[:plain_text] ? imsi_data[5..14] : Digest::MD5.hexdigest(imsi_data[5..14] + options[:hash_salt])
    
    return imsi
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get Cause data. IE Type Value : 002
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_cause(payload_data)
    cause = {}
    
    cause[:cause_val] = payload_data[0].unpack("H*")[0].hex
    cause[:cause_pce] = (payload_data[1].unpack("C")[0] & 0b00000100) >> 2
    cause[:cause_bce] = (payload_data[1].unpack("C")[0] & 0b00000010) >> 1
    cause[:cause_cs]  = (payload_data[1].unpack("C")[0] & 0b00000001)

    return cause
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get Recovery data. IE Type Value : 003
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_recovery(payload_data)
    recovery = {}
    
    recovery[:recovery] = payload_data.unpack("H*")[0].hex

    return recovery
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get APN data. IE Type Value : 071
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_apn(payload_data)
    apn = {}
    access_point_name = ""

    payload_data.each_byte{|str|
      str = 46 if str < 32
      access_point_name += str.chr
    }
    apn[:apn] = access_point_name
    
    return apn
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get AMBR data. IE Type Value : 072
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_ambr(payload_data)   
    ambr = {}
        
    ambr[:ambr_up_link]   = payload_data[0..3].unpack("H*")[0].hex
    ambr[:ambr_down_link] = payload_data[4..7].unpack("H*")[0].hex
    
    return ambr
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get EPS Bearer ID data. IE Type Value : 073
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_ebi(payload_data)
    ebi = {}
    
    ebi[:ebi] = (payload_data[0].unpack("C")[0] & 0b00001111)

    return ebi
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get a MEI data. IE Type Value : 075
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_mei(payload_data)
    mei = {}
    
    mei[:mei] = payload_data.unpack("h*")[0]
    
    return mei
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get a MSISDN data. IE Type Value : 076
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_msisdn(payload_data)
    msisdn = {}
    
    msisdn[:msisdn_country_code] = payload_data[0].unpack("h*")[0].to_i
    msisdn[:msisdn_address_digits] = payload_data.unpack("h*")[0]
    
    return msisdn
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get Indication data. IE Type Value : 077
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_indication(payload_data)
    indication = {}
    
    indication[:indication_daf]    = (payload_data[0].unpack("C")[0] & 0b10000000) >> 7
    indication[:indication_dtf]    = (payload_data[0].unpack("C")[0] & 0b01000000) >> 6
    indication[:indication_hi]     = (payload_data[0].unpack("C")[0] & 0b00100000) >> 5
    indication[:indication_dfi]    = (payload_data[0].unpack("C")[0] & 0b00010000) >> 4
    indication[:indication_oi]     = (payload_data[0].unpack("C")[0] & 0b00001000) >> 3
    indication[:indication_isrsi]  = (payload_data[0].unpack("C")[0] & 0b00000100) >> 2
    indication[:indication_israi]  = (payload_data[0].unpack("C")[0] & 0b00000010) >> 1
    indication[:indication_sgwci]  = (payload_data[0].unpack("C")[0] & 0b00000001)
    
    indication[:indication_sqci]   = (payload_data[1].unpack("C")[0] & 0b10000000) >> 7
    indication[:indication_uimsi]  = (payload_data[1].unpack("C")[0] & 0b01000000) >> 6
    indication[:indication_cfsi]   = (payload_data[1].unpack("C")[0] & 0b00100000) >> 5
    indication[:indication_crsi]   = (payload_data[1].unpack("C")[0] & 0b00010000) >> 4
    indication[:indication_ps]     = (payload_data[1].unpack("C")[0] & 0b00001000) >> 3
    indication[:indication_pt]     = (payload_data[1].unpack("C")[0] & 0b00000100) >> 2
    indication[:indication_si]     = (payload_data[1].unpack("C")[0] & 0b00000010) >> 1
    indication[:indication_msv]    = (payload_data[1].unpack("C")[0] & 0b00000001)

    indication[:indication_retloc] = (payload_data[2].unpack("C")[0] & 0b10000000) >> 7
    indication[:indication_pbic]   = (payload_data[2].unpack("C")[0] & 0b01000000) >> 6
    indication[:indication_srni]   = (payload_data[2].unpack("C")[0] & 0b00100000) >> 5
    indication[:indication_s6af]   = (payload_data[2].unpack("C")[0] & 0b00010000) >> 4
    indication[:indication_s4af]   = (payload_data[2].unpack("C")[0] & 0b00001000) >> 3
    indication[:indication_mbmdt]  = (payload_data[2].unpack("C")[0] & 0b00000100) >> 2
    indication[:indication_israu]  = (payload_data[2].unpack("C")[0] & 0b00000010) >> 1
    indication[:indication_ccrsi]  = (payload_data[2].unpack("C")[0] & 0b00000001)

    return indication
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get PCO data. IE Type Value : 078
  # @param [String]    payload_data       gtp packet payload body data.
  # @param [Integer] pco_ie_length        ie_length
  # @gtp_header_param [Hash]              parsed GTP header parameters.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_pco(payload_data, pco_ie_length, gtp_header_param)
    pco = {}
    
    id_length_size = 3
    count = 0
    
    while pco_ie_length > 1
      pc_id = payload_data[1..2].unpack("H*")[0]
      
      case pc_id
      when "c021" then pco_type = "Link Control Protocol"
      when "c023" then pco_type = "Point-to-Point Protocol"
      when "c223" then pco_type = "Challenge Handshake Authentication Protocol"
      when "8021" then pco_type = "Internet Protocol Control Protocol"

      when "0001" then pco_type = "P-CSCF IPv6 Address ";     pco_type << "Request" if gtp_header_param[:req_res] == :REQUEST
      when "0002" then pco_type = "IM CN Subsystem Signaling Flag"
      when "0003" then pco_type = "DNS Server IPv6 Address "; pco_type << "Request" if gtp_header_param[:req_res] == :REQUEST
      when "0004" then pco_type = gtp_header_param[:req_res] == :REQUEST ? "Not Supported" : "Policy Control rejection code"
      when "0005" then pco_type = gtp_header_param[:req_res] == :REQUEST ? "MS Support of Network Requested Bearer Control indicator" : "Selected Bearer Control Mode"
      when "0006" then pco_type = "Reserved"
      when "0007" then pco_type = "DSMIPv6 Home Agent Address "; pco_type << "Request"      if gtp_header_param[:req_res] == :REQUEST
      when "0008" then pco_type = "DSMIPv6 Home Network Prefix "; pco_type << "Request"     if gtp_header_param[:req_res] == :REQUEST
      when "0009" then pco_type = "DSMIPv6 IPv4 Home Agent Address "; pco_type << "Request" if gtp_header_param[:req_res] == :REQUEST
      when "000a" then pco_type = gtp_header_param[:req_res] == :REQUEST ? "IP address allocation via NAS signalling" : "Reserved"
      when "000b" then pco_type = gtp_header_param[:req_res] == :REQUEST ? "IPv4 address allocation via DHCPv4" : "Reserved"
      when "000c" then pco_type = "P-CSCF IPv4 Address "; pco_type << "Request"             if gtp_header_param[:req_res] == :REQUEST
      when "000d" then pco_type = "DNS Server IPv4 Address "; pco_type << "Request"         if gtp_header_param[:req_res] == :REQUEST
      when "000e" then pco_type = "MSISDN"; pco_type << "Request"                           if gtp_header_param[:req_res] == :REQUEST
      else  pco_type = "Operator Specific Use"
      end
      
      count > 0 ? pco[:pco] = pco_type << ", " << pco[:pco] : pco[:pco] = pco_type
      
      pco_length = payload_data[3].unpack("H*")[0].hex + id_length_size
      payload_data = payload_data[pco_length..-1]
      
      pco_ie_length = pco_ie_length - pco_length
      count += 1
    end
    
    return pco
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get PAA data. IE Type Value : 079
  # @param [String]    payload_data       gtp packet payload body data.
  # @option options [Boolean] :plain_text   Set true to keep original private information.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_paa(payload_data, options)
    paa = {}

    pdn_type_val = (payload_data[0].unpack("C")[0] & 0b00000111)
    
    case pdn_type_val
    when 1 then # ipv4
      pdn_addr_prefix = payload_data[1..-1].unpack("C4").join(".")
      pdn_addr_prefix = options[:plain_text] ? pdn_addr_prefix : Digest::MD5.hexdigest(pdn_addr_prefix + options[:hash_salt])
    when 2 then # ipv6
      pdn_addr_prefix_length = payload_data[1].unpack("C")[0]
      pdn_addr_prefix = IPAddr.ntop(payload_data[2..-1])
      pdn_addr_prefix = options[:plain_text] ? pdn_addr_prefix : Digest::MD5.hexdigest(pdn_addr_prefix + options[:hash_salt])
    when 3 then # ipv4ipv6
      pdn_addr_prefix_length = payload_data[1].unpack("C")[0]
      pdn_addr_prefix_v6 = IPAddr.ntop(payload_data[2..17])
      pdn_addr_prefix = payload_data[18..-1].unpack("C4").join(".")
      pdn_addr_prefix = options[:plain_text] ? pdn_addr_prefix : Digest::MD5.hexdigest(pdn_addr_prefix + options[:hash_salt])
    else
      pdn_addr_prefix = ""
      pdn_addr_prefix = options[:plain_text] ? pdn_addr_prefix : Digest::MD5.hexdigest(pdn_addr_prefix + options[:hash_salt])
    end
    paa[:paa] = pdn_addr_prefix
    
    return paa
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get Bearer QoS data. IE Type Value : 080
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_bearer_qos(payload_data)
    bearer_qos = {}
    
    bearer_qos[:bearer_qos_pci]                 = (payload_data[0].unpack("C")[0] & 0b01000000) >> 6
    bearer_qos[:bearer_qos_pl]                  = (payload_data[0].unpack("C")[0] & 0b00111100) >> 2
    bearer_qos[:bearer_qos_pvi]                 = (payload_data[0].unpack("C")[0] & 0b00000001)
    
    bearer_qos[:bearer_qos_label_qci]           = payload_data[1].unpack("H*")[0].hex
    
    bearer_qos[:bearer_qos_max_uplink]          = payload_data[2..6].unpack("H*")[0].hex
    bearer_qos[:bearer_qos_max_downlink]        = payload_data[7..11].unpack("H*")[0].hex
    bearer_qos[:bearer_qos_guaranteed_uplink]   = payload_data[12..16].unpack("H*")[0].hex
    bearer_qos[:bearer_qos_guaranteed_downlink] = payload_data[17..21].unpack("H*")[0].hex
    
    return bearer_qos
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get Rat Type data. IE Type Value : 082
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_rat_type(payload_data)
    rat_type = {}
    
    rat_type[:rat_type] = payload_data.unpack("H*")[0].to_i
    
    return rat_type
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get Serving Network data. IE Type Value : 083
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_serving_network(payload_data)    
    serving_network = {}
    
    serving_network[:serving_network_mcc] = (payload_data[0].unpack("h*")[0] << (payload_data[1].unpack("C")[0] & 0b00001111).to_s).to_i
    serving_network[:serving_network_mnc] = payload_data[2].unpack("h*")[0].to_i      
    
    return serving_network
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get Bearer TFT data. IE Type Value : 084
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_bearer_tft(payload_data)
    bearer_tft = {}
    
    bearer_tft[:bearer_tft] = payload_data.unpack("H*")[0].hex
    
    return bearer_tft
  end
  
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get MCC,MNC,LAC,CI,SAC,RAC,TAC,ECI number from ULI data. IE Type Value : 086
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_uli(payload_data)
    uli = {}
    
    uli_flag = Hash.new
    uli_offset = 1
    
    uli_flag[:spare_bit]         = (payload_data[0].unpack("C")[0] & 0b11000000) >> 6
    uli_flag[:lai_present_flag]  = (payload_data[0].unpack("C")[0] & 0b00100000) >> 5
    uli_flag[:ecgi_present_flag] = (payload_data[0].unpack("C")[0] & 0b00010000) >> 4
    uli_flag[:tai_present_flag]  = (payload_data[0].unpack("C")[0] & 0b00001000) >> 3
    uli_flag[:rai_present_flag]  = (payload_data[0].unpack("C")[0] & 0b00000100) >> 2
    uli_flag[:sai_present_flag]  = (payload_data[0].unpack("C")[0] & 0b00000010) >> 1
    uli_flag[:cgi_present_flag]  = (payload_data[0].unpack("C")[0] & 0b00000001)

    # Parse CGI Field
    if uli_flag[:cgi_present_flag] > 0
      uli[:uli_mcc] = (payload_data[uli_offset].unpack("h*")[0] << (payload_data[uli_offset+1].unpack("C")[0] & 0b00001111).to_s).to_i
      uli[:uli_mnc] = payload_data[uli_offset+2].unpack("h*")[0].to_i
      uli[:uli_lac] = payload_data[uli_offset+3..uli_offset+4].unpack("H*")[0].hex
      uli[:uli_ci]  = payload_data[uli_offset+5..uli_offset+6].unpack("H*")[0].hex

      uli_offset += 7 
    end
  
    # Parse SAI Field  
    if uli_flag[:sai_present_flag] > 0
      uli[:uli_mcc] = (payload_data[uli_offset].unpack("h*")[0] << (payload_data[uli_offset+1].unpack("C")[0] & 0b00001111).to_s).to_i
      uli[:uli_mnc] = payload_data[uli_offset+2].unpack("h*")[0].to_i
      uli[:uli_lac] = payload_data[uli_offset+3..uli_offset+4].unpack("H*")[0].hex
      uli[:uli_sac] = payload_data[uli_offset+5..uli_offset+6].unpack("H*")[0].hex

      uli_offset += 7 
    end

    # Parse RAI Field  
    if uli_flag[:rai_present_flag] > 0
      uli[:uli_mcc] = (payload_data[uli_offset].unpack("h*")[0] << (payload_data[uli_offset+1].unpack("C")[0] & 0b00001111).to_s).to_i
      uli[:uli_mnc] = payload_data[uli_offset+2].unpack("h*")[0].to_i
      uli[:uli_lac] = payload_data[uli_offset+3..uli_offset+4].unpack("H*")[0].hex
      uli[:uli_rac] = payload_data[uli_offset+5..uli_offset+6].unpack("H*")[0].hex

      uli_offset += 7
    end

    # Parse TAI Field
    if uli_flag[:tai_present_flag] > 0
      uli[:uli_mcc] = (payload_data[uli_offset].unpack("h*")[0] << (payload_data[uli_offset+1].unpack("C")[0] & 0b00001111).to_s).to_i
      uli[:uli_mnc] = payload_data[uli_offset+2].unpack("h*")[0].to_i
      uli[:uli_tac] = payload_data[uli_offset+3..uli_offset+4].unpack("H*")[0].hex

      uli_offset += 5
    end

    # Parse ECGI Field
    if uli_flag[:ecgi_present_flag] > 0
      uli[:uli_mcc] = (payload_data[uli_offset].unpack("h*")[0] << (payload_data[uli_offset+1].unpack("C")[0] & 0b00001111).to_s).to_i
      uli[:uli_mnc] = payload_data[uli_offset+2].unpack("h*")[0].to_i
      uli[:uli_eci] = payload_data[uli_offset+3..uli_offset+6].unpack("H*")[0].hex
      uli[:uli_enb_id] = payload_data[uli_offset+3..uli_offset+5].unpack("H*")[0].hex
      uli[:uli_cell_id] = payload_data[uli_offset+6].unpack("H*")[0].hex

      uli_offset += 7
    end

    # Parse LAI Field
    if uli_flag[:lai_present_flag] > 0
      uli[:uli_mcc] = (payload_data[uli_offset].unpack("h*")[0] << (payload_data[uli_offset+1].unpack("C")[0] & 0b00001111).to_s).to_i
      uli[:uli_mnc] = payload_data[uli_offset+2].unpack("h*")[0].to_i
      uli[:uli_lac] = payload_data[uli_offset+3..uli_offset+4].unpack("H*")[0].hex

      uli_offset += 6
    end
    
    return uli
  end
  
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get F-TEID data. IE Type Value : 087
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_f_teid(payload_data)
    f_teid = {}
        
    f_teid_v4v6_type_val      = (payload_data[0].unpack("C")[0] & 0b11000000) >> 6
    f_teid_interface_type_val = (payload_data[0].unpack("C")[0] & 0b00111111)
    
    case f_teid_v4v6_type_val
    when 2 then f_teid = {:f_teid_v4v6 => "IPv4", :f_teid_interface => nil, :f_teid_gre_key => nil, :f_teid_addr => nil}
    when 1 then f_teid = {:f_teid_v4v6 => "IPv6", :f_teid_interface => nil, :f_teid_gre_key => nil, :f_teid_addr => nil}
    else f_teid = {:f_teid_v4v6 => nil, :f_teid_interface => nil, :f_teid_gre_key => nil, :f_teid_addr => nil}
    end

    case f_teid_interface_type_val
    when S5_S8_PGW_PMIPv6                               then f_teid_interface = "S5/S8 PGW PMIPv6"
    when S11_MME_GTP_C                                  then f_teid_interface = "S11 MME GTP-C"

    when S1_U_ENODEB_GTP_U                              then f_teid_interface = "S1-U eNodeB GTP-U interface"
    when S1_U_SGW_GTP_U                                 then f_teid_interface = "S1-U SGW GTP-U interface"
    when S12_RNC_GTP_U                                  then f_teid_interface = "S12 RNC GTP-U interface"
    when S12_SGW_GTP_U                                  then f_teid_interface = "S12 SGW GTP-U interface"
    when S5_S8_SGW_GTP_U                                then f_teid_interface = "S5/S8 SGW GTP-U interface"
    when S5_S8_PGW_GTP_U                                then f_teid_interface = "S5/S8 PGW GTP-U interface"
    when S5_S8_SGW_GTP_C                                then f_teid_interface = "S5/S8 SGW GTP-C interface"
    when S5_S8_PGW_GTP_C                                then f_teid_interface = "S5/S8 PGW GTP-C interface"
    when S5_S8_SGW_PMIPv6_NOT_USED_CPLANE               then f_teid_interface = "S5/S8 SGW PMIPv6 interface(since alternate CoA is not used the c-plane)"
    when S5_S8_PGW_PMIPv6                               then f_teid_interface = "S5/S8 PGW PMIPv6 interface"
    when S11_MME_GTP_C                                  then f_teid_interface = "S11 MME GTP-C interface"
    when S11_S4_SGW_GTP_C                               then f_teid_interface = "S11/S4 SGW GTP-C interface"
    when S10_MME_GTP_C                                  then f_teid_interface = "S10 MME GTP-C interface"
    when S3_MME_GTP_C                                   then f_teid_interface = "S3 MME GTP-C interface"
    when S3_SGSN_GTP_C                                  then f_teid_interface = "S3 SGSN GTP-C interface"
    when S4_SGSN_GTP_U                                  then f_teid_interface = "S4 SGSN GTP-U interface"
    when S4_SGW_GTP_U                                   then f_teid_interface = "S4 SGW GTP-U interface"
    when S4_SGSN_GTP_C                                  then f_teid_interface = "S4 SGSN GTP-C interface"
    when S16_SGSN_GTP_C                                 then f_teid_interface = "S16 SGSN GTP-C interface"
    when ENODEB_GTP_U_INTERFACE_FOR_DL_DATA_FORWARDING  then f_teid_interface = "eNodeB GTP-U interface for DL data forwarding"
    when ENODEB_GTP_U_INTERFACE_FOR_UL_DATA_FORWARDING  then f_teid_interface = "eNodeB GTP-U interface for UL data forwarding"
    when RNC_GTP_U_INTERFACE_FOR_DATA_FORWARDING        then f_teid_interface = "RNC GTP-U interface for data forwarding"
    when SGSN_GTP_U_INTERFACE_FOR_DATA_FORWARDING       then f_teid_interface = "SGSN GTP-U interface for data forwarding"
    when SGW_GTP_U_INTERFACE_FOR_DL_DATA_FORWARDING     then f_teid_interface = "SGW GTP-U interface for DL data forwarding"
    when SM_MBMS_GW_GTP_C                               then f_teid_interface = "Sm MBMS GW GTP-C interface"
    when SN_MBMS_GW_GTP_C                               then f_teid_interface = "Sn MBMS GW GTP-C interface"
    when SM_MME_GTP_C                                   then f_teid_interface = "Sm MME GTP-C interface"
    when SN_SGSN_GTP_C                                  then f_teid_interface = "Sn SGSN GTP-C interface"
    when SGW_GTP_U_INTERFACE_FOR_UL_DATA_FORWARDING     then f_teid_interface = "SGW GTP-U interface for UL data forwarding"
    when SN_SGSN_GTP_U                                  then f_teid_interface = "Sn SGSN GTP-U  interface"
    when S2B_EPDG_GTP_C                                 then f_teid_interface = "S2b ePDG GTP-C interface"
    when S2B_U_EPDG_GTP_U                               then f_teid_interface = "S2b-U ePDG GTP-U interface"
    when S2B_PGW_GTP_C                                  then f_teid_interface = "S2b PGW GTP-C interface"
    when S2B_U_PGW_GTP_U                                then f_teid_interface = "S2b-U PGW GTP-U interface"
    when S2A_TWAN_GTP_U                                 then f_teid_interface = "S2a TWAN GTP-U interface"
    when S2A_TWAN_GTP_C                                 then f_teid_interface = "S2a TWAN GTP-C interface"
    when S2A_PGW_GTP_C                                  then f_teid_interface = "S2a PGW GTP-C interface"
    when S2A_PGW_GTP_U                                  then f_teid_interface = "S2a PGW GTP-U interface"
    else return f_teid
    end
    
    f_teid[:f_teid_interface] = f_teid_interface

    f_teid[:f_teid_gre_key] = payload_data[1..4].unpack("N*")[0]
    
    case f_teid_v4v6_type_val
    when 2 then f_teid_addr = payload_data[5..8].unpack("C4").join(".")
    when 1 then f_teid_addr = ""
    else f_teid_addr = ""
    end
    
    f_teid[:f_teid_addr] = f_teid_addr

    return f_teid
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get Bearer Context data. IE Type Value : 093
  # @param [String]    payload_data       gtp packet payload body data.
  # @param [Integer] bearer_context_length      ie_length
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_bearer_context(payload_data, bearer_context_length)
    bearer_context = {}
    
    while bearer_context_length > 1
      ie_type = payload_data[0].unpack("H*")[0].hex
      ie_length = payload_data[1..2].unpack("H*")[0].hex
      type_length_size = 4
      
      ie_data = payload_data[type_length_size..type_length_size+ie_length-1]
      
      case ie_type
      when EBI          then bearer_context[:bearer_ebi] = parse_ie_ebi(ie_data).values[0]
      when BEARER_TFT   then bearer_context[:bearer_tft] = parse_ie_bearer_tft(ie_data).values[0]
      when CAUSE        then
        parse_ie_cause(ie_data).each{|key, value|
          case key
          when :cause_val then bearer_context[:bearer_cause_val] = value
          when :cause_pce then bearer_context[:bearer_cause_pce] = value
          when :cause_bce then bearer_context[:bearer_cause_bce] = value
          when :cause_cs  then bearer_context[:bearer_cause_cs]  = value
          else next
          end
        }
      when F_TEID then 
        parse_ie_f_teid(ie_data).each{|key, value|
          case key
          when :f_teid_v4v6      then bearer_context[:bearer_f_teid_v4v6]      = value
          when :f_teid_interface then bearer_context[:bearer_f_teid_interface] = value
          when :f_teid_gre_key   then bearer_context[:bearer_f_teid_gre_key]   = value
          when :f_teid_addr      then bearer_context[:bearer_f_teid_addr]      = value
          else next
          end        
        }
      when BEARER_QOS   then parse_ie_bearer_qos(ie_data).each{|key, value| bearer_context[key] = value}
      when CHARGING_ID  then bearer_context[:bearer_charging_id] = parse_ie_charging_id(ie_data).values[0]
      when BEARER_FLAGS then parse_ie_bearer_flags(ie_data).each{|key, value| bearer_context[key] = value}
      end
      
      payload_data = payload_data[ie_length+type_length_size..-1]
      bearer_context_length = bearer_context_length - (ie_length+type_length_size)
    end

    return bearer_context
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get Charging ID data. IE Type Value : 094
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_charging_id(payload_data)   
    bearer_charging_id = {}
    
    bearer_charging_id[:bearer_charging_id] = payload_data.unpack("H*")[0].hex
    
    return bearer_charging_id
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get Charging Characteristics data. IE Type Value : 095
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_charging_characteristics(payload_data)
    charging_characteristics = {}

    charging_characteristics[:charging_characteristics] = payload_data.unpack("H*")[0].hex
    
    return charging_characteristics
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get Trace Information data. IE Type Value : 096
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_trace_information(payload_data)
    trace_info = {}

    trace_info[:trace_info_mcc]                                 = (payload_data[0].unpack("h*")[0] << (payload_data[1].unpack("C")[0] & 0b00001111).to_s).to_i
    trace_info[:trace_info_mnc]                                 = payload_data[2].unpack("h*")[0].to_i
    trace_info[:trace_info_id]                                  = payload_data[3..5].unpack("H*")[0].hex
    trace_info[:trace_info_triggering_events]                   = payload_data[6..14].unpack("H*")[0].hex
    trace_info[:trace_info_list_of_ne_types]                    = payload_data[15..16].unpack("H*")[0].hex
    trace_info[:trace_info_session_trace_depth]                 = payload_data[17].unpack("H*")[0].hex
    trace_info[:trace_info_list_of_interfaces]                  = payload_data[18..29].unpack("H*")[0].hex
    trace_info[:trace_info_ip_addr_of_trace_collection_entity]  = payload_data[30..-1].unpack("H*")[0].hex
  
    return trace_info
  end
  
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get Bearer Flags data. IE Type Value : 097
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_bearer_flags(payload_data)
    bearer_flags = {}
    
    bearer_flags[:bearer_flags_asi]  = (payload_data[0].unpack("C")[0] & 0b00001000) >> 3
    bearer_flags[:bearer_flags_vind] = (payload_data[0].unpack("C")[0] & 0b00000100) >> 2
    bearer_flags[:bearer_flags_vb]   = (payload_data[0].unpack("C")[0] & 0b00000010) >> 1
    bearer_flags[:bearer_flags_ppc]  = (payload_data[0].unpack("C")[0] & 0b00000001)
        
    return bearer_flags
  end
  
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get PDN Type data. IE Type Value : 099
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_pdn_type(payload_data)    
    pdn_type = {}
    pdn_type_val = (payload_data[0].unpack("C")[0] & 0b00000111)
    
    case pdn_type_val
    when 1 then pdn_type_data = "IPv4"
    when 2 then pdn_type_data = "IPv6"
    when 3 then pdn_type_data = "IPv4v6"
    else pdn_type_data = ""
    end

    pdn_type[:pdn_type] = pdn_type_data
    
    return pdn_type
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get UE Time Zone data. IE Type Value : 114
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_ue_time_zone(payload_data)
    ue_tmz = {}
    
    sign = (payload_data[0].unpack("H*")[0].hex & 8) > 0 ? "-" : "+"
    ue_time = (payload_data[0].unpack("H*")[0].hex >> 4) + (payload_data[0].unpack("H*")[0].hex & 7) * 10
    ue_time_hour = ue_time / 4
    ue_time_min = ue_time % 4 * 15
  
    ue_tmz[:ue_time_zone] = "GMT %s %dhours %dminutes" % [sign, ue_time_hour, ue_time_min]
    
    daylight_saving_time_val = payload_data[1].unpack("H*")[0].hex
    
    case daylight_saving_time_val
    when 0 then daylight_saving_time = "No adjustment for Daylight Saving Time."
    when 1 then daylight_saving_time = "+1 hour adjustment for Daylight Saving Time."
    when 2 then daylight_saving_time = "+2 hour adjustment for Daylight Saving Time."
    else daylight_saving_time = "Spare"
    end
    
    ue_tmz[:ue_time_zone_daylight_saving_time] = daylight_saving_time
    
    return ue_tmz
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get APN Restriction data. IE Type Value : 127
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_apn_restriction(payload_data)    
    apn_restriction = {}
    
    apn_restriction_val = payload_data.unpack("H*")[0].to_i

    case apn_restriction_val
    when 1 then apn_restriction_type = "Public-1"
    when 2 then apn_restriction_type = "Public-2"
    when 3 then apn_restriction_type = "Private-1"
    when 4 then apn_restriction_type = "Private-2"
    else apn_restriction_type = "No Existing Contexts or Restriction"
    end
    
    apn_restriction[:apn_restriction] = apn_restriction_type
    
    return apn_restriction
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get Selection Mode data. IE Type Value : 128
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_selection_mode(payload_data)
    selection_mode = {}
    
    selection_mode_val = payload_data.unpack("H*")[0].hex

    case selection_mode_val
    when 0 then selection_mode_data = "MS or network provided APN, subscribed verified"
    when 1 then selection_mode_data = "MS provided APN, subscription not verified"
    when 2 then selection_mode_data = "Network provided APN, subscription not verified"
    else selection_mode_data = "For future use"
    end
    
    selection_mode[:selection_mode] = selection_mode_data
    
    return selection_mode
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get Change Reporting Action data. IE Type Value : 131
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_change_reporting_action(payload_data)
    change_reporting_action = {}

    change_reporting_action[:change_reporting_action] = payload_data.unpack("H*")[0].hex
    
    return change_reporting_action
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get FQ-CSID data. IE Type Value : 132
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_fq_csid(payload_data)
    fq_csid = {}
    
    fq_csid[:fq_csid_node_id_type] = (payload_data[0].unpack("C")[0] & 0b11110000) >> 4
    fq_csid[:fq_csid_num_of_csids] = (payload_data[0].unpack("C")[0] & 0b00001111)
    
    case fq_csid[:fq_csid_node_id_type]
    when 0 then size = 4
    when 1 then size = 16
    else size = 4
    end
    
    fq_csid[:fq_csid_node_id] = payload_data[1..size].unpack("H*")[0].hex
    size += 1
    
    count = 0
    while count < fq_csid[:fq_csid_num_of_csids]
      if fq_csid[:fq_csid_pdn_csid].nil?
        fq_csid[:fq_csid_pdn_csid] = [payload_data[size+count..size+count+1].unpack("H*")[0].hex]
      else
        fq_csid[:fq_csid_pdn_csid] << payload_data[size+count+1..size+count+2].unpack("H*")[0].hex
      end

      count += 1
    end
    
    count == 1 ? fq_csid_pdn_csid = fq_csid[:fq_csid_pdn_csid][0].to_s : fq_csid_pdn_csid = fq_csid[:fq_csid_pdn_csid].join(", ")
    fq_csid[:fq_csid_pdn_csid] = fq_csid_pdn_csid
    
    return fq_csid
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get FQDN data. IE Type Value : 136
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_fqdn(payload_data)
    fqdn = {}
    
    fqdn[:fqdn] = payload_data.unpack("H*")[0].hex
    
    return fqdn
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get UCI data. IE Type Value : 145
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_uci(payload_data)
    uci = {}

    uci[:uci_mcc]         = (payload_data[0].unpack("h*")[0] << (payload_data[1].unpack("C")[0] & 0b00001111).to_s).to_i
    uci[:uci_mnc]         = payload_data[2].unpack("h*")[0].to_i
    
    uci[:uci_csg_id]      = ((payload_data[3].unpack("C")[0] & 0b00000111) << 24) + payload_data[4..6].unpack("H*")[0].hex
    uci[:uci_access_mode] = (payload_data[7].unpack("C")[0] & 0b11000000) >> 6
    uci[:uci_lcsg]        = (payload_data[7].unpack("C")[0] & 0b00000010) >> 1
    uci[:uci_cmi]         = (payload_data[7].unpack("C")[0] & 0b00000001)

    return uci
  end
 
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get CSG Information Reporting Action data. IE Type Value : 146
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_csg_information_reporting_action(payload_data)
    csg_information_reporting_action = {}
    
    csg_information_reporting_action[:csg_information_reporting_action_uciuhc] = (payload_data[0].unpack("C")[0] & 0b00000100) >> 2
    csg_information_reporting_action[:csg_information_reporting_action_ucishc] = (payload_data[0].unpack("C")[0] & 0b00000010) >> 1
    csg_information_reporting_action[:csg_information_reporting_action_ucicsg] = (payload_data[0].unpack("C")[0] & 0b00000001)
    
    return csg_information_reporting_action
  end
 
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get LDN data. IE Type Value : 151
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_ldn(payload_data)
    ldn = {}
    local_distinguished_name = ""

    payload_data.each_byte{|str|
      str = 46 if str < 32
      local_distinguished_name += str.chr
    }
    ldn[:ldn] = local_distinguished_name
    
    return ldn
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get LDN data. IE Type Value : 156
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_epc_timer(payload_data)
    epc_timer = {}
        
    epc_timer[:epc_timer_val] = (payload_data[0].unpack("C")[0] & 0b00011111)
    
    epc_timer_unit_val = (payload_data[0].unpack("C")[0] & 0b11100000) >> 5
    
    case epc_timer_unit_val
    when 0 then epc_timer_unit = "value is incremented in multiples of 2 seconds"
    when 1 then epc_timer_unit = "value is incremented in multiples of 1 minute "
    when 2 then epc_timer_unit = "value is incremented in multiples of 10 minutes"
    when 3 then epc_timer_unit = "value is incremented in multiples of 1 hour"
    when 4 then epc_timer_unit = "value is incremented in multiples of 10 hours"
    when 7 then epc_timer_unit = "value indicates that the timer is infinite"
    else epc_timer_unit = "value shall be interpreted as multiples of 1 minute in this version of the protocol"
    end
    
    epc_timer[:epc_timer_unit] = epc_timer_unit
    
    return epc_timer
  end
  
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get Signalling Priority Indication data. IE Type Value : 157
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_signalling_priority_indication(payload_data)
    signalling_priority_indication = {}
    
    signalling_priority_indication[:signalling_priority_indication] = payload_data[0].unpack("H*")[0].hex
    
    return signalling_priority_indication
  end
    
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get APCO data. IE Type Value : 163
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_apco(payload_data)    
    apco = {}
    
    apco[:apco] = payload_data.unpack("H*")[0].hex
    
    return apco
  end
  
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get H(e)NB Information Reporting data. IE Type Value : 165
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_hnb_information_reporting(payload_data)
    hnb_information_reporting = {}
    
    hnb_information_reporting[:hnb_information_reporting] = payload_data[0].unpack("H*")[0].hex
    
    return hnb_information_reporting
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get IPv4 Configuration Parameters data. IE Type Value : 166
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_ip4cp(payload_data)
    ip4cp = {}
    
    ip4cp[:ip4cp_subnet_prefix_length] = payload_data[0].unpack("H*")[0].hex
    ip4cp[:ip4cp_ipv4_default_router_addr] = payload_data[1..-1].unpack("C4").join(".")
    
    return ip4cp
  end
  
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get TWAN Identifier data. IE Type Value : 169
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_twan_identifier(payload_data)
    twan_identifier = {}
    bssidi      = payload_data[0].unpack("H*")[0].hex
    ssid_length = payload_data[1].unpack("H*")[0].hex
    
    if bssidi > 0
      twan_identifier = {:twan_identifier_bssidi => bssidi, :twan_identifier_ssid => nil, :twan_identifier_bssid => nil}
      twan_identifier[:twan_identifier_bssid] = payload_data[2+ssid_length..2+ssid_length+5].unpack("H*")[0]
    else
      twan_identifier = {:twan_identifier_bssidi => bssidi, :twan_identifier_ssid => nil}
    end
        
    twan_identifier[:twan_identifier_ssid] = payload_data[2..2+ssid_length-1].unpack("H*")[0]
    
    return twan_identifier
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  # Get Private Extension data. IE Type Value : 255
  # @param [String]    payload_data       gtp packet payload body data.
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
  def parse_ie_private_extension(payload_data)
    private_extension = {}
    
    private_extension[:private_extension_enterprise_id] = payload_data[0..1].unpack("H*")[0].hex
    private_extension[:private_extension_proprietary_val] = payload_data[2..-1].unpack("H*")[0]
    
    return private_extension
  end
end


