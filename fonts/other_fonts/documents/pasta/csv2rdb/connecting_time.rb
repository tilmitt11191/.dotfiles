#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'mysql2'
require 'rubygems'
require 'optparse'
require 'time'
require 'json'

SQL_SERV  = 'localhost'
SQL_USER  = 'isnet'
SQL_PASS  = 'isnet'
SQL_DB    = 'isnet'
SQL_TBL_TCP    = 'nagaoka_0803_tcp'
SQL_TBL_VOLUME = 'nagaoka_0803_vol'

SESSION_TIMEOUT = 2.0
ONLINE_TIMEOUT  = 2.0
BREAK_CNT  = nil
OL_SEQ_EPS = 0.01

opt = OptionParser.new
options = Hash.new

options['sampling_div']     = 1 # sampling rate = sampling_dev / 16
options['tblname_tcp']      = SQL_TBL_TCP
options['tblname_volume']   = SQL_TBL_VOLUME
options['session_timeout']  = SESSION_TIMEOUT
options['online_timeout']   = ONLINE_TIMEOUT
options['break_cnt']        = BREAK_CNT
options['detail_json_file'] = 'detail.json'
options['readable']         = false

class Online
  def initialize(src_ipaddr = nil, ol = nil)
    @src_ipaddr = src_ipaddr
    @ol = ol
  end
  attr_accessor :src_ipaddr, :ol
  def ol_empty?
    return true if @ol == nil
    return false
  end
  def ol
    if @ol
      return @ol
    else
      return nil
    end
  end
  def make(src_ipaddr, ol = nil)
    @src_ipaddr = src_ipaddr
    @ol = ol
  end
  def clear
    self.src_ipaddr = nil
    self.ol = nil
  end
  def add_ol(ol)
    @ol = Array.new unless @ol
    @ol << ol
  end
  def sort_ol!
    self.ol.sort!{|a, b| a['volume_begin'] <=> b['volume_begin']}
  end
  def ol_stat
    values = {
      "volume_begin"     => @ol.first['volume_begin'],
      "volume_end"       => @ol.last['volume_end'],
      "src_ipaddr"       => @src_ipaddr,
      "upload_size"      => 0,
      "download_size"    => 0,
      "upload_packets"   => 0,
      "download_packets" => 0
    }
    @ol.each{|v|
      values['upload_size'] += v['upload_size']
      values['download_size'] += v['download_size']
      values['upload_packets'] += v['upload_packets']
      values['download_packets'] += v['download_packets']
    }
    return values
  end
  def num_ol
    if @ol
      return @ol.size
    else
      return 0
    end
  end

  # cannot care about the most end of blocks
  def separate_online_blocks(timeout = 0.0)
    pre_end = 0.0
    new_ol_ary = Array.new
    new_ol = Online.new(@src_ipaddr)
    @ol.each{|v|
      if new_ol.ol_empty?
        new_ol.make(@src_ipaddr)
        new_ol.add_ol(v)
      else
        if v['volume_begin'] - pre_end < timeout + OL_SEQ_EPS
          new_ol.add_ol(v)
        else
          new_ol_ary << new_ol.dup
          new_ol.clear
          new_ol.add_ol(v)
        end
      end
      pre_end = v['volume_end']
    }
    return new_ol_ary
  end
  def src_ipaddr
    return @src_ipaddr
  end
end


