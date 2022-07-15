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
// Speedster7t GDDR reference design (RD17)
//      Testbench
//      Can use either simple behavioural model of NAP or 
//      fullchip NoC and GDDR models
// ------------------------------------------------------------------

// Control whether signal dump vpd/wlf files are generated
`define DUMP_SIM_SIGNALS

`include "gddr_dci_port_names.svh"
`include "gddr_model_names.svh"

`timescale 1 ps / 1 ps

// Path to the ioring simulation files
`define ACX_IORING_SIM_FILES_PATH "../../src/ioring/"

module tb_gddr_ref_design (
);

    // -------------------------
    // Local signals
    // -------------------------
    logic   clk = 0;
    logic   reset_n;
    logic   chip_ready;
    logic   test_start;
    logic   test_fail;
    logic   test_fail_d;
    logic   test_timeout;
    logic   test_complete;
    

    // -------------------------
    // Define clock in FPGA Fabric as 500MHz
    // -------------------------
    localparam   CLOCK_PERIOD = 2000;
    always #(CLOCK_PERIOD/2) clk <= ~clk;

    // -------------------------
    // Define number of interfaces
    // -------------------------
    localparam   GDDR6_NOC_CONFIG            = 8'b11111111;
    localparam   GDDR6_DCI_CONFIG            = 4'b1111;

    // -------------------------
    // Define GDDR interface Data Rate
    // -------------------------

    `ifdef GDDR6_DATA_RATE_16
      localparam GDDR_DATA_RATE = 16;
      localparam GDDR_CONTROLLER_CLOCK_PERIOD = 1008; // Updated for Micron model
      localparam GDDR_CFG_FILENAME = "../gddr_config_16Gbps.txt";
    `endif

    `ifdef GDDR6_DATA_RATE_14
      localparam GDDR_DATA_RATE = 14;
      localparam GDDR_CONTROLLER_CLOCK_PERIOD = 1152; // Updated for Micron model
      localparam GDDR_CFG_FILENAME = "../gddr_config_14Gbps.txt";
    `endif

    `ifdef GDDR6_DATA_RATE_12
      localparam GDDR_DATA_RATE = 12;
      localparam GDDR_CONTROLLER_CLOCK_PERIOD = 1344; // Updated for Micron model
      localparam GDDR_CFG_FILENAME = "../gddr_config_12Gbps.txt";
    `endif

    // -------------------------
    // Simulation sequence
    // -------------------------

    // Deassert reset 10 cycles after chip_ready.
    initial
    begin
        reset_n <= 1'b0;
        test_start <= 1'b0;
        #10;    // To prevent false triggering at time 0 when chip_ready is being assigned.
        while ( chip_ready !== 1'b1 )
            @(posedge clk);
        repeat (10) @(posedge clk); // Board response time to chip asserting ready
        reset_n <= 1'b1;
        // Start test 50 cycles later
        repeat (50) @(posedge clk);
        test_start <= 1'b1;
        $display("%t : Test started", $time);
    end

// Unfortunately ifdefs cannot be OR'd together
// Note : Cannot use ACX_GDDR6_RTL_INCLUDE as it is defined in a separate file which
// will be compiled independently of this file
// Create new define to indicate to this file when any of the GDDR controllers is using
// RTL
`ifdef ACX_GDDR6_0_FULL
    `define ACX_GDDR6_RTL_USED
`elsif ACX_GDDR6_1_FULL
    `define ACX_GDDR6_RTL_USED
`elsif ACX_GDDR6_2_FULL
    `define ACX_GDDR6_RTL_USED
`elsif ACX_GDDR6_3_FULL
    `define ACX_GDDR6_RTL_USED
`elsif ACX_GDDR6_4_FULL
    `define ACX_GDDR6_RTL_USED
`elsif ACX_GDDR6_5_FULL
    `define ACX_GDDR6_RTL_USED
`elsif ACX_GDDR6_6_FULL
    `define ACX_GDDR6_RTL_USED
`elsif ACX_GDDR6_7_FULL
    `define ACX_GDDR6_RTL_USED
`endif

    // Timeout to stop the test if required
    initial
    begin
        test_timeout <= 1'b0;
        // Standalone test of 1000 transactions, is approximately 200us
        # 200us;

        // If not in standalone mode and at least
        // one of the GDDR controllers is using RTL
        // Then initialisation time is 130us
