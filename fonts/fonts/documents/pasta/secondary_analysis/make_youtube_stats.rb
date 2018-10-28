#!/usr/bin/env ruby

STDOUT.sync = true

ABANDON_THRESHOLD = 30 * 60  # sec
WATCH_TIMEOUT_THRESHOLD = 30 * 60 # sec

require 'time'
require 'csv'
require 'optparse'
require 'logger'
require 'uri'
require_relative 'smart_device_spec.rb'

opt = OptionParser.new
options = {}
options['begin_time'] = Time.now.strftime( '%Y%m%d-%H%M%S' )
opt.banner = "Usage: #{File.basename($0)} input_http_csv_file"
opt.permute!( ARGV )

if ARGV.size == 1
  options['input_http_csv_file'] = ARGV[0]
else
  print opt.help
  exit
end

# Create dictionary data that linking YouTube ID and feed label  
class IdMappingDictionary
  @@dictionary = {}

  # Construct a new instance.
  # @note Dictinary is two type of private dictinary for each src IP address and Common dictionary.
  # @note Linked Parmanent ID, Temporary ID and Feed label.
  def initialize
    @dictionary = {}
    [:permanent_feed, :temporary_feed, :temporary_permanent].each do |type|
      @dictionary[ type ] = Hash.new{|hash, key| hash[key] = Array.new }
      @@dictionary[ type ] ||= Hash.new{|hash, key| hash[key] = Hash.new( 0 ) }
    end
  end

  # Register linked data of Parmanent ID, Temporary ID and Feed label from Youtube ID mapping.
  # Register in the dictiornary of Private Dictionary for each src IP address and Common Dictionary.
  # @param  [Time]   time               parsed time of request_begin
  # @param  [String] feed_label         feed label from request_path
  # @param  [String] youtube_id_mapping YouTube ID mapping data from HTTP Session
  def register_youtube_id_mapping( time, feed_label, youtube_id_mapping = '' )
    youtube_id_mapping.split(' ').each do |id_pair|
      next unless id_pair.include? ':'
      permanent_id, temporary_id = id_pair.split ':'
      @dictionary[ :permanent_feed ][ permanent_id ]  << [time, feed_label]
      @dictionary[ :temporary_feed ][ temporary_id ]  << [time, feed_label]
      @dictionary[ :temporary_permanent ][ temporary_id ]  << [time, permanent_id]
      @@dictionary[ :permanent_feed ][ permanent_id ][ feed_label ] += 1
      @@dictionary[ :temporary_feed ][ temporary_id ][ feed_label ] += 1
      @@dictionary[ :temporary_permanent ][ temporary_id ][ permanent_id ] += 1
    end
  end

  # Search ID or feed labe from Private Dictionary.
  # @param  [Symbol]  type  type of searching method
  # @param  [String]  key   key of dictionary data(Parmanent ID or Temporary ID)
  # @param  [Time]    time  parsed time of request_begin
  # @return [String]  Return result of searching(Feed label or Parmanent ID).
  def search_private_dictionary( type, key, time )
    @dictionary[ type ][ key ].sort_by!{|v| v[0]}
    searched = nil
    @dictionary[ type ][ key ].reverse_each do |dictionary_time, id_or_feed|
      next if dictionary_time > time
      break if time - dictionary_time > WATCH_TIMEOUT_THRESHOLD
      searched = id_or_feed
    end
    searched
  end

  # Search ID or feed labe from Common Dictionary.
  # @param  [Symbol]  type  type of searching method
  # @param  [String]  key   key of dictionary data(Parmanent ID or Temporary ID)
  # @return [String]  Return result of searching(Feed label or Parmanent ID).
  def search_common_dictionary( type, key )
    @@dictionary[ type ][ key ].empty? ? nil : @@dictionary[ type ][ key ].to_a.max_by{|v| v[1]}[0]
  end

  # Search ID or feed labe from Dictionaries.
  # @param  [Symbol]  type  type of searching method
  # @param  [String]  key   key of dictionary data(Parmanent ID or Temporary ID)
  # @param  [Time]    time  parsed time of request_begin
  # @return [String]  Return result of searching(Feed label or Parmanent ID).
  def search_dictionary( type, key, time )
    searched = search_private_dictionary( type, key, time )
    searched
  end

