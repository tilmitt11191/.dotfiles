/*
 *  ethernet_header.c
 *
 *  Copyright (C) 1998-2014  KDDI R&D Laboratories
 */
 
#include <ruby.h>
#include "ruby_pcap.h"

VALUE cEthernetHeader;

u_short
check_tpid_pattern(u_short tpid)
{
    switch (tpid){
#ifdef ETHERTYPE_VLAN
        case ETHERTYPE_VLAN:
        case ETHERTYPE_8021AD:
        case ETHERTYPE_QINQ1:
        case ETHERTYPE_QINQ2:
        case ETHERTYPE_QINQ3:
        case ETHERTYPE_EXT_VLAN:
            return VLAN;
        case ETHERTYPE_EOE:
            return EOE;
        case ETHERTYPE_PBB:
            return PBB;
        default:
            return DEFAULT;
#else
        case ETH_P_8021Q:
        case ETH_P_8021AD:
        case ETH_P_QINQ1:
        case ETH_P_QINQ2:
        case ETH_P_QINQ3:
        case ETHERTYPE_EXT_VLAN:
            return VLAN;
        case ETHERTYPE_EOE:
            return EOE;
        case ETH_P_8021AH:
            return PBB;
        default:
            return DEFAULT;
#endif
    }
}

VALUE
setup_ethernet_headers(struct ether_header *eth_header)
{
    VALUE ethernetheaders;
    int offset = MAC_ADDR_OFFSET;
    int pkt_head = 0;
    int tag = 0;

    ethernetheaders = rb_ary_new();

    for(;;){
        switch (check_tpid_pattern(ntohs(*(u_short *)((u_char *)eth_header + offset)))){
        case VLAN:
            offset += VLAN_FRAME_SIZE;
            tag ++;
            break;
        case EOE:
            offset += EOE_FRAME_SIZE;
            rb_ary_push(ethernetheaders, Data_Wrap_Struct(cEthernetHeader, 0, 0, ((u_char *)eth_header + pkt_head)));
            pkt_head += ((tag * VLAN_FRAME_SIZE) + EOE_FRAME_SIZE);
            tag = 0;
            break;
        case PBB:
            offset += PBB_FRAME_SIZE;
            rb_ary_push(ethernetheaders, Data_Wrap_Struct(cEthernetHeader, 0, 0, ((u_char *)eth_header + pkt_head)));
            pkt_head += ((tag * VLAN_FRAME_SIZE) + PBB_FRAME_SIZE);
            tag = 0;
            break;
        case DEFAULT:
            rb_ary_push(ethernetheaders, Data_Wrap_Struct(cEthernetHeader, 0, 0, ((u_char *)eth_header + pkt_head)));
            return ethernetheaders;
        }
    }
}

int
get_ethernet_header_length(struct ether_header *eth_header)
{
    int offset = MAC_ADDR_OFFSET;

    for(;;){
        switch (check_tpid_pattern(ntohs(*(u_short *)((u_char *)eth_header + offset)))){
        case VLAN:
            offset += VLAN_FRAME_SIZE;
            break;
        case EOE:
            offset += EOE_FRAME_SIZE;
            break;
        case PBB:
            offset += PBB_FRAME_SIZE;
            break;
        case DEFAULT:
            return (offset + ETHER_TYPE_LEN);
        }
    }
}

/* Return destination MAC address of packet as {http://www.ruby-doc.org/core-1.9.3/String.html String}. */
static VALUE
ethernet_header_dst_mac(VALUE self)
{
    struct ether_header *eth_header;
    char mac_addr[32];

    DEBUG_PRINT("ethernet_header_dst_mac");

    GetEthernetHeader(self, eth_header);
    sprintf(mac_addr, "%02x:%02x:%02x:%02x:%02x:%02x",
        eth_header->ether_dhost[0], eth_header->ether_dhost[1], eth_header->ether_dhost[2], 
        eth_header->ether_dhost[3], eth_header->ether_dhost[4], eth_header->ether_dhost[5]);

    return rb_str_new2(mac_addr);
}

/* Return destination MAC address of packet as Integer. */
static VALUE
ethernet_header_dst_mac_int(VALUE self)
{
    struct ether_header *eth_header;
    VALUE mac_int;
    int i;

    DEBUG_PRINT("ethernet_header_dst_mac_int");

    GetEthernetHeader(self, eth_header);
    mac_int = INT2FIX(0);
    for(i=0; i < ETHER_ADDR_LEN; i++){
        mac_int = rb_funcall(mac_int, rb_intern("+"), 1, rb_funcall((INT2FIX(eth_header->ether_dhost[i])),
            rb_intern("<<"), 1, INT2FIX(8 * ((ETHER_ADDR_LEN - 1) - i))));
    }
    return mac_int;
}

