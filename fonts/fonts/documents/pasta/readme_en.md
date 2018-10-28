# Primary analysis tool (analyze_pcap.rb)

analyze_pcap.rb analyzes tcp/http/ssl session, udp session, and traffic volume per unit of time from pcap files, and output results in csv format.

## Functional specification

### Before use

analyze_pcap.rb is teted on ruby 1.9.3.

analyze_pcap.rb ensures performance only on ruby 1.9.3. analyze_pcap.rb never work on ruby 1.8.x. analyze_pcap.rb may work on ruby 2.0.x, which is compatible with ruby 1.9.x, but not guaranteed.

analyze_pcap.rb requires ruby-pcap library which is provided under the directory ruby-pcap/.

analyze_pcap.rb requires hpricot library which is provided under the directory hpricot/.

When Facter library is installed, analyze_pcap detect the number of processors to create appropriate number of child processes automatically. However, if -c/--max-child-processes option is set, they have a priority. Note that amount of memory is not calculated.

analyze_pcap.rb requires the following files included.

* tcp_sessions.rb
* http_parser.rb
* video_container_parser.rb
* udp_sessions.rb
* dns_parser.rb
* traffic_volume.rb
* gtp_parser.rb
* gtp_ie_parser.rb
* gtp_msg_parser.rb

### How to use

#### General usage

    Usage: analyze_pcap.rb [options] pcapfiles
        -h, --help                       show help
        -c processes,                    set number of maximum child processes
            --max-child-processes
        -d, --output-debug-file          enable debug output
        -f, --omit-field-names           omit field names in first row
        -i time,                         set timeout check interval in sec
            --timeout-check-interval
        -l, --file-prefix-label prefix   specify file prefix
        -o, --half-close-timeout time    set half close timeout in sec
        -p, --http-ports ports           set destination ports for HTTP in comma separated format
        -q, --ssl-ports ports            set destination ports for HTTP/SSL in comma separated format
        -r, --cancel-remaining-sessions  cancel remaining sessions at the end of process
        -s, --sampling-ratio ratio       enable source IP address based sampling
        -t, --tcp-timeout time           set tcp timeout in sec
        -u, --udp-timeout time           set udp timeout in sec
        -v [time],                       output traffic volume time. time unit can be set in sec
            --output-traffic-volume
            --no-corresponding-response  output results even if corresponding response is not found
            --plain-text                 do not hash source ip address
            --on-the-fly-threshold packets
                                         set on-the-fly threshold
            --ipv4-subnet-prefix-length length
                                         set subnet prefix length for IPv4
            --ipv6-subnet-prefix-length length
                                         set subnet prefix length for IPv6
            --gtp-all                    output all gtp parameter
            --version                    show version

#### Input pcap files

Input pcap files shuld be given as arguments. The given files will be sorted in dictionary order before processing. Thus, input pcap files must have correctly ordered file names.

#### Output

analyze_pcap.rb output the following files.

* log_*.txt: log file
* tcp_*.csv: result of tcp/http/ssl analysis
* udp_*.csv: result of udp analysis
* gtp_*.csv: result of gtp analysis
* debug_*.txt: debug output (only when -d/--output-debug-file options is set)
* volume_*.csv: traffic volume per unit of time (only when -v/--output-traffic-volume option is set)

Note the following related specification.

* anayze_pcap.rb outputs files into current directory by default. File names are determined from execution date and time ('tcp_[YYYYMMDD-hhmmss].csv', 'log_[YYYYMMDD-hhmmss].txt', etc).
    * When you need to add a prefix or specify output directory, use -l/--file-prefix-label option.
* When -d/--output-debug-file option is given, analyze_pcap.rb outputs raw data of HTTP body ('debug_[YYYYMMDD-hhmmss].csv'). Be careful with the option because the debug output may be excessively large and may include personal data.
* Peronal data including IP addresses is hashed with a ramdom salt. If you need plain data of them, use --plain-text option.

#### Target of analysis

analyze_pcap.rb targets all of TCP and UDP sessions. When the TCP session is a HTTP session, analyze_pcap.rb analyzes HTTP protocol too.

