#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

STDOUT.sync = true

require 'pcap'
require 'time'
require 'logger'
require 'csv'
require 'ipaddr'

require 'optparse'
opt = OptionParser.new
options = {}

# option parser
options[:begin_time]                     = Time.now
options[:outfile_prefix]                 = ''
options[:timeout]                        = 16
options[:ippush_ports]                   = [5000, 5223, 5228]
options[:version]                        = '$Id: count_ip_pushes.rb 659 2013-05-13 03:00:20Z fukumoto $'

opt.banner = "Usage: #{File.basename($0)} [options] pcapfiles"
opt.on( '-h'            , '--help'                                  , 'show help' ) { print opt.help; exit }
opt.on( '-l prefix'     , '--file-prefix-label prefix'     , String , 'specify file prefix' ) {|v| options[:outfile_prefix] = v + '_' }
opt.on( '-p ports'      , '--ip-push-ports ports'          , Array  , 'set source ports for IP pushes in comma separated format' ) {|v| options[:ippush_ports] = v.map{|m| m.to_i} }
opt.on( '-t time'       , '--timeout time'                 , Integer, 'set timeout in sec' ) {|v| options[:timeout] = v.to_i }
opt.on( '-i file'       , '--ip-push-file file'            , Integer, 'set IP address file for IP pushes' ) {|v| options[:ippush_file] = v }
opt.on( '-s file'       , '--service-file file'            , Integer, 'set IP address file for services' ) {|v| options[:service_file] = v }
opt.on(                   '--version'                               , 'show version' ) { puts options[:version]; exit }
opt.permute!( ARGV )

if ARGV.empty?
  print opt.help
  exit
else
  options[:infiles] = ARGV
end


class IPPush
  def initialize( ippush_timeout = @@ippush_timeout )
    @@ippush_timeout = ippush_timeout
    @first_packet = nil
    @last_packet  = nil
    @n_packets    = 0
    @size         = 0
  end

  def receive( pkt )
    @first_packet ||= pkt
    @last_packet = pkt
    @n_packets += 1
    @size += pkt.tcp_data_len
  end

  def closed?( time )
    time - ( @last_packet ? @last_packet.time : Time.at(0) ) > @@ippush_timeout
  end

  attr_reader :first_packet
  attr_reader :last_packet
  attr_reader :n_packets
  attr_reader :size
end

def get_filename( type, options )
  options[:outfile_prefix] + type + '_' + options[:begin_time].strftime( "%Y%m%d-%H%M%S" ) + '.' + (['debug', 'log'].include?( type ) ? 'txt' : 'csv' )
end

logger = Logger.new( get_filename( 'log', options ) )
logger.level = Logger::INFO

# write options
logger.info( "ruby_version = #{RUBY_VERSION}" )
logger.info( "ruby_release_date = #{RUBY_RELEASE_DATE}" )
logger.info( "ruby_patch_level = #{RUBY_PATCHLEVEL}" )
logger.info( "ruby_platform = #{RUBY_PLATFORM}" )
logger.info( "pid = #{Process.pid}" )
logger.info( "uid = #{Process.uid}" )
logger.info( "gid = #{Process.gid}" )
options.each do |k, v|
  logger.info( "options: #{k.to_s} = #{v.inspect}" )
end

# load ipaddr files
logger.info( "reading IP addr file for IP pushes" )
ippush_ipaddr = {}
File.open( options[:ippush_file] || 'line_ippush.txt' ){|file| file.each{|ipaddr| ippush_ipaddr[IPAddr.new(ipaddr.chomp)] = true} }
logger.info( "ippush_ipaddr = #{ippush_ipaddr}" )

logger.info( "reading IP addr file for services" )
service_ipaddr = {}
File.open( options[:service_file] || 'line.txt' ){|file| file.each{|ipaddr| service_ipaddr[IPAddr.new(ipaddr.chomp)] = true} }
logger.info( "service_ipaddr = #{service_ipaddr}" )


