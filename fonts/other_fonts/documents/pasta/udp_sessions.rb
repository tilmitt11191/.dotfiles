# -*- encoding: utf-8 -*-

require_relative 'dns_parser.rb'

require 'pcap'
require 'ipaddr'
require 'digest/md5'
require 'time'

# UDPP session determined by four tuple (source/destination ip addresss/port number).
# The class treats udp sessions as simple bitstreams.
class UDPSession
  # Construct a new instance.
  def initialize( options )
    @@options = options
    @first_packet = {:FORWARD => nil, :REVERSE => nil}
    @last_packet  = {:FORWARD => nil, :REVERSE => nil}
    @n_packets    = {:FORWARD =>   0, :REVERSE =>   0}
    @size         = {:FORWARD =>   0, :REVERSE =>   0}
  end

  # Receive a new packet.
  # @param [IPPacket] pkt                An IP packet object.
  def receive( pkt )
    if @first_packet[:FORWARD] == nil
      @first_packet[:FORWARD] = pkt
      direction = :FORWARD
    elsif @first_packet[:FORWARD].ip_src == pkt.ip_src and @first_packet[:FORWARD].ip_dst == pkt.ip_dst and
          @first_packet[:FORWARD].sport == pkt.sport and @first_packet[:FORWARD].dport == pkt.dport
      direction = :FORWARD
    elsif @first_packet[:REVERSE] == nil and
          @first_packet[:FORWARD].ip_src == pkt.ip_dst and @first_packet[:FORWARD].ip_dst == pkt.ip_src and
          @first_packet[:FORWARD].sport == pkt.dport and @first_packet[:FORWARD].dport == pkt.sport
      @first_packet[:REVERSE] = pkt
      direction = :REVERSE
    elsif @first_packet[:FORWARD].ip_src == pkt.ip_dst and @first_packet[:FORWARD].ip_dst == pkt.ip_src and
          @first_packet[:FORWARD].sport == pkt.dport and @first_packet[:FORWARD].dport == pkt.sport
      direction = :REVERSE
    else
      raise 'assert in udp packet receiver'
    end
    @n_packets[direction] += 1
    @size[direction] += pkt.udp_len
    @last_packet[direction] = pkt
  end

  # Check if the UDP session is closed (timeouted).
  # @param [Time] time                Current time.
  # @param [Time] udp_timeout         Timeout threshold in sec.
  # @return [Boolean]  Return true is the UDP session is closed (timeouted).
  def closed?( time, udp_timeout )
    last_time = [@last_packet[:FORWARD] ? @last_packet[:FORWARD].time : Time.at(0),
                 @last_packet[:REVERSE] ? @last_packet[:REVERSE].time : Time.at(0)].max
    time - last_time > udp_timeout
  end

  # @param [IPPacket] value  first received packet in the UDP session.
  attr_reader :first_packet
  # @param [IPPacket] value  last received packet in the UDP session.
  attr_reader :last_packet
  # @param [Integer] value  number of packets received in the UDP session.
  attr_reader :n_packets
  # @param [Hash] value  total octets received in the UDP session in the :FORWARD/:REVERSE direction.
  attr_reader :size
end


