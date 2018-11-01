# 
# pcapファイルを解析し、src macaddr, dst macaddr, pc num, pac size, start time, end time、throughputを取得する
#

require 'pcap'
require 'logger'
				
class IP_Prs
	@@proc_flg = 0
	if @@proc_flg == 0
	 	# pcap_info: "pcap ipaddr=>[src macaddr, dst macaddr, pc num, pac size, start time, end time、throughput]"
		@@pcap_info = Hash.new { |hash,key| hash[key] = [] }
		@@pcap_bkup = Hash::new
	end
 	
  def initialize
	@log = Logger.new("./tmp_log/#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}.log")
	@log.level = Logger::DEBUG
  end

  def logger(log_lv, msg)

	case log_lv
	when 0 #DEBUG
		@log.debug(msg)
	when 1 #INFO
		@log.info(msg)
	when 2 #WARN
		@log.warn(msg)
	when 3 #ERROR
		@log.error(msg)
	when 4 #FATAL
		@log.fatal(msg)
	end
  end


  def arrng_pinfo(packet)
	if @start_time == nil
		logger(0, "arrange pinfo")
		@start_time = packet.time.to_f
		@@pcap_bkup["#{packet.ip_dst}"] = packet.time.to_f
	end

	prog_time = packet.time.to_f
    
	# 変化のない情報は、ファイルに出力しハッシュテーブルから削除する
	if (prog_time - @start_time) >= 1
	
		@@pcap_bkup.keys.each{ |pcap_key|
		  if @@pcap_info["#{pcap_key}"][5].to_f > 0
			diff = @@pcap_info["#{pcap_key}"][5].to_f - @@pcap_bkup["#{pcap_key}"].to_f
			if diff == 0
				# pcap info file create
				begin
				 pinfo_list = open(@pcapinfo_tmp, "a")
				 pinfo_list.puts(@@pcap_info["#{pcap_key}"].join(","))
				 pinfo_list.close
				rescue => ex
				 logger(4, "pinfo list create error: #{ex.message}")
		 	 	 logger(4, "exit")
				 exit
				end

				# ip list file create
				begin
				 open(@iplist_tmp, "a"){|ip_list| ip_list.write("#{pcap_key}\n");ip_list.close}
				rescue => ex
				 logger(4, "ip list create error; #{ex.message}")
			 	 logger(4, "exit")
				 exit
				end

				@@pcap_info.delete("#{pcap_key}"){ |key|
					logger(4, "no such key(#{key}) in pcap info")
				 	logger(4, "exit")
					exit
				}
				logger(0, "file out and removed no change info: #{pcap_key}")				
			end
		  end
		}
		@start_time = packet.time.to_f
		
		@@pcap_bkup.clear
		@@pcap_info.each{ |pinfo_key, pinfo_val|
			@@pcap_bkup["#{pinfo_key}"] = pinfo_val[5]
		}
	end
  end
	
  def mk_new_pinfo(packet)	
	# src/dst MACアドレスの取得
	src_macaddr = packet.ethernet_headers[0].src_mac
	dst_macaddr = packet.ethernet_headers[0].dst_mac
  
	@@pcap_info["#{packet.ip_dst}"] << src_macaddr			#0: src mac address
	@@pcap_info["#{packet.ip_dst}"] << dst_macaddr			#1: dst mac address
	@@pcap_info["#{packet.ip_dst}"] << 1					#2: pac num
	@@pcap_info["#{packet.ip_dst}"] << packet.size			#3: pac size
	@@pcap_info["#{packet.ip_dst}"] << packet.time.to_f		#4: start time
 	@@pcap_info["#{packet.ip_dst}"] << nil					#5: end time
 	@@pcap_info["#{packet.ip_dst}"] << nil					#6: throughput
 	
	rescue => ex
	 logger(4, "An error occurred at mk_new_pinfo: #{ex.message}")  
  end

  def mk_iplist( pcap_file)
	logger(1, "=== mk_iplist start ===")
	logger(1, "parse pcap file is #{pcap_file}")
	
 	@pcapinfo_tmp = "./tmp_log/pcapinfo_list"
	@iplist_tmp = "./tmp_log/ip_list"

	if @@proc_flg == 0
	 begin
 	 	open(@pcapinfo_tmp, "w")
 	 	open(@iplist_tmp, "w")
	 	@@proc_flg = 1
	 rescue => ex
	 	logger(4, "can't open/create file: #{ex.message}")
	 	logger(4, "exit")
	 	exit
	 end
	end

  	begin
	 cap = Pcap::Capture.open_offline(pcap_file)
	 logger(0, "#{pcap_file} opened")
	rescue =>ex
	 logger(4, "pcap file open error: #{pcap_file} #{ex.message}")
 	 logger(4, "exit")
 	 exit
	end
	
	# pcapファイル解析開始
	cap.setfilter("ip")
	cap.loop do |pkt|
	 if pkt.ip? and pkt.tcp?
		if @@pcap_info.key?("#{pkt.ip_dst}") == false
			mk_new_pinfo(pkt)

		elsif @@pcap_info["#{pkt.ip_dst}"][5].to_i > 0 and (pkt.time.to_f - @@pcap_info["#{pkt.ip_dst}"][5].to_f) >= 1
			logger(0, "1sec over #{pkt.ip_dst} from " << @@pcap_info["#{pkt.ip_dst}"][5].to_s << " to #{pkt.time.to_f}")
			
			# パケット終了-開始までが1sec以上ある場合、別セッションとして取得するため
			# それまでの結果を一度ファイルに出力する

			# pcap info file create
			begin
			 pinfo_list = open(@pcapinfo_tmp, "a")
			 pinfo_list.puts(@@pcap_info["#{pkt.ip_dst}"].join(","))
			 pinfo_list.close
			rescue => ex
			 logger(4, "pinfo list create error: #{ex.message}")
	 	 	 logger(4, "exit")
			 exit
			end

			# ip list file create
			begin
			 open(@iplist_tmp, "a"){|ip_list| ip_list.write("#{pkt.ip_dst}\n");ip_list.close}
			rescue => ex
			 logger(4, "ip list create error; #{ex.message}")
		 	 logger(4, "exit")
			 exit
			end

			@@pcap_info.delete("#{pkt.ip_dst}"){|key|			
				logger(4, "no such key(#{key}) in pcap info")
			 	logger(4, "exit")
				exit
			}

			logger(0, "delete and create new key @#{pkt.ip_dst}")

			# 再度ハッシュ生成
			mk_new_pinfo(pkt)
		else
			@@pcap_info["#{pkt.ip_dst}"][2] += 1
			@@pcap_info["#{pkt.ip_dst}"][3] = @@pcap_info["#{pkt.ip_dst}"][3].to_i + pkt.size
			@@pcap_info["#{pkt.ip_dst}"][5] = pkt.time.to_f	#5: end time
			@@pcap_info["#{pkt.ip_dst}"][6] = @@pcap_info["#{pkt.ip_dst}"][3].to_i*8/ (@@pcap_info["#{pkt.ip_dst}"][5].to_f - @@pcap_info["#{pkt.ip_dst}"][4].to_f)
		end
	  # ハッシュ内容を見直す
	  arrng_pinfo(pkt)
	  
	 end
	end
	cap.close
	logger(0, "cap file closed. pcap_info size: " << @@pcap_info.size.to_s )

	# 複数pcapファイルを入力とした場合、出力は最後にまとめて行う
	if ARGV.size == 0
		# ip list file create
		@@pcap_info.keys.each{|ipadd|
			begin
			 open(@iplist_tmp, "a"){|ip_list| ip_list.write("#{ipadd}\n"); ip_list.close}
			rescue => ex
			 logger(4, "ip list create error; #{ex.message}")
 	 		 logger(4, "exit")
			 exit
			end
		}
		logger(1, "ip_list file created")

		# data info file create
		@@pcap_info.each_value do |p_info|
			begin
			 open(@pcapinfo_tmp, "a"){|pinfo_list|
			 pinfo_list.write("#{p_info[0]}, #{p_info[1]}, #{p_info[2]}, #{p_info[3]}, #{p_info[4]}, #{p_info[5]}, #{p_info[6]}\n"); pinfo_list.close}
			rescue => ex
			 logger(4, "pinfo list create error: #{ex.message}")
 		 	 logger(4, "exit")
			 exit
			end
		end
		logger(1, "pinfo_list file created")
	end
	rescue => ex
	 logger(4, "An error occurred at mk_iplist: #{ex.message}")
	 logger(4, "#{$@}")
 	 logger(4, "exit")
	 exit	 
  end
end