IP_ADDR_RANGE = [
  [IPAddr.new( '10.90.0.0/19' )  , 'pcon/gj normal'],
  [IPAddr.new( '10.42.128.0/19' ), 'pcon/gj heavy'],
  [IPAddr.new( '10.114.0.0/19' ) , 'gbl normal'],
  [IPAddr.new( '10.77.0.0/19' )  , 'orz normal'],
  [IPAddr.new( '10.43.128.0/19' ), 'gbl/orz heavy'],
  [IPAddr.new( '10.14.0.0/18' )  , 'unipkc normal'],
  [IPAddr.new( '10.44.128.0/19' ), 'unipkc  heavy'],
  [IPAddr.new( '10.80.0.0/17' )  , 'uno mix'],
  [IPAddr.new( '10.80.128.0/17' ), 'unij mix']
]
def get_ip_addr_range ip_addr
  IP_ADDR_RANGE.each do |range|
    return range[1] if range[0].include? ip_addr
  end
  return 'unknown'
end


ippushes = {}
stats = {}
serviced_ipaddr = {}
last_timeout_check = nil
options[:infiles].uniq.sort.each_with_index do |file, index|
  logger.info "analysing #{file} (#{index + 1}/#{options[:infiles].size})"
  begin
    cap = Pcap::Capture.open_offline( file )
  rescue => e
    logger.fatal( "failed to open a pcap file: #{file}" )
    logger.fatal( "#{e.message}" )
    e.backtrace.each{|b| logger.fatal( "#{b}" ) }
    next
  end
  cap.each do |pkt|
    # timeout check
    last_timeout_check = pkt.time unless last_timeout_check
    if pkt.time - last_timeout_check > 1.0
      ippushes.each do |ippush_key, ippush|
        if ippush.closed? pkt.time
          range = get_ip_addr_range ippush_key[1]
          sport = ippush_key[2]
          stats[ range ] ||= {}
          stats[ range ][ sport ] ||= { :n_pushes => 0, :n_packets => 0, :size => 0, :dst_ipaddr => {} }
          stats[ range ][ sport ][ :n_pushes ] += 1
          stats[ range ][ sport ][ :n_packets ] += ippush.n_packets
          stats[ range ][ sport ][ :size ] += ippush.size
          stats[ range ][ sport ][ :dst_ipaddr ][ ippush_key[1] ] = true
          ippushes.delete ippush_key
        end
      end
      last_timeout_check = pkt.time
    end
    # count number of users
    if pkt.tcp? and pkt.tcp_syn? and !pkt.tcp_ack?
      ip_src = IPAddr.new( pkt.ip_src.to_s )
      ip_dst = IPAddr.new( pkt.ip_dst.to_s )
      range = get_ip_addr_range ip_src
      serviced_ipaddr[ range ] ||= {}
      serviced_ipaddr[ range ][ 'all' ] ||= {}
      serviced_ipaddr[ range ][ 'all' ][ ip_src ] = true
      if service_ipaddr[ ip_dst ]
        serviced_ipaddr[ range ][ 'serviced' ] ||= {}
        serviced_ipaddr[ range ][ 'serviced' ][ ip_src ] = true
      end
    end
    # store new packet
    if pkt.tcp? and !pkt.tcp_syn? and !pkt.tcp_rst? and !pkt.tcp_fin? and
      pkt.tcp_data_len >= 64 and options[ :ippush_ports ].include?( pkt.sport )
      ip_src = IPAddr.new( pkt.ip_src.to_s )
      ip_dst = IPAddr.new( pkt.ip_dst.to_s )
      if ippush_ipaddr[ ip_src ]
        key = [ ip_src, ip_dst, pkt.sport, pkt.dport ]
        ippushes[ key ] ||= IPPush.new( options[ :timeout ] )
        ippushes[ key ].receive pkt
      end
    end
  end
  cap.close
end
logger.info( "completed analysis of pcap files" )

# write out
logger.info( "writing out stats" )
header = %w!range src_port n_dst_ipaddr n_pushes, n_packets size!
outfile = CSV.open( get_filename( 'ippush', options ), 'w' )
  outfile << header
stats.each do |range, v|
  v.each do |sport, w|
    outfile << [ range, sport, w[:dst_ipaddr].size, w[:n_pushes], w[:n_packets], w[:size] ]
  end
end

logger.info( "writing out number of users" )
header = %w!range serviced n_users!
outfile = CSV.open( get_filename( 'users', options ), 'w' )
  outfile << header
serviced_ipaddr.each do |range, v|
  v.each do |serviced, w|
    outfile << [ range, serviced, w.size ]
  end
end

logger.info( "successful completion of the whole process" )
