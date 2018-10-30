# Test Case of pasta

## Test of TCP

###test_tcp_sessions.rb
 - **TCPSession** Class Code coverage
 - **TCPSessions** Class Code coverage
 - The behavior of **TCPSession** Class and **TCPSessions** Class 

* [Normal operation]
 - Normal operation of TCP session. ( flags : SYN, ACK, FIN )
 - Sequence Number and ACK Number looop ( flags : SYN, ACK, FIN, PSH )
 - Reordering Packets
 - URG flag ON. ( flags : SYN, ACK, FIN, URG )
 - RST flag ON. ( flags : SYN, ACK, FIN, RST )
 - Straddle the date of sessions

***
***
# Test of not adding
## Test of Ethernet
* [Normal operation]
 - Parse VLAN, EOE and PBB

## Test of IP
* [Normal operation]
 - Parse IPv4 and IPv6

## Test of TCP
* [Normal operation]
 - Captured packets when SEQ number is looped
 - Captured packets when ACK number is looped

* [Abnormal operation]
 - Wrong data length
 - Wrong Header length
 - Wrong the port number
 - Packet duplication
 - Interaction with the terminal there is no sudden

## Test of UDP
 - **UDPSession** Class Code coverage
 - **UDPSessions** Class Code coverage
 - The behavior of **UDPSession** Class and **UDPSessions** Class.

* [Normal operation]
 - Receive UDP Packets
 - Parse DNS data

   Each DNS record(A, AAAA, CNAME, HINFO, MX, NS, PTR, SQA, SRV, TXT)

* [Abnormal operation]
 - Wrong data length.
 
## Test of HTTP
 - **HTTPParser** Class Code coverage

* [Normal operation]
 - HTTP method (GET, HEAD, POST, PUT, DELETE ...)
 - Pipelining
 - Pattern of Response name and Response message
 - video_container_parse
 - parse_tarminal_ids
 - parse_html5
 - parse_youtube_feed