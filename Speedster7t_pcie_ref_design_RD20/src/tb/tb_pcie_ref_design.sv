// ------------------------------------------------------------------
//
// Copyright (c) 2021  Achronix Semiconductor Corp.
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
// Speedster7t PCIe reference design (RD20)
//      Testbench
//      Supports both BFM and RTL simulation of either PCIe core
// ------------------------------------------------------------------

// Timescale required as clock periods defined in this testbench
`timescale 1 ps / 1 ps

`ifdef ACX_PCIE_0_FULL
  `define ACX_PCIE_FULL
`endif

`ifdef ACX_PCIE_1_FULL
  `define ACX_PCIE_FULL
`endif

// ------------------------------------------------------------------

`include "pcie_defines.svh"

// ------------------------------------------------------------------

// The length of time taken in simulation to complete the test varies between BFM and RTL
`ifndef ACX_PCIE_FULL
    `define ACX_PCIE_TB_TIMEOUT_LIMIT   55500
`else
    `define ACX_PCIE_TB_TIMEOUT_LIMIT   200000
`endif


// ------------------------------------------------------------------
// Define top level testbench
// ------------------------------------------------------------------
`define TB_NAME tb_pcie_ref_design

module `TB_NAME;

  localparam TIMEOUT_LIMIT = `ACX_PCIE_TB_TIMEOUT_LIMIT;

