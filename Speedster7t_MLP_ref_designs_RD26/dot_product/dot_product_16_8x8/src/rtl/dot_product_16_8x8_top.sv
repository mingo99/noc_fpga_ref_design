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

module dot_product_16_8x8_top #(
    localparam integer N  = 8,          // integer size
    localparam integer M  = 16,         // number parallel multiplies
    localparam integer Mb = M / 2,      // number items in BRAM write
    localparam integer A  = 10,         // BRAM address bits
    localparam integer S  = 48          // bits in result
) (
    input  wire              i_clk,
    // BRAM inputs
    input  wire [Mb*N-1 : 0] i_b,       // Mb N-bit integers (2's compl)
    input  wire [A-1 : 0]    i_b_addr,  // BRAM address bits
    input  wire              i_wren,    // BRAM write enable
    // input data for dot-product
    input  wire [M*N-1 : 0]  i_a,       // M N-bit integers (2's compl)
    input  wire              i_first,   // high for first item of dotproduct
    input  wire              i_last,    // high for last item of dotproduct
    // output data
    output wire [S-1 : 0]    o_sum,     // dot product (2's compl)
    output wire              o_valid    // high when o_sum is finished dotproduct
);

  // Prevent retiming of these registers, otherwise logic is put between
  // IPINs and these registers, which gives unrealistic timing.
  (* syn_allow_retiming=0 *) reg [Mb*N-1 : 0] reg_b;
  (* syn_allow_retiming=0 *) reg [A-1 : 0]    reg_b_addr;
  (* syn_allow_retiming=0 *) reg              reg_wren;
  (* syn_allow_retiming=0 *) reg [M*N-1 : 0]  reg_a;
  (* syn_allow_retiming=0 *) reg              reg_first;
  (* syn_allow_retiming=0 *) reg              reg_last;
  (* syn_allow_retiming=0 *) reg [S-1 : 0]    reg_sum;
  (* syn_allow_retiming=0 *) reg              reg_valid;

  wire [S-1 : 0] sum;
  wire           valid;

  always @(posedge i_clk)
  begin
      reg_b         <= i_b;
      reg_b_addr    <= i_b_addr;
      reg_wren      <= i_wren;
      reg_a         <= i_a;
      reg_first     <= i_first;
      reg_last      <= i_last;

      reg_sum       <= sum;
      reg_valid     <= valid;
  end

  assign o_sum   = reg_sum;
  assign o_valid = reg_valid;

  dot_product_16_8x8 u_dot_product_16_8x8 (
      .i_clk        (i_clk),
      // BRAM inputs
      .i_b          (reg_b),        // Mb N-bit integers (2's compl)
      .i_b_addr     (reg_b_addr),   // BRAM address bits
      .i_wren       (reg_wren),     // BRAM write enable
      // input data for dot-product
      .i_a          (reg_a),        // M N-bit integers (2's compl)
      .i_first      (reg_first),    // high for first item of dotproduct
      .i_last       (reg_last),     // high for last item of dotproduct
      // output data
      .o_sum        (sum),          // dot product (2's compl)
      .o_valid      (valid)         // high when o_sum is the finished dot-product
  );


endmodule : dot_product_16_8x8_top

