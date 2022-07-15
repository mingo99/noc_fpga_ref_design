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
// Wrapper around VERTICAL NAP to convert IO to a 
// SystemVerilog interface
// ------------------------------------------------------------------

`include "nap_interfaces.svh"

module nap_vertical_wrapper
#(
    parameter COLUMN        = 4'hx,
    parameter ROW           = 4'hx,
    parameter N2S_ARB_SCHED = 32'hxxxxxxxx, // north-to-south arbitration schedule
    parameter S2N_ARB_SCHED = 32'hxxxxxxxx  // south-to-north arbitration schedule
)
(
    // Inputs
    input wire              i_clk,
    input wire              i_reset_n,      // Negative synchronous reset
    // Modport types are swapped here compared to names
    // This is because the NAP rx channel is data received from the NoC,
    // hence it has to be a transmitter from the NAP
    // The stream names are then correct from the perspective of the user design
    t_DATA_STREAM.rx        if_ds_tx,       // Data stream to transmit to NoC, (NAP receives data)
    t_DATA_STREAM.tx        if_ds_rx,       // Data stream to receive from NoC, (NAP transmits data)
    output wire             o_output_rstn
);

    // Instantiate vertical NAP and connect ports to SV interface
    // noprune and must_keep is required as otherwise synthesis 
    // does not see this module connect to anything external.
    ACX_NAP_VERTICAL #(
        .must_keep                  (1),
        .column                     (COLUMN),
        .row                        (ROW),
        .n2s_arbitration_schedule   (N2S_ARB_SCHED),
        .s2n_arbitration_schedule   (S2N_ARB_SCHED)
    ) i_nap_vertical (
        .clk                        (i_clk),
        .rstn                       (i_reset_n),
        .output_rstn                (o_output_rstn),
        // rx_ signals are data stream output from NAP
        .rx_ready                   (if_ds_rx.ready),
        .rx_valid                   (if_ds_rx.valid),
        .rx_sop                     (if_ds_rx.sop),
        .rx_eop                     (if_ds_rx.eop),
        .rx_data                    (if_ds_rx.data),
        .rx_src                     (if_ds_rx.addr),
        // tx_ signals are data stream input to NAP
        .tx_ready                   (if_ds_tx.ready),
        .tx_valid                   (if_ds_tx.valid),
        .tx_sop                     (if_ds_tx.sop),
        .tx_eop                     (if_ds_tx.eop),
        .tx_dest                    (if_ds_tx.addr),
        .tx_data                    (if_ds_tx.data)
    ) /* synthesis syn_noprune=1 */;
   
endmodule : nap_vertical_wrapper

