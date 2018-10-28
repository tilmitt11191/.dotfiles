/*
 *  ip_packet.c
 *
 *  Copyright (C) 1998, 1999  Masaki Fukushima
 */

#include "ruby_pcap.h"
#include <netdb.h>
#include <arpa/inet.h>

VALUE cIPPacket;
static VALUE cIPAddr;

static VALUE setup_ip_packet_class_ipv4(struct packet_object *pkt, int nl_len);
static VALUE setup_ip_packet_class_ipv6(struct packet_object *pkt, int nl_len);
static int get_last_extension_header_offset(struct ip6_hdr *ipv6);
static VALUE get_extension_header_array(struct ip6_hdr *ipv6);
static VALUE new_ipaddr_int(struct in_addr *addr);
static VALUE new_ipaddr_str(struct in_addr *addr);
static VALUE new_ipv6addr_int(struct in6_addr *addr);
static VALUE new_ipv6addr_str(struct in6_addr *addr);

#define CheckTruncateIp(pkt, need) \
    CheckTruncate(pkt, pkt->hdr.layer3_off, need, "truncated IP")

VALUE
setup_ip_packet(struct packet_object *pkt, int nl_len)
{
    VALUE class;
    int header_len, version;

    DEBUG_PRINT("setup_ip_packet");
    version = (IP_HDR(pkt)->ip_v);
    if ((nl_len > 0) && ((version != 4) && (version != 6))) {
        return cPacket;
    }

    if(version == 4){
        class = setup_ip_packet_class_ipv4(pkt, nl_len);
    }
    else if(version == 6){
        class = setup_ip_packet_class_ipv6(pkt, nl_len);
    }
    else{
        class = cIPPacket;
    }
    return class;
}

static VALUE
setup_ip_packet_class_ipv4(struct packet_object *pkt, int nl_len)
{
    VALUE class = cIPPacket;
    struct ip *ipv4;
    int header_len, payload_len;

    ipv4 = IP_HDR(pkt);
    nl_len = MIN(nl_len, ntohs(ipv4->ip_len));
    if (nl_len <= IP4_HDR_SIZE) {
        return class;
    }
    header_len = ipv4->ip_hl * 4;
    payload_len = nl_len - header_len;
    if (payload_len <= 0) {
        return class;
    }
    pkt->hdr.layer4_off = pkt->hdr.layer3_off + header_len;
    if ((ntohs(ipv4->ip_off) & IP_OFFMASK) != 0) {
        return class;
    }
    /* if this is fragment zero, setup upper layer */
    switch (ipv4->ip_p) {
    case IPPROTO_TCP:
        class = setup_tcp_packet(pkt, payload_len);
        break;
    case IPPROTO_UDP:
        class = setup_udp_packet(pkt, payload_len);
        break;
    case IPPROTO_ICMP:
        class = setup_icmp_packet(pkt, payload_len);
        break;
    }
    return class;
}

static VALUE
setup_ip_packet_class_ipv6(struct packet_object *pkt, int nl_len)
{
    VALUE class = cIPPacket;
    VALUE next_header_array;
    struct ip6_hdr *ipv6;
    int last_next_header, total_len, header_len, payload_len;

    ipv6 = IPv6_HDR(pkt);
    total_len = ntohs(ipv6->ip6_plen) + IP6_HDR_SIZE;
    nl_len = MIN(nl_len, total_len);
    if (nl_len <= IP6_HDR_SIZE) {
        return class;
    }
    header_len = get_last_extension_header_offset(ipv6);
    payload_len = nl_len - header_len;
    if (payload_len <= 0) {
        return class;
    }
    pkt->hdr.layer4_off = pkt->hdr.layer3_off + header_len;
    next_header_array = get_extension_header_array(ipv6);
    last_next_header = NUM2UINT(rb_funcall(next_header_array, rb_intern("last"), 0));
    /* if this is fragment zero, setup upper layer */
    switch (last_next_header) {
    case IPPROTO_TCP:
        class = setup_tcp_packet(pkt, payload_len);
        break;
    case IPPROTO_UDP:
        class = setup_udp_packet(pkt, payload_len);
        break;
    case IPPROTO_ICMP:
        class = setup_icmp_packet(pkt, payload_len);
        break;
    }
    return class;
}

