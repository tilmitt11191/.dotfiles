/*
 *  ruby_pcap.h
 *
 *  Copyright (C) 1998-2000  Masaki Fukushima
 */

#ifndef RUBY_PCAP_H
#define RUBY_PCAP_H

#include "ruby.h"
#include <pcap.h>
#include <stdio.h>
#include <net/ethernet.h>
#include <netinet/in.h>
#include <netinet/in_systm.h>
#include <netinet/ip.h>
#include <netinet/ip6.h>
#include <arpa/inet.h>
#ifndef IP_OFFMASK
# define IP_OFFMASK 0x1fff
#endif
#ifdef linux
# define __FAVOR_BSD
#endif
#include <netinet/tcp.h>
#include <netinet/udp.h>
#include <netinet/ip_icmp.h>
#include <netinet/if_ether.h>
#include <sys/socket.h>
#include <netdb.h>

#ifdef DEBUG
# define DEBUG_PRINT(x) do {\
    ((RTEST(ruby_debug) && RTEST(ruby_verbose))?\
    (fprintf(stderr, "%s\n", x),fflush(stderr)) : 0)\
} while (0)
#else
# define DEBUG_PRINT(x) do {} while (0)
#endif

#define UINT32_2_NUM(i) rb_uint2inum(i)
#ifndef UINT2NUM
# define UINT2NUM(i) rb_uint2inum(i)
#endif
#define MIN(x, y)       ((x)<(y) ? (x) : (y))


#define PACKET_MARSHAL_VERSION  1

#define IP4_HDR_SIZE            20
#define IP6_HDR_SIZE            40
#define TPID_SIZE               2
#define ARP_HEADER_SIZE         28
#define VLAN_FRAME_SIZE         4
#define EOE_FRAME_SIZE          16
#define PBB_FRAME_SIZE          18
#define MAC_ADDR_OFFSET         12
#define TRAFFIC_CLASS_MASK_V6   0x00000ff0
#define FLOW_LABEL_MASK_V6      0xfffff000
#define ETHER_MIN_SIZE          (ETHER_MIN_LEN - ETHER_CRS_LEN)


/* Ethernet protocol ID's */
#define ETHERTYPE_EOE           0xe0e0
#define ETHERTYPE_PBB           0x88e7
#define ETHERTYPE_EXT_VLAN      0xa100
#define ETHERTYPE_8021AD        0x88a8
#define ETHERTYPE_QINQ1         0x9100
#define ETHERTYPE_QINQ2         0x9200
#define ETHERTYPE_QINQ3         0x9300

/* ruby config.h defines WORDS_BIGENDIAN if big-endian */
struct packet_object_header {
#ifdef WORDS_BIGENDIAN
    u_char version:4;           /* marshal format version       */
    u_char flags:4;             /* flags                        */
#else
    u_char flags:4;             /* flags                        */
    u_char version:4;           /* marshal format version       */
#endif
#define POH_UDATA 0x01          /* flag: user data exists       */
#define POH_RSVD1 0x02          /*       (reserved)             */
#define POH_RSVD2 0x03          /*       (reserved)             */
#define POH_RSVD3 0x04          /*       (reserved)             */
    u_char dl_type;             /* data-link type (DLT_*)       */
    u_short layer3_off;         /* layer 3 header offset        */
    u_short layer4_off;         /* layer 4 header offset        */
    u_short layer5_off;         /* layer 5 header offset        */
#define OFF_NONEXIST 0xffff     /* offset value for non-existent layer  */
    struct pcap_pkthdr pkthdr;  /* pcap packet header           */
};

struct packet_object {
    struct packet_object_header hdr;    /* packet object header */
    u_char *data;                       /* packet data          */
    VALUE udata;                        /* user data            */
};

/* VALN Header Struct */
struct vlan_header {
    u_short tpid;
    u_short vlan_data;
};
#define VLAN_PCP_MASK       0xe000
#define VLAN_CFI_MASK       0x1000
#define VLAN_VID_MASK       0x0fff
#define VLAN_PCP_BITSHIFT   13
#define VLAN_CFI_BITSHIFT   12

struct eoe_frame_header {
    u_short tpid;     /* EoE frame TPID 0xe0e0 */
    u_char  eoe_ttl;
    u_char  eid;
};

