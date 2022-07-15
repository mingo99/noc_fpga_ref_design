module pcie_rtl_testcase (

  input pciex8_bfm_test_done,
  input pciex16_bfm_test_done,
  output logic pciex8_rtl_test_done,
  output logic pciex16_rtl_test_done
);

`ifdef ACX_PCIE_0_FULL
  `define ACX_PCIE_FULL
`endif
`ifdef ACX_PCIE_1_FULL
  `define ACX_PCIE_FULL
`endif

`ifdef ACX_PCIE_FULL

parameter DISPLAY_NAME = "TEST.";

`define PCIESVC_FLAT_INCLUDES 1

`include "svc_loader_util.svi"
`include "svc_util_parms.v"
`include "svc_util_macros.v"
`include "svt_svc_util_tasks.sv"
`include "svc_plusarg_tasks.v"
`include "pciesvc_application_parms.v"
`include "pciesvc_ll_parms.v"
`include "pciesvc_ll_msgcodes.v"
`include "pciesvc_phylayer_msgcodes.v"
`include "pciesvc_parms.v"
`include "pciesvc_tlp_parms.v"
`include "pciesvc_tlp_tasks.v"
`include "pcie_rtl_tasks.sv"
`include "pciesvc_appl_msgcodes.v"


reg     done;
integer status;
integer tmp_status;
int i, addr_count;
logic [63:0] target_addr [17:0];
  int                         addr_count_pcie_x8;
  int                         reg_addr_count_pcie_x8;
  int                         addr_count_pcie_x16;
  int                         reg_addr_count_pcie_x16;
  int                         num_DWs;
