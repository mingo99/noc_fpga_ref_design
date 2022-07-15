// ------------------------------------------------------------------
//
// Copyright (c) 2019  Achronix Semiconductor Corp.
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
// MLP in 16 8x8 mode
// Use dot_product_16_8x8 macro
// ------------------------------------------------------------------

`timescale 1 ps / 1 ps

// Include interfaces here, need to ensure this is then the first file in synthesis list
`include "7t_interfaces.svh"

module mlp_wrapper_multi
#(
    parameter                           IN_DATA_WIDTH   = 144,
    parameter                           BRAM_ADDR_WIDTH = 10,
    parameter                           BRAM_DATA_WIDTH = 64,
    parameter                           NUM_MLP         = 4,
    parameter                           MAX_COLS        = 4
)
(
    // Inputs
    input  wire                         clk,
    input  wire                         reset_n,            // Negative synchronous reset
    input  wire [IN_DATA_WIDTH-1:0]     mlp_din,
    input  wire                         mlp_din_sof,
    input  wire                         mlp_din_eof,
    input  wire [BRAM_ADDR_WIDTH-2:0]   bram_rd_addr,       // Double width output, so half the address

    // Write to BRAM
    input  wire [BRAM_ADDR_WIDTH-1:0]   bram_wr_addr,       // Double width output, so half the address
    input  wire [7 -1: 0]               bram_blk_wr_addr,   // BRAM block write address
    input  wire [BRAM_DATA_WIDTH-1:0]   bram_din,
    input  wire                         bram_wren,

    // Outputs
    output t_mlp_out                    dout [MAX_COLS -1:0],
    output wire [MAX_COLS -1:0]         dout_valid 

);

    dot_product_16_8x8_multi #(
        .NUM_MLP        (NUM_MLP)
    ) i_dp_16_8x8 (
        .i_clk          (clk),
        .i_reset_n      (reset_n),
        // BRAM inputs
        .i_b            (bram_din[63:0]),   // Only supports 8 pixel x 8 bits.  Half width bram write
        .i_b_wraddr     (bram_wr_addr),
        .i_blk_wr_addr  (bram_blk_wr_addr),
        .i_wren         (bram_wren),
        .i_b_rdaddr     (bram_rd_addr),
        // Input data for dot-product
        .i_a            (mlp_din[127:0]),   // Only supports 16 pixels x 8 bits
        .i_first        (mlp_din_sof),
        .i_last         (mlp_din_eof),
        // Output data
        .o_sum          (dout),
        .o_valid        (dout_valid)
    );


endmodule : mlp_wrapper_multi


