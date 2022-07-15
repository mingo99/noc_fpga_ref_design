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
//

//---------------------------------------------------------------------------------
// File : Common interfaces for 7t devices
//---------------------------------------------------------------------------------
`timescale 1ps/1ps

`ifndef INCLUDE_7T_INTERFACES_SVH
`define INCLUDE_7T_INTERFACES_SVH

typedef logic [256 -1:0] t_mlp_out;

// AXI4 interface used by NOC
interface t_AXI4
    #(parameter DATA_WIDTH = 0,
      parameter ADDR_WIDTH = 0,
      parameter LEN_WIDTH  = 0);
    logic                       awvalid;
    logic                       awready;
    logic [ADDR_WIDTH -1:0]     awaddr;
    logic [LEN_WIDTH -1:0]      awlen;
    logic [8 -1:0]              awid;
    logic [4 -1:0]              awqos;
    logic [2 -1:0]              awburst;
    logic                       awlock;
    logic [3 -1:0]              awsize;
    logic [3 -1:0]              awregion;
    logic                       wvalid;
    logic                       wready;
    logic [DATA_WIDTH -1:0]     wdata;
    logic [(DATA_WIDTH/8) -1:0] wstrb;
    logic                       wlast;
    logic                       arready;
    logic [DATA_WIDTH -1:0]     rdata;
    logic                       rlast;
    logic [2 -1:0]              rresp;
    logic                       rvalid;
    logic [8 -1:0]              rid;
    logic [ADDR_WIDTH -1:0]     araddr;
    logic [LEN_WIDTH -1:0]      arlen;
    logic [8 -1:0]              arid;
    logic [4 -1:0]              arqos;
    logic [2 -1:0]              arburst;
    logic                       arlock;
    logic [3 -1:0]              arsize;
    logic                       arvalid;
    logic [3 -1:0]              arregion;
    logic                       rready;
    logic                       bvalid;
    logic                       bready;
    logic [2 -1:0]              bresp;
    logic [8 -1:0]              bid;
    modport master (input  awready, bresp, bvalid, bid, wready, arready, rdata, rlast, rresp, rvalid, rid,
                    output awaddr, awlen, awid, awqos, awburst, awlock, awsize, awvalid, awregion, bready, wdata, wlast, 
                           rready, wstrb, wvalid, araddr, arlen, arid, arqos, arburst, arlock, arsize, arvalid, arregion);
    modport slave  (output awready, bresp, bvalid, bid, wready, arready, rdata, rlast, rresp, rvalid, rid,
                    input  awaddr, awlen, awid, awqos, awburst, awlock, awsize, awvalid,  awregion, bready, wdata, wlast,
                           rready, wstrb, wvalid, araddr, arlen, arid, arqos, arburst, arlock, arsize, arvalid, arregion);
    modport monitor (input awready, bresp, bvalid, bid, wready, arready, rdata, rlast, rresp, rvalid, rid,
                           awaddr, awlen, awid, awqos, awburst, awlock, awsize, awvalid,  awregion, bready, wdata, wlast,
                           rready, wstrb, wvalid, araddr, arlen, arid, arqos, arburst, arlock, arsize, arvalid, arregion);
endinterface : t_AXI4

`endif // INCLUDE_7T_INTERFACES_SVH

