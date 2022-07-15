// ------------------------------------------------------------------
//
// Copyright (c) 2020  Achronix Semiconductor Corp.
// All Rights Reserved.
//
//
// This software constitutes an unpublished work and contains
// valuable proprietary information and trade secrets belonging
// to Achronix Semiconductor Corp.
//
// This software may not be used, copied, distributed or disclosed
// without specific prior written authorization from
// Achronix Semiconductor Corp.
//
// The copyright notice above does not evidence any actual or intended
// publication of such software.
//
// ------------------------------------------------------------------
//      Defines to create and connect logic to SERDES Model
// ------------------------------------------------------------------


`ifndef INCLUDE_MACRO_DEFS
`define INCLUDE_MACRO_DEFS

`define ACX_AXI_MASTER_PORT(S) \
  logic                       ``S``_m_awvalid;\
  logic                       ``S``_m_awready = 0;\
  logic [ADDR_WIDTH -1:0]     ``S``_m_awaddr;\
  logic [LEN_WIDTH -1:0]      ``S``_m_awlen;\
  logic [8 -1:0]              ``S``_m_awid;\
  logic [4 -1:0]              ``S``_m_awqos;\
  logic [2 -1:0]              ``S``_m_awburst;\
  logic                       ``S``_m_awlock;\
  logic [3 -1:0]              ``S``_m_awsize;\
  logic [3 -1:0]              ``S``_m_awregion = 0;\
  logic [3:0]                 ``S``_m_awcache = 0;\
  logic [2:0]                 ``S``_m_awprot = 0;\
  logic                       ``S``_m_wvalid;\
  logic                       ``S``_m_wready = 0;\
  logic [DATA_WIDTH -1:0]     ``S``_m_wdata;\
  logic [(DATA_WIDTH/8) -1:0] ``S``_m_wstrb;\
  logic                       ``S``_m_wlast;\
  logic                       ``S``_m_arready = 0;\
  logic [DATA_WIDTH -1:0]     ``S``_m_rdata = 0;\
  logic                       ``S``_m_rlast = 0;\
  logic [2 -1:0]              ``S``_m_rresp;\
  logic                       ``S``_m_rvalid = 0;\
  logic [8 -1:0]              ``S``_m_rid = 0;\
  logic [ADDR_WIDTH -1:0]     ``S``_m_araddr;\
  logic [LEN_WIDTH -1:0]      ``S``_m_arlen;\
  logic [8 -1:0]              ``S``_m_arid;\
  logic [4 -1:0]              ``S``_m_arqos;\
  logic [2 -1:0]              ``S``_m_arburst;\
  logic                       ``S``_m_arlock;\
  logic [3 -1:0]              ``S``_m_arsize;\
  logic                       ``S``_m_arvalid;\
  logic [3 -1:0]              ``S``_m_arregion = 0;\
  logic [3:0]                 ``S``_m_arcache = 0;\
  logic [2:0]                 ``S``_m_arprot = 0;\
  logic                       ``S``_m_aresetn = 0;\
  logic                       ``S``_m_rready = 0;\
  logic                       ``S``_m_bvalid = 0;\
  logic                       ``S``_m_bready;\
  logic [2 -1:0]              ``S``_m_bresp;\
  logic [8 -1:0]              ``S``_m_bid = 0

`define ACX_AXI_SLAVE_PORT(S) \
  logic                         ``S``_s_awvalid;\
  logic                         ``S``_s_awready = 0;\
  logic [SLAVE_ADDR_WIDTH -1:0] ``S``_s_awaddr;\
  logic [LEN_WIDTH -1:0]        ``S``_s_awlen;\
  logic [8 -1:0]                ``S``_s_awid;\
  logic [4 -1:0]                ``S``_s_awqos;\
  logic [2 -1:0]                ``S``_s_awburst;\
  logic                         ``S``_s_awlock;\
  logic [3 -1:0]                ``S``_s_awsize;\
  logic [3 -1:0]                ``S``_s_awregion = 0;\
  logic [3:0]                   ``S``_s_awcache = 0;\
  logic [2:0]                   ``S``_s_awprot = 0;\
  logic                         ``S``_s_wvalid;\
  logic                         ``S``_s_wready = 0;\
  logic [DATA_WIDTH -1:0]       ``S``_s_wdata;\
  logic [(DATA_WIDTH/8) -1:0]   ``S``_s_wstrb;\
  logic                         ``S``_s_wlast;\
  logic                         ``S``_s_arready = 0;\
  logic [DATA_WIDTH -1:0]       ``S``_s_rdata = 0;\
  logic                         ``S``_s_rlast = 0;\
  logic [2 -1:0]                ``S``_s_rresp = 0;\
  logic                         ``S``_s_rvalid = 0;\
  logic [8 -1:0]                ``S``_s_rid = 0;\
  logic [ADDR_WIDTH -1:0]       ``S``_s_araddr;\
  logic [LEN_WIDTH -1:0]        ``S``_s_arlen;\
  logic [8 -1:0]                ``S``_s_arid;\
  logic [4 -1:0]                ``S``_s_arqos;\
  logic [2 -1:0]                ``S``_s_arburst;\
  logic                         ``S``_s_arlock;\
  logic [3 -1:0]                ``S``_s_arsize;\
  logic                         ``S``_s_arvalid;\
  logic [3 -1:0]                ``S``_s_arregion = 0;\
  logic [3:0]                   ``S``_s_arcache = 0;\
  logic [2:0]                   ``S``_s_arprot = 0;\
  logic                         ``S``_s_aresetn = 0;\
  logic                         ``S``_s_rready = 0;\
  logic                         ``S``_s_bvalid = 0;\
  logic                         ``S``_s_bready;\
  logic [2 -1:0]                ``S``_s_bresp;\
  logic [8 -1:0]                ``S``_s_bid


