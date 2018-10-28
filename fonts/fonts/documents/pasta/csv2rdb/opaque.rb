#!/usr/bin/env ruby

SQL_SERV  = 'localhost'
SQL_USER  = 'isnet'
SQL_PASS  = 'isnet'
SQL_DB    = 'isnet'

CNT    = 0
IPADDR = 1

require 'rubygems'
require 'mysql2'
require 'cgi'
require 'uri'
require 'optparse'
require 'csv'
require 'time'

opt = OptionParser.new
options = Hash.new
options['sql_serv'] = SQL_SERV
options['sql_db']   = SQL_DB
options['sql_user'] = SQL_USER
options['sql_pass'] = SQL_PASS
# options['udp_tblname'] = 'fri20130412_udp'
# options['tcp_tblname'] = 'fri20130412_tcp'
options['use_progressbar'] = true

begin
  require 'progressbar'
rescue LoadError
  STDERR.puts("progressbar could not be loaded.")
  options['use_progressbar'] = false
end

SQL_FORMAT_TABLE = {
  # tcp
  'tcp_begin'=> 'double',
  'tcp_end'=> 'double',
  'syn_src_mac'=> 'varchar(17)',
  'syn_dst_mac'=> 'varchar(17)',
  'syn_ack_src_mac'=> 'varchar(17)',
  'syn_ack_dst_mac'=> 'varchar(17)',
  'tcp_close_state'=> 'varchar(80)',
  'src_ipaddr'=> 'varchar(40)',
  'src_ipaddr_subnet_prefix' => 'varchar(18)', # xxx.yyy.zzz.www/99
  'dst_ipaddr'=> 'varchar(15)',
  'src_port'=> 'smallint',
  'dst_port'=> 'smallint',
  'tcp_upload_size'=> 'integer',
  'tcp_download_size'=> 'integer',
  'tcp_upload_resent'=> 'integer',
  'tcp_download_resent'=> 'integer',
  'tcp_upload_unexpected'=> 'integer',
  'tcp_download_unexpected'=> 'integer',
  'tcp_upload_n_packets'=> 'integer',
  'tcp_download_n_packets'=> 'integer',
  'tcp_upload_resent_n_packets'=> 'integer',
  'tcp_download_resent_n_packets'=> 'integer',
  'tcp_upload_unexpected_n_packets'=> 'integer',
  'tcp_download_unexpected_n_packets'=> 'integer',
  'syn_window_size'=> 'smallint',
  'syn_ttl'=> 'smallint',
  'syn_fragment'=> 'smallint',
  'syn_total_length'=> 'smallint',
  'syn_options'=> 'varchar(80)',
  'syn_quirks'=> 'varchar(80)',
  'syn_ack_window_size'=> 'smallint',
  'syn_ack_ttl'=> 'smallint',
  'syn_ack_fragment'=> 'smallint',
  'syn_ack_total_length'=> 'smallint',
  'syn_ack_options'=> 'varchar(80)',
  'syn_ack_quirks'=> 'varchar(80)',
  'client_rtt'=> 'integer',
  'server_rtt'=> 'integer',
  'tcp_hash'=> 'varchar(40)',
  'request_begin'=> 'double',
  'request_end'=> 'double',
  'request_end_ack'=> 'double',
  'request_size'=> 'integer',
  'request_actual_size'=> 'integer',
  'request_method'=> 'varchar(32)',
  'request_path'=> 'varchar(1024)',
  'request_version'=> 'varchar(32)',
  'request_host'=> 'varchar(256)',
  'request_range'=> 'varchar(80)',
  'request_content_length'=> 'varchar(80)',
  'request_referer'=> 'varchar(1024)',
  'request_user_agent'=> 'varchar(512)',
  'response_begin'=> 'double',
  'response_end'=> 'double',
  'response_end_ack'=> 'double',
  'response_size'=> 'integer',
  'response_actual_size'=> 'integer',
  'response_version'=> 'varchar(32)',
  'response_code'=> 'smallint',
  'response_message'=> 'varchar(16)',
  'response_server'=> 'varchar(80)',
  'response_accept_ranges'=> 'varchar(80)',
  'response_content_range'=> 'varchar(80)',
  'response_content_length'=> 'integer',
  'response_content_type'=> 'varchar(80)',
  'response_connection'=> 'varchar(32)',
  'gps_type'=> 'varchar(16)',
  'gps_latitude'=> 'double',
  'gps_longitude'=> 'double',
  'gps_time'=> 'varchar(14)',
  'gps_accuracy'=> 'integer',
  'imsi_type'=> 'varchar(64)',
  'imsi_value'=> 'varchar(64)',
  'meid_type'=> 'varchar(64)',
  'meid_value'=> 'varchar(64)',
  'html5' => 'varchar(64)',
  'youtube_id_mapping' => 'varchar(1024)',
  'video_container' => 'varchar(8)',
  'video_major_brand' => 'varchar(8)',
  'video_duration' => 'double',
  'video_type' => 'varchar(8)',
  'video_profile' => 'varchar(32)',
  'video_bitrate' => 'integer',
  'video_width' => 'integer',
  'video_height' => 'integer',
  'video_horizontal_resolution' => 'integer',
  'video_vertical_resolution' => 'integer',
  'audio_type' => 'varchar(8)',
  'audio_bitrate' => 'integer',
  'audio_channel_count' => 'integer',
  'audio_sample_size' => 'integer',
  'audio_sample_rate' => 'integer',
  'request_dns' => 'varchar(256)'
}


