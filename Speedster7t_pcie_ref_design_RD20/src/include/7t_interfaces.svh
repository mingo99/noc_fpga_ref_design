//
// Copyright (c) 2021  Achronix Semiconductor Corp.
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

//---------------------------------------------------------------------------------
// Fixed NoC system widths
//---------------------------------------------------------------------------------

// AXI NAP
`define ACX_NAP_AXI_DATA_WIDTH        256
`define ACX_NAP_AXI_SLAVE_ADDR_WIDTH  42    // Slave AXI address is full address space
`define ACX_NAP_AXI_MSTR_ADDR_WIDTH   28    // Master AXI address is only 28 bits

// Data Streaming NAP
`define ACX_NAP_VERTICAL_DATA_WIDTH   293
`define ACX_NAP_HORIZONTAL_DATA_WIDTH 288
`define ACX_NAP_DS_ADDR_WIDTH         4

// Ethernet NAP
`define ACX_NAP_ETH_DATA_WIDTH        256
`define ACX_NAP_ETH_MOD_WIDTH         5     // The NAP processes mod as a numerical value
                                            // So the width is how many bits required to represent the value
`define ACX_NAP_ETH_FLAG_WIDTH        30    // Number of bits in the flags / timestamp section

// GDDR DCI
`define ACX_GDDR_DCI_AXI_DATA_WIDTH        512
`define ACX_GDDR_DCI_AXI_ADDR_WIDTH        33

//---------------------------------------------------------------------------------
// AXI4 interface
//---------------------------------------------------------------------------------
// AXI4 interface can be used in multiple locations, therefore default value not assigned
interface t_AXI4
    #(parameter DATA_WIDTH = 0,
      parameter ADDR_WIDTH = 0,
      parameter LEN_WIDTH  = 0,
      parameter ID_WIDTH   = 0);
    logic                       awvalid;
    logic                       awready;
    logic [ADDR_WIDTH -1:0]     awaddr;
    logic [LEN_WIDTH  -1:0]     awlen;
    logic [ID_WIDTH   -1:0]     awid;
    logic [4 -1:0]              awqos;
    logic [2 -1:0]              awburst;
    logic                       awlock;
    logic [3 -1:0]              awsize;
    logic [3 -1:0]              awregion;
    logic [3 -1:0]              awprot;
    logic [4 -1:0]              awcache;
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
    logic [ID_WIDTH   -1:0]     rid;
    logic [ADDR_WIDTH -1:0]     araddr;
    logic [LEN_WIDTH  -1:0]     arlen;
    logic [ID_WIDTH   -1:0]     arid;
    logic [4 -1:0]              arqos;
    logic [2 -1:0]              arburst;
    logic                       arlock;
    logic [3 -1:0]              arsize;
    logic                       arvalid;
    logic [3 -1:0]              arregion;
    logic [3 -1:0]              arprot;
    logic [4 -1:0]              arcache;
    logic                       rready;
    logic                       bvalid;
    logic                       bready;
    logic [2 -1:0]              bresp;
    logic [ID_WIDTH -1:0]       bid;
    modport master (input  awready, bresp, bvalid, bid, wready, arready, rdata, rlast, rresp, rvalid, rid,
                    output awaddr, awlen, awid, awqos, awburst, awlock, awsize, awvalid, awregion, awprot, awcache, 
                           bready, rready, wstrb, wvalid, wdata, wlast,
                           araddr, arlen, arid, arqos, arburst, arlock, arsize, arvalid, arregion, arprot, arcache);
    modport slave  (output awready, bresp, bvalid, bid, wready, arready, rdata, rlast, rresp, rvalid, rid,
                    input  awaddr, awlen, awid, awqos, awburst, awlock, awsize, awvalid, awregion,  awprot, awcache,
                           bready, rready, wstrb, wvalid, wdata, wlast,
                           araddr, arlen, arid, arqos, arburst, arlock, arsize, arvalid, arregion, arprot, arcache);
endinterface : t_AXI4

//---------------------------------------------------------------------------------
// Data Streaming interface
//---------------------------------------------------------------------------------
// This interface covers one direction, two interfaces are required per NAP
// As the interface applies to both vertical and horizontal NAPs, DATA_WIDTH will vary
interface t_DATA_STREAM
  #(parameter DATA_WIDTH = 0,
    parameter ADDR_WIDTH = `ACX_NAP_DS_ADDR_WIDTH);
    logic                    ready;
    logic                    valid;
    logic [DATA_WIDTH -1:0]  data;
    logic                    eop;
    logic                    sop;
    logic [ADDR_WIDTH -1:0]  addr;

    modport rx ( input  valid, eop, sop, data, addr, output ready);
    modport tx ( input  ready, output valid, eop, sop, data, addr);

    // Primarily for simulation usage
    // Used to validate a stream, measure throughput, count packets, and rate control
    modport monitor ( input  valid, eop, sop, data, addr, ready);