class Timeline
  def initialize(src_ipaddr = nil, tl = nil)
    @src_ipaddr = src_ipaddr
    @tl = tl
  end
  attr_accessor :src_ipaddr, :tl
  def make(src_ipaddr, tl = nil)
    @src_ipaddr = src_ipaddr
    @tl = tl
  end
  def add_tl(tl)
    @tl = Array.new unless @tl
    @tl << tl
  end
  def del_tl(tl)
    return @tl.reject{|v| v == tl}
  end
  def del_tl!(tl)
    self.tl.reject!{|v| v == tl}
  end
  def src_ipaddr
    return @src_ipaddr
  end
  def tl
    return @tl
  end
  def html5?
    html5 = Array.new
    @tl.each{|v|
      html5 << v['html5'] if v['html5']
    }
    if html5.empty?
      return nil
    else
      return html5.uniq
    end
  end
  def start_end
    ret = self.start_end_to_f
    return [Time.at(ret[0]), Time.at(ret[1].to_f)]
  end
  def start_end_to_f
    st = nil
    ed = nil
    @tl.each{|v|
      if st == nil or v['tcp_begin'] < st
        st = v['tcp_begin']
      end
      if ed == nil or v['tcp_end'] > ed
        ed = v['tcp_end']
      end
    }
    return [st, ed]
  end
  def sort_tl!
    self.tl.sort!{|a, b|
      a['tcp_begin'] <=> b['tcp_begin']
    }
  end
  def tl_empty?
    return true if @tl == nil
    return false
  end
  def clear
    self.src_ipaddr = nil
    self.tl = nil
  end
  def num_tl
    if @tl
      return @tl.size
    else
      0
    end
  end
  def tcp_num_tl
    a = Array.new
    @tl.each{|v|
      a << v['tcp_hash']
    }
    unless a.empty?
      return a.uniq.size
    else
      return 0
    end
  end
  def ave_servicetime_tcp
    a = Array.new
    @tl.each{|v|
      a << v['tcp_hash']
    }
    unless a.empty?
      tmp = 0.0
      @tl.each{|v|
        tmp += v['tcp_end'] - v['tcp_begin']
      }
      ret = tmp / @tl.size
      return ret
    else
      return 0
    end    
  end
  def tcp_size
    h = Hash.new(nil)
    upload = 0
    download = 0
    @tl.each{|v|
      unless h[v['tcp_hash']]
        upload = upload + v['tcp_upload_size'] + v['tcp_upload_resent'] + v['tcp_upload_unexpected']
        download = download + v['tcp_download_size'] + v['tcp_download_resent'] + v['tcp_download_unexpected']
        h[v['tcp_hash']] = true      
      end
    }
    return [upload, download]
  end
  # タイムアウト秒離れた複数セッションをブロックとして切り出し，それぞれを
  # Timeline クラスのオブジェクトとして再定義し，それぞれを配列に畳んで返す．
  # 畳むべき Timeline が存在しないときは nil を返す
  def separate_timeline_blocks(timeout_sec = 1.0, cnt = 0)
    return nil if @tl.size == 0
    st = @tl.first['tcp_begin']
    et = @tl.first['tcp_end']
    ret = Array.new
    dup = self
    should_be_deleted = Array.new
    dup.tl.each{|v|
      if v['tcp_begin'] >= st and v['tcp_begin'] <= et + timeout_sec
        should_be_deleted << v
        et = v['tcp_end'] if v['tcp_end'] > et.to_f
      end
    }
    b = Timeline.new(@src_ipaddr)
    should_be_deleted.each{|v|
      b.add_tl(v)
      dup.del_tl!(v)
    }
    b.sort_tl!
    ret << b
    res = dup.separate_timeline_blocks(timeout_sec, cnt + 1)
    ret.concat res if res
    return ret
  end
end

begin
  opt.on('-T tblname_tcp'     , String  , 'select target table of TCP'                                                ){ |v| options['tblname_tcp']      = v }
  opt.on('-V tblname_volume'  , String  , 'select target table of VOLUME'                                             ){ |v| options['tblname_volume']   = v }
  opt.on('-r sampling_div'    , Integer , 'sampling ratio for target users [1-16]'                                    ){ |v| options['sampling_div']     = v }
  opt.on('-s tcp timeout'     , Float   , 'timeout for dividing TCP flows to each page'                               ){ |v| options['session_timeout']  = v }
  opt.on('-o online timeout'  , Float   , 'timeout for dividing online status to each block'                          ){ |v| options['online_timeout']   = v }
  opt.on('-b break_count'     , Integer , 'break this process as of the no. of processed users amounts to this count.'){ |v| options['break_cnt']        = v }
  opt.on('-d detail JSON file', String  , 'output JSON file'                                                          ){ |v| options['detail_json_file'] = v }
  opt.on('-a'                           , 'if you need a readable regular json file, use this'                        ){     options['readable'] = true      }
  opt.permute!(ARGV)
rescue
  puts opt.help
  exit  
end