// Create testbench signals to connect serdes from Root-Complex to DUT
`define ACX_SERDES_MODEL_DATA(S) \
  wire  ``S``_datap_0;\
  wire  ``S``_datan_0;\
  wire  ``S``_datap_1;\
  wire  ``S``_datan_1;\
  wire  ``S``_datap_2;\
  wire  ``S``_datan_2;\
  wire  ``S``_datap_3;\
  wire  ``S``_datan_3;\
  wire  ``S``_datap_4;\
  wire  ``S``_datan_4;\
  wire  ``S``_datap_5;\
  wire  ``S``_datan_5;\
  wire  ``S``_datap_6;\
  wire  ``S``_datan_6;\
  wire  ``S``_datap_7;\
  wire  ``S``_datan_7;\
  wire  ``S``_datap_8;\
  wire  ``S``_datan_8;\
  wire  ``S``_datap_9;\
  wire  ``S``_datan_9;\
  wire  ``S``_datap_10;\
  wire  ``S``_datan_10;\
  wire  ``S``_datap_11;\
  wire  ``S``_datan_11;\
  wire  ``S``_datap_12;\
  wire  ``S``_datan_12;\
  wire  ``S``_datap_13;\
  wire  ``S``_datan_13;\
  wire  ``S``_datap_14;\
  wire  ``S``_datan_14;\
  wire  ``S``_datap_15;\
  wire  ``S``_datan_15

// Connect serdes signals to Root-Complex
`define SERDES_PORT_CONNECT(A,B) \
                          .``A``_datap_0   (``B``_datap_0),\
                          .``A``_datan_0   (``B``_datan_0),\
                          .``A``_datap_1   (``B``_datap_1),\
                          .``A``_datan_1   (``B``_datan_1),\
                          .``A``_datap_2   (``B``_datap_2),\
                          .``A``_datan_2   (``B``_datan_2),\
                          .``A``_datap_3   (``B``_datap_3),\
                          .``A``_datan_3   (``B``_datan_3),\
                          .``A``_datap_4   (``B``_datap_4),\
                          .``A``_datan_4   (``B``_datan_4),\
                          .``A``_datap_5   (``B``_datap_5),\
                          .``A``_datan_5   (``B``_datan_5),\
                          .``A``_datap_6   (``B``_datap_6),\
                          .``A``_datan_6   (``B``_datan_6),\
                          .``A``_datap_7   (``B``_datap_7),\
                          .``A``_datan_7   (``B``_datan_7),\
                          .``A``_datap_8   (``B``_datap_8),\
                          .``A``_datan_8   (``B``_datan_8),\
                          .``A``_datap_9   (``B``_datap_9),\
                          .``A``_datan_9   (``B``_datan_9),\
                          .``A``_datap_10   (``B``_datap_10),\
                          .``A``_datan_10   (``B``_datan_10),\
                          .``A``_datap_11   (``B``_datap_11),\
                          .``A``_datan_11   (``B``_datan_11),\
                          .``A``_datap_12   (``B``_datap_12),\
                          .``A``_datan_12   (``B``_datan_12),\
                          .``A``_datap_13   (``B``_datap_13),\
                          .``A``_datan_13   (``B``_datan_13),\
                          .``A``_datap_14   (``B``_datap_14),\
                          .``A``_datan_14   (``B``_datan_14),\
                          .``A``_datap_15   (``B``_datap_15),\
                          .``A``_datan_15   (``B``_datan_15)

