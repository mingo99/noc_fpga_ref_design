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
// 2D convolution testbench
//      Can use either behavioural model of NAP or FullChip BFM
//      simulation
// ------------------------------------------------------------------

// Control whether signal dump vpd files are generated
`define DUMP_SIM_SIGNALS

/* Testbench to test MLP */
`define TB_TESTNAME tb_mlp_conv2d

`include "7t_interfaces.svh"

module `TB_TESTNAME ();

    // -------------------------
    // Clocks and resets
    // -------------------------
    logic   clk = 0;
    logic   reset_n;
    logic   chip_ready;
    logic   conv2d_error;
    logic   conv_done;
    logic   data_error;

    // Define clock as 750MHz
    localparam CLOCK_PERIOD = 1333;

    always #(CLOCK_PERIOD/2) clk <= ~clk;

    // Deassert reset after 50 cycles
    initial
    begin
        reset_n <= 1'b0;
        #10;    // To prevent false triggering at time 0 when chip_ready is being assigned.
        while ( chip_ready !== 1'b1 )
            @(posedge clk);
        // Board response time to chip asserting ready
        repeat (50) @(posedge clk);
        reset_n <= 1'b1;
    end

    // ------------------------------------------------------
    // Test finish
    // ------------------------------------------------------
    // Have timeout in case test fails to complete in time
    logic test_timeout = 0;
    initial
    begin
        repeat (150000) @(posedge clk);
        test_timeout = 1;
    end

    initial
    begin
        repeat (50) @(posedge clk);
        @(posedge reset_n);
        repeat (50) @(posedge clk);
        @(posedge (test_timeout | conv_done) );

        if( test_timeout )
            $error( "Test timed out" );

        if( test_timeout | data_error | conv2d_error )
            $error( "Test FAILED" );
        else
            $display( "%t : Test PASSED", $time );

        repeat (50) @(posedge clk);
        $finish;
    end

    // -------------------------
    // Simulation modes
    // -------------------------

    // Actual NAP is 256 bits.  Input FIFO is only 144.
    localparam  INF_DATA_WIDTH = 144;

    // Testbench has to connect to NAP slave via tasks
    // Use hierarchical links
`ifdef ACX_SIM_STANDALONE_MODE

    // When binding, the module is inside the target module, so gets
    // parameters and signal names from that module - not this module
    bind i_conv2d.i_axi_slave_wrapper_in.i_axi_slave
    tb_noc_memory_behavioural #(
        .INIT_FILE_NAME         ("../../src/mem_init_files/nap_in.txt"),
        .MEM_TYPE               ("gddr"),
        .DST_DATA_WIDTH         (144),
        .VERBOSITY              (3)
    ) i_noc_gddr_in (
        // Inputs
        .i_clk                  (clk),
        .i_reset_n              (rstn),
        .i_write_result         (1'b0)
    );

    bind i_conv2d.i_axi_slave_wrapper_out.i_axi_slave
    tb_noc_memory_behavioural #(
        .INIT_FILE_NAME         (""),
        .MEM_TYPE               ("gddr"),
        .DST_DATA_WIDTH         (144),
        .VERBOSITY              (3)
    ) i_noc_gddr_out (
        // Inputs
        .i_clk                  (clk),
        .i_reset_n              (rstn),
        .i_write_result         (1'b0)
    );


    // The memory checker needs the t_AXI4 port type
    // Following defined in makefile as it needs to defined before 
    // tb_axi_mem_checker compiled
    // `define AXI_MEM_CHECK_AXI4_PORT

    tb_axi_mem_checker #(
        .WRITE_FILE_NAME        ("../../src/mem_init_files/nap_out_compare.txt"),
        .CHECK_FILE_NAME        ("../../src/mem_init_files/nap_out.txt"),
        .AXI_DATA_WIDTH         (256),
        .AXI_ADDR_WIDTH         (42),
        .ADDR_MASK_BITS         (21),   // 16 bits offset + 5 bits shift
        .DATA_MASK_BITS         (192)   // Some columns only have 12 MLP, so max bits for comparision is 12x16
    ) i_nap_chk (
        // Inputs
        .i_clk                  (clk),
        .i_reset_n              (reset_n),
        .i_write_result         (conv_done),
        // AXI
        .axi                    (i_conv2d.nap_out),  // Monitor the AXI interface to the output NAP

        // Outputs
        .o_error                (data_error)
    );

    // Need to drive the chip ready signal to start the testbench
    initial
    begin
        chip_ready = 1'b0;
        #100000;
        chip_ready = 1'b1;
    end

