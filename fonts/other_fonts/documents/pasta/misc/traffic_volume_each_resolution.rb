#!/usr/local/bin/ruby

require 'pcap'

require 'optparse'
opt = OptionParser.new
options = {}

options[:outfile_prefix]                 = ''
options[:resolution]                     = 1_000
options[:aggregation_units]              = [1, 10, 100, 1_000, 10_000, 60_000, 100_000, 600_000, 900_000]
options[:max_duration]                   = 60 * 60  # sec
options[:version]                        = ' (HEAD, master) 2015-02-25 14:21:03 +0900 912a25c115fa72646c2450b13daf12e9205986d5'

opt.banner = "Usage: #{File.basename($0)} [options] pcapfiles"
opt.on( '-h'                   , '--help'                                  , 'show help' ) { print opt.help; exit }
opt.on( '-f capture_filter'    , '--capture-filter'               , String , 'set capture filter' ) {|v| options[:capture_filter] = v }
opt.on( '-l prefix'            , '--file-prefix-label prefix'     , String , 'specify file prefix' ) {|v| options[:outfile_prefix] = v + '_' }
opt.on( '-r resolution'        , '--resolution'                   , Integer, 'set resolution. (sec / resolution) means resolution units' ) {|v| options[:resolution] = v.to_i}
opt.on( '-u aggregation_units' , '--aggregation-units'            , Array  , 'set aggregation units in the resolution unit' ) {|v| options[:aggregation_units] = v.map{|m| m.to_i}}
opt.on( '-m max_duration'      , '--max-duration'                 , Integer, 'set max duratoin in sec' ) {|v| options[:max_duration] = v.map{|m| m.to_i}}
opt.on(                          '--version'                      , 'show version' ) { puts options[:version]; exit }
opt.permute!( ARGV )

if ARGV.empty?
  print opt.help
  exit
else
  options[:infiles] = ARGV
end


#### calculate aggregated bps
def calc_bps( time_size, aggregation_unit, resolution )
  aggregated = []
  time_size.each do |l|
    aggregated[l[0] / aggregation_unit] ||= 0
    aggregated[l[0] / aggregation_unit] += l[1]
  end
  aggregated.map{|b| b.to_f * resolution.to_f / aggregation_unit.to_f }
end


begin_time = nil
time_size = []
options[:infiles].uniq.sort.each_with_index do |file, index|
  cap = Pcap::Capture.open_offline( file )
  cap.setfilter options[:capture_filter]
  cap.each do |pkt|
    begin_time ||= pkt.time
    relative_time = ((pkt.time - begin_time) * options[:resolution]).to_i
    time_size << [relative_time, pkt.size * 8]
  end
end

#### output
options[:aggregation_units].each do |unit|
  outfile = File.open( "#{options[:outfile_prefix]}#{sprintf("%010d", unit)}.plt", 'w' )

  outfile.write <<"EOS"
set terminal emf font "Times-Roman" 16 size 1024, 384
set size 1, 1
set offsets 0, 0, -0.5, 0
set xlabel "time [sec]"
set ylabel "throughput [Mbit/sec]"
set style line 1 lc rgb "dark-blue" lt 1 lw 1
set ytics 200
set xtics 300
set nokey
set grid ytics
set xrange [0:#{options[:max_duration]}]
set yrange [0:500]
set output "#{options[:outfile_prefix]}#{sprintf("%010d", unit)}.emf"
plot "-" with steps ls 1
EOS

  calc_bps( time_size, unit, options[:resolution] ).each_with_index do |b, i|
    outfile.write "#{i * unit / options[:resolution].to_f} #{b.to_f ? b / 1_000_000.0 : 0}\n"
  end

  outfile.write "end\n"
end
