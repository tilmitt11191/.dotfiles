#!/usr/bin/env ruby
require 'rubygems'
require 'mysql2'
require 'cgi'
require 'optparse'
require 'csv'
require 'time'

require_relative 'def_sql_tbl_fmt.rb'

SQL_SERV  = 'localhost'
SQL_USER  = 'testuser'
SQL_PASS  = 'testpass'
SQL_DB    = 'testdb'

opt = OptionParser.new
options = {}

begin
  require 'progressbar'
  options['progressbar'] = true
rescue LoadError
  STDERR.puts("progressbar could not be loaded.")
  options['progressbar'] = false
end

def check_params options
  def check_table_name(tablename)
    t = tablename
    t = t.gsub(/[-\.]/, '_')
    unless /[a-zA-Z]/ =~ t
      STDERR.puts "table name must need some [a-zA-Z] chars!"
      exit
    end
    return t
  end

  # check csv files
  csvfiles = {}
  options.each_pair{|k, v|
    if /(.*)csvname/ =~ k
      csvfiles[$1] = v
      puts "[CSV] csv(#{$1}): #{v}"
    end
  }
  # when no csvfiles was found then try to get csv names from argv
  if csvfiles.size == 0
    if options['argv']
      options['argv'].each{|arg|
        if /^[a-zA-Z0-9_]+_([a-zA-Z]+)_\d\d\d\d\d\d\d\d-\d\d\d\d\d\d.csv$/ =~ File.basename(arg)
          csvfiles[$1] = arg
        end
      }
    end
  end

  # check tables
  tables = {}
  options.each_pair{|k, v|
    if /(.*)tblname/ =~ k
      tables[$1] = check_table_name(v)
      puts "[TABLE] table(#{$1}): #{tables[$1]}"
    end
  }
  csvfiles.each_pair{|k, v|
    unless tables[k]
      t = check_table_name(File.basename(v, '.csv'))
      tables[k] = t
      puts "[TABLE] table(#{k}): #{tables[k]}"
    end
  }

  options['csvfiles'] = csvfiles
  options['tables']   = tables
end

def create_table options
  db = Mysql2::Client.new(:host=>options['sql_serv'],
                          :username=>options['sql_user'],
                          :password=>options['sql_pass'])
  unless db.query("show databases like '#{options['sql_db']}'").size == 1
    STDERR.puts("Creating MySQL Database #{options['sql_db']}")
    db.query("create database #{options['sql_db']} character set utf8")
  end

  options['tables'].each_pair{|tblname, csv|
    format = SQL_TABLE_FORMAT[tblname]
    db = Mysql2::Client.new(:host=>options['sql_serv'],
                            :username=>options['sql_user'],
                            :password=>options['sql_pass'],
                            :database=>options['sql_db'])
    unless db.query("show tables from #{options['sql_db']} like '#{options['tables'][tblname]}'").size == 1
      ary = Array.new
      format.each_pair{|k, v|
        ary << [k, v].join(' ')
      }
      str = ary.join(",\n")
      query = <<SQL
create table #{options['tables'][tblname]} (
#{str}
) character set utf8
SQL
      puts query
      db.query(query)
    else
      puts "[SQL] Table #{options['tables'][tblname]} is already existed"
    end
  }
end

