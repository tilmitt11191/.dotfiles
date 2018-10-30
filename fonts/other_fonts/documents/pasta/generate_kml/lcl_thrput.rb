#!/usr/bin/env ruby

# 
# pcapファイルからIPアドレスの取得＠ip_list
# 取得したIPアドレスから、経度、緯度、地域の割り出す＠geoip
#

require 'fileutils'
tmplog_dir = "tmp_log"
FileUtils.mkdir(tmplog_dir) unless FileTest.exist?(tmplog_dir)

require "#{File.dirname(__FILE__)}/ip_list.rb"
require "#{File.dirname(__FILE__)}/geoip.rb"

if ARGV.empty?
	puts "*.pcap file set plz."
	exit
end

ip_prs = IP_Prs.new
geoip_chk = GeoIP_Chk.new()

while arg = ARGV.shift
	ip_prs.mk_iplist(arg)
end

geoip_chk.mk_geoip(ip_prs)

begin
	File.rename("./tmp_log/ip_list", "./tmp_log/#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}-ip_list")
	File.rename("./tmp_log/pcapinfo_list", "./tmp_log/#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}-pcapinfo_list")
rescue => ex
	ip_prs.logger(4, "An error occurred at lcl_thrput: #{ex.message}")
 	ip_prs.logger(4, "#{$@}")
 	ip_prs.logger(4, "exit")
	exit	 
end
