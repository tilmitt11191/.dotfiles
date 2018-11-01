# -*- encoding: utf-8 -*-

require 'pcap'
require 'ipaddr'
require 'digest/md5'
require 'time'

# Calculate traffic volume from given packets.
# The traffic volume is measured in the determined time unit.
class TrafficVolume

  # Construct a new instance.
  def initialize()
    @n_packets = {:UPLOAD => 0, :DOWNLOAD => 0}
    @size      = {:UPLOAD => 0, :DOWNLOAD => 0}
    @ip_ver    = nil
  end

  # Receive a new packet, and get HTTP/TCP session informaion when the packet closes the session.
  # @param [IPAddr] key                A client IP Address object which is used to determine the direction.
  # @param [IPPacket]  pkt                An IP packet object.
  def receive( key, pkt )
    direction = (pkt.ip_src == key) ? :UPLOAD : :DOWNLOAD
    @n_packets[direction] += 1
    @size[direction] += pkt.ip_total_length
    @ip_ver ||= pkt.ip_ver
  end

  # @param [Integer] value  number of packets received in the instance in the :UPLOAD/:DOWNLOAD direction.
  attr_reader :n_packets
  # @param [Hash] value  total octets received in the insntance in the :UPLOAD/:DOWNLOAD direction.
  attr_reader :size
  # @param [Integer] value  IP version of the first pakcet.
  attr_reader :ip_ver
end


# An container of TrafficVolume
# The class provides a function to sort incoming IP packets into appropriate TrafficVolume instance automatically.
class TrafficVolumes

  # Construct a new instance.
  # @param [Hash] syn_count        syn packet counter to determine the direction of the session.
  # @param [Hash] syn_ack_count    syn+ack packet counter to determine the direction of the session.
  # @param [Hash] options  Options to construct a new insntance.
  # @option options [Integer] :traffic_volume_unit        A traffic volume unit in sec.
  # @option options [Float]   :sampling_ratio             A sampling ratio, which must be between 0.0 and 1.0. nil makes total inspection.
  # @option options [String]  :hash_salt                  A hash salt for hashing private information.
  # @option options [Hash]    :subnet_prefix_length       Subnet mask lengths of IPv4/IPv6 for "src_ipaddr_subnet_prefix" field
  # @option options [Boolean] :plain_text                 Set true to keep original private information.
  def initialize( syn_count, syn_ack_count, options )
    @sessions = Hash.new
    @current_time = nil
    @syn_count = syn_count
    @syn_ack_count = syn_ack_count
    @options = options
  end

  # Receive a new packet.
  # @param [IPPacket] pkt                An IP packet object.
  # @return [Array]  Return a list of formatted information of each traffic volume insntance when it comes to a new time bin.
  def receive( pkt )
    ret = []
    return ret unless pkt.ip?
    @current_time = pkt.time unless @current_time
    if (pkt.time - @current_time) >= @options[:traffic_volume_unit]
      ret = @sessions.to_a.map{|session| format_traffic_volume_info( session[0], session[1] )}
      @sessions.clear
    end
    @current_time += @options[:traffic_volume_unit] while (pkt.time - @current_time) >= @options[:traffic_volume_unit]
    key = ( @syn_count[pkt.ethernet_headers[0].dst_mac + pkt.ethernet_headers[0].src_mac] >= @syn_ack_count[pkt.ethernet_headers[0].dst_mac + pkt.ethernet_headers[0].src_mac] ) ? pkt.ip_src : pkt.ip_dst
    if (!@options[:sampling_ratio] or (Digest::MD5.hexdigest( key.to_s ).to_i(16) % (2 ** 32)).to_f / (2 ** 32).to_f < @options[:sampling_ratio])
      @sessions[key] ||= TrafficVolume.new()
      @sessions[key].receive key, pkt
    end
    ret
  end

  # Close all traffic volume insntances forcefully, and return formattted informaion of closed.
  # @return [Array]  Return a list of formatted information of traffic volume insntances.
  # @note  This method shold only be used at the end of the whole process to squeeze out remaining data.
  def force_close_all()
    ret = @sessions.to_a.map{|session| format_traffic_volume_info( session[0], session[1] )}
    @sessions.clear
    ret
  end

  private

  def format_traffic_volume_info( key, session )
    {'volume' => [
      [
      @current_time.iso8601(6),
      (@current_time + @options[:traffic_volume_unit]).iso8601(6),
      @current_time.to_f.to_s,
      (@current_time + @options[:traffic_volume_unit]).to_f.to_s,
      session.ip_ver,
      @options[:plain_text] ? key.to_s : Digest::MD5.hexdigest(key.to_s + @options[:hash_salt]),
      key.mask(@options[:subnet_prefix_length][session.ip_ver]).to_s + '/' + @options[:subnet_prefix_length][session.ip_ver].to_s,
      session.size[:UPLOAD],
      session.size[:DOWNLOAD],
      session.n_packets[:UPLOAD],
      session.n_packets[:DOWNLOAD]
      ]
      ]
    }
  end

end
