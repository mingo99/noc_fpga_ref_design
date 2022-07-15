// ------------------------------------------------------------------
//
// Copyright (c) 2021 Achronix Semiconductor Corp.
// All Rights Reserved.
//
// This Software constitutes an unpublished work and contains
// valuable proprietary information and trade secrets belonging
// to Achronix Semiconductor Corp.
//
// Permission is hereby granted to use this Software including
// without limitation the right to copy, modify, merge or distribute
// copies of the software subject to the following condition:
//
// The above copyright notice and this permission notice shall
// be included in in all copies of the Software.
//
// The Software is provided “as is” without warranty of any kind
// expressed or implied, including  but not limited to the warranties
// of merchantability fitness for a particular purpose and non-infringement.
// In no event shall the copyright holder be liable for any claim,
// damages, or other liability for any damages or other liability,
// whether an action of contract, tort or otherwise, arising from, 
// out of, or in connection with the Software
//
// ------------------------------------------------------------------
// Speedster7t 2D NoC reference design (RD22)
//      Top level testbench instantiating DUT and DSM
// ------------------------------------------------------------------

`timescale 1 ps / 1 ps

`include "nap_interfaces.svh"

// Enable VCS to create a signal dump
`define DUMP_SIM_SIGNALS

module tb_noc_2d_ref_design #(
   parameter SIM_COMMAND_FILENAME  = "../ac7t1550_2D_NoC_sim.txt" // Test command file

);

   // -------------------------
   // Local signals
   // -------------------------
   logic   send_clk = 0;
   logic   chk_clk = 0;
   logic   cc_clk = 0;
   logic   reg_clk = 0;
   logic   reset_n = 1'b0;
   logic   test_start_h_send;
   logic   test_start_h_chk;
   logic   test_start_v_send;
   logic   test_start_v_chk;
   logic   test_start_axi;
   logic   test_fail_h;
   logic   test_fail_v;
   logic   test_fail_axi;
   logic   test_fail;
   logic   test_fail_d;
   logic   script_done;
   logic   chip_ready;
   logic   test_timeout;
   logic   fcu_error;
   logic   test_complete;
   
   // VectorPath Rev-1 Board Signals
   `include     "vectorpath_rev1_signal_list.svh"

   // -------------------------
   // Clocks
   // -------------------------
   
   // Define clock as 500MHz and slightly slower (~499MHZ)
   // Uses 2 clock domains to show that the logic at one
   // NAP can operate at a different clock rate than logic
   // connected to another NAP
   localparam CLOCK_PERIOD_SEND = 2000;
   localparam CLOCK_PERIOD_CHK  = 2010; // slightly slower
   localparam CLOCK_PERIOD_CC   = 5000; // 200 MHz for Core Clock
   always #(CLOCK_PERIOD_SEND/2) send_clk <= ~send_clk;
   always #(CLOCK_PERIOD_CHK/2)  chk_clk  <= ~chk_clk;
   always #(CLOCK_PERIOD_CC/2)   cc_clk   <= ~cc_clk;
   
   // Clock for Register Control Block - 200 MHz
   localparam CLOCK_PERIOD_REG = 5000;
   always #(CLOCK_PERIOD_REG/2)  reg_clk  <= ~reg_clk;

   // -------------------------
   // Simulation sequence
   // -------------------------
   
   // Deassert reset after chip is ready
   initial
     begin
        reset_n = 1'b0;
        test_start_h_send = 1'b0;
        test_start_v_send = 1'b0;
        test_start_h_chk = 1'b0;
        test_start_v_chk = 1'b0;
        test_start_axi = 1'b0;
        while ( chip_ready !== 1'b1 )
          @(posedge send_clk);
        repeat (10) @(posedge send_clk); // Board response time to chip asserting ready
        $display($time, ": Chip is ready, release reset");
        reset_n = 1'b1;
        // Start test 50 cycles later
        repeat (50) @(posedge send_clk);
        test_start_h_send <= 1'b1;
        test_start_v_send <= 1'b1;
        test_start_axi    <= 1'b1;
        // wait 5 cycles before checking
        repeat (5) @(posedge chk_clk);
        test_start_h_chk <= 1'b1;
        test_start_v_chk <= 1'b1;
     end
   
   // Timeout to stop the test if required
   initial
     begin
        test_timeout <= 1'b0;
        repeat (50000) @(posedge chk_clk);
        test_timeout <= 1'b1;
     end

   
   // When test completes, or times out, assert finish
   initial
     begin
        #100;
        @(posedge reset_n);
        while ( ~(test_timeout || test_complete) )
          @(posedge chk_clk);

        // wait just a bit of time
        repeat(20)@(posedge chk_clk);
        
        if ( ~test_complete )
          $error( "%t : Test didn't complete in time", $time );
        
        if ( fcu_error || test_fail || test_timeout  )
          $error( "%t : TEST FAILED", $time );
        else
          $display( "%t : TEST PASSED", $time );
        $finish;
     end



   // ------------------------------------------
   // Instantiate Device Simulation Model, (DSM)
   // ------------------------------------------

   // Include the utility file which defines the bind macros
   `include "ac7t1550_utils.svh"

   //Instantiate Speedster7t1550
   `ACX_DEVICE_NAME `ACX_DEVICE_NAME (
                      .FCU_CONFIG_USER_MODE   (chip_ready)
                      );

   // Specify the path to the ioring simulation files
   `define ACX_IORING_SIM_FILES_PATH "../../src/ioring/"

   // Record any errors during configuration and test execution
   assign fcu_error = `ACX_DEVICE_NAME.fcu.error;

   // ------------------------------------
   // Configure DSM
   // Enable NoC performance monitoring
   // ------------------------------------
   initial begin
      script_done = 1'b0;

      // Ensure correct version of sim package is being used
      // This design requires 8.6.1 as a minimum
      `ACX_DEVICE_NAME.require_version(8, 6, 0, 0);

      // Set the verbosity options on the messages
      `ACX_DEVICE_NAME.set_verbosity(2);

      // Configure the DSM clocks and perform any configuration
      `include "../../src/ioring/noc_2d_ref_design_top_sim_config.svh"


      // Wait on reset, (released after chip is programmed)
      while(!reset_n) // in reset
          @(posedge chk_clk);

      repeat(10)@(posedge chk_clk);
      // Initiate NoC performance measurement
      `ACX_DEVICE_NAME.start_test("2d_noc_ref_design");

      // Run user script
     `ACX_DEVICE_NAME.fcu.configure( SIM_COMMAND_FILENAME, "full" );
      script_done = 1'b1;
     
      while ( ~(test_timeout || test_complete) ) begin
          repeat(500)@(posedge chk_clk);
          `ACX_DEVICE_NAME.print_statistics("2d_noc_stats");
      end

      // Close NoC performance measurement
      `ACX_DEVICE_NAME.end_test();
   end

    // There are two methods to connect to the ioring signals in the DSM
    //   1.  The user can use the interfaces built into the DSM.
    //       These are useful during early development, prior to an ACE project being compiled
    //   2.  Using the ACE generated bindings file, once an ACE project has been run.
    //  Both methods achieve the same connection.
    // The define ACX_DSM_INTERFACES_TO_MONITOR_MODE controls the mode of the DSM
    // DCI ports, and is also used to determine the usage of the port bindings file

`ifdef ACX_DSM_INTERFACES_TO_MONITOR_MODE
    `include "../../src/ioring/noc_2d_ref_design_top_user_design_port_bindings.svh"
`endif

   
   // -----------------------------------------
   // Bind NAPs in design to the NoC in the DSM
   // -----------------------------------------
   // horizontal NAP at col=9, row=4 
   `ACX_BIND_NAP_HORIZONTAL(DUT.i_nap_row_in.i_nap_horizontal,9,4);
   // horizontal NAP at col=6, row=4 
   `ACX_BIND_NAP_HORIZONTAL(DUT.i_nap_row_out.i_nap_horizontal,6,4);
   
   // vertical NAP at col=3, row=1 
   `ACX_BIND_NAP_VERTICAL(DUT.i_nap_col_3.i_nap_vertical,3,1);
   // vertical NAP at col=3, row=7 
   `ACX_BIND_NAP_VERTICAL(DUT.i_nap_col_4.i_nap_vertical,3,7);
   
   // AXI slave NAP at col=1, row=1 (south-west corner)
   `ACX_BIND_NAP_AXI_SLAVE(DUT.i_axi_slave_wrapper_in.i_axi_slave,1,1);
   // AXI master NAP at col=9, row=8 (north-east corner)
   `ACX_BIND_NAP_AXI_MASTER(DUT.i_axi_bram_rsp.i_axi_master_nap.i_axi_master,9,8);

   // Bind the Register Control Block AXI Master NAP to col=3, row=3 
   // This same location should be in the ace_placements.pdc, and the demo/scripts/ac7t1500_demo.tcl
   `ACX_BIND_NAP_AXI_MASTER(DUT.i_reg_control_block.i_axi_master.i_axi_master,3,3);

   // -------------------------
   // DUT
   // -------------------------
   noc_2d_ref_design_top
     DUT (
          // Inputs
          .i_send_clk         (send_clk),
          .i_chk_clk          (chk_clk),
          .i_cc_clk           (cc_clk),
          .i_reg_clk          (reg_clk),
          .pll_send_clk_lock  (1'b1),                 // lock signal from PLL
          .pll_chk_clk_lock   (1'b1),                 // lock signal from PLL

          // Outputs
          .led_l                (led_l),
          .led_l_oe           ()
          );

   assign test_fail_axi = led_l[2]; // Will be asserted if read errors
   assign test_fail_v   = led_l[3]; // Will be asserted if read errors 
   assign test_fail_h   = led_l[6]; // Will be asserted if read errors

   // complete when AXI transactions are done
   assign test_complete = script_done;

   // -------------------------
   // Monitor the test
   // -------------------------

   assign test_fail = test_fail_h | test_fail_v | test_fail_axi;

   // Only assert error message once on rising edge of fail
   always @(posedge chk_clk)
     begin
        test_fail_d <= test_fail;
        // Note that $error automatically issues the location of the error
        if( test_fail & ~test_fail_d )
          $error( "%t : test_fail asserted", $time );
     end

   // -------------------------
   // Simulation dump signals to file
   // -------------------------
   // Optionally enabled as can slow simulation
`ifdef DUMP_SIM_SIGNALS
   initial
     begin
 `ifdef VCS
        $vcdplusfile("sim_output_pluson.vpd");  
        $vcdpluson(0, tb_noc_2d_ref_design);
  `ifdef SIMSTEP_fullchip_bs
        $vcdpluson(0,tb_noc_2d_ref_design.DUT);
  `endif
 `elsif MODEL_TECH   // Defined by QuestaSim
        // WLF filename is set by using the -wlf option to vsim
        // or else in the modelsim.ini file.
        $wlfdumpvars(0, tb_noc_2d_ref_design);
  `ifdef SIMSTEP_fullchip_bs
        $wlfdumpvars(0,tb_noc_2d_ref_design.DUT);
  `endif
 `endif
     end
`endif

endmodule : tb_noc_2d_ref_design

