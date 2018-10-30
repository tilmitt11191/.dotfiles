/*
 *  ethernet_header_tag.c
 *
 *  Copyright (C) 1998-2014  KDDI R&D Laboratories
 */


#include <ruby.h>
#include "ruby_pcap.h"

VALUE cEthernetHeaderTag;

VALUE setup_ethernet_header_tags(struct ether_header *eth_header)
{
    VALUE ethernetheadertags;
    int offset = MAC_ADDR_OFFSET;

    ethernetheadertags = rb_ary_new();

    for(;;){
        switch (check_tpid_pattern(ntohs(*(u_short *)((u_char *)eth_header + offset)))){
        case VLAN:
            rb_ary_push( ethernetheadertags,
                Data_Wrap_Struct(cEthernetHeaderTag, 0, 0, ((u_char *)eth_header + offset)));
            offset += VLAN_FRAME_SIZE;
            break;
        case EOE:
            rb_ary_push( ethernetheadertags,
                Data_Wrap_Struct(cEthernetHeaderTag, 0, 0, ((u_char *)eth_header + offset)));
            offset += EOE_FRAME_SIZE;
            return ethernetheadertags;
        case PBB:
            rb_ary_push( ethernetheadertags,
                Data_Wrap_Struct(cEthernetHeaderTag, 0, 0, ((u_char *)eth_header + offset)));
            offset += PBB_FRAME_SIZE;
            return ethernetheadertags;
        case DEFAULT:
            rb_ary_push( ethernetheadertags,
                Data_Wrap_Struct(cEthernetHeaderTag, 0, 0, ((u_char *)eth_header + offset)));
            return ethernetheadertags;
        }
    }
}

/* Return the value of tpid. */
static VALUE
ethernet_header_tag_tpid(VALUE self)
{
    struct vlan_header *vlan;

    DEBUG_PRINT("ethernet_header_tag_tpid");

    GetVLANFrame(self, vlan);
    return INT2FIX(ntohs(vlan->tpid));
}

/* Return the value of 3-bit pcp filed. VLAN frame only. */
static VALUE
ethernet_header_tag_pcp(VALUE self)
{
    struct vlan_header *vlan;

    DEBUG_PRINT("ethernet_header_tag_pcp");

    GetVLANFrame(self, vlan);
    if (check_tpid_pattern(ntohs(vlan->tpid)) != VLAN) {
        return Qnil;
    }
    return INT2FIX((ntohs(vlan->vlan_data) & VLAN_PCP_MASK) >> VLAN_PCP_BITSHIFT );
}

/* Return the value of 1-bit cfi filed. VLAN frame only. */
static VALUE
ethernet_header_tag_cfi(VALUE self)
{
    struct vlan_header *vlan;

    DEBUG_PRINT("ethernet_header_tag_cfi");

    GetVLANFrame(self, vlan);
    if (check_tpid_pattern(ntohs(vlan->tpid)) != VLAN) {
        return Qnil;
    }
    return INT2FIX((ntohs(vlan->vlan_data) & VLAN_CFI_MASK) >> VLAN_CFI_BITSHIFT );
}

/* Return the value of 24-bit vid filed. VLAN frame only. */
static VALUE
ethernet_header_tag_vid(VALUE self)
{
    struct vlan_header *vlan;

    DEBUG_PRINT("ethernet_header_tag_vid");

    GetVLANFrame(self, vlan);
    if (check_tpid_pattern(ntohs(vlan->tpid)) != VLAN) {
        return Qnil;
    }
    return INT2FIX(ntohs(vlan->vlan_data) & VLAN_VID_MASK);
}

/* Return the value of ttl filed. EOE frame and PBB frame(ttl flag on) */
static VALUE
ethernet_header_tag_ttl(VALUE self)
{
    struct eoe_frame_header *eoe;
    struct pbb_frame_header *pbb;

    DEBUG_PRINT("ethernet_header_tag_ttl");

    GetEOEFrame(self, eoe);
    if (check_tpid_pattern(ntohs(eoe->tpid)) == EOE) {
         return INT2FIX(eoe->eoe_ttl);
    }
    else if (check_tpid_pattern(ntohs(eoe->tpid)) == PBB) {
        GetPBBFrame(self, pbb);
        if ((pbb->res2_flg) & 1 == 1) {
            return INT2FIX(pbb->i_sid_1);
        }
    }
    return Qnil;
}

/* Return the value of eid filed. EOE frame only. */
static VALUE
ethernet_header_tag_eid(VALUE self)
{
    struct eoe_frame_header *eoe;

    DEBUG_PRINT("ethernet_header_tag_eid");

    GetEOEFrame(self, eoe);
    if (check_tpid_pattern(ntohs(eoe->tpid)) != EOE) {
        return Qnil;
    }
    return INT2FIX(eoe->eid);
}

/* Return the value of 4-bit i-pcp(i-dei) filed. PBB frame only. */
static VALUE
ethernet_header_tag_itag_pcp(VALUE self)
{
    struct pbb_frame_header *pbb;

    DEBUG_PRINT("ethernet_header_tag_itag_pcp");

    GetPBBFrame(self, pbb);
    if (check_tpid_pattern(ntohs(pbb->tpid)) != PBB) {
        return Qnil;
    }
    return INT2FIX(pbb->i_pcp);
}

