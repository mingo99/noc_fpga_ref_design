//---------------------------------------------------------------------
//  Copyright (c) 2020  Achronix Semiconductor Corp.
//  All Rights Reserved.
//
//  This software constitutes an unpublished work and contains
//  valuable proprietary information and trade secrets belonging
//  to Achronix Semiconductor Corp.
//
//  This software may not be used, copied, distributed or disclosed
//  without specific prior written authorization from
//  Achronix Semiconductor Corp.
//
//  The copyright notice above does not evidence any actual or intended
//  publication of such software.
//
//---------------------------------------------------------------------

`define TB_TESTNAME tb_mvm_8mlp_16int8_earlyout

`timescale 1 ps / 1 ps


// read sequence of result values from i_first to i_last, and
// compare with expected values
module compare_result #(
    parameter integer S = 48,
    parameter integer V = 256
) (
    input wire                  i_clk,
    input wire signed [S-1 : 0] i_sum,
    input wire                  i_first,
    input wire                  i_pause,
    input wire                  i_last,
    input wire signed [S-1 : 0] i_expected[V-1 : 0],
    output logic                o_fail
);

  logic active = 1'b0;
  integer c = 0;

  always @(posedge i_clk)
  begin
      o_fail <= 1'b0;
      if (i_first)
          active <= 1'b1;
      else if (i_last)
          active <= 1'b0;
          
      if ((i_first || active) && !i_pause)
        begin
          if (i_expected[c] == i_sum)
              $display("Correct : result[%0d] = %0d ('h%0x)", c, i_sum, i_sum);
          else
          begin
              $error("Compare result failed : Expected[%0d] = %0d ('h%0x) but computed %0d ('h%0x)",
                 c, i_expected[c], i_expected[c], i_sum, i_sum);
              o_fail <= 1'b1;
          end

          if (i_last)
              c = 0;
          else
              c = c + 1;
        end
  end

endmodule : compare_result


module `TB_TESTNAME #() ();

  // Do not have localparam in module definition.  Otherwise this prevents
  // parameters within this module from being overwritten at runtime
  localparam integer V = 256;     // VxV matrix
  localparam integer M = 8;       // number BRAMs, number MLPs
  localparam integer N = 8;       // integer size
  localparam integer B = 16;      // block size (number parallel multiplies)
  localparam integer Bw = 8;      // block size for writing BRAM
  localparam integer S = 48;      // bits in result

  localparam integer W = Bw*N;    // write width (wrblock size)
  localparam integer A = 10;      // native address width
  localparam integer Ablk = 7;    // block address width
  localparam integer R = B*N;     // read width (rdblock size)
  localparam integer Ar = A-1;    // read address width


  // clock
  localparam integer period = 1334;
  reg clk = 1'b0;
  initial
  begin
      forever
      begin
          #(period/2) clk = 1'b1;
          #(period/2) clk = 1'b0;
      end
  end

  // DUT
  reg [W-1 : 0]   tb_i_matrix;
  reg             tb_i_matrix_wren = 1'b0;
  reg             tb_i_matrix_wrpause = 1'b0;
  reg [B*N-1 : 0] tb_i_vector;
  reg             tb_i_first = 1'b0;
  reg             tb_i_last = 1'b0;
  reg             tb_i_pause = 1'b0;
  wire [S-1 : 0]  tb_o_sum;
  wire            tb_o_first_sum, tb_o_last_sum, tb_o_pause_sum;

  mvm_8mlp_16int8_earlyout DUT (
      .i_clk                (clk),
      .i_matrix             (tb_i_matrix),
      .i_matrix_wren        (tb_i_matrix_wren),
      .i_matrix_wrpause     (tb_i_matrix_wrpause),
      .i_v                  (tb_i_vector),
      .i_first              (tb_i_first),
      .i_last               (tb_i_last),
      .i_pause              (tb_i_pause),
      .o_sum                (tb_o_sum),
      .o_first              (tb_o_first_sum),
      .o_last               (tb_o_last_sum),
      .o_pause              (tb_o_pause_sum)
  );


  // compare DUT output
  logic signed [S-1 : 0] expected[V-1 : 0];
  logic                  test_fail = 1'b0;
  logic                  compare_fail;
   
  compare_result u_compare_result(
      .i_clk        (clk),
      .i_sum        (tb_o_sum),
      .i_first      (tb_o_first_sum),
      .i_last       (tb_o_last_sum),
      .i_pause      (tb_o_pause_sum),
      .i_expected   (expected),
      .o_fail       (compare_fail)
  );

  always @(posedge clk)
    if ( compare_fail )
        test_fail <= 1'b1;

  // Test vectors
  `include "matrix.svh"
  `include "test_sequence.svh"

  initial
  begin
      $display("---------- Simulation Start ----------");
      test_sequence;      
      if ( test_fail )
        $error("---------- TEST FAILED ------------");      
      else
        $display("---------- TEST PASSED ------------");
      $finish;
  end

  // -------------------------
  // Simulation dump signals to file
  // -------------------------
  // Optionally enabled as can slow simulation
`ifdef ACX_DUMP_SIM_SIGNALS
  initial
  begin
    `ifdef VCS          // Defined by VCS
       $vcdplusfile("sim_output_pluson.vpd");  
       $vcdpluson(0,`TB_TESTNAME);
       `ifdef SIMSTEP_fullchip_bs
          $vcdpluson(0,`TB_TESTNAME.DUT);
       `endif
    `elsif MODEL_TECH   // Defined by QuestaSim
       // WLF filename is set by using the -wlf option to vsim
       // or else in the modelsim.ini file.
       $wlfdumpvars(0, `TB_TESTNAME);
       `ifdef SIMSTEP_fullchip_bs
          $wlfdumpvars(0,`TB_TESTNAME.DUT);
       `endif
    `endif
  end
`endif


endmodule : tb_mvm_8mlp_16int8_earlyout

