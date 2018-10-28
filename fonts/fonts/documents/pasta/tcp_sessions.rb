#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require_relative 'http_parser.rb'

require 'pcap'
require 'ipaddr'
require 'digest/md5'
require 'time'


# TCP session determined by four tuple (source/destination ip addresss/port number).
# The class supports a simplified TCP state diagram and HTTP 1.1 protocol (HTTP parser library is required).
class TCPSession

  # Construct a new instance.
  # @param [Hash] options  Options to construct a new insntance.
  # @option options [Integer] :tcp_timeout                A threshold for tcp timeout.
  # @option options [Integer] :half_close_timeout         A threshold for tcp timeout in half close state.
  # @option options [Array]   :http_ports                 An array consists of port numbers to be treated as HTTP sessions.
  # @option options [Array]   :ssl_ports                  An array consists of port numbers to be treated as SSL sessions.
  # @option options [Array]   :outputs                    Output debug information if "debug" is included.
  # @option options [Integer] :missing_threshold          A threshold for detection of missing packets.
  # @option options [Integer] :on_the_fly_threshold       A threshold for number of stored HTTP/TCP/IP packets until parsed.
  # @option options [String]  :hash_salt                  A hash salt for hashing private information.
  # @option options [Hash]    :subnet_prefix_length       Subnet mask lengths of IPv4/IPv6 for "src_ipaddr_subnet_prefix" field.
  # @option options [Boolean] :plain_text                 Set true to keep original private information.
  # @option options [Boolean] :no_corresponding_response  Set true to output http requests even if they lack corresponding http responses.
  # @option options [Boolean] :parse_html                 Set true to analyze http body using hpricot library.
  def initialize( options )
    @@options = options
    @@http_parser_for_padding = HTTPParser.new( @@options[:plain_text], @@options[:hash_salt] )
    @http_parser = nil
    @mac = {}
    @tcp_state   = :LISTEN
    @close_type  = ''
    @first_packet            = nil
    @last_packet             = nil
    @packets                 = {:REQUEST => [], :RESPONSE => []}
    @seq_history             = {:REQUEST => {}, :RESPONSE => {}}
    @ack_time_history        = {:REQUEST => [], :RESPONSE => []}
    @disordered_packets      = {:REQUEST => [], :RESPONSE => []}
    @processed_packets_size  = {:REQUEST => 0, :RESPONSE => 0}
    @duplicated_packets_size = {:REQUEST => 0, :RESPONSE => 0}
    @unexpected_packets_size = {:REQUEST => 0, :RESPONSE => 0}
    @processed_n_packets     = {:REQUEST => 0, :RESPONSE => 0}
    @duplicated_n_packets    = {:REQUEST => 0, :RESPONSE => 0}
    @unexpected_n_packets    = {:REQUEST => 0, :RESPONSE => 0}
    @last_seq                = {:REQUEST => nil, :RESPONSE => nil}
    @fingerprint             = {:REQUEST => {}, :RESPONSE => {}}
    @client_rtt              = nil
    @server_rtt              = nil
  end

  # Maximum value of TCP sequence number
  TCP_SEQ_MAX = 2 ** 32

  # Compare two integers in a ring buffer for tcp sequence numbers.
  # @param [Integer] a  A first sequence number.
  # @param [Integer] b  A second sequence number.
  # @return [Boolean]  Return true when a >= b in a ring buffer.
  def self.tcp_seq_ge?( a, b ) ( ( a - b     ) % TCP_SEQ_MAX < TCP_SEQ_MAX / 2 ) end

  # Compare two integers in a ring buffer for tcp sequence numbers.
  # @param [Integer] a  A first sequence number.
  # @param [Integer] b  A second sequence number.
  # @return [Boolean]  Return true when a > b in a ring buffer.
  def self.tcp_seq_gt?( a, b ) ( ( a - b - 1 ) % TCP_SEQ_MAX < TCP_SEQ_MAX / 2 ) end

  # Calculate number modulo maximum tcp sequence number.
  # @param [Integer] a  A sequence number.
  # @return [Boolean]  Return a number modulo maximum tcp sequence number.
  def self.tcp_seq_mod( a ) ( a % TCP_SEQ_MAX ) end

  # Receive a new packet, and get HTTP/TCP session informaion when the packet closes the session.
  # @param [IPPacket] pkt                An IP packet object.
  # @return [Array]  If the incoming packet closes any existing session, return a list of formatted HTTP/TCP session information. Otherwise, return nil.
  def receive( pkt )
    rr = ( (!@first_packet or @first_packet.ip_src_i == pkt.ip_src_i) ? :REQUEST : :RESPONSE )
    case @tcp_state
    when :LISTEN
      @last_packet = pkt
      if pkt.tcp_syn? and !pkt.tcp_ack? and !pkt.tcp_urg? and !pkt.tcp_psh? and !pkt.tcp_rst? and !pkt.tcp_fin? and rr == :REQUEST and !pkt.tcp_data
        @tcp_state = :SYN_RECEIVED
        push :REQUEST, pkt
        if pkt.datalink == 1
          @mac['syn_src_mac'] = pkt.ethernet_headers[0].src_mac
          @mac['syn_dst_mac'] = pkt.ethernet_headers[0].dst_mac
        end
        @fingerprint[:REQUEST] = calc_fingerprint( pkt, :REQUEST )
        @first_packet = pkt
        @http_parser = @@options[:http_ports].include?( pkt.dport ) ? HTTPParser.new( @@options[:plain_text], @@options[:hash_salt], @packets, @ack_time_history ) : nil
      end

    when :SYN_RECEIVED
      @last_packet = pkt
      if pkt.tcp_syn? and !pkt.tcp_ack? and rr == :REQUEST
        push_disordered :REQUEST, pkt
      elsif pkt.tcp_syn? and pkt.tcp_ack? and rr == :RESPONSE
        @tcp_state = :ESTABLISHED
        push :RESPONSE, pkt
        if pkt.datalink == 1
          @mac['syn_ack_src_mac'] = pkt.ethernet_headers[0].src_mac
          @mac['syn_ack_dst_mac'] = pkt.ethernet_headers[0].dst_mac
        end
        @fingerprint[:RESPONSE] = calc_fingerprint( pkt, :RESPONSE )
        @server_rtt = calc_server_rtt unless @server_rtt
      end

    when :ESTABLISHED, :HALF_CLOSED
      @last_packet = pkt
      if pkt.tcp_syn? and !pkt.tcp_ack?
        push_disordered :REQUEST, pkt
      elsif pkt.tcp_syn? and pkt.tcp_ack?
        push_disordered :RESPONSE, pkt
      else
        @ack_time_history[rr] << [pkt.tcp_ack, pkt.time] if pkt.tcp_ack? and (@ack_time_history[rr].empty? or TCPSession.tcp_seq_gt?( pkt.tcp_ack, @ack_time_history[rr].last[0]))

        # ordered packet
        if ( TCPSession.tcp_seq_ge?( @last_seq[rr], pkt.tcp_seq ) ) and ( TCPSession.tcp_seq_ge?( pkt.tcp_seq + pkt.tcp_data_len, @last_seq[rr] ) )
          push rr, pkt
          @client_rtt = calc_client_rtt unless @client_rtt
        # disordered packet
        else
          push_disordered rr, pkt
          @tcp_state = :MISSING if @disordered_packets[rr].size > @@options[:missing_threshold]
        end

        if pkt.tcp_fin? or pkt.tcp_rst?
          case @tcp_state
          when :ESTABLISHED
            @tcp_state = :HALF_CLOSED
            @close_type = (rr == :REQUEST ? 'clt_' : 'srv_') + (pkt.tcp_fin? ? 'fin' : 'rst') + '/'
          when :HALF_CLOSED
            if rr == :REQUEST and (@close_type == 'srv_fin/' or @close_type == 'srv_rst/')
              @tcp_state = :CLOSED
              @close_type.concat 'clt_' + (pkt.tcp_fin? ? 'fin' : 'rst')
            elsif rr == :RESPONSE and (@close_type == 'clt_fin/' or @close_type == 'clt_rst/')
              @tcp_state = :CLOSED
              @close_type.concat 'srv_' + (pkt.tcp_fin? ? 'fin' : 'rst')
            end
          end
        end
      end

    when :MISSING
      @last_packet = pkt
      @unexpected_packets_size[rr] += pkt.tcp_data_len
      @unexpected_n_packets[rr] += 1

      if pkt.tcp_fin? or pkt.tcp_rst?
        @tcp_state = :CLOSED
        @close_type = 'missing'
      end

    when :CLOSED
      push_disordered rr, pkt
    end

    on_the_fly

    return closed? ? format_tcp_http_info : nil
  end

  # If the session is timeouted, close the session and return formatted HTTP/TCP session information.
  # @param [Time]    time               Current time.
  # @return [Array]  If the session is timeouted, return a list of formatted HTTP/TCP session information. otherwise, return nil.
  def alive_check( time )
    if @last_packet and ((time - @last_packet.time > @@options[:tcp_timeout]) or (time - @last_packet.time > @@options[:half_close_timeout] and @tcp_state == :HALF_CLOSED))
      @tcp_state = :CLOSED
      @close_type.concat 'timeout'
      on_the_fly
      return format_tcp_http_info
    else
      return nil
    end
  end

  # Close the session forcefully, and get HTTP/TCP session informaion of closed sessions.
  # @return [Array]  Return a list of formatted HTTP/TCP session information.
  def force_close()
    @tcp_state = :CLOSED
    @close_type.concat 'force'
    on_the_fly
    format_tcp_http_info
  end

  private

  # Format TCP session information
  # @return [Array] Return an array listing TCP session information fields.
  # @note  Return value does not include HTTP session information.
  def format_tcp_info()
    [
    @first_packet.time.iso8601(6),
    @last_packet.time.iso8601(6),
    @first_packet.time.to_f.to_s,
    @last_packet.time.to_f.to_s,
    @mac['syn_src_mac'],
    @mac['syn_dst_mac'],
    @mac['syn_ack_src_mac'],
    @mac['syn_ack_dst_mac'],
    @close_type,
    @first_packet.ip_ver,
    @@options[:plain_text] ? @first_packet.ip_src_s : Digest::MD5.hexdigest( @first_packet.ip_src_s + @@options[:hash_salt] ),
    @first_packet.ip_src.mask(@@options[:subnet_prefix_length][@first_packet.ip_ver]).to_s + '/' + @@options[:subnet_prefix_length][@first_packet.ip_ver].to_s,
    @first_packet.ip_dst_s,
    @first_packet.sport,
    @first_packet.dport,
    @processed_packets_size[:REQUEST],
    @processed_packets_size[:RESPONSE],
    @duplicated_packets_size[:REQUEST],
    @duplicated_packets_size[:RESPONSE],
    @unexpected_packets_size[:REQUEST] + @disordered_packets[:REQUEST].inject(0){|sum, pkt| sum + pkt.tcp_data_len},
    @unexpected_packets_size[:RESPONSE] + @disordered_packets[:RESPONSE].inject(0){|sum, pkt| sum + pkt.tcp_data_len},
    @processed_n_packets[:REQUEST],
    @processed_n_packets[:RESPONSE],
    @duplicated_n_packets[:REQUEST],
    @duplicated_n_packets[:RESPONSE],
    @unexpected_n_packets[:REQUEST] + @disordered_packets[:REQUEST].size,
    @unexpected_n_packets[:RESPONSE] + @disordered_packets[:RESPONSE].size,
    @fingerprint[:REQUEST]['window_size'],
    @fingerprint[:REQUEST]['ttl'],
    @fingerprint[:REQUEST]['fragment'] ? 1 : 0,
    @fingerprint[:REQUEST]['total_length'],
    @fingerprint[:REQUEST]['options'],
    @fingerprint[:REQUEST]['quirks'],
    @fingerprint[:RESPONSE]['window_size'],
    @fingerprint[:RESPONSE]['ttl'],
    @fingerprint[:RESPONSE]['fragment'] ? 1 : 0,
    @fingerprint[:RESPONSE]['total_length'],
    @fingerprint[:RESPONSE]['options'],
    @fingerprint[:RESPONSE]['quirks'],
    @client_rtt,
    @server_rtt,
    Digest::MD5.hexdigest(Marshal.dump(@first_packet))
    ]
  end

  # Format HTTP/TCP session information
  # @return [Array] Return an array listing HTTP/TCP session information fields.
  # @note  Return value include not only HTTP session information but also TCP session information.
  def format_tcp_http_info()
    return [] unless @client_rtt
    tcp_info = format_tcp_info()
    ret = {}
    ret['debug'] = ["######## #{tcp_info.join(", ")} ########\r\n"] if @@options[:outputs].include?('debug')
    if @http_parser
      ret['tcp'] = []
      @http_parser.format_http_info( @@options[:outputs].include?('debug'), @@options[:no_corresponding_response], @@options[:parse_html] ).each do |http|
        ret['tcp'] << tcp_info + http['tcp']
        ret['debug'].first << http['debug'] if @@options[:outputs].include?('debug')
      end
    else
      ret['tcp'] = [tcp_info.concat( @@http_parser_for_padding.padding )]
    end
    [ret]
  end

  def clean_up_duplicated_packets( rr )
    # discard packets having the same sequence number with the pushed packet 
    # and unexpected packets from disordered packet buffer
    @disordered_packets[rr].delete_if do |pkt|
      if @seq_history[rr][pkt.tcp_seq]
        @duplicated_packets_size[rr] += pkt.tcp_data_len
        @duplicated_n_packets[rr] += 1
        true
      elsif TCPSession.tcp_seq_ge?( @last_seq[rr], pkt.tcp_seq + pkt.tcp_data_len )
        @unexpected_packets_size[rr] += pkt.tcp_data_len
        @unexpected_n_packets[rr] += 1
        true
      else
        false
      end
    end
  end

  def push_disordered( rr, pkt )
    if @seq_history[rr][pkt.tcp_seq]
      @duplicated_packets_size[rr] += pkt.tcp_data_len
      @duplicated_n_packets[rr] += 1
    elsif TCPSession.tcp_seq_ge?( @last_seq[rr], pkt.tcp_seq + pkt.tcp_data_len )
      @unexpected_packets_size[rr] += pkt.tcp_data_len
      @unexpected_n_packets[rr] += 1
    else
      @disordered_packets[rr] << pkt
    end
  end

  def push( rr, pkt, cleanup = true )
    @packets[rr] << pkt
    @seq_history[rr][pkt.tcp_seq] = true
    @last_seq[rr] = TCPSession.tcp_seq_mod( pkt.tcp_seq + pkt.tcp_data_len + (pkt.tcp_syn? ? 1 : 0) )
    # search for a reasonable packet to be pushed into packet buffer from disordered packet buffer
    if to_be_pushed_index = @disordered_packets[rr].index{|dp| TCPSession.tcp_seq_ge?( @last_seq[rr], dp.tcp_seq ) and TCPSession.tcp_seq_ge?( dp.tcp_seq + dp.tcp_data_len, @last_seq[rr] )}
      to_be_pushed = @disordered_packets[rr][to_be_pushed_index]
      @disordered_packets[rr].delete_at to_be_pushed_index
      push rr, to_be_pushed, false
      clean_up_duplicated_packets( rr ) if cleanup
    end
  end

  def on_the_fly
    if closed? or (@packets[:REQUEST].size + @packets[:RESPONSE].size >= @@options[:on_the_fly_threshold] and @client_rtt and @server_rtt)
      @http_parser.on_the_fly closed? if @http_parser
      [:REQUEST, :RESPONSE].each do |rr|
        @processed_packets_size[rr] += @packets[rr].inject(0){|sum, pkt| sum + pkt.tcp_data_len}
        @processed_n_packets[rr] += @packets[rr].size
        @packets[rr].clear
      end
    end
  end

  def calc_client_rtt
    return nil if !@packets[:RESPONSE].first or !@packets[:REQUEST][1]
    syn_ack_time = @packets[:RESPONSE].first.time
    ack_time     = @packets[:REQUEST][1].time
    ((ack_time - syn_ack_time) * 1_000_000).to_i
  end

  def calc_server_rtt
    return nil if !@packets[:REQUEST].first or !@packets[:RESPONSE].first
    syn_time     = @packets[:REQUEST].first.time
    syn_ack_time = @packets[:RESPONSE].first.time
    ((syn_ack_time - syn_time) * 1_000_000).to_i
  end

  def calc_fingerprint( pkt, rr )
    options = []
    quirks = {}
    return {} if pkt == nil
    begin
      ret = {
        'window_size'  => pkt.tcp_win,
        'ttl'          => pkt.ip_ttl,
        'fragment'     => pkt.ip_df?,
        'total_length' => pkt.ip_total_length,
      }

      eol = false
      quirks['Z'] = true if pkt.ip_ver == 4 and pkt.ip_id == 0
      quirks['I'] = true if (pkt.ip_ver == 4 and pkt.ip_header_length != 20) or (pkt.ip_ver == 6 and pkt.ip_header_length != 40)
      quirks['U'] = true if pkt.tcp_urp != 0
      quirks['X'] = true if pkt.ip_data[12, 1].unpack('C')[0] & 0b00001111 != 0 or pkt.ip_data[13, 1].unpack('C')[0] & 0b11000000 != 0
      quirks['A'] = true if (rr == :REQUEST and pkt.tcp_ack != 0) or (rr == :RESPONSE and pkt.tcp_ack == 0)
      quirks['F'] = true if pkt.tcp_fin? or pkt.tcp_rst? or pkt.tcp_psh? or pkt.tcp_urg?
      quirks['D'] = true if pkt.tcp_data_len != 0

      buf = pkt.ip_data[20...(pkt.tcp_hlen * 4)].unpack('C' * (pkt.tcp_hlen * 4 - 20))
      until buf.empty?
        case type = buf.shift
        when 0  # End of Option List
          options << 'E'
          eol = true
        when 1  # No-Operation
          options << 'N'
        when 2  # Maximum Segment Size
          quirks['E'] = true if eol
          sum = 0; (buf.shift - 2).times{|i| sum = sum * 256 + buf.shift}
          options << 'M' + sum.to_s
        when 3  # TCP Window Scale Option
          quirks['E'] = true if eol
          sum = 0; (buf.shift - 2).times{|i| sum = sum * 256 + buf.shift}
          options << 'W' + sum.to_s
        when 4  # SACK Permitted
          quirks['E'] = true if eol
          buf.shift
          options << 'S'
        when 8  # Time Stamp Option
          quirks['E'] = true if eol
          buf.shift
          tsval = 0; 4.times{|i| tsval = tsval * 256 + buf.shift}
          tsecr = 0; 4.times{|i| tsecr = tsecr * 256 + buf.shift}
          quirks['T'] = true if rr == :REQUEST and tsecr != 0
          options << 'T' + (tsval == 0 ? '0' : '')
        else
          quirks['E'] = true if eol
          (buf.shift - 2).times{|i| buf.shift}
          options << '?' + type.to_s
        end
      end
    rescue
      quirks['!'] = true
    end

    ret['options'] = options.join(',')
    ret['quirks'] = quirks.to_a.map{|x| x[0]}.join('')
    ret
  end

  def closed?
    @tcp_state == :CLOSED
  end