* Use -p/--http-ports option to specify HTTP port. Only when the port number is 80 or 8080, the session is recognized as a HTTP session by default.
* Use -q/--ssl-ports option to specif SSL port. Only when the port number is 443 or 8443, the session is recognized as a SSL session by default.

analyze_pcap.rb analyze all sessions by default, but you can sample the sessions by -s/--sampling-ratio option.

#### TCP sessions

When no packet is detected for a period, analyze_pcap.rb assumes that the TCP session is closed unexpectedly. -t/--tcp-timeout time option gives timeout threshold and -i/--timeout-check-interval gives timeout check interval. The timeout check is available even in half-close state. The timeout threshold in half-close state, which is set by -o/--half-close-timeout option, is independent from general tcp timeout threshold.

At the last of the process, analyze_pcap.rb close all of the remaining sessions forcefully. When -r/--cancel-remaining-sessions option is given, all of the remaining sessions are discarded instead.

#### UDP sessions

UDP is a sessionless protocol, but analyze_pcap.rb defines UDP session as a set of UDP packets they have the same IP addresses and port numbers for conveniense sake. UDP sessions can be timeouted just like TCP sessions. The timeout threshould is set by -u/--udp-timeout option. Note that the timeout check interval is shared with the interval for TCP sessions.

At the last of the process, analyze_pcap.rb close all of the remaining sessions forcefully. When -r/--cancel-remaining-sessions option, which is shared with TCP sessions, is set, all of the remaining sessions are discarded instead.

The direction of the session is detected automatically based on the appearance frequency of SYN packets and SYN+ACK packets.

#### Traffic volume

When -v/--output-traffic-volume option is set, analyze_pcap.rb outputs traffic volume per unit of time. Unit of time is 1 sec by default, however you can overwrite it with an argument put after -v/--output-traffic-volume option. Note that the first and last slot may be unreliable.

The direction of the traffic volume is detected automatically based on the appearance frequency of SYN packets and SYN+ACK packets.

#### Parallel processing

analyze_pcap.rb create child processes to process the pcap files in parallel. Maximum number of child processes is set by -c/--max-child-processes option.

* When max number of child process is less than 1, no child process will be created.
* Note that many child processes can strain memory

## Technical specification

### Documentation

Major classes and modules includes documents in YARD format.

### Reconstruction of TCP sessions

analyze_pcap.rb recunstruct TCP sessions at first step.

* analyze_pcap.rb analyzes TCP sessions whose handshake is detected. 
* Resent packets are counted separately from normal packets
* Reordered packets are sorted automatically. analyze_pcap.rb also handles SACK packets.

### HTTP parser

When a HTTP session is closed, HTTP parser parses body part of the HTTP session and output the result to csv file.

* Please refer http_csv_format.xlsx for information on output file format
* HTTP parser output the result only when a pair of request/response headers is found. When only request is detected, analyze_pcap.rb outputs nothing.
    * When --no-corresponding-response options is set, analyze_pcap.rb outputs HTTP sessions they include only HTTP responses.

### GTPv2-C parser

When an address port number uses GTP port number (2123), in a UDP packet, analyze the GTPv2-C packet.
The GTPv2-C is a sessionless protocol as well as a UDP packet, but analyze_pcap.rb defines a group of request/response as 1 session with the same sequence number.
* Please refer to output_csv_format.xlsx for information on output file format.
* A detailed analysis result is output by appointing --gtp-all option.
* Personal data including IP addresses(PAA) and terminal identifieris(IMSI_MSIN) hashed with a random salt. If you need plain data of them, use --plain-text option.
* The message type of targeted for analysis is Create Session Request/Response, Modify Bearer Request/Response.The message excluding it is ignored.
* GTP parser output the result only when a pair of request/response headers is found. At the last of the process, analyze_pcap.rb close all of the remaining sessions forcefully. When -r/--cancel-remaining-sessions option is given, all of the remaining sessions are discarded instead.

### Miscellaneous

#### HTML5

* analyze_pcap.rb scans body part of each HTTP sessions to check if HTML5 related techniques are used.

#### Videos

* analyze_pcap.rb scans video containers to analyze video information when the video container is ISO/IEC 14496-12 (ISO base media file format) or FLV or ISO/IEC 13818-1 (only MPEG-2 TS/TTS).