def insert(options)
  options['tables'].each_pair{|tblname, table|
    db = Mysql2::Client.new(:host     => options['sql_serv'],
                            :username => options['sql_user'],
                            :password => options['sql_pass'],
                            :database => options['sql_db']   )

    if options['errorlog']
      errfp = File.open("#{options['errorlog']}#{options['sql_db']}_#{table}_error.log", 'w')
    end

    csvfile = options['csvfiles'][tblname]
    nl = `wc -l #{csvfile}`.split("\s")[0].to_i - 1 if options['progressbar']

    if options['progressbar'] and nl != nil
      pbar = ProgressBar.new("#{tblname}", nl)
    end

    format = SQL_TABLE_FORMAT[tblname]
    CSV.open(csvfile, {:headers => :first_row, :encoding => Encoding::ASCII_8BIT}).each{|row|
      begin
        values = row.to_hash
        # -------- transform rules of types from fuk-csv to mysql ---------
        values.each_pair{|k, v| # escape for mysql
          if v and format[k] and (format[k].include?("varchar") or format[k].include?("text"))
            values[k] = '\'' + Mysql2::Client.escape(values[k]).to_s + '\''
          end
        }
        values.keys.select{|item| (/begin/ =~ item or /end/ =~ item) and /float/ !~ item }.each{|item|
        values[item] = Time.parse(values[item]).to_f if values[item]
        }
        # -----------------------------------------------------------------
        sql_ary_key = []
        sql_ary_val = []
        values.each_pair{|k, v|
          if format.key?(k)
            sql_ary_key << k
            if v
              sql_ary_val << v
            else
              sql_ary_val << 'NULL'
            end
          else
          end
        }
        sql_str_key = sql_ary_key.join(',')
        sql_str_val = sql_ary_val.join(',')
        sql_str = "insert into #{table} (#{sql_str_key}) values (#{sql_str_val})"
        begin # sql insert
          db.query(sql_str)
        rescue
          if options['errorlog']
            errfp.puts "Insert error: #{sql_str}"
          else
            STDERR.puts "Insert error: #{sql_str}"
          end
        end
        pbar.inc if options['progressbar'] and nl != nil
      rescue => err
        errfp <<  err
      end
    }
    pbar.finish if options['progressbar'] and nl != nil
    errfp.close
  }
end

options['sql_serv'] = SQL_SERV
options['sql_user'] = SQL_USER
options['sql_pass'] = SQL_PASS
options['sql_db'] = SQL_DB

begin
  opt.on('-s', '--mysql-server MySQL Server'          , String, 'MySQL Server'       ){|v| options['sql_serv']            = v }
  opt.on('-r', '--mysql-user MySQL User'              , String, 'MySQL User'         ){|v| options['sql_user']            = v }
  opt.on('-p', '--mysql-db-password MySQL DB Password', String, 'MySQL User Password'){|v| options['sql_pass']            = v }
  opt.on('-d', '--mysql-database MySQL DB'            , String, 'MySQL Database'     ){|v| options['sql_db']              = v }
  opt.on('-T', '--tcp-table TCP table name'           , String, 'TCP table name'     ){|v| options['tcp'+'tblname']       = v }
  opt.on('-U', '--udp-table UDP table name'           , String, 'UDP table name'     ){|v| options['udp'+'tblname']       = v }
  opt.on('-V', '--volume-table VOLUME table name'     , String, 'VOLUME table name'  ){|v| options['volume'+'tblname']    = v }
  opt.on('-G', '--gtp-table GTP table name'           , String, 'GTP table name'     ){|v| options['gtp'+'tblname']       = v }
  opt.on('-t', '--tcp-csvfile TCP csvfile'            , String, 'TCP table name'     ){|v| options['tcp'+'csvname']       = v }
  opt.on('-u', '--udp-csvfile UDP csvfile'            , String, 'UDP table name'     ){|v| options['udp'+'csvname']       = v }
  opt.on('-v', '--volume-csvfile VOLUME csvfile'      , String, 'VOLUME table name'  ){|v| options['volume'+'csvname']    = v }
  opt.on('-g', '--gtp-csvfile GTP csvfile'            , String, 'GTP table name'     ){|v| options['gtp'+'csvname']       = v }
  opt.on('-e', '--error-log error log file'           , String, 'error log file'     ){|v| options['errorlog']            = v }
  opt.on('-P', '--progressbar-disable'                                               ){    options['progressbar']         = false}
  opt.permute!(ARGV)
rescue
  errmsg =<<EOS
usage: ruby #{__FILE__}
EOS
  puts errmsg
  exit
end

options['argv'] = ARGV
check_params options
create_table options
insert options