end


# An container of TCP sessions.
# The class provides a function to sort incoming IP packets into appropriate TCP session insntance automatically.
class TCPSessions

  # Construct a new instance.
  # @param [Hash] options  Options to construct a new insntance.
  # @option options [Integer] :tcp_timeout                A threshold for tcp timeout.
  # @option options [Integer] :half_close_timeout         A threshold for tcp timeout in half close state.
  # @option options [Float]   :sampling_ratio             A sampling ratio, which must be between 0.0 and 1.0. nil makes total inspection.
  # @option options [Array]   :http_ports                 An array consists of port numbers to be treated as HTTP sessions.
  # @option options [Array]   :ssl_ports                  An array consists of port numbers to be treated as SSL sessions.
  # @option options [Array]   :outputs                    Output debug information if "debug" is included.
  # @option options [Integer] :on_the_fly_threshold       A threshold for number of stored HTTP/TCP/IP packets until parsed.
  # @option options [Integer] :missing_threshold          A threshold for detection of missing packets.
  # @option options [String]  :hash_salt                  A hash salt for hashing private information.
  # @option options [Hash]    :subnet_prefix_length       Subnet mask lengths of IPv4/IPv6 for "src_ipaddr_subnet_prefix" field
  # @option options [Boolean] :plain_text                 Set true to keep original private information.
  # @option options [Boolean] :no_corresponding_response  Set true to output http requests even if they lack corresponding http responses.
  # @option options [Boolean] :parse_html                 Set true to analyze http body using hpricot library.
  def initialize( options )
    @sessions = Hash.new
    @options = options
  end

  # Receive a new packet, and get HTTP/TCP session informaion when the packet closes the session.
  # @param [IPPacket] pkt                An IP packet object.
  # @param [Boolean]  leading            Leading mode or not.
  # @return [Array]  Return a list of formatted HTTP/TCP session information if the incoming packet closes any existing session.
  # @raise [RuntimeError]  Raise a RuntimeError if a non-TCP packet is given
  def receive( pkt, leading )
    raise 'non-TCP packet' unless pkt.tcp?
    if @sessions[ reverse_key = pkt.ip_dst_s + ',' + pkt.ip_src_s + ',' + pkt.dport.to_s + ',' + pkt.sport.to_s ]
      key = reverse_key
    elsif @sessions[ forward_key = pkt.ip_src_s + ',' + pkt.ip_dst_s + ',' + pkt.sport.to_s + ',' + pkt.dport.to_s ]
      key = forward_key
    elsif leading and pkt.tcp_syn? and !pkt.tcp_ack? and
      (!@options[:sampling_ratio] or (Digest::MD5.hexdigest( pkt.ip_src_s ).to_i(16) % (2 ** 32)).to_f / (2 ** 32).to_f < @options[:sampling_ratio])
      key = forward_key
      @sessions[key] = TCPSession.new( @options )
    else
      return []
    end

    if ret = @sessions[key].receive( pkt )
      @sessions.delete key
      return ret
    else
      return []
    end
  end

  # Close timeouted sessions and return formatted HTTP/TCP session information.
  # @param [Time]    time               Current time.
  # @return [Array]  Return a list of formatted HTTP/TCP session information, they are closed by timeout.
  def timeout_check( time )
    ret = []
    @sessions.each do |k, v|
      if r = v.alive_check( time )
        ret.concat r
        @sessions.delete k
      end
    end
    return ret
  end

  # Close all sessions forcefully, and get HTTP/TCP session informaion of closed sessions.
  # @return [Array]  Return a list of formatted HTTP/TCP session information, they are closed forcefully.
  # @note  This method shold only be used at the end of the whole process to squeeze out remaining sessions.
  def force_close_all()
    ret = []
    @sessions.each_value do |v|
      ret.concat v.force_close
    end
    @sessions.clear
    return ret
  end

  # Check if the instance holds any session.
  # @return [Boolean]  Return true when no TCP sessions are remaining.
  def empty?
    @sessions.empty?
  end
end
