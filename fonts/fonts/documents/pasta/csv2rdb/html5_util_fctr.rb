#!/usr/bin/env ruby

require 'rubygems'
require 'mysql2'
require 'csv'

SQL_SERV  = 'localhost'
SQL_USER  = 'isnet'
SQL_PASS  = 'isnet'
SQL_DB    = 'isnet'

HTTP_PORT = 80

db = Mysql2::Client.new(:host=>SQL_SERV,
                        :username=>SQL_USER,
                        :password=>SQL_PASS,
                        :database=>SQL_DB)

res = db.query("select html5 from #{ARGV[0]} where dst_port = #{HTTP_PORT}")
html5 = {'all' => 0}
res.each{|row|  
  if row['html5']
    row['html5'].split('/').each{|html5teq|
      html5[html5teq] ||= 0
      html5[html5teq] += 1
    }
  end
  html5['all'] += 1
}
CSV.open(ARGV[0] +'.csv', 'w', {:force_quotes => false}){|out|
  html5.each{|v|
    out << v
  }
}
