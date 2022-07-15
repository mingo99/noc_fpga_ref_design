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
// Speedster7t GDDR reference design (RD17)
//      Defines to create and connect logic to GDDR DCI ports
// ------------------------------------------------------------------

`ifndef INCLUDE_GDDR_DCI_PORT_NAMES
`define INCLUDE_GDDR_DCI_PORT_NAMES

`define ACX_GDDR_DCI_INPUT(S) \
input wire                      ``S``_clk,\
input wire                      ``S``_aresetn, \
input wire                      ``S``_awready ,\
input wire                      ``S``_wready ,\
input wire                      ``S``_arready ,\
input wire                      ``S``_rvalid ,\
input wire [512 -1:0]           ``S``_rdata ,\
input wire                      ``S``_rlast ,\
input wire [2 -1:0]             ``S``_rresp ,\
input wire [7 -1:0]             ``S``_rid ,\
input wire                      ``S``_bvalid ,\
input wire [2 -1:0]             ``S``_bresp ,\
input wire [7 -1:0]             ``S``_bid

    

`define ACX_GDDR_DCI_OUTPUT(S) \
output wire                     ``S``_awvalid ,\
output wire [33 -1:0]           ``S``_awaddr ,\
output wire [8 -1:0]            ``S``_awlen ,\
output wire [7 -1:0]            ``S``_awid ,\
output wire [3 -1:0]            ``S``_awqos ,\
output wire [2 -1:0]            ``S``_awburst ,\
output wire                     ``S``_awlock ,\
output wire [3 -1:0]            ``S``_awsize ,\
output wire                     ``S``_wvalid ,\
output wire [512 -1:0]          ``S``_wdata ,\
output wire [(512/8) -1:0]      ``S``_wstrb ,\
output wire                     ``S``_wlast ,\
output wire                     ``S``_arvalid ,\
output wire [33 -1:0]           ``S``_araddr ,\
output wire [8 -1:0]            ``S``_arlen ,\
output wire [7 -1:0]            ``S``_arid ,\
output wire [3 -1:0]            ``S``_arqos ,\
output wire [2 -1:0]            ``S``_arburst ,\
output wire                     ``S``_arlock ,\
output wire [3 -1:0]            ``S``_arsize ,\
output wire                     ``S``_rready ,\
output wire                     ``S``_bready ,\
output wire [4 -1:0]            ``S``_arcache ,\
output wire [4 -1:0]            ``S``_awcache ,\
output wire [3 -1:0]            ``S``_arprot ,\
output wire [3 -1:0]            ``S``_awprot
    

`define ACX_GDDR_DCI_ASSIGN(A,B) \
assign ``A``_awaddr       =     ``B``.dci.awaddr;\
assign ``A``_awlen        =     ``B``.dci.awlen;\
assign ``A``_arcache      =     ``B``.dci.arcache;\
assign ``A``_awcache      =     ``B``.dci.awcache;\
assign ``A``_arprot       =     ``B``.dci.arprot;\
assign ``A``_awprot       =     ``B``.dci.awprot;\
assign ``A``_awid         =     ``B``.dci.awid;\
assign ``A``_awqos        =     ``B``.dci.awqos;\
assign ``A``_awburst      =     ``B``.dci.awburst;\
assign ``A``_awlock       =     ``B``.dci.awlock;\
assign ``A``_awsize       =     ``B``.dci.awsize;\
assign ``A``_wvalid       =     ``B``.dci.wvalid;\
assign ``A``_wdata        =     ``B``.dci.wdata;\
assign ``A``_wstrb        =     ``B``.dci.wstrb;\
assign ``A``_wlast        =     ``B``.dci.wlast;\
assign ``A``_arvalid      =     ``B``.dci.arvalid;\
assign ``A``_araddr       =     ``B``.dci.araddr;\
assign ``A``_arlen        =     ``B``.dci.arlen;\
assign ``A``_arid         =     ``B``.dci.arid;\
assign ``A``_arqos        =     ``B``.dci.arqos;\
assign ``A``_arburst      =     ``B``.dci.arburst;\
assign ``A``_arlock       =     ``B``.dci.arlock;\
assign ``A``_arsize       =     ``B``.dci.arsize;\
assign ``A``_rready       =     ``B``.dci.rready;\
assign ``A``_bready       =     ``B``.dci.bready;\
assign ``A``_awvalid      =     ``B``.dci.awvalid;\
assign ``B``.dci.awready  =     ``A``_awready;\
assign ``B``.dci.wready   =     ``A``_wready;\
assign ``B``.dci.arready  =     ``A``_arready;\
assign ``B``.dci.rvalid   =     ``A``_rvalid;\
assign ``B``.dci.rdata    =     ``A``_rdata;\
assign ``B``.dci.rlast    =     ``A``_rlast;\
assign ``B``.dci.rresp    =     ``A``_rresp;\
assign ``B``.dci.rid      =     ``A``_rid;\
assign ``B``.dci.bvalid   =     ``A``_bvalid;\
assign ``B``.dci.bresp    =     ``A``_bresp;\
assign ``B``.dci.bid      =     ``A``_bid;

// Macro definitions used in testbench
`define ACX_GDDR_TB_DCI_PORT(S) \
logic                   ``S``_clk ;\
logic                   ``S``_aresetn;\
logic                   ``S``_awready;\
logic                   ``S``_wready;\
logic                   ``S``_arready;\
logic                   ``S``_rvalid;\
logic [512 -1:0]        ``S``_rdata;\
logic                   ``S``_rlast;\
logic [2 -1:0]          ``S``_rresp;\
logic [7 -1:0]          ``S``_rid;\
logic                   ``S``_bvalid;\
logic [2 -1:0]          ``S``_bresp;\
logic [7 -1:0]          ``S``_bid;\
logic [4 -1:0]          ``S``_arcache;\
logic [4 -1:0]          ``S``_awcache;\
logic [3 -1:0]          ``S``_arprot;\
logic [3 -1:0]          ``S``_awprot;\
logic                   ``S``_awvalid;\
logic [33 -1:0]         ``S``_awaddr;\
logic [8 -1:0]          ``S``_awlen;\
logic [7 -1:0]          ``S``_awid;\
logic [3 -1:0]          ``S``_awqos;\
logic [2 -1:0]          ``S``_awburst;\
logic                   ``S``_awlock;\
logic [3 -1:0]          ``S``_awsize;\
logic                   ``S``_wvalid;\
logic [512 -1:0]        ``S``_wdata;\
logic [(512/8) -1:0]    ``S``_wstrb;\
logic                   ``S``_wlast;\
logic                   ``S``_arvalid;\
logic [33 -1:0]         ``S``_araddr;\
logic [8 -1:0]          ``S``_arlen;\
logic [7 -1:0]          ``S``_arid;\
logic [3 -1:0]          ``S``_arqos;\
logic [2 -1:0]          ``S``_arburst;\
logic                   ``S``_arlock;\
logic [3 -1:0]          ``S``_arsize;\
logic                   ``S``_rready;\
logic                   ``S``_bready;


