#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require_relative 'gtp_parser.rb'

# GTP Port No.
GTPC_V2_PORT = 2123

# UDPP session determined by four tuple (source/destination ip addresss/port number).
# The class treats udp sessions as simple bitstreams.
class GTPSession

  include GTPParser

  # Construct a new instance.
  def initialize( options )
    @@options = options
  end

  # Receive a new packet.
  # @param [IPPacket] pkt                An IP packet object.
  def receive( pkt, leading )
    gtp_info = parse_gtp_data(pkt.time, pkt.udp_data, leading, @@options)
    if gtp_info.empty?
      return nil 
    else
      ret = {'gtp'=>[gtp_info]}
      return [ret]
    end
  end

  attr_reader :gtp_session

end

# An container of GTP sessions.
# The class provides a function to sort incoming IP packets into appropriate GTP session insntance automatically.
class GTPSessions

  def initialize( options )
    @sessions = Hash.new
    @options = options
  end

  # Receive a new packet.
  # @param [IPPacket] pkt                An IP packet object.
  def receive( pkt, leading )
    raise 'not udp!'  unless pkt.udp?
    if @sessions[ reverse_key = pkt.ip_dst_s + ',' + pkt.ip_src_s + ',' + pkt.dport.to_s + ',' + pkt.sport.to_s ]
      key = reverse_key
    elsif @sessions[ forward_key = pkt.ip_src_s + ',' + pkt.ip_dst_s + ',' + pkt.sport.to_s + ',' + pkt.dport.to_s ]
      key = forward_key
    elsif leading and (!@options[:sampling_ratio] or (Digest::MD5.hexdigest( pkt.ip_src_s ).to_i(16) % (2 ** 32)).to_f / (2 ** 32).to_f < @options[:sampling_ratio])
      key = forward_key
      @sessions[key] = GTPSession.new( @options )
    else
      return []
    end

    if ret = @sessions[key].receive( pkt, leading )
      @sessions.delete key if @sessions[key].gtp_session.empty?
      return ret
    else
      return []
    end       
  end

  # Check if each GTP session is timeouted, and delete half session information.
  # @param [Time] time                Current time.
  def timeout_check( time )
    @sessions.each_key{|key|
      if @sessions[key].gtp_session
        @sessions[key].gtp_session.each{|sequence_number, gtp_session_value|
          last_time = [gtp_session_value[:REQUEST][:pkt_time] ? gtp_session_value[:REQUEST][:pkt_time] : Time.at(0),
                       gtp_session_value[:RESPONSE][:pkt_time] ? gtp_session_value[:RESPONSE][:pkt_time] : Time.at(0)].max
          if time - last_time > @options[:gtp_timeout]
            @sessions[key].gtp_session.delete sequence_number
            @sessions.delete key if @sessions[key].gtp_session.empty?
          end
        }
      end
    }
  end

  def force_close_all()
    ret = []
    @sessions.each_key do |key|
      @sessions[key].format_gtp_info(@options).each{|gtp_data|
        ret << gtp_data
      }
      @sessions.delete key
    end

    ret
  end

  # Check if the instance holds any session.
  # @return [Boolean]  Return true when no GTP sessions are remaining.
  def empty?
    @sessions.empty?
  end
end