begin
  opt.on('-s MYSQL_SERVER, String'           ){|v| options['sql_serv']    = v }
  opt.on('-u MYSQL_DATABASE_USER, String'    ){|v| options['sql_user']    = v }
  opt.on('-p MYSQL_DATABASE_PASSWORD, String'){|v| options['sql_pass']    = v }
  opt.on('-d MYSQL_DATABASE_NAME, String'    ){|v| options['sql_db']      = v }
  opt.on('-T MySQL_TABLE_NAME', String       ){|v| options['tcp_tblname'] = v }
  opt.on('-U MySQL_TABLE_NAME', String       ){|v| options['udp_tblname'] = v }
  opt.permute!(ARGV)
rescue
  errmsg =<<EOS
usage: ruby #{__FILE__} -T TCP_SQL_TABLE_NAME -U TCP_UDP_TABLE_NAME
EOS
  puts errmsg
  exit  
end

def dns_map(db, options)
  nslookup = {}
  p options
  q_str = "select src_ipaddr, dns_request, dns_response, udp_end from #{options['udp_tblname']} where dns_response is not null"
  res = db.query q_str
  res.each{|row|
    src_ipaddr = row['src_ipaddr'].to_s
    dnsreq = row['dns_request'].to_s
    req_type = dnsreq.split(':')[0]
    next unless req_type == 'A' or req_type == 'AAAA'
    req_dom = dnsreq.split(':')[1]
    dnsres = row['dns_response'].to_s
    ipaddrs = []
    dnsres.split('/').each{|res_record|
      type, res, ttl = nil, nil, nil
      if /(.*)%(.*)/ =~ res_record
        type = $1.split('#')[0].split(':')[0]
        if type == 'A' or type == 'AAAA'
          res = $1.split('#')[1]
          ttl = $2.split('#')[1].to_i
          begin
            ipaddrs << [res, ttl].join('#')
          rescue
          end
        end
      end
    }
    udp_end = row['udp_end'].to_s
    key = [src_ipaddr, req_dom, udp_end].join('/')
    nslookup[key] ||= []
      ipaddrs.each{|ipaddr|
      nslookup[key] << ipaddr
    }
  }
  return nslookup
end
def preimage(map)
  preimage_map = {}
  map.each_pair{|key, ipaddrs|
    spkey = key.split('/')
    src_ipaddr = spkey[0]
    req_dom = spkey[1]
    udp_end = spkey[2].to_f
    ipaddrs.each{|ipaddr|
      ip = ipaddr.split('#')[0]
      ttl = ipaddr.split('#')[1].to_i
      preimage_map[ip] ||= []
      preimage_map[ip] << [req_dom, src_ipaddr, udp_end, ttl]
    }
  }
  return preimage_map
end

def rev_nslookup(ipaddr, src_ipaddr, tcp_begin, preimage_map)
  cnd_doms = preimage_map[ipaddr]
  return nil unless cnd_doms
  ret = nil
  cnd_doms.each{|v|
    if v[1] and v[1] == src_ipaddr
      if tcp_begin - v[2] >= 0 and tcp_begin - v[2] < v[3]
        ret = [v[0], v[3]]
      end
    end
  }
  return ret
end

db = Mysql2::Client.new(:host=>options['sql_serv'],
                        :username=>options['sql_user'],
                        :password=>options['sql_pass'],
                        :database=>options['sql_db'])


map = dns_map(db, options)
preimage_map = preimage(map)

q_str = "select src_ipaddr, dst_ipaddr, tcp_begin, tcp_hash from #{options['tcp_tblname']}"
res = db.query q_str

if options['use_progressbar']
  nl = res.size
  pbar = ProgressBar.new("SQL Commit", nl)
end

headers = res.first.to_hash.keys

unless db.query("show fields from #{options['tcp_tblname']} like 'request_dns'").size == 1
  puts add_sql = "ALTER TABLE #{options['tcp_tblname']} add request_dns varchar(256);"
  db.query add_sql
  puts add_sql = "ALTER TABLE #{options['tcp_tblname']} add dns_ttl integer;"
  db.query add_sql
end
unless db.query("show index from #{options['tcp_tblname']} where Key_name = 'key_tcp_hash'").size == 1
  puts index_sql = "alter table #{options['tcp_tblname']} add index key_tcp_hash(tcp_hash)"
  db.query index_sql
end

res.each{|row|
  request_dns = rev_nslookup(row['dst_ipaddr'], row['src_ipaddr'], row['tcp_begin'].to_f, preimage_map)
  if request_dns 
    request_dns[0] = '\'' + Mysql2::Client.escape(request_dns[0]).to_s + '\''
    add_q = "update #{options['tcp_tblname']} set request_dns = #{request_dns[0]}, dns_ttl = #{request_dns[1]} where tcp_hash = '#{row['tcp_hash']}'"
    begin
      db.query add_q
    rescue
      STDERR.puts "error: #{add_q}"
    end
  end
  pbar.inc if options['use_progressbar']
}
pbar.finish if options['use_progressbar']