`ifndef ACX_SIM_STANDALONE_MODE
    `ifdef ACX_GDDR6_RTL_USED
            $display("Extend sim timeout as GDDR RTL detected");
            # 130us;
    `endif
`endif
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

        if ( test_fail || test_timeout )
            $error( "%t : TEST FAILED", $time );
        else
            $display( "%t : TEST PASSED", $time );

        $finish;
    end

    // --------------------------------------------
    // Declare the Direct Connect interface signals
    // --------------------------------------------
    // These will not be used in STANDALONE mode
    // However they still need to be defined so they are connected to the DUT

    // West side GDDR DCI ports
    `ACX_GDDR_TB_DCI_PORT(gddr6_1_dc0)
    `ACX_GDDR_TB_DCI_PORT(gddr6_2_dc0)  
    // East side GDDR DCI ports
    `ACX_GDDR_TB_DCI_PORT(gddr6_5_dc0)
    `ACX_GDDR_TB_DCI_PORT(gddr6_6_dc0)
        
    // -------------------------
    // Simulation model of NOC
    // -------------------------
`ifdef ACX_SIM_STANDALONE_MODE
    // When binding, the module is inside the target module, so gets
    // parameters and signal names from that module - not this module
    genvar i;    
    for ( i=0; i<8;i=i+1) begin
      if (GDDR6_NOC_CONFIG[i]) begin
        bind DUT.gddr_gen_noc[i].noc_on.i_axi_slave_wrapper.i_axi_slave.x_NAP_AXI_SLAVE
        tb_noc_memory_behavioural #(
            .INIT_FILE_NAME            (""),
            .WRITE_FILE_NAME           (""),
            .CHECK_FILE_NAME           (""),
            .MEM_TYPE                  ("gddr"),
            .DST_DATA_WIDTH            (256),
            .CHK_ADDR_WIDTH            (19),
            .CHK_ADDR_MASK_BITS        (16),
            .CHK_DATA_MASK_BITS        (16),
            .VERBOSITY                 (3)
        ) i_noc_gddr_in (
            // Inputs
            .i_clk                     (clk),      // This signal refers to the clk input on the NAP_AXI_SLAVE
            .i_reset_n                 (rstn),     // This signal refers to the rstn input on the NAP_AXI_SLAVE
            .i_write_result            (1'b0)
        );
      end
    end

    // Need to drive the chip ready signal to start the testbench
    initial
    begin
        chip_ready = 1'b0;
        #100000;
        chip_ready = 1'b1;
    end

`else   // Use the full chip simulation

    // Include the DSM utility file which defines the macros
    `include "ac7t1500_utils.svh"

    // ----------------------------------------------------------------------------

    // Create the wires to connect between the DSM and the GDDR memory models
    `ACX_GDDR_MODEL_WIRE(gddr6_0);
    `ACX_GDDR_MODEL_WIRE(gddr6_1);
    `ACX_GDDR_MODEL_WIRE(gddr6_2);
    `ACX_GDDR_MODEL_WIRE(gddr6_3);
    `ACX_GDDR_MODEL_WIRE(gddr6_4);
    `ACX_GDDR_MODEL_WIRE(gddr6_5);
    `ACX_GDDR_MODEL_WIRE(gddr6_6);
    `ACX_GDDR_MODEL_WIRE(gddr6_7);

    // Instantiate Speedster7t1500
    // Connect chip_ready and GDDR ports
    ac7t1500 ac7t1500( 
               .FCU_CONFIG_USER_MODE (chip_ready),
               `ACX_GDDR_PORT_CONNECT(GDDR6_E0, gddr6_0),
               `ACX_GDDR_PORT_CONNECT(GDDR6_E1, gddr6_1),
               `ACX_GDDR_PORT_CONNECT(GDDR6_E2, gddr6_2),
               `ACX_GDDR_PORT_CONNECT(GDDR6_E3, gddr6_3),
               `ACX_GDDR_PORT_CONNECT(GDDR6_W0, gddr6_4),
               `ACX_GDDR_PORT_CONNECT(GDDR6_W1, gddr6_5),
               `ACX_GDDR_PORT_CONNECT(GDDR6_W2, gddr6_6),
               `ACX_GDDR_PORT_CONNECT(GDDR6_W3, gddr6_7)
     );


    initial begin
        // Ensure correct version of sim package is being used
        // This design requires 8.3.alpha as a minimum
        ac7t1500.require_version(8, 3, 3, "a");
        // Set the verbosity options on the messages
        ac7t1500.set_verbosity(3);

        // Set GDDR interface clock frequencies to match the design target
        // Valid settings are:
        // GDDR Data Rate 16Gbps --> Controller Clock set to 1GHz
        // GDDR Data Rate 14Gbps --> Controller Clock set to 875MHz
        // GDDR Data Rate 12Gbps --> Controller Clock set to 750MHz

        // AXI clock at NAP interface is the same as controller clock rate
        ac7t1500.clocks.set_clock_period("gddr_0_noc0_clk", GDDR_CONTROLLER_CLOCK_PERIOD);
        ac7t1500.clocks.set_clock_period("gddr_0_noc1_clk", GDDR_CONTROLLER_CLOCK_PERIOD);
        ac7t1500.clocks.set_clock_period("gddr_1_noc0_clk", GDDR_CONTROLLER_CLOCK_PERIOD);
        ac7t1500.clocks.set_clock_period("gddr_1_noc1_clk", GDDR_CONTROLLER_CLOCK_PERIOD);
        ac7t1500.clocks.set_clock_period("gddr_2_noc0_clk", GDDR_CONTROLLER_CLOCK_PERIOD);
        ac7t1500.clocks.set_clock_period("gddr_2_noc1_clk", GDDR_CONTROLLER_CLOCK_PERIOD);
        ac7t1500.clocks.set_clock_period("gddr_3_noc0_clk", GDDR_CONTROLLER_CLOCK_PERIOD);
        ac7t1500.clocks.set_clock_period("gddr_3_noc1_clk", GDDR_CONTROLLER_CLOCK_PERIOD);
        ac7t1500.clocks.set_clock_period("gddr_4_noc0_clk", GDDR_CONTROLLER_CLOCK_PERIOD);
        ac7t1500.clocks.set_clock_period("gddr_4_noc1_clk", GDDR_CONTROLLER_CLOCK_PERIOD);
        ac7t1500.clocks.set_clock_period("gddr_5_noc0_clk", GDDR_CONTROLLER_CLOCK_PERIOD);
        ac7t1500.clocks.set_clock_period("gddr_5_noc1_clk", GDDR_CONTROLLER_CLOCK_PERIOD);
        ac7t1500.clocks.set_clock_period("gddr_6_noc0_clk", GDDR_CONTROLLER_CLOCK_PERIOD);
        ac7t1500.clocks.set_clock_period("gddr_6_noc1_clk", GDDR_CONTROLLER_CLOCK_PERIOD);
        ac7t1500.clocks.set_clock_period("gddr_7_noc0_clk", GDDR_CONTROLLER_CLOCK_PERIOD);
        ac7t1500.clocks.set_clock_period("gddr_7_noc1_clk", GDDR_CONTROLLER_CLOCK_PERIOD);

        // AXI clock at DCI is half of controller clock rate
        ac7t1500.clocks.set_clock_period("gddr_1_dc0_clk", GDDR_CONTROLLER_CLOCK_PERIOD*2);
        ac7t1500.clocks.set_clock_period("gddr_1_dc1_clk", GDDR_CONTROLLER_CLOCK_PERIOD*2);
        ac7t1500.clocks.set_clock_period("gddr_2_dc0_clk", GDDR_CONTROLLER_CLOCK_PERIOD*2);
        ac7t1500.clocks.set_clock_period("gddr_2_dc1_clk", GDDR_CONTROLLER_CLOCK_PERIOD*2);
        ac7t1500.clocks.set_clock_period("gddr_5_dc0_clk", GDDR_CONTROLLER_CLOCK_PERIOD*2);
        ac7t1500.clocks.set_clock_period("gddr_5_dc1_clk", GDDR_CONTROLLER_CLOCK_PERIOD*2);
        ac7t1500.clocks.set_clock_period("gddr_6_dc0_clk", GDDR_CONTROLLER_CLOCK_PERIOD*2);
        ac7t1500.clocks.set_clock_period("gddr_6_dc1_clk", GDDR_CONTROLLER_CLOCK_PERIOD*2);


        // -------------------------
        // Configure GDDR controllers in RTL mode
        // -------------------------
        // `include "../../src/ioring/gddr_ref_design_top_sim_config.svh"


      fork
        `ifdef ACX_GDDR6_0_FULL
          ac7t1500.fcu.configure( GDDR_CFG_FILENAME, "gddr_0");
        `endif
        `ifdef ACX_GDDR6_1_FULL
          ac7t1500.fcu.configure( GDDR_CFG_FILENAME, "gddr_1");
        `endif
        `ifdef ACX_GDDR6_2_FULL
          ac7t1500.fcu.configure( GDDR_CFG_FILENAME, "gddr_2");
        `endif
        `ifdef ACX_GDDR6_3_FULL
          ac7t1500.fcu.configure( GDDR_CFG_FILENAME, "gddr_3");
        `endif
        `ifdef ACX_GDDR6_4_FULL
          ac7t1500.fcu.configure( GDDR_CFG_FILENAME, "gddr_4");
        `endif
        `ifdef ACX_GDDR6_5_FULL
          ac7t1500.fcu.configure( GDDR_CFG_FILENAME, "gddr_5");
        `endif
        `ifdef ACX_GDDR6_6_FULL
          ac7t1500.fcu.configure( GDDR_CFG_FILENAME, "gddr_6");
        `endif
        `ifdef ACX_GDDR6_7_FULL
          ac7t1500.fcu.configure( GDDR_CFG_FILENAME, "gddr_7");
        `endif
      join

    end

    // -------------------------
    // Bind the NAP used to poll for GDDR configuration registers
    // -------------------------
    `ACX_BIND_NAP_AXI_SLAVE(DUT.i_axi_nap_csr_master.i_axi_slave_wrapper_cfg.i_axi_slave,4,5);

    // Bind the DUT NAPs to locations within the NoC
    // For consistency between simulation and implmentation, these locations match
    // those specified in the placement file, /constraints/ace_placements.pdc
    genvar i;
    generate  
        for ( i=0; i<8;i=i+1) begin : gb_nap_bind
          if (GDDR6_NOC_CONFIG[i])begin
            if (i < 4)begin
            `ACX_BIND_NAP_AXI_SLAVE(DUT.gddr_gen_noc[i].noc_on.i_axi_slave_wrapper.i_axi_slave,5,(i+3));
            end
            else begin
            `ACX_BIND_NAP_AXI_SLAVE(DUT.gddr_gen_noc[i].noc_on.i_axi_slave_wrapper.i_axi_slave,6,(i-1));
            end
          end  
        end  
    endgenerate

    // ----------------------------------------------------------------------------
    // Assign the DUT DCI IO ports to the DSM DCI ports
    // The middle four out of the eight GDDR6 controllers support DCI 
    // ----------------------------------------------------------------------------

    // There are two methods for connecting to the DSM DCI ports
    // Either using the DSM built in interfaces, (AXI for GDDR)
    // or by using the ACE generated port binding file.
    // The define ACX_DSM_INTERFACES_TO_MONITOR_MODE controls the mode of the DSM
    // DCI ports, and is also used to determine the usage of the port bindings file
    `ifdef ACX_DSM_INTERFACES_TO_MONITOR_MODE
        `include "../../src/ioring/gddr_ref_design_top_user_design_port_bindings.svh"
    `else
        // West side DCI port connections to 1 and 2
        `ACX_GDDR_TB_DCI_ASSIGN(gddr6_1_dc0,gddr6_1_dc0)
        `ACX_GDDR_TB_DCI_ASSIGN(gddr6_2_dc0,gddr6_2_dc0)

        // East side DCI port connections to 5 and 6
        `ACX_GDDR_TB_DCI_ASSIGN(gddr6_5_dc0,gddr6_5_dc0)
        `ACX_GDDR_TB_DCI_ASSIGN(gddr6_6_dc0,gddr6_6_dc0)
    `endif

`endif

    // PLL signals coming from IO ring
    logic   pll_lock;
    logic   pll_gddr_NE_lock;
    logic   pll_gddr_NW_lock;
    assign  pll_lock         = reset_n;
    assign  pll_gddr_NE_lock = reset_n;
    assign  pll_gddr_NW_lock = reset_n;

    // -------------------------
    // DUT
    // -------------------------
    gddr_ref_design_top #(
        .GDDR6_NOC_CONFIG       (GDDR6_NOC_CONFIG),
        .GDDR6_DCI_CONFIG       (GDDR6_DCI_CONFIG),
        .NUM_TRANSACTIONS       (1000)           // Set to 0 for continuous
    ) DUT (
        // Inputs
        .i_clk                  (clk),
        .i_reset_n              (reset_n),
        .i_start                (test_start),

        .*,                     // Connect the DCI ports, (has same signal names)

        // Outputs
        .o_fail_oe              (),
        .o_xact_done_oe         (),
        .o_xact_done            (test_complete),
        .o_fail                 (test_fail)
    );

    // -------------------------
    // GDDR Model Instantiation
    // -------------------------
    /*
    RTL mode simulation requires use of the GDDR6 memory simulation models. 
    Achronix is not able to provide these models directly to the user.
    Rather, the user needs to acquire these models directly from their preferred vendor.

    The testbench and reference design were developed using models from Micron Technology Inc. 
    To obtain these models, the user should contact Micron Sales or Technical Support directly.

    The following sections shows how a model should be instantiated and connected
    */


