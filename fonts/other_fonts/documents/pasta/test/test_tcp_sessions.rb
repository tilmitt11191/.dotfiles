require 'test/unit'
require 'pcap'
require 'csv'
require_relative '../tcp_sessions.rb'

CAPTURE_DIR = "capture_file/"
TEST_PACKET = CAPTURE_DIR + "select_cap.pcap"
NORMAL_OPE = CAPTURE_DIR + "normal_ope.pcap"
SEQ_ACK = CAPTURE_DIR + "seq_ack_edit.pcap"
REORDERING_CONNECT = CAPTURE_DIR + "reordering_edit_connect.pcap"
REORDERING_TRANSFER = CAPTURE_DIR + "reordering_edit_transfer.pcap"
REORDERING_CLOSE = CAPTURE_DIR + "reordering_edit_close.pcap"
URG_FLG = CAPTURE_DIR + "urg_flg.pcap"
RST_FLG = CAPTURE_DIR + "rst_flg.pcap"
STRADDLE_DATE = CAPTURE_DIR + "straddle_date.pcap"

SALT_CHAR = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$&"

IP_VER = 9

class TCPSession
  public :format_tcp_info
  public :format_tcp_http_info
  public :clean_up_duplicated_packets
  public :push_disordered
  public :push
  public :on_the_fly
  public :calc_client_rtt
  public :calc_server_rtt
  public :calc_fingerprint
  public :closed?

  attr_accessor :tcp_state, :client_rtt, :packets, :last_seq, :last_packet, 
    :first_packet, :packets, :close_type, :last_packet, :duplicated_packets_size,
    :duplicated_n_packets, :unexpected_packets_size, :unexpected_n_packets,
    :disordered_packets, :server_rtt, :processed_packets_size, :processed_n_packets,
    :mac, :fingerprint, :http_parser

end

# make Hash class behave pseudo Packet class
class Hash
  def method_missing(name)
    return self[name] if key? name
    self.each{|k,v| return v if k.to_s.to_sym == name}
    super.method_missing name
  end
end

def create_first_packet(session, ip_dst, ip_src)
  session.first_packet = {
    :ip_dst_i => ip_dst,
    :ip_src_i => ip_src,
    :time => Time.new,
    :ip_ver => 4,
    :ip_dst_s => "192.168.0.1",
    :ip_dst => IPAddr.new("192.168.0.1"),
    :ip_src_s => "192.168.100.254",
    :ip_src => IPAddr.new("192.168.100.254"),
    :sport => 50976,
    :dport => 80,
  }
end

def create_instance_packets(session)
  hash_data = {:time => Time.new(2014, 1, 1, 0, 0, 0, "+09:00"), :tcp_data_len => 100}
  session.packets = {
    :RESPONSE => [
      {:time => Time.new(2014, 1, 1, 0, 1, 0, "+09:00"), :tcp_data_len => 300},
      {:time => Time.new(2014, 1, 1, 0, 1, 10, "+09:00"), :tcp_data_len => 400}],
    :REQUEST => [
      {:time => Time.new(2013, 12, 31, 23, 59, 30, "+09:00"), :tcp_data_len => 100},
      {:time => Time.new(2014, 1, 1, 0, 1, 50, "+09:00"), :tcp_data_len => 200}]
    }
end

def create_last_packet(session, test_time)
  session.last_packet = {
    :time => test_time,
  }
end
  
def create_last_seq(session)
  session.last_seq = {
    :REQUEST => 1987214423,
    :RESPONSE => 1987214423
  }
end

def create_options
  options = Hash.new
  options[:begin_time]                     = Time.now
  options[:outfile_prefix]                 = ''
  options[:field_names]                    = true
  options[:tcp_timeout]                    = 16
  options[:udp_timeout]                    = 16
  options[:traffic_volume_unit]            = nil
  options[:half_close_timeout]             = 4
  options[:http_ports]                     = [80, 8080]
  options[:ssl_ports]                      = [443, 8443]
  options[:cancel_remaining_sessions]      = false
  options[:sampling_ratio]                 = nil
  options[:timeout_check_interval]         = 4
  options[:plain_text]                     = false
  options[:on_the_fly_threshold]           = 1
  options[:missing_threshold]              = 64
  options[:subnet_prefix_length]           = {4 => 19, 6 => 64}
  options[:outputs]                        = ['tcp', 'udp', 'gtp']
  options[:csv]                            = CSV
  options[:version]                        = ' (HEAD, master) 2015-02-25 14:21:03 +0900 912a25c115fa72646c2450b13daf12e9205986d5'
  options[:gtp_all]                        = false
  options[:hash_salt] = Array.new(16).map{|m| SALT_CHAR[rand(SALT_CHAR.size)]}.join('')

  return options
end
  
def create_test_packet
  pkt = Hash.new
  pkt = {
    :ip_dst_s => "192.168.0.1",
    :ip_src_s => "192.168.100.254",
    :ip_dst_i => "0xc0a80001".to_i(16),
    :ip_src_i => "0xc0a864fe".to_i(16),
    :sport => 50976,
    :dport => 80,
    :tcp_win => 8192,
    :ip_ver => 4,
    :ip_ttl => 120,
    :ip_df? => true,
    :ip_total_length => 52,
    :ip_header_length => 20,
    :ip_id => 24931,
    :tcp_hlen => 8,
    :tcp_urp => 0,
    :ip_data => ["ecab005004e76d9e0000000080022000f7210000020405b40103030801010402"].pack('H*'),
    :tcp_ack => 1987214424,
    :tcp_urg? => false,
    :tcp_ack? => false,
    :tcp_psh? => false,
    :tcp_rst? => false,
    :tcp_syn? => false,
    :tcp_fin? => false,
    :tcp_data => nil,
    :tcp_data_len => 0,
    :datalink => 0,
    :tcp_seq => 1987214424,
    :ethernet_headers => [{:src_mac => "12:34:56:78:90:ab", :dst_mac => "ab:cd:ef:01:23:45"}],
    :time => Time.new,
  }
  return pkt
end

def set_ip_direction_to_response(pkt)
  pkt[:ip_dst_i] = "0xc0a864fe".to_i(16)
  pkt[:ip_src_i] = "0xc0a80001".to_i(16)
end