/* Return IP version. */
static VALUE ipp_ver(VALUE self);
/* Return  true if IP version is IPv4. */
static VALUE ipp_ver4(VALUE self);
/* Return  true if IP version is IPv6. */
static VALUE ipp_ver6(VALUE self);
/* Return header length. (Unit: 4 octets) IPv4 only. */
static VALUE ipp_hlen(VALUE self);
/* Return header length. (Unit: octet) */
static VALUE ipp_header_length(VALUE self);
/* Return payload length. (Unit: octets) */
static VALUE ipp_payload_length(VALUE self);
/* Return payload length. (Unit: octets) IPv6 only. */
static VALUE ipp_plen(VALUE self);
/* Return the value of TOS field. */
static VALUE ipp_tos(VALUE self);
/* Return total length. IPv4 only. */
static VALUE ipp_len(VALUE self);
/* Return total length. */
static VALUE ipp_total_length(VALUE self);
/* Return identification. */
static VALUE ipp_id(VALUE self);
/* Return the value of 3-bits IP flag field. IPv4 only. */
static VALUE ipp_flags(VALUE self);
/* Return true if Don't Fragment bit is set. IPv4 only. */
static VALUE ipp_df(VALUE self);
/* Return true if More Fragment bit is set. IPv4 only. */
static VALUE ipp_mf(VALUE self);
/* Return fragment offset. IPv4 only. */
static VALUE ipp_off(VALUE self);
/* Return TTL of IPv4 or Hoplimit field of IPv6. */
static VALUE ipp_ttl(VALUE self);
/* Return the value of protocol field. IPv4 only. */
static VALUE ipp_proto(VALUE self);
/* Return the value of checksum field. IPv4 only. */
static VALUE ipp_sum(VALUE self);
/* Return the value of flow field. IPv6 only. */
static VALUE ipp_flow(VALUE self);
/* Return source IP address as {http://www.ruby-doc.org/core-1.9.3/Integer.html Integer}. */
static VALUE ipp_src_int(VALUE self);
/* Return destination IP address as {http://www.ruby-doc.org/core-1.9.3/Integer.html Integer}. */
static VALUE ipp_dst_int(VALUE self);
/* Return source IP address as {http://www.ruby-doc.org/core-1.9.3/String.html String}. */
static VALUE ipp_src_str(VALUE self);
/* Return destination IP address as {http://www.ruby-doc.org/core-1.9.3/String.html String}. */
static VALUE ipp_dst_str(VALUE self);
/* Return next headers as {http://www.ruby-doc.org/core-1.9.3/Array.html Array}. IPv6 only. */
static VALUE ipp_next(VALUE self);