`ifdef ACX_GDDR6_0_FULL
    micron_gddr6 # (
        .device(2)      // 16Gb DIE
       ,.datarate(GDDR_DATA_RATE)   // Data rate
       ,.debug(0)) mem_model_w0
    (
      `GDDR_MODEL_PORT_CONNECT(gddr6_0)
    );
`endif

`ifdef ACX_GDDR6_1_FULL
    micron_gddr6 # (
        .device(2)      // 16Gb DIE
       ,.datarate(GDDR_DATA_RATE)   // Data rate
       ,.debug(0)) mem_model_w1
    (
      `GDDR_MODEL_PORT_CONNECT(gddr6_1)
    );
`endif

`ifdef ACX_GDDR6_2_FULL
    micron_gddr6 # (
        .device(2)      // 16Gb DIE
       ,.datarate(GDDR_DATA_RATE)   // Data rate
       ,.debug(0)) mem_model_w2
    (
      `GDDR_MODEL_PORT_CONNECT(gddr6_2)
    );
`endif

`ifdef ACX_GDDR6_3_FULL
    micron_gddr6 # (
        .device(2)      // 16Gb DIE
       ,.datarate(GDDR_DATA_RATE)   // Data rate
       ,.debug(0)) mem_model_w3
    (
      `GDDR_MODEL_PORT_CONNECT(gddr6_3)
    );
`endif

`ifdef ACX_GDDR6_4_FULL
    micron_gddr6 # (
        .device(2)      // 16Gb DIE
       ,.datarate(GDDR_DATA_RATE)   // Data rate
       ,.debug(0)) mem_model_e0
    (
      `GDDR_MODEL_PORT_CONNECT(gddr6_4)
    );
