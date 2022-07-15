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
// This module is a wrapper that puts a registers at all inputs and outputs
// of the dot-product macro, to get more meaningful timing results.
// For a user design, this wrapper can be excluded and the mlp_stack
// component can be directly instantiated.
// ------------------------------------------------------------------

`timescale 1 ps / 1 ps

module dot_product_bfloat16_4mlp_top #(
    localparam integer K = 4,               // number of MLPs, must be >= 2
    localparam integer B = 2,               // number parallel multiplies for one MLP
    localparam integer FP = 16,             // floating point size (fp16e8)
    localparam integer E = 8,               // exponent size
    localparam integer P = FP - E           // fp precision
) (
    input  wire                 i_clk,
    // input data
    input  wire [K*B*FP-1 : 0]  i_a,        // pll arguments for all MLPs (fp16e8)
    input  wire [K*B*FP-1 : 0]  i_b,        // pll arguments for all MLPs (fp16e8)
    input  wire                 i_first,    // high for first item of dotproduct
    input  wire                 i_last,     // high for last item of dotproduct
    // output data
    output wire [FP-1 : 0]      o_sum,      // dot product (fp16e8)
    output wire                 o_valid     // high when o_sum is finished dotproduct
);

  // prevent retiming of these registers, otherwise logic is put between
  // IPINs and these registers, which gives unrealistic timing.
  // (This is for the demo design only.)
  (* syn_allow_retiming=0, must_keep=1 *) reg [K*B*FP-1 : 0] reg_a;
  (* syn_allow_retiming=0, must_keep=1 *) reg [K*B*FP-1 : 0] reg_b;
  (* syn_allow_retiming=0, must_keep=1 *) reg                reg_first;
  (* syn_allow_retiming=0, must_keep=1 *) reg                reg_last = 1'b0; // prevent X on o_valid
  (* syn_allow_retiming=0, must_keep=1 *) reg [FP-1 : 0]     reg_sum;
  (* syn_allow_retiming=0, must_keep=1 *) reg                reg_valid;

  wire [FP-1 : 0] sum;
  wire            valid;

  always @(posedge i_clk)
  begin
      reg_a     <= i_a;
      reg_b     <= i_b;
      reg_first <= i_first;
      reg_last  <= i_last;

      reg_sum   <= sum;
      reg_valid <= valid;
  end

  assign o_sum   = reg_sum;
  assign o_valid = reg_valid;

  mlp_stack u_mlp_stack (
      .i_clk        (i_clk),
      // input data for dot-product
      .i_a          (reg_a),        // parallel args for all MLPs (fp16e8)
      .i_b          (reg_b),        // parallel args for all MLPs (fp16e8)
      .i_first      (reg_first),    // high for first item of dotproduct
      .i_last       (reg_last),     // high for last item of dotproduct
      // output data
      .o_sum        (sum),          // dot product (fp16e8)
      .o_valid      (valid)         // high when o_sum is the finished dot-product
  );


endmodule : dot_product_bfloat16_4mlp_top