def get_target_users(db, tblname_tcp, sampling_div)
  regex_ary = Array.new(0)
  (0..sampling_div).each{|i|
    regex_ary << "src_ipaddr regexp '#{i.to_s(16)}$'"
  }
  regex = regex_ary.join(' or ')
  query = "select src_ipaddr from #{tblname_tcp} where #{regex}" 

  src_ipaddr_list = Hash.new

  res = db.query(query);
  res.each{|row|
    if src_ipaddr_list[row['src_ipaddr']]
      src_ipaddr_list[row['src_ipaddr']] = src_ipaddr_list[row['src_ipaddr']] + 1
    else
      src_ipaddr_list[row['src_ipaddr']] = 1
    end
  }
  return src_ipaddr_list
end

def mk_online(src_ipaddr, db, tblname_volume)
  online = Online.new(src_ipaddr)
  query = "select * from #{tblname_volume} where src_ipaddr = '#{src_ipaddr}'"
  res = db.query(query)  
  res.each{|row|
    online.add_ol(row)
  }
  online.sort_ol!
  return online
end

def mk_timeline(src_ipaddr, db, tblname_tcp)
  timeline = Timeline.new(src_ipaddr)
  query = "select * from #{tblname_tcp} where src_ipaddr = '#{src_ipaddr}'"
  res = db.query(query)  
  res.each{|row|
    timeline.add_tl(row)
  }
  timeline.sort_tl!
  return timeline
end



db = Mysql2::Client.new( :host     => SQL_SERV,
                         :username => SQL_USER,
                         :password => SQL_PASS,
                         :database => SQL_DB )

target_list = get_target_users(db, options['tblname_tcp'], options['sampling_div'])

user_count = 0
puts "num of target users: #{target_list.size}"

