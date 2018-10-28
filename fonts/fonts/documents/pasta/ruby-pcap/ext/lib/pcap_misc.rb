
module Pcap
  class Packet
    def to_s
      'Some packet'
    end

    def inspect
      "#<#{self.class}: #{self}>"
    end
  end

  class IPPacket
    def to_s
      "#{src_s} > #{dst_s}"
    end
  end

  class TCPPacket
    def tcp_flags_s
      return \
        (tcp_urg? ? 'U' : '.') +
        (tcp_ack? ? 'A' : '.') +
        (tcp_psh? ? 'P' : '.') +
        (tcp_rst? ? 'R' : '.') +
        (tcp_syn? ? 'S' : '.') +
        (tcp_fin? ? 'F' : '.')
    end

    def to_s
      "#{src_s}:#{sport} > #{dst_s}:#{dport} #{tcp_flags_s}"
    end
  end

  class UDPPacket
    def to_s
      "#{src_s}:#{sport} > #{dst_s}:#{dport} len #{udp_len} sum #{udp_sum}"
    end
  end

  class ICMPPacket
    def to_s
      "#{src_s} > #{dst_s}: icmp: #{icmp_typestr}"
    end
  end

  #
  # Backword compatibility
  #
  IpPacket = IPPacket
  TcpPacket = TCPPacket
  UdpPacket = UDPPacket

end

class Time
  # tcpdump style format
  def tcpdump
    sprintf "%0.2d:%0.2d:%0.2d.%0.6d", hour, min, sec, tv_usec
  end
end

class IPAddr
  def marshal_dump
  end
  def marshal_load
  end
end

autoload :Pcaplet, 'pcaplet'