`else // FULLCHIP_BFM mode

    // Need to include the header file
    `include "ac7t1500_utils.svh"

    // Instantiate Speedster7t1500
    // Connect all ports to same named signals
    ac7t1500 ac7t1500( .FCU_CONFIG_USER_MODE (chip_ready) );

    initial begin
        // Ensure correct version of sim package is being used
        // This design requires 8.2 as a minimum
        ac7t1500.require_version(8, 2, 0, 0);
        // Set the verbosity options on the messages
        ac7t1500.verbosity = 3;
    end

    // Bind the two NAPs
    `ACX_BIND_NAP_AXI_SLAVE(i_conv2d.i_axi_slave_wrapper_in.i_axi_slave,1,1);
    `ACX_BIND_NAP_AXI_SLAVE(i_conv2d.i_axi_slave_wrapper_out.i_axi_slave,1,2);

    // ------------------------------------------------------
    // Connect and monitor GDDR interface within device
    // ------------------------------------------------------

    // Initialise the GDDR.
    defparam ac7t1500.fullchip_top.u_gddr6_sdram_sys_top_w2.u_lower_ch.INIT_FILE_NAME = "../../src/mem_init_files/nap_in.txt";

    // The design targets GDDR6 at address 0x0.  This is the West 2, noc0 interface
    `define ACX_GDDR_NOC_PATH ac7t1500.interfaces.gddr6_w2_noc0

    // tb_axi_mem_checker #(
    //     .WRITE_FILE_NAME        ("../../src/mem_init_files/nap_out_compare.txt"),
    //     .CHECK_FILE_NAME        ("../../src/mem_init_files/nap_out.txt"),
    //     .AXI_DATA_WIDTH         (256),
    //     .AXI_ADDR_WIDTH         (42),
    //     .ADDR_MASK_BITS         (21),   // 16 bits offset + 5 bits shift
    //     .DATA_MASK_BITS         (192)   // Some columns only have 12 MLP, so max bits for comparision is 12x16
    // ) i_nap_chk (
    //     // Inputs
    //     .i_clk                  (`ACX_GDDR_NOC_PATH.clk),
    //     .i_reset_n              (`ACX_GDDR_NOC_PATH.aresetn),
    //     .i_write_result         (conv_done),
    //     // AXI
    //     .axi                    (`ACX_GDDR_NOC_PATH),  // Monitor the AXI interface at the GDDR

    //     // Outputs
    //     .o_error                (data_error)
    // );

`endif

    // ------------------------------------------------------
    // DUT
    // ------------------------------------------------------
    mlp_conv2d_top #(
        // Tensor flow parameters
        .BATCH                  (60),
        .IN_HEIGHT              (227),
        .IN_WIDTH               (227),
        .IN_CHANNELS            (3),
        .FILTER_HEIGHT          (11),
        .FILTER_WIDTH           (11),
        .OUT_CHANNELS           (1),

        .INF_DATA_WIDTH         (INF_DATA_WIDTH)
    ) i_conv2d (
        // Inputs
        .i_clk                  (clk),
        .i_reset_n              (reset_n),
        .pll_1_lock             (chip_ready),
        .pll_2_lock             (chip_ready),
        .o_conv_done            (conv_done),
        .o_error                (conv2d_error)
    );


    // ------------------------------------------------------
    // Simulation waveform dumping
    // ------------------------------------------------------
`ifdef DUMP_SIM_SIGNALS
    initial
    begin
    `ifdef VCS
        // $vcdplusfile("sim_output_pluson.vpd");  
        // $vcdpluson(0,`TB_TESTNAME);
        $fsdbDumpfile("sim_output_pluson.fsdb");  
        $fsdbDumpvars(0,`TB_TESTNAME);
        `ifdef SIMSTEP_fullchip_bs
            // $vcdpluson(0,`TB_TESTNAME.DUT.i_conv2d);
            $fsdbDumpvars(0,`TB_TESTNAME.DUT.i_conv2d);
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

