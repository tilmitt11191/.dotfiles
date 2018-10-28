# -*- encoding: utf-8 -*-
#!/usr/bin/env ruby
# coding: ascii-8bit

require "#{File.dirname(__FILE__)}/../http_parser.rb"

svn_revision_check = HTTP_PARSER_VERSION.split()
if svn_revision_check[2].to_i > 630
  require "#{File.dirname(__FILE__)}/../video_container_parser.rb"
end

exit if ARGV.size != 1

options = {
  "plain_text" => true,
  "hash_salt" => 'example'
}
 
request = {
  "headers" => {"Host" => 'gdata.youtube'},
  "path" => "test_pass"
}

response = {
  "headers" => {"Content-Type" => '/application/atom+xml. type=feed/i'},
  "body" => File.open(ARGV[0], :encoding => Encoding::ASCII_8BIT),
  "path" => 'test_pass'
}
hp = HTTPParser.new(options["plain_text"], options["hash_salt"])
parsed = hp.parse_youtube_feed(request, response)
p parsed