# TCPSession Class Code coverrage
class TCPSessionTest < Test::Unit::TestCase

  def setup
  end

  ## recieve()
  def test_tcp_session_receive
    pkt = create_test_packet
    tcp_session = TCPSession.new(create_options)

    #:LISTEN
    assert_nil(tcp_session.receive(pkt))
    assert_nil(tcp_session.mac['syn_src_mac'])
    assert_nil(tcp_session.mac['syn_dst_mac'])
    assert_equal(tcp_session.fingerprint[:REQUEST], {})
    assert_nil(tcp_session.first_packet)
    assert_nil(tcp_session.http_parser)

    pkt = create_test_packet
    pkt[:tcp_syn?] = true
    assert_nil(tcp_session.receive(pkt))
    assert_nil(tcp_session.mac['syn_src_mac'])
    assert_nil(tcp_session.mac['syn_dst_mac'])
    assert_equal(tcp_session.fingerprint[:REQUEST]["window_size"], 8192)
    assert_equal(tcp_session.first_packet[:ip_ver], 4)
    assert_equal(tcp_session.http_parser.class, HTTPParser)

    pkt = create_test_packet
    tcp_session.tcp_state = :LISTEN
    pkt[:tcp_syn?] = true
    pkt[:datalink] = 1
    assert_nil(tcp_session.receive(pkt))
    assert_equal(tcp_session.tcp_state, :SYN_RECEIVED)
    assert_equal(tcp_session.closed?, false)
    assert_equal(tcp_session.mac['syn_src_mac'], "12:34:56:78:90:ab")
    assert_equal(tcp_session.mac['syn_dst_mac'], "ab:cd:ef:01:23:45")
    assert_equal(tcp_session.fingerprint[:REQUEST]["window_size"], 8192)
    assert_equal(tcp_session.first_packet[:ip_ver], 4)
    assert_equal(tcp_session.http_parser.class, HTTPParser)

    #:SYN_RECEIVED
    create_first_packet(tcp_session, "0xc0a80001".to_i(16) , "0xc0a864fe".to_i(16))
    create_instance_packets(tcp_session)

    pkt = create_test_packet
    assert_nil(tcp_session.receive(pkt))
    assert_equal(tcp_session.tcp_state, :SYN_RECEIVED)

    pkt = create_test_packet
    pkt[:tcp_syn?] = true
    pkt[:tcp_ack?] = true
    assert_nil(tcp_session.receive(pkt))
    assert_equal(tcp_session.tcp_state, :SYN_RECEIVED)

    pkt = create_test_packet
    pkt[:tcp_syn?] = true
    pkt[:tcp_ack?] = true
    pkt[:ip_dst_i] = "0xc0a864fe".to_i(16)
    pkt[:ip_src_i] = "0xc0a80001".to_i(16) #RESPONSE
    assert_nil(tcp_session.receive(pkt))
    assert_equal(tcp_session.tcp_state, :ESTABLISHED)

    tcp_session.tcp_state = :SYN_RECEIVED
    pkt = create_test_packet
    pkt[:tcp_syn?] = true
    pkt[:tcp_ack?] = true
    pkt[:ip_dst_i] = "0xc0a864fe".to_i(16)
    pkt[:ip_src_i] = "0xc0a80001".to_i(16) #RESPONSE
    pkt[:datalink] = 1
    assert_nil(tcp_session.receive(pkt))
    assert_equal(tcp_session.tcp_state, :ESTABLISHED)
    assert_equal(tcp_session.mac['syn_ack_src_mac'], "12:34:56:78:90:ab")
    assert_equal(tcp_session.mac['syn_ack_dst_mac'], "ab:cd:ef:01:23:45")

    #:ESTABLISHED
    pkt = create_test_packet
    pkt[:tcp_syn?] = true
    set_ip_direction_to_response(pkt)
    assert_nil(tcp_session.receive(pkt))
    assert_equal(tcp_session.tcp_state, :ESTABLISHED)

    pkt = create_test_packet
    pkt[:tcp_syn?] = true
    pkt[:tcp_ack?] = true
    set_ip_direction_to_response(pkt)
    assert_nil(tcp_session.receive(pkt))
    assert_equal(tcp_session.tcp_state, :ESTABLISHED)

    pkt = create_test_packet
    pkt[:tcp_ack?] = true
    set_ip_direction_to_response(pkt)
    assert_nil(tcp_session.receive(pkt))
    create_last_seq(tcp_session)
    pkt[:tcp_data_len] = 100
    pkt[:tcp_seq] = 1987214423
    assert_nil(tcp_session.receive(pkt))
    assert_equal(tcp_session.tcp_state, :ESTABLISHED)

    pkt = create_test_packet
    pkt[:tcp_ack?] = true
    pkt[:tcp_fin?] = true
    set_ip_direction_to_response(pkt)
    assert_nil(tcp_session.receive(pkt))
    assert_equal(tcp_session.tcp_state, :HALF_CLOSED)

    pkt = create_test_packet
    tcp_session.tcp_state = :ESTABLISHED
    pkt[:tcp_ack?] = true
    pkt[:tcp_rst?] = true
    set_ip_direction_to_response(pkt)
    assert_nil(tcp_session.receive(pkt))
    assert_equal(tcp_session.tcp_state, :HALF_CLOSED)

    #:HALF_CLOSED
    pkt = create_test_packet
    pkt[:tcp_rst?] = true
    assert_equal(tcp_session.receive(pkt)[0]['tcp'], [])
    assert_equal(tcp_session.tcp_state, :CLOSED)
    assert_equal(tcp_session.close_type, 'srv_rst/clt_rst')

    pkt = create_test_packet
    tcp_session.tcp_state = :HALF_CLOSED
    pkt[:tcp_rst?] = true
    tcp_session.close_type = 'clt_rst/'
    assert_nil(tcp_session.receive(pkt))
    assert_equal(tcp_session.tcp_state, :HALF_CLOSED)
    assert_equal(tcp_session.close_type, 'clt_rst/')

    pkt = create_test_packet
    pkt[:tcp_rst?] = true
    set_ip_direction_to_response(pkt)
    tcp_session.close_type = 'clt_rst/'
    assert_equal(tcp_session.receive(pkt)[0]['tcp'], [])
    assert_equal(tcp_session.tcp_state, :CLOSED)
    assert_equal(tcp_session.close_type, 'clt_rst/srv_rst')

    pkt = create_test_packet
    pkt[:tcp_rst?] = true
    set_ip_direction_to_response(pkt)
    tcp_session.tcp_state = :HALF_CLOSED
    tcp_session.close_type = 'srv_rst/'
    assert_nil(tcp_session.receive(pkt))
    assert_equal(tcp_session.tcp_state, :HALF_CLOSED)
    assert_equal(tcp_session.close_type, 'srv_rst/')

    pkt = create_test_packet
    pkt[:tcp_rst?] = true
    tcp_session.close_type = 'srv_fin/'
    assert_equal(tcp_session.receive(pkt)[0]['tcp'], [])
    assert_equal(tcp_session.tcp_state, :CLOSED)
    assert_equal(tcp_session.close_type, 'srv_fin/clt_rst')

    pkt = create_test_packet
    pkt[:tcp_fin?] = true
    assert_equal(tcp_session.receive(pkt)[0]['tcp'], [])
    assert_equal(tcp_session.tcp_state, :CLOSED)
    assert_equal(tcp_session.close_type, 'srv_fin/clt_rst')

    pkt = create_test_packet
    tcp_session.tcp_state = :HALF_CLOSED
    pkt[:tcp_fin?] = true
    tcp_session.close_type = 'clt_fin/'
    assert_nil(tcp_session.receive(pkt))
    assert_equal(tcp_session.tcp_state, :HALF_CLOSED)
    assert_equal(tcp_session.close_type, 'clt_fin/')

    pkt = create_test_packet
    pkt[:tcp_fin?] = true
    set_ip_direction_to_response(pkt)
    tcp_session.close_type = 'clt_fin/'
    assert_not_nil(tcp_session.receive(pkt))
    assert_equal(tcp_session.tcp_state, :CLOSED)
    assert_equal(tcp_session.close_type, 'clt_fin/srv_fin')

    pkt = create_test_packet
    pkt[:tcp_fin?] = true
    set_ip_direction_to_response(pkt)
    tcp_session.tcp_state = :HALF_CLOSED
    tcp_session.close_type = 'srv_fin/'
    assert_nil(tcp_session.receive(pkt))
    assert_equal(tcp_session.tcp_state, :HALF_CLOSED)
    assert_equal(tcp_session.close_type, 'srv_fin/')

    pkt = create_test_packet
    pkt[:tcp_fin?] = true
    tcp_session.close_type = 'srv_fin/'
    assert_not_nil(tcp_session.receive(pkt))
    assert_equal(tcp_session.tcp_state, :CLOSED)
    assert_equal(tcp_session.close_type, 'srv_fin/clt_fin')

    #:CLOSED
    assert_equal(tcp_session.closed?, true)
  end

  ## alive_check()
  def test_tcp_session_alive_check
    pkt = create_test_packet
    tcp_session = TCPSession.new(create_options)
    before_time = Time.new(2014, 1, 1, 0, 0, 0, "+09:00")
    after_time = Time.new(2014, 1, 1, 0, 0, 17, "+09:00")

    assert_nil(tcp_session.alive_check(before_time))
    create_last_packet(tcp_session, before_time)
    assert_equal(tcp_session.alive_check(after_time), [])
  end

  ## force_close()
  def test_tcp_session_force_close
    pkt = create_test_packet
    tcp_session = TCPSession.new(create_options)
    assert_equal(tcp_session.force_close(), [])
  end

  ## format_tcp_http_info()
  def test_tcp_session_format_tcp_http_info
    pkt = create_test_packet
    tcp_session = TCPSession.new(create_options)

    assert_equal(tcp_session.format_tcp_http_info, [])
    tcp_session.client_rtt = 243058
    create_first_packet(tcp_session, "0xc0a80001".to_i(16) , "0xc0a864fe".to_i(16))
    create_last_packet(tcp_session, Time.new)
    assert_equal(tcp_session.format_tcp_http_info[0]['tcp'][0][IP_VER], 4)

    pkt = create_test_packet
    pkt[:tcp_syn?] = true
    assert_equal(tcp_session.format_tcp_info[IP_VER], 4)
    assert_equal(tcp_session.format_tcp_http_info[0]['tcp'][0][IP_VER], 4)
  end

  ## clean_up_duplicated_packets()
  ## push_disordered()
  ## push()
  def test_tcp_session_push
    pkt = create_test_packet
    tcp_session = TCPSession.new(create_options)
    create_last_seq(tcp_session)

    tcp_session.push_disordered(:REQUEST, pkt)
    tcp_session.push(:REQUEST, pkt, false)
    assert_equal(tcp_session.duplicated_n_packets[:REQUEST], 0)
    assert_equal(tcp_session.duplicated_n_packets[:RESPONSE], 0)
    assert_equal(tcp_session.unexpected_n_packets[:REQUEST], 0)
    assert_equal(tcp_session.unexpected_n_packets[:RESPONSE], 0)
    p tcp_session.disordered_packets[:REQUEST]
    assert_not_nil(tcp_session.disordered_packets[:REQUEST])
    assert_not_nil(tcp_session.disordered_packets[:RESPONSE])

    #cleanup
    tcp_session = TCPSession.new(create_options)
    create_last_seq(tcp_session)
    tcp_session.push_disordered(:REQUEST, pkt)
    tcp_session.push(:REQUEST, pkt, true)
    tcp_session.push_disordered(:REQUEST, pkt)
    assert_equal(tcp_session.duplicated_n_packets[:REQUEST], 1)
    assert_equal(tcp_session.duplicated_n_packets[:RESPONSE], 0)
    assert_equal(tcp_session.unexpected_n_packets[:REQUEST], 0)
    assert_equal(tcp_session.unexpected_n_packets[:RESPONSE], 0)

    tcp_session = TCPSession.new(create_options)
    create_last_seq(tcp_session)
    pkt[:tcp_seq] = 1000
    tcp_session.push_disordered(:RESPONSE, pkt)
    assert_equal(tcp_session.duplicated_n_packets[:REQUEST], 0)
    assert_equal(tcp_session.duplicated_n_packets[:RESPONSE], 0)
    assert_equal(tcp_session.unexpected_n_packets[:REQUEST], 0)
    assert_equal(tcp_session.unexpected_n_packets[:RESPONSE], 1)
    assert_equal(tcp_session.clean_up_duplicated_packets(:REQUEST), [])
  end

  ## on_the_fly()
  def test_tcp_session_on_the_fly
    tcp_session = TCPSession.new(create_options)
    tcp_session.on_the_fly
    assert_equal(tcp_session.processed_n_packets[:REQUEST], 0)
    assert_equal(tcp_session.processed_n_packets[:RESPONSE], 0)

    create_instance_packets(tcp_session)
    tcp_session.client_rtt = 243058
    tcp_session.server_rtt = 243058
    tcp_session.on_the_fly
    assert_equal(tcp_session.processed_n_packets[:REQUEST], 2)
    assert_equal(tcp_session.processed_n_packets[:RESPONSE], 2)

    tcp_session.tcp_state = :CLOSED
    tcp_session.on_the_fly
    assert_equal(tcp_session.processed_n_packets[:REQUEST], 2)
    assert_equal(tcp_session.processed_n_packets[:RESPONSE], 2)
  end

  ## calc_client_rtt()
  def test_tcp_session_calc_client_rtt
    pkt = create_test_packet
    tcp_session = TCPSession.new(create_options)

    assert_nil(tcp_session.calc_client_rtt)

    create_instance_packets(tcp_session)
    assert_equal(tcp_session.calc_client_rtt, 50000000)
  end

  ## calc_server_rtt()
  def test_tcp_session_calc_server_rtt
    pkt = create_test_packet
    tcp_session = TCPSession.new(create_options)

    assert_nil(tcp_session.calc_server_rtt)

    create_instance_packets(tcp_session)
    assert_equal(tcp_session.calc_server_rtt, 90000000)
  end

  ## tcp_seq_ge?
  ## tcp_seq_gt?
  ## tcp_seq_mod
  def test_subroutines_for_tcp_seq
    assert_equal( TCPSession.tcp_seq_ge?( 1, 0 ), true )
    assert_equal( TCPSession.tcp_seq_ge?( 0, 1 ), false )
    assert_equal( TCPSession.tcp_seq_ge?( 0, 0 ), true )
    assert_equal( TCPSession.tcp_seq_ge?( 2 ** 32, 0 ), true )
    assert_equal( TCPSession.tcp_seq_ge?( 0, 2 ** 32 ), true )
    assert_equal( TCPSession.tcp_seq_ge?( 2 ** 32 - 1, 0 ), false )
    assert_equal( TCPSession.tcp_seq_ge?( 0, 2 ** 32 - 1 ), true )

    assert_equal( TCPSession.tcp_seq_gt?( 1, 0 ), true )
    assert_equal( TCPSession.tcp_seq_gt?( 0, 1 ), false )
    assert_equal( TCPSession.tcp_seq_gt?( 0, 0 ), false )
    assert_equal( TCPSession.tcp_seq_gt?( 2 ** 32, 0 ), false )
    assert_equal( TCPSession.tcp_seq_gt?( 0, 2 ** 32 ), false )
    assert_equal( TCPSession.tcp_seq_gt?( 2 ** 32 - 1, 0 ), false )
    assert_equal( TCPSession.tcp_seq_gt?( 0, 2 ** 32 - 1 ), true )

    assert_equal( TCPSession.tcp_seq_mod( 0 ), 0 )
    assert_equal( TCPSession.tcp_seq_mod( 1 ), 1 )
    assert_equal( TCPSession.tcp_seq_mod( 2 ** 32 - 1 ), 2 ** 32 - 1 )
    assert_equal( TCPSession.tcp_seq_mod( 2 ** 32 ), 0 )
    assert_equal( TCPSession.tcp_seq_mod( 2 ** 32 + 1 ), 1 )
  end

  ## calc_fingerprint()
  def test_subroutines_for_fingerprint_calculation
    t = TCPSession.new( {} )
    fp = t.calc_fingerprint( nil, :RESPONSE )
    assert_equal( fp, {} )
    pkt = create_test_packet

    pkt[:tcp_ack] = 0
    fp = t.calc_fingerprint( pkt, :REQUEST )
    assert_equal( fp['window_size'], 8192 )
    assert_equal( fp['ttl'], 120 )
    assert_equal( fp['fragment'], true )
    assert_equal( fp['total_length'], 52 )
    assert_equal( fp['options'], 'M1460,N,W8,N,N,S' )
    assert_equal( fp['quirks'], '' )

    pkt[:tcp_win] = 64404
    pkt[:tcp_ack] = 1987214424
    pkt[:ip_data] = ["0050ecaa96825f3f76727c588012fb94f7600000020405640101040201030307"].pack('H*')
    pkt[:ip_ttl] = 54
    pkt[:ip_id] = 0
    fp = t.calc_fingerprint( pkt, :RESPONSE )
    assert_equal( fp['window_size'], 64404 )
    assert_equal( fp['ttl'], 54 )
    assert_equal( fp['fragment'], true )
    assert_equal( fp['total_length'], 52 )
    assert_equal( fp['options'], 'M1380,N,N,S,N,W7' )
    assert_equal( fp['quirks'], 'Z' )

    pkt[:ip_ver] = 4
    pkt[:ip_header_length] = 21
    pkt[:tcp_urp] = 1
    pkt[:tcp_ack] = 0
    pkt[:tcp_fin?] = true
    pkt[:tcp_data_len] = 1
    pkt[:ip_data] = ["0050ecaa96825f3f76727c58fffffb94f7600000020405640100040201030307"].pack('H*')
    fp = t.calc_fingerprint( pkt, :RESPONSE )
    assert_equal( fp['options'], 'M1380,N,E,S,N,W7' )
    assert_equal( fp['quirks'], 'ZIUXAFDE' )

    pkt[:ip_ver] = 6
    pkt[:ip_header_length] = 40
    pkt[:tcp_urp] = 0
    pkt[:tcp_ack] = 1
    pkt[:tcp_data_len] = 0
    pkt[:tcp_fin?] = false
    pkt[:tcp_rst?] = true  
    pkt[:ip_data] = ["ecab005004e76d9e0000000080022000f7210000080a00000001000000010000"].pack('H*')
    fp = t.calc_fingerprint( pkt, :REQUEST )
    assert_equal( fp['options'], 'T,E,E' )
    assert_equal( fp['quirks'], 'AFT' )

    pkt[:ip_ver] = 6
    pkt[:ip_header_length] = 42
    pkt[:tcp_urp] = 0
    pkt[:tcp_ack] = 1
    pkt[:tcp_data_len] = 0
    pkt[:tcp_fin?] = false
    pkt[:tcp_rst?] = false
    pkt[:tcp_psh?] = true
    pkt[:ip_data] = ["ecab005004e76d9e0000000080022000f7210000080a00000000000000000902"].pack('H*')
    fp = t.calc_fingerprint( pkt, :REQUEST )
    assert_equal( fp['options'], 'T0,?9' )
    assert_equal( fp['quirks'], 'IAF' )

    pkt[:ip_ver] = 6
    pkt[:ip_header_length] = 40
    pkt[:tcp_urp] = 0
    pkt[:tcp_ack] = 0
    pkt[:tcp_data_len] = 0
    pkt[:tcp_fin?] = false
    pkt[:tcp_rst?] = false
    pkt[:tcp_psh?] = false
    pkt[:tcp_urg?] = true
    pkt[:ip_data] = ["ecab005004e76d9e0000000080022000f7210000080a00000000000000010402"].pack('H*')
    fp = t.calc_fingerprint( pkt, :RESPONSE )
    assert_equal( fp['options'], 'T0,S' )
    assert_equal( fp['quirks'], 'AF' )
  end