struct pbb_frame_header {
    u_short tpid;     /* PBB frame TPID 0x88e7 */
    u_char  res2_flg:2;
    u_char  res1_flg:1;
    u_char  uca_flg:1;
    u_char  i_pcp:4;
    u_char  i_sid_1;
    u_short i_sid_2;
};

enum TPID_PATTERN {
    DEFAULT,
    VLAN,
    EOE,
    PBB
};

#define PKTFLAG_TEST(pkt, flag) ((pkt)->hdr.flags & (flag))
#define PKTFLAG_SET(pkt, flag, val) \
    ((val) ? ((pkt)->hdr.flags |= (flag)) : ((pkt)->hdr.flags &= ~(flag)))

#define LAYER2_HDR(pkt) ((pkt)->data)
#define LAYER3_HDR(pkt) ((pkt)->data + (pkt)->hdr.layer3_off)
#define LAYER4_HDR(pkt) ((pkt)->data + (pkt)->hdr.layer4_off)
#define LAYER5_HDR(pkt) ((pkt)->data + (pkt)->hdr.layer5_off)

#define GetPacket(obj, pkt) Data_Get_Struct(obj, struct packet_object, pkt)
#define Caplen(pkt, from) ((pkt)->hdr.pkthdr.caplen - (from))
#define CheckTruncate(pkt, from, need, emsg) (\
    (from) + (need) > (pkt)->hdr.pkthdr.caplen ? \
        rb_raise(eTruncatedPacket, (emsg)) : 0 \
)

#define IsKindOf(v, class) RTEST(rb_obj_is_kind_of(v, class))
#define CheckClass(v, class) ((IsKindOf(v, class)) ? 0 :\
    rb_raise(rb_eTypeError, "wrong type %s (expected %s)",\
        rb_class2name(CLASS_OF(v)), rb_class2name(class)))

#define GetEthernetHeader(obj, ethernet_header) Data_Get_Struct(obj, struct ether_header, ethernet_header)
#define GetVLANFrame(obj, vlan) Data_Get_Struct(obj, struct vlan_header, vlan)
#define GetEOEFrame(obj, eoe) Data_Get_Struct(obj, struct eoe_frame_header, eoe)
#define GetPBBFrame(obj, pbb) Data_Get_Struct(obj, struct pbb_frame_header, pbb)

/* Pcap.c */
extern VALUE mPcap, rbpcap_convert;
extern VALUE ePcapError;
extern VALUE eTruncatedPacket;
extern VALUE cFilter;
void Init_pcap(void);
VALUE filter_match(VALUE self, VALUE v_pkt);

/* packet.c */
extern VALUE cPacket;
void Init_packet(void);
VALUE new_packet(const u_char *, const struct pcap_pkthdr *, int);

/* ethernet_header.c */
void Init_ethernet_header(void);
VALUE setup_ethernet_headers(struct ether_header *);
u_short check_tpid_pattern(u_short tpid);
int get_ethernet_header_length(struct ether_header *);
extern VALUE cEthernetHeader;

/* ethernet_header_tag.c */
void Init_ethernet_header_tag(void);
VALUE setup_ethernet_header_tags(struct ether_header *);
extern VALUE cEthernetHeaderTag;

/* ip_packet.c */
#define IP_HDR(pkt)     ((struct ip *)LAYER3_HDR(pkt))
#define IPv6_HDR(pkt)   ((struct ip6_hdr *)LAYER3_HDR(pkt))
#define IP_DATA(pkt)    ((u_char *)LAYER4_HDR(pkt))
extern VALUE cIPPacket;
void Init_ip_packet(void);
VALUE setup_ip_packet(struct packet_object *, int);
VALUE new_ipaddr(struct in_addr *);
VALUE new_ipv6addr(struct in6_addr *);
char ip_version(VALUE);
int get_payload_length_ipv4(struct ip *);
int get_payload_length_ipv6(struct ip6_hdr *);
int get_total_length(struct packet_object *);

/* tcp_packet.c */
extern VALUE cTCPPacket;
void Init_tcp_packet(void);
VALUE setup_tcp_packet(struct packet_object *, int);

/* udp_packet.c */
extern VALUE cUDPPacket;
void Init_udp_packet(void);
VALUE setup_udp_packet(struct packet_object *, int);

/* icmp_packet.c */
extern VALUE cICMPPacket;
void Init_icmp_packet(void);
VALUE setup_icmp_packet(struct packet_object *, int);

#endif /* RUBY_PCAP_H */
