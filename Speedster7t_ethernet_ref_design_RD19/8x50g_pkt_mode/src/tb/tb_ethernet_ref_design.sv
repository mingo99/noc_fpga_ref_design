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
// Speedster7t Ethernet reference design (RD19)
//      400G, 8x50G, Packet Mode Testbench
//      Looks back device serdes pins
// ------------------------------------------------------------------

`timescale 1 ps / 1 ps

`include "7t_interfaces.svh"

// Control whether signal dump vpd files are generated
`define ACX_DUMP_SIM_SIGNALS

// Select whether Ethernet subsystem 0, (default), or subsystem 1 is used
// `define ACX_USE_ETHERNET1

module tb_ethernet_ref_design #(
    parameter NUM_LOOPBACK_PKTS   = 1000,                   // Number of loopback packets generated, (per NAP)
    parameter CFG_FILENAME        = "../eiu_config.txt"     // EIU configuration file
);

    // -------------------------
    // Local signals
    // -------------------------
    logic           usr_clk = 0;
    logic           ff_clk  = 0;
    logic           ref_clk = 0;
    logic           mac_clk = 0;
    logic           reset_n;
    logic           serdes_reset_n;
    logic           chip_ready;
    logic           test_start;
    logic           test_timeout;
    logic           test_complete;
    logic           plls_lock;

    // Loop back test signals
    logic [31:0]    lb_pkt_num;          // Count the number of received packets
    logic           lb_checksum_error;   // Assert if check failed
    logic           lb_pkt_size_error;   // Assert if packet size error
    logic           lb_payload_error;    // Assert if there is a mismatch
    logic           lb_fail;

    // -------------------------
    // Clocks
    // -------------------------

    // User logic and testbench clock.  Set to 507MHz
    // All Ethernet NAPs must be run at 507MHz.
    localparam CLOCK_PERIOD_TB = 1972;
    always #(CLOCK_PERIOD_TB/2) usr_clk <= ~usr_clk;

    // Ethernet fifo, (ff) clocks
    // As data interfaces are 256 bits wide, 100G = 390MHz.
    // Define clock as 390MHz
    localparam CLOCK_PERIOD_FF = 2570;
    always #(CLOCK_PERIOD_FF/2) ff_clk <= ~ff_clk;

    // MAC requires 900MHz reference clock
    // Also requires ff_clk > 782MHz. Assign to below 900MHz.
    localparam CLOCK_PERIOD_MAC = 1112;
    localparam CLOCK_PERIOD_REF = 1110;
    always #(CLOCK_PERIOD_MAC/2) mac_clk <= ~mac_clk;
    always #(CLOCK_PERIOD_REF/2) ref_clk <= ~ref_clk;

    // Each serdes model is set to 53.125 Gbps.
    // With a 64 bit interface, that translates to a parallel
    // interface frequency of 830MHz, a period of 1204 ps.
    // This is assigned as a define to the serdes BFM models
    // However there are inefficiencies with the PCS BFM model which mean it inserts
    // additional frames.  Therefore it is necessary to run the Serdes BFM model
    // fractionally faster to account of this, with a period of 1000 ps.
    // This is simply a modelling issue which will be addressed in future releases
    // This will not affect the actual PCS or Serdes IP built into the device.
    localparam CLOCK_PERIOD_SERDES = 1000;
    localparam SERDES_DATA_WIDTH   = 64;

    // -------------------------
    // Simulation sequence
    // -------------------------
    initial
    begin
        reset_n        <= 1'b0;
        serdes_reset_n <= 1'b0;
        test_start     <= 1'b0;
        plls_lock      <= 1'b0;

        #10;    // To prevent false triggering at time 0 when chip_ready is being assigned.
        // Chip ready is asserted once configurations are done
        while ( chip_ready !== 1'b1 )
            @(posedge usr_clk);

        // Allow serdes to bring link up
        serdes_reset_n <= 1'b1;

        // When config complete both pll's would be in lock
        plls_lock   <= 1'b1;

        // Release testbench and DUT reset
        repeat (20) @(posedge usr_clk);
        reset_n <= 1'b1;

        // Start test 50 cycles later
        repeat (50) @(posedge usr_clk);

        test_start <= 1'b1;
    end

    // Timeout to stop the test if required
    initial
    begin
        test_timeout <= 1'b0;
        repeat (100000) @(posedge usr_clk);
        test_timeout <= 1'b1;
    end

    // End of test is when after all ip_pkts have been read, and allow time to be returned
    // In addition all loopback packets must have been received
    initial
    begin
        test_complete       = 1'b0;

        while ( test_start !== 1'b1 )
            @(posedge usr_clk);

        // Wait until all loopback packets have been checked
        // Each generator creates NUM_LOOPBACK_PKTS, and there are 4 generators
        while(lb_pkt_num != (NUM_LOOPBACK_PKTS*4))
            @(posedge usr_clk);

        // Test is now done
        test_complete = 1'b1;
    end

    // Loopback fail conditions
    assign lb_fail     = lb_checksum_error | lb_pkt_size_error | lb_payload_error;

    // After a period, assert finish
    initial
    begin
        #100;
        @(posedge reset_n);
        while (~(test_timeout || test_complete))
            @(posedge usr_clk);

        if ( ~test_complete )
            $error( "%t : Test didn't complete in time", $time );

        if ( lb_fail || test_timeout  )
            $error( "TEST FAILED" );
        else
            $display( "%0t : TEST PASSED", $time );

        $finish;
    end


    // -------------------------
    // FPGA
    // -------------------------

    // Include the utility file which defines the macros
    `include "ac7t1500_utils.svh"

    // Serdes pins ethernet subsystem 0
    logic   SRDS_N0_RX_N0;
    logic   SRDS_N0_RX_N1;
    logic   SRDS_N0_RX_N2;
    logic   SRDS_N0_RX_N3;
    logic   SRDS_N0_RX_P0;
    logic   SRDS_N0_RX_P1;
    logic   SRDS_N0_RX_P2;
    logic   SRDS_N0_RX_P3;
    logic   SRDS_N1_RX_N0;
    logic   SRDS_N1_RX_N1;
    logic   SRDS_N1_RX_N2;
    logic   SRDS_N1_RX_N3;
    logic   SRDS_N1_RX_P0;
    logic   SRDS_N1_RX_P1;
    logic   SRDS_N1_RX_P2;
    logic   SRDS_N1_RX_P3;
    logic   SRDS_N0_TX_N0;
    logic   SRDS_N0_TX_N1;
    logic   SRDS_N0_TX_N2;
    logic   SRDS_N0_TX_N3;
    logic   SRDS_N0_TX_P0;
    logic   SRDS_N0_TX_P1;
    logic   SRDS_N0_TX_P2;
    logic   SRDS_N0_TX_P3;
    logic   SRDS_N1_TX_N0;
    logic   SRDS_N1_TX_N1;
    logic   SRDS_N1_TX_N2;
    logic   SRDS_N1_TX_N3;
    logic   SRDS_N1_TX_P0;
    logic   SRDS_N1_TX_P1;
    logic   SRDS_N1_TX_P2;
    logic   SRDS_N1_TX_P3;

    // Serdes pins ethernet subsystem 1
    logic   SRDS_N2_RX_N0;
    logic   SRDS_N2_RX_N1;
    logic   SRDS_N2_RX_N2;
    logic   SRDS_N2_RX_N3;
    logic   SRDS_N2_RX_P0;
    logic   SRDS_N2_RX_P1;
    logic   SRDS_N2_RX_P2;
    logic   SRDS_N2_RX_P3;
    logic   SRDS_N3_RX_N0;
    logic   SRDS_N3_RX_N1;
    logic   SRDS_N3_RX_N2;
    logic   SRDS_N3_RX_N3;
    logic   SRDS_N3_RX_P0;
    logic   SRDS_N3_RX_P1;
    logic   SRDS_N3_RX_P2;
    logic   SRDS_N3_RX_P3;
    logic   SRDS_N2_TX_N0;
    logic   SRDS_N2_TX_N1;
    logic   SRDS_N2_TX_N2;
    logic   SRDS_N2_TX_N3;
    logic   SRDS_N2_TX_P0;
    logic   SRDS_N2_TX_P1;
    logic   SRDS_N2_TX_P2;
    logic   SRDS_N2_TX_P3;
    logic   SRDS_N3_TX_N0;
    logic   SRDS_N3_TX_N1;
    logic   SRDS_N3_TX_N2;
    logic   SRDS_N3_TX_N3;
    logic   SRDS_N3_TX_P0;
    logic   SRDS_N3_TX_P1;
    logic   SRDS_N3_TX_P2;
    logic   SRDS_N3_TX_P3;

    // Instantiate Speedster7t1500
    // Connect the chip_ready and serdes signals
    ac7t1500 ac7t1500(
        .FCU_CONFIG_USER_MODE   (chip_ready),

        // Ethernet subsystem 0
        .SRDS_N0_RX_N0,
        .SRDS_N0_RX_N1,
        .SRDS_N0_RX_N2,
        .SRDS_N0_RX_N3,
        .SRDS_N0_RX_P0,
        .SRDS_N0_RX_P1,
        .SRDS_N0_RX_P2,
        .SRDS_N0_RX_P3,
        .SRDS_N1_RX_N0,
        .SRDS_N1_RX_N1,
        .SRDS_N1_RX_N2,
        .SRDS_N1_RX_N3,
        .SRDS_N1_RX_P0,
        .SRDS_N1_RX_P1,
        .SRDS_N1_RX_P2,
        .SRDS_N1_RX_P3,
        .SRDS_N0_TX_N0,
        .SRDS_N0_TX_N1,
        .SRDS_N0_TX_N2,
        .SRDS_N0_TX_N3,
        .SRDS_N0_TX_P0,
        .SRDS_N0_TX_P1,
        .SRDS_N0_TX_P2,
        .SRDS_N0_TX_P3,
        .SRDS_N1_TX_N0,
        .SRDS_N1_TX_N1,
        .SRDS_N1_TX_N2,
        .SRDS_N1_TX_N3,
        .SRDS_N1_TX_P0,
        .SRDS_N1_TX_P1,
        .SRDS_N1_TX_P2,
        .SRDS_N1_TX_P3,

        // Ethernet subsystem 1
        .SRDS_N2_RX_N0,
        .SRDS_N2_RX_N1,
        .SRDS_N2_RX_N2,
        .SRDS_N2_RX_N3,
        .SRDS_N2_RX_P0,
        .SRDS_N2_RX_P1,
        .SRDS_N2_RX_P2,
        .SRDS_N2_RX_P3,
        .SRDS_N3_RX_N0,
        .SRDS_N3_RX_N1,
        .SRDS_N3_RX_N2,
        .SRDS_N3_RX_N3,
        .SRDS_N3_RX_P0,
        .SRDS_N3_RX_P1,
        .SRDS_N3_RX_P2,
        .SRDS_N3_RX_P3,
        .SRDS_N2_TX_N0,
        .SRDS_N2_TX_N1,
        .SRDS_N2_TX_N2,
        .SRDS_N2_TX_N3,
        .SRDS_N2_TX_P0,
        .SRDS_N2_TX_P1,
        .SRDS_N2_TX_P2,
        .SRDS_N2_TX_P3,
        .SRDS_N3_TX_N0,
        .SRDS_N3_TX_N1,
        .SRDS_N3_TX_N2,
        .SRDS_N3_TX_N3,
        .SRDS_N3_TX_P0,
        .SRDS_N3_TX_P1,
        .SRDS_N3_TX_P2,
        .SRDS_N3_TX_P3
    );

    // Initial functions within device simulation model   
    initial begin
        // Ensure correct version of sim package is being used
        // This design requires 8.2 as a minimum
        ac7t1500.require_version(8, 2, 0, 0);
        // Set message verbosity level
        ac7t1500.verbosity = 3;
    end

    // Bind the Ethernet NAPs
    // Eth 0 column[1:0] maps to NOC columns [2:1]
    // Eth 1 column[1:0] maps to NOC columns [5:4]
    // Programmed EIU to assign 400G MAC0, to columns 0 & 1, rows 7-8.
    // This square arrangement of NAPs gives better timing performance on die
`ifndef ACX_USE_ETHERNET1
    `ACX_BIND_NAP_VERTICAL(DUT.gb_nap[0].i_nap_eth_lb.i_nap_vertical,2,7);
    `ACX_BIND_NAP_VERTICAL(DUT.gb_nap[1].i_nap_eth_lb.i_nap_vertical,2,8);
    `ACX_BIND_NAP_VERTICAL(DUT.gb_nap[2].i_nap_eth_lb.i_nap_vertical,1,7);
    `ACX_BIND_NAP_VERTICAL(DUT.gb_nap[3].i_nap_eth_lb.i_nap_vertical,1,8);
`else
    `ACX_BIND_NAP_VERTICAL(DUT.gb_nap[0].i_nap_eth_lb.i_nap_vertical,5,7);
    `ACX_BIND_NAP_VERTICAL(DUT.gb_nap[1].i_nap_eth_lb.i_nap_vertical,5,8);
    `ACX_BIND_NAP_VERTICAL(DUT.gb_nap[2].i_nap_eth_lb.i_nap_vertical,4,7);
    `ACX_BIND_NAP_VERTICAL(DUT.gb_nap[3].i_nap_eth_lb.i_nap_vertical,4,8);
`endif

    // Internal clocks that require particular frequencies
    // Into the subsystems are groups of global clocks.
    // mq0/1_tx/rx_clk[3:0] are driven by glb_clk[0].
    // mq0/1_ref_clk is also driven by glb_clk[0]
    // mq0_ff_tx/rx_clk[3:0] is driven by glb_clk[1]
    // mq1_ff_tx/rx_clk[3:0] is driven by glb_clk[2]
    // For 400G MAC 0, same setup.  ref_clk = glb_clk[0], ff0 = glb_clk[1], ff1 = glb_clk[2]

    // The key clocks that need setting are the ff_clks as they define the MAC clock rate
    // Override the default clock assignments within ac7t1500.
    // As they are already forced, release first to confirm.
    initial
    begin
      #100
      release ac7t1500.fullchip_top.u_enoc_n_top_u0.i_glb_clk1[0];
      release ac7t1500.fullchip_top.u_enoc_n_top_u0.i_glb_clk1[1];
      release ac7t1500.fullchip_top.u_enoc_n_top_u0.i_glb_clk1[2];
      #100
      force ac7t1500.fullchip_top.u_enoc_n_top_u0.i_glb_clk1[0] = ref_clk;
      force ac7t1500.fullchip_top.u_enoc_n_top_u0.i_glb_clk1[1] = mac_clk;
      force ac7t1500.fullchip_top.u_enoc_n_top_u0.i_glb_clk1[2] = mac_clk;
    end


    // -------------------------
    // Configuration
    // -------------------------

    // Call function within chip to configure the registers
    initial
    begin
        #10;    // Allows for verbosity to be set in alternate initial block
        fork
            ac7t1500.fcu.configure( CFG_FILENAME, "ethernet0" );
            ac7t1500.fcu.configure( CFG_FILENAME, "ethernet1" );
        join
    end

    // Loopback all 8 Serdes lanes. This supports the 8x50G, (400G) loopback
    // Ethernet 0
    assign SRDS_N0_RX_P0 = SRDS_N0_TX_P0;
    assign SRDS_N0_RX_N0 = SRDS_N0_TX_N0;
    assign SRDS_N0_RX_P1 = SRDS_N0_TX_P1;
    assign SRDS_N0_RX_N1 = SRDS_N0_TX_N1;
    assign SRDS_N0_RX_P2 = SRDS_N0_TX_P2;
    assign SRDS_N0_RX_N2 = SRDS_N0_TX_N2;
    assign SRDS_N0_RX_P3 = SRDS_N0_TX_P3;
    assign SRDS_N0_RX_N3 = SRDS_N0_TX_N3;
    assign SRDS_N1_RX_P0 = SRDS_N1_TX_P0;
    assign SRDS_N1_RX_N0 = SRDS_N1_TX_N0;
    assign SRDS_N1_RX_P1 = SRDS_N1_TX_P1;
    assign SRDS_N1_RX_N1 = SRDS_N1_TX_N1;
    assign SRDS_N1_RX_P2 = SRDS_N1_TX_P2;
    assign SRDS_N1_RX_N2 = SRDS_N1_TX_N2;
    assign SRDS_N1_RX_P3 = SRDS_N1_TX_P3;
    assign SRDS_N1_RX_N3 = SRDS_N1_TX_N3;

    // Ethernet 1
    assign SRDS_N2_RX_P0 = SRDS_N2_TX_P0;
    assign SRDS_N2_RX_N0 = SRDS_N2_TX_N0;
    assign SRDS_N2_RX_P1 = SRDS_N2_TX_P1;
    assign SRDS_N2_RX_N1 = SRDS_N2_TX_N1;
    assign SRDS_N2_RX_P2 = SRDS_N2_TX_P2;
    assign SRDS_N2_RX_N2 = SRDS_N2_TX_N2;
    assign SRDS_N2_RX_P3 = SRDS_N2_TX_P3;
    assign SRDS_N2_RX_N3 = SRDS_N2_TX_N3;
    assign SRDS_N3_RX_P0 = SRDS_N3_TX_P0;
    assign SRDS_N3_RX_N0 = SRDS_N3_TX_N0;
    assign SRDS_N3_RX_P1 = SRDS_N3_TX_P1;
    assign SRDS_N3_RX_N1 = SRDS_N3_TX_N1;
    assign SRDS_N3_RX_P2 = SRDS_N3_TX_P2;
    assign SRDS_N3_RX_N2 = SRDS_N3_TX_N2;
    assign SRDS_N3_RX_P3 = SRDS_N3_TX_P3;
    assign SRDS_N3_RX_N3 = SRDS_N3_TX_N3;

    // Define device, Serdes clock frequencies, and mac modes
    // Ethernet 0
    `ACX_CONFIG_SERDES_BFM(u_eth_pciex8_sys_top_u0.u_eth_sys_top, u0_serdes_4lane_top, CLOCK_PERIOD_SERDES, SERDES_DATA_WIDTH, 1)
    `ACX_CONFIG_SERDES_BFM(u_eth_pciex8_sys_top_u0.u_eth_sys_top, u1_serdes_4lane_top, CLOCK_PERIOD_SERDES, SERDES_DATA_WIDTH, 1)
    `ACX_CONFIG_MAC_BFM(u_eth_pciex8_sys_top_u0.u_eth_sys_top, 1, 32, 0)

    // Ethernet 1
    `ACX_CONFIG_SERDES_BFM(u_eth_sys_top_u0, u0_serdes_4lane_top, CLOCK_PERIOD_SERDES, SERDES_DATA_WIDTH, 1)
    `ACX_CONFIG_SERDES_BFM(u_eth_sys_top_u0, u1_serdes_4lane_top, CLOCK_PERIOD_SERDES, SERDES_DATA_WIDTH, 1)
    `ACX_CONFIG_MAC_BFM(u_eth_sys_top_u0, 1, 32, 0)

    // -------------------------
    // DUT
    // -------------------------

    // The Ethernet IP signals are not used in the testbench
    // They go direct to the Ethernet subsystem in silicon

    ethernet_8x50g_pkt_mode_top #(
        .NUM_LOOPBACK_PKTS      (NUM_LOOPBACK_PKTS)
    ) DUT (
        // Inputs
        .i_reset_n              (reset_n),
        .i_start                (test_start),

        // Clocks
        .i_eth_clk              (usr_clk),
        .pll_usr_lock           (plls_lock),
        // System PLLs
        .pll_eth_ref_lock       (plls_lock),
        .pll_eth_ff_lock        (plls_lock),
        .pll_noc_lock           (plls_lock),

        // Packet checker outputs
        // Due to issue with ACE 8.2, buses done as individual IO signals
        // This will be resolved in future releases
        .o_pkt_num0             (lb_pkt_num[0]),
        .o_pkt_num1             (lb_pkt_num[1]),
        .o_pkt_num2             (lb_pkt_num[2]),
        .o_pkt_num3             (lb_pkt_num[3]),
        .o_pkt_num4             (lb_pkt_num[4]),
        .o_pkt_num5             (lb_pkt_num[5]),
        .o_pkt_num6             (lb_pkt_num[6]),
        .o_pkt_num7             (lb_pkt_num[7]),
        .o_pkt_num8             (lb_pkt_num[8]),
        .o_pkt_num9             (lb_pkt_num[9]),
        .o_pkt_num10            (lb_pkt_num[10]),
        .o_pkt_num11            (lb_pkt_num[11]),
        .o_pkt_num12            (lb_pkt_num[12]),
        .o_pkt_num13            (lb_pkt_num[13]),
        .o_pkt_num14            (lb_pkt_num[14]),
        .o_pkt_num15            (lb_pkt_num[15]),
        .o_pkt_num16            (lb_pkt_num[16]),
        .o_pkt_num17            (lb_pkt_num[17]),
        .o_pkt_num18            (lb_pkt_num[18]),
        .o_pkt_num19            (lb_pkt_num[19]),
        .o_pkt_num20            (lb_pkt_num[20]),
        .o_pkt_num21            (lb_pkt_num[21]),
        .o_pkt_num22            (lb_pkt_num[22]),
        .o_pkt_num23            (lb_pkt_num[23]),
        .o_pkt_num24            (lb_pkt_num[24]),
        .o_pkt_num25            (lb_pkt_num[25]),
        .o_pkt_num26            (lb_pkt_num[26]),
        .o_pkt_num27            (lb_pkt_num[27]),
        .o_pkt_num28            (lb_pkt_num[28]),
        .o_pkt_num29            (lb_pkt_num[29]),
        .o_pkt_num30            (lb_pkt_num[30]),
        .o_pkt_num31            (lb_pkt_num[31]),
        .o_checksum_error       (lb_checksum_error),
        .o_pkt_size_error       (lb_pkt_size_error),
        .o_payload_error        (lb_payload_error)
        // Will not connect the _oen signals as unused in the testbench.
    );


    // -------------------------
    // Simulation dump signals to file
    // -------------------------
    // Optionally enabled as can slow simulation
`ifdef ACX_DUMP_SIM_SIGNALS
    initial
    begin
    `ifdef VCS
        $vcdplusfile("sim_output_pluson.vpd");  
        $vcdpluson(0,tb_ethernet_ref_design);
        `ifdef SIMSTEP_fullchip_bs
            $vcdpluson(0,tb_ethernet_ref_design.DUT);
        `endif
    `elsif MODEL_TECH   // Defined by QuestaSim
        // WLF filename is set by using the -wlf option to vsim
        // or else in the modelsim.ini file.
        $wlfdumpvars(0, tb_ethernet_ref_design);
        `ifdef SIMSTEP_fullchip_bs
            $wlfdumpvars(0,tb_ethernet_ref_design.DUT);
        `endif
    `endif
    end
`endif

endmodule : tb_ethernet_ref_design

