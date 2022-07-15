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
// Description : Testbench for dot product 16fp_4mlp
// ------------------------------------------------------------------

// `include "speedster7t/common/acx_floating_point.v"
`include "speedster7t/common/acx_floating_point.sv"

task null_stmt;
endtask

// Control whether signal dump vpd files are generated
`define ACX_DUMP_SIM_SIGNALS

// Define testbench name
`define TB_TESTNAME tb_dot_product_fp16_4mlp

`timescale 1 ps / 1 ps

module compare_result #(
    parameter           S = 16
) (
    input  wire         clk,
    input  wire         valid,
    input  wire [S-1:0] sum,
    input  wire         exp_valid,
    input  wire [S-1:0] expected,
    output logic        fail
);
  always @(posedge clk)
  begin
      fail <= 1'b0;
      if (valid)
        begin
          if (exp_valid)
            begin
              if (sum == expected)
                  $display("CORRECT: expected %f (16'h%04h), computed %f",
                            fp16::bitstoreal(expected), expected,
                            fp16::bitstoreal(sum));
              else
              begin
                  $display("ERROR:   expected %f (16'h%04h), computed %f (16'h%04h)",
                            fp16::bitstoreal(expected), expected,
                            fp16::bitstoreal(sum), sum);      
                  fail <= 1'b1;
              end
            end
          else
          begin
            $display("ERROR:   computed %f (16'h%04h), but expected value unknown",
                            fp16::bitstoreal(sum), sum);
            fail <= 1'b1;
          end
        end
  end
endmodule : compare_result


`timescale 1 ps / 1 ps

module `TB_TESTNAME #(
    localparam integer B = 2,       // number parallel multiplies for one MLP
    localparam integer K = 4,       // number of MLPs
    localparam integer FP = 16      // floating point size (fp16)
) ();

  // 500MHz Clock
  localparam integer CLOCK_PERIOD = 2000;
  reg clk = 0;
  initial
      forever
          #(CLOCK_PERIOD/2) clk = ~clk;

  // DUT
  reg [K*B*FP-1 : 0]    a;
  reg [K*B*FP-1 : 0]    b;
  wire [FP-1 : 0]       sum;
  reg                   first = 0, last = 0;
  wire                  valid;

  dot_product_fp16_4mlp_top DUT (
      .i_clk        (clk),
      .i_a          (a),
      .i_b          (b),
      .i_first      (first),
      .i_last       (last),
      .o_sum        (sum),
      .o_valid      (valid)
  );

  localparam MLP_LATENCY   = 5;                         // s1, s2, s2.5, s3, s4(ab)
  localparam STACK_LATENCY = MLP_LATENCY + (K-1) + 2;   // last +2 for s4(cd), s4(fpcd)
  localparam DUT_LATENCY   = STACK_LATENCY + 2;         // top-level input and output regs

  reg           exp_valid = 1'b0;
  reg  [FP-1:0] expected = '0;
  wire          exp_valid_d;
  wire [FP-1:0] expected_d;
  logic         compare_fail;
  logic         test_fail = 1'b0;

  tb_pipeline #(
      .width        (FP+1),
      .depth        (DUT_LATENCY)
  ) u_expect_pipeline (
      .i_clk        (clk),
      .i_din        ({exp_valid, expected}),
      .o_dout       ({exp_valid_d, expected_d})
  );

  compare_result #(
      .S            (FP)
  ) u_compare_result (
      .clk          (clk),
      .valid        (valid),
      .sum          (sum),
      .exp_valid    (exp_valid_d),
      .expected     (expected_d),
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


