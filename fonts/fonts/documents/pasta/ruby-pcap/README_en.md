# ruby-pcap

## Installation
ruby-pcap is a ruby extension to LBL libpcap (Packet Capture library).
This library also includes classes to access TCP/IP header.


##Requirements
  - ruby-1.9.3
  - libpcap (http://www.tcpdump.org/)
  - rdoc (4.0.1~)

## Pre-Installation
** Make sure that previous version of pcap(ruby-pcap) is not installed with the following command **

`gem list`

** Uninstall if you have installed **

`sudo gem uninstall pcap`

** Update rdoc **

In the case of the version of rdoc 4.0.1 below, you may receive an error the following may appear in the document ri generated.

 - Enclosing class/module 'xxx' for class xxx not known
 - Enclosing class/module 'xxx' for module xxx not known
 - Enclosing class/module 'xxx' for alias xxx xxx not known

Make sure that the version of rdoc is 4.0.1 or more, please re-install the pcap again.

##Compile:

* If 'rake' and 'rubygems' is installed, following commands will install ruby-pcap.

* Reference Manual will be generated in the 'doc' directory.

`rake`

`rake build`

`sudo gem install pkg/pcap_[yyyymmdd].[hash].gem`

## Usage

See the Reference Manual under the directory 'doc' or some Gem installation.

Directory 'examples' contains some simple scripts.

# Author

Masaki Fukushima <fukusima@goto.info.waseda.ac.jp>

 Modifications by
Andrew Hobson <ahobson@gmail.com>

 OS X and Ruby 1.9.2 support by
Tim Jarratt <tjarratt@gmail.com>

 Performance Improvements and other great contributes by
Ilya Maykov

ruby-pcap is copyrighted free software by Masaki Fukushima.

# LICENSE
You can redistribute it and/or modify it under the terms of
the GPL (GNU GENERAL PUBLIC LICENSE).  See COPYING file about GPL.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  See the GPL for
more details.