// Connect DUT serdes pins to x16 Root-Complex
`define ACX_PCIEX16_SERDES_PORT_CONNECT(A,B) \
                      .SRDS_N0_``A``_N0({``B``_datan_0,``B``_datan_0}),\
                      .SRDS_N0_``A``_P0({``B``_datap_0,``B``_datap_0}),\
                      .SRDS_N0_``A``_N1({``B``_datan_1,``B``_datan_1}),\
                      .SRDS_N0_``A``_P1({``B``_datap_1,``B``_datap_1}),\
                      .SRDS_N0_``A``_N2({``B``_datan_2,``B``_datan_2}),\
                      .SRDS_N0_``A``_P2({``B``_datap_2,``B``_datap_2}),\
                      .SRDS_N0_``A``_N3({``B``_datan_3,``B``_datan_3}),\
                      .SRDS_N0_``A``_P3({``B``_datap_3,``B``_datap_3}),\
                      .SRDS_N1_``A``_N0({``B``_datan_4,``B``_datan_4}),\
                      .SRDS_N1_``A``_P0({``B``_datap_4,``B``_datap_4}),\
                      .SRDS_N1_``A``_N1({``B``_datan_5,``B``_datan_5}),\
                      .SRDS_N1_``A``_P1({``B``_datap_5,``B``_datap_5}),\
                      .SRDS_N1_``A``_N2({``B``_datan_6,``B``_datan_6}),\
                      .SRDS_N1_``A``_P2({``B``_datap_6,``B``_datap_6}),\
                      .SRDS_N1_``A``_N3({``B``_datan_7,``B``_datan_7}),\
                      .SRDS_N1_``A``_P3({``B``_datap_7,``B``_datap_7}),\
                      .SRDS_N2_``A``_N0({``B``_datan_8,``B``_datan_8}),\
                      .SRDS_N2_``A``_P0({``B``_datap_8,``B``_datap_8}),\
                      .SRDS_N2_``A``_N1({``B``_datan_9,``B``_datan_9}),\
                      .SRDS_N2_``A``_P1({``B``_datap_9,``B``_datap_9}),\
                      .SRDS_N2_``A``_N2({``B``_datan_10,``B``_datan_10}),\
                      .SRDS_N2_``A``_P2({``B``_datap_10,``B``_datap_10}),\
                      .SRDS_N2_``A``_N3({``B``_datan_11,``B``_datan_11}),\
                      .SRDS_N2_``A``_P3({``B``_datap_11,``B``_datap_11}),\
                      .SRDS_N3_``A``_N0({``B``_datan_12,``B``_datan_12}),\
                      .SRDS_N3_``A``_P0({``B``_datap_12,``B``_datap_12}),\
                      .SRDS_N3_``A``_N1({``B``_datan_13,``B``_datan_13}),\
                      .SRDS_N3_``A``_P1({``B``_datap_13,``B``_datap_13}),\
                      .SRDS_N3_``A``_N2({``B``_datan_14,``B``_datan_14}),\
                      .SRDS_N3_``A``_P2({``B``_datap_14,``B``_datap_14}),\
                      .SRDS_N3_``A``_N3({``B``_datan_15,``B``_datan_15}),\
                      .SRDS_N3_``A``_P3({``B``_datap_15,``B``_datap_15})

// Connect DUT serdes pins to x8 Root-Complex
`define ACX_PCIEX8_SERDES_PORT_CONNECT(A,B) \
                      .SRDS_N6_``A``_N0({``B``_datan_0,``B``_datan_0}),\
                      .SRDS_N6_``A``_P0({``B``_datap_0,``B``_datap_0}),\
                      .SRDS_N6_``A``_N1({``B``_datan_1,``B``_datan_1}),\
                      .SRDS_N6_``A``_P1({``B``_datap_1,``B``_datap_1}),\
                      .SRDS_N6_``A``_N2({``B``_datan_2,``B``_datan_2}),\
                      .SRDS_N6_``A``_P2({``B``_datap_2,``B``_datap_2}),\
                      .SRDS_N6_``A``_N3({``B``_datan_3,``B``_datan_3}),\
                      .SRDS_N6_``A``_P3({``B``_datap_3,``B``_datap_3}),\
                      .SRDS_N7_``A``_N0({``B``_datan_4,``B``_datan_4}),\
                      .SRDS_N7_``A``_P0({``B``_datap_4,``B``_datap_4}),\
                      .SRDS_N7_``A``_N1({``B``_datan_5,``B``_datan_5}),\
                      .SRDS_N7_``A``_P1({``B``_datap_5,``B``_datap_5}),\
                      .SRDS_N7_``A``_N2({``B``_datan_6,``B``_datan_6}),\
                      .SRDS_N7_``A``_P2({``B``_datap_6,``B``_datap_6}),\
                      .SRDS_N7_``A``_N3({``B``_datan_7,``B``_datan_7}),\
                      .SRDS_N7_``A``_P3({``B``_datap_7,``B``_datap_7})

// Root-complex names
//`define ACX_RC_X8_NAME  root_x8
//`define ACX_RC_X16_NAME root_x16

// Utility define to turn a macro into a string
//`define ACX_STRINGIFY(x) `"x`"

`endif // INCLUDE_MACRO_DEFS

