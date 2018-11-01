#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

STDOUT.sync = true

require 'pcap'
require 'ipaddr'
require 'time'

require 'optparse'
opt = OptionParser.new
options = {}

options[ :time_unit ] = 1

# option parser
opt.banner = "Usage: #{File.basename($0)} [options] pcapfiles"
opt.on( '-u unit'       , '--time-unit unit'                        , 'time unit in sec' ) {|v| options[ :time_unit ] = v.to_i }
opt.on( '-e ip_addr'    , '--enodeb-ip-addr ip_addr'                , 'set eNodeB ip address (ip address block is also acceptable)' ) {|v| options[ :enodeb_ip_addr ] = IPAddr.new( v ) }
opt.on( '-h'            , '--help'                                  , 'show help' ) { print opt.help; exit }
opt.on(                   '--version'                               , 'show version' ) { puts options[:version]; exit }
opt.permute!( ARGV )

if ARGV.empty?
  print opt.help
  exit
else
  options[:infiles] = ARGV
end


class Pcap::Packet

  def gtp?
    if self.udp? and ( self.dport == 2152 or self.sport == 2152 )
      return true
    else
      return false
    end
  end

  def gpdu?
    return false unless self.gtp?
    self.udp_data[ 1 ].unpack( 'C' )[ 0 ] == 255
  end

  def gtp_header_len
    return nil unless self.gtp?
    offset = 8
    extension_header_flag = ( self.udp_data[ 0 ].unpack( 'C' )[ 0 ] & 0b00000100 ) != 0
    sequence_number_flag  = ( self.udp_data[ 0 ].unpack( 'C' )[ 0 ] & 0b00000010 ) != 0
    npdu_number_flag      = ( self.udp_data[ 0 ].unpack( 'C' )[ 0 ] & 0b00000001 ) != 0
    if extension_header_flag or sequence_number_flag or npdu_number_flag
      offset += 4
      next_header_type = self.udp_data[ offset - 1 ].unpack( 'C' )[ 0 ]
      while next_header_type != 0 and extension_header_flag
        offset += self.udp_data[ offset ].unpack( 'C' )[ 0 ] * 4
        next_header_type = self.udp_data[ offset - 1 ].unpack( 'C' )[ 0 ]
      end
    end
    offset
  end

  def gtp_data
    return nil unless self.gtp?
    self.udp_data[ self.gtp_header_len..-1 ]
  end

  def userip4?
    self.gpdu? and self.user_packet.ip_ver == 4
  end

  def user_packet
    if self.gpdu?
      return Pcap::Capture.object_reset( self, gtp_data.size )
    else
      return nil
    end
  end

end


TCP_SEQ_MAX = 2 ** 32

def params_template
  {
    :n_resent_packets  => 0,
    :sent_data         => 0,
    :acked_data        => 0,
    :active_sessions   => {},
    :active_users      => {},
  }
end
bins = []


base_time = nil
sent_seq = Hash.new{|h, k| h[k] = []}
last_ack = {}

options[:infiles].uniq.sort.each_with_index do |file, index|
  cap = Pcap::Capture.open_offline( file )
  cap.each do |packet|
    gtp_dst = packet.ip_dst
    if user_packet = packet.user_packet and user_packet.tcp?
      base_time ||= user_packet.time
      relative_time = user_packet.time - base_time
      bin_index = ( relative_time / options[ :time_unit ] ).to_i
      bins[ bin_index ] ||= params_template
      bin = bins[ bin_index ]
      is_forward = ( options[ :enodeb_ip_addr ].include? gtp_dst )

      forward_key = [ user_packet.ip_src, user_packet.ip_dst, user_packet.tcp_sport, user_packet.tcp_dport ]
      reverse_key = [ user_packet.ip_dst, user_packet.ip_src, user_packet.tcp_dport, user_packet.tcp_sport ]

      if is_forward and user_packet.tcp_data_len > 0
        if sent_seq[ forward_key ].include? user_packet.tcp_seq
          bin[ :n_resent_packets ] += 1
        else
          bin[ :sent_data ] += user_packet.tcp_data_len
        end
        sent_seq[ forward_key ] << user_packet.tcp_seq
      end

      if ( not is_forward ) and user_packet.tcp_ack?
        if last_ack[ reverse_key ]
          diff = ( user_packet.tcp_ack - last_ack[ reverse_key ] ) % TCP_SEQ_MAX
          bin[ :acked_data ] += diff if diff < TCP_SEQ_MAX / 2
        end
        last_ack[ reverse_key ] = user_packet.tcp_ack
      end

      bin[ :active_sessions ][ is_forward ? forward_key : reverse_key ] = true
      bin[ :active_users ][ is_forward ? user_packet.ip_dst : user_packet.ip_src ] = true
    end
  end
end

File.open( File.basename( options[:infiles].first, '.pcap' ) + '_analysis.csv', 'w' ) do |f|
  f.write( "time_relative[sec],sent_data[byte],acked_data[byte],n_active_sessions,n_active_users,n_resent_packets\n" )
  bins.each_with_index do |bin, i|
    next unless bin
    f.write( "#{ i * options[ :time_unit ] },#{ bin[ :sent_data ] },#{ bin[ :acked_data ] },#{ bin[ :active_sessions ].size },#{ bin[ :active_users ].size },#{ bin[ :n_resent_packets ] }\n")
  end
end