endinterface : t_DATA_STREAM

//---------------------------------------------------------------------------------
// Ethernet streaming interface
//---------------------------------------------------------------------------------

// Structure of Ethernet flags.  Defined as a packed array to allow conversion
// between the flag structure and the timestamp field
// TX flags are output by the timestamp field on all cycles except when SoP = 1
typedef struct packed {
    logic [(`ACX_NAP_ETH_FLAG_WIDTH-24) -1:0]   unused;
    logic                                       class_b;
    logic                                       class_a;
    logic                                       crc_ovr;
    logic                                       crc_inv;
    logic                                       crc;
    logic                                       error;
    logic                                       frame;
    logic [17 -1:0]                             id;
} t_ETH_TX_FLAGS;

// RX flags are input by the timestamp field on all cycles except when SoP = 1
typedef struct packed {
    logic [(`ACX_NAP_ETH_FLAG_WIDTH-14) -1:0]   unused;
    logic [5 -1:0]                              seq_id;
    logic [8 -1:0]                              err_stat;
    logic                                       err;
} t_ETH_RX_FLAGS;

// Following 2 fields overload the same 30 bits
// Although timestamp should also be applied here, the selection is done within 
// the nap_ethernet_wrapper.  So to ease user design, timestamp is defined
// separately
typedef union packed {
    t_ETH_TX_FLAGS              tx;
    t_ETH_RX_FLAGS              rx;
} t_ETH_FLAG_UNION;

// Ethernet streaming interface.  This covers one direction, two interfaces are required per NAP
interface t_ETH_STREAM
  #(parameter DATA_WIDTH = `ACX_NAP_ETH_DATA_WIDTH,
    parameter MOD_WIDTH  = `ACX_NAP_ETH_MOD_WIDTH,
    parameter ADDR_WIDTH = `ACX_NAP_DS_ADDR_WIDTH );
    logic [ADDR_WIDTH -1:0]                 addr;    // Default EIU address is 0xf
    logic                                   ready;
    logic                                   valid;
    logic [DATA_WIDTH -1:0]                 data;
    logic                                   eop;
    logic                                   sop;
    logic [MOD_WIDTH  -1:0]                 mod;
    logic [`ACX_NAP_ETH_FLAG_WIDTH -1:0]    timestamp;
    t_ETH_FLAG_UNION                        flags;

    modport rx ( input  addr, valid, eop, sop, data, mod, flags, timestamp, output ready);
    modport tx ( input  ready, output addr, valid, eop, sop, data, mod, flags, timestamp);
    
    // For simulation usage, to validate a stream, measure throughput and count packets
    modport monitor ( input  addr, valid, eop, sop, data, mod, flags, timestamp, ready);

endinterface : t_ETH_STREAM

// NoC passes mod as numerical value.
// Many existing interfaces represent mod as a bitwise value, with '1' set per valid lane
// Provide functions to convert between the two
`define ACX_NAP_ETH_BITWISE_MOD_WIDTH  (`ACX_NAP_ETH_DATA_WIDTH/8)

// Convert from bitwise mod to a numerical mod
function [`ACX_NAP_ETH_MOD_WIDTH -1:0] acx_num_mod (logic [`ACX_NAP_ETH_BITWISE_MOD_WIDTH -1:0] bitwise_mod);
    acx_num_mod = 0;
    while ( bitwise_mod )
    begin
        bitwise_mod = (bitwise_mod>>1);
        acx_num_mod++;
    end
endfunction;

// Convert from a numerical mod to a bitwise form
function [`ACX_NAP_ETH_BITWISE_MOD_WIDTH -1:0] acx_bitwise_mod (logic [`ACX_NAP_ETH_MOD_WIDTH -1:0] num_mod);
    acx_bitwise_mod = (2**num_mod) - 1;
endfunction;


`endif // INCLUDE_7T_INTERFACES_SVH