end

# Create YouTube State Transitions and Quality Info Data from HTTPsessions
class YouTubeSession
  include SmartDeviceSpec

  STATE_BEGIN = 'begin'
  STATE_EXIT  = 'exit'

  # Construct a new instance.
  # @param [Logger] logger log info
  def initialize(logger = nil)
    @id_mapping_dictionary = IdMappingDictionary.new
    @watches               = []
    @logger                = logger
    @smart_device_list     = []
  end

  # Register linked data of Parmanent ID, Temporary ID and Feed label from Youtube ID mapping.
  # @param  [Time]    time               parsed time of request_begin
  # @param  [String]  path               request_path from HTTP Session
  # @param  [String]  youtube_id_mapping YouTube ID mapping data from HTTP Session
  def register_youtube_id_mapping( time, path, youtube_id_mapping )
    return nil if /\/comments\?|\/events|\/channels|\/playlists\?|\/suggest/ =~ path
    return nil unless youtube_id_mapping and !youtube_id_mapping.empty?
    feed_label = (/\?/ =~ path ? $` : path).split(/\//).last
    feed_label = 'playlists' if /pl[0-9a-z_\-]+/i =~ feed_label
    raise 'parse failed in feed label extraction' unless feed_label
    @id_mapping_dictionary.register_youtube_id_mapping( time, feed_label, youtube_id_mapping )
  end

  # Resister YouTube watching datas to instance valiable.
  # @param  [Symbol] method         method of parse
  # @param  [Time]    time           parsed time of request_begin
  # @param  [String]  path           request_path from HTTP Session
  # @param  [String]  referer        request_referer from HTTP Session
  # @param  [String]  user_agent     request_user_agent from HTTP Session
  # @param  [Array]   quality_info   Quality info of YouTube Movies from HTTP Session 
  def register_watch( method, time, path, referer, user_agent, quality_info = nil )
    parsed_path = parse_path( method, path )
    case method
    when :watch
      if parsed_path
        if parsed_path.key?('v')
          permanent_id = parsed_path['v']
        elsif parsed_path.key?('vidoe_id')
          permanent_id = parsed_path['video_id']
        else
          permanent_id = nil
        end
        temporary_id = nil
        feed_label = categorize_watch_feed( parsed_path )
        application = nil
      else
        return
      end
    when :redirector, :content
      if temporary_id = parsed_path['id']
        permanent_id = nil
        if /gdata/ =~ parsed_path['app']
          feed_label = parsed_path['el']
          feed_label_source = feed_label ? :redirector : nil
        else
          feed_label = nil
          feed_label_source = nil
        end
        application = parsed_path['devKey']
      else
        return
      end
    when :embedded
      if permanent_id = parsed_path['docid']
        temporary_id = nil
        feed_label = parsed_path['el']
        feed_label_source = feed_label ? :embedded : nil
        application = parsed_path['devKey']
      else
        return
      end
    end
    @watches << {
      :time => time,
      :temporary_id => temporary_id,
      :permanent_id => permanent_id,
      :feed_label => feed_label,
      :feed_label_source => feed_label_source,
      :referer => categorize_referer( referer ),
      :referer_collapse => categorize_referer( referer, true ),
      :application => application,
      :watch_method => method,
      :os => categorize_os( user_agent ), 
      :display_class => categorize_display_class( user_agent ),
      :quality_info => quality_info
    }
  end

  # Parse request path. Create array of query.
  # @param  [Symbol]  method         method of parse
  # @param  [String]  path           request_path from HTTP Session
  # @return [Hash]    Return result of parsed request path.
  def parse_path( method, path )
    begin
      case method
      when :watch
        return parse_query( $' ) if /watch\?/ =~ path
      when :redirector, :content, :embedded
        if /playback\?/ =~ path
          return parse_query( $' )
        elsif /playback\// =~ path
          query_in_path, query = $'.split('?', 2)
          return parse_query( query ).merge( Hash[*query_in_path.split('/')] ) if query
          return Hash[*query_in_path.split('/')]
        end
      end
      {}
    rescue
      raise 'parse failed in parse_path()'
    end
  end

  # Parse query in request path. Decode form by URI library.
  # @param  [String]  query   query of request_path
  # @return [Hash]    Return result of decoded query by URI library.
  def parse_query( query )
    query.sub!(/&[a-z]*&/){|s| "&"}
    query.sub!(/watch\?/){|s| "watch%3F&"}
    query.sub!(/==/){|s| "%3D%3D"}
    query.sub!(/=&/){|s| "%3D&"}
    query.sub!(/&&/){|s| "%26&"}
    query.chomp!("&")
    return Hash[*URI.decode_www_form(query).flatten] if query
    {}
  end

  # Categorize referer from request referer of HTTP session.
  # @param  [String]  referer   request_referer from HTTP Session
  # @param  [Boolean] collapse  transition type is collapse(true) or expend(false)
  # @return [String]  Return parsed URI host address.
  def categorize_referer( referer, collapse = false )
    ret = nil
    return ret unless referer
    case referer
    when /\/t.co\//         then ret = 'Twitter'
    when /\/m.facebook.com/ then ret = 'Facebook'
    when /google/           then ret = 'Google'
    when /yahoo/            then ret = 'Yahoo'
    when /youtube/i         then return ret
    else
      ret = URI.parse( referer ).host
    end
    ret = 'externalsites' if collapse
    ret
  end

  # Categorize OS from request user-agent of HTTP session.
  # @param  [String]  user_agent     request_user_agent from HTTP Session
  # @return [String]  Return OS info of device.
  def categorize_os( user_agent )
    os = get_smart_device_spec( user_agent )[:os]
    os.nil? ? 'unknown' : os
  end

  # Categorize display class of device from request user-agent of HTTP session.
  # @param  [String]  user_agent     request_user_agent from HTTP Session
  # @return [String]  Return display class of device.
  def categorize_display_class( user_agent )
    display_class = get_smart_device_spec( user_agent )[:display_class]
    return display_class if display_class
    case user_agent
    when /Mac OS/           then return 'pc'
    else return 'unknown'
    end
  end

  # Categorize feed label from request path of HTTP session in watch method.
  # @param  [String]  path  request_path from HTTP Session
  # @return [Hash]    Return feed label from parsed request path.
  def categorize_watch_feed( path )
    if path.key?( 'feature' )
      case path['feature']
      when /youtu.be/ then return nil
      when /rel/      then return 'related'
      when /g-/       then return 'standard'
      when /share/
        return 'Facebook' if path.key?( 'fb_source' )
      else
        return path['feature']
      end
    elsif path.key?( 'preq' ) and path['preq'].include?( '&q=' )
      return 'videos'
    end
    nil
  end

  # Resolve states of watch. Search feed label from dictionary and referer.
  # @param  [Boolean] collapse  transition type is collapse(true) or expend(false)
  def resolve_states( collapse = false )
    @watches.sort_by!{|watch| watch[:time]}
    @watches.each do |watch|
      unless watch[:feed_label]
        watch[:permanent_id] = @id_mapping_dictionary.search_dictionary( :temporary_permanent, watch[:temporary_id], watch[:time] ) unless watch[:permanent_id]
        watch[:feed_label] = @id_mapping_dictionary.search_dictionary( :permanent_feed, watch[:permanent_id], watch[:time] ) if watch[:permanent_id]
        watch[:feed_label_source] = :permanent_id if watch[:feed_label]
        unless watch[:feed_label]
          watch[:feed_label] = @id_mapping_dictionary.search_dictionary( :temporary_feed, watch[:temporary_id], watch[:time] ) if watch[:temporary_id]
          watch[:feed_label_source] = :temporary_id if watch[:feed_label]
        end
      end
      if collapse && (/most_|top_|recently_featured|watch_on_mobile/ =~ watch[:feed_label])
        watch[:state] = 'initialfeed'
      elsif collapse
        watch[:state] = watch[:feed_label] || watch[:referer_collapse]
      else
        watch[:state] = watch[:feed_label] || watch[:referer]
      end
      @logger.debug( "state unknown, not fount from dictionary: watch:#{watch}" )  if @logger && !watch[:state]
    end
  end

  # Resolve transitions of state.
  # @param  [Boolean] collapse    transition type is collapse(true) or expend(false)
  # @return [Array]   Return result of resolved state transitions.
  def state_transitions( collapse = false )
    resolve_states( collapse )
    state_transitions_list = []
    state_transitions_list_tmp = []
    current_state = STATE_BEGIN
    prev_permanent_id = nil
    prev_temporary_id = nil
    prev_watch_time = nil
    @watches.each do |watch|
      next if watch[:watch_method] == :content
      if is_timeout_diff?(watch[:time], prev_watch_time)
        if (!prev_permanent_id and !prev_temporary_id) or
          (prev_permanent_id and prev_permanent_id != watch[:permanent_id]) or
          (prev_temporary_id and prev_temporary_id != watch[:temporary_id])
          state_transitions_list_tmp << [current_state, watch[:state]]
          current_state = watch[:state]
        end
      else
        state_transitions_list_tmp << [current_state, STATE_EXIT]
        state_transitions_list << state_transitions_list_tmp
        state_transitions_list_tmp = [[STATE_BEGIN, watch[:state]]]
        current_state = watch[:state]
      end
      prev_permanent_id = watch[:permanent_id]
      prev_temporary_id = watch[:temporary_id]
      prev_watch_time = watch[:time]
    end
    unless state_transitions_list_tmp.empty?
      state_transitions_list_tmp << [current_state, STATE_EXIT]
      state_transitions_list << state_transitions_list_tmp
    end
    state_transitions_list
  end

  # Get Quality info of watch.
  # @return [Array] Return extracted quality info from watches.
  def qualities()
    @watches.sort_by!{|watch| watch[:time]}
    ret = []
    @watches.each do |watch|
      next unless watch[:quality_info] and /video/ =~ watch[:quality_info]['response_content_type']
      ret << watch[:quality_info]
    end
    ret
  end

  # Get OS info of device.
  # @return [String]  Return OS info.
  def os()
    @watches.empty? ? 'unknown' : @watches.sort_by{|watch| watch[:time]}.first[:os]
  end

  # Get display class info of device.
  # @return [String]  Return display class info.
  def display_class()
    @watches.empty? ? 'unknown' : @watches.sort_by{|watch| watch[:time]}.first[:display_class]
  end

  # Check timeout threshold of the watch.
  # @return [Boolean]  Return result of cheked timeout.
  def is_timeout_diff?(time, prev_time)
    prev_time.nil? ? true : (time - prev_time) < WATCH_TIMEOUT_THRESHOLD  
  end

end

# for debugging
logger = Logger.new( File.basename(options['input_http_csv_file'], '.*') + '_log_' + options['begin_time'] + '.txt' )
logger.level = Logger::DEBUG

# read csv file and register youtube sessions
youtube_sessions = Hash.new{|hash, key| hash[key] = YouTubeSession.new(logger) }
CSV.open( options['input_http_csv_file'], 'r', {:headers => :first_row, :encoding => Encoding::ASCII_8BIT} ).each do |l|
  begin
    values = l.to_hash

    # target only youtube related sessions
    next unless values['request_path'] and values['request_host'] and values['request_host'].include? 'youtube'

    # standardize inputs
    request_begin = Time.parse( values['request_begin'] )

    # for quality analysis
    quality_info = {
      # primitive values
      'response_begin' => response_begin = Time.parse( values['response_begin'] ),
      'response_end' => response_end = Time.parse( values['response_end'] ),
      'response_size' => response_size = values['response_size'].to_i,
      'response_actual_size' => response_actual_size = values['response_actual_size'].to_i,
      'response_content_type' => values['response_content_type'],
      'response_content_range' => values['response_content_range'],
      'tcp_close_state' => values['tcp_close_state'],
      'tcp_download_unexpected' => tcp_download_unexpected = values['tcp_download_unexpected'].to_i,
      'video_container' => values['video_container'],
      'video_major_brand' => values['video_major_brand'],
      'video_duration' => values['video_duration'].to_i,
      'video_bitrate' => values['video_bitrate'].to_i,
      'audio_bitrate' => values['audio_bitrate'].to_i,
      # calculated values
      'response_throughput' => response_actual_size / (response_end - response_begin),
      'download_complete' => response_size == response_actual_size,
      'broken' => tcp_download_unexpected > 0
    }

    # for debugging
    debug_info = {
      'request_begin' => request_begin,
      'request_path' => values['request_path'],
      'youtube_id_mapping' => values['youtube_id_mapping'],
      'request_referer' => values['request_referer'],
      'user_agent' => (values['request_user_agent'] ? values['request_user_agent'].gsub(/ |gzip/, '') : 'unknown'),
      'tcp_hash' => values['tcp_hash']
    }

    begin
      case values['request_host']

      # register the mapping table with feed label
      when /gdata/
        # skip if the http session does not include feed label
        next unless values['response_content_type'] and /application\/atom\+xml.*type=feed/i =~ values['response_content_type']
        # registration
        youtube_sessions[ values['src_ipaddr'] ].register_youtube_id_mapping( request_begin, values['request_path'], values['youtube_id_mapping'].to_s )

      # register the redirector
      when /redirector/
        youtube_sessions[ values['src_ipaddr'] ].register_watch( :redirector, request_begin, values['request_path'], values['request_referer'], values['request_user_agent'] )

      # register the content download
      when /\.c\.youtube\.com/
        youtube_sessions[ values['src_ipaddr'] ].register_watch( :content, request_begin, values['request_path'], values['request_referer'], values['request_user_agent'], quality_info )

      # register the embedded watch
      when /s\.youtube\.com/
        youtube_sessions[ values['src_ipaddr'] ].register_watch( :embedded, request_begin, values['request_path'], values['request_referer'], values['request_user_agent'] )

      # register the video watch
      else
        # skip if the http session is not a watch request
        next unless values['request_path'].include?( '/watch?' )
        youtube_sessions[ values['src_ipaddr'] ].register_watch( :watch, request_begin, values['request_path'], values['request_referer'], values['request_user_agent'] )
      end
    rescue => e
      logger.debug( "#{e.message}: #{debug_info.inspect}" )
    end

  rescue => e
    logger.error( e.message )
    e.backtrace.each{|b| @logger.error b}
    logger.error( l.inspect )
  end
end

# statistical processing
state_transitions_graph = Hash.new{|hash_from, key_from| hash_from[key_from] = Hash.new{|hash_to, key_to| hash_to[key_to] = Hash.new(0)}}
appeared_states = Hash.new{|hash, key| hash[key] = Hash.new(0)}
quality_abandon = Hash.new{|hash, key| hash[key] = []}
n_sessions = Hash.new{|hash, key| hash[key] = []}
duration = Hash.new{|hash, key| hash[key] = []}

# generate state transitions diagrams
video_info_items = ['video_container', 'video_major_brand', 'video_duration', 'video_bitrate', 'audio_bitrate']
youtube_sessions.each do |src_ipaddr, session|
  video_info = {}
  [session.os, 'all'].each do |os|
    [session.display_class, 'all'].each do |display_class|
      ['expand', 'collapse'].each do |external_site_style|
        next if (state_transitions_list = session.state_transitions( external_site_style == 'collapse' )).empty?
        state_transitions_list.each_with_index do |state_transitions, nth_sessions|
          portal = state_transitions.first[1]
          [portal, 'all'].each do |portal_feed|
            portal_feed ||= 'unknown'
            category = [os, display_class, external_site_style, portal_feed].join('_')
            state_transitions.each do |from, to|
              from ||= 'unknown'
              to ||= 'unknown'
              state_transitions_graph[category][from][to] += 1
              appeared_states[category][from] = true
              appeared_states[category][to] = true
            end
            n_sessions[category] << [src_ipaddr, nth_sessions, state_transitions.size - 1]

            begin_time = nil
            end_time = nil
            session.qualities.each do |quality|
              begin_time ||= quality['response_begin']
              end_time = quality['response_end']
              quality_dup = quality.dup
              if instance_length = ( quality_dup['response_content_range'] ? quality_dup['response_content_range'].partition('/')[2].to_i : nil )
                video_info[instance_length] ||= {}
                video_info_items.each do |i|
                  video_info[instance_length][i] = quality_dup[i] unless video_info[instance_length][i] and video_info[instance_length][i] != 0
                  quality_dup[i] = video_info[instance_length][i]
                end
              end
              if !quality_abandon[category].empty? and
                quality_abandon[category].last['src_ipaddr'] == src_ipaddr and
                quality_dup['response_begin'] - quality_abandon[category].last['response_begin'] < ABANDON_THRESHOLD
                quality_abandon[category].last['abandon'] = false
              end
              quality_dup['src_ipaddr'] = src_ipaddr
              quality_dup['abandon'] = true
              quality_dup['portal'] = portal
              quality_abandon[category] << quality_dup
            end
            duration[category] << [begin_time, end_time, end_time - begin_time]
          end
        end
      end
    end
  end
end

appeared_states.each do |category, states|
  # generate header fields
  states = states.keys.sort
  states -= [YouTubeSession::STATE_BEGIN, YouTubeSession::STATE_EXIT]
  states.unshift YouTubeSession::STATE_BEGIN
  states.push YouTubeSession::STATE_EXIT
  # write out
  outfile = CSV.open(File.basename(options['input_http_csv_file'], '.*') + '_transitions_' + category + '_' + options['begin_time'] + '.csv', 'w')
  outfile << [''] + states
  states.each do |from|
    outfile << [from] + states.map{|to| state_transitions_graph[category][from][to]}
  end
end

quality_abandon.each do |category, qas|
  outfile = CSV.open(File.basename(options['input_http_csv_file'], '.*') + '_qualityabandon_' + category + '_' + options['begin_time'] + '.csv', 'w')
  output_items = [
  'src_ipaddr', 'abandon', 'portal',
  'response_begin', 'response_end',
  'response_size', 'response_actual_size',
  'response_content_type', 'response_content_range',
  'tcp_close_state', 'tcp_download_unexpected',
  'video_container', 'video_major_brand', 'video_duration',
  'video_bitrate', 'audio_bitrate',
  'response_throughput', 'download_complete', 'broken'
  ]
  outfile << output_items
  qas.each do |qa|
    outfile << output_items.map{|x| qa[x]}
  end
end

n_sessions.each do |category, sessions|
  outfile = CSV.open(File.basename(options['input_http_csv_file'], '.*') + '_nsessions_' + category + '_' + options['begin_time'] + '.csv', 'w')
  outfile << ['src_ipaddr', 'sequence_number', 'n_sessions']
  sessions.each do |session|
    outfile << session
  end
end

duration.each do |category, durations|
  outfile = CSV.open(File.basename(options['input_http_csv_file'], '.*') + '_durations_' + category + '_' + options['begin_time'] + '.csv', 'w')
  outfile << ['begin_time', 'end_time', 'duratoin']
  durations.each do |duration|
    outfile << duration
  end
end
