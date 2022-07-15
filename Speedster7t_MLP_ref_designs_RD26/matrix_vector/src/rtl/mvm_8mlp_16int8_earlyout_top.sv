// This module is a wrapper that puts a registers at all inputs and outputs
// of the dot-product macro, to get more meaningful timing results.

`timescale 1 ps / 1 ps

module mvm_8mlp_16int8_earlyout_top #(
    localparam integer V = 256,   // VxV matrix
    localparam integer M = 8,     // number BRAMs, number MLPs
    localparam integer N = 8,     // integer size
    localparam integer B = 16,    // block size (number parallel multiplies)
    localparam integer Bw = 8,    // block size for writing BRAM
    localparam integer S = 48     // bits in result
) (
    input  wire              i_clk,
    // matrix inputs
    input  wire [Bw*N-1 : 0] i_matrix,  // Bw N-bit integers (2's compl)
    input  wire              i_matrix_wren, // while writing matrix data
    input  wire              i_matrix_wrpause, // pause writing
    // vector inputs
    input  wire [B*N-1 : 0]  i_v,       // B N-bit integers (2's compl)
    input  wire              i_first,   // high for first vector item
    input  wire              i_last,    // high for last vector item
    input  wire              i_pause,   // ignore i_v
    // output data
    output wire [S-1 : 0]    o_sum,     // output vector item (2's compl)
    output wire              o_first,   // high for first output item
    output wire              o_last,    // high for last output item
    output wire              o_pause    // high when o_sum is invalid
);

  // prevent retiming of these registers, otherwise logic is put between
  // IPINs and these registers, which gives unrealistic timing.
  (* syn_allow_retiming=0 *) reg [Bw*N-1 : 0] reg_matrix;
  (* syn_allow_retiming=0 *) reg              reg_matrix_wren;
  (* syn_allow_retiming=0 *) reg              reg_matrix_wrpause;
  (* syn_allow_retiming=0 *) reg [B*N-1 : 0]  reg_v;
  (* syn_allow_retiming=0 *) reg              reg_first;
  (* syn_allow_retiming=0 *) reg              reg_last;
  (* syn_allow_retiming=0 *) reg              reg_pause;
  (* syn_allow_retiming=0 *) reg [S-1 : 0]    reg_sum;
  (* syn_allow_retiming=0 *) reg              reg_first_sum;
  (* syn_allow_retiming=0 *) reg              reg_last_sum;
  (* syn_allow_retiming=0 *) reg              reg_pause_sum;

  wire [S-1 : 0] sum;
  wire           first_sum, last_sum, pause_sum;

  always @(posedge i_clk)
  begin
      reg_matrix <= i_matrix;
      reg_matrix_wren <= i_matrix_wren;
      reg_matrix_wrpause <= i_matrix_wrpause;
      reg_v <= i_v;
      reg_first <= i_first;
      reg_last <= i_last;
      reg_pause <= i_pause;

      reg_sum <= sum;
      reg_first_sum <= first_sum;
      reg_last_sum <= last_sum;
      reg_pause_sum <= pause_sum;
  end

  assign o_sum = reg_sum;
  assign o_first = reg_first_sum;
  assign o_last = reg_last_sum;
  assign o_pause = reg_pause_sum;

  mvm_8mlp_16int8_earlyout u_mvm_8mlp_16int8_earlyout (
      .i_clk(i_clk),
      // BRAM inputs
      .i_matrix(reg_matrix),
      .i_matrix_wren(reg_matrix_wren),
      .i_matrix_wrpause(reg_matrix_wrpause),
      // input data for dot-product
      .i_v(reg_v),
      .i_first(reg_first),
      .i_last(reg_last),
      .i_pause(reg_pause),
      // output data
      .o_sum(sum),        
      .o_first(first_sum),
      .o_last(last_sum),
      .o_pause(pause_sum)
  );


endmodule : mvm_8mlp_16int8_earlyout_top