`endif

`ifdef ACX_GDDR6_5_FULL
    micron_gddr6 # (
        .device(2)      // 16Gb DIE
       ,.datarate(GDDR_DATA_RATE)   // Data rate
       ,.debug(0)) mem_model_e1
    (
      `GDDR_MODEL_PORT_CONNECT(gddr6_5)
    );
`endif

`ifdef ACX_GDDR6_6_FULL
    micron_gddr6 # (
        .device(2)      // 16Gb DIE
       ,.datarate(GDDR_DATA_RATE)   // Data rate
       ,.debug(0)) mem_model_e2
    (
      `GDDR_MODEL_PORT_CONNECT(gddr6_6)
    );
`endif

`ifdef ACX_GDDR6_7_FULL
    micron_gddr6 # (
        .device(2)      // 16Gb DIE
       ,.datarate(GDDR_DATA_RATE)   // Data rate
       ,.debug(0)) mem_model_e3
    (
      `GDDR_MODEL_PORT_CONNECT(gddr6_7)
    );
`endif


    // -------------------------
    // Monitor the test
    // -------------------------
    // Only assert error message once on rising edge of fail
    always @(posedge clk)
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
    `ifdef VCS          // Defined by VCS
        $vcdplusfile("sim_output_pluson.vpd");  
        $vcdpluson(0,tb_gddr_ref_design);
        `ifdef SIMSTEP_fullchip_bs
            $vcdpluson(0,`TB_TESTNAME.DUT);
        `endif
    `elsif MODEL_TECH   // Defined by QuestaSim
        // WLF filename is set by using the -wlf option to vsim
        // or else in the modelsim.ini file.
        $wlfdumpvars(0, tb_gddr_ref_design);
        `ifdef SIMSTEP_fullchip_bs
            $wlfdumpvars(0,`TB_TESTNAME.DUT);
        `endif
    `endif
    end
`endif

endmodule : tb_gddr_ref_design