logic [31:0] irq_data;
logic [31:0] original_cnt_val;
logic [31:0] new_cnt_val;


   //================================================================================
   // Define FPGA Address Space
   //================================================================================
   localparam ACX_FPGA_GDDR6_0A_BASE = {27'h0, 4'h0, 33'h0};
   localparam ACX_FPGA_GDDR6_0B_BASE = {27'h0, 4'h1, 33'h0};
   localparam ACX_FPGA_GDDR6_1A_BASE = {27'h0, 4'h2, 33'h0};
   localparam ACX_FPGA_GDDR6_1B_BASE = {27'h0, 4'h3, 33'h0};
   localparam ACX_FPGA_GDDR6_2A_BASE = {27'h0, 4'h4, 33'h0};
   localparam ACX_FPGA_GDDR6_2B_BASE = {27'h0, 4'h5, 33'h0};
   localparam ACX_FPGA_GDDR6_3A_BASE = {27'h0, 4'h6, 33'h0};
   localparam ACX_FPGA_GDDR6_3B_BASE = {27'h0, 4'h7, 33'h0};
   localparam ACX_FPGA_GDDR6_4A_BASE = {27'h0, 4'h8, 33'h0};
   localparam ACX_FPGA_GDDR6_4B_BASE = {27'h0, 4'h9, 33'h0};
   localparam ACX_FPGA_GDDR6_5A_BASE = {27'h0, 4'hA, 33'h0};
   localparam ACX_FPGA_GDDR6_5B_BASE = {27'h0, 4'hB, 33'h0};
   localparam ACX_FPGA_GDDR6_6A_BASE = {27'h0, 4'hC, 33'h0};
   localparam ACX_FPGA_GDDR6_6B_BASE = {27'h0, 4'hD, 33'h0};
   localparam ACX_FPGA_GDDR6_7A_BASE = {27'h0, 4'hE, 33'h0};
   localparam ACX_FPGA_GDDR6_7B_BASE = {27'h0, 4'hF, 33'h0};

   localparam ACX_FPGA_DDR4_BASE = {24'h000001, 40'h0};

   localparam ACX_FPGA_NAP_BASE = {28'h0000004,36'h0};

   localparam ACX_BRAM1_NAP_COL = 2;
   localparam ACX_BRAM1_NAP_ROW = 4;

   localparam ACX_BRAM2_NAP_COL = 6;
   localparam ACX_BRAM2_NAP_ROW = 5;

   localparam ACX_REG1_NAP_COL = 0;
   localparam ACX_REG1_NAP_ROW = 6;

   localparam ACX_REG2_NAP_COL = 4;
   localparam ACX_REG2_NAP_ROW = 1;

   localparam REG_CNT_0_ADDR = 16;
   localparam REG_CNT_CFG_0_ADDR = 17;
   localparam REG_CNT_1_ADDR = 18;
   localparam REG_CNT_CFG_1_ADDR = 19;

   localparam REG_IRQ_0_ADDR = 20;
   localparam REG_IRQ_CFG_0_ADDR = 21;
   localparam REG_IRQ_MASTER_ADDR = 22;

   localparam REG_CLEAR_ON_RD_ADDR = 23;

pciesvc_toolbox toolbox0();
defparam toolbox0.DISPLAY_NAME = {DISPLAY_NAME,"toolbox0."};

//-----------------------------------------------------------
// Define test parameters here
//-----------------------------------------------------------

localparam MEM_ACCESS_TRAFFIC_CLASS = 0;



initial 
  begin: L_Init //{

    reg[256*8-1:0] msglog_transaction_file;
    pciesvc_device_serdes_x16_model_config model_cfg;

    $msglog_suppress("tb_pcie_ref_design.root_x8.target_appl0",  MSGCODE_PCIESVC_APPL_TARGET_UNINITIALIZED_MEM_DATA, 0, 0);
    $msglog_suppress("tb_pcie_ref_design.root_x16.target_appl0", MSGCODE_PCIESVC_APPL_TARGET_UNINITIALIZED_MEM_DATA, 0, 0);
    $msglog_suppress("tb_pcie_ref_design.root_x8.port0.pl0",     MSGCODE_PCIESVC_PHY_WRONG_LINK_WIDTH, 0, 0);



    $msglog(LOG_INFO, "%sInit: TEST_INFO Running serial_serdes_mode_test",DISPLAY_NAME);
    model_cfg = new("pciesvc_device_serdes_x16_model_cfg");
    model_cfg.randomize();

   // Identify log file name
    if (model_cfg.msglog_transaction_file != "") 
      begin
        $msglog(LOG_INFO, "%sInit: Setting the transaction logfile=%s", DISPLAY_NAME, model_cfg.msglog_transaction_file);
        $cast(msglog_transaction_file,model_cfg.msglog_transaction_file);
        $msglog_control(MSGLOG_CONTROL_SET_TRANSACTION_LOG_FILE, 0, msglog_transaction_file);
      end
    else $msglog(LOG_INFO, "%sInit: Using the default transaction (empty) logfile", DISPLAY_NAME);

   // Setting the base address of targets
   target_addr[0] = ACX_FPGA_GDDR6_0A_BASE;
   target_addr[1] = ACX_FPGA_GDDR6_0B_BASE;
   target_addr[2] = ACX_FPGA_GDDR6_1A_BASE;
   target_addr[3] = ACX_FPGA_GDDR6_1B_BASE;
   target_addr[4] = ACX_FPGA_GDDR6_2A_BASE;
   target_addr[5] = ACX_FPGA_GDDR6_2B_BASE;
   target_addr[6] = ACX_FPGA_GDDR6_3A_BASE;
   target_addr[7] = ACX_FPGA_GDDR6_3B_BASE;
   target_addr[8] = ACX_FPGA_GDDR6_4A_BASE;
   target_addr[9] = ACX_FPGA_GDDR6_4B_BASE;
   target_addr[10] = ACX_FPGA_GDDR6_5A_BASE;
   target_addr[11] = ACX_FPGA_GDDR6_5B_BASE;
   target_addr[12] = ACX_FPGA_GDDR6_6A_BASE;
   target_addr[13] = ACX_FPGA_GDDR6_6B_BASE;
   target_addr[14] = ACX_FPGA_GDDR6_7A_BASE;
   target_addr[15] = ACX_FPGA_GDDR6_7B_BASE;

   target_addr[16] = ACX_FPGA_DDR4_BASE;

   target_addr[17] = ACX_FPGA_NAP_BASE;


   pciex8_rtl_test_done = 0;
   pciex16_rtl_test_done = 0;

   fork
`ifdef ACX_PCIE_0_FULL //{ /*LinkupInitialization sequence */  
    DoInitLinkUpRcEp0(model_cfg);
`endif //}

`ifdef ACX_PCIE_1_FULL //{ /*LinkupInitialization sequence */  
    DoInitLinkUpRcEp1(model_cfg);
`endif //}
   join

`ifdef ACX_PCIE_0_FULL //{

   `ifndef ACX_PCIE_1_FULL //PCIex16 is BFM, then wait for x16 BFM test to complete
      while (!pciex16_bfm_test_done);
   `endif


//-----------------------------------------------------------------------------------------------------------------------
    // Start to write/read/check data
//-----------------------------------------------------------------------------------------------------------------------

     for (num_DWs=16; num_DWs <= 128; num_DWs=num_DWs+16) begin
       for (addr_count= 0;  addr_count<17; addr_count++) begin
         MemRandWrRdComp0(target_addr[addr_count],
                         num_DWs,
                         MEM_ACCESS_TRAFFIC_CLASS);
       end
     end


     $display ($time, ": Start pciex8 RTL access to bram1");
     for (num_DWs=16; num_DWs <= (16*4); num_DWs=num_DWs+16) begin
       NAPRandWrRdComp0(target_addr[17],
                       ACX_BRAM1_NAP_COL,
                       ACX_BRAM1_NAP_ROW,
                       num_DWs,
                       MEM_ACCESS_TRAFFIC_CLASS);
     end

      //----------------------------------
      // Now read/write to register set
      // using PCIex8
      //----------------------------------


      // -----------------------------------
      // loop through read/write registers
      // These are 8 32-bit registers
      // -----------------------------------

      $display ("-------------------------------");
      $display ($time, ": PCIex8 Writing and Reading the eight 32-bit Registers");
      $display ("-------------------------------");


      for(reg_addr_count_pcie_x8= 0; reg_addr_count_pcie_x8<8; reg_addr_count_pcie_x8++) begin
        NAPRandWrRdCompDW0((target_addr[17] + reg_addr_count_pcie_x8*64),
                                  ACX_REG1_NAP_COL,
                                  ACX_REG1_NAP_ROW,
                                  MEM_ACCESS_TRAFFIC_CLASS);
      end // for (addr_count_pcie_x8= 0;  addr_count_pcie_x8<8; addr_count_pcie_x8++)

      // -----------------------------------
      // loop through read-only registers
      // These are 8 32-bit registers
      // Excpected value is addr + bias
      // In this case, Addr + 0
      // -----------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Reading the 8 read-only Registers");
      $display ("-------------------------------");

      for(reg_addr_count_pcie_x8= 8; reg_addr_count_pcie_x8<16; reg_addr_count_pcie_x8++) begin
        NAPRdCompDW0((target_addr[17] + reg_addr_count_pcie_x8*64),
                    ACX_REG1_NAP_COL,
                    ACX_REG1_NAP_ROW,
                    MEM_ACCESS_TRAFFIC_CLASS,
                    reg_addr_count_pcie_x8*64);
      end
      // -----------------------------------
      // loop through read/write registers
      // These are 4 64-bit registers
      // -----------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Writing and Reading the four 64-bit Registers");
      $display ("-------------------------------");

      for(reg_addr_count_pcie_x8= 24; reg_addr_count_pcie_x8<28; reg_addr_count_pcie_x8++) begin
        NAPRandWrRdComp0((target_addr[17] + reg_addr_count_pcie_x8*64),
                                  ACX_REG1_NAP_COL,
                                  ACX_REG1_NAP_ROW,
                                  2,
                                  MEM_ACCESS_TRAFFIC_CLASS);
      end // for (addr_count_pcie_x8= 24;  addr_count_pcie_x8<28; addr_count_pcie_x8++)


      //-------------------------------------
      // read on clear register
      // first write to set the value
      // then read it back
      // on second read it should be all 0s
      //-------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Writing and Reading the clear-on-read register");
      $display ("-------------------------------");

      reg_addr_count_pcie_x8 = REG_CLEAR_ON_RD_ADDR;

      NAPRandWrRdCompDW0((target_addr[17] + reg_addr_count_pcie_x8*64),
                        ACX_REG1_NAP_COL,
                        ACX_REG1_NAP_ROW,
                        MEM_ACCESS_TRAFFIC_CLASS);

      NAPRdCompDW0((target_addr[17] + reg_addr_count_pcie_x8*64),
                  ACX_REG1_NAP_COL,
                  ACX_REG1_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  0);

      //-------------------------------------
      // IRQ register
      // first write to set the value
      // then read it back
      // and read the master register
      // then clear the IRQ, read master register
      // to make sure it's 0
      //-------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Writing and Reading the IRQ register");
      $display ("-------------------------------");

      irq_data = $random   ;// 32-bit random data

      reg_addr_count_pcie_x8 = REG_IRQ_0_ADDR;
      NAPWrDW0((target_addr[17] + reg_addr_count_pcie_x8*64),
                  ACX_REG1_NAP_COL,
                  ACX_REG1_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  irq_data);

      // check that the Master IRQ register is set to 1
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Check the master IRQ register is set to 1");
      $display ("-------------------------------");
      reg_addr_count_pcie_x8 = REG_IRQ_MASTER_ADDR;
      NAPRdCompDW0((target_addr[17] + reg_addr_count_pcie_x8*64),
                  ACX_REG1_NAP_COL,
                  ACX_REG1_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  1);

      // Now clear the IRQ register
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Clear the IRQ register");
      $display ("-------------------------------");
      reg_addr_count_pcie_x8 = REG_IRQ_CFG_0_ADDR;
      NAPWrDW0((target_addr[17] + reg_addr_count_pcie_x8*64),
                  ACX_REG1_NAP_COL,
                  ACX_REG1_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  irq_data);

      // read the IRQ register and make sure it's been cleared
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Check the IRQ register has cleared");
      $display ("-------------------------------");
      reg_addr_count_pcie_x8 = REG_IRQ_0_ADDR;
      NAPRdCompDW0((target_addr[17] + reg_addr_count_pcie_x8*64),
                  ACX_REG1_NAP_COL,
                  ACX_REG1_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  0);

      // check that the Master IRQ register is set back to 0
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Check the master IRQ register is cleared");
      $display ("-------------------------------");
      reg_addr_count_pcie_x8 = REG_IRQ_MASTER_ADDR;
      NAPRdCompDW0((target_addr[17] + reg_addr_count_pcie_x8*64),
                  ACX_REG1_NAP_COL,
                  ACX_REG1_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  0);

      //-------------------------------------------
      // Counter registers
      // first write to set the value of 1 counter
      // then read it back to make sure the value is set
      // then write the config reg and set down counter
      // then read counter again and see that it's lower
      // 
      // Next do the same with the other counter
      // but make it count up
      //-------------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Writing to counter register");
      $display ("-------------------------------");

      original_cnt_val = 32'h7FFFFFFF; //Set at mid-point

      reg_addr_count_pcie_x8 = REG_CNT_0_ADDR;
      NAPWrDW0((target_addr[17] + reg_addr_count_pcie_x8*64),
                  ACX_REG1_NAP_COL,
                  ACX_REG1_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  original_cnt_val);

      //-------------------------------------------
      // Set the config register to count down
      // and enable the counter
      //-------------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Writing to counter config register");
      $display ("-------------------------------");

      reg_addr_count_pcie_x8 = REG_CNT_CFG_0_ADDR;
      NAPWrDW0((target_addr[17] + reg_addr_count_pcie_x8*64),
                  ACX_REG1_NAP_COL,
                  ACX_REG1_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  {29'h0, 1'b1, 1'b1, 1'b0});

      // now stop the down counter
      NAPWrDW0((target_addr[17] + reg_addr_count_pcie_x8*64),
                  ACX_REG1_NAP_COL,
                  ACX_REG1_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  {29'h0, 1'b1, 1'b0, 1'b0});


      //-----------------------------
      // read counter and check it's
      // value is smaller
     //-----------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Reading counter register");
      $display ("-------------------------------");
      reg_addr_count_pcie_x8 = REG_CNT_0_ADDR;
      NAPRdDW0((target_addr[17] + reg_addr_count_pcie_x8*64),
                  ACX_REG1_NAP_COL,
                  ACX_REG1_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  new_cnt_val);

      if(new_cnt_val < original_cnt_val) // check number decreased
        $strobe("PCIEx8 :: Counter old value %h > counter new value %h", original_cnt_val, new_cnt_val);
      else begin
         $display(" ERROR:: Old counter %h",original_cnt_val);
         $display(" ERROR:: New counter %h",new_cnt_val);
         $error("ERROR :: Old counter NOT > new counter value");
         $fatal("ERROR :: Old counter NOT > new counter value");
      end


      //-------------------------------------------
      // Counter registers
      // Read counter to make sure the value is 0
      // then write the config reg and set up counter
      // then read counter again and see that it's higher
      //-------------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Writing to counter register");
      $display ("-------------------------------");

      original_cnt_val = 32'h7FFFFFFF; //Set at mid-point

      reg_addr_count_pcie_x8 = REG_CNT_1_ADDR;
      NAPWrDW0((target_addr[17] + reg_addr_count_pcie_x8*64),
                  ACX_REG1_NAP_COL,
                  ACX_REG1_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  original_cnt_val);

      //-------------------------------------------
      // Set the config register to count up
      // and enable the counter
      //-------------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Writing to counter config register");
      $display ("-------------------------------");

      reg_addr_count_pcie_x8 = REG_CNT_CFG_1_ADDR;
      NAPWrDW0((target_addr[17] + reg_addr_count_pcie_x8*64),
                  ACX_REG1_NAP_COL,
                  ACX_REG1_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  {29'h0, 1'b0, 1'b1, 1'b0});

      // now stop the up counter
      NAPWrDW0((target_addr[17] + reg_addr_count_pcie_x8*64),
                  ACX_REG1_NAP_COL,
                  ACX_REG1_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  {29'h0, 1'b0, 1'b0, 1'b0});

      //-----------------------------
      // read counter and check it's
      // value is smaller
      //-----------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Reading counter register");
      $display ("-------------------------------");
      reg_addr_count_pcie_x8 = REG_CNT_1_ADDR;
      NAPRdDW0((target_addr[17] + reg_addr_count_pcie_x8*64),
                  ACX_REG1_NAP_COL,
                  ACX_REG1_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  new_cnt_val);

      if(new_cnt_val > original_cnt_val) // check number decreased
        $strobe("PCIEx8 :: Counter old value %h < counter new value %h", original_cnt_val, new_cnt_val);
      else begin
         $display(" ERROR:: Old counter %h",original_cnt_val);
         $display(" ERROR:: New counter %h",new_cnt_val);
         $error("ERROR :: Old counter NOT < new counter value");
         $fatal("ERROR :: Old counter NOT < new counter value");
      end

//-----------------------------------------------------------------------------------------------------------------------
    // wait for everything to become idle
//-----------------------------------------------------------------------------------------------------------------------
    $msglog(LOG_INFO, "%sCleanup: Waiting for everything to become IDLE for PCIex8", DISPLAY_NAME);
    status = 0;
    while (!status)
      begin
        #10ns;
        tb_pcie_ref_design.root_x8.port0.dl0.IsDataLinkIdle(status);
        status = status & tmp_status;
        tb_pcie_ref_design.root_x8.port0.tl0.IsTransactionLayerIdle(tmp_status);
        status = status & tmp_status;
        status = status & tmp_status;
      end
 
          
    $display("\n**************************************** TEST CASE RESULTS ********************************************\n");
    tb_pcie_ref_design.root_x8.port0.dl0.DisplayStats;
    tb_pcie_ref_design.root_x8.port0.tl0.DisplayStats;
        
    //CheckCredits;
    $display ($time, ": ========================PCIex8 RTL Mode Test Completed, Results: =============================");
    CheckTestStatus;
  pciex8_rtl_test_done = 1;
`endif //}

//=================================================================================================================
//=================================================================================================================

//=================================================================================================================
//=================================================================================================================
`ifdef ACX_PCIE_1_FULL //{

   `ifndef ACX_PCIE_0_FULL //PCIex8 is BFM, then wait for x8 BFM test to complete
      while (!pciex8_bfm_test_done);
   `else  //PCIex8 is RTL, wait for PCIex8 RTL mode test done
      while (!pciex8_rtl_test_done);
   `endif


//-----------------------------------------------------------------------------------------------------------------------
    // Start to write/read/check data
//-----------------------------------------------------------------------------------------------------------------------

     //for (num_DWs=16; num_DWs <= (16*17); num_DWs=num_DWs+64) begin
     for (num_DWs=16; num_DWs <= 128; num_DWs=num_DWs+16) begin
       for (addr_count= 0;  addr_count<17; addr_count++) begin
         MemRandWrRdComp1(target_addr[addr_count],
                         num_DWs,
                         MEM_ACCESS_TRAFFIC_CLASS);
       end
     end


     addr_count = 17;
       $display ($time, ": Place holder for pciex8 RTL access to bram1");

     addr_count = 18;
     for (num_DWs=16; num_DWs <= (16*4); num_DWs=num_DWs+16) begin
       NAPRandWrRdComp1(target_addr[17],
                       ACX_BRAM2_NAP_COL,
                       ACX_BRAM2_NAP_ROW,
                       num_DWs,
                       MEM_ACCESS_TRAFFIC_CLASS);
     end

     addr_count = 19;

      //----------------------------------
      // Now read/write to register set
      // using PCIex16
      //----------------------------------


      // -----------------------------------
      // loop through read/write registers
      // These are 8 32-bit registers
      // -----------------------------------

      $display ("-------------------------------");
      $display ($time, ": PCIex16 Writing and Reading the eight 32-bit Registers");
      $display ("-------------------------------");


      for(reg_addr_count_pcie_x16= 0; reg_addr_count_pcie_x16<8; reg_addr_count_pcie_x16++) begin
        NAPRandWrRdCompDW1((target_addr[17] + reg_addr_count_pcie_x16*64),
                                  ACX_REG2_NAP_COL,
                                  ACX_REG2_NAP_ROW,
                                  MEM_ACCESS_TRAFFIC_CLASS);
      end // for (addr_count_pcie_x16= 0;  addr_count_pcie_x16<8; addr_count_pcie_x16++)

      // -----------------------------------
      // loop through read-only registers
      // These are 8 32-bit registers
      // Excpected value is addr + bias
      // In this case, Addr + 0
      // -----------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Reading the 8 read-only Registers");
      $display ("-------------------------------");

      for(reg_addr_count_pcie_x16= 8; reg_addr_count_pcie_x16<16; reg_addr_count_pcie_x16++) begin
        NAPRdCompDW1((target_addr[17] + reg_addr_count_pcie_x16*64),
                    ACX_REG2_NAP_COL,
                    ACX_REG2_NAP_ROW,
                    MEM_ACCESS_TRAFFIC_CLASS,
                    reg_addr_count_pcie_x16*64);
      end
      // -----------------------------------
      // loop through read/write registers
      // These are 4 64-bit registers
      // -----------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Writing and Reading the four 64-bit Registers");
      $display ("-------------------------------");

      for(reg_addr_count_pcie_x16= 24; reg_addr_count_pcie_x16<28; reg_addr_count_pcie_x16++) begin
        NAPRandWrRdComp1((target_addr[17] + reg_addr_count_pcie_x16*64),
                                  ACX_REG2_NAP_COL,
                                  ACX_REG2_NAP_ROW,
                                  2,
                                  MEM_ACCESS_TRAFFIC_CLASS);
      end // for (addr_count_pcie_x16= 24;  addr_count_pcie_x16<28; addr_count_pcie_x16++)


      //-------------------------------------
      // read on clear register
      // first write to set the value
      // then read it back
      // on second read it should be all 0s
      //-------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Writing and Reading the clear-on-read register");
      $display ("-------------------------------");

      reg_addr_count_pcie_x16 = REG_CLEAR_ON_RD_ADDR;

      NAPRandWrRdCompDW1((target_addr[17] + reg_addr_count_pcie_x16*64),
                        ACX_REG2_NAP_COL,
                        ACX_REG2_NAP_ROW,
                        MEM_ACCESS_TRAFFIC_CLASS);

      NAPRdCompDW1((target_addr[17] + reg_addr_count_pcie_x16*64),
                  ACX_REG2_NAP_COL,
                  ACX_REG2_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  0);

      //-------------------------------------
      // IRQ register
      // first write to set the value
      // then read it back
      // and read the master register
      // then clear the IRQ, read master register
      // to make sure it's 0
      //-------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Writing and Reading the IRQ register");
      $display ("-------------------------------");

      irq_data = $random   ;// 32-bit random data

      reg_addr_count_pcie_x16 = REG_IRQ_0_ADDR;
      NAPWrDW1((target_addr[17] + reg_addr_count_pcie_x16*64),
                  ACX_REG2_NAP_COL,
                  ACX_REG2_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  irq_data);

      // check that the Master IRQ register is set to 1
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Check the master IRQ register is set to 1");
      $display ("-------------------------------");
      reg_addr_count_pcie_x16 = REG_IRQ_MASTER_ADDR;
      NAPRdCompDW1((target_addr[17] + reg_addr_count_pcie_x16*64),
                  ACX_REG2_NAP_COL,
                  ACX_REG2_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  1);

      // Now clear the IRQ register
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Clear the IRQ register");
      $display ("-------------------------------");
      reg_addr_count_pcie_x16 = REG_IRQ_CFG_0_ADDR;
      NAPWrDW1((target_addr[17] + reg_addr_count_pcie_x16*64),
                  ACX_REG2_NAP_COL,
                  ACX_REG2_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  irq_data);

      // read the IRQ register and make sure it's been cleared
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Check the IRQ register has cleared");
      $display ("-------------------------------");
      reg_addr_count_pcie_x16 = REG_IRQ_0_ADDR;
      NAPRdCompDW1((target_addr[17] + reg_addr_count_pcie_x16*64),
                  ACX_REG2_NAP_COL,
                  ACX_REG2_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  0);

      // check that the Master IRQ register is set back to 0
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Check the master IRQ register is cleared");
      $display ("-------------------------------");
      reg_addr_count_pcie_x16 = REG_IRQ_MASTER_ADDR;
      NAPRdCompDW1((target_addr[17] + reg_addr_count_pcie_x16*64),
                  ACX_REG2_NAP_COL,
                  ACX_REG2_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  0);

      //-------------------------------------------
      // Counter registers
      // first write to set the value of 1 counter
      // then read it back to make sure the value is set
      // then write the config reg and set down counter
      // then read counter again and see that it's lower
      // 
      // Next do the same with the other counter
      // but make it count up
      //-------------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Writing to counter register");
      $display ("-------------------------------");

      original_cnt_val = 32'h7FFFFFFF; //Set at mid-point

      reg_addr_count_pcie_x16 = REG_CNT_0_ADDR;
      NAPWrDW1((target_addr[17] + reg_addr_count_pcie_x16*64),
                  ACX_REG2_NAP_COL,
                  ACX_REG2_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  original_cnt_val);

      //-------------------------------------------
      // Set the config register to count down
      // and enable the counter
      //-------------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Writing to counter config register");
      $display ("-------------------------------");

      reg_addr_count_pcie_x16 = REG_CNT_CFG_0_ADDR;
      NAPWrDW1((target_addr[17] + reg_addr_count_pcie_x16*64),
                  ACX_REG2_NAP_COL,
                  ACX_REG2_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  {29'h0, 1'b1, 1'b1, 1'b0});

      // now stop the down counter
      NAPWrDW1((target_addr[17] + reg_addr_count_pcie_x16*64),
                  ACX_REG2_NAP_COL,
                  ACX_REG2_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  {29'h0, 1'b1, 1'b0, 1'b0});


      //-----------------------------
      // read counter and check it's
      // value is smaller
     //-----------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Reading counter register");
      $display ("-------------------------------");
      reg_addr_count_pcie_x16 = REG_CNT_0_ADDR;
      NAPRdDW1((target_addr[17] + reg_addr_count_pcie_x16*64),
                  ACX_REG2_NAP_COL,
                  ACX_REG2_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  new_cnt_val);

      if(new_cnt_val < original_cnt_val) // check number decreased
        $strobe("PCIEx16 :: Counter old value %h > counter new value %h", original_cnt_val, new_cnt_val);
      else begin
         $display(" ERROR:: Old counter %h",original_cnt_val);
         $display(" ERROR:: New counter %h",new_cnt_val);
         $error("ERROR :: Old counter NOT > new counter value");
         $fatal("ERROR :: Old counter NOT > new counter value");
      end


      //-------------------------------------------
      // Counter registers
      // Read counter to make sure the value is 0
      // then write the config reg and set up counter
      // then read counter again and see that it's higher
      //-------------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Writing to counter register");
      $display ("-------------------------------");

      original_cnt_val = 32'h7FFFFFFF; //Set at mid-point

      reg_addr_count_pcie_x16 = REG_CNT_1_ADDR;
      NAPWrDW1((target_addr[17] + reg_addr_count_pcie_x16*64),
                  ACX_REG2_NAP_COL,
                  ACX_REG2_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  original_cnt_val);

      //-------------------------------------------
      // Set the config register to count up
      // and enable the counter
      //-------------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Writing to counter config register");
      $display ("-------------------------------");

      reg_addr_count_pcie_x16 = REG_CNT_CFG_1_ADDR;
      NAPWrDW1((target_addr[17] + reg_addr_count_pcie_x16*64),
                  ACX_REG2_NAP_COL,
                  ACX_REG2_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  {29'h0, 1'b0, 1'b1, 1'b0});

      // now stop the up counter
      NAPWrDW1((target_addr[17] + reg_addr_count_pcie_x16*64),
                  ACX_REG2_NAP_COL,
                  ACX_REG2_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  {29'h0, 1'b0, 1'b0, 1'b0});

      //-----------------------------
      // read counter and check it's
      // value is smaller
      //-----------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Reading counter register");
      $display ("-------------------------------");
      reg_addr_count_pcie_x16 = REG_CNT_1_ADDR;
      NAPRdDW1((target_addr[17] + reg_addr_count_pcie_x16*64),
                  ACX_REG2_NAP_COL,
                  ACX_REG2_NAP_ROW,
                  MEM_ACCESS_TRAFFIC_CLASS,
                  new_cnt_val);

      if(new_cnt_val > original_cnt_val) // check number decreased
        $strobe("PCIEx16 :: Counter old value %h < counter new value %h", original_cnt_val, new_cnt_val);
      else begin
         $display(" ERROR:: Old counter %h",original_cnt_val);
         $display(" ERROR:: New counter %h",new_cnt_val);
         $error("ERROR :: Old counter NOT < new counter value");
         $fatal("ERROR :: Old counter NOT < new counter value");
      end

      addr_count = 20;
      //----------------------------------
      // Now read/write to register set
      // using PCIex8
      //----------------------------------

     $display ($time, ": Place holder for pciex8 RTL access to reg set1");

//-----------------------------------------------------------------------------------------------------------------------
    // wait for everything to become idle
//-----------------------------------------------------------------------------------------------------------------------
    $msglog(LOG_INFO, "%sCleanup: Waiting for everything to become IDLE", DISPLAY_NAME);
    status = 0;
    while (!status)
      begin
        #10ns;
        tb_pcie_ref_design.root_x16.port0.dl0.IsDataLinkIdle(status);
        status = status & tmp_status;
        tb_pcie_ref_design.root_x16.port0.tl0.IsTransactionLayerIdle(tmp_status);
        status = status & tmp_status;
        status = status & tmp_status;
      end
 
          
    $display("\n********************************************** TEST CASE RESULTS **************************************************\n");
    tb_pcie_ref_design.root_x16.port0.dl0.DisplayStats;
    tb_pcie_ref_design.root_x16.port0.tl0.DisplayStats;
        
    //CheckCredits;
    $display ($time, ": ========================PCIex16 RTL Mode Test Completed, Results: =============================");
    CheckTestStatus;
    pciex16_rtl_test_done = 1;

`endif //}

  end //}
`endif
endmodule

