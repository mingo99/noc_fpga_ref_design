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
// Image FIFO using BRAM72K
// Gets image from NAP, plays out to MLPs
// Must be large enough to hold MATRIX_SIZE + STRIDE number of lines
// Each pixel is 3 bytes deep, (number of layers).  4 pixels per location
// ------------------------------------------------------------------

`timescale 1 ps / 1 ps


module line_fifo
#(
    parameter       DATA_WIDTH = 24,
    parameter       ADDR_WIDTH = 11

)
(
    // Inputs
    input  wire                     i_clk,
    input  wire                     i_reset_n,              // Negative synchronous reset
    input  wire                     i_wr_en,
    input  wire                     i_wr_addr_reset,        // Reset address, for new image
    input  wire [DATA_WIDTH-1:0]    i_data_in,

    input  wire                     i_rd_en,
    input  wire [ADDR_WIDTH-1:0]    i_rd_addr,

    // Outputs
    output wire [DATA_WIDTH-1:0]    o_data_out
);


    logic [ADDR_WIDTH-1:0] wr_addr;

    // Calcuate address
    always @(posedge i_clk)
        if ( ~i_reset_n || i_wr_addr_reset )
            wr_addr <= 0;
        else if ( i_wr_en )
            wr_addr <= wr_addr + 1;

    // Port memory width is 14 bits.
    // If addresses are less than this, then they need to be left justified
    logic [14 -1:0] wr_addr_pad;
    logic [14 -1:0] rd_addr_pad;

    assign wr_addr_pad = (ADDR_WIDTH == 14) ? wr_addr   : {wr_addr,   {(14-ADDR_WIDTH){1'b0}}};
    assign rd_addr_pad = (ADDR_WIDTH == 14) ? i_rd_addr : {i_rd_addr, {(14-ADDR_WIDTH){1'b0}}};
    

    // Instantiate BRAM72K_SDP memory
    // Two needed to store sufficient lines of input image.
    // Current storage is 4 pixels x 3 layers, (12 bytes), is stored in one 144 word.
    // For largest image, (227+3)/4 = 57 words per line x 15 lines = 855 locations
    // REVISIT - A future enhancement would be to use the ACX_MEM_GEN macro to create this memory
    wire [144 -1:0] data_out_l, data_out_h;

    ACX_BRAM72K_SDP #(
        .write_width    (72),
        .read_width     (72),
        .byte_width     (8),    // Width of a byte, 8 or 9 bits.
        .outreg_enable  (1)
    ) i_bram_l (
        .wrclk          (i_clk),
        .rdclk          (i_clk),
        .din            ({72'h0, i_data_in[71:0]}),
        .we             (18'h3ffff),
        .wren           (i_wr_en),
        .wraddr         (wr_addr_pad),
        .wrmsel         (1'b0),
        .rden           (1'b1),
        .rdaddr         (rd_addr_pad),
        .rdmsel         (1'b0),
        .outreg_rstn    (1'b1),
        .outlatch_rstn  (1'b1),
        .outreg_ce      (1'b1),
        .sbit_error     (),
        .dbit_error     (),
        .dout           (data_out_l)
    );

    ACX_BRAM72K_SDP #(
        .write_width    (72),
        .read_width     (72),
        .byte_width     (8),    // Width of a byte, 8 or 9 bits.
        .outreg_enable  (1)
    ) i_bram_h (
        .wrclk          (i_clk),
        .rdclk          (i_clk),
        .din            ({ {(144-DATA_WIDTH+72){1'b0}}, i_data_in[DATA_WIDTH-1:72]}),
        .we             (18'h3ffff),
        .wren           (i_wr_en),
        .wraddr         (wr_addr_pad),
        .wrmsel         (1'b0),
        .rden           (1'b1),
        .rdaddr         (rd_addr_pad),
        .rdmsel         (1'b0),
        .outreg_rstn    (1'b1),
        .outlatch_rstn  (1'b1),
        .outreg_ce      (1'b1),
        .sbit_error     (),
        .dbit_error     (),
        .dout           (data_out_h)
    );

    assign o_data_out = {data_out_h[71:0], data_out_l[71:0]};

endmodule : line_fifo