json_raw_ary = Array.new
target_list.keys.each{|src_ipaddr|
  break if options['break_cnt'] and user_count >= options['break_cnt']
  
  puts "(#{user_count+1}/#{target_list.size}) #{src_ipaddr} is being performed..."

  timeline = mk_timeline(src_ipaddr, db, options['tblname_tcp'])
  online = mk_online(src_ipaddr, db, options['tblname_volume'])

  se = timeline.start_end_to_f
  online_stat = online.ol_stat
  user_tcp_size = timeline.tcp_size
  res_timeline = timeline.separate_timeline_blocks(options['session_timeout'])
  res_online   = online.separate_online_blocks(options['online_timeout'])
  
  json_raw_top = {
    'src_ipaddr'        => src_ipaddr,
    'page_num'          => res_timeline.size,
    'begin'             => se[0],
    'begin_iso8601'     => Time.at(se[0]).iso8601(6),
    'end'               => se[1],
    'end_iso8601'       => Time.at(se[1]).iso8601(6),
    'service_time'      => se[1]-se[0],
    'tcp_upload_size'   => user_tcp_size[0],
    'tcp_download_size' => user_tcp_size[1]
  }

  # page
  pret_tl = nil
  pret_ol = nil
  page_count = 0

  json_raw_page_ary = Array.new
  res_timeline.each{|btl|
    se = btl.start_end_to_f
    page_tcp_size = btl.tcp_size
    ave_st = btl.ave_servicetime_tcp

    gap = nil
    if pret_tl
      gap = se[0] - pret_tl
    end
    pret_tl = se[1]


    html5funcs = nil
    html5funcs = btl.html5?.join(',') if btl.html5?
    json_raw_page = {
      'page_count'          => page_count,
      'begin'               => se[0],
      'begin_iso8601'       => Time.at(se[0]).iso8601(6),
      'end'                 => se[1],
      'end_iso8601'         => Time.at(se[1]).iso8601(6),
      'service_time'        => se[1]-se[0],
      'average_service_time'=> ave_st,
      'num_l4_siml_session' => btl.tcp_num_tl,
      'num_l7_siml_session' => btl.num_tl.to_s,
      'l4proto'             => 'tcp',
      'tcp_upload_size'     => page_tcp_size[0],
      'tcp_download_size'   => page_tcp_size[1],
      'html5funcs'          => html5funcs,
      'gap'                 => gap
    }

    # L3/L4
    json_raw_l3l4_ary = Array.new
    btl.tl.each{|row|
      l7proto = String.new
      if (row['dst_port'] == 80 or row['dst_port'] == 8080) and not /CONNECT/i =~ row['request_method']    
        l7proto = 'http'
      elsif row['dst_port'] == 443 or /CONNECT/i =~ row['request_method']
        l7proto = 'https'
      else
        l7proto = 'other'
      end

      json_raw_l3l4 = {
        'tcp_hash'          => row['tcp_hash'],
        'dst_ipaddr'        => row['dst_ipaddr'],
        'src_port'          => row['src_port'],
        'dst_port'          => row['dst_port'],
        'begin'             => row['tcp_begin'],
        'begin_iso8601'     => Time.at(row['tcp_begin']).iso8601(6),
        'end'               => row['tcp_end'],
        'end_iso8601'       => Time.at(row['tcp_end']).iso8601(6),
        'service_time'      => row['tcp_end']-row['tcp_begin'],
        'tcp_upload_size'   => row['tcp_upload_size']+row['tcp_upload_resent']+row['tcp_upload_unexpected'],
        'tcp_download_size' => row['tcp_download_size']+row['tcp_download_resent']+row['tcp_download_unexpected'],
        'tcp_close_state'   => row['tcp_close_state'],
        'l7proto'           => l7proto
      }
      
      # L7
      if json_raw_l3l4['l7proto'] == 'http'
        json_raw_l3l4['l7'] = {
          'begin'                => row['request_begin'],
          'begin_iso8601'        => Time.at(row['request_begin']).iso8601(6),
          'end'                  => row['response_end'],
          'end_iso8601'          => Time.at(row['response_end']).iso8601(6),
          'service_time'         => row['response_end']-row['request_begin'],
          'response_size'        => row['response_size'],
          'response_actual_size' => row['response_actual_size'],
          'request_host'         => row['request_host'],
          'request_path'         => row['request_path'],
          'gps_latitude'         => row['gps_latitude'],
          'gps_longitude'        => row['gps_longitude'],
          'request_referer'      => row['request_referer'],
          'request_user_agent'   => row['request_user_agent'],
          'html5'                => row['html5']
        }
      end
      json_raw_l3l4_ary << json_raw_l3l4.dup
    }
    json_raw_page['l3l4'] =  json_raw_l3l4_ary.dup
    json_raw_page_ary << json_raw_page.dup
    page_count = page_count + 1
  }

  # online ( by volume traffic )
  json_raw_online = {
    'begin'         => online_stat['volume_begin'],
    'begin_iso8601' => Time.at(online_stat['volume_begin']).iso8601(6),
    'end'           => online_stat['volume_end'],
    'end_iso8601'   => Time.at(online_stat['volume_end']).iso8601(6),
    'service_time'  => online_stat['volume_end'] - online_stat['volume_begin'],
    'num_blocks'    => res_online.size
  }

  block_count = 0
  json_raw_online_ary = Array.new
  res_online.each{|bol|
    block_stat = bol.ol_stat
    gap = nil
    if pret_ol
      gap = block_stat['volume_begin'] - pret_ol
    end
    json_raw_online_ary << {
      'block_count'   => block_count,
      'begin'         => block_stat['volume_begin'],
      'begin_iso8601' => Time.at(block_stat['volume_begin']).iso8601(6),
      'end'           => block_stat['volume_end'],
      'end_iso8601'   => Time.at(block_stat['volume_end']).iso8601(6),
      'service_time'  => block_stat['volume_end'] - block_stat['volume_begin'],
      'gap'           => gap
    }
    pret_ol = block_stat['volume_end']
    block_count = block_count + 1
  }
  json_raw_online['block'] = json_raw_online_ary.dup
  user_count = user_count + 1

  json_raw_top['pages']  = json_raw_page_ary.dup
  json_raw_top['online'] = json_raw_online.dup

  json_raw_ary << json_raw_top.dup
}

puts "now writing to json file #{options['detail_json_file']}"

res = nil
if options['readable']
  res = json_raw_ary.to_json(
                             :indent    => ' ' * 1,
                             :object_nl => "\n",
                             :space     => ' '
                             )
else
  res = json_raw_ary.to_json
end


File.open(options['detail_json_file']+'.log', 'w'){|out|
  out << options.to_json(
                         :indent    => ' ' * 1,
                         :object_nl => "\n",
                         :space     => ' '
                         )
}
File.open(options['detail_json_file'], 'w'){|out|
  out << res
}
