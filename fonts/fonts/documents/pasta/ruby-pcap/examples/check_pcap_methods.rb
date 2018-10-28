#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
require 'pcap'
require 'logger'

cap = Pcap::Capture.open_offline( ARGV[0] )


count = 0

cap.each do |packet|
  begin
    count = count + 1
    if packet.ethernet?
      packet.ethernet_headers.each do |ether_header|
        ether_header.dst_mac_i
        ether_header.dst_mac
        ether_header.src_mac_i
        ether_header.src_mac
        ether_header.vlan?
        ether_header.eoe?
        ether_header.pbb?
        ether_header.tags.class
        ether_header.tags.each do |ether_tag|
          ether_tag.tpid
          ether_tag.pcp
          ether_tag.cfi
          ether_tag.vid
          ether_tag.ttl
          ether_tag.eid
          ether_tag.itag_pcp
          ether_tag.itag_dei
          ether_tag.flag_uca
          ether_tag.flag_res1
          ether_tag.flag_res2
          ether_tag.itag_ttl_flag
          ether_tag.itag_sid
          ether_tag.vlan?
          ether_tag.eoe?
        end
      end
    end
    next unless packet.ip?

    packet.ip_data
    packet.ip_df?
    packet.ip_ver
    packet.ipv4?
    packet.ipv6?
    packet.class
    packet.ip_next
    packet.ip_dst
    packet.ip_dst_i
    packet.ip_dst_s
    packet.dst
    packet.dst_i
    packet.dst_s
    packet.ip_src
    packet.ip_src_i
    packet.ip_src_s
    packet.src
    packet.src_i
    packet.src_s
    packet.ip_flags
    packet.ip_flow
    packet.ip_hlen
    packet.ip_header_length
    packet.ip_plen
    packet.ip_payload_length
    packet.ip_id
    packet.ip_total_length
    packet.ip_len
    packet.ip_mf?
    packet.ip_off
    packet.ip_proto
    packet.ip_sum
    packet.ip_tos
    packet.ip_ttl
    packet.ip_hoplimit
    packet.to_s

    #TCP
    if packet.tcp?
      packet.dport
      packet.dst_mac_address
      packet.sport
      packet.src_mac_address
      packet.tcp_ack
      packet.tcp_ack?
      packet.tcp_data
      packet.tcp_data_len
      packet.tcp_fin?
      packet.tcp_flags
      packet.tcp_flags_s
      packet.tcp_hlen
      packet.tcp_off
      packet.tcp_psh?
      packet.tcp_rst?
      packet.tcp_seq
      packet.tcp_sum
      packet.tcp_syn?
      packet.tcp_urg?
      packet.tcp_urp
      packet.tcp_win
      packet.to_s
      next
    end

    #UDP
    if packet.udp?
      packet.dport
      packet.sport
      packet.to_s
      packet.udp_data
      packet.udp_dport
      packet.udp_len
      packet.sport
      packet.udp_sum
      next
    end

  rescue => e
    p "Count #{count}"
    p "Error #{e.message}"
    next
  end
end
p "complete"

