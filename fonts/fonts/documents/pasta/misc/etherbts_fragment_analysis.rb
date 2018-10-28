#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

STDOUT.sync = true

require 'pcap'
require 'ipaddr'
require 'time'

require 'optparse'
opt = OptionParser.new
options = {}

# option parser

opt.banner = "Usage: #{File.basename($0)} [options] pcapfiles"
opt.on( '-h'            , '--help'                                  , 'show help' ) { print opt.help; exit }
opt.on(                   '--version'                               , 'show version' ) { puts options[:version]; exit }
opt.permute!( ARGV )

if ARGV.empty?
  print opt.help
  exit
else
  options[:infiles] = ARGV
end


class IPAddr
  LTE_NET_FOR_DATA_IPADDR = 
  {
    :type1 => [
      '106.140.0.0/16', '106.141.0.0/16', '106.142.0.0/16', '106.143.0.0/16', '106.144.0.0/16', '106.145.0.0/16',
      '106.135.0.0/16',
      '106.148.0.0/16',
    ].map{|x| IPAddr.new( x )},
    :type2 => [
      '106.136.0.0/16', '106.137.0.0/16', '106.138.0.0/16', '106.139.0.0/16', '106.146.0.0/16',
      '111.236.0.0/16', '111.237.0.0/16', '111.238.0.0/16', '111.239.0.0/16',
      '36.9.0.0/16', '36.10.0.0/16', '36.11.0.0/16', '36.12.0.0/16', '36.13.0.0/16', '36.14.0.0/16', '36.15.0.0/16',
      '14.14.0.0/16', '14.15.0.0/16',
      '59.136.0.0/16', '59.138.0.0/16',
      '106.161.0.0/16', '106.175.0.0/16', '106.178.0.0/16', '106.179.0.0/16', '106.180.0.0/16', '106.181.0.0/16', '106.182.0.0/16',
      '119.104.0.0/16',
    ].map{|x| IPAddr.new( x )},
  }

  def lte_net_for_data_type
    LTE_NET_FOR_DATA_IPADDR.each_pair do |type, ranges|
      ranges.each do |range|
        return type if range.include? self
      end
    end
    nil
  end
end


class Pcap::Packet

  EPC_IPADDR = IPAddr.new( '10.152.0.0/16' )
  ENB_IPADDR = IPAddr.new( '10.172.0.0/16' )

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
    self.gpdu? and ( ( self.gtp_data[ 0 ].unpack( 'C' )[ 0 ] & 0b11110000 ) >> 4 ) == 4
  end

  def is_forward?
    self.ip? and EPC_IPADDR.include?( self.ip_src ) and ENB_IPADDR.include?( self.ip_dst )
  end

end


type_dictionary = {}

n_packets = {
  :all            => {
    :all            => { true => 0, false => 0 },
    :ip             => { true => 0, false => 0 },
    :gtp            => { true => 0, false => 0 },
    :gpdu           => { true => 0, false => 0 },
    :fragment       => { true => 0, false => 0 },
    :userip4        => { true => 0, false => 0 },
  },
  :type1          => {
    :fragment       => { true => 0, false => 0 },
  },
  :type2          => {
    :fragment       => { true => 0, false => 0 },
  },
  :lte_net          => {
    :fragment       => { true => 0, false => 0 },
  },
}

size_of_fragment = {
  :all     => Array.new( 1_600, 0 ),
  :lte_net => Array.new( 1_600, 0 ),
  :type1   => Array.new( 1_600, 0 ),
  :type2   => Array.new( 1_600, 0 ),
}

size_of_gtp_header = Array.new( 256, 0 )

first_fragment_timestamp = {}
FRAGMENT_DELAY_MAX = 1_000
fragment_delay = Array.new( FRAGMENT_DELAY_MAX, 0 )


# make a dictionary of lte net for data
options[:infiles].uniq.sort.each_with_index do |file, index|
  cap = Pcap::Capture.open_offline( file )
  cap.each do |packet|
    if packet.ip?
      ip_key = [ packet.ip_src_i, packet.ip_dst_i, packet.ip_id ]
      first_fragment_timestamp[ ip_key ] = packet.time if packet.ip_mf?
    end
    if packet.userip4?
      src_ipaddr_type = IPAddr.new( packet.gtp_data[ 12, 4 ].unpack( 'N' )[ 0 ], Socket::AF_INET ).lte_net_for_data_type
      dst_ipaddr_type = IPAddr.new( packet.gtp_data[ 16, 4 ].unpack( 'N' )[ 0 ], Socket::AF_INET ).lte_net_for_data_type
      type_dictionary[ [ packet.ip_src_i, packet.ip_dst_i, packet.ip_id ] ] = ( src_ipaddr_type or dst_ipaddr_type or :lte_net )
    end
  end
end


# main
options[:infiles].uniq.sort.each_with_index do |file, index|
  cap = Pcap::Capture.open_offline( file )
  cap.each do |packet|
    next unless packet.is_forward?

    n_packets[ :all ][ :all ][ true ] += 1
    n_packets[ :all ][ :ip ][ packet.ip? ] += 1
    n_packets[ :all ][ :gtp ][ packet.gtp? ] += 1
    n_packets[ :all ][ :gpdu ][ packet.gpdu? ] += 1
    n_packets[ :all ][ :userip4 ][ packet.userip4? ] += 1
    size_of_gtp_header[ packet.gtp_header_len ] += 1 if packet.gtp?

    ip_key = [ packet.ip_src_i, packet.ip_dst_i, packet.ip_id ]
    if packet.ip? and ( packet.userip4? or packet.ip_off != 0 ) and type = type_dictionary[ ip_key ]
      if packet.ip_off != 0 and first_fragment_timestamp[ ip_key ]
        diff = ( ( packet.time - first_fragment_timestamp[ ip_key ] ) * 1_000_000 ).to_i.abs
        fragment_delay[ [ diff, FRAGMENT_DELAY_MAX - 1 ].min ] += 1
#        p packet.time.iso8601(6)
      end
      fragmented = ( packet.ip_mf? or packet.ip_off != 0 )
      n_packets[ :all ][ :fragment ][ fragmented ] += 1
      n_packets[ type ][ :fragment ][ fragmented ] += 1
      if fragmented
        size_of_fragment[ :all ][ packet.size ] += 1
        size_of_fragment[ type ][ packet.size ] += 1
      end
    end
  end
  cap.close
end

p fragment_delay
p n_packets
p size_of_fragment
p size_of_gtp_header
