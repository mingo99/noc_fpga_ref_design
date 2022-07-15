//
// Copyright (c) 2016  Achronix Semiconductor Corp.
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
// Description: Example register set which connects to an AXI NAP
//---------------------------------------------------------------------------------

`timescale 1ps/1ps

`include "7t_interfaces.svh"

module axi_nap_register_set 
  #(
    parameter TGT_DATA_WIDTH = 0, // Target data width.
    parameter TGT_ADDR_WIDTH = 0,
    parameter NAP_COL        = 4'hx,
    parameter NAP_ROW        = 4'hx,
    parameter NAP_N2S_ARB_SCHED  = 32'hxxxxxxxx, // north-to-south arbitration schedule
    parameter NAP_S2N_ARB_SCHED  = 32'hxxxxxxxx  // south-to-north arbitration schedule
)
(
    // Clocks and reset
    input  wire                     i_clk,
    input  wire                     i_reset_n
);


   // first make the NAP interface
   // this contains all the AXI signals for NAP
   t_AXI4 #(
            .DATA_WIDTH (TGT_DATA_WIDTH),
            .ADDR_WIDTH (TGT_ADDR_WIDTH),
            .LEN_WIDTH  (8),
            .ID_WIDTH   (8))
   axi_if();

   // instantiate the NAP
   nap_master_wrapper
     #(
       .COLUMN (NAP_COL),
       .ROW    (NAP_ROW),
       .N2S_ARB_SCHED (NAP_N2S_ARB_SCHED),
       .S2N_ARB_SCHED (NAP_S2N_ARB_SCHED)
       )
   i_axi_master_nap(
                    // Inputs
                    .i_clk (i_clk),
                    .i_reset_n (i_reset_n), // Negative synchronous reset
                    .nap (axi_if), // Module is a master
                    // Outputs
                    .o_output_rstn (),
                    .o_error_valid (),
                    .o_error_info ()
                    );

acx_axi_slave_register #(.TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                         .TGT_DATA_WIDTH (TGT_DATA_WIDTH) // actual data is only 64 bits
                         )
i_acx_axi_slave_register
(
    .i_clk           (i_clk               ),                     //  input           
    .i_rstn          (i_reset_n           ),                     // ,input           
    .i_awvalid       (axi_if.awvalid      ),                     // ,input           
    .i_awaddr        (axi_if.awaddr       ),                     // ,input  [ 31:0]  
    .i_awid          (axi_if.awid         ),                     // ,input  [  3:0]  
    .i_awlen         (axi_if.awlen        ),                     // ,input  [  7:0]  
    .i_awburst       (axi_if.awburst      ),                     // ,input  [  1:0]  
    .i_wvalid        (axi_if.wvalid       ),                     // ,input           
    .i_wdata         (axi_if.wdata        ),                     // ,input  [ 31:0]  
    .i_wstrb         (axi_if.wstrb        ),                     // ,input  [  3:0]  
    .i_wlast         (axi_if.wlast        ),                     // ,input           
    .i_bready        (axi_if.bready       ),                     // ,input           
    .i_arvalid       (axi_if.arvalid      ),                     // ,input           
    .i_araddr        (axi_if.araddr       ),                     // ,input  [ 31:0]  
    .i_arid          (axi_if.arid         ),                     // ,input  [  3:0]  
    .i_arlen         (axi_if.arlen        ),                     // ,input  [  7:0]  
    .i_arburst       (axi_if.arburst      ),                     // ,input  [  1:0]  
    .i_rready        (axi_if.rready       ),                     // ,input           
    .o_awready       (axi_if.awready      ),                     // ,output          
    .o_wready        (axi_if.wready       ),                     // ,output          
    .o_bvalid        (axi_if.bvalid       ),                     // ,output          
    .o_bresp         (axi_if.bresp        ),                     // ,output [  1:0]  
    .o_bid           (axi_if.bid          ),                     // ,output [  3:0]  
    .o_arready       (axi_if.arready      ),                     // ,output          
    .o_rvalid        (axi_if.rvalid       ),                     // ,output          
    .o_rdata         (axi_if.rdata        ),                     // ,output [ 31:0]  
    .o_rresp         (axi_if.rresp        ),                     // ,output [  1:0]  
    .o_rid           (axi_if.rid          ),                     // ,output [  3:0]  
    .o_rlast         (axi_if.rlast        )                     // ,output          
);



endmodule : axi_nap_register_set

/* vim: set ts=3 sw=3 : */
