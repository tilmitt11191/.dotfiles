# -*- encoding: utf-8 -*-
DNS_PARSER_VERSION = '$Id$'

# DNS Parser
# @abstract Get DNS data that parsed from UDP sessions
module DNSParser
  DNS_SERVER_DST_PORT = 53
  QUESTION_FIELD_START_INDEX = 12
  MAX_DOMAIN_NAME = 255
  SHORT_LENGTH = 2
  LONG_LENGTH = 4
  IPV4_ADDR_LENGTH = 4
  IPV6_ADDR_LENGTH = 16

  RECORD_TYPE = {
    1     => 'A',
    2     => 'NS',
    5     => 'CNAME',
    6     => 'SOA',
    # 7     => 'MB', # experimental
    # 8     => 'MG', # experimental
    # 9     => 'MR', # experimental
    # 10    => 'NULL', # experimental
    11    => 'WKS',
    12    => 'PTR',
    13    => 'HINFO',
    14    => 'MINFO',
    15    => 'MX',
    16    => 'TXT',
    17    => 'RP',
    18    => 'AFSDB',
    24    => 'SIG',
    25    => 'KEY',
    28    => 'AAAA',
    29    => 'LOC',
    33    => 'SRV',
    35    => 'NAPTR',
    36    => 'KX',
    37    => 'CERT',
    39    => 'DNAME',
    41    => 'OPT',
    42    => 'APL',
    43    => 'DS',
    44    => 'SSHFP',
    45    => 'IPSECKEY',
    46    => 'RRSIG',
    47    => 'NSEC',
    48    => 'DNSKEY',
    49    => 'DHCID',
    50    => 'NSEC3',
    51    => 'NSEC3PARAM',
    52    => 'TLSA',
    55    => 'HIP',
    99    => 'SPF',
    249   => 'TKEY',
    250   => 'TSIG',
    251   => 'IXFR',
    252   => 'AXFR',
    253   => 'MAILB',
    254   => 'MAILA',
    255   => 'ANY',
    257   => 'CAA',
    32769 => 'DLV',
    32768 => 'TA'
  }
  RECORD_TYPE.default = ''

  RECORD_CLASS = {
    1 => 'IN',
    2 => 'CS',
    3 => 'CH',
    4 => 'HS'
  }
  RECORD_CLASS.default = ''

  RDATA_OF_RR = {
    'A'     => [:address],
    'AAAA'  => [:address],
    'CNAME' => [:cname],
    'HINFO' => [:cpu, :os],
    'MX'    => [:preference, :exchange],
    'NS'    => [:nsdata],
    'PTR'   => [:ptrdname],
    'SOA'   => [:mname, :rname, :serial, :refresh, :retry, :expire, :minimum],
    'SRV'   => [:priority, :weight, :port, :target],
    'TXT'   => [:txt_data]
  }
  RDATA_OF_RR.default = []

  HEADER_FIELD_INDEX = {
    # [Start Index , Size(byte)]
    :qdcount => [4, SHORT_LENGTH], # Question Count
    :ancount => [6, SHORT_LENGTH], # Answer Count
    :nscount => [8, SHORT_LENGTH], # Authority Name Server Count
    :arcount => [10, SHORT_LENGTH] # Additional Count
  }

  # Get parsed DNS data.
  # @param  [String]  dns_query  DNS query
  # @return [Hash]    Return parsed DNS data
  def get_parsed_dns( dns_query )
    begin
      parsed_dns = {
        :index => 0,
        :domain_name_dictionary => [],
        :dns_header_field => Hash.new(),
        :question_section => Hash.new(),
        :answer_section => Hash.new(),
        :authority_section => Hash.new(),
        :additional_section => Hash.new()
       }

      parsed_dns[:dns_header_field] = get_header_section(dns_query)
      parsed_dns[:index] = QUESTION_FIELD_START_INDEX
      parsed_dns[:question_section] = get_question_section(dns_query, parsed_dns)
      parsed_dns[:answer_section] = get_answer_resource_record(dns_query, parsed_dns)
      parsed_dns[:authority_section] = get_authority_resource_record(dns_query, parsed_dns)
      parsed_dns[:additional_section] = get_additional_resource_record(dns_query, parsed_dns)
    rescue
    end
    parsed_dns
  end

  # Search rdata values from Resource Record Table.
  # @param  [String]  rr   Resource Record
  # @return [Array]   Return RDATA array of searched result
  def search_rdata_type( rr )
    rdata_ary = []
    RDATA_OF_RR[rr[:type]].each{|rdata_type|
      rdata_ary << [rdata_type, rr[rdata_type]]
     }
    rdata_ary
  end

  # Get values of Header field.
  # @param  [String]  dns_query   DNS query
  # @return [Hash]    Return DNS Heder Filed
  def get_header_section(dns_query)
    header_section = {}
    HEADER_FIELD_INDEX.each do |header, index|
      header_section[header] = dns_query[index[0], index[1]].unpack("n")[0]
    end
    return header_section
  end
  private :get_header_section

  # Get values of Questions Field.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @return [Hash]    Return DNS Question Field
  def get_question_section(dns_query, parsed_dns)
    question = {}
    question_section = []
    qdcount = parsed_dns[:dns_header_field][:qdcount]
    return if qdcount == 0
    for cnt in 0..qdcount-1
      question = {
        :qname => get_name(dns_query, parsed_dns),
        :qtype => get_type(dns_query, parsed_dns),
        :qclass => get_class(dns_query, parsed_dns)}
        question_section << question
    end
    question_section
  end
  private :get_question_section

  # Get Answer Filed of Resource Record.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @return [Hash]    Return DNS Answer Filed of Resource Record
  def get_answer_resource_record(dns_query, parsed_dns)
    ancount = parsed_dns[:dns_header_field][:ancount]
    return nil if ancount == 0
    get_resource_record(dns_query, ancount, parsed_dns)
  end
  private :get_answer_resource_record

  # Parse Authority Filed of Resource Record.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @return [Hash]    Return DNS Authority Filed of Resource Record
  def get_authority_resource_record(dns_query, parsed_dns)
    nscount = parsed_dns[:dns_header_field][:nscount]
    return nil if nscount == 0
    get_resource_record(dns_query, nscount, parsed_dns)
  end
  private :get_authority_resource_record

  # Get Additional Filed of Resource Record.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @return [Hash]    Return DNS Additional Filed of Resource Record
  def get_additional_resource_record(dns_query, parsed_dns)
    arcount = parsed_dns[:dns_header_field][:arcount]
    return nil if arcount == 0
    get_resource_record(dns_query, arcount, parsed_dns)
  end
  private :get_additional_resource_record

  # Get Resource Record.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  def get_resource_record(dns_query, count, parsed_dns)
    resource_record = []
    (0..count-1).each{
      resource_record << get_rdata(dns_query, parsed_dns)
    }
    return resource_record
  end
  private :get_resource_record

  # Get RDATA.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  def get_rdata(dns_query, parsed_dns)
    resource_record = {}
    resource_record[:name] = get_name(dns_query, parsed_dns)
    resource_record[:type] = get_type(dns_query, parsed_dns)
    resource_record[:class] = get_class(dns_query, parsed_dns)
    resource_record[:ttl] = get_rdata_value(dns_query, parsed_dns, LONG_LENGTH)
    resource_record[:rdlength] = get_rdata_value(dns_query, parsed_dns, SHORT_LENGTH)

    case resource_record[:type]
    when 'A'
      a_record(dns_query, parsed_dns, resource_record)
    when 'AAAA'
      aaaa_record(dns_query, parsed_dns, resource_record)
    when 'CNAME'
      cname_record(dns_query, parsed_dns, resource_record)
    when 'HINFO'
      hinfo_record(dns_query, parsed_dns, resource_record)
    when 'MX'
      mx_record(dns_query, parsed_dns, resource_record)
    when 'NS'
      ns_record(dns_query, parsed_dns, resource_record)
    when 'PTR'
      ptr_record(dns_query, parsed_dns, resource_record)
    when 'SOA'
      soa_record(dns_query, parsed_dns, resource_record)
    when 'SRV'
      srv_record(dns_query, parsed_dns, resource_record)
    when 'TXT'
      txt_record(dns_query, parsed_dns, resource_record)
    else
      parsed_dns[:index] += resource_record[:rdlength]
    end
    return resource_record
  end
  private :get_rdata

  # Get A record.
  # @param  [String]  dns_query  DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @param  [Hash]    Parsing Resource Record data
  def a_record(dns_query, parsed_dns, resource_record)
    resource_record[:address] = get_ipaddr(dns_query, parsed_dns, IPV4_ADDR_LENGTH)
  end
  private :a_record

  # Get AAAA record.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @param  [Hash]    Parsing Resource Record data
  def aaaa_record(dns_query, parsed_dns, resource_record)
    resource_record[:address] = get_ipaddr(dns_query, parsed_dns, IPV6_ADDR_LENGTH)
  end
  private :aaaa_record

  # Get CNAME record.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @param  [Hash]    Parsing Resource Record data
  def cname_record(dns_query, parsed_dns, resource_record)
    resource_record[:cname] = get_name(dns_query, parsed_dns)
  end
  private :cname_record

  # Get HINFO record.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @param  [Hash]    Parsing Resource Record data
  def hinfo_record(dns_query, parsed_dns, resource_record)
    resource_record[:cpu] = get_string(dns_query, parsed_dns)
    resource_record[:os] = get_string(dns_query, parsed_dns)
  end
  private :hinfo_record

  # Get MX record.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @param  [Hash]    Parsing Resource Record data
  def mx_record(dns_query, parsed_dns, resource_record)
    resource_record[:preference] = get_rdata_value(dns_query, parsed_dns, SHORT_LENGTH)
    resource_record[:exchange] = get_name(dns_query, parsed_dns)
  end
  private :mx_record

  # Get NS record.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @param  [Hash]    Parsing Resource Record data
  def ns_record(dns_query, parsed_dns, resource_record)
    resource_record[:nsdname] = get_name(dns_query, parsed_dns)
  end
  private :ns_record

  # Get PTR record.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @param  [Hash]    Parsing Resource Record data
  def ptr_record(dns_query, parsed_dns, resource_record)
    resource_record[:ptrdname] = get_name(dns_query, parsed_dns)
  end
  private :ptr_record

  # Get SOA record.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @param  [Hash]    Parsing Resource Record data
  def soa_record(dns_query, parsed_dns, resource_record)
    resource_record[:mname] = get_name(dns_query, parsed_dns)
    resource_record[:rname] = get_name(dns_query, parsed_dns)
    [:serial, :refresh, :retry, :expire, :minimum].each do |field| 
      resource_record[field] = get_rdata_value(dns_query, parsed_dns, SHORT_LENGTH)
    end
  end
  private :soa_record

  # Get SRV record.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @param  [Hash]    Parsing Resource Record data
  def srv_record(dns_query, parsed_dns, resource_record)
    [:priority, :weight, :port].each do |field| 
      resource_record[field] = get_rdata_value(dns_query, parsed_dns, SHORT_LENGTH)
    end
    resource_record[:target] = get_name(dns_query, parsed_dns)
  end
  private :srv_record

  # Get TXT record.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @param  [Hash]    Parsing Resource Record data
  def txt_record(dns_query, parsed_dns, resource_record)
    resource_record[:txt_data] = get_string(dns_query, parsed_dns)
  end
  private :txt_record

  # Get NAME of RDATA.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @return [String]  Return NAME of RDATA
  def get_name(dns_query, parsed_dns)
    domain_array = []
    for l in 0 .. MAX_DOMAIN_NAME
      domain_str_num = dns_query[parsed_dns[:index]].unpack("C")[0]
      if (domain_str_num & 0xc0) == 0xc0
        buf = compression_domain_name(dns_query, parsed_dns)
        parsed_dns[:domain_name_dictionary] << {:first_index => parsed_dns[:index], :domain_name => buf}
        domain_array << buf
        parsed_dns[:index] += SHORT_LENGTH
        break
      else
        break unless create_domain_array(dns_query, parsed_dns, domain_str_num, domain_array)
      end
    end
    return create_domain_name(domain_array)
  end
  private :get_name

  # Create the array of Domain name string.
  # @param  [String]  dns_query       DNS query
  # @param  [Hash]    parsed_dns      Parsing DNS data
  # @param  [Integer] domain_str_num  Number of Domain name strings
  # @param  [Array]   domain_array    Array of Domain name strings
  def create_domain_array(dns_query, parsed_dns, domain_str_num, domain_array)
    buf = create_domain_string(dns_query, parsed_dns, domain_str_num)
    return nil unless buf
    domain_array << buf
  end
  private :create_domain_array

  # Converts ths UDP data, and create a string of Domain name.
  # @param  [String]  dns_query       DNS query
  # @param  [Hash]    parsed_dns      Parsing DNS data
  # @param  [Integer] domain_str_num  Number of Domain name strings
  # @return [String]  Return strings parsed UDP packet
  def create_domain_string(dns_query, parsed_dns, domain_str_num)
    buf = ""
    dns_query[parsed_dns[:index] + 1, domain_str_num].unpack("C*").each{|c| buf << sprintf("%c", c)} unless domain_str_num == 0
    buf = nil if buf == ""
    parsed_dns[:domain_name_dictionary] << {:first_index => parsed_dns[:index], :domain_name => buf}
    parsed_dns[:index] += domain_str_num + 1
    return buf
  end
  private :create_domain_string

  # Join array of Domain strings, create a domain name.
  # @param  [Array]   domain_array    Array of Domain name strings
  # @return [String]  Return joined Domain name
  def create_domain_name(domain_array)
    domain = domain_array.join('.')
    domain.encode!("US-ASCII", :invalid => :replace, :undef => :replace, :replace => '?')
    domain = '?' unless /[\w-]+(\.[\w-]+)+/ =~ domain
    return domain
  end
  private :create_domain_name

  # Get Domain name from Compression Message.
  # @param  [String]  dns_query       DNS query
  # @param  [Hash]    parsed_dns      Parsing DNS data
  # @return [String]  Return searched Domain name
  def compression_domain_name(dns_query, parsed_dns)
    buf = ""
    domain_array = []
    offset = dns_query[parsed_dns[:index],SHORT_LENGTH].unpack("n")[0] & 0x3fff

    parsed_dns[:domain_name_dictionary].each do |domain_info|
      if domain_info[:first_index] >= offset
        domain_array << domain_info[:domain_name]
        break if domain_info[:domain_name].nil? or domain_info[:domain_name].include?(".")
      end
    end
    domain = domain_array.compact.join('.')
    return domain
  end
  private :compression_domain_name

  # Get String data of RDATA.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @return Return string data of RDATA
  def get_string(dns_query, parsed_dns)
    str_num = dns_query[parsed_dns[:index]].unpack("C")[0]
    str = dns_query[parsed_dns[:index] + 1, str_num]
    str.encode!("US-ASCII", :invalid => :replace, :undef => :replace, :replace => '?')
    parsed_dns[:index] += str_num + 1
    return str
  end
  private :get_string

  # Get IP address of RDATA.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @param  [Integer] length      Target length
  # @return Return IP address of RDATA
  def get_ipaddr(dns_query, parsed_dns, length)
    address = ""
    case length
    when IPV4_ADDR_LENGTH
      address = dns_query[parsed_dns[:index], length].unpack("CCCC").join('.')
    when IPV6_ADDR_LENGTH
      address = dns_query[parsed_dns[:index], length].unpack("nnnnnnnn").map{|v| sprintf("%x", v)}.join(':')
    end
    parsed_dns[:index] += length
    return address
  end
  private :get_ipaddr

  # Get TYPE of RDATA.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @return Return type name of RDATA
  def get_type(dns_query, parsed_dns)
    RECORD_TYPE[get_rdata_value(dns_query, parsed_dns, SHORT_LENGTH).to_i]
  end
  private :get_type

  # Get CLASS of RDATA.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @return Return class name of RDATA
  def get_class(dns_query, parsed_dns)
    RECORD_CLASS[get_rdata_value(dns_query, parsed_dns, SHORT_LENGTH).to_i]
  end
  private :get_class

  # Get the integer value of RDATA.
  # @param  [String]  dns_query   DNS query
  # @param  [Hash]    parsed_dns  Parsing DNS data
  # @param  [Integer] length      Target length
  # @return Return value of RDATA
  def get_rdata_value(dns_query, parsed_dns, length)
    template = length == LONG_LENGTH ? "N" : "n"
    value = dns_query[parsed_dns[:index], length].unpack(template)[0]
    parsed_dns[:index] += length
    return value
  end
  private :get_rdata_value

end
