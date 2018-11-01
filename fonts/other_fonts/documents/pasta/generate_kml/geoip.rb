# -*- encoding: UTF-8 -*-
#
# ip_listファイルに記載されているIPアドレスから
# geoipライブラリを利用して、経度、緯度、地域を割り出す＠日本限定
# 割り出す精度は、GeoIPに依存する
# geoipにて地域が割り出せない場合、地域は"UNKNWON"として出力される
#

require 'rubygems'
require 'digest/md5'
require 'geoip'
require 'optparse'
require 'csv'

GEOIP_REGION_TO_JAPAN_PREFECTURE = {
  JP01: 23, JP02:  5, JP03:  2, JP04: 12, JP05: 38, JP06: 18,
  JP07: 40, JP08:  7, JP09: 21, JP10: 10, JP11: 34, JP12:  1,
  JP13: 28, JP14:  8, JP15: 17, JP16:  3, JP17: 37, JP18: 46,
  JP19: 14, JP20: 39, JP21: 43, JP22: 26, JP23: 24, JP24:  4,
  JP25: 45, JP26: 20, JP27: 42, JP28: 29, JP29: 15, JP30: 44,
  JP31: 33, JP32: 27, JP33: 41, JP34: 11, JP35: 25, JP36: 32,
  JP37: 22, JP38:  9, JP39: 36, JP40: 13, JP41: 31, JP42: 16,
  JP43: 30, JP44:  6, JP45: 35, JP46: 19, JP47: 47,
}

PREFECTURES = {
  1 => '北海道',  2 => '青森県',  3 => '岩手県',  4 => '宮城県',  5 => '秋田県',  6 => '山形県',
  7 => '福島県',  8 => '茨城県',  9 => '栃木県', 10 => '群馬県', 11 => '埼玉県', 12 => '千葉県',
  13 => '東京都', 14 => '神奈川県', 15 => '新潟県', 16 => '富山県', 17 => '石川県', 18 => '福井県',
  19 => '山梨県', 20 => '長野県', 21 => '岐阜県', 22 => '静岡県', 23 => '愛知県', 24 => '三重県',
  25 => '滋賀県', 26 => '京都府', 27 => '大阪府', 28 => '兵庫県', 29 => '奈良県', 30 => '和歌山県',
  31 => '鳥取県', 32 => '島根県', 33 => '岡山県', 34 => '広島県', 35 => '山口県', 36 => '徳島県',
  37 => '香川県', 38 => '愛媛県', 39 => '高知県', 40 => '福岡県', 41 => '佐賀県', 42 => '長崎県',
  43 => '熊本県', 44 => '大分県', 45 => '宮崎県', 46 => '鹿児島県', 47 => '沖縄県',
}