`define ACX_GDDR_TB_DCI_ASSIGN(A,B) \
assign ``A``_clk               = ac7t1500.interfaces.``B``.clk;\
assign ac7t1500.interfaces.``B``.awvalid  = ``A``_awvalid;\
assign ac7t1500.interfaces.``B``.awaddr   = ``A``_awaddr;\
assign ac7t1500.interfaces.``B``.awlen    = ``A``_awlen;\
assign ac7t1500.interfaces.``B``.awid     = ``A``_awid;\
assign ac7t1500.interfaces.``B``.awqos    = ``A``_awqos;\
assign ac7t1500.interfaces.``B``.awburst  = ``A``_awburst;\
assign ac7t1500.interfaces.``B``.awlock   = ``A``_awlock;\
assign ac7t1500.interfaces.``B``.awsize   = ``A``_awsize;\
assign ac7t1500.interfaces.``B``.wvalid   = ``A``_wvalid;\
assign ac7t1500.interfaces.``B``.wdata    = ``A``_wdata;\
assign ac7t1500.interfaces.``B``.wstrb    = ``A``_wstrb;\
assign ac7t1500.interfaces.``B``.wlast    = ``A``_wlast;\
assign ac7t1500.interfaces.``B``.arvalid  = ``A``_arvalid;\
assign ac7t1500.interfaces.``B``.araddr   = ``A``_araddr;\
assign ac7t1500.interfaces.``B``.arlen    = ``A``_arlen;\
assign ac7t1500.interfaces.``B``.arid     = ``A``_arid;\
assign ac7t1500.interfaces.``B``.arqos    = ``A``_arqos;\
assign ac7t1500.interfaces.``B``.arburst  = ``A``_arburst;\
assign ac7t1500.interfaces.``B``.arlock   = ``A``_arlock;\
assign ac7t1500.interfaces.``B``.arsize   = ``A``_arsize;\
assign ac7t1500.interfaces.``B``.rready   = ``A``_rready;\
assign ac7t1500.interfaces.``B``.bready   = ``A``_bready;\
assign ``A``_awready           = ac7t1500.interfaces.``B``.awready;\
assign ``A``_wready            = ac7t1500.interfaces.``B``.wready;\
assign ``A``_arready           = ac7t1500.interfaces.``B``.arready;\
assign ``A``_rvalid            = ac7t1500.interfaces.``B``.rvalid;\
assign ``A``_rdata             = ac7t1500.interfaces.``B``.rdata;\
assign ``A``_rlast             = ac7t1500.interfaces.``B``.rlast;\
assign ``A``_rresp             = ac7t1500.interfaces.``B``.rresp;\
assign ``A``_rid               = ac7t1500.interfaces.``B``.rid;\
assign ``A``_bvalid            = ac7t1500.interfaces.``B``.bvalid;\
assign ``A``_bresp             = ac7t1500.interfaces.``B``.bresp;\
assign ``A``_bid               = ac7t1500.interfaces.``B``.bid;\
assign ``A``_aresetn           =reset_n;

`endif // INCLUDE_GDDR_DCI_PORT_NAMES

