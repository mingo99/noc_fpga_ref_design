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
// Speedster7t DDR reference design (RD18)
//      Testbench
//      Can use either simple behavioural model of NAP or 
//      fullchip NoC and DDR models
// ------------------------------------------------------------------

// Control whether signal dump vpd files are generated
`define ACX_DUMP_SIM_SIGNALS

`timescale 1 ps / 1 ps


module tb_ddr4_ref_design ();

    // -------------------------
    // Local signals
    // -------------------------
    logic       clk = 0;
    logic       training_clk = 0;
    logic       reset_n;
    logic       chip_ready;
    logic [5:0] count_value;
    logic       count_done;
    logic       test_start;
    logic       test_fail;
    logic       test_fail_d;
    logic       test_timeout;
    logic       test_complete;
    logic       training_rstn;
    logic       training_done;

    // DDR4 model pins
    wire        ALERT_n           ;
    wire        DDR4_S0_BP_UNUSED ;
    wire        VREF              ;
    wire        RESET_n           ;
    wire [71:0] DQ           ;
    wire [17:0] DQS_c        ;
    wire [17:0] DQS_t        ;
    wire [8:0]  DM_n         ;
    wire [8:0]  DM_DBI_UDQS  ;
    wire [17:0] ADDR         ;
    wire [3:0]  CK_c         ;
    wire [3:0]  CK_t         ;
    wire        ACT_n        ;
    wire [1:0]  BA           ;
    wire [1:0]  BG           ;
    wire [3:0]  CS_n         ;
    wire        PARITY       ;
    wire [3:0]  CKE          ;
    wire [3:0]  ODT          ;
    wire [2:0]  C            ;
    wire        TEN          ;
    wire        ZQ           ;

    logic       PWR;

    // -------------------------
    // Clocks
    // -------------------------

    // Define testbench clocks
    localparam DESIGN_CLOCK_PERIOD      = 2000;     // 500MHz NAP and design clock
    localparam TRAINING_CLOCK           = 4000;     // 250MHz clock for DDR4 training block

    always #(DESIGN_CLOCK_PERIOD/2)       clk             <= ~clk;
    always #(TRAINING_CLOCK/2)            training_clk    <= ~training_clk ;
    

    // -------------------------
    // Simulation sequence
    // -------------------------
    
    initial
    begin
        reset_n       <= 1'b0;
        test_start    <= 1'b0;
        training_rstn <= 1'b0;
        #10;    // To prevent false triggering at time 0 when chip_ready is being assigned.

        // Wait for chip to be configured
        while ( chip_ready !== 1'b1 )
            @(posedge clk);

        repeat (10) @(posedge clk); // Board response time to chip asserting ready

        // Training block is always in design.  However in BFM mode it is not used, 
        // so it is held in reset throughout so that it does not perform transactions to the memory
        // When held in reset, force the output to be true.
    `ifdef ACX_DDR4_FULL
        // Start training block (if not using RTL, then training_done is always asserted)
        $display("%t : DDR4 training started", $time);
        training_rstn <= 1'b1;
        while ( training_done !== 1'b1 )
            repeat (10) @(posedge clk);
        $display("%t : DDR4 training complete", $time);
    `else
        repeat (10) @(posedge clk);
        force DUT.train_done = 1'b1;
    `endif
        // Training is now complete, release the design reset
        reset_n <= 1'b1;
        // Start test 50 cycles later
        repeat (50) @(posedge clk);
        test_start <= 1'b1;
    end

    // Timeout to stop the test if required
    initial
        begin
        test_timeout <= 1'b0;
        repeat (60000) @(posedge clk);
`ifndef ACX_SIM_STANDALONE_MODE
    `ifdef ACX_DDR4_FULL
        $display("Extend sim timeout as DDR4 RTL model is being used");
        repeat (1200000) @(posedge clk);
    `endif
`endif
        test_timeout <= 1'b1;
    end

    // After a period, assert finish
    initial
    begin
        #100;
        @(posedge reset_n);
        while (~(test_timeout || test_complete))
        @(posedge clk);

        if ( ~test_complete )
            $error( "%t : Test didn't complete in time", $time );

        if ( test_fail || test_timeout )
            $error( "%t : TEST FAILED", $time );
        else
            $display( "%t : TEST PASSED", $time );

        $finish;
    end


    // ---------------------------------------
    // Direct connect interface signals
    // ---------------------------------------
    logic                         ddr4_1_dc_awvalid;
    logic                         ddr4_1_dc_awready;
    logic [40 -1:0]               ddr4_1_dc_awaddr;
    logic [8 -1:0]                ddr4_1_dc_awlen;
    logic [8 -1:0]                ddr4_1_dc_awid;
    logic [4 -1:0]                ddr4_1_dc_awqos;
    logic [2 -1:0]                ddr4_1_dc_awburst;
    logic                         ddr4_1_dc_awlock;
    logic [3 -1:0]                ddr4_1_dc_awsize;
    logic [4 -1:0]                ddr4_1_dc_awregion;
    logic [4 -1:0]                ddr4_1_dc_awcache;
    logic [3 -1:0]                ddr4_1_dc_awprot;
    logic                         ddr4_1_dc_wvalid;
    logic                         ddr4_1_dc_wready;
    logic [512 -1:0]              ddr4_1_dc_wdata;
    logic [(512/8) -1:0]          ddr4_1_dc_wstrb;
    logic                         ddr4_1_dc_wlast;
    logic                         ddr4_1_dc_arready;
    logic                         ddr4_1_dc_arvalid;
    logic [40 -1:0]               ddr4_1_dc_araddr;
    logic [8 -1:0]                ddr4_1_dc_arlen;
    logic [8 -1:0]                ddr4_1_dc_arid;
    logic [4 -1:0]                ddr4_1_dc_arqos;
    logic [2 -1:0]                ddr4_1_dc_arburst;
    logic                         ddr4_1_dc_arlock;
    logic [3 -1:0]                ddr4_1_dc_arsize;
    logic [4 -1:0]                ddr4_1_dc_arregion;
    logic [4 -1:0]                ddr4_1_dc_arcache;
    logic [3 -1:0]                ddr4_1_dc_arprot;
    logic                         ddr4_1_dc_rready;
    logic                         ddr4_1_dc_rvalid;
    logic [512 -1:0]              ddr4_1_dc_rdata;
    logic                         ddr4_1_dc_rlast;
    logic [2 -1:0]                ddr4_1_dc_rresp;
    logic [8 -1:0]                ddr4_1_dc_rid;
    logic                         ddr4_1_dc_bvalid;
    logic                         ddr4_1_dc_bready;
    logic [2 -1:0]                ddr4_1_dc_bresp;
    logic [8 -1:0]                ddr4_1_dc_bid;

    logic                         ddr4_1_clk;
    logic [1:0]                   ddr4_1_clk_alt;
    logic                         ddr4_1_rstn;

    // Unused DDR DCI ports
    // Need instances so they can connect to the DUT
    logic                         ddr4_1_dc_arex_auto_precharge;
    logic                         ddr4_1_dc_arex_parity;
    logic                         ddr4_1_dc_arex_poison;
    logic                         ddr4_1_dc_arex_urgent;
    logic [64 -1:0]               ddr4_1_dc_rex_parity = 64'b0;    // Input to DUT
    logic                         ddr4_1_dc_awex_auto_precharge;
    logic                         ddr4_1_dc_awex_parity;
    logic                         ddr4_1_dc_awex_poison;
    logic                         ddr4_1_dc_awex_urgent;
    logic [64 -1:0]               ddr4_1_dc_wex_parity;

    logic                         ddr4_1_dc_axi_arpoison_irq;
    logic                         ddr4_1_dc_axi_awpoison_irq;
    logic                         ddr4_1_dfi_alert_err_irq;
    logic                         ddr4_1_ecc_corrected_err_irq;
    logic                         ddr4_1_ecc_corrected_err_irq_fault;
    logic                         ddr4_1_ecc_uncorrected_err_irq;
    logic                         ddr4_1_ecc_uncorrected_err_irq_fault;
    logic                         ddr4_1_noc_axi_arpoison_irq;
    logic                         ddr4_1_noc_axi_awpoison_irq;    
    logic                         ddr4_1_par_raddr_err_irq;
    logic                         ddr4_1_par_raddr_err_irq_fault;
    logic                         ddr4_1_par_rdata_err_irq;
    logic                         ddr4_1_par_rdata_err_irq_fault;
    logic                         ddr4_1_par_waddr_err_irq;
    logic                         ddr4_1_par_waddr_err_irq_fault;
    logic                         ddr4_1_par_wdata_err_irq;
    logic                         ddr4_1_par_wdata_err_irq_fault;
    logic                         ddr4_1_phy_irq_n;


    // ---------------------------------------
    // Two simulation modes supported.
    // Standalone mode has simple model of NOC
    // Fullchip BFM uses real NoC with DDR BFM
    // ---------------------------------------

`ifdef ACX_SIM_STANDALONE_MODE
    // When binding, the module is inside the target module, so gets
    // parameters and signal names from that module - not this module
    bind DUT.i_axi_slave_wrapper_in.i_axi_slave.x_NAP_AXI_SLAVE
        tb_noc_memory_behavioural #(
                                    .INIT_FILE_NAME         (""),
                                    .WRITE_FILE_NAME        (""),
                                    .CHECK_FILE_NAME        (""),
                                    .MEM_TYPE               ("ddr"),
                                    .DST_DATA_WIDTH         (256),
                                    .CHK_ADDR_WIDTH         (19),
                                    .CHK_ADDR_MASK_BITS     (16),
                                    .CHK_DATA_MASK_BITS     (16),
                                    .VERBOSITY              (3)
                                    ) i_noc_memory (
                                                    // Inputs
                                                    .i_clk                  (clk),      // This signal refers to the clk input on the NAP_AXI_SLAVE
                                                    .i_reset_n              (rstn),     // This signal refers to the rstn input on the NAP_AXI_SLAVE
                                                    .i_write_result         (1'b0)
                                                    );

    // Drive the chip ready signal to start the testbench
    initial
    begin
        chip_ready = 1'b0;
        #100000;
        chip_ready = 1'b1;
    end

    // In standalone mode require clock and reset into the DCI ports so that the packet generator
    // and checkers correctly reset
    // In fullchip simulation mode, these clocks are provided by the DDR4 subsystem.
    localparam STANDALONE_DCI_CLOCK_PERIOD = 2500;     // 400MHz DCI interface clock

    logic   standalone_dci_clk = 0;
    always #(STANDALONE_DCI_CLOCK_PERIOD/2)  standalone_dci_clk <= ~standalone_dci_clk;

    assign ddr4_1_clk          = standalone_dci_clk;
    assign ddr4_1_clk_alt[0]   = ddr4_1_clk;
    assign ddr4_1_clk_alt[1]   = ddr4_1_clk;
    assign ddr4_1_rstn         = reset_n;

`else // FULLCHIP_BFM mode

    // Include the utility file which defines the macros
    `include "ac7t1500_utils.svh"   

    // ------------------------------------------
    // Instantiate target device simulation model
    // ------------------------------------------
    ac7t1500 ac7t1500( 
            .FCU_CONFIG_USER_MODE   (chip_ready)
        `ifdef ACX_DDR4_FULL
            ,.DDR4_S0_BP_ZN_SENSE   ()
            ,.DDR4_S0_BP_ZN         (ZQ)
            ,.DDR4_S0_DQ            (DQ[71:0])
            ,.DDR4_S0_UDQS_N        (DQS_c[17:9])
            ,.DDR4_S0_LDQS_N        (DQS_c[8:0])
            ,.DDR4_S0_LDQS_P        (DQS_t[8:0])
            ,.DDR4_S0_DM_DBI_UDQS_P (DM_DBI_UDQS[8:0])
            ,.DDR4_S0_A             (ADDR[13:0])
            ,.DDR4_S0_A17           (ADDR[17])
            ,.DDR4_S0_ACT_N         (ACT_n)
            ,.DDR4_S0_BA            (BA[1:0])
            ,.DDR4_S0_BG            (BG[1:0])
            ,.DDR4_S0_CID           (C)
            ,.DDR4_S0_CS_N          (CS_n)
            ,.DDR4_S0_CKE           (CKE)
            ,.DDR4_S0_CK_N          (CK_c)
            ,.DDR4_S0_CK_P          (CK_t)
            ,.DDR4_S0_ODT           (ODT)
            ,.DDR4_S0_PAR           (PARITY)
            ,.DDR4_S0_RAS_N         (ADDR[16])
            ,.DDR4_S0_CAS_N         (ADDR[15])
            ,.DDR4_S0_WE_N          (ADDR[14])
            ,.DDR4_S0_BP_UNUSED     (DDR4_S0_BP_UNUSED)
            ,.DDR4_S0_BP_ALERT_N    (ALERT_n)
            ,.DDR4_S0_BP_VREF       (VREF)
            ,.DDR4_S0_BP_MEMRESET_L (RESET_n)
        `endif
        );


    // For the target device, set the verbosity options on the messages
    initial begin
        ac7t1500.set_verbosity(3);
        // Ensure correct version of sim package is being used
        // This design requires 8.2.update2 as a minimum
        ac7t1500.require_version(8, 2, 0, 2);
    end

    // Set target device internal clocks for DDR controller core
    initial
    begin
        localparam DDR4_CONTROLLER_CLOCK_PERIOD =  1250 ;
        ac7t1500.clocks.global_clk_sw.set_global_clocks('{32{(DDR4_CONTROLLER_CLOCK_PERIOD/2)}}) ;
    end

    // Set target device, DDR interface clocks
    initial begin
        // Set DDR interface clock frequency
        // DDR Data Rate can be 3200, 2666, 2400Mbps
        // For Data Rate 3200Mbps, the interface clock period below needs to be 800MHz
        // For Data Rate 2666Mbps and 2400Mbps, the interface clock period needs to
        // be fast enough to support the data rate chosen.
        // Note : The NoC clock is an internal NoC clock, it is not the frequency that the user
        //        design NoC has to operate at.
        // As the direct connect interface, (DCI), is twice as wide, it operates at half the frequency.

        localparam DDR4_INTERFACE_CLOCK_PERIOD = 1250; // 800MHz

        ac7t1500.clocks.set_clock_period("ddr4_noc0_clk", DDR4_INTERFACE_CLOCK_PERIOD);
        ac7t1500.clocks.set_clock_period("ddr4_dc0_clk",  DDR4_INTERFACE_CLOCK_PERIOD*2);
    end

    // Bind the user design NAP to a location in the target device NoC
    `ACX_BIND_NAP_AXI_SLAVE(DUT.i_axi_slave_wrapper_in.i_axi_slave,3,2);

    // The training and polling block does control via a NAP
    `ACX_BIND_NAP_AXI_SLAVE(DUT.i_ddr4_training_block.i_axi_nap_csr_master.i_axi_slave_wrapper_cfg.i_axi_slave,4,4);
        
    // Direct connect AXI interface to DDR controller
    // DCI is bound to interface ac7t1500.ddr4_dc0()
    assign ac7t1500.interfaces.ddr4_dc0.awvalid  = ddr4_1_dc_awvalid;
    assign ac7t1500.interfaces.ddr4_dc0.awaddr   = ddr4_1_dc_awaddr;
    assign ac7t1500.interfaces.ddr4_dc0.awlen    = ddr4_1_dc_awlen;
    assign ac7t1500.interfaces.ddr4_dc0.awid     = ddr4_1_dc_awid;
    assign ac7t1500.interfaces.ddr4_dc0.awqos    = ddr4_1_dc_awqos;
    assign ac7t1500.interfaces.ddr4_dc0.awburst  = ddr4_1_dc_awburst;
    assign ac7t1500.interfaces.ddr4_dc0.awlock   = ddr4_1_dc_awlock;
    assign ac7t1500.interfaces.ddr4_dc0.awsize   = ddr4_1_dc_awsize;
    assign ac7t1500.interfaces.ddr4_dc0.awregion = ddr4_1_dc_awregion;
    assign ac7t1500.interfaces.ddr4_dc0.wvalid   = ddr4_1_dc_wvalid;
    assign ac7t1500.interfaces.ddr4_dc0.wdata    = ddr4_1_dc_wdata;
    assign ac7t1500.interfaces.ddr4_dc0.wstrb    = ddr4_1_dc_wstrb;
    assign ac7t1500.interfaces.ddr4_dc0.wlast    = ddr4_1_dc_wlast;
    assign ac7t1500.interfaces.ddr4_dc0.arvalid  = ddr4_1_dc_arvalid;
    assign ac7t1500.interfaces.ddr4_dc0.araddr   = ddr4_1_dc_araddr;
    assign ac7t1500.interfaces.ddr4_dc0.arlen    = ddr4_1_dc_arlen;
    assign ac7t1500.interfaces.ddr4_dc0.arid     = ddr4_1_dc_arid;
    assign ac7t1500.interfaces.ddr4_dc0.arqos    = ddr4_1_dc_arqos;
    assign ac7t1500.interfaces.ddr4_dc0.arburst  = ddr4_1_dc_arburst;
    assign ac7t1500.interfaces.ddr4_dc0.arlock   = ddr4_1_dc_arlock;
    assign ac7t1500.interfaces.ddr4_dc0.arsize   = ddr4_1_dc_arsize;
    assign ac7t1500.interfaces.ddr4_dc0.arregion = ddr4_1_dc_arregion;
    assign ac7t1500.interfaces.ddr4_dc0.rready   = ddr4_1_dc_rready;
    assign ac7t1500.interfaces.ddr4_dc0.bready   = ddr4_1_dc_bready;
    assign ddr4_1_dc_awready = ac7t1500.interfaces.ddr4_dc0.awready;
    assign ddr4_1_dc_wready  = ac7t1500.interfaces.ddr4_dc0.wready;
    assign ddr4_1_dc_arready = ac7t1500.interfaces.ddr4_dc0.arready;
    assign ddr4_1_dc_rvalid  = ac7t1500.interfaces.ddr4_dc0.rvalid;
    assign ddr4_1_dc_rdata   = ac7t1500.interfaces.ddr4_dc0.rdata;
    assign ddr4_1_dc_rlast   = ac7t1500.interfaces.ddr4_dc0.rlast;
    assign ddr4_1_dc_rresp   = ac7t1500.interfaces.ddr4_dc0.rresp;
    assign ddr4_1_dc_rid     = ac7t1500.interfaces.ddr4_dc0.rid;
    assign ddr4_1_dc_bvalid  = ac7t1500.interfaces.ddr4_dc0.bvalid;
    assign ddr4_1_dc_bresp   = ac7t1500.interfaces.ddr4_dc0.bresp;
    assign ddr4_1_dc_bid     = ac7t1500.interfaces.ddr4_dc0.bid;
    assign ddr4_1_clk        = ac7t1500.interfaces.ddr4_dc0.clk;
    // From testbench rather than from output of embedded interface
    assign ddr4_1_rstn       = reset_n;


    `ifdef ACX_DDR4_FULL               
        // FULLCHIP_RTL mode
        // In this mode the full DDR4 controller RTL is used, along with DDR4 memory models to give a
        // cycle accurate simulation.

        // Configure DDR4 controller
        // In silicon this function is performed by the bitstream.
        localparam DDR4_CFG_FILENAME  = "../ddr4_memc_config.txt" ;
        initial
        begin
            #10 // Allow verbosity to be set in different initial block
            // Current configuration support only DDR4 3200Mbps rate //
            `ifdef ACX_DDR4_3200
                ac7t1500.fcu.configure (DDR4_CFG_FILENAME, "ddr4");  
            `endif
        end
        
       `ifdef DDR4_X4         // For future DDR X4 support
          assign DM_DBI_UDQS = DQS_t[17:9];
       `else                  // Currently supporting only DDR4 X8 mode
          assign DM_DBI_UDQS = DM_n[8:0];
       `endif

       
        // -------------------------------
        // Connect DDR4 memory models
        // -------------------------------

        wire  [7:0] NC1_net      ;
        wire        NC_DQS_c_net ;
        wire        NC_DQS_t_net ;
        wire        NC_DM_n_net  ;

        genvar      k;
        `ifdef ACX_USE_MICRON_MODEL

           import arch_package::*;
           import proj_package::*;
           ddr4_module_if idimm();
           wire        model_enable ;
           assign model_enable = 1'b1 ;


        `ifdef DDR4_2G
            parameter UTYPE_density CONFIGURED_DENSITY = _2G ;
        `endif

        `ifdef DDR4_8G
            parameter UTYPE_density CONFIGURED_DENSITY = _8G ;
        `endif

           DDR4_if #(.CONFIGURED_DQ_BITS(8)) iDDR4();

           assign iDDR4.CK[1] = idimm.CK[1];
           `ifdef DDR4_X4    // For Future DDR X4 support //
              generate
                  for(k=0;k<9;k=k+1)
                  begin: gen_dqs_x4_0_8
                      tran(idimm.DQS_t[k], DQS_t[k]);
                      tran(idimm.DQS_c[k], DQS_c[k]);
                  end

                  for(k=9;k<18;k=k+1)
                  begin: gen_dqs_t_x4_9_17
                      tran(idimm.DQS_t[k], DM_DBI_UDQS[k]);
                      tran(idimm.DQS_c[k], DQS_c[k]);
                  end
              endgenerate
           `else          // Currently supporting only X8 mode //
              generate
                   for(k=0;k<8;k=k+1)
                   begin: gen_dq_0_7
                       tran(idimm.u0_r0.DQ[k], DQ[k]);
                       tran(idimm.u1_r0.DQ[k], DQ[k+8]);
                       tran(idimm.u2_r0.DQ[k], DQ[k+16]);
                       tran(idimm.u3_r0.DQ[k], DQ[k+24]);
                       tran(idimm.u4_r0.DQ[k], DQ[k+32]);
                       tran(idimm.u5_r0.DQ[k], DQ[k+40]);
                       tran(idimm.u6_r0.DQ[k], DQ[k+48]);
                       tran(idimm.u7_r0.DQ[k], DQ[k+56]);
                       `ifdef ECC
                          tran(idimm.u8_r0.DQ[k], DQ[k+64]);
                       `endif
                   end
              endgenerate
              tran(idimm.u0_r0.DM_n,  DM_DBI_UDQS[0]);
              tran(idimm.u0_r0.DQS_c, DQS_c[0]);
              tran(idimm.u0_r0.DQS_t, DQS_t[0]);

              tran(idimm.u1_r0.DM_n,  DM_DBI_UDQS[1]);
              tran(idimm.u1_r0.DQS_c, DQS_c[1]);
              tran(idimm.u1_r0.DQS_t, DQS_t[1]);

              tran(idimm.u2_r0.DM_n,  DM_DBI_UDQS[2]);
              tran(idimm.u2_r0.DQS_c, DQS_c[2]);
              tran(idimm.u2_r0.DQS_t, DQS_t[2]);

              tran(idimm.u3_r0.DM_n,  DM_DBI_UDQS[3]);
              tran(idimm.u3_r0.DQS_c, DQS_c[3]);
              tran(idimm.u3_r0.DQS_t, DQS_t[3]);

              tran(idimm.u4_r0.DM_n,  DM_DBI_UDQS[4]);
              tran(idimm.u4_r0.DQS_c, DQS_c[4]);
              tran(idimm.u4_r0.DQS_t, DQS_t[4]);

              tran(idimm.u5_r0.DM_n,  DM_DBI_UDQS[5]);
              tran(idimm.u5_r0.DQS_c, DQS_c[5]);
              tran(idimm.u5_r0.DQS_t, DQS_t[5]);

              tran(idimm.u6_r0.DM_n,  DM_DBI_UDQS[6]);
              tran(idimm.u6_r0.DQS_c, DQS_c[6]);
              tran(idimm.u6_r0.DQS_t, DQS_t[6]);

              tran(idimm.u7_r0.DM_n,  DM_DBI_UDQS[7]);
              tran(idimm.u7_r0.DQS_c, DQS_c[7]);
              tran(idimm.u7_r0.DQS_t, DQS_t[7]);

              `ifdef ECC
                tran(idimm.u8_r0.DM_n, DM_DBI_UDQS[8]);
                tran(idimm.u8_r0.DQS_c, DQS_c[8]);
                tran(idimm.u8_r0.DQS_t, DQS_t[8]);
              `endif //  `ifdef ECC
           `endif
           assign idimm.CK[0] = CK_c[0];
           assign idimm.CK[1] = CK_t[0];

           assign idimm.ACT_n = ACT_n;
           assign idimm.RAS_n_A16 = ADDR[16];
           assign idimm.CAS_n_A15 = ADDR[15];
           assign idimm.WE_n_A14 = ADDR[14];
           assign ALERT_n = idimm.ALERT_n;
           assign idimm.PARITY = PARITY;
           assign idimm.RESET_n = RESET_n;
           assign idimm.TEN = TEN;
           assign idimm.CS_n = CS_n[1:0];
           assign idimm.CKE = CKE[0];
           assign idimm.ODT = ODT[0];
           assign idimm.C = C;
           assign idimm.BG = BG;
           assign idimm.BA = BA;
           assign idimm.ADDR = ADDR[13:0];
           assign idimm.ADDR_17 = ADDR[17];
           assign idimm.ZQ = ZQ;
           assign idimm.PWR = PWR;
           assign idimm.VREF_CA = VREF;
           assign idimm.VREF_DQ = VREF;

           ddr4_model #(.CONFIGURED_DQ_BITS(8), .CONFIGURED_DENSITY(CONFIGURED_DENSITY), .CONFIGURED_RANKS(1))
                u0_r0 (.model_enable(model_enable), .iDDR4(idimm.u0_r0));
           ddr4_model #(.CONFIGURED_DQ_BITS(8), .CONFIGURED_DENSITY(CONFIGURED_DENSITY), .CONFIGURED_RANKS(1))
                u1_r0 (.model_enable(model_enable), .iDDR4(idimm.u1_r0));
           ddr4_model #(.CONFIGURED_DQ_BITS(8), .CONFIGURED_DENSITY(CONFIGURED_DENSITY), .CONFIGURED_RANKS(1))
                u2_r0 (.model_enable(model_enable), .iDDR4(idimm.u2_r0));
           ddr4_model #(.CONFIGURED_DQ_BITS(8), .CONFIGURED_DENSITY(CONFIGURED_DENSITY), .CONFIGURED_RANKS(1))
                u3_r0 (.model_enable(model_enable), .iDDR4(idimm.u3_r0));
           ddr4_model #(.CONFIGURED_DQ_BITS(8), .CONFIGURED_DENSITY(CONFIGURED_DENSITY), .CONFIGURED_RANKS(1))
                u4_r0 (.model_enable(model_enable), .iDDR4(idimm.u4_r0));
           ddr4_model #(.CONFIGURED_DQ_BITS(8), .CONFIGURED_DENSITY(CONFIGURED_DENSITY), .CONFIGURED_RANKS(1))
                u5_r0 (.model_enable(model_enable), .iDDR4(idimm.u5_r0));
           ddr4_model #(.CONFIGURED_DQ_BITS(8), .CONFIGURED_DENSITY(CONFIGURED_DENSITY), .CONFIGURED_RANKS(1))
                u6_r0 (.model_enable(model_enable), .iDDR4(idimm.u6_r0));
           ddr4_model #(.CONFIGURED_DQ_BITS(8), .CONFIGURED_DENSITY(CONFIGURED_DENSITY), .CONFIGURED_RANKS(1))
                u7_r0 (.model_enable(model_enable), .iDDR4(idimm.u7_r0));
           `endif //  `ifdef ACX_USE_MICRON_MODEL

           `ifdef ACX_USE_HYNIX_MODEL

                `ifdef DDR4_8Gx8
                    `define NUM_OF_DRAMS 8
                `endif
                wire [7:0] DQS_t_mem;
                wire [7:0] DQS_c_mem;

                generate
                    for(k=0;k<`NUM_OF_DRAMS;k=k+1)
                    begin : gb_hynx

                        assign (weak0,weak1) #(0)  DQS_t = DQS_t_mem;
                        assign (weak0,weak1) #(150) DQS_t_mem = DQS_t;

                        assign (weak0,weak1) #(0)  DQS_c = DQS_c_mem;
                        assign (weak0,weak1) #(150) DQS_c_mem = DQS_c;

                        DDR4
                          #(
                            .tDQSCK (169),
                            .DLY    (10)
                            )
                          U_HYNIX_DDR4
                          (
                           .CLK     (CK_t[0]),
                           .CLKB    (CK_c[0]),
                           .CKE     (CKE[0]),
                           .ACTB    (ACT_n),
                           .CSB     (CS_n[0]),
                           .RASB    (ADDR[16]),
                           .CASB    (ADDR[15]),
                           .WEB     (ADDR[14]),
                           .BG      (BG),
                           .BA      (BA),
                           .ADDR    (ADDR[13:0]),
                           .DQS     (DQS_t_mem[k]),
                           .DQSB    (DQS_c_mem[k]),
                           .DQ      (DQ[((k+1)*8)-1:(k*8)]),
                           .ODT     (ODT[0]),
                           .DMB     (DM_DBI_UDQS[k]),
                           .RESETB  (RESET_n),
                           .PAR     (PARITY),
                           .ALERTB  (ALERT_n),
                           .TEN     (TEN)
                           );
                    end // for (k=0;k<`NUM_OF_DRAMS;k=k+1)
                endgenerate

           `endif //  `ifdef ACX_USE_HYNIX_MODEL

        assign TEN = 1'b0;
        assign PWR = 1'b1;

        // -------------------------------
        // -------------------------------
    `endif  // ACX_DDR4_FULL


`endif // FULLCHIP_BFM/RTL mode

    // -------------------------
    // DUT
    // -------------------------

    // PLL signals coming from IO ring
    logic   pll_1_lock;
    logic   pll_2_lock;
    assign  pll_1_lock = reset_n;
    assign  pll_2_lock = reset_n;

    ddr4_ref_design_top #(
                          .DDR4_ADDR_ID                 (2'b01),
                          .NUM_TRANSACTIONS             (256)           // Set to 0 for continuous
                          ) DUT (
                                 // Inputs
                                 .i_clk                 (clk),
                                 .i_training_clk        (training_clk),
                                 .i_training_rstn       (training_rstn),
                                 .i_reset_n             (reset_n),
                                 .i_start               (test_start),

                                 // Connect the DCI port
                                 .*,

                                 // Outputs
                                 .o_xact_done            (test_complete),
                                 .o_fail                 (test_fail),
                                 .o_training_done        (training_done),
                                 .o_fail_oe              (),
                                 .o_xact_done_oe         (),
                                 .o_training_done_oe     ()
                                 );

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

    // -------------------------------
    // Simulation dump signals to file
    // -------------------------------
    // Optionally enabled as can slow simulation
`ifdef ACX_DUMP_SIM_SIGNALS
    initial
    begin
    `ifdef VCS
        $vcdplusfile("sim_output_pluson.vpd");
        $vcdpluson(0,tb_ddr4_ref_design);
        `ifdef SIMSTEP_fullchip_bs
        $vcdpluson(0,`TB_TESTNAME.DUT);
        `endif
    `elsif MODEL_TECH   // Defined by QuestaSim
        // WLF filename is set by using the -wlf option to vsim
        // or else in the modelsim.ini file.
        $wlfdumpvars(0, tb_ddr4_ref_design);
        `ifdef SIMSTEP_fullchip_bs
        $wlfdumpvars(0,`TB_TESTNAME.DUT);
        `endif
    `endif
    end
`endif //  `ifdef ACX_DUMP_SIM_SIGNALS

    // -------------------------------------
    // Display regular simulation heartbeats
    // -------------------------------------
    initial
    begin
        forever
        begin
            #100us;
            $display("%t : Current simulation time", $time);
        end // forever begin
    end

endmodule : tb_ddr4_ref_design