class GeoIP_Chk

  def mk_geoip(ip_prs)
	ip_prs.logger(1, "=== mk_geoip start ===")
	
	line_nums = 0
	iplist_tmp = "./tmp_log/ip_list"
	pcapinfo_tmp = "./tmp_log/pcapinfo_list"
	
	geo_csv = "#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}_geo_thrpt.csv"
		
	options = {
		dat_path: '/usr/share/GeoIP/GeoLiteCity.dat'
	}
	OptionParser.new do |opt|
		opt.on('-f'){|v| options[:dat_path] = v }
	end

	unless File.exists? options[:dat_path]
		ip_prs.logger(4, "No such file: #{options[:dat_path]}")
		ip_prs.logger(4, "exit")
	 	exit
	end

	arr = ("a".."z").to_a + ("0".."9").to_a + ("A".."Z").to_a + ['.', '/']
	salt = ""
	2.times { salt += arr[rand(arr.length)] }

	geo = GeoIP.new(options[:dat_path])
	
	begin
	 geocsv = CSV.open(geo_csv, "w:Shift_JIS")
	 geocsv << ["Begin_at", "Begin_usec", "End_at", "End_usec", "IpAddress", "src macaddr", "dst macaddr", "CountryName", "CityName", "Latitude", "Longitude", "Throughput", "TotalPackets", "TotalBytes"]
	 geocsv.close
	rescue => ex
	 ip_prs.logger(4, "CVS write title error: #{ex.message}")
	 ip_prs.logger(4, "exit")
	 exit
	end

	begin
	 ip_or_hostname = open(iplist_tmp, "r")
	 ip_prs.logger(1, "open ip list file")
	rescue => ex
	 ip_prs.logger(4, "ip list read error: #{ex.message}")
	 ip_prs.logger(4, "exit")
	 exit
	end

	begin
	 pcap_info = open(pcapinfo_tmp, "r")
	 ip_prs.logger(1, "open pcap info file")
	rescue => ex
	 ip_prs.logger(4, "pcap info file read error: #{ex.message}")
	 ip_prs.logger(4, "exit")
	 exit
	end

	# pcapファイル解析結果を取得
	CSV.foreach(pcap_info) do |pinfo_csv|
		# 調査対象IPアドレス取得
		ip_addrs = ip_or_hostname.gets.chomp!
		ip_prs.logger(0, "read line@#{line_nums} ip list, ip addr: #{ip_addrs}")

		# IPアドレス調査 by GeoIP
		geoip = geo.city(ip_addrs)
		begin
		 key = geoip.country_code2 + geoip.region_name
 		rescue => ex
		 ip_prs.logger(3, "can't resolv ip address by GeoIP: #{ip_addrs} #{ex.message}")
		end
		
		crypt_ip = Digest::MD5.hexdigest(ip_addrs + salt)
		
		src_mac = pinfo_csv[0]
		dst_mac = pinfo_csv[1]

		pac_num = pinfo_csv[2].to_i
		pac_siz = pinfo_csv[3].to_i

		bgn_time = Time.at(pinfo_csv[4].to_f).strftime("%Y-%m-%d %H:%M:%S")
		bgn_utime = Time.at(pinfo_csv[4].to_f).usec

		if pinfo_csv[5].to_f > 0 and pinfo_csv[4].to_f != pinfo_csv[5].to_f
			end_time = Time.at(pinfo_csv[5].to_f).strftime("%Y-%m-%d %H:%M:%S")
			end_utime = Time.at(pinfo_csv[5].to_f).usec
			thrpt = pinfo_csv[6].to_f
		else
			end_time = "UNKNOWN"
			end_utime = "UNKNOWN"
			thrpt = "UNKNOWN"
		end

		if geoip != nil and prefecture_code = GEOIP_REGION_TO_JAPAN_PREFECTURE[key.to_sym]
			country_name = PREFECTURES[prefecture_code]
			city_name = geoip.city_name
			latitude = geoip.latitude
			longitude = geoip.longitude
		else
			country_name = "UNKNOWN"
			city_name = "UNKNOWN"
			latitude = "UNKNOWN"
			longitude = "UNKNOWN"
		end
		
		# 最終結果CSV出力
		# 日本以外はUNKNOWN出力
		begin
		 geocsv = CSV.open(geo_csv, "a:Shift_JIS")
		 geocsv << [bgn_time, bgn_utime, end_time, end_utime, crypt_ip, src_mac, dst_mac, country_name, city_name, latitude, longitude, thrpt, pac_num, pac_siz]
		 geocsv.close
		rescue => ex
		 ip_prs.logger(4, "CVS file write error: #{ex.message}")
		 ip_prs.logger(4, "exit")
		 exit
		end
		line_nums += 1
	end
	
	ip_or_hostname.close
	ip_prs.logger(1, "=== mk_geoip finish ===")
  	
	rescue => ex
	 ip_prs.logger(4, "An error occurred at mk_geoip: #{ex.message}")
 	 ip_prs.logger(4, "#{$@}")
 	 ip_prs.logger(4, "exit")
	 exit	 
  end
end
