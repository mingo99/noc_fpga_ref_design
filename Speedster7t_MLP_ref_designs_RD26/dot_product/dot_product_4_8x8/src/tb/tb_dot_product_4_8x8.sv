// ------------------------------------------------------------------
//
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
// ------------------------------------------------------------------
//  Description : Top level testbench
// ------------------------------------------------------------------


task null_stmt;
endtask

// Control whether signal dump vpd files are generated
`define ACX_DUMP_SIM_SIGNALS

// Define testbench name
`define TB_TESTNAME tb_dot_product_4_8x8

`timescale 1 ps / 1 ps

module compare_result #(
    parameter S = 48
) (
    input  wire         clk,
    input  wire         valid,
    input  wire [S-1:0] sum,
    input  wire         exp_valid,
    input  wire [S-1:0] expected,
    output logic        fail
);
  reg [S-1:0] expected_d1, expected_d2;
  reg exp_valid_d1, exp_valid_d2;
  always @(posedge clk)
  begin
      exp_valid_d1 <= exp_valid;
      exp_valid_d2 <= exp_valid_d1;
      expected_d1 <= expected;
      expected_d2 <= expected_d1;
      fail        <= 1'b0;
      if (valid)
        begin
          if (exp_valid_d2)
            begin
              if (sum == expected_d2)
                  $display("CORRECT: expected %d, computed %d", expected_d2, sum);
              else
              begin
                  $display("ERROR:   expected %d, computed %d", expected_d2, sum);
                  fail <= 1'b1;
              end
            end
          else
            $display("SKIP:    computed %d", sum);
        end
  end
endmodule : compare_result


module `TB_TESTNAME #(
    localparam integer N = 8,       // integer size
    localparam integer M = 4,       // number parallel multiplies
    localparam integer S = 48       // bits in result
) ();

  // 500MHz Clock
  localparam integer CLOCK_PERIOD = 2000;
  reg clk = 0;
  initial
      forever
          #(CLOCK_PERIOD/2) clk = ~clk;

  // DUT
  reg  [M*N-1 : 0]  a;
  reg  [M*N-1 : 0]  b;
  wire [S-1 : 0]    sum;
  reg               first = 0, last = 0;
  wire              valid;

  dot_product_4_8x8 DUT (
      .i_clk        (clk),
      .i_a          (a),
      .i_b          (b),
      .i_first      (first),
      .i_last       (last),
      .o_sum        (sum),
      .o_valid      (valid)
  );

  reg [S-1:0]   expected = '0;
  reg           exp_valid = 1'b0;
  logic         compare_fail;
  logic         test_fail = 1'b0;

  compare_result u_compare_result (
      .clk          (clk),
      .valid        (valid),
      .sum          (sum),
      .exp_valid    (exp_valid),
      .expected     (expected),
      .fail         (compare_fail)
  );

  always @(posedge clk)
    if ( compare_fail )
        test_fail <= 1'b1;

  // Test vectors
  `include "test_sequence.svh"
  initial
  begin
      $display("---------- SIMULATION START ----------");
      test_sequence;
      if ( test_fail )
        $error("---------- TEST FAILED ------------");      
      else
        $display("---------- TEST PASSED ------------");
      $finish;
  end

  // Write waveform data
`ifdef ACX_DUMP_SIM_SIGNALS
  initial
  begin
      `ifdef VCS
          $vcdplusfile("sim_output_pluson.vpd");  
          $vcdpluson(0,`TB_TESTNAME);
         `ifdef SIMSTEP_fullchip_bs
              $vcdpluson(0,`TB_TESTNAME.DUT.x_fullchip_wrapper.u_fullchip.x_config_top);
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

endmodule : `TB_TESTNAME