/* Return the value of 1-bit uca filed. PBB frame only. */
static VALUE
ethernet_header_tag_flag_uca(VALUE self)
{
    struct pbb_frame_header *pbb;
    GetPBBFrame(self, pbb);

    DEBUG_PRINT("ethernet_header_tag_flag_uca");

    if (check_tpid_pattern(ntohs(pbb->tpid)) != PBB) {
        return Qnil;
    }
    return INT2FIX(pbb->uca_flg);
}

/* Return the value of 1-bit res1 filed. PBB frame only. */
static VALUE
ethernet_header_tag_flag_res1(VALUE self)
{
    struct pbb_frame_header *pbb;
    GetPBBFrame(self, pbb);

    DEBUG_PRINT("ethernet_header_tag_flag_res1");

    if (check_tpid_pattern(ntohs(pbb->tpid)) != PBB) {
        return Qnil;
    }
    return INT2FIX(pbb->res1_flg);
}

/* Return the value of 2-bit res2 filed. PBB frame only. */
static VALUE
ethernet_header_tag_flag_res2(VALUE self)
{
    struct pbb_frame_header *pbb;

    DEBUG_PRINT("ethernet_header_tag_flag_res2");

    GetPBBFrame(self, pbb);
    if (check_tpid_pattern(ntohs(pbb->tpid)) != PBB) {
        return Qnil;
    }
    return INT2FIX(pbb->res2_flg);
}

/* Return the value of i-sid filed. PBB frame only. */
static VALUE
ethernet_header_tag_sid(VALUE self)
{
    struct pbb_frame_header *pbb;

    DEBUG_PRINT("ethernet_header_tag_sid");

    GetPBBFrame(self, pbb);
    if (check_tpid_pattern(ntohs(pbb->tpid)) != PBB) {
        return Qnil;
    }
    if ((pbb->res2_flg) & 1 == 1 ) {
        return INT2FIX(ntohs(pbb->i_sid_2));
    }
    return INT2FIX(ntohs(pbb->i_sid_2) + ((pbb->i_sid_1) << 16));
}

/* Return true if ethernet header tag include VLAN frame */
static VALUE
ethernet_header_tag_vlan(VALUE self)
{
    struct vlan_header *vlan;

    DEBUG_PRINT("ethernet_header_tag_vlan");

    GetVLANFrame(self, vlan);
    if (check_tpid_pattern(ntohs(vlan->tpid)) != VLAN) {
        return Qfalse;
    }
    return Qtrue;
}

/* Return true if ethernet header tag include EOE frame */
static VALUE
ethernet_header_tag_eoe(VALUE self)
{
    struct eoe_frame_header *eoe;

    DEBUG_PRINT("ethernet_header_tag_eoe");

    GetEOEFrame(self, eoe);
    if (check_tpid_pattern(ntohs(eoe->tpid)) != EOE) {
        return Qfalse;
    }
    return Qtrue;
}

/* Return true if ethernet header tag include PBB frame */
static VALUE
ethernet_header_tag_pbb(VALUE self)
{
    struct pbb_frame_header *pbb;

    DEBUG_PRINT("ethernet_header_tag_pbb");

    GetPBBFrame(self, pbb);
    if (check_tpid_pattern(ntohs(pbb->tpid)) != PBB) {
        return Qfalse;
    }
    return Qtrue;
}

/* Initialization of EthernetHeaderTag class */
void Init_ethernet_header_tag(void)
{
    DEBUG_PRINT("Init_ethernet_header_tag");

    /* A packet carrying Ethernet Header Tag */
    cEthernetHeaderTag = rb_define_class_under(mPcap, "EthernetHeaderTag", rb_cObject);

    rb_define_method(cEthernetHeaderTag, "tpid", ethernet_header_tag_tpid, 0);
    rb_define_method(cEthernetHeaderTag, "pcp", ethernet_header_tag_pcp, 0);
    rb_define_method(cEthernetHeaderTag, "cfi", ethernet_header_tag_cfi, 0);
    rb_define_method(cEthernetHeaderTag, "vid", ethernet_header_tag_vid, 0);
    rb_define_method(cEthernetHeaderTag, "ttl", ethernet_header_tag_ttl, 0);
    rb_define_method(cEthernetHeaderTag, "eid", ethernet_header_tag_eid, 0);
    rb_define_method(cEthernetHeaderTag, "itag_pcp", ethernet_header_tag_itag_pcp, 0);
    rb_define_alias(cEthernetHeaderTag,  "itag_dei", "itag_pcp");
    rb_define_method(cEthernetHeaderTag, "flag_uca", ethernet_header_tag_flag_uca, 0);
    rb_define_method(cEthernetHeaderTag, "flag_res1", ethernet_header_tag_flag_res1, 0);
    rb_define_method(cEthernetHeaderTag, "flag_res2", ethernet_header_tag_flag_res2, 0);
    rb_define_alias(cEthernetHeaderTag,  "itag_ttl_flag", "flag_res2");
    rb_define_method(cEthernetHeaderTag, "itag_sid", ethernet_header_tag_sid, 0);
    rb_define_method(cEthernetHeaderTag, "vlan?", ethernet_header_tag_vlan, 0);
    rb_define_method(cEthernetHeaderTag, "eoe?", ethernet_header_tag_eoe, 0);
    rb_define_method(cEthernetHeaderTag, "pbb?", ethernet_header_tag_pbb, 0);
}