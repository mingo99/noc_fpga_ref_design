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
// Wrapper around a VERTICAL NAP to convert IO to an Ethernet
// SystemVerilog interface
// ------------------------------------------------------------------

`include "7t_interfaces.svh"

module nap_ethernet_wrapper
#(
    parameter NUM_MOD_VALUE = 0,            // Set to 1 to enable the numerical mod ports
                                            // When set to 0 enables the bit per lane mod
    parameter N2S_ARB_SCHED = 32'hxxxxxxxx, // north-to-south arbitration schedule
    parameter S2N_ARB_SCHED = 32'hxxxxxxxx  // south-to-north arbitration schedule
)
(
    // Inputs
    input wire 	        i_clk,
    input wire 	        i_reset_n,   // Negative synchronous reset
    // Modport types are swapped here compared to names
    // This is because the NAP rx channel is data received from the NoC,
    // hence it has to be a transmitter from the NAP
    // The stream names are then correct from the perspective of the user design
    t_ETH_STREAM.rx      if_eth_tx,   // Ethernet stream to transmit to NoC, (NAP receives data)
    t_ETH_STREAM.tx      if_eth_rx,   // Ethernet stream to receive from NoC, (NAP transmits data)
    output wire 	     o_output_rstn
);

    // Vertical NAP data width is 293 bits.
    // Composed of data=256, mod=5, flags=30, spare=2
    logic [`ACX_NAP_VERTICAL_DATA_WIDTH -1:0] if_eth_tx_data;
    logic [`ACX_NAP_ETH_FLAG_WIDTH      -1:0] if_eth_tx_flags;
    logic [2                            -1:0] if_eth_tx_spare = 2'b00;
    logic [`ACX_NAP_VERTICAL_DATA_WIDTH -1:0] if_eth_rx_data;
    logic [`ACX_NAP_ETH_FLAG_WIDTH      -1:0] if_eth_rx_flags;
    logic [2                            -1:0] if_eth_rx_spare;

    // Assign elements to concatenated data buses
    assign if_eth_tx_data = {if_eth_tx_spare, if_eth_tx_flags, if_eth_tx.mod, if_eth_tx.data};
    assign {if_eth_rx_spare, if_eth_rx_flags, if_eth_rx.mod, if_eth_rx.data} = if_eth_rx_data;

    // Default EIU destination is row 0xf.
    // Ignore the address assignment input to this wrapper
    logic [`ACX_NAP_DS_ADDR_WIDTH -1:0] if_eth_tx_addr;
    assign if_eth_tx_addr = `ACX_NAP_DS_ADDR_WIDTH'hf;

    // Instantiate vertical NAP and connect ports to SV interface
    // noprune and must_keep is required as otherwise synthesis 
    // does not see this module connect to anything external.
    ACX_NAP_VERTICAL #(
       .must_keep                (1),
       .n2s_arbitration_schedule (N2S_ARB_SCHED),
       .s2n_arbitration_schedule (S2N_ARB_SCHED)
   ) i_nap_vertical (
        .clk            (i_clk),
        .rstn           (i_reset_n),
        .output_rstn    (o_output_rstn),
        // rx_ signals are data stream output from NAP
        .rx_ready       (if_eth_rx.ready),
        .rx_valid       (if_eth_rx.valid),
        .rx_sop         (if_eth_rx.sop),
        .rx_eop         (if_eth_rx.eop),
        .rx_data        (if_eth_rx_data),
        .rx_src         (if_eth_rx.addr),
        // tx_ signals are data stream input to NAP
        .tx_ready       (if_eth_tx.ready),
        .tx_valid       (if_eth_tx.valid),
        .tx_sop         (if_eth_tx.sop),
        .tx_eop         (if_eth_tx.eop),
        .tx_dest        (if_eth_tx_addr),
        .tx_data        (if_eth_tx_data)
    ) /* synthesis syn_noprune=1 */;

    // Timestamp is valid on SoP cycle, flags are valid on all other cycles
    // Union joins the flags together.  Only one data set, so drive directly from data input
    assign if_eth_rx.flags     = (if_eth_rx.sop) ? `ACX_NAP_ETH_FLAG_WIDTH'b0 : if_eth_rx_flags;
    assign if_eth_rx.timestamp = (if_eth_rx.sop) ? if_eth_rx_flags : `ACX_NAP_ETH_FLAG_WIDTH'b0;

    assign if_eth_tx_flags = (if_eth_tx.sop) ?  if_eth_tx.timestamp : if_eth_tx.flags.tx;

endmodule : nap_ethernet_wrapper