#define IPP_METHOD_V4(func, need, val) \
static VALUE\
(func)(VALUE self)\
{\
    struct packet_object *pkt;\
    struct ip *ip;\
\
    DEBUG_PRINT(#func);\
    GetPacket(self, pkt);\
    if(ip_version(self) != 4){\
        return Qnil;\
    }\
    CheckTruncateIp(pkt, (need));\
    ip = IP_HDR(pkt);\
    return (val);\
}

IPP_METHOD_V4(ipp_hlen,   1,  INT2FIX(ip->ip_hl))
IPP_METHOD_V4(ipp_len,    4,  INT2FIX(ntohs(ip->ip_len)))
IPP_METHOD_V4(ipp_id,     6,  INT2FIX(ntohs(ip->ip_id)))
IPP_METHOD_V4(ipp_flags,  8,  INT2FIX((ntohs(ip->ip_off) & ~IP_OFFMASK) >> 13))
IPP_METHOD_V4(ipp_df,     8,  (ntohs(ip->ip_off) & IP_DF) ? Qtrue : Qfalse)
IPP_METHOD_V4(ipp_mf,     8,  (ntohs(ip->ip_off) & IP_MF) ? Qtrue : Qfalse)
IPP_METHOD_V4(ipp_off,    8,  INT2FIX(ntohs(ip->ip_off) & IP_OFFMASK))
IPP_METHOD_V4(ipp_proto,  10, INT2FIX(ip->ip_p))
IPP_METHOD_V4(ipp_sum,    12, INT2FIX(ip->ip_sum))

#define IPP_METHOD_V6(func, need, val) \
static VALUE\
(func)(VALUE self)\
{\
    struct packet_object *pkt;\
    struct ip6_hdr *ipv6;\
\
    DEBUG_PRINT(#func);\
    GetPacket(self, pkt);\
    if(ip_version(self) != 6){\
        return Qnil;\
    }\
    CheckTruncateIp(pkt, (need));\
    ipv6 = IPv6_HDR(pkt);\
    return (val);\
}

IPP_METHOD_V6(ipp_flow, 4, INT2FIX((ntohs(ipv6->ip6_flow) & FLOW_LABEL_MASK_V6) >> 16))
IPP_METHOD_V6(ipp_plen, 6, INT2FIX(ntohs(ipv6->ip6_plen)))
IPP_METHOD_V6(ipp_next, 7, get_extension_header_array(ipv6))

#define IPP_METHOD_COMMON(func, need_v4, val_v4, need_v6, val_v6) \
static VALUE\
(func)(VALUE self)\
{\
    struct packet_object *pkt;\
    struct ip *ipv4;\
    struct ip6_hdr *ipv6;\
    int version;\
    VALUE ret;\
\
    DEBUG_PRINT(#func);\
    version = ip_version(self);\
    GetPacket(self, pkt);\
    if(version == 4){\
        CheckTruncateIp(pkt, (need_v4));\
        ipv4 = IP_HDR(pkt);\
        ret = (val_v4);\
    }\
    else if(version == 6){\
        CheckTruncateIp(pkt, (need_v6));\
        ipv6 = IPv6_HDR(pkt);\
        ret = (val_v6);\
    }\
    else{\
        ret = Qnil;\
    }\
    return ret;\
}

IPP_METHOD_COMMON(ipp_tos,            2,  INT2FIX(ipv4->ip_tos),          2,  INT2FIX(((ntohs(ipv6->ip6_flow) & TRAFFIC_CLASS_MASK_V6) >> 4)))
IPP_METHOD_COMMON(ipp_ttl,            9,  INT2FIX(ipv4->ip_ttl),          8,  INT2FIX(ipv6->ip6_hlim))
IPP_METHOD_COMMON(ipp_src_int,       16,  new_ipaddr_int(&ipv4->ip_src), 24,  new_ipv6addr_int(&ipv6->ip6_src))
IPP_METHOD_COMMON(ipp_src_str,       16,  new_ipaddr_str(&ipv4->ip_src), 24,  new_ipv6addr_str(&ipv6->ip6_src))
IPP_METHOD_COMMON(ipp_dst_int,       20,  new_ipaddr_int(&ipv4->ip_dst), 40,  new_ipv6addr_int(&ipv6->ip6_dst))
IPP_METHOD_COMMON(ipp_dst_str,       20,  new_ipaddr_str(&ipv4->ip_dst), 40,  new_ipv6addr_str(&ipv6->ip6_dst))
IPP_METHOD_COMMON(ipp_header_length,  1,  INT2FIX((ipv4->ip_hl) * 4),     7,  INT2FIX(get_last_extension_header_offset(ipv6)))
IPP_METHOD_COMMON(ipp_payload_length, 4,  INT2FIX(get_payload_length_ipv4(ipv4)), 6,  INT2FIX(get_payload_length_ipv6(ipv6)))
IPP_METHOD_COMMON(ipp_total_length,   4,  INT2FIX(ntohs(ipv4->ip_len)),   6,  INT2FIX(ntohs(ipv6->ip6_plen) + IP6_HDR_SIZE))


#define IPP_METHOD_VERSION(func, need, val) \
static VALUE\
(func)(VALUE self)\
{\
    struct packet_object *pkt;\
    struct ip *ip;\
\
    DEBUG_PRINT(#func);\
    GetPacket(self, pkt);\
    CheckTruncateIp(pkt, (need));\
    ip = IP_HDR(pkt);\
    return (val);\
}

IPP_METHOD_VERSION(ipp_ver,   1, INT2FIX(ip->ip_v))
IPP_METHOD_VERSION(ipp_ver4,  1, (ip_version(self) == 4) ? Qtrue : Qfalse)
IPP_METHOD_VERSION(ipp_ver6,  1, (ip_version(self) == 6) ? Qtrue : Qfalse)

char
ip_version(VALUE self)
{
    struct packet_object *pkt;
    struct ip *ipv4;

    GetPacket(self, pkt);
    ipv4 = IP_HDR(pkt);
    return ipv4->ip_v;
}

int 
get_payload_length_ipv4(struct ip *ipv4)
{
    return ntohs(ipv4->ip_len) - ((ipv4->ip_hl) * 4);
}

int
get_payload_length_ipv6(struct ip6_hdr *ipv6)
{
    int offset, payload_length;

    offset = get_last_extension_header_offset(ipv6);
    payload_length = IP6_HDR_SIZE + ntohs(ipv6->ip6_plen) - offset;
    return payload_length;
}

int
get_total_length(struct packet_object *pkt)
{
    struct ip *ipv4;
    struct ip6_hdr *ipv6;

    ipv4 = IP_HDR(pkt);
    if(ipv4->ip_v == 4){
        return ntohs(ipv4->ip_len);
    }
    else if (ipv4->ip_v == 6){
        ipv6 = IPv6_HDR(pkt);
        return (IP6_HDR_SIZE + ntohs(ipv6->ip6_plen));
    }
    return -1;
}

/*
 * Return the check result of the checksum field. IPv4 only.
 */
static VALUE
ipp_sumok(VALUE self)
{
    struct packet_object *pkt;
    struct ip *ip;
    int hlen, i, sum;
    unsigned short *ipus;

    GetPacket(self, pkt);
    if(ip_version(self) != 4){
        return Qnil;
    }

    CheckTruncateIp(pkt, 20);
    ip = IP_HDR(pkt);

    hlen = ip->ip_hl * 4;
    CheckTruncateIp(pkt, hlen);

    ipus = (unsigned short *)ip;
    sum = 0;
    hlen /= 2; /* 16-bit word */
    for (i = 0; i < hlen; i++) {
        sum += ntohs(ipus[i]);
        sum = (sum & 0xffff) + (sum >> 16);
    }
    if (sum == 0xffff)
        return Qtrue;

    return Qfalse;
}

/*
 * Return data part as {http://www.ruby-doc.org/core-1.9.3/String.html String}.
 */
static VALUE
ipp_data(VALUE self)
{
    struct packet_object *pkt;
    struct ip *ipv4;
    struct ip6_hdr *ipv6;
    int len, hlen, version;
    VALUE ret;

    DEBUG_PRINT("ipp_data");
    GetPacket(self, pkt);
    version = ip_version(self);
    if(version == 4){
        CheckTruncateIp(pkt, 20);
        ipv4 = IP_HDR(pkt);

        hlen = ipv4->ip_hl * 4;
        len = pkt->hdr.pkthdr.caplen - pkt->hdr.layer3_off - hlen;
        ret = rb_str_new((u_char *)ipv4 + hlen, len);
    }
    else if(version == 6){
        CheckTruncateIp(pkt, 40);
        ipv6 = IPv6_HDR(pkt);

        hlen = get_last_extension_header_offset(ipv6);
        len = pkt->hdr.pkthdr.caplen - pkt->hdr.layer3_off - hlen;
        ret = rb_str_new((u_char *)ipv6 + hlen, len);
    }
    return ret;
}

/*
 * IPv6 Next Header
 */
static int
get_last_extension_header_offset(struct ip6_hdr *ipv6)
{
    int offset;
    int next_header;
    int last_fragment;
    int header_length;
    int packet_length;
    struct ip6_ext *ipv6ext;
    offset = IP6_HDR_SIZE;

    next_header = ipv6->ip6_nxt;
    packet_length = ntohs(ipv6->ip6_plen) + IP6_HDR_SIZE;
    while (1) {
        switch( next_header ) {
        case IPPROTO_IPV6:    /* IPv6 header */
        case IPPROTO_AH:      /* IPv6 authentication header  */
        case IPPROTO_HOPOPTS: /* IPv6 Hop-by-Hop options */
        case IPPROTO_ROUTING: /* IPv6 routing header */
        case IPPROTO_DSTOPTS: /* IPv6 destination options */
            if(next_header == IPPROTO_AH){
                 header_length = ((2 + ((struct ip6_ext *)(ipv6 + offset))->ip6e_len) << 2);
            }
            else{
                 header_length = ((1 + ((struct ip6_ext *)(ipv6 + offset))->ip6e_len) << 3);
            }
            if( (offset + header_length) > packet_length )
                break;

            next_header = ((struct ip6_ext *)((char *)ipv6 + offset))->ip6e_nxt;
            offset += header_length;
            continue;
        case IPPROTO_FRAGMENT: /* IPv6 fragmentation header */
            header_length = sizeof(struct ip6_frag);
            if( (offset + header_length) > packet_length )
                break;

            next_header = ((struct ip6_frag *)((char *)ipv6 + offset))->ip6f_nxt;
            last_fragment = (((struct ip6_frag *)((char *)ipv6 + offset))->ip6f_offlg) & IP6F_MORE_FRAG;
            offset += header_length;

            /* If the case of the last fragment, go back to the next header check */
            if( last_fragment == 0 )
                continue;

            break;
        default:
            break;
        }
        break;
    }
    return offset;
}

static VALUE
get_extension_header_array(struct ip6_hdr *ipv6)
{
    int offset;
    int next_header;
    int last_fragment;
    int header_length;
    int packet_length;
    struct ip6_ext *ipv6ext;
    offset = IP6_HDR_SIZE;
    VALUE ary = rb_ary_new();

    next_header = ipv6->ip6_nxt;
    packet_length = ipv6->ip6_plen + IP6_HDR_SIZE;
    while (1) {
        rb_ary_push(ary, INT2FIX(next_header));
        switch( next_header ) {
        case IPPROTO_IPV6:    /* IPv6 header */
        case IPPROTO_AH:      /* IPv6 authentication header  */
        case IPPROTO_HOPOPTS: /* IPv6 Hop-by-Hop options */
        case IPPROTO_ROUTING: /* IPv6 routing header */
        case IPPROTO_DSTOPTS: /* IPv6 destination options */
            if(next_header == IPPROTO_AH){
                 header_length = ((2 + ((struct ip6_ext *)(ipv6 + offset))->ip6e_len) << 2);
            }
            else{
                 header_length = ((1 + ((struct ip6_ext *)(ipv6 + offset))->ip6e_len) << 3);
            }
            if( (offset + header_length) > packet_length )
                return ary;

            next_header = ((struct ip6_ext *)((char *)ipv6 + offset))->ip6e_nxt;
            offset += header_length;
            continue;
        case IPPROTO_FRAGMENT: /* IPv6 fragmentation header */
            header_length = sizeof(struct ip6_frag);
            if( (offset + header_length) > packet_length )
                return ary;

            next_header = ((struct ip6_frag *)((char *)ipv6 + offset))->ip6f_nxt;
            last_fragment = (((struct ip6_frag *)((char *)ipv6 + offset))->ip6f_offlg) & IP6F_MORE_FRAG;
            offset += header_length;

            /* If the case of the last fragment, go back to the next header check */
            if( last_fragment == 0 )
                continue;

            rb_ary_push(ary, INT2FIX(next_header));
            return ary;
        default:
            return ary;
        }
    }
    return ary;
}

/*
 * IPAddress
 */
/* Return source IP address as {IPAddr}. */
static VALUE
ipp_src(VALUE self)
{
    struct packet_object *pkt;
    struct ip *ipv4;
    struct ip6_hdr *ipv6;
    int version;
    VALUE ret;
    ID obj_id;

    DEBUG_PRINT("ipp_src");
    obj_id = rb_intern("@src_address");
    if (rb_ivar_defined(self, obj_id) == Qtrue){
        return rb_ivar_get(self, obj_id);
    }
    version = ip_version(self);
    GetPacket(self, pkt);
    if(version == 4){
        CheckTruncateIp(pkt, 16);
        ipv4 = IP_HDR(pkt);
        ret = new_ipaddr(&ipv4->ip_src);
    }
    else if(version == 6){
        CheckTruncateIp(pkt, 24);
        ipv6 = IPv6_HDR(pkt);
        ret = new_ipv6addr(&ipv6->ip6_src);
    }
    else{
        return Qnil;
    }
    rb_ivar_set(self, obj_id, ret);
    return ret;
}

/* Return destination IP address as {IPAddr}. */
static VALUE
ipp_dst(VALUE self)
{
    struct packet_object *pkt;
    struct ip *ipv4;
    struct ip6_hdr *ipv6;
    int version;
    VALUE ret;
    ID obj_id;

    DEBUG_PRINT("ipp_dst");
    obj_id = rb_intern("@dst_address");
    if (rb_ivar_defined(self, obj_id) == Qtrue){
        return rb_ivar_get(self, obj_id);
    }
    version = ip_version(self);
    GetPacket(self, pkt);
    if(version == 4){
        CheckTruncateIp(pkt, 20);
        ipv4 = IP_HDR(pkt);
        ret = new_ipaddr(&ipv4->ip_dst);
    }
    else if(version == 6){
        CheckTruncateIp(pkt, 40);
        ipv6 = IPv6_HDR(pkt);
        ret = new_ipv6addr(&ipv6->ip6_dst);
    }
    else{
        return Qnil;
    }
    rb_ivar_set(self, obj_id, ret);
    return ret;
}

/* IPv4 adress (32bit) is stored by immediate value */
#if SIZEOF_VOIDP < 4
# error IPAddress assumes sizeof(void *) >= 4
#endif

VALUE
new_ipaddr(struct in_addr *addr)
{
    VALUE ipaddr_obj;
    unsigned char addr_int[4];
    char addr_str[32];

    memcpy(addr_int, addr, 4);
    sprintf(addr_str, "0x%02x%02x%02x%02x", addr_int[0], addr_int[1], addr_int[2], addr_int[3]);

    ipaddr_obj = Data_Wrap_Struct(cIPAddr, 0, 0, 0);
    VALUE argv[] = {rb_Integer(rb_str_new2(addr_str)), INT2FIX(AF_INET)};
    rb_obj_call_init(ipaddr_obj, 2, argv);
    return ipaddr_obj;
}

static VALUE
new_ipaddr_int(struct in_addr *addr)
{
    return UINT2NUM(ntohl(addr->s_addr));
}

static VALUE
new_ipaddr_str(struct in_addr *addr)
{
    unsigned char addr_int[4];
    char addr_str[32];

    memcpy(addr_int, addr, 4);
    sprintf(addr_str, "%d.%d.%d.%d", addr_int[0], addr_int[1], addr_int[2], addr_int[3]);
    return rb_str_new2(addr_str);
}

VALUE
new_ipv6addr(struct in6_addr *addr)
{
    VALUE ipaddr_obj;
    unsigned short addr_int[8];
    char addr_str[40];

    memcpy(addr_int, addr, 16);
    sprintf(addr_str, "0x%04x%04x%04x%04x%04x%04x%04x%04x", 
        ntohs(addr_int[0]), ntohs(addr_int[1]), ntohs(addr_int[2]), ntohs(addr_int[3]), 
        ntohs(addr_int[4]), ntohs(addr_int[5]), ntohs(addr_int[6]), ntohs(addr_int[7]));

    ipaddr_obj = Data_Wrap_Struct(cIPAddr, 0, 0, 0);
    VALUE argv[] = {rb_Integer(rb_str_new2(addr_str)), INT2FIX(AF_INET6)};
    rb_obj_call_init(ipaddr_obj, 2, argv);
    return ipaddr_obj;
}

static VALUE
new_ipv6addr_int(struct in6_addr *addr)
{
    VALUE addr_int;
    unsigned short addr_tmp[8];
    int i;

    memcpy(addr_tmp, addr, 16);
    addr_int = INT2FIX(0);
    for(i=0; i < 8; i++){
        addr_int = rb_funcall(addr_int, rb_intern("+"), 1, rb_funcall(INT2FIX(ntohs(addr_tmp[i])),
            rb_intern("<<"), 1, INT2FIX(16 * (7 - i))));
    }
    return addr_int;
}

static VALUE
new_ipv6addr_str(struct in6_addr *addr)
{
    unsigned short addr_int[8];
    char addr_str[40];

    memcpy(addr_int, addr, 16);
    sprintf(addr_str, "%x:%x:%x:%x:%x:%x:%x:%x", 
        ntohs(addr_int[0]), ntohs(addr_int[1]), ntohs(addr_int[2]), ntohs(addr_int[3]), 
        ntohs(addr_int[4]), ntohs(addr_int[5]), ntohs(addr_int[6]), ntohs(addr_int[7]));
    return rb_str_new2(addr_str);
}

void
Init_ip_packet(void)
{
    DEBUG_PRINT("Init_ip_packet");

    /* A packet carrying IP header. */
    cIPPacket = rb_define_class_under(mPcap, "IPPacket", cPacket);

    /* IPv4 IPv6 Common Method */
    rb_define_method(cIPPacket, "ip_ver", ipp_ver, 0);
    rb_define_method(cIPPacket, "ipv4?", ipp_ver4, 0);
    rb_define_method(cIPPacket, "ipv6?", ipp_ver6, 0);
    rb_define_method(cIPPacket, "ip_header_length", ipp_header_length, 0);
    rb_define_method(cIPPacket, "ip_payload_length", ipp_payload_length, 0);
    rb_define_method(cIPPacket, "ip_tos", ipp_tos, 0);
    rb_define_method(cIPPacket, "ip_total_length", ipp_total_length, 0);
    rb_define_method(cIPPacket, "ip_ttl", ipp_ttl, 0);
    rb_define_alias(cIPPacket,  "ip_hoplimit", "ip_ttl");
    rb_define_method(cIPPacket, "ip_src", ipp_src, 0);
    rb_define_alias(cIPPacket,  "src", "ip_src");
    rb_define_method(cIPPacket, "ip_src_i", ipp_src_int, 0);
    rb_define_alias(cIPPacket,  "src_i", "ip_src_i");
    rb_define_method(cIPPacket, "ip_src_s", ipp_src_str, 0);
    rb_define_alias(cIPPacket,  "src_s", "ip_src_s");
    rb_define_method(cIPPacket, "ip_dst", ipp_dst, 0);
    rb_define_alias(cIPPacket,  "dst", "ip_dst");
    rb_define_method(cIPPacket, "ip_dst_i", ipp_dst_int, 0);
    rb_define_alias(cIPPacket,  "dst_i", "ip_dst_i");
    rb_define_method(cIPPacket, "ip_dst_s", ipp_dst_str, 0);
    rb_define_alias(cIPPacket,  "dst_s", "ip_dst_s");
    rb_define_method(cIPPacket, "ip_data", ipp_data, 0);

    /* IPv4 Methods. IPv6 is nil */
    rb_define_method(cIPPacket, "ip_hlen", ipp_hlen, 0);
    rb_define_alias(cIPPacket,  "ip4_hlen", "ip_hlen");
    rb_define_method(cIPPacket, "ip_len", ipp_len, 0);
    rb_define_alias(cIPPacket,  "ip4_len", "ip_len");
    rb_define_method(cIPPacket, "ip_id", ipp_id, 0);
    rb_define_method(cIPPacket, "ip_proto", ipp_proto, 0);
    rb_define_method(cIPPacket, "ip_flags", ipp_flags, 0);
    rb_define_method(cIPPacket, "ip_df?", ipp_df, 0);
    rb_define_method(cIPPacket, "ip_mf?", ipp_mf, 0);
    rb_define_method(cIPPacket, "ip_off", ipp_off, 0);
    rb_define_method(cIPPacket, "ip_sum", ipp_sum, 0);
    rb_define_method(cIPPacket, "ip_sumok?", ipp_sumok, 0);

    /* IPv6 Methods. IPv4 is nil */
    rb_define_method(cIPPacket, "ip_flow", ipp_flow, 0);
    rb_define_method(cIPPacket, "ip_plen", ipp_plen, 0);
    rb_define_alias(cIPPacket,  "ip6_plen", "ip_plen");
    rb_define_method(cIPPacket, "ip_next", ipp_next, 0);

    /* Require IPAddr class. */
    rb_f_require(Qnil, rb_str_new2("ipaddr"));
    cIPAddr = rb_define_class("IPAddr", rb_cObject);

    Init_tcp_packet();
    Init_udp_packet();
    Init_icmp_packet();
}