end

# TCPSessions Class Code coverrage
class TCPSessionsTest < Test::Unit::TestCase

  def setup
  end

  ## receive
  ## timeout_check
  ## force_close_all
  ## empty?
  def test_tcp_sessions
    tcp_sessions = TCPSessions.new(create_options)
    #receive
    pkt = {:tcp? => false}
    assert_raise(RuntimeError){tcp_sessions.receive(pkt, false)}
    assert_raise(RuntimeError){tcp_sessions.receive(pkt, true)}
    
    #Instance doesn't have sesssion.
    pkt = {
      :ip_dst_s => "192.168.0.1",
      :ip_src_s => "192.168.100.254",
      :sport => 50976,
      :dport => 80,
      :tcp? => true,
      :tcp_syn? => true,
      :tcp_ack? => false
      }
    assert_equal(tcp_sessions.receive(pkt, false), [])
    pkt[:tcp_syn?] =  false
    assert_equal(tcp_sessions.receive(pkt, false), [])

    assert_equal(tcp_sessions.timeout_check(Time.new), [])
    assert_equal(tcp_sessions.force_close_all, [])
    assert_equal(tcp_sessions.empty?, true)

    #Instance has sesssions.
    packets = Pcap::Capture.open_offline( TEST_PACKET )
    count = 0
    packets.each do |packet|
      count += 1
      tcp_sessions.receive(packet, true)
      if count == 7
        #force_close_all
        assert_equal(tcp_sessions.receive(packet, true), [])
        assert_equal(tcp_sessions.empty?, false)
        assert_not_nil(tcp_sessions.force_close_all)
      end
    end
  end