`ifdef ACX_PCIE_FULL

  // Following VIP modules needed for RTL mode sim

    `include "svc_util_parms.v"
    `include "pciesvc_parms.v"

    parameter NUM_PMA_INTERFACE_BITS = 10;
    parameter DISPLAY_NAME = "tb_pcie_ref_design.";

    // Message logging control
    initial
    begin
    `ifndef MSGLOG_LEVEL
        `define MSGLOG_LEVEL 1
    `endif
        $msglog_level(`MSGLOG_LEVEL);
    end

    // Global random seed
    integer global_random_seed, unused;

    `ifndef SVC_RANDOM_BY_THREAD
        initial
        begin : L_RandSeed
        `ifdef SVC_RANDOM_SEED
            global_random_seed = `SVC_RANDOM_SEED ;
        `else
            global_random_seed = 0;
        `endif
            $msglog(LOG_INFO, "Global random seed being set to %0d", global_random_seed);
        end
    `endif



//===========================================================================
  // VIP modules
//===========================================================================
    reg reset;
    wire clkreq_n;

    // Global Memory seen by everything in the system
    svc_mem mem0();
    defparam mem0.DISPLAY_NAME = "mem0.";

    `ifdef EXPERTIO_PCIESVC_GLOBAL_SHADOW_PATH
        pciesvc_global_shadow global_shadow0();
        defparam global_shadow0.DISPLAY_NAME = "global_shadow0.";
    `else
        `ifdef PCIESVC_INCLUDE_SYSTEMVERILOG_API
            pciesvc_global_shadow global_shadow0();
            defparam global_shadow0.DISPLAY_NAME = "global_shadow0.";
            defparam global_shadow0.HIERARCHY_NUMBER = 0;  // default root_x8 hierarchy
        `endif // PCIESVC_INCLUDE_SYSTEMVERILOG_API
    `endif  // EXPERTIO_PCIESVC_GLOBAL_SHADOW_PATH

    // SERDES
    `ACX_SERDES_MODEL_DATA(root_x8_tx);
    `ACX_SERDES_MODEL_DATA(root_x16_tx);
    `ACX_SERDES_MODEL_DATA(x8_endpoint_tx);
    `ACX_SERDES_MODEL_DATA(x16_endpoint_tx);

    // PCIe x8 root complex model
    pciesvc_device_serdes_x16_model_8g root_x8(
                          .reset                (reset),
                          .clkreq_n             (clkreq_n),
                          `SERDES_PORT_CONNECT  (rx, x8_endpoint_tx),
                          `SERDES_PORT_CONNECT  (tx, root_x8_tx)
                         );

    // PCIe x16 root complex model
    pciesvc_device_serdes_x16_model_8g root_x16(
                          .reset                (reset),
                          .clkreq_n             (clkreq_n),
                          `SERDES_PORT_CONNECT  (rx, x16_endpoint_tx),
                          `SERDES_PORT_CONNECT  (tx, root_x16_tx)
                         );


    defparam root_x8.DISPLAY_NAME = "root_x8.";
    defparam root_x8.DEVICE_IS_ROOT = 1;
    defparam root_x8.PCIE_SPEC_VER = PCIE_SPEC_VER_5_0;

    defparam root_x16.DISPLAY_NAME = "root_x16.";
    defparam root_x16.DEVICE_IS_ROOT = 1;
    defparam root_x16.PCIE_SPEC_VER = PCIE_SPEC_VER_5_0;

`endif //ACX_PCIE_FULL

    // -------------------------
    // Local signals
    // -------------------------
    logic       clk            = 1'b0;
    logic       serdes_ref_clk = 1'b0;
    logic       reset_n;
    logic       test_start;
    logic       test_fail;
    logic       mstr_test_fail;
    logic       mstr_test_fail_d;
    logic       chip_ready;
    logic       test_timeout;
    logic       test_complete_pciex16;
    logic       test_complete_pciex8;
    logic       test_complete;
    logic       mstr_test_complete;
    logic       pll_1_lock;
    logic       pciex8_bfm_test_done;
    logic       pciex16_bfm_test_done;
    logic       pciex8_rtl_test_done;
    logic       pciex16_rtl_test_done;

    // IP interface ports from PCIe cores
    logic [3:0] pci_express_x16_status_flr_pf_active;
    logic       pci_express_x16_status_flr_vf_active;
    logic [5:0] pci_express_x16_status_ltssm_state;
    logic [5:0] pci_express_x8_status_ltssm_state;


    // PLL lock to the design will be asserted once configuration is complete
    // In the testbench, reset_n is driven after configuration
    assign pll_1_lock = reset_n;

    // Test done is driven by different testcases depending on whether
    // the PCIe core is in BFM or RTL simulation mode
`ifndef ACX_PCIE_1_FULL
    assign test_complete_pciex16 = pciex16_bfm_test_done;
`else
    assign test_complete_pciex16 = pciex16_rtl_test_done;
`endif

`ifndef ACX_PCIE_0_FULL
    assign test_complete_pciex8 = pciex8_bfm_test_done;
`else
    assign test_complete_pciex8 = pciex8_rtl_test_done;
`endif


   
   // set when the test is complete
   assign test_complete = (test_complete_pciex16 &
                           test_complete_pciex8 &
                           mstr_test_complete) | test_fail;
   
   
    // -------------------------
    // Clocks
    // -------------------------
    // Define clock as 500MHz
    // At this point the timescale is in ps, so set clocks to correct frequencies based on ps
    localparam CLOCK_PERIOD             = 2000;     // 500MHz DUT clock
    // REVISIT - This gives a 100GHz signal, not 100MHz.  But serdes not locking without it!!
    localparam SERDES_REF_CLOCK_PERIOD  = 10;    // 100MHz serdes reference clock

    always #(CLOCK_PERIOD/2)            clk            <= ~clk;
    always #(SERDES_REF_CLOCK_PERIOD/2) serdes_ref_clk <= ~serdes_ref_clk;

   // -------------------------
   // Simulation sequence
   // -------------------------

   // Deassert reset after 50 cycles
   initial
     begin
        reset_n    <= 1'b0;
        test_start <= 1'b0;
        while ( chip_ready !== 1'b1 )
          @(posedge clk);
        repeat (10) @(posedge clk); // Board response time to chip asserting ready
        $display($time, ": Chip is ready, release reset");
        reset_n <= 1'b1;
        // Start test 50 cycles later
        repeat (50) @(posedge clk);
        test_start <= 1'b1;
     end

   
   // Timeout to stop the test if required
   initial
     begin
        test_timeout <= 1'b0;
        repeat (TIMEOUT_LIMIT) @(posedge clk);
        test_timeout <= 1'b1;
     end

   // After a period, assert finish
   initial
     begin
        #100;
        @(posedge reset_n);
        while ( ~(test_timeout || test_complete) )
          @(posedge clk);

        if ( ~test_complete )
          $error( "%t : Test didn't complete in time", $time );
        
        if ( test_fail || test_timeout  )
          $error( "%t : TEST FAILED", $time );
        else
          $display( "%t : TEST PASSED", $time );
        $finish;
     end

//===========================================================================
   //Instantiate Speedster7t1500
//===========================================================================

  `include "ac7t1500_utils.svh"

  ac7t1500  ac7t1500 (
                      .SRDS_N6_REFCLK_N                 (~serdes_ref_clk),
                      .SRDS_N7_REFCLK_N                 (~serdes_ref_clk),
                      .SRDS_N0_REFCLK_N                 (~serdes_ref_clk),
                      .SRDS_N1_REFCLK_N                 (~serdes_ref_clk),
                      .SRDS_N2_REFCLK_N                 (~serdes_ref_clk),
                      .SRDS_N3_REFCLK_N                 (~serdes_ref_clk),
                      .SRDS_N6_REFCLK_P                 (serdes_ref_clk),
                      .SRDS_N7_REFCLK_P                 (serdes_ref_clk),
                      .SRDS_N0_REFCLK_P                 (serdes_ref_clk),
                      .SRDS_N1_REFCLK_P                 (serdes_ref_clk),
                      .SRDS_N2_REFCLK_P                 (serdes_ref_clk),
                      .SRDS_N3_REFCLK_P                 (serdes_ref_clk),
`ifdef ACX_PCIE_FULL
                      `ACX_PCIEX16_SERDES_PORT_CONNECT  (RX, root_x16_tx),
                      `ACX_PCIEX16_SERDES_PORT_CONNECT  (TX, x16_endpoint_tx),
                      `ACX_PCIEX8_SERDES_PORT_CONNECT   (RX, root_x8_tx),
                      `ACX_PCIEX8_SERDES_PORT_CONNECT   (TX, x8_endpoint_tx),
`endif
                      .FCU_CONFIG_USER_MODE             (chip_ready)
                    );

//===========================================================================
   // Configure DSM and load PCIe configuration files
//===========================================================================

    // Following config files are used to configure the PCIe RTL cores
    string     pciex16CfgFileName   = "../../src/tb/Gen5_16lanes_PCIE_1_mem64Bit_bitstream0.txt" ;
    string     pciex8CfgFileName    = "../../src/tb/Gen5_8lanes_PCIE_0_mem64Bit_bitstream0.txt" ;

    initial begin
        // Ensure correct version of sim package is being used
        // This design requires 8.2 as a minimum
        ac7t1500.require_version(8, 3, 3, "a");
        // Set the verbosity options on the messages
        #10;    // Allow interfaces to be created before setting verbosity
        ac7t1500.set_verbosity(2);

        // Configure PCIe cores
        fork
        `ifdef ACX_PCIE_0_FULL
            ac7t1500.fcu.configure (pciex8CfgFileName, "full") ;
        `endif
        `ifdef ACX_PCIE_1_FULL
            ac7t1500.fcu.configure (pciex16CfgFileName, "full") ;
        `endif
        join

    end

   
//===========================================================================
   //Bind DUT logic to FPGA resources
//===========================================================================
   // BRAM responder
   // AXI master NAP at col=3, row=5 
   `ACX_BIND_NAP_AXI_MASTER(DUT.i_axi_bram_rsp1.i_axi_master_nap.i_axi_master,3,5);

   // BRAM responder
   // AXI master NAP at col=7, row=6 
   `ACX_BIND_NAP_AXI_MASTER(DUT.i_axi_bram_rsp2.i_axi_master_nap.i_axi_master,7,6);
   
   // register set
   // AXI master NAP at col=1, row=7 
   `ACX_BIND_NAP_AXI_MASTER(DUT.i_axi_nap_reg_set1.i_axi_master_nap.i_axi_master,1,7);
   
   // register set
   // AXI master NAP at col=5, row=2 
   `ACX_BIND_NAP_AXI_MASTER(DUT.i_axi_nap_reg_set2.i_axi_master_nap.i_axi_master,5,2);

   // Master logic data generator/checker for PCIe
   // AXI Slave NAP at col=2, row=4
   `ACX_BIND_NAP_AXI_SLAVE(DUT.i_pcie16_axi_gen_chk.i_axi_slave_wrapper_in.i_axi_slave,2,4);
   

   // Master logic data generator/checker for PCIe
   // AXI Slave NAP at col=6, row=3
   `ACX_BIND_NAP_AXI_SLAVE(DUT.i_pcie8_axi_gen_chk.i_axi_slave_wrapper_in.i_axi_slave,6,3);
   
   // Bind ports from DSM to DUT
   `ifdef ACX_DSM_INTERFACES_TO_MONITOR_MODE
       `include "../../src/ioring/pcie_ref_design_top_user_design_port_bindings.svh"
   `endif


//===========================================================================
   // Instantiate DUT
//===========================================================================
   pcie_ref_design_top  DUT (
                                // Inputs
                                .i_clk                      (clk),
                                .i_reset_n                  (reset_n),
                                .i_start                    (test_start),
                                .pll_1_lock                 (pll_1_lock),

                                // Fabric IO signals from IP
                                .*,

                                // Outputs
                                .o_mstr_test_complete       (mstr_test_complete),
                                .o_mstr_test_complete_oe    (),
                                .o_fail                     (mstr_test_fail),
                                .o_fail_oe                  ()
                                );

   // -------------------------
   // Monitor the test
   // -------------------------
   // Only assert error message once on rising edge of fail
   always @(posedge clk or negedge reset_n)
     begin
        if (~reset_n) begin
          test_fail <= 0;
          mstr_test_fail_d <= 0;
        end
        else begin
          mstr_test_fail_d <= mstr_test_fail;
          // Note that $error automatically issues the location of the error
          if( mstr_test_fail & ~mstr_test_fail_d ) begin
            test_fail <= 1;
            $error( "%t : test_fail asserted", $time );
          end
        end
     end


   
//===========================================================================
   // Start the BFM Mode test
//===========================================================================

   pcie_bfm_testcase pcie_bfm_testcase(.reset_n                 (reset_n),
                                       .test_start              (test_start),
                                       .pciex8_bfm_test_done    (pciex8_bfm_test_done),
                                       .pciex16_bfm_test_done   (pciex16_bfm_test_done)
);

`ifdef ACX_PCIE_FULL
//===========================================================================
   // Start the RTL Mode test
//===========================================================================

   pcie_rtl_testcase pcie_rtl_testcase(
                                       .pciex8_bfm_test_done    (pciex8_bfm_test_done),
                                       .pciex16_bfm_test_done   (pciex16_bfm_test_done),
                                       .pciex8_rtl_test_done    (pciex8_rtl_test_done),
                                       .pciex16_rtl_test_done   (pciex16_rtl_test_done)
);

`endif   //ACX_PCIE_FULL

//===========================================================================
   // Simulation dump signals to file
//===========================================================================
   // Optionally enabled as can slow simulation
`ifdef DUMP_SIM_SIGNALS
   initial
     begin
 `ifdef VCS
        $vcdplusfile("sim_output_pluson.vpd");  
        $vcdpluson(0,`TB_NAME);
  `ifdef SIMSTEP_fullchip_bs
        $vcdpluson(0,`TB_NAME.DUT);
  `endif
 `elsif MODEL_TECH   // Defined by QuestaSim
        // WLF filename is set by using the -wlf option to vsim
        // or else in the modelsim.ini file.
        $wlfdumpvars(0, `TB_NAME);
  `ifdef SIMSTEP_fullchip_bs
        $wlfdumpvars(0,`TB_NAME.DUT);
  `endif
 `endif
     end
`endif


endmodule : `TB_NAME