# An container of UDP sessions.
# The class provides a function to sort incoming IP packets into appropriate UDP session insntance automatically.
class UDPSessions

  include DNSParser

  # Construct a new instance.
  # @param [Hash] syn_count        syn packet counter to determine the direction of the session.
  # @param [Hash] syn_ack_count    syn+ack packet counter to determine the direction of the session.
  # @param [Hash] options  Options to construct a new insntance.
  # @option options [Integer] :udp_timeout                A threshold for udp timeout.
  # @option options [Float]   :sampling_ratio             A sampling ratio, which must be between 0.0 and 1.0. nil makes total inspection.
  # @option options [String]  :hash_salt                  A hash salt for hashing private information.
  # @option options [Hash]    :subnet_prefix_length       Subnet mask lengths of IPv4/IPv6 for "src_ipaddr_subnet_prefix" field
  # @option options [Boolean] :plain_text                 Set true to keep original private information.
  def initialize( syn_count, syn_ack_count, options )
    @sessions = Hash.new
    @syn_count = syn_count
    @syn_ack_count = syn_ack_count
    @options = options
  end

  # Receive a new packet.
  # @param [IPPacket] pkt                An IP packet object.
  def receive( pkt )
    raise 'not udp!'  unless pkt.udp?
    if @sessions[ reverse_key = pkt.ip_dst_s + ',' + pkt.ip_src_s + ',' + pkt.dport.to_s + ',' + pkt.sport.to_s ]
      key = reverse_key
    elsif @sessions[ forward_key = pkt.ip_src_s + ',' + pkt.ip_dst_s + ',' + pkt.sport.to_s + ',' + pkt.dport.to_s ]
      key = forward_key
    elsif (!@options[:sampling_ratio] or (Digest::MD5.hexdigest( pkt.ip_src_s ).to_i(16) % (2 ** 32)).to_f / (2 ** 32).to_f < @options[:sampling_ratio])
      key = forward_key
      @sessions[key] = UDPSession.new( @options )
    else
      return []
    end
    @sessions[key].receive pkt
  end

  # Check if each UDP session is timeouted, and return an Array including closed session information.
  # @param [Time] time                Current time.
  # @return [Array]  Return a list of formatted information of closed UDP sessions.
  def timeout_check( time )
    ret = []
    @sessions.each_key do |key|
      if @sessions[key].closed? time, @options[:udp_timeout]
        ret << format_udp_info( @sessions[key] )
        @sessions.delete key
      end
    end
    ret
  end

  # Close all sessions forcefully, and return session informaion of closed UDP sessions.
  # @return [Array]  Return a list of formatted information of closed UDP sessions.
  # @note  This method shold only be used at the end of the whole process to squeeze out remaining sessions.
  def force_close_all()
    ret = []
    @sessions.each_key do |key|
      ret << format_udp_info( @sessions[key] )
      @sessions.delete key
    end
    ret
  end

  private

  def format_udp_info( session )
    fp = session.first_packet
    lp = session.last_packet

    if ( fp[:REVERSE] and @syn_count[fp[:FORWARD].ethernet_headers[0].dst_mac + fp[:FORWARD].ethernet_headers[0].src_mac] >= @syn_count[fp[:REVERSE].ethernet_headers[0].dst_mac + fp[:REVERSE].ethernet_headers[0].src_mac]) or
       (!fp[:REVERSE] and @syn_count[fp[:FORWARD].ethernet_headers[0].dst_mac + fp[:FORWARD].ethernet_headers[0].src_mac] >= @syn_ack_count[fp[:FORWARD].ethernet_headers[0].dst_mac + fp[:FORWARD].ethernet_headers[0].src_mac])
      upload = :FORWARD
      download = :REVERSE
      ip_src = fp[:FORWARD].ip_src_s
      ip_src_ipaddr = fp[:FORWARD].ip_src
      ip_dst = fp[:FORWARD].ip_dst_s
      sport = fp[:FORWARD].sport
      dport = fp[:FORWARD].dport
    else
      upload = :REVERSE
      download = :FORWARD
      ip_src = fp[:FORWARD].ip_dst_s
      ip_src_ipaddr = fp[:FORWARD].ip_src
      ip_dst = fp[:FORWARD].ip_src_s
      sport = fp[:FORWARD].dport
      dport = fp[:FORWARD].sport
    end

    if dst_has_dns_port?(dport, sport)
      dns_port = dport
      dns_download = download
    else
      dns_port = sport
      dns_download = download == :REVERSE ? :FORWARD : :REVERSE
    end

    {'udp' => [
               [
                [fp[:FORWARD] ? fp[:FORWARD].time : Time.at(2**32), fp[:REVERSE] ? fp[:REVERSE].time : Time.at(2**32)].min.iso8601(6),
                [lp[:FORWARD] ? lp[:FORWARD].time : Time.at(0), lp[:REVERSE] ? lp[:REVERSE].time : Time.at(0)].max.iso8601(6),
                [fp[:FORWARD] ? fp[:FORWARD].time : Time.at(2**32), fp[:REVERSE] ? fp[:REVERSE].time : Time.at(2**32)].min.to_f.to_s,
                [lp[:FORWARD] ? lp[:FORWARD].time : Time.at(0), lp[:REVERSE] ? lp[:REVERSE].time : Time.at(0)].max.to_f.to_s,
                fp[upload] ? fp[upload].ethernet_headers[0].src_mac : nil,
                fp[upload] ? fp[upload].ethernet_headers[0].dst_mac : nil,
                fp[download] ? fp[download].ethernet_headers[0].src_mac : nil,
                fp[download] ? fp[download].ethernet_headers[0].dst_mac : nil,
                fp[:FORWARD].ip_ver,
                @options[:plain_text] ? ip_src : Digest::MD5.hexdigest(ip_src + @options[:hash_salt]),
                ip_src_ipaddr.mask(@options[:subnet_prefix_length][fp[:FORWARD].ip_ver]).to_s + '/' + @options[:subnet_prefix_length][fp[:FORWARD].ip_ver].to_s,
                ip_dst,
                sport,
                dport,
                session.size[upload],
                session.size[download],
                session.n_packets[upload],
                session.n_packets[download],
               ] + format_dns_info( fp, dns_download, dns_port )
              ]
    }
  end

  def dst_has_dns_port?(dport, sport)
    return true  if dport == DNS_SERVER_DST_PORT
    return false if sport == DNS_SERVER_DST_PORT
    true
  end

  def format_dns_info( fp, download, dport )
    dns_request = nil
    dns_response = nil
    return [nil, nil] unless fp[download] and (dport == DNS_SERVER_DST_PORT)
    parsed_dns = get_parsed_dns( fp[download].udp_data )

    begin
      dns_request = [parsed_dns[:question_section].first[:qtype], parsed_dns[:question_section].first[:qname]].join(':')
      return [dns_request, nil] unless parsed_dns[:answer_section]
      dns_response = format_dns_response( parsed_dns )
    rescue
      return [nil, nil]
    end
    return [dns_request, dns_response]
  end

  def format_dns_response( parsed_dns )
    parsed_dns_array = []
    parsed_dns[:answer_section].each{|answer|
      rdata_ary = []
      search_rdata_type( answer ).each{|rdata_type, rdata|
        rdata_ary << [rdata_type, rdata].join('#')
       }
      rdata_ary << "ttl##{answer[:ttl]}"
      parsed_dns_array << [answer[:type], rdata_ary.join('%')].join(':')
     }
    dns_response = parsed_dns_array.join('/')
  end

end
