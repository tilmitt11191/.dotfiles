# -*- encoding: utf-8 -*-

require_relative 'video_container_parser.rb'

require 'uri'
require 'zlib'
require 'stringio'
require 'rexml/document'
require 'digest/md5'

# A HTTP parser which works closely with TCPSessions and TCPSession.
# The HTTP Parser can parse HTTP sessions on the fly.
class HTTPParser

  include VideoContainerParser

  # Construct a new instance.
  # @param [Boolean] plain_text        Set true to keep original private information.
  # @param [String]  hash_salt         A hash salt for hashing private information.
  # @param [Array]   packets           A packet queue to be parsed.
  # @param [Array]   ack_time_history  An array of pairs of TCP ACK number and captured time.
  # @note  The packet queue and the ACK/time history are shared with TCPSession and is updated externally. This design is decided to reduce the cost of parameter passing.
  # @note  Nil is acceptable for packets and ack_time_history.
  def initialize( plain_text, hash_salt, packets = nil, ack_time_history = nil )
    @@plain_text = plain_text
    @@hash_salt = hash_salt
    @packets = packets
    @ack_time_history = ack_time_history
    @buffer = {:REQUEST => '', :RESPONSE => ''}
    @sessions = {:REQUEST => [], :RESPONSE => []}
    @first_packets = {:REQUEST => nil, :RESPONSE => nil}
    @http_state = {:REQUEST => nil, :RESPONSE => nil}
    @body_remaining = {:REQUEST => nil, :RESPONSE => nil}
    @seq_time_history = {:REQUEST => [], :RESPONSE => []}
    new_session( :REQUEST )
    new_session( :RESPONSE )
  end

  # Try to parse payloads of packets in the packet queue.
  # @param [Boolean] closed  Set true if the underlaid TCP session is already closed and the HTTP parser also should finalize the HTTP session.
  # @note  On the fly processing can reduce memory usage.
  def on_the_fly( closed = false )
    [:REQUEST, :RESPONSE].each do |rr|
      @first_packets[rr] ||= @packets[rr].first
      @packets[rr].each do |pkt|
        if pkt.tcp_data
          @buffer[rr].concat( pkt.tcp_data[ TCPSession.tcp_seq_mod( @seq_time_history[rr].last[0] - pkt.tcp_seq ), pkt.tcp_data_len ].to_s )
        end
        seq = TCPSession.tcp_seq_mod( pkt.tcp_seq + pkt.tcp_data_len + (pkt.tcp_syn? ? 1 : 0) )
        if @seq_time_history[rr].empty?
          @seq_time_history[rr] << [seq, pkt.time]
        elsif TCPSession.tcp_seq_gt?( seq, @seq_time_history[rr].last[0] )
          @seq_time_history[rr] << [seq, [pkt.time, @seq_time_history[rr].last[1]].max]
        end
      end
      while !@buffer[rr].empty?
        case @http_state[rr]
        when :MESSAGE
          read_size, parsed, leaving = try_to_parse( rr, :MESSAGE, @buffer[rr] )
          break if read_size == 0
          @sessions[rr].last['size'] += read_size - leaving.size
          @sessions[rr].last['actual_size'] += read_size - leaving.size
          @sessions[rr].last.merge! parsed
          @buffer[rr].slice! 0, read_size
          @http_state[rr] = :HEADER
          @sessions[rr].last['begin_time'] = search_timestamp( rr )
        when :HEADER
          read_size, headers = try_to_parse( rr, :HEADER, @buffer[rr] )
          break if read_size == 0
          @sessions[rr].last['size'] += read_size
          @sessions[rr].last['actual_size'] += read_size
          @sessions[rr].last['headers'] = headers
          @buffer[rr].slice! 0, read_size
          @http_state[rr] = :BODY
          redo
        when :BODY
          if @sessions[rr].last['headers']['Content-Length'] or rr == :REQUEST
            unless @body_remaining[rr]
              content_length = [@sessions[rr].last['headers']['Content-Length'].to_i, 0].max
              @body_remaining[rr] = content_length
              @sessions[rr].last['size'] += content_length
            end
            read = @buffer[rr].slice! 0, @body_remaining[rr]
            @sessions[rr].last['actual_size'] += read ? read.size : 0
            @sessions[rr].last['body'].concat read if body_for_retention?( @sessions[rr].last['headers']['Content-Type'], @sessions[rr].last['body'].size )
            @body_remaining[rr] -= read ? read.size : 0
            if @body_remaining[rr] == 0
              @sessions[rr].last['end_time'] = search_timestamp( rr )
              new_session rr
            end
          else
            # when Content-Lenth is not set, search for next http message
            read_size, parsed, leaving = try_to_parse( rr, :MESSAGE, @buffer[rr] )
            # http message is not found
            if read_size == 0
              @sessions[rr].last['size'] += @buffer[rr].size
              @sessions[rr].last['actual_size'] += @buffer[rr].size
              @sessions[rr].last['body'].concat @buffer[rr] if body_for_retention?( @sessions[rr].last['headers']['Content-Type'], @sessions[rr].last['body'].size )
              @buffer[rr] = ''
            # http message is found
            else
              @sessions[rr].last['size'] += leaving.size
              @sessions[rr].last['actual_size'] += leaving.size
              @sessions[rr].last['body'].concat leaving  if body_for_retention?( @sessions[rr].last['headers']['Content-Type'], @sessions[rr].last['body'].size )
              @sessions[rr].last['end_time'] = search_timestamp( rr )
              new_session rr
              @sessions[rr].last['size'] += read_size - leaving.size
              @sessions[rr].last['actual_size'] += read_size - leaving.size
              @sessions[rr].last.merge! parsed
              @buffer[rr].slice! 0, read_size
              @http_state[rr] = :HEADER
              @sessions[rr].last['begin_time'] = search_timestamp( rr )
            end
          end
        end
      end
      @sessions[rr].last['end_time'] = search_timestamp( rr ) if closed and @http_state[rr] == :BODY

      # fill out ack times
      next unless @first_packets[rr]
      ack_time_history = (rr == :REQUEST ? @ack_time_history[:RESPONSE] : @ack_time_history[:REQUEST])
      target_ack = @first_packets[rr].tcp_seq + 1
      @sessions[rr].each do |session|
        target_ack += session['actual_size']
        next unless session['end_time'] and !session['end_time_ack']
        next if ack_time_history.empty?
        if index = ack_time_history.index{|history| TCPSession.tcp_seq_ge?( history[0], target_ack )}
          session['end_time_ack'] = ack_time_history[index][1]
          ack_time_history.slice! 0, index
        end
      end
    end
  end

  # Output dummy session information for padding.
  # @return [Array]  Return an array consists of nils. The size of the array equals to valid HTTP session information.
  def padding
    format_request_response( :REQUEST ) + format_request_response( :RESPONSE ) + 
    parse_gps_request() + parse_terminal_ids() + parse_html5() + parse_youtube_feed() + parse_video_container()
  end

  # Format HTTP session information.
  # @param [Boolean] outfile_debug              Set true to output debug information.
  # @param [Boolean] no_corresponding_response  Set true to output http requests even if they lack corresponding http responses.
  # @param [Boolean] parse_html                 Set true to analyze http body using hpricot library.
  # @return [Array]  Return an array listing HTTP session information fields including GPS, terminal ID, HTML5, YouTube feed, and video container.
  def format_http_info( outfile_debug = nil, no_corresponding_response = false, parse_html = false )
    ret = []
    @sessions[:REQUEST].each_with_index do |request, i|
      break unless (response = @sessions[:RESPONSE][i]) or no_corresponding_response
      break unless request['headers']
      break unless no_corresponding_response or response['headers']
      response = nil if response and !response['headers']
      if response and !response['body'].empty? and response['headers'] and response['headers']['Transfer-Encoding'] == 'chunked'
        body = ''
        until response['body'].empty?
          if response['body'].gsub!( /\A([0-9a-fA-F]+)(\r\n|\r|\n)/, '' )
            body.concat( response['body'].slice!( 0, $1.to_i( 16 ) ) )
            response['body'].gsub!( /\A(\r\n|\r|\n)/, '' )
          else
            break
          end
        end
        response['body'] = body
      end
      if response and !response['body'].empty? and response['headers'] and response['headers']['Content-Encoding'] == 'gzip'
        begin
          response['body'] = Zlib::GzipReader.new( StringIO.new( response['body'] ), encoding: "ASCII-8BIT" ).read
        rescue
          response['body'] = ''
        end
      end
      r = {}
      formatted_request = format_request_response( :REQUEST, request )
      formatted_response = format_request_response( :RESPONSE, response )
      parsed_request_path = parse_request_path( request['path'] )
      r['tcp'] = formatted_request + formatted_response +
                 parse_gps_request( parsed_request_path ) + parse_terminal_ids( parsed_request_path, request['headers'] ) +
                 parse_html5( request, response, parse_html ) + parse_youtube_feed( request, response ) +
                 parse_video_container( response['body'] )
      r['debug'] = debug_message( {:REQUEST => [request, formatted_request], :RESPONSE => [response, formatted_response]} ) if outfile_debug
      ret << r
    end
    ret
  end

  private

  def format_request_response( rr, session = nil )
    session ||= {'headers' => {}}
    ret = [
    session['begin_time'] ? session['begin_time'].iso8601(6) : nil,
    session['end_time'] ? session['end_time'].iso8601(6) : nil,
    session['end_time_ack'] ? session['end_time_ack'].iso8601(6) : nil,
    session['size'],
    session['actual_size']
    ]
    case rr
    when :REQUEST
      ret += [
      session['message'],
      session['path'],
      session['version'],
      session['headers']['Host'],
      session['headers']['Range'],
      session['headers']['Content-Length'],
      session['headers']['Referer'],
      session['headers']['User-Agent']
      ]
    when :RESPONSE
      ret += [
      session['version'],
      session['status'],
      session['message'],
      session['headers']['Server'],
      session['headers']['Accept-Ranges'],
      session['headers']['Content-Range'],
      session['headers']['Content-Length'],
      session['headers']['Content-Type'],
      session['headers']['Connection']
      ]
    end
  end

  def debug_message( data )
    ret = ''
    [:REQUEST, :RESPONSE].each do |rr|
      ret << "======== #{rr.to_s.downcase} ========\r\n"
      ret << "-------- formatted csv --------\r\n"
      ret << data[rr][1].join(", ") + "\r\n"
      ret << "-------- http info --------\r\n"
      data[rr][0].each do |key, value|
        next if ['headers', 'body'].include? key
        ret << "#{key} = #{value}\r\n"
      end
      ret << "-------- http headers (in random order) --------\r\n"
      data[rr][0]['headers'].each do |key, value|
        ret << "#{key}: #{value}\r\n"
      end
      ret << "-------- http body (text/video only) --------\r\n"
      ret << data[rr][0]['body'].to_s + "\r\n"
    end
    ret
  end

  def session_format
    {
      'begin_time'   => nil,
      'end_time'     => nil,
      'end_time_ack' => nil,
      'size'         => 0,
      'actual_size'  => 0,
      'version'      => nil,
      'path'         => nil,
      'body'         => '',
      'status'       => nil,
      'message'      => nil,
      'headers'      => nil
    }
  end

  def new_session( rr )
    @http_state[rr] = :MESSAGE
    @body_remaining[rr] = nil
    @sessions[rr] << session_format
  end

    def search_timestamp( rr )
    target_seq = @sessions[rr].inject(0){|s, x| s + x['actual_size']} + @first_packets[rr].tcp_seq + 1
    @seq_time_history[rr].each_with_index do |history, i|
      if TCPSession.tcp_seq_ge?( history[0], target_seq )
        time = history[1]
        @seq_time_history[rr].slice! 0...i
        return time
      end
    end
    nil
  end

  REQUEST_METHOD_REGEX = /^(.*?)(OPTIONS|GET|HEAD|POST|PUT|DELETE|TRACE|CONNECT)\s+([^\s]*)\s+([^\s]*)\s*(\r\n|\r|\n)/
  RESPONSE_CODE_REGEX = /^(.*?)(HTTP\/[0-9]+\.[0-9]+)\s+([0-9]{3})\s+([^\n\r]*)\s*(\r\n|\r|\n)/
  NULL_LINE_REGEX = /^(\r\n|\r|\n)/
  HTTP_HEADER_REGEX = /^([A-Z][A-Za-z-]*):\s*([^\n\r]*)\s*(\r\n|\r|\n)/
  def try_to_parse( rr, http_state, concat_data )
    case http_state
    when :MESSAGE, :BODY
      read_size = 0
      parsed = {}
      case rr
      when :REQUEST
        if REQUEST_METHOD_REGEX =~ concat_data
          leaving, parsed['message'], parsed['path'], parsed['version'] = $1, $2, $3, $4
          read_size = Regexp.last_match.offset(0)[1]
        end
      when :RESPONSE
        if RESPONSE_CODE_REGEX =~ concat_data
          leaving, parsed['version'], parsed['status'], parsed['message'] = $1, $2, $3, $4
          read_size = Regexp.last_match.offset(0)[1]
        end
      end
      return read_size, parsed, leaving

    when :HEADER
      read_size = 0
      headers = {}
      finished = false
      concat_data.each_line do |l|
        read_size += l.size
        if NULL_LINE_REGEX =~ l
          finished = true
          break
        elsif HTTP_HEADER_REGEX =~ l
          headers[$1] = $2
        end
      end
      if finished
        return read_size, headers
      else
        return 0, {}
      end
    end
  end

  BODY_RETENTION_RULES = {
    /(text\/|application\/atom\+xml)/i => 1_048_576,
    /(video\/)/i => 65_536
  }
  def body_for_retention?( content_type, current_size )
    BODY_RETENTION_RULES.each do |rule, size_limit|
      return true if rule =~ content_type.to_s and (!size_limit or current_size < size_limit)
    end
    return false
  end

  def parse_request_path( request_path )
    q = []
    begin
      parsed = URI.parse( request_path ).query
    rescue
      return q
    end
    return q unless parsed
    parsed.split('&').each do |arg|
      s = arg.split('=')
      q << [
      String.method_defined?(:encode) ? s[0].to_s.encode("US-ASCII", "US-ASCII", :invalid => :replace, :undef => :replace, :replace => '?') : s[0],
      String.method_defined?(:encode) ? s[1].to_s.encode("US-ASCII", "US-ASCII", :invalid => :replace, :undef => :replace, :replace => '?') : s[1],
      ]
    end
    q
  end

  TERMINAL_IDS_REGEX = {
    'IMSI' => /((^|[^0-9])(44(00[78]|05[0-6]|07[0-9]|08[89]|170)[0-9]{10})($|[^0-9]))/,
    'MEID' => /((^|[^0-9a-fA-F])([a-fA-F][0-9a-fA-F]{13})($|[^0-9a-fA-F]))/
  }
  def parse_terminal_ids( parsed_request_path = [], headers = {} )
    path_headers = {
      'path' => Hash[*parsed_request_path.flatten],
      'headers' => headers
    }
    res = {}
    TERMINAL_IDS_REGEX.each do |id, regex|
      path_headers.each do |ph, q|
        break if res[id]
        q.each do |k, v|
          if regex =~ v
            res[id] = ["#{ph}/#{k}", $3]
            break
          end
        end
      end
    end
    [res['IMSI'] ? res['IMSI'][0] : nil, res['IMSI'] ? ( @@plain_text ? res['IMSI'][1] : Digest::MD5.hexdigest( res['IMSI'][1] + @@hash_salt ) ) : nil,
     res['MEID'] ? res['MEID'][0] : nil, res['MEID'] ? ( @@plain_text ? res['MEID'][1] : Digest::MD5.hexdigest( res['MEID'][1] + @@hash_salt ) ) : nil]
  end

  REGEX_COORDINATE = {'degree' => /^[0-9]+\.[0-9]+$/, 'msec' => /^[0-9]{1,32}$/, 'dms' => /^[0-9]+[\.\/][0-9]+[\.\/][0-9]+(\.[0-9]+)?$/}
  EXTREME_POINTS = {'north' => 45.5571861111111, 'south' => 20.4252777777778, 'east' => 153.986388888889, 'west' => 122.933611111111}
  def is_valid_coordinate_in_japan( lat, lon )
    begin
      if REGEX_COORDINATE['degree'] =~ lat and REGEX_COORDINATE['degree'] =~ lon
        lat, lon = lat.to_f, lon.to_f
      elsif REGEX_COORDINATE['msec'] =~ lat and REGEX_COORDINATE['msec'] =~ lon
        lat, lon = msec_to_degree(lat), msec_to_degree(lon)
      elsif REGEX_COORDINATE['dms'] =~ lat and REGEX_COORDINATE['dms'] =~ lon
        lat, lon = dms_to_degree(lat), dms_to_degree(lon)
      else
        return nil
      end
      if EXTREME_POINTS['south'] < lat.to_f and lat.to_f < EXTREME_POINTS['north'] and EXTREME_POINTS['west'] < lon.to_f and lon.to_f < EXTREME_POINTS['east']
        return [lat, lon]
      else
        return nil
      end
    rescue => e
      return nil
    end
  end

  def msec_to_degree( msec )
    msec.to_i.to_f / 3600000.0
  end

  def dms_to_degree( dms )
    s = dms.to_s.split(/[\.\/]/)
    s[0].to_i + s[1].to_f/60.0 + (s[2].to_s + '.' + s[3].to_s).to_f / 3600.0
  end

  def tokyo_to_wgs84( lat, lon )
    return (lat - 0.00010695 * lat + 0.000017464 * lon + 0.0046017), (lon - 0.000046038 * lat - 0.000083043 * lon + 0.010040)
  end

  COMMA_SEMICOLON_SEPARATED_REGEX = /([0-9\.\/]+)[,;]([0-9\.\/]+)([,;]([0-9\.\/]+)[,;]([0-9\.\/]+))?/
  def parse_gps_request( parsed_request_path = [] )
    qa = parsed_request_path
    q = Hash[*qa.flatten]
    gps_type = nil
    lat = nil
    lon = nil
    if q['datum'] and q['unit'] and q['lat'] and q['lon'] and q['datum'] == 'tokyo' and q['unit'] == 'dms'
      gps_type = 'location'
      lat = dms_to_degree q['lat']
      lon = dms_to_degree q['lon']
    elsif q['ver'] and q['datum'] and q['unit'] and q['lat'] and q['lon'] and q['alt'] and q['time'] and
      q['smaj'] and q['smin'] and q['vert'] and q['majaa'] and q['fm']
      gps_type = 'gpsone'
      if q['unit'] == '0'
        lat = dms_to_degree q['lat']
        lon = dms_to_degree q['lon']
      else
        lat = q['lat'].to_f
        lon = q['lon'].to_f
      end
      if q['datum'] == '1'
        lat, lon = tokyo_to_wgs84 lat, lon
      end
    else
      q.each_value do |v|
        if COMMA_SEMICOLON_SEPARATED_REGEX =~ v
          [[$1, $2], [$2, $1]].each do |o|
            if c = is_valid_coordinate_in_japan( *o )
              gps_type = 'other'
              lat, lon = *c
              break
            end
          end
        end
      end
      qa.each do |i|
        qa.each do |j|
          next if i[0] == j[0]
          if c = is_valid_coordinate_in_japan( i[1], j[1] )
            gps_type = 'other'
            lat, lon = *c
            break
          end
        end
        break if gps_type
      end
    end
    if ['location', 'gpsone', 'other'].include? gps_type
      return [gps_type, lat, lon, q['time'], q['fm']]
    else
      return [nil, nil, nil, nil, nil]
    end
  end

  HTML5_REGEX_RES_BODY = [ # id       , # class   , # tag    , # target     , # regex
                          # Geo Location
                          ['geoloc'   , 'elem'    , 'script' , nil          , /navigator\.geolocation/      ],
                          # History Interface
                          ['history'  , 'elem'    , 'script' , nil          , /history\.pushState\s*(.*)/   ],
                          # Network Information API(old)
                          ['ninfoapi' , 'elem'    , 'script' , nil          , /navigator\.connection\.type/ ],
                          # WebNotifications
                          ['notif'    , 'elem'    , 'script' , nil          , /webkitNotifications/         ],
                          # Server-Sent Events
                          ['ssevents' , 'elem'    , 'script' , nil          , /EventSource\s*(.*)/          ],
                          # WebRTC (MediaStream)
                          ['gusrmedia', 'elem'    , 'script' , nil          , /GetUserMedia\s*(.*)/i        ],
                          # WebRTC (MediaStream)
                          ['rtcpeer'  , 'elem'    , 'script' , nil          , /RTCPeerConnection\s*(.*)/i   ],
                          # Web Intents
                          ['wintents' , 'elem'    , 'script' , nil          , /startActivity/i              ],
                          # Web Workers
                          ['worker'   , 'elem'    , 'script' , nil          , /\s*Worker\s*(.*)/            ],
                          # The WebSocket API(code)
                          ['wsocket'  , 'elem'    , 'script' , nil          , /WebSocket\s*(.*)/            ],
                          # XMLHttpRequest
                          ['xmlhreq'  , 'elem'    , 'script' , nil          , /XMLHttpRequest/              ],
                          # Web Speech API
                          ['wspeech'  , 'elem'    , 'script' , nil          , /SpeechRecognition\s*(.*)/i   ],
                          # CU-RTC-Web
                          ['curtcweb' , 'elem'    , 'script' , nil          , /RealtimeMediaStream\s*(.*)/i ],
                          
                          # HTML5 Doctype manifest
                          ['html5'    , 'doctype' , 'doctype', 'html'       , nil                         ],
                          # Local Storage
                          ['lstorage' , 'elem'    , 'script' , nil          , /localStorage/              ],
                          # Session Storage
                          ['sstorage' , 'elem'    , 'script' , nil          , /sessionStorage/            ],
                          # WebSQL DataBase
                          ['websqldb' , 'elem'    , 'script' , nil          , /openDatabase\s*(.*)/       ],
                          # IndexedDB
                          ['indexeddb', 'elem'    , 'script' , nil          , /indexedDB\.open\s*(.*)/    ],
                          # App Cache
                          ['appcache' , 'elem'    , 'html'   , 'manifest'   , nil                         ],
                          # Web Worker
                          ['worker'   , 'elem'    , 'script' , nil          , /Worker\s*(.*)/             ],
                          # WebSocket (code)
                          ['wsocket'  , 'elem'    , 'script' , nil          , /WebSocket\s*(.*)/          ],
                          # Notifications
                          ['notif'    , 'elem'    , 'script' , nil          , /webkitNotifications/       ],
                          # File API including Drag-in/out
                          ['fileapi'  , 'elem'    , 'script' , nil          , /dataTransfer/              ],
                          # File System API
                          ['fsapi'    , 'elem'    , 'script' , nil          , /requestFileSystem\s*(.*)/  ],
                          # Device Orientation as G-sensor
                          ['devorient', 'elem'    , 'script' , nil          , /deviceorientation/         ],
                          # Speech Input
                          ['speech'   , 'elem'    , 'input'  , nil          , /x-webkit-speech/i          ],
                          # GetUserMedia for WebRTC, etc of  Device Access
                          ['gusrmedia', 'elem'    , 'script' , nil          , /getUserMedia\s*(.*)/       ],
                          # Video
                          ['video'    , 'elem'    , 'video'  , nil          , nil                         ],
                          # Audio
                          ['audio'    , 'elem'    , 'audio'  , nil          , nil                         ]
                         ]
  HTML5_REGEX_HEADER = [
                        # Content Security Policy 1.0
                        ['ccpolicy' , /Content-Security-Policy/i],
                        # Cross-Origin Resource Sharing
                        ['corigres' , /Access-Control-Allow-Origin/i],

                        ['wsocreq'  , /Sec-WebSocket-Key/i],     # => WebSocket REQ
                        ['wsocres'  , /Sec-WebSocket-Accept/i]  # => WebScoket RES
                       ]

  def estimate_html5( str )

    # Calibrate Hpricot.buffer_size
    if str && str.bytesize > 16384              # 16384 -> Hpricot default buffer size
      Hpricot.buffer_size = str.bytesize + 1024 # str.bytesize + mergin
    else
      Hpricot.buffer_size = nil                 # set default Hpricot buffer size
    end

    doc = Hpricot(str)
    ret = Array.new
    (doc/'*').each{|v|
      if v.doctype?
        HTML5_REGEX_RES_BODY.each{|rr|
          if rr[1] == 'doctype' and rr[2] == 'doctype'
            ret << rr[0] if v.doctype['target'].downcase == rr[3]
          end
        }
      end
      if v.elem?
        HTML5_REGEX_RES_BODY.each{|rr|
          if rr[1] == 'elem' and ( v.elem['tag'].downcase == rr[2] or v.elem['tag'] == nil )
            # there exist target attr. and defined regex
            # no sample
            if rr[3] and rr[4]
              if rr[4] =~ v.elem['attrs'][rr[3]]
                ret << rr[0]
                next
              end
            end
            # there exist target attr., but there's NOT regex
            # e.g. appcache (in short, if there exist 'manifest' attr. then output its mark)
            if rr[3] and not rr[4]
              if v.elem['attrs'] and v.elem['attrs'].include?(rr[3])
                ret << rr[0]
                next
              end
            end
            # there exist defined regex, but there's NOT target attr.
            # e.g. lstorage
            if not rr[3] and rr[4]
              if rr[4] =~ v.elem.to_s
                ret << rr[0]
                next
              end
            end
            # there're NOT any attrs. and defined regex
            # e.g. video
            if not rr[3] and not rr[4]
              ret << rr[0]
              next
            end
          end
        }
      end
      # for js file
      if not v.doctype? and not v.elem?
        if /function/ =~ v.to_s
          HTML5_REGEX_RES_BODY.each{|rr|
            if rr[1] == 'elem' and rr[2] == 'script'
              if rr[4] =~ v.to_s
                ret << rr[0]
                next
              end
            end
          }
        end
      end
    }
    return ret.uniq
  end

  def parse_html5( request = nil, response = nil, parse_html = false )
    return [nil] unless request and response
    return [nil] unless parse_html
    ret = []
    if /text/ =~ response['headers']['Content-Type'].to_s
      begin
        ret = estimate_html5( response['body'][0..1_000_000] )
      rescue SystemStackError => e
        ret = []
      rescue =>e
        ret = []
      end
    end
    HTML5_REGEX_HEADER.each do |regex|
      request['headers'].each_key{|k| ret << regex[0] if regex[1] =~ k}
      response['headers'].each_key{|k| ret << regex[0] if regex[1] =~ k}
    end
    ret.empty? ? [nil] : [ret.uniq.join('/')]
  end

  def parse_youtube_feed( request = nil, response = nil )
    return [nil] unless request and response
    return [nil] unless request['headers']['Host'] and request['headers']['Host'].include?( 'gdata.youtube' )
    return [nil] unless response['headers']['Content-Type'] and /application\/atom\+xml.*type=feed/i =~ response['headers']['Content-Type']
    return [nil] if !request['path'] or /\/comments\?|\/events|\/channels|\/playlists\?/ =~ request['path']
    videos = [] 
    begin
      xml = REXML::Document.new response['body']
      xml.elements.each('feed/entry') do |entry|
        video = []
        if id = entry.elements['media:group/yt:videoid']
          video << id.text
        elsif /.*video:([0-9a-zA-Z\-_]+)/ =~ entry.elements['id'].text
          video << $1
        else
          next
        end
        begin
          if content = entry.elements['content']
            uri = content.attributes['src']
          elsif content = entry.elements['media:group/media:content']
            uri = content.attributes['url']
          end
          query = URI.parse( uri ).query
          query.split('&').each do |arg|
            s = arg.split('=')
            if s[0] == 'id'
              video << s[1]
              break
            end
          end
        rescue
        end
        videos << video.join(':')
      end
      return [videos.join(' ')]
    rescue => e
      return [nil]
    end
  end

end