end

# TCPSessions the behavior of TCPSession Class and TCPSessions Class 
class TCPSessionsBehaviorTest < Test::Unit::TestCase

  def setup
  end

  ## Normal operation of TCP session. ( flags : SYN, ACK, FIN )
  def test_tcp_session_normal_ope
    tcp_session = TCPSession.new(create_options)
    
    packets = Pcap::Capture.open_offline( NORMAL_OPE )
    count = 0
    packets.each do |packet|
      count += 1
      tcp_session.receive( packet )
      case count
      when 1
        assert_equal(tcp_session.tcp_state, :SYN_RECEIVED)
        assert_equal(tcp_session.mac["syn_src_mac"], "00:1b:d3:de:ed:33")
        assert_equal(tcp_session.mac["syn_dst_mac"], "00:a0:de:68:d7:28")
        assert_equal(tcp_session.fingerprint[:REQUEST]["window_size"], 65535)
        assert_equal(tcp_session.fingerprint[:REQUEST]["ttl"], 63)
        assert_equal(tcp_session.fingerprint[:REQUEST]["fragment"], true)
        assert_equal(tcp_session.fingerprint[:REQUEST]["total_length"], 64)
        assert_equal(tcp_session.fingerprint[:REQUEST]["options"], "M1236,N,W4,N,N,T,S,E,E")
        assert_equal(tcp_session.fingerprint[:REQUEST]["quirks"], "")
        assert_equal(tcp_session.fingerprint[:RESPONSE], {})
      when 2
        assert_equal(tcp_session.tcp_state, :ESTABLISHED)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["window_size"], 42900)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["ttl"], 54)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["fragment"], false)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["total_length"], 52)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["options"], "M1414,N,N,S,N,W6")
        assert_equal(tcp_session.fingerprint[:RESPONSE]["quirks"], "")
      when 3..7
        assert_equal(tcp_session.tcp_state, :ESTABLISHED)
        assert_equal(tcp_session.duplicated_n_packets[:REQUEST], 0)
        assert_equal(tcp_session.duplicated_n_packets[:RESPONSE], 0)
        assert_equal(tcp_session.duplicated_packets_size[:REQUEST], 0)
        assert_equal(tcp_session.duplicated_packets_size[:RESPONSE], 0)
        assert_equal(tcp_session.unexpected_n_packets[:REQUEST], 0)
        assert_equal(tcp_session.unexpected_n_packets[:RESPONSE], 0)
        assert_equal(tcp_session.unexpected_packets_size[:REQUEST], 0)
        assert_equal(tcp_session.unexpected_packets_size[:RESPONSE], 0)
        assert_equal(tcp_session.disordered_packets[:REQUEST], [])
        assert_equal(tcp_session.disordered_packets[:RESPONSE], [])
      when 8
        assert_equal(tcp_session.tcp_state, :HALF_CLOSED)
        assert_equal(tcp_session.close_type, "clt_fin/")
      when 9
        assert_equal(tcp_session.tcp_state, :CLOSED)
        assert_equal(tcp_session.close_type, "clt_fin/srv_fin")
      end
    end
  end

  ## Sequence Number and ACK Number loop ( flags : SYN, ACK, FIN, PSH )
  def test_tcp_session_seq_ack_loop
    tcp_session = TCPSession.new(create_options)
    
    packets = Pcap::Capture.open_offline( SEQ_ACK )
    count = 0
    packets.each do |packet|
      count += 1
      tcp_session.receive( packet )
      case count
      when 1
        assert_equal(tcp_session.tcp_state, :SYN_RECEIVED)
        assert_equal(tcp_session.mac["syn_src_mac"], "00:1b:d3:de:ed:33")
        assert_equal(tcp_session.mac["syn_dst_mac"], "00:a0:de:68:d7:28")
        assert_equal(tcp_session.fingerprint[:REQUEST]["window_size"], 65535)
        assert_equal(tcp_session.fingerprint[:REQUEST]["ttl"], 63)
        assert_equal(tcp_session.fingerprint[:REQUEST]["fragment"], true)
        assert_equal(tcp_session.fingerprint[:REQUEST]["total_length"], 64)
        assert_equal(tcp_session.fingerprint[:REQUEST]["options"], "M1236,N,W4,N,N,T,S,E,E")
        assert_equal(tcp_session.fingerprint[:REQUEST]["quirks"], "")
        assert_equal(tcp_session.fingerprint[:RESPONSE], {})
      when 2
        assert_equal(tcp_session.tcp_state, :ESTABLISHED)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["window_size"], 42900)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["ttl"], 54)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["fragment"], false)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["total_length"], 52)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["options"], "M1414,N,N,S,N,W6")
        assert_equal(tcp_session.fingerprint[:RESPONSE]["quirks"], "A")
      when 3..7
        assert_equal(tcp_session.tcp_state, :ESTABLISHED)
        assert_equal(tcp_session.duplicated_n_packets[:REQUEST], 0)
        assert_equal(tcp_session.duplicated_n_packets[:RESPONSE], 0)
        assert_equal(tcp_session.duplicated_packets_size[:REQUEST], 0)
        assert_equal(tcp_session.duplicated_packets_size[:RESPONSE], 0)
        assert_equal(tcp_session.unexpected_n_packets[:REQUEST], 0)
        assert_equal(tcp_session.unexpected_n_packets[:RESPONSE], 0)
        assert_equal(tcp_session.unexpected_packets_size[:REQUEST], 0)
        assert_equal(tcp_session.unexpected_packets_size[:RESPONSE], 0)
        assert_equal(tcp_session.disordered_packets[:REQUEST], [])
        assert_equal(tcp_session.disordered_packets[:RESPONSE], [])
      when 8
        assert_equal(tcp_session.tcp_state, :HALF_CLOSED)
        assert_equal(tcp_session.close_type, "clt_fin/")
      when 9
        assert_equal(tcp_session.tcp_state, :CLOSED)
        assert_equal(tcp_session.close_type, "clt_fin/srv_fin")
      end
    end
  end

  ## Reordering Packets
  ### Reordering of Connect phase
  def test_tcp_session_reordering_connect
    tcp_session = TCPSession.new(create_options)
    
    packets = Pcap::Capture.open_offline( REORDERING_CONNECT )
    count = 0
    packets.each do |packet|
      count += 1
      tcp_session.receive( packet )
      case count
      when 1
        assert_equal(tcp_session.tcp_state, :SYN_RECEIVED)
        assert_equal(tcp_session.mac["syn_src_mac"], "00:1b:d3:de:ed:33")
        assert_equal(tcp_session.mac["syn_dst_mac"], "00:a0:de:68:d7:28")
        assert_equal(tcp_session.fingerprint[:REQUEST]["window_size"], 65535)
        assert_equal(tcp_session.fingerprint[:REQUEST]["ttl"], 63)
        assert_equal(tcp_session.fingerprint[:REQUEST]["fragment"], true)
        assert_equal(tcp_session.fingerprint[:REQUEST]["total_length"], 64)
        assert_equal(tcp_session.fingerprint[:REQUEST]["options"], "M1236,N,W4,N,N,T,S,E,E")
        assert_equal(tcp_session.fingerprint[:REQUEST]["quirks"], "")
        assert_equal(tcp_session.fingerprint[:RESPONSE], {})
      when 2
        assert_equal(tcp_session.tcp_state, :SYN_RECEIVED)
        assert_equal(tcp_session.fingerprint[:RESPONSE], {})
      when 3
        assert_equal(tcp_session.tcp_state, :ESTABLISHED)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["window_size"], 42900)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["ttl"], 54)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["fragment"], false)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["total_length"], 52)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["options"], "M1414,N,N,S,N,W6")
        assert_equal(tcp_session.fingerprint[:RESPONSE]["quirks"], "")
      when 4..7
        assert_equal(tcp_session.tcp_state, :ESTABLISHED)
        assert_equal(tcp_session.duplicated_n_packets[:REQUEST], 0)
        assert_equal(tcp_session.duplicated_n_packets[:RESPONSE], 0)
        assert_equal(tcp_session.duplicated_packets_size[:REQUEST], 0)
        assert_equal(tcp_session.duplicated_packets_size[:RESPONSE], 0)
        assert_equal(tcp_session.unexpected_n_packets[:REQUEST], 0)
        assert_equal(tcp_session.unexpected_n_packets[:RESPONSE], 0)
        assert_equal(tcp_session.unexpected_packets_size[:REQUEST], 0)
        assert_equal(tcp_session.unexpected_packets_size[:RESPONSE], 0)
        assert_equal(tcp_session.disordered_packets[:REQUEST], [])
        assert_equal(tcp_session.disordered_packets[:RESPONSE], [])
      when 8
        assert_equal(tcp_session.tcp_state, :HALF_CLOSED)
        assert_equal(tcp_session.close_type, "clt_fin/")
      when 9
        assert_equal(tcp_session.tcp_state, :CLOSED)
        assert_equal(tcp_session.close_type, "clt_fin/srv_fin")
      end
    end
  end

  ## Reordering Packets
  ### Reordering of Data transfer phase
  def test_tcp_session_reordering_transfer
    tcp_session = TCPSession.new(create_options)
    
    packets = Pcap::Capture.open_offline( REORDERING_TRANSFER )
    count = 0
    packets.each do |packet|
      count += 1
      tcp_session.receive( packet )
      case count
      when 1
        assert_equal(tcp_session.tcp_state, :SYN_RECEIVED)
        assert_equal(tcp_session.mac["syn_src_mac"], "00:1b:d3:de:ed:33")
        assert_equal(tcp_session.mac["syn_dst_mac"], "00:a0:de:68:d7:28")
        assert_equal(tcp_session.fingerprint[:REQUEST]["window_size"], 65535)
        assert_equal(tcp_session.fingerprint[:REQUEST]["ttl"], 63)
        assert_equal(tcp_session.fingerprint[:REQUEST]["fragment"], true)
        assert_equal(tcp_session.fingerprint[:REQUEST]["total_length"], 64)
        assert_equal(tcp_session.fingerprint[:REQUEST]["options"], "M1236,N,W4,N,N,T,S,E,E")
        assert_equal(tcp_session.fingerprint[:REQUEST]["quirks"], "")
        assert_equal(tcp_session.fingerprint[:RESPONSE], {})
      when 2
        assert_equal(tcp_session.tcp_state, :ESTABLISHED)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["window_size"], 42900)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["ttl"], 54)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["fragment"], false)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["total_length"], 52)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["options"], "M1414,N,N,S,N,W6")
        assert_equal(tcp_session.fingerprint[:RESPONSE]["quirks"], "")
      when 3..7
        assert_equal(tcp_session.tcp_state, :ESTABLISHED)
        assert_equal(tcp_session.duplicated_n_packets[:REQUEST], 0)
        assert_equal(tcp_session.duplicated_n_packets[:RESPONSE], 0)
        assert_equal(tcp_session.duplicated_packets_size[:REQUEST], 0)
        assert_equal(tcp_session.duplicated_packets_size[:RESPONSE], 0)
        assert_equal(tcp_session.unexpected_n_packets[:REQUEST], 0)
        assert_equal(tcp_session.unexpected_n_packets[:RESPONSE], 0)
        assert_equal(tcp_session.unexpected_packets_size[:REQUEST], 0)
        assert_equal(tcp_session.unexpected_packets_size[:RESPONSE], 0)
        assert_equal(tcp_session.disordered_packets[:REQUEST], [])
        assert_equal(tcp_session.disordered_packets[:RESPONSE], [])
      when 8
        assert_equal(tcp_session.tcp_state, :HALF_CLOSED)
        assert_equal(tcp_session.close_type, "clt_fin/")
      when 9
        assert_equal(tcp_session.tcp_state, :CLOSED)
        assert_equal(tcp_session.close_type, "clt_fin/srv_fin")
      end
    end
  end

  ## Reordering Packets
  ### Reordering of Close phase
  def test_tcp_session_reordering_close
    tcp_session = TCPSession.new(create_options)
    
    packets = Pcap::Capture.open_offline( REORDERING_CLOSE )
    count = 0
    packets.each do |packet|
      count += 1
      tcp_session.receive( packet )
      case count
      when 1
        assert_equal(tcp_session.tcp_state, :SYN_RECEIVED)
        assert_equal(tcp_session.mac["syn_src_mac"], "00:1b:d3:de:ed:33")
        assert_equal(tcp_session.mac["syn_dst_mac"], "00:a0:de:68:d7:28")
        assert_equal(tcp_session.fingerprint[:REQUEST]["window_size"], 65535)
        assert_equal(tcp_session.fingerprint[:REQUEST]["ttl"], 63)
        assert_equal(tcp_session.fingerprint[:REQUEST]["fragment"], true)
        assert_equal(tcp_session.fingerprint[:REQUEST]["total_length"], 64)
        assert_equal(tcp_session.fingerprint[:REQUEST]["options"], "M1236,N,W4,N,N,T,S,E,E")
        assert_equal(tcp_session.fingerprint[:REQUEST]["quirks"], "")
        assert_equal(tcp_session.fingerprint[:RESPONSE], {})
      when 2
        assert_equal(tcp_session.tcp_state, :ESTABLISHED)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["window_size"], 42900)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["ttl"], 54)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["fragment"], false)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["total_length"], 52)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["options"], "M1414,N,N,S,N,W6")
        assert_equal(tcp_session.fingerprint[:RESPONSE]["quirks"], "")
      when 3..7
        assert_equal(tcp_session.tcp_state, :ESTABLISHED)
        assert_equal(tcp_session.duplicated_n_packets[:REQUEST], 0)
        assert_equal(tcp_session.duplicated_n_packets[:RESPONSE], 0)
        assert_equal(tcp_session.duplicated_packets_size[:REQUEST], 0)
        assert_equal(tcp_session.duplicated_packets_size[:RESPONSE], 0)
        assert_equal(tcp_session.unexpected_n_packets[:REQUEST], 0)
        assert_equal(tcp_session.unexpected_n_packets[:RESPONSE], 0)
        assert_equal(tcp_session.unexpected_packets_size[:REQUEST], 0)
        assert_equal(tcp_session.unexpected_packets_size[:RESPONSE], 0)
        assert_equal(tcp_session.disordered_packets[:REQUEST], [])
        assert_equal(tcp_session.disordered_packets[:RESPONSE], [])
      when 8
        assert_equal(tcp_session.tcp_state, :HALF_CLOSED)
        assert_equal(tcp_session.close_type, "srv_fin/")
      when 9
        assert_equal(tcp_session.tcp_state, :CLOSED)
        assert_equal(tcp_session.close_type, "srv_fin/clt_fin")
      end
    end
  end

  ## URG flag ON. ( flags : SYN, ACK, FIN, URG )
  def test_tcp_session_urg_flg
    tcp_session = TCPSession.new(create_options)
    
    packets = Pcap::Capture.open_offline( URG_FLG )
    count = 0
    packets.each do |packet|
      count += 1
      tcp_session.receive( packet )
      case count
      when 1
        assert_equal(tcp_session.tcp_state, :SYN_RECEIVED)
        assert_equal(tcp_session.mac["syn_src_mac"], "00:1b:d3:de:ed:33")
        assert_equal(tcp_session.mac["syn_dst_mac"], "00:a0:de:68:d7:28")
        assert_equal(tcp_session.fingerprint[:REQUEST]["window_size"], 65535)
        assert_equal(tcp_session.fingerprint[:REQUEST]["ttl"], 63)
        assert_equal(tcp_session.fingerprint[:REQUEST]["fragment"], true)
        assert_equal(tcp_session.fingerprint[:REQUEST]["total_length"], 64)
        assert_equal(tcp_session.fingerprint[:REQUEST]["options"], "M1236,N,W4,N,N,T,S,E,E")
        assert_equal(tcp_session.fingerprint[:REQUEST]["quirks"], "")
        assert_equal(tcp_session.fingerprint[:RESPONSE], {})
      when 2
        assert_equal(tcp_session.tcp_state, :ESTABLISHED)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["window_size"], 42900)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["ttl"], 54)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["fragment"], false)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["total_length"], 52)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["options"], "M1414,N,N,S,N,W6")
        assert_equal(tcp_session.fingerprint[:RESPONSE]["quirks"], "")
      when 3..7
        assert_equal(tcp_session.tcp_state, :ESTABLISHED)
        assert_equal(tcp_session.duplicated_n_packets[:REQUEST], 0)
        assert_equal(tcp_session.duplicated_n_packets[:RESPONSE], 0)
        assert_equal(tcp_session.duplicated_packets_size[:REQUEST], 0)
        assert_equal(tcp_session.duplicated_packets_size[:RESPONSE], 0)
        assert_equal(tcp_session.unexpected_n_packets[:REQUEST], 0)
        assert_equal(tcp_session.unexpected_n_packets[:RESPONSE], 0)
        assert_equal(tcp_session.unexpected_packets_size[:REQUEST], 0)
        assert_equal(tcp_session.unexpected_packets_size[:RESPONSE], 0)
        assert_equal(tcp_session.disordered_packets[:REQUEST], [])
        assert_equal(tcp_session.disordered_packets[:RESPONSE], [])
      when 8
        assert_equal(tcp_session.tcp_state, :HALF_CLOSED)
        assert_equal(tcp_session.close_type, "clt_fin/")
      when 9
        assert_equal(tcp_session.tcp_state, :CLOSED)
        assert_equal(tcp_session.close_type, "clt_fin/srv_fin")
      end
    end
  end

  ## RST flag ON. ( flags : SYN, ACK, FIN, RST )
  def test_tcp_session_rst_flg
    tcp_session = TCPSession.new(create_options)
    
    packets = Pcap::Capture.open_offline( RST_FLG )
    count = 0
    packets.each do |packet|
      count += 1
      tcp_session.receive( packet )
      case count
      when 1
        assert_equal(tcp_session.tcp_state, :SYN_RECEIVED)
        assert_equal(tcp_session.mac["syn_src_mac"], "00:1b:d3:de:ed:33")
        assert_equal(tcp_session.mac["syn_dst_mac"], "00:a0:de:68:d7:28")
        assert_equal(tcp_session.fingerprint[:REQUEST]["window_size"], 65535)
        assert_equal(tcp_session.fingerprint[:REQUEST]["ttl"], 63)
        assert_equal(tcp_session.fingerprint[:REQUEST]["fragment"], true)
        assert_equal(tcp_session.fingerprint[:REQUEST]["total_length"], 64)
        assert_equal(tcp_session.fingerprint[:REQUEST]["options"], "M1236,N,W4,N,N,T,S,E,E")
        assert_equal(tcp_session.fingerprint[:REQUEST]["quirks"], "")
        assert_equal(tcp_session.fingerprint[:RESPONSE], {})
      when 2
        assert_equal(tcp_session.tcp_state, :ESTABLISHED)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["window_size"], 42900)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["ttl"], 54)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["fragment"], false)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["total_length"], 52)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["options"], "M1414,N,N,S,N,W6")
        assert_equal(tcp_session.fingerprint[:RESPONSE]["quirks"], "")
      when 3..6
        assert_equal(tcp_session.tcp_state, :ESTABLISHED)
        assert_equal(tcp_session.duplicated_n_packets[:REQUEST], 0)
        assert_equal(tcp_session.duplicated_n_packets[:RESPONSE], 0)
        assert_equal(tcp_session.duplicated_packets_size[:REQUEST], 0)
        assert_equal(tcp_session.duplicated_packets_size[:RESPONSE], 0)
        assert_equal(tcp_session.unexpected_n_packets[:REQUEST], 0)
        assert_equal(tcp_session.unexpected_n_packets[:RESPONSE], 0)
        assert_equal(tcp_session.unexpected_packets_size[:REQUEST], 0)
        assert_equal(tcp_session.unexpected_packets_size[:RESPONSE], 0)
        assert_equal(tcp_session.disordered_packets[:REQUEST], [])
        assert_equal(tcp_session.disordered_packets[:RESPONSE], [])
      when 7
        assert_equal(tcp_session.tcp_state, :HALF_CLOSED)
        assert_equal(tcp_session.close_type, "srv_rst/")
      when 8
        assert_equal(tcp_session.tcp_state, :CLOSED)
        assert_equal(tcp_session.close_type, "srv_rst/clt_fin")
      when 9
        assert_equal(tcp_session.tcp_state, :CLOSED)
        assert_equal(tcp_session.close_type, "srv_rst/clt_fin")
      end
    end
  end

  ## Straddle the date of sessions.
  def test_tcp_session_straddle_date
    tcp_session = TCPSession.new(create_options)
    
    packets = Pcap::Capture.open_offline( STRADDLE_DATE )
    count = 0
    packets.each do |packet|
      count += 1
      tcp_session.receive( packet )
      case count
      when 1
        assert_equal(tcp_session.tcp_state, :SYN_RECEIVED)
        assert_equal(tcp_session.mac["syn_src_mac"], "08:60:6e:7d:13:45")
        assert_equal(tcp_session.mac["syn_dst_mac"], "00:15:2c:13:c6:c0")
        assert_equal(tcp_session.fingerprint[:REQUEST]["window_size"], 8192)
        assert_equal(tcp_session.fingerprint[:REQUEST]["ttl"], 128)
        assert_equal(tcp_session.fingerprint[:REQUEST]["fragment"], true)
        assert_equal(tcp_session.fingerprint[:REQUEST]["total_length"], 52)
        assert_equal(tcp_session.fingerprint[:REQUEST]["options"], "M1460,N,W8,N,N,S")
        assert_equal(tcp_session.fingerprint[:REQUEST]["quirks"], "")
        assert_equal(tcp_session.fingerprint[:RESPONSE], {})
      when 2..12
        assert_equal(tcp_session.tcp_state, :ESTABLISHED)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["window_size"], 14140)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["ttl"], 55)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["fragment"], true)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["total_length"], 52)
        assert_equal(tcp_session.fingerprint[:RESPONSE]["options"], "M1380,N,N,S,N,W9")
        assert_equal(tcp_session.fingerprint[:RESPONSE]["quirks"], "Z")
        assert_equal(tcp_session.duplicated_n_packets[:REQUEST], 0)
        assert_equal(tcp_session.duplicated_n_packets[:RESPONSE], 0)
        assert_equal(tcp_session.duplicated_packets_size[:REQUEST], 0)
        assert_equal(tcp_session.duplicated_packets_size[:RESPONSE], 0)
        assert_equal(tcp_session.unexpected_n_packets[:REQUEST], 0)
        assert_equal(tcp_session.unexpected_n_packets[:RESPONSE], 0)
        assert_equal(tcp_session.unexpected_packets_size[:REQUEST], 0)
        assert_equal(tcp_session.unexpected_packets_size[:RESPONSE], 0)
        assert_equal(tcp_session.disordered_packets[:REQUEST], [])
        assert_equal(tcp_session.disordered_packets[:RESPONSE], [])
      when 13..14
        assert_equal(tcp_session.tcp_state, :HALF_CLOSED)
        assert_equal(tcp_session.close_type, "srv_fin/")
      when 15..17
        assert_equal(tcp_session.tcp_state, :CLOSED)
        assert_equal(tcp_session.close_type, "srv_fin/clt_fin")
      end
    end
  end
end