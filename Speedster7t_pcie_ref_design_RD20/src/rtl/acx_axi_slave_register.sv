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
//     Function: AXI Slave Registers 
// ------------------------------------------------------------------

module acx_axi_slave_register # (
     parameter TGT_ADDR_WIDTH   = 28,
     parameter ID_WIDTH         = 8,
     parameter LEN_WIDTH        = 8,
     parameter BURST_WIDTH      = 2,
     parameter TGT_DATA_WIDTH   = 64,
     parameter RESP_WIDTH       = 2
) 
(
    // Input
    input  wire                             i_clk,
    input  wire                             i_rstn,
    input  wire                             i_awvalid,
    input  wire  [TGT_ADDR_WIDTH-1:0]       i_awaddr,
    input  wire  [ID_WIDTH-1:0]             i_awid,
    input  wire  [LEN_WIDTH-1:0]            i_awlen,
    input  wire  [BURST_WIDTH-1:0]          i_awburst,
    input  wire                             i_wvalid,
    input  wire  [TGT_DATA_WIDTH-1:0]       i_wdata,
    input  wire  [(TGT_DATA_WIDTH/8)-1:0]   i_wstrb,
    input  wire                             i_wlast,
    input  wire                             i_bready,
    input  wire                             i_arvalid,
    input  wire  [TGT_ADDR_WIDTH-1:0]       i_araddr,
    input  wire  [ID_WIDTH-1:0]             i_arid,
    input  wire  [LEN_WIDTH-1:0]            i_arlen,
    input  wire  [BURST_WIDTH-1:0]          i_arburst,
    input  wire                             i_rready,

    // Output
    output wire                             o_awready,
    output wire                             o_wready,
    output wire                             o_bvalid,
    output wire [RESP_WIDTH-1:0]            o_bresp,
    output wire [ID_WIDTH-1:0]              o_bid,
    output wire                             o_arready,
    output wire                             o_rvalid,
    output wire [TGT_DATA_WIDTH-1:0]        o_rdata,
    output wire [RESP_WIDTH-1:0]            o_rresp,
    output wire [ID_WIDTH-1:0]              o_rid,
    output wire                             o_rlast
);


   localparam STRB_WIDTH = 8;
   localparam REG_DATA_WIDTH = 64;
   

   
//-----------------------------------------------------------------
// AXI Interface
//-----------------------------------------------------------------
wire [TGT_ADDR_WIDTH-1:0]   addr_w;
wire [STRB_WIDTH-1:0]       wr_w;
wire                        rd_w;
wire                        accept_w;
wire [REG_DATA_WIDTH-1:0]   write_data_w;
wire [REG_DATA_WIDTH-1:0]   read_data_w;
wire [LEN_WIDTH-1:0]        len_w;
wire                        ack_w;
wire                        error_w;

// set top read bits to 0
   assign o_rdata[TGT_DATA_WIDTH-1:REG_DATA_WIDTH] = {192{1'b0}};
   
// Currently only support single cycle register access
// so burst length is set to 0.  Force to 0 to improve timing
// REVISIT - potential to allow burst accesses to registers as a future enhancement.   
acx_slave_reg_if # (
    .TGT_ADDR_WIDTH (TGT_ADDR_WIDTH ),
    .ID_WIDTH       (ID_WIDTH       ),
    .LEN_WIDTH      (LEN_WIDTH      ),
    .BURST_WIDTH    (BURST_WIDTH    ), 
    .TGT_DATA_WIDTH (REG_DATA_WIDTH ),
    .STRB_WIDTH     (STRB_WIDTH     ),
    .RESP_WIDTH     (RESP_WIDTH     )
) u_axi_reg_if (
    .i_clk              (i_clk),
    .i_rstn             (i_rstn),

    // AXI port
    .i_axi_awvalid      (i_awvalid),
    .i_axi_awaddr       (i_awaddr),
    .i_axi_awid         (i_awid),
    .i_axi_awlen        (i_awlen),
    .i_axi_awburst      (i_awburst),
    .i_axi_wvalid       (i_wvalid),
    .i_axi_wdata        (i_wdata[REG_DATA_WIDTH-1:0]),
    .i_axi_wstrb        (i_wstrb[STRB_WIDTH-1:0]),
    .i_axi_wlast        (i_wlast),
    .i_axi_bready       (i_bready),
    .i_axi_arvalid      (i_arvalid),
    .i_axi_araddr       (i_araddr),
    .i_axi_arid         (i_arid),
    .i_axi_arlen        (i_arlen),
    .i_axi_arburst      (i_arburst),
    .i_axi_rready       (i_rready),
    .o_axi_awready      (o_awready),
    .o_axi_wready       (o_wready),
    .o_axi_bvalid       (o_bvalid),
    .o_axi_bresp        (o_bresp),
    .o_axi_bid          (o_bid),
    .o_axi_arready      (o_arready),
    .o_axi_rvalid       (o_rvalid),
    .o_axi_rdata        (o_rdata[REG_DATA_WIDTH-1:0]),
    .o_axi_rresp        (o_rresp),
    .o_axi_rid          (o_rid),
    .o_axi_rlast        (o_rlast),
    
    // Register interface
    .o_reg_addr         (addr_w),
    .i_reg_accept       (accept_w),
    .o_reg_wr           (wr_w),
    .o_reg_rd           (rd_w),
    .o_reg_len          (len_w),
    .o_reg_write_data   (write_data_w),
    .i_reg_ack          (ack_w),
    .i_reg_error        (error_w),
    .i_reg_read_data    (read_data_w)
);

//-----------------------------------------------------------------
// Register core
//-----------------------------------------------------------------
acx_slave_reg_core
#(
    .TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
    .LEN_WIDTH      (LEN_WIDTH ), 
    .TGT_DATA_WIDTH (REG_DATA_WIDTH), 
    .STRB_WIDTH     (STRB_WIDTH)  
)
u_reg_core
(
    .i_clk          (i_clk),
    .i_rstn         (i_rstn),

    .i_wr           (wr_w),
    .i_rd           (rd_w),
    .i_len          (len_w),
    .i_addr         (addr_w),
    .i_write_data   (write_data_w),
    .o_accept       (accept_w),
    .o_ack          (ack_w),
    .o_error        (error_w),
    .o_read_data    (read_data_w)
);

endmodule : acx_axi_slave_register

