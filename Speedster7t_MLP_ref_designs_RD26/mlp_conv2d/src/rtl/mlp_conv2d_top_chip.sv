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
// 2D convolution top structure, replicated N times across the chip
// ------------------------------------------------------------------

module mlp_conv2d_top_chip
#(
    // Batch gives size of instance
    parameter   BATCH               = 4,
    // Rows and columns defines number of instances
    parameter   NUM_ROWS            = 4,
    parameter   NUM_COLS            = 4
)
(
    // Inputs
    input  wire                         i_clk,
    input  wire                         i_reset_n,      // Negative synchronous reset
    input  wire                         pll_1_lock,     // Reference PLL locked
    input  wire                         pll_2_lock,     // System PLL locked
    // Outputs
    output wire                         o_conv_done,    // Indicate when current convolution is complete
    output wire                         o_conv_done_oe, // Associated output enable
    output wire                         o_error,        // Indicates a write bresp error
    output wire                         o_error_oe      // Associated output enable
);

    logic [(NUM_ROWS*NUM_COLS)-1:0] error;
    logic [(NUM_ROWS*NUM_COLS)-1:0] conv_done;

    // Fix output enables to always be on
    assign o_conv_done_oe = 1'b1;
    assign o_error_oe     = 1'b1;

    generate 
        for (genvar row=0; row<NUM_ROWS; row=row+1 ) begin : chip_row
            for (genvar col=0; col<NUM_COLS; col=col+1 ) begin : chip_col
                mlp_conv2d_top #(
                    .BATCH (BATCH)
                ) i_top (
                    .i_clk          (i_clk),
                    .i_reset_n      (i_reset_n),
                    .pll_1_lock     (pll_1_lock),
                    .pll_2_lock     (pll_2_lock),
                    .o_conv_done    (conv_done[(row*NUM_COLS)+col]),
                    .o_conv_done_oe (),     // Unused at the instance level
                    .o_error        (error[(row*NUM_COLS)+col]),
                    .o_error_oe     ()      // Unused at the instance level
                );
            end // block: chip_col
        end // block: chip_row
    endgenerate

    // Untimed output signals.  If they are to be registered they would
    // require flops to get the signals across the die.
    assign o_error     = |error;
    assign o_conv_done = &conv_done;

endmodule : mlp_conv2d_top_chip
   
