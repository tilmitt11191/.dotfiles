#!/usr/bin/env ruby

require 'csv'
require 'rubygems'
require 'json'
require 'gnuplot'
require 'find'

json = nil
File.open(ARGV[0], 'r'){|row| json = JSON.load(row)}

json.each{|user|
  # foreach user
  CSV.open("tmp/#{user['src_ipaddr']}.csv", "w"){|csv|
    y_axis = 0
    user['pages'].each{|page|
      # page-line
      csv << [page['begin'], y_axis.to_f, 'page_begin']
      csv << [page['end'], y_axis.to_f, 'page_end']
      csv << []
      # y_axis += 5
      
      l3l4s = page['l3l4']
      l3l4s.each{|l3l4|
        csv << [l3l4['begin'], y_axis.to_f, ['tcp_begin', [l3l4['dst_ipaddr'],l3l4['dst_port']].join(':')].join('|')]
        csv << [l3l4['end'], y_axis.to_f, ['tcp_end', l3l4['tcp_close_state']].join('|')]
        csv << []
        y_axis += 1
      }
      y_axis += 10
    }
  }
}



# test
Find.find("tmp/") {|f|
  if /\.csv$/ =~ f
    outps = "#{File.basename(f,'.csv')}.ps"
    
    keys_x = {}
    keys_y = {}
    page_x = []
    page_y = []
    additional = []
    csv = CSV.open(f)
    swap_x = nil
    swap_y = nil
    csv.each{|row|
      case row[2]
      when /^page/
        # for page
        page_x << row[0].to_f + 9*3600
        page_y << row[1].to_f
        if /end$/ =~ row[2]
          page_x << nil
          page_y << nil
        end
      when /^tcp/
        # for tcp
        # tcp_x << row[0].to_f + 9*3600
        if /begin/ =~ row[2]
          swap_x = row[0].to_f + 9*3600
          swap_y = row[1].to_f
        end
        if /end/ =~ row[2]
          key = row[2].split('|')[1]
          keys_x[key] ||= []
          keys_y[key] ||= []
          keys_x[key] << swap_x
          keys_x[key] << row[0].to_f + 9*3600
          keys_x[key] << nil
          keys_y[key] << swap_y
          keys_y[key] << row[1].to_f
          keys_y[key] << nil
        end
      end
    }

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.title  "tcp flows: #{f}"
        plot.ylabel ''
        plot.xlabel 'time'
        plot.noytics
        plot.terminal "postscript mono"
        plot.output "ps/#{outps}"
        plot.xdata 'time'
        plot.timefmt '"%s"'
        plot.format 'x "%H:%M:%S"'
        plot.key 'left'
        
        plot.data << Gnuplot::DataSet.new( [page_x, page_y] ){|ds|
          ds.using = "1:2"
          ds.with = "lp"
          ds.linewidth = "20"
          ds.linecolor = 'rgbcolor "green"'
          ds.title = "page time-chart"
        }
        cnt = 0
        keys_x.each_pair{|key, x|
          plot.data << Gnuplot::DataSet.new( [x, keys_y[key]] ){|ds|
            ds.using = "1:2"
            ds.with = "lp"
            ds.title = "#{key}"
            # ds.linecolor = 'rgbcolor "black"'
            ds.linewidth = "3"
          }
        }
      end
    end
  end
}