/* Return source MAC address of packet as {http://www.ruby-doc.org/core-1.9.3/String.html String}. */
static VALUE
ethernet_header_src_mac(VALUE self)
{
    struct ether_header *eth_header;
    char mac_addr[32];

    DEBUG_PRINT("ethernet_header_src_mac");

    GetEthernetHeader(self, eth_header);
    sprintf(mac_addr, "%02x:%02x:%02x:%02x:%02x:%02x",
        eth_header->ether_shost[0], eth_header->ether_shost[1], eth_header->ether_shost[2],
        eth_header->ether_shost[3], eth_header->ether_shost[4], eth_header->ether_shost[5]);

    return rb_str_new2(mac_addr);
}

/* Return source MAC address of packet as Integer. */
static VALUE
ethernet_header_src_mac_int(VALUE self)
{
    struct ether_header *eth_header;
    VALUE mac_int;
    int i;

    DEBUG_PRINT("ethernet_header_src_mac_int");

    GetEthernetHeader(self, eth_header);
    mac_int = INT2FIX(0);
    for(i=0; i < ETHER_ADDR_LEN; i++){
        mac_int = rb_funcall(mac_int, rb_intern("+"), 1, rb_funcall((INT2FIX(eth_header->ether_shost[i])),
            rb_intern("<<"), 1, INT2FIX(8 * ((ETHER_ADDR_LEN - 1) - i))));
    }
    return mac_int;
}

/* Return as {http://www.ruby-doc.org/core-1.9.3/Array.html Array} of objects of {EthernetHeaderTag}.  */
static VALUE
ethernet_header_tags(VALUE self)
{
    struct ether_header *eth_header;
    int offset = MAC_ADDR_OFFSET;

    DEBUG_PRINT("ethernet_header_tags");

    GetEthernetHeader(self, eth_header);
    return setup_ethernet_header_tags(eth_header);
}

/* Return true if ethernet header include VLAN frame */
static VALUE
ethernet_header_vlan(VALUE self)
{
    struct ether_header *eth_header;
    int offset = MAC_ADDR_OFFSET;

    DEBUG_PRINT("ethernet_header_vlan");

    GetEthernetHeader(self, eth_header);
    for(;;){
        switch (check_tpid_pattern(ntohs(*(u_short *)((u_char *)eth_header + offset)))){
        case VLAN:
            return Qtrue;
        case EOE:
            offset += EOE_FRAME_SIZE;
            break;
        case PBB:
            offset += PBB_FRAME_SIZE;
            break;
        case DEFAULT:
            return Qfalse;
        }
    }
}

/* Return true if ethernet header include EOE frame */
static VALUE
ethernet_header_eoe(VALUE self)
{
    struct ether_header *eth_header;
    int offset = MAC_ADDR_OFFSET;

    DEBUG_PRINT("ethernet_header_eoe");

    GetEthernetHeader(self, eth_header);
    for(;;){
        switch (check_tpid_pattern(ntohs(*(u_short *)((u_char *)eth_header + offset)))){
        case VLAN:
            offset += VLAN_FRAME_SIZE;
            break;
        case EOE:
            return Qtrue;
        case PBB:
            offset += PBB_FRAME_SIZE;
            break;
        case DEFAULT:
            return Qfalse;
        }
    }
}

/* Return true if ethernet header include PBB frame */
static VALUE
ethernet_header_pbb(VALUE self)
{
    struct ether_header *eth_header;
    int offset = MAC_ADDR_OFFSET;

    DEBUG_PRINT("ethernet_header_pbb");

    GetEthernetHeader(self, eth_header);
    for(;;){
        switch (check_tpid_pattern(ntohs(*(u_short *)((u_char *)eth_header + offset)))){
        case VLAN:
            offset += VLAN_FRAME_SIZE;
            break;
        case EOE:
            offset += EOE_FRAME_SIZE;
            break;
        case PBB:
            return Qtrue;
        case DEFAULT:
            return Qfalse;
        }
    }
}

/* Initialization of EthernetHeader class */
void Init_ethernet_header(void)
{
    DEBUG_PRINT("Init_ethernet_header");

    /* A packet carrying Ethernet Header */
    cEthernetHeader = rb_define_class_under(mPcap, "EthernetHeader", rb_cObject);

    rb_define_method(cEthernetHeader, "dst_mac", ethernet_header_dst_mac, 0);
    rb_define_alias(cEthernetHeader,  "dst_mac_address", "dst_mac");
    rb_define_method(cEthernetHeader, "dst_mac_i", ethernet_header_dst_mac_int, 0);
    rb_define_alias(cEthernetHeader,  "dst_mac_address_i", "dst_mac_i");
    rb_define_method(cEthernetHeader, "src_mac", ethernet_header_src_mac, 0);
    rb_define_alias(cEthernetHeader,  "src_mac_address", "src_mac");
    rb_define_method(cEthernetHeader, "src_mac_i", ethernet_header_src_mac_int, 0);
    rb_define_alias(cEthernetHeader,  "src_mac_address_i", "src_mac_i");
    rb_define_method(cEthernetHeader, "tags", ethernet_header_tags, 0);
    rb_define_method(cEthernetHeader, "vlan?", ethernet_header_vlan, 0);
    rb_define_method(cEthernetHeader, "eoe?", ethernet_header_eoe, 0);
    rb_define_method(cEthernetHeader, "pbb?", ethernet_header_pbb, 0);

    Init_ethernet_header_tag();
}