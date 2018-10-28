#!/bin/env ruby

require 'rubygems'
require 'mysql'

SQL_SERV  = 'localhost'
SQL_USER  = 'isnet'
SQL_PASS  = 'isnet'
SQL_DB    = 'isnet'
SQL_TBL   = 'http_20120402_134021'

# MySQL DB に接続する
db = Mysql.new(SQL_SERV, SQL_USER, SQL_PASS, SQL_DB)

# select してみる．結果は res に格納されている．
res = db.query("select * from #{SQL_TBL}")
# res をイテレータで一行ずつ読み，hash に放り込んでみる．
# 配列のときは each．
res.each_hash{|row| p row }

# tcp_begin をキーとして降順(逆順)に 10レコードだけ
# tcp_begin, srcip と dstip を表示してみる
res = db.query("select tcp_begin, src_ipaddr, dst_ipaddr from #{SQL_TBL} order by tcp_begin desc limit 10")
res.each_hash{|row|
  val = row
  val['tcp_begin'] = Time.at(val['tcp_begin'].to_f).to_f
  p val
}

# MySQL DB を切り離す
db.close

