// ------------------------------------------------------------------
//
// Copyright (c) 2021 Achronix Semiconductor Corp.
// All Rights Reserved.
//
// This Software constitutes an unpublished work and contains
// valuable proprietary information and trade secrets belonging
// to Achronix Semiconductor Corp.
//
// Permission is hereby granted to use this Software including
// without limitation the right to copy, modify, merge or distribute
// copies of the software subject to the following condition:
//
// The above copyright notice and this permission notice shall
// be included in in all copies of the Software.
//
// The Software is provided “as is” without warranty of any kind
// expressed or implied, including  but not limited to the warranties
// of merchantability fitness for a particular purpose and non-infringement.
// In no event shall the copyright holder be liable for any claim,
// damages, or other liability for any damages or other liability,
// whether an action of contract, tort or otherwise, arising from, 
// out of, or in connection with the Software
//
// ------------------------------------------------------------------
// Wrapper around AXI SLAVE NAP to convert IO to a 
// SystemVerilog interface
// ------------------------------------------------------------------

`include "nap_interfaces.svh"

module nap_slave_wrapper
#(
    parameter CSR_ACCESS_ENABLE = 1'b0,         // Enable NAP access to CSR space
    parameter COLUMN            = 4'hx,
    parameter ROW               = 4'hx,
    parameter E2W_ARB_SCHED     = 32'hxxxxxxxx, // east-to-west arbitration schedule
    parameter W2E_ARB_SCHED     = 32'hxxxxxxxx  // west-to-east arbitration schedule
)
(
    // Inputs
    input  wire         i_clk,
    input  wire         i_reset_n,              // Negative synchronous reset
    t_AXI4.slave        nap,                    // Module is a slave

    output wire         o_output_rstn,
    output wire         o_error_valid,
    output wire [2:0]   o_error_info
);

    // Instantiate slave and connect ports to SV interface
    // noprune is required as otherwise synthesis does not see this module connect to anything external.
    ACX_NAP_AXI_SLAVE #(
        .must_keep                  (1),
        .csr_access_enable          (CSR_ACCESS_ENABLE),
        .column                     (COLUMN),
        .row                        (ROW),
        .e2w_arbitration_schedule   (E2W_ARB_SCHED),
        .w2e_arbitration_schedule   (W2E_ARB_SCHED)
   ) i_axi_slave (
        .clk            (i_clk),
        .rstn           (i_reset_n),
        .output_rstn    (o_output_rstn),
        .arready        (nap.arready),
        .arvalid        (nap.arvalid),
        .arqos          (nap.arqos),
        .arburst        (nap.arburst),
        .arlock         (nap.arlock),
        .arsize         (nap.arsize),
        .arlen          (nap.arlen),
        .arid           (nap.arid),
        .araddr         (nap.araddr),
        .awready        (nap.awready),
        .awvalid        (nap.awvalid),
        .awqos          (nap.awqos),
        .awburst        (nap.awburst),
        .awlock         (nap.awlock),
        .awsize         (nap.awsize),
        .awlen          (nap.awlen),
        .awid           (nap.awid),
        .awaddr         (nap.awaddr),
        .wready         (nap.wready),
        .wvalid         (nap.wvalid),
        .wdata          (nap.wdata),
        .wstrb          (nap.wstrb),
        .wlast          (nap.wlast),
        .rready         (nap.rready),
        .rvalid         (nap.rvalid),
        .rresp          (nap.rresp),
        .rid            (nap.rid),
        .rdata          (nap.rdata),
        .rlast          (nap.rlast),
        .bready         (nap.bready),
        .bvalid         (nap.bvalid),
        .bid            (nap.bid),
        .bresp          (nap.bresp),
        .error_valid    (o_error_valid),
        .error_info     (o_error_info)
    ) /* synthesis syn_noprune=1 */;

endmodule : nap_slave_wrapper

