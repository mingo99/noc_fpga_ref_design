// ------------------------------------------------------------------
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
// ------------------------------------------------------------------
// Wrapper around AXI MASTER NAP to convert IO to a 
// SystemVerilog interface
// ------------------------------------------------------------------

`include "7t_interfaces.svh"

module nap_master_wrapper
  #(
    parameter COLUMN        = 4'hx,
    parameter ROW           = 4'hx,
    parameter N2S_ARB_SCHED = 32'hxxxxxxxx, // north-to-south arbitration schedule
    parameter S2N_ARB_SCHED = 32'hxxxxxxxx  // south-to-north arbitration schedule
    )
   (
    // Inputs
    input wire          i_clk,
    input wire          i_reset_n,          // Negative synchronous reset
    t_AXI4.master       nap,                // Module is a master

    output wire         o_output_rstn,
    output wire         o_error_valid,
    output wire [2:0]   o_error_info
    );

   // Instantiate slave and connect ports to SV interface
   // noprune is required as otherwise synthesis does not see this module connect to anything external.
   ACX_NAP_AXI_MASTER 
     #(.column    (COLUMN),
       .row       (ROW),
       .n2s_arbitration_schedule (N2S_ARB_SCHED),
       .s2n_arbitration_schedule (S2N_ARB_SCHED),
       .must_keep (1)
       )
     i_axi_master (
                   .clk         (i_clk),
                   .rstn        (i_reset_n),
                   .output_rstn (o_output_rstn),
                   .arready     (nap.arready),
                   .arvalid     (nap.arvalid),
                   .arqos       (nap.arqos),
                   .arburst     (nap.arburst),
                   .arlock      (nap.arlock),
                   .arsize      (nap.arsize),
                   .arlen       (nap.arlen),
                   .arid        (nap.arid),
                   .araddr      (nap.araddr[27:0]),
                   .awready     (nap.awready),
                   .awvalid     (nap.awvalid),
                   .awqos       (nap.awqos),
                   .awburst     (nap.awburst),
                   .awlock      (nap.awlock),
                   .awsize      (nap.awsize),
                   .awlen       (nap.awlen),
                   .awid        (nap.awid),
                   .awaddr      (nap.awaddr[27:0]),
                   .wready      (nap.wready),
                   .wvalid      (nap.wvalid),
                   .wdata       (nap.wdata),
                   .wstrb       (nap.wstrb),
                   .wlast       (nap.wlast),
                   .rready      (nap.rready),
                   .rvalid      (nap.rvalid),
                   .rresp       (nap.rresp),
                   .rid         (nap.rid),
                   .rdata       (nap.rdata),
                   .rlast       (nap.rlast),
                   .bready      (nap.bready),
                   .bvalid      (nap.bvalid),
                   .bid         (nap.bid),
                   .bresp       (nap.bresp),
                   .error_valid (o_error_valid),
                   .error_info  (o_error_info)
                   ) /* synthesis syn_noprune=1 */;
   
endmodule : nap_master_wrapper

