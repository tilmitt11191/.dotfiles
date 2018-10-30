#!/usr/bin/env ruby
require 'optparse'
require 'time'

options = {}
CENV = '/usr/bin/env'
TCPDUMP = "#{CENV} tcpdump"
MERGECAP = "#{CENV} mergecap"
MKDIR = "#{CENV} mkdir"

options['time_suffix']  = Time.now.strftime("%Y%m%d%H%M%S")
options['outdir']       = './outdir' + '_' + options['time_suffix']
options['ports']        = []
options['ipaddrs']      = []
options['tcpudp']       = []
options['disable_vlan'] = false
options['enable_merge'] = false

opt = OptionParser.new
begin
  opt.on('-d output_dir'  , '--output-dir output_dir'    , String, 'output directory'                    ){|v| options['outdir']  = v }
  opt.on('-p ports'       , '--ports ports'              , String, 'screen pcap(s) with the ports'       ){|v| options['ports']           = v.split(',').map{|w| w.to_i }}
  opt.on('-i ip_addresses', '--ip-addresses ip_addresses', String, 'screen pcap(s) with the ip-addresses'){|v| options['ipaddrs']         = v.split(',').map{|w| w.strip }}
  opt.on('-t ip_addresses', '--tcpudp TCP/UDP'           , String, 'screen pcap(s) with TCP/UDP'         ){|v| options['tcpudp']          = v.split(',').map{|w| w.strip }}
  opt.on('-V'             , '--vlan-disable'                     , 'VLAN disable'                        ){    options['disable_vlan']    = true }
  opt.on('-m'             , '--mergepcap-enable'                 , 'enable pcap-merge'                   ){    options['enable_merge']    = true }
  opt.permute!(ARGV)
rescue
  errmsg =<<EOS
example: ruby #{__FILE__} [-d outdir] [-p 80,443] [-i 10.0.0.1,192.168.0.0/24] [-t tcp] [-V] [-m]
EOS
  puts errmsg
  exit
end

p options
files = ARGV

unless File.exist? options['outdir']
  `#{MKDIR} -p #{options['outdir']}`
else
  puts "#{options['outdir']} was existed, abort "
  exit
end

files.each{|fn|
  outfn = "#{options['outdir']}/#{File.basename(fn)}"
  puts "#{fn} -> #{outfn}"
  # set TCP/UDP filter
  tcpudp_filter = String.new
  case options['tcpudp'].size
  when 0
    tcpudp_filter = nil
  when 1
    tcpudp_filter = options['tcpudp'][0]
  else
    tcpudp_filter = "\\( #{options['tcpudp'].join(' or ')} \\)"
  end

  # set ipaddr filter
  ip_filter = String.new
  case options['ipaddrs'].size
  when 0
    ip_filter = nil
  when 1
    ip_filter = "dst or src net #{options['ipaddrs'][0]}"
  else
    ip_filter = "\\( dst or src net #{options['ipaddrs'].join(' or ')} \\)"
  end

  # set port filter
  port_filter = String.new
  case options['ports'].size
  when 0
    port_filter = nil
  when 1
    port_filter = "port #{options['ports'][0]}"
  else
    port_filter = "\\( port #{options['ports'].join(' or ')} \\)"
  end

  # set vlan
  if options['disable_vlan']
    filter = []
  else
    filter = ['vlan']
  end

  filter << tcpudp_filter if tcpudp_filter
  filter << ip_filter if ip_filter
  filter << port_filter if port_filter

  cmd = "#{TCPDUMP} -r #{fn} -n -s 65535 -w #{outfn} #{filter.join(' and ')}"
  `#{cmd}`
}

if options['enable_merge']
  cmd = "#{MERGECAP} -s 65535 -w #{options['outdir']}/merged.pcap #{options['outdir']}/*.pcap"
  puts cmd
  `#{cmd}`
end
