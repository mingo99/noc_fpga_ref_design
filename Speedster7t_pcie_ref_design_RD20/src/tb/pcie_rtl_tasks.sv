task DoReset;
  begin
    $msglog(LOG_INFO, "DUT_CONFIG:  Asserting reset.");    
    tb_pcie_ref_design.reset = 1;
    #1;
    #100; tb_pcie_ref_design.reset = 0;

    // insert DUT resets here.
    #100;
    $msglog(LOG_INFO, "DUT_CONFIG:  Deasserting reset after 100ns.  Reset Finished.");    
  end
endtask

///////////////////////////////////////////////////////////////////////////////////
task CheckTestStatus;
  integer       log_err_cnt, log_warn_cnt, log_notice_cnt;
  begin
    $msglog_clear(LOG_NOTICE);  
    log_err_cnt    = $msglog_count(LOG_ERR);
    log_warn_cnt   = $msglog_count(LOG_WARN);
    log_notice_cnt = $msglog_count(LOG_NOTICE);

    log_warn_cnt = log_warn_cnt - log_err_cnt;
    log_notice_cnt = log_notice_cnt - log_warn_cnt - log_err_cnt;
        
    if ((log_warn_cnt == 0) && (log_err_cnt == 0) && (log_notice_cnt == 0))
      begin
        $msglog(LOG_INFO, "%sCheckTestStatus:  No Errors, Warnings or Notices. Have a nice day! :) \nSvtTestEpilog: Passed\n", DISPLAY_NAME);

      end
    else 
      begin
        $msglog(LOG_INFO, "    %sCheckTestStatus:  %0d errors, %0d warnings, %0d notices found! :( \nSvtTestEpilog: Failed\n", 
          DISPLAY_NAME, log_err_cnt, log_warn_cnt, log_notice_cnt);
        tb_pcie_ref_design.test_fail = 1;
      end
  end
      
endtask // CheckTestStatus

task MemRandWrRdComp0;
  input [63:0] address;
  input [31:0] length_in_dwords;
  input [31:0] tc;

  logic [31:0] command_num;
  logic [31:0] tx_driver_status;

  begin
    tb_pcie_ref_design.root_x8.driver0.USE_INTERNAL_DATA_BUFFERS_VAR = 1; // use the auto-allocated data buffers
    $msglog(LOG_INFO, "%sMemWr: Requesting a MEM WRITE, address = 0x%x, dwords = %0d, payload contents:",
                           DISPLAY_NAME, address, length_in_dwords);

    tb_pcie_ref_design.root_x8.driver0.QueueMemWrite(address,
                                   length_in_dwords,       // length of read
                                   4'hF,         // first DW BE
                                   4'hF,          // last DW BE
                                   tc,                     // traffic class 
                                   2'b0,                   // address translation
                                   1'b0,                   // error/poison
                                   32'h0,
                                   32'h0,          
                                   32'h0,    
                                   1'b1,                    //blocking
                                   command_num,
                                   tx_driver_status);
   

    $msglog(LOG_INFO, "%sMemRd: Requesting a MEM READ, address = 0x%x, dwords = %0d",
                       DISPLAY_NAME, address, length_in_dwords);
    tb_pcie_ref_design.root_x8.driver0.QueueMemRead(address,                 // address
                                  length_in_dwords,        // length of read
                                  4'hF,          // first dw be
                                  4'hF,           // last dw be
                                  tc,                      // traffic class
                                  2'b0,                    // address translation
                                  32'h0,                   // buffer ptr
                                  32'h0,                   // buffer len
                                  32'h0,              // ei code
                                  1'b1,                    // blocking
                                  command_num,          // transaction id
                                  tx_driver_status); 

    $msglog(LOG_INFO, "%sMemRd: Waiting for completion of the memory read (xid = %x)", DISPLAY_NAME, command_num);
    tb_pcie_ref_design.root_x8.driver0.WaitForCompletion(command_num,tx_driver_status);
  end

endtask

task NAPRandWrRdComp0;
  input [63:0] nap_base;
  input [3:0] col;
  input [2:0] row;
  input [31:0] length_in_dwords;
  input [31:0] tc;

  logic [31:0] command_num;
  logic [31:0] tx_driver_status;

  begin
    tb_pcie_ref_design.root_x8.driver0.USE_INTERNAL_DATA_BUFFERS_VAR = 1; // use the auto-allocated data buffers
    $msglog(LOG_INFO, "%sMemWr: Requesting a NAP WRITE, column = %0d, row = %0d, dwords = %0d, payload contents:",
                           DISPLAY_NAME, col, row, length_in_dwords);

    tb_pcie_ref_design.root_x8.driver0.QueueMemWrite({nap_base[63:35], col, row, nap_base[27:0]},
                                   length_in_dwords,       // length of read
                                   4'hF,         // first DW BE
                                   4'hF,          // last DW BE
                                   tc,                     // traffic class 
                                   2'b0,                   // address translation
                                   1'b0,                   // error/poison
                                   32'h0,
                                   32'h0,          
                                   32'h0,    
                                   1'b1,                    //blocking
                                   command_num,
                                   tx_driver_status);
   

    $msglog(LOG_INFO, "%sMemWr: Requesting a NAP READ, column = %0d, row = %0d, dwords = %0d, payload contents:",
                           DISPLAY_NAME, col, row, length_in_dwords);
    tb_pcie_ref_design.root_x8.driver0.QueueMemRead({nap_base[63:35], col, row, nap_base[27:0]},                 // address
                                  length_in_dwords,        // length of read
                                  4'hF,          // first dw be
                                  4'hF,           // last dw be
                                  tc,                      // traffic class
                                  2'b0,                    // address translation
                                  32'h0,                   // buffer ptr
                                  32'h0,                   // buffer len
                                  32'h0,              // ei code
                                  1'b1,                    //blocking
                                  command_num,          // transaction id
                                  tx_driver_status); 

    $msglog(LOG_INFO, "%sMemRd: Waiting for completion of the memory read (xid = %x)", DISPLAY_NAME, command_num);
    tb_pcie_ref_design.root_x8.driver0.WaitForCompletion(command_num,tx_driver_status);
  end

endtask

task NAPRandWrRdCompDW0;
  input [63:0] nap_base;
  input [3:0] col;
  input [2:0] row;
  input [31:0] tc;

  logic [31:0] command_num;
  logic [31:0] tx_driver_status;

  begin
    tb_pcie_ref_design.root_x8.driver0.USE_INTERNAL_DATA_BUFFERS_VAR = 1; // use the auto-allocated data buffers
    $msglog(LOG_INFO, "%sMemWr: Requesting a NAP WRITE, column = %0d, row = %0d, dwords = %0d, payload contents:",
                           DISPLAY_NAME, col, row, 1);

    tb_pcie_ref_design.root_x8.driver0.QueueMemWrite({nap_base[63:35], col, row, nap_base[27:0]},
                                   32'h1,       // length of read
                                   4'hF,         // first DW BE
                                   4'h0,          // last DW BE
                                   tc,                     // traffic class 
                                   2'b0,                   // address translation
                                   1'b0,                   // error/poison
                                   32'h0,
                                   32'h0,          
                                   32'h0,    
                                   1'b1,                    //blocking
                                   command_num,
                                   tx_driver_status);
   

    $msglog(LOG_INFO, "%sMemWr: Requesting a NAP READ, column = %0d, row = %0d, dwords = %0d, payload contents:",
                           DISPLAY_NAME, col, row, 1);
    tb_pcie_ref_design.root_x8.driver0.QueueMemRead({nap_base[63:35], col, row, nap_base[27:0]},                 // address
                                  32'h1,        // length of read
                                  4'hF,          // first dw be
                                  4'h0,           // last dw be
                                  tc,                      // traffic class
                                  2'b0,                    // address translation
                                  32'h0,                   // buffer ptr
                                  32'h0,                   // buffer len
                                  32'h0,              // ei code
                                  1'b1,                    //blocking
                                  command_num,          // transaction id
                                  tx_driver_status); 

    $msglog(LOG_INFO, "%sMemRd: Waiting for completion of the memory read (xid = %x)", DISPLAY_NAME, command_num);
    tb_pcie_ref_design.root_x8.driver0.WaitForCompletion(command_num,tx_driver_status);
  end

endtask

task NAPRdCompDW0;
  input [63:0] nap_base;
  input [3:0] col;
  input [2:0] row;
  input [31:0] tc;
  input [31:0] expected_rd_data;

  logic [31:0] command_num;
  logic [31:0] tx_driver_status;

  reg [31:0] buffer_ptr;
  reg [31:0] buffer_len;
  logic [31:0] swapped_expected_data;

  begin
    tb_pcie_ref_design.root_x8.driver0.USE_INTERNAL_DATA_BUFFERS_VAR = 0; // Turn off auto-allocated data buffers
    swapped_expected_data = {expected_rd_data[7:0],
                             expected_rd_data[15:8],
                             expected_rd_data[23:16],
                             expected_rd_data[31:24]};
    buffer_len = 4;
    `PCIESVC_MEM_PATH.AllocateMemory(DISPLAY_NAME, buffer_len, buffer_ptr);

    `PCIESVC_MEM_PATH.WriteMemory(DISPLAY_NAME,buffer_ptr,swapped_expected_data,4);


     $display ($time, ": Fake write to read-only Registers to setup for subsequent read.");

    tb_pcie_ref_design.root_x8.driver0.QueueMemWrite({nap_base[63:35], col, row, nap_base[27:0]},
                                   32'h1,       // length of read
                                   4'hF,         // first DW BE
                                   4'h0,          // last DW BE
                                   tc,                     // traffic class 
                                   2'b0,                   // address translation
                                   1'b0,                   // error/poison
                                   buffer_ptr,
                                   buffer_len,          
                                   32'h0,    
                                   1'b1,                    //blocking
                                   command_num,
                                   tx_driver_status);
   

    $msglog(LOG_INFO, "%sMemWr: Requesting a NAP READ, column = %0d, row = %0d, dwords = %0d, expected data is: 0x%0h",
                           DISPLAY_NAME, col, row, 1, expected_rd_data);
    tb_pcie_ref_design.root_x8.driver0.QueueMemRead({nap_base[63:35], col, row, nap_base[27:0]},                 // address
                                  32'h1,        // length of read
                                  4'hF,          // first dw be
                                  4'h0,           // last dw be
                                  tc,                      // traffic class
                                  2'b0,                    // address translation
                                  buffer_ptr,                   // buffer ptr
                                  buffer_len,                   // buffer len
                                  32'h0,              // ei code
                                  1'b1,                    //blocking
                                  command_num,          // transaction id
                                  tx_driver_status); 

    $msglog(LOG_INFO, "%sMemRd: Waiting for completion of the memory read (xid = %x)", DISPLAY_NAME, command_num);
    tb_pcie_ref_design.root_x8.driver0.WaitForCompletion(command_num,tx_driver_status);
  end

endtask

task NAPWrDW0;
  input [63:0] nap_base;
  input [3:0] col;
  input [2:0] row;
  input [31:0] tc;
  input [31:0] wr_data;

  logic [31:0] command_num;
  logic [31:0] tx_driver_status;

  reg [31:0] buffer_ptr;
  reg [31:0] buffer_len;
  logic [31:0] swapped_wr_data;

  begin
    tb_pcie_ref_design.root_x8.driver0.USE_INTERNAL_DATA_BUFFERS_VAR = 0; // Turn off auto-allocated data buffers
    swapped_wr_data = {wr_data[7:0],
                       wr_data[15:8],
                       wr_data[23:16],
                       wr_data[31:24]};
    buffer_len = 4;
    `PCIESVC_MEM_PATH.AllocateMemory(DISPLAY_NAME, buffer_len, buffer_ptr);

    `PCIESVC_MEM_PATH.WriteMemory(DISPLAY_NAME,buffer_ptr,swapped_wr_data,4);


     $display ($time, ": Write to a single DW");

    tb_pcie_ref_design.root_x8.driver0.QueueMemWrite({nap_base[63:35], col, row, nap_base[27:0]},
                                   32'h1,       // length of read
                                   4'hF,         // first DW BE
                                   4'h0,          // last DW BE
                                   tc,                     // traffic class 
                                   2'b0,                   // address translation
                                   1'b0,                   // error/poison
                                   buffer_ptr,
                                   buffer_len,          
                                   32'h0,    
                                   1'b1,                    //blocking
                                   command_num,
                                   tx_driver_status);
    $msglog(LOG_INFO, "%sMemRd: Waiting for completion of the memory read (xid = %x)", DISPLAY_NAME, command_num);
    tb_pcie_ref_design.root_x8.driver0.WaitForCompletion(command_num,tx_driver_status);
    tb_pcie_ref_design.root_x8.driver0.ENABLE_SHADOW_MEMORY_CHECKING_VAR = 1;
    $display ($time, ": Extra delay before next Write");
    #200ns;
  end

endtask

task NAPRdDW0;
  input [63:0] nap_base;
  input [3:0] col;
  input [2:0] row;
  input [31:0] tc;
  output [31:0] rd_data;

  logic [31:0] command_num;
  logic [31:0] tx_driver_status;

  reg [31:0] buffer_ptr;
  reg [31:0] buffer_len;
  logic [31:0] swapped_rd_data;

  begin
    tb_pcie_ref_design.root_x8.driver0.USE_INTERNAL_DATA_BUFFERS_VAR = 0; // Turn off auto-allocated data buffers
    tb_pcie_ref_design.root_x8.driver0.ENABLE_SHADOW_MEMORY_CHECKING_VAR = 0; //Turn off data compare
    buffer_len = 4;
    `PCIESVC_MEM_PATH.AllocateMemory(DISPLAY_NAME, buffer_len, buffer_ptr);

     $display ($time, ": Read a single DW");

    tb_pcie_ref_design.root_x8.driver0.QueueMemRead({nap_base[63:35], col, row, nap_base[27:0]},                 // address
                                  32'h1,        // length of read
                                  4'hF,          // first dw be
                                  4'h0,           // last dw be
                                  tc,                      // traffic class
                                  2'b0,                    // address translation
                                  buffer_ptr,                   // buffer ptr
                                  buffer_len,                   // buffer len
                                  32'h0,              // ei code
                                  1'b1,                    // blocking
                                  command_num,          // transaction id
                                  tx_driver_status); 
    tb_pcie_ref_design.root_x8.driver0.WaitForCompletion(command_num,tx_driver_status);
    `PCIESVC_MEM_PATH.ReadMemory(DISPLAY_NAME,buffer_ptr,swapped_rd_data);
    rd_data = {swapped_rd_data[7:0],
               swapped_rd_data[15:8],
               swapped_rd_data[23:16],
               swapped_rd_data[31:24]};

    tb_pcie_ref_design.root_x8.driver0.ENABLE_SHADOW_MEMORY_CHECKING_VAR = 1; //Turn on data compare
  end

endtask


task DoInitLinkUpRcEp0(pciesvc_device_serdes_x16_model_config model_cfg);
  bit [31:0] cfg_data;
  bit        tx_error;
  int hdr_credit, data_credit,i; 
    
    // Bring SVC/Dut out of reset.
    #1;  // Can set _VARs after 2ns.
    $msglog_suppress("tb_pcie_ref_design.endpoint0.port0.serdes0", MSGCODE_PCIESVC_SERDES_BYTE_UNLOCK, 0, 0);
    $msglog_suppress("tb_pcie_ref_design.endpoint0.port0.serdes1", MSGCODE_PCIESVC_SERDES_BYTE_UNLOCK, 0, 0);
    $msglog_suppress("tb_pcie_ref_design.endpoint0.port0.serdes2", MSGCODE_PCIESVC_SERDES_BYTE_UNLOCK, 0, 0);
    $msglog_suppress("tb_pcie_ref_design.endpoint0.port0.serdes3", MSGCODE_PCIESVC_SERDES_BYTE_UNLOCK, 0, 0);
    $msglog_suppress("tb_pcie_ref_design.root_x8.port0.serdes0", MSGCODE_PCIESVC_SERDES_BYTE_UNLOCK, 0, 0);
    $msglog_suppress("tb_pcie_ref_design.root_x8.port0.serdes1", MSGCODE_PCIESVC_SERDES_BYTE_UNLOCK, 0, 0);
    $msglog_suppress("tb_pcie_ref_design.root_x8.port0.serdes2", MSGCODE_PCIESVC_SERDES_BYTE_UNLOCK, 0, 0);
    $msglog_suppress("tb_pcie_ref_design.root_x8.port0.serdes3", MSGCODE_PCIESVC_SERDES_BYTE_UNLOCK, 0, 0);
    

`ifdef PCIESVC_INCLUDE_PA
    cfg_data = 0;
    cfg_data[PA_TRANSACTION_MODE_TRANSACTION_LOGGING_ENABLED_BIT] = 1;
    tb_pcie_ref_design.root_x8.port0.tl0.SetPATransactionMode(cfg_data);
    
    cfg_data = 0;
    cfg_data[PA_LINK_MODE_PACKET_LOGGING_ENABLED_BIT] = 1;
    cfg_data[PA_LINK_MODE_PAYLOAD_LOGGING_ENABLED_BIT] = 1;
    tb_pcie_ref_design.root_x8.port0.dl0.SetPALinkMode(cfg_data);
    
    cfg_data = 0;
    cfg_data[PA_PHY_MODE_OS_LOGGING_ENABLED_BIT] = 1;
    cfg_data[PA_PHY_MODE_LTSSM_LOGGING_ENABLED_BIT] = 1;
    tb_pcie_ref_design.root_x8.port0.pl0.SetPAPhyMode(cfg_data);

`endif

    //To handle: 
    //WARNING: root_x8.port0.pl0.LTSSMStateMachine: Timeout in state LTSSM_POLLING_ACTIVE as conditions to transition to state Polling.Configuration or Polling.Compliance are not met. VIP will now transition back to state Detect.Quiet
    //INFO:    SNPS_PCIE_VIP_DEBUG_TIP: The parameter POLLING_ACTIVE_TIMEOUT_NS is set to 240000. If DUT is functioning correctly and the conditions to transition to state Polling.Configuration or Polling.Compliance will take more time then increase POLLING_ACTIVE_TIMEOUT_NS to avoid this timeout.

    tb_pcie_ref_design.root_x8.port0.pl0.POLLING_ACTIVE_TIMEOUT_NS_VAR = 480000;
    $display("TEST_INFO setting POLLING_ACTIVE_TIMEOUT_NS_VAR to 480000");
    DoReset;
 
    tb_pcie_ref_design.root_x8.port0.pl0.PCIE_SPEC_VER_VAR = PCIE_SPEC_VER_5_0;

    tb_pcie_ref_design.root_x8.port0.tl0.PCIE_SPEC_VER_VAR = PCIE_SPEC_VER_5_0;

    tb_pcie_ref_design.root_x8.port0.dl0.PCIE_SPEC_VER_VAR = PCIE_SPEC_VER_5_0;


    $display("TEST_INFO setting PCIE_SPEC_VER_5_0");
    tb_pcie_ref_design.root_x8.port0.tl0.REMOTE_MAX_PAYLOAD_SIZE_VAR = model_cfg.max_payload_size;
    tb_pcie_ref_design.root_x8.port0.tl0.REMOTE_MAX_READ_REQUEST_SIZE_VAR = model_cfg.max_payload_size;
    tb_pcie_ref_design.root_x8.port0.dl0.MAX_PAYLOAD_SIZE_VAR = model_cfg.max_payload_size;
    tb_pcie_ref_design.root_x8.requester0.MAX_DATA_LEN_IN_BYTES_VAR = model_cfg.max_payload_size;

    $msglog(LOG_INFO, "%sbasic_serial5: TEST_INFO max_payload_size config = %0d:",
                           DISPLAY_NAME, model_cfg.max_payload_size);

    tb_pcie_ref_design.root_x8.driver0.PERCENTAGE_USE_TLP_DIGEST_VAR = model_cfg.root_digest_percentage;

    $msglog(LOG_INFO, "%sbasic_serial5: TEST_INFO root_digest_percentage config = %0d:",
                           DISPLAY_NAME, model_cfg.root_digest_percentage);
    // TODO: How to set endpoint digest percentage? 
    //
    tb_pcie_ref_design.root_x8.port0.pl0.SetSupportedSpeeds(model_cfg.root_supported_speeds); 

    $msglog(LOG_INFO, "%sbasic_serial5: TEST_INFO root_supported_speeds config = %0d:",
                           DISPLAY_NAME, model_cfg.root_supported_speeds);

    tb_pcie_ref_design.root_x8.port0.pl0.SetLinkWidth(model_cfg.root_link_width);

    $msglog(LOG_INFO, "%sbasic_serial5: TEST_INFO root_link_width config = %0d:",
                           DISPLAY_NAME, model_cfg.root_link_width);
     
    tb_pcie_ref_design.root_x8.port0.dl0.ENABLE_EI_TX_TLP_ON_RETRY_VAR = model_cfg.en_retry_ei;

     $msglog(LOG_INFO, "%sbasic_serial5: TEST_INFO en_retry_ei config = %0d:",
                           DISPLAY_NAME, model_cfg.en_retry_ei);

     if (|model_cfg.enable_vc[7:1])
      begin
        for (i=1;i<8;i=i+1)
          begin
            if (model_cfg.enable_vc[i])
              begin
                hdr_credit = model_cfg.hdr_credit_p;
                data_credit = model_cfg.data_credit_p;
                tb_pcie_ref_design.root_x8.port0.tl0.SetInitTxCredits(0,i, FC_TYPE_P, hdr_credit, data_credit);
                $msglog(LOG_INFO, "%sbasic_serial5: TEST_INFO Posted hdr_credit = 0x%0h data_credit = 0x%0h enable_vc = 0x%0h config:",
                           DISPLAY_NAME, hdr_credit, data_credit, model_cfg.enable_vc[i]);
                hdr_credit = model_cfg.hdr_credit_np;
                data_credit = model_cfg.data_credit_np;
                tb_pcie_ref_design.root_x8.port0.tl0.SetInitTxCredits(0,i, FC_TYPE_NP, hdr_credit, data_credit);
                $msglog(LOG_INFO, "%sbasic_serial5: TEST_INFO Non-Posted hdr_credit = 0x%0h data_credit = 0x%0h enable_vc = 0x%0h config:",
                           DISPLAY_NAME, hdr_credit, data_credit, model_cfg.enable_vc[i]);
                hdr_credit = model_cfg.hdr_credit_cpl;
                data_credit = model_cfg.data_credit_cpl;
                tb_pcie_ref_design.root_x8.port0.tl0.SetInitTxCredits(0,i, FC_TYPE_CPL, hdr_credit, data_credit);
                $msglog(LOG_INFO, "%sbasic_serial5: TEST_INFO Completion hdr_credit = 0x%0h data_credit = 0x%0h enable_vc = 0x%0h config:",
                           DISPLAY_NAME, hdr_credit, data_credit, model_cfg.enable_vc[i]);

              end // if (model_cfg.enable_vc[i])
          end
      end

    for (i=1;i<8;i=i+1)
      begin
        if (model_cfg.enable_vc[i])
          begin
            case(i)
              0: 
                 begin
                   tb_pcie_ref_design.root_x8.port0.tl0.SetVcEnable(0,0,1);
                 
                 end
              1: 
                 begin
                   tb_pcie_ref_design.root_x8.port0.tl0.SetVcEnable(0,1,1);
                 
                 end
              2: 
                 begin
                   tb_pcie_ref_design.root_x8.port0.tl0.SetVcEnable(0,2,1);
                 
                 end
              3: 
                 begin
                   tb_pcie_ref_design.root_x8.port0.tl0.SetVcEnable(0,3,1);
                  
                 end
              4: 
                 begin
                   tb_pcie_ref_design.root_x8.port0.tl0.SetVcEnable(0,4,1);
                  
                 end
              5: 
                 begin
                   tb_pcie_ref_design.root_x8.port0.tl0.SetVcEnable(0,5,1);
                  
                 end
              6: 
                 begin
                   tb_pcie_ref_design.root_x8.port0.tl0.SetVcEnable(0,6,1);
                  
                 end
              7: 
                 begin
                   tb_pcie_ref_design.root_x8.port0.tl0.SetVcEnable(0,7,1);
                  
                 end
            endcase
          end // if(model_cfg.enable_vc[i])
      end // for(i=0....
    
    if (model_cfg.max_acknak_latency_timer != 0)
      begin
      
        tb_pcie_ref_design.root_x8.port0.dl0.SetMaxAttachedAckNakLatency(model_cfg.max_acknak_latency_timer);
      end
     if (model_cfg.min_acknak_latency_timer != 0)
      begin
       
        tb_pcie_ref_design.root_x8.port0.dl0.SetMinAttachedAckNakLatency(model_cfg.min_acknak_latency_timer);
      end



    // set up the requester ids in the root port
    tb_pcie_ref_design.root_x8.driver0.SetRequesterID(16'h0100); 
    tb_pcie_ref_design.root_x8.port0.tl0.AddRequesterIdApplIdMapEntry(16'h0100, tb_pcie_ref_design.root_x8.APPL_ID_DRIVER, tx_error);

    tb_pcie_ref_design.root_x8.port0.dl0.link_enable = 1;
    
    $display("TEST_INFO waiting for root link_enable");
    case(model_cfg.pcie_ep_max_speed)
       "PIPE_RATE_2_5G":
       begin
               wait (tb_pcie_ref_design.root_x8.port0.pl0_phy_ready == 1  && (tb_pcie_ref_design.root_x8.port0.pl0.local_rate == PIPE_RATE_2_5G)); // phy ready and local_rate=gen1
               $display("TEST_INFO done root phy_ready == 1 and root.port0.pl0.local_rate == pipe_rate_2_5G");
       end
       "PIPE_RATE_5G":
       begin
               wait (tb_pcie_ref_design.root_x8.port0.pl0_phy_ready == 1  && (tb_pcie_ref_design.root_x8.port0.pl0.local_rate == PIPE_RATE_5G)); // phy ready and local_rate=gen2
               $display("TEST_INFO done root phy_ready == 1 and root.port0.pl0.local_rate == pipe_rate_5G");
       end
       "PIPE_RATE_8G":
       begin
               wait (tb_pcie_ref_design.root_x8.port0.pl0_phy_ready == 1  && (tb_pcie_ref_design.root_x8.port0.pl0.local_rate == PIPE_RATE_8G)); // phy ready and local_rate=gen3
               $display("TEST_INFO done root phy_ready == 1 and root.port0.pl0.local_rate == pipe_rate_8G");
       end
       "PIPE_RATE_16G":
       begin
               wait (tb_pcie_ref_design.root_x8.port0.pl0_phy_ready == 1  && (tb_pcie_ref_design.root_x8.port0.pl0.local_rate == PIPE_RATE_16G)); // phy ready and local_rate=gen4
               $display("TEST_INFO done root phy_ready == 1 and root.port0.pl0.local_rate == pipe_rate_16G");
       end
       "PIPE_RATE_32G":
       begin
               wait (tb_pcie_ref_design.root_x8.port0.pl0_phy_ready == 1  && (tb_pcie_ref_design.root_x8.port0.pl0.local_rate == PIPE_RATE_32G)); // phy ready and local_rate=gen5
               $display("TEST_INFO done root phy_ready == 1 and root.port0.pl0.local_rate == pipe_rate_32G");
       end
       "PIPE_RATE_64G":
       begin
               wait (tb_pcie_ref_design.root_x8.port0.pl0_phy_ready == 1  && (tb_pcie_ref_design.root_x8.port0.pl0.local_rate == PIPE_RATE_64G)); // phy ready and local_rate=gen6
               $display("TEST_INFO done root phy_ready == 1 and root.port0.pl0.local_rate == pipe_rate_64G");
       end     
    endcase            
    wait (tb_pcie_ref_design.root_x8.port0.dl0_status == 1); // DL ready
    $display("TEST_INFO done root dl0_status == 1"); 

endtask


//===============================================================================================================
task MemRandWrRdComp1;
  input [63:0] address;
  input [31:0] length_in_dwords;
  input [31:0] tc;

  logic [31:0] command_num;
  logic [31:0] tx_driver_status;

  begin
    tb_pcie_ref_design.root_x16.driver0.USE_INTERNAL_DATA_BUFFERS_VAR = 1; // use the auto-allocated data buffers
    $msglog(LOG_INFO, "%sMemWr: Requesting a MEM WRITE, address = 0x%x, dwords = %0d, payload contents:",
                           DISPLAY_NAME, address, length_in_dwords);

    tb_pcie_ref_design.root_x16.driver0.QueueMemWrite(address,
                                   length_in_dwords,       // length of read
                                   4'hF,         // first DW BE
                                   4'hF,          // last DW BE
                                   tc,                     // traffic class 
                                   2'b0,                   // address translation
                                   1'b0,                   // error/poison
                                   32'h0,
                                   32'h0,          
                                   32'h0,    
                                   1'b1,                    //blocking
                                   command_num,
                                   tx_driver_status);
   

    $msglog(LOG_INFO, "%sMemRd: Requesting a MEM READ, address = 0x%x, dwords = %0d",
                       DISPLAY_NAME, address, length_in_dwords);
    tb_pcie_ref_design.root_x16.driver0.QueueMemRead(address,                 // address
                                  length_in_dwords,        // length of read
                                  4'hF,          // first dw be
                                  4'hF,           // last dw be
                                  tc,                      // traffic class
                                  2'b0,                    // address translation
                                  32'h0,                   // buffer ptr
                                  32'h0,                   // buffer len
                                  32'h0,              // ei code
                                  1'b1,                    // blocking
                                  command_num,          // transaction id
                                  tx_driver_status); 

    $msglog(LOG_INFO, "%sMemRd: Waiting for completion of the memory read (xid = %x)", DISPLAY_NAME, command_num);
    tb_pcie_ref_design.root_x16.driver0.WaitForCompletion(command_num,tx_driver_status);
  end

endtask

task NAPRandWrRdComp1;
  input [63:0] nap_base;
  input [3:0] col;
  input [2:0] row;
  input [31:0] length_in_dwords;
  input [31:0] tc;

  logic [31:0] command_num;
  logic [31:0] tx_driver_status;

  begin
    tb_pcie_ref_design.root_x16.driver0.USE_INTERNAL_DATA_BUFFERS_VAR = 1; // use the auto-allocated data buffers
    $msglog(LOG_INFO, "%sMemWr: Requesting a NAP WRITE, column = %0d, row = %0d, dwords = %0d, payload contents:",
                           DISPLAY_NAME, col, row, length_in_dwords);

    tb_pcie_ref_design.root_x16.driver0.QueueMemWrite({nap_base[63:35], col, row, nap_base[27:0]},
                                   length_in_dwords,       // length of read
                                   4'hF,         // first DW BE
                                   4'hF,          // last DW BE
                                   tc,                     // traffic class 
                                   2'b0,                   // address translation
                                   1'b0,                   // error/poison
                                   32'h0,
                                   32'h0,          
                                   32'h0,    
                                   1'b1,                    //blocking
                                   command_num,
                                   tx_driver_status);
   

    $msglog(LOG_INFO, "%sMemWr: Requesting a NAP READ, column = %0d, row = %0d, dwords = %0d, payload contents:",
                           DISPLAY_NAME, col, row, length_in_dwords);
    tb_pcie_ref_design.root_x16.driver0.QueueMemRead({nap_base[63:35], col, row, nap_base[27:0]},                 // address
                                  length_in_dwords,        // length of read
                                  4'hF,          // first dw be
                                  4'hF,           // last dw be
                                  tc,                      // traffic class
                                  2'b0,                    // address translation
                                  32'h0,                   // buffer ptr
                                  32'h0,                   // buffer len
                                  32'h0,              // ei code
                                  1'b1,                    //blocking
                                  command_num,          // transaction id
                                  tx_driver_status); 

    $msglog(LOG_INFO, "%sMemRd: Waiting for completion of the memory read (xid = %x)", DISPLAY_NAME, command_num);
    tb_pcie_ref_design.root_x16.driver0.WaitForCompletion(command_num,tx_driver_status);
  end

endtask

task NAPRandWrRdCompDW1;
  input [63:0] nap_base;
  input [3:0] col;
  input [2:0] row;
  input [31:0] tc;

  logic [31:0] command_num;
  logic [31:0] tx_driver_status;

  begin
    tb_pcie_ref_design.root_x16.driver0.USE_INTERNAL_DATA_BUFFERS_VAR = 1; // use the auto-allocated data buffers
    $msglog(LOG_INFO, "%sMemWr: Requesting a NAP WRITE, column = %0d, row = %0d, dwords = %0d, payload contents:",
                           DISPLAY_NAME, col, row, 1);

    tb_pcie_ref_design.root_x16.driver0.QueueMemWrite({nap_base[63:35], col, row, nap_base[27:0]},
                                   32'h1,       // length of read
                                   4'hF,         // first DW BE
                                   4'h0,          // last DW BE
                                   tc,                     // traffic class 
                                   2'b0,                   // address translation
                                   1'b0,                   // error/poison
                                   32'h0,
                                   32'h0,          
                                   32'h0,    
                                   1'b1,                    //blocking
                                   command_num,
                                   tx_driver_status);
   

    $msglog(LOG_INFO, "%sMemWr: Requesting a NAP READ, column = %0d, row = %0d, dwords = %0d, payload contents:",
                           DISPLAY_NAME, col, row, 1);
    tb_pcie_ref_design.root_x16.driver0.QueueMemRead({nap_base[63:35], col, row, nap_base[27:0]},                 // address
                                  32'h1,        // length of read
                                  4'hF,          // first dw be
                                  4'h0,           // last dw be
                                  tc,                      // traffic class
                                  2'b0,                    // address translation
                                  32'h0,                   // buffer ptr
                                  32'h0,                   // buffer len
                                  32'h0,              // ei code
                                  1'b1,                    //blocking
                                  command_num,          // transaction id
                                  tx_driver_status); 

    $msglog(LOG_INFO, "%sMemRd: Waiting for completion of the memory read (xid = %x)", DISPLAY_NAME, command_num);
    tb_pcie_ref_design.root_x16.driver0.WaitForCompletion(command_num,tx_driver_status);
  end

endtask

task NAPRdCompDW1;
  input [63:0] nap_base;
  input [3:0] col;
  input [2:0] row;
  input [31:0] tc;
  input [31:0] expected_rd_data;

  logic [31:0] command_num;
  logic [31:0] tx_driver_status;

  reg [31:0] buffer_ptr;
  reg [31:0] buffer_len;
  logic [31:0] swapped_expected_data;

  begin
    tb_pcie_ref_design.root_x16.driver0.USE_INTERNAL_DATA_BUFFERS_VAR = 0; // Turn off auto-allocated data buffers
    swapped_expected_data = {expected_rd_data[7:0],
                             expected_rd_data[15:8],
                             expected_rd_data[23:16],
                             expected_rd_data[31:24]};
    buffer_len = 4;
    `PCIESVC_MEM_PATH.AllocateMemory(DISPLAY_NAME, buffer_len, buffer_ptr);

    `PCIESVC_MEM_PATH.WriteMemory(DISPLAY_NAME,buffer_ptr,swapped_expected_data,4);


     $display ($time, ": Fake write to read-only Registers to setup for subsequent read.");

    tb_pcie_ref_design.root_x16.driver0.QueueMemWrite({nap_base[63:35], col, row, nap_base[27:0]},
                                   32'h1,       // length of read
                                   4'hF,         // first DW BE
                                   4'h0,          // last DW BE
                                   tc,                     // traffic class 
                                   2'b0,                   // address translation
                                   1'b0,                   // error/poison
                                   buffer_ptr,
                                   buffer_len,          
                                   32'h0,    
                                   1'b1,                    //blocking
                                   command_num,
                                   tx_driver_status);
   

    $msglog(LOG_INFO, "%sMemWr: Requesting a NAP READ, column = %0d, row = %0d, dwords = %0d, expected data is: 0x%0h",
                           DISPLAY_NAME, col, row, 1, expected_rd_data);
    tb_pcie_ref_design.root_x16.driver0.QueueMemRead({nap_base[63:35], col, row, nap_base[27:0]},                 // address
                                  32'h1,        // length of read
                                  4'hF,          // first dw be
                                  4'h0,           // last dw be
                                  tc,                      // traffic class
                                  2'b0,                    // address translation
                                  buffer_ptr,                   // buffer ptr
                                  buffer_len,                   // buffer len
                                  32'h0,              // ei code
                                  1'b1,                    //blocking
                                  command_num,          // transaction id
                                  tx_driver_status); 

    $msglog(LOG_INFO, "%sMemRd: Waiting for completion of the memory read (xid = %x)", DISPLAY_NAME, command_num);
    tb_pcie_ref_design.root_x16.driver0.WaitForCompletion(command_num,tx_driver_status);
  end

endtask

task NAPWrDW1;
  input [63:0] nap_base;
  input [3:0] col;
  input [2:0] row;
  input [31:0] tc;
  input [31:0] wr_data;

  logic [31:0] command_num;
  logic [31:0] tx_driver_status;

  reg [31:0] buffer_ptr;
  reg [31:0] buffer_len;
  logic [31:0] swapped_wr_data;

  begin
    tb_pcie_ref_design.root_x16.driver0.USE_INTERNAL_DATA_BUFFERS_VAR = 0; // Turn off auto-allocated data buffers
    swapped_wr_data = {wr_data[7:0],
                       wr_data[15:8],
                       wr_data[23:16],
                       wr_data[31:24]};
    buffer_len = 4;
    `PCIESVC_MEM_PATH.AllocateMemory(DISPLAY_NAME, buffer_len, buffer_ptr);

    `PCIESVC_MEM_PATH.WriteMemory(DISPLAY_NAME,buffer_ptr,swapped_wr_data,4);


     $display ($time, ": Write to a single DW");

    tb_pcie_ref_design.root_x16.driver0.QueueMemWrite({nap_base[63:35], col, row, nap_base[27:0]},
                                   32'h1,       // length of read
                                   4'hF,         // first DW BE
                                   4'h0,          // last DW BE
                                   tc,                     // traffic class 
                                   2'b0,                   // address translation
                                   1'b0,                   // error/poison
                                   buffer_ptr,
                                   buffer_len,          
                                   32'h0,    
                                   1'b1,                    //blocking
                                   command_num,
                                   tx_driver_status);
    $msglog(LOG_INFO, "%sMemRd: Waiting for completion of the memory read (xid = %x)", DISPLAY_NAME, command_num);
    tb_pcie_ref_design.root_x16.driver0.WaitForCompletion(command_num,tx_driver_status);
    tb_pcie_ref_design.root_x16.driver0.ENABLE_SHADOW_MEMORY_CHECKING_VAR = 1;
    $display ($time, ": Extra delay before next Write");
    #200ns;
  end

endtask

task NAPRdDW1;
  input [63:0] nap_base;
  input [3:0] col;
  input [2:0] row;
  input [31:0] tc;
  output [31:0] rd_data;

  logic [31:0] command_num;
  logic [31:0] tx_driver_status;

  reg [31:0] buffer_ptr;
  reg [31:0] buffer_len;
  logic [31:0] swapped_rd_data;

  begin
    tb_pcie_ref_design.root_x16.driver0.USE_INTERNAL_DATA_BUFFERS_VAR = 0; // Turn off auto-allocated data buffers
    tb_pcie_ref_design.root_x16.driver0.ENABLE_SHADOW_MEMORY_CHECKING_VAR = 0; //Turn off data compare
    buffer_len = 4;
    `PCIESVC_MEM_PATH.AllocateMemory(DISPLAY_NAME, buffer_len, buffer_ptr);

     $display ($time, ": Read a single DW");

    tb_pcie_ref_design.root_x16.driver0.QueueMemRead({nap_base[63:35], col, row, nap_base[27:0]},                 // address
                                  32'h1,        // length of read
                                  4'hF,          // first dw be
                                  4'h0,           // last dw be
                                  tc,                      // traffic class
                                  2'b0,                    // address translation
                                  buffer_ptr,                   // buffer ptr
                                  buffer_len,                   // buffer len
                                  32'h0,              // ei code
                                  1'b1,                    // blocking
                                  command_num,          // transaction id
                                  tx_driver_status); 
    tb_pcie_ref_design.root_x16.driver0.WaitForCompletion(command_num,tx_driver_status);
    `PCIESVC_MEM_PATH.ReadMemory(DISPLAY_NAME,buffer_ptr,swapped_rd_data);
    rd_data = {swapped_rd_data[7:0],
               swapped_rd_data[15:8],
               swapped_rd_data[23:16],
               swapped_rd_data[31:24]};

    tb_pcie_ref_design.root_x16.driver0.ENABLE_SHADOW_MEMORY_CHECKING_VAR = 1; //Turn on data compare
  end

endtask


task DoInitLinkUpRcEp1(pciesvc_device_serdes_x16_model_config model_cfg);
  bit [31:0] cfg_data;
  bit        tx_error;
  int hdr_credit, data_credit,i; 
    
    // Bring SVC/Dut out of reset.
    #1;  // Can set _VARs after 2ns.
    $msglog_suppress("tb_pcie_ref_design.endpoint0.port0.serdes0", MSGCODE_PCIESVC_SERDES_BYTE_UNLOCK, 0, 0);
    $msglog_suppress("tb_pcie_ref_design.endpoint0.port0.serdes1", MSGCODE_PCIESVC_SERDES_BYTE_UNLOCK, 0, 0);
    $msglog_suppress("tb_pcie_ref_design.endpoint0.port0.serdes2", MSGCODE_PCIESVC_SERDES_BYTE_UNLOCK, 0, 0);
    $msglog_suppress("tb_pcie_ref_design.endpoint0.port0.serdes3", MSGCODE_PCIESVC_SERDES_BYTE_UNLOCK, 0, 0);
    $msglog_suppress("tb_pcie_ref_design.root_x16.port0.serdes0", MSGCODE_PCIESVC_SERDES_BYTE_UNLOCK, 0, 0);
    $msglog_suppress("tb_pcie_ref_design.root_x16.port0.serdes1", MSGCODE_PCIESVC_SERDES_BYTE_UNLOCK, 0, 0);
    $msglog_suppress("tb_pcie_ref_design.root_x16.port0.serdes2", MSGCODE_PCIESVC_SERDES_BYTE_UNLOCK, 0, 0);
    $msglog_suppress("tb_pcie_ref_design.root_x16.port0.serdes3", MSGCODE_PCIESVC_SERDES_BYTE_UNLOCK, 0, 0);
    

`ifdef PCIESVC_INCLUDE_PA
    cfg_data = 0;
    cfg_data[PA_TRANSACTION_MODE_TRANSACTION_LOGGING_ENABLED_BIT] = 1;
    tb_pcie_ref_design.root_x16.port0.tl0.SetPATransactionMode(cfg_data);
    
    cfg_data = 0;
    cfg_data[PA_LINK_MODE_PACKET_LOGGING_ENABLED_BIT] = 1;
    cfg_data[PA_LINK_MODE_PAYLOAD_LOGGING_ENABLED_BIT] = 1;
    tb_pcie_ref_design.root_x16.port0.dl0.SetPALinkMode(cfg_data);
    
    cfg_data = 0;
    cfg_data[PA_PHY_MODE_OS_LOGGING_ENABLED_BIT] = 1;
    cfg_data[PA_PHY_MODE_LTSSM_LOGGING_ENABLED_BIT] = 1;
    tb_pcie_ref_design.root_x16.port0.pl0.SetPAPhyMode(cfg_data);

`endif

    //To handle: 
    //WARNING: root_x16.port0.pl0.LTSSMStateMachine: Timeout in state LTSSM_POLLING_ACTIVE as conditions to transition to state Polling.Configuration or Polling.Compliance are not met. VIP will now transition back to state Detect.Quiet
    //INFO:    SNPS_PCIE_VIP_DEBUG_TIP: The parameter POLLING_ACTIVE_TIMEOUT_NS is set to 240000. If DUT is functioning correctly and the conditions to transition to state Polling.Configuration or Polling.Compliance will take more time then increase POLLING_ACTIVE_TIMEOUT_NS to avoid this timeout.

    tb_pcie_ref_design.root_x16.port0.pl0.POLLING_ACTIVE_TIMEOUT_NS_VAR = 480000;
    $display("TEST_INFO setting POLLING_ACTIVE_TIMEOUT_NS_VAR to 480000");
    DoReset;
 
    tb_pcie_ref_design.root_x16.port0.pl0.PCIE_SPEC_VER_VAR = PCIE_SPEC_VER_5_0;

    tb_pcie_ref_design.root_x16.port0.tl0.PCIE_SPEC_VER_VAR = PCIE_SPEC_VER_5_0;

    tb_pcie_ref_design.root_x16.port0.dl0.PCIE_SPEC_VER_VAR = PCIE_SPEC_VER_5_0;


    $display("TEST_INFO setting PCIE_SPEC_VER_5_0");
    tb_pcie_ref_design.root_x16.port0.tl0.REMOTE_MAX_PAYLOAD_SIZE_VAR = model_cfg.max_payload_size;
    tb_pcie_ref_design.root_x16.port0.tl0.REMOTE_MAX_READ_REQUEST_SIZE_VAR = model_cfg.max_payload_size;
    tb_pcie_ref_design.root_x16.port0.dl0.MAX_PAYLOAD_SIZE_VAR = model_cfg.max_payload_size;
    tb_pcie_ref_design.root_x16.requester0.MAX_DATA_LEN_IN_BYTES_VAR = model_cfg.max_payload_size;

    $msglog(LOG_INFO, "%sbasic_serial5: TEST_INFO max_payload_size config = %0d:",
                           DISPLAY_NAME, model_cfg.max_payload_size);

    tb_pcie_ref_design.root_x16.driver0.PERCENTAGE_USE_TLP_DIGEST_VAR = model_cfg.root_digest_percentage;

    $msglog(LOG_INFO, "%sbasic_serial5: TEST_INFO root_digest_percentage config = %0d:",
                           DISPLAY_NAME, model_cfg.root_digest_percentage);
    // TODO: How to set endpoint digest percentage? 
    //
    tb_pcie_ref_design.root_x16.port0.pl0.SetSupportedSpeeds(model_cfg.root_supported_speeds); 

    $msglog(LOG_INFO, "%sbasic_serial5: TEST_INFO root_supported_speeds config = %0d:",
                           DISPLAY_NAME, model_cfg.root_supported_speeds);

    tb_pcie_ref_design.root_x16.port0.pl0.SetLinkWidth(model_cfg.root_link_width);

    $msglog(LOG_INFO, "%sbasic_serial5: TEST_INFO root_link_width config = %0d:",
                           DISPLAY_NAME, model_cfg.root_link_width);
     
    tb_pcie_ref_design.root_x16.port0.dl0.ENABLE_EI_TX_TLP_ON_RETRY_VAR = model_cfg.en_retry_ei;

     $msglog(LOG_INFO, "%sbasic_serial5: TEST_INFO en_retry_ei config = %0d:",
                           DISPLAY_NAME, model_cfg.en_retry_ei);

     if (|model_cfg.enable_vc[7:1])
      begin
        for (i=1;i<8;i=i+1)
          begin
            if (model_cfg.enable_vc[i])
              begin
                hdr_credit = model_cfg.hdr_credit_p;
                data_credit = model_cfg.data_credit_p;
                tb_pcie_ref_design.root_x16.port0.tl0.SetInitTxCredits(0,i, FC_TYPE_P, hdr_credit, data_credit);
                $msglog(LOG_INFO, "%sbasic_serial5: TEST_INFO Posted hdr_credit = 0x%0h data_credit = 0x%0h enable_vc = 0x%0h config:",
                           DISPLAY_NAME, hdr_credit, data_credit, model_cfg.enable_vc[i]);
                hdr_credit = model_cfg.hdr_credit_np;
                data_credit = model_cfg.data_credit_np;
                tb_pcie_ref_design.root_x16.port0.tl0.SetInitTxCredits(0,i, FC_TYPE_NP, hdr_credit, data_credit);
                $msglog(LOG_INFO, "%sbasic_serial5: TEST_INFO Non-Posted hdr_credit = 0x%0h data_credit = 0x%0h enable_vc = 0x%0h config:",
                           DISPLAY_NAME, hdr_credit, data_credit, model_cfg.enable_vc[i]);
                hdr_credit = model_cfg.hdr_credit_cpl;
                data_credit = model_cfg.data_credit_cpl;
                tb_pcie_ref_design.root_x16.port0.tl0.SetInitTxCredits(0,i, FC_TYPE_CPL, hdr_credit, data_credit);
                $msglog(LOG_INFO, "%sbasic_serial5: TEST_INFO Completion hdr_credit = 0x%0h data_credit = 0x%0h enable_vc = 0x%0h config:",
                           DISPLAY_NAME, hdr_credit, data_credit, model_cfg.enable_vc[i]);

              end // if (model_cfg.enable_vc[i])
          end
      end

    for (i=1;i<8;i=i+1)
      begin
        if (model_cfg.enable_vc[i])
          begin
            case(i)
              0: 
                 begin
                   tb_pcie_ref_design.root_x16.port0.tl0.SetVcEnable(0,0,1);
                 
                 end
              1: 
                 begin
                   tb_pcie_ref_design.root_x16.port0.tl0.SetVcEnable(0,1,1);
                 
                 end
              2: 
                 begin
                   tb_pcie_ref_design.root_x16.port0.tl0.SetVcEnable(0,2,1);
                 
                 end
              3: 
                 begin
                   tb_pcie_ref_design.root_x16.port0.tl0.SetVcEnable(0,3,1);
                  
                 end
              4: 
                 begin
                   tb_pcie_ref_design.root_x16.port0.tl0.SetVcEnable(0,4,1);
                  
                 end
              5: 
                 begin
                   tb_pcie_ref_design.root_x16.port0.tl0.SetVcEnable(0,5,1);
                  
                 end
              6: 
                 begin
                   tb_pcie_ref_design.root_x16.port0.tl0.SetVcEnable(0,6,1);
                  
                 end
              7: 
                 begin
                   tb_pcie_ref_design.root_x16.port0.tl0.SetVcEnable(0,7,1);
                  
                 end
            endcase
          end // if(model_cfg.enable_vc[i])
      end // for(i=0....
    
    if (model_cfg.max_acknak_latency_timer != 0)
      begin
      
        tb_pcie_ref_design.root_x16.port0.dl0.SetMaxAttachedAckNakLatency(model_cfg.max_acknak_latency_timer);
      end
     if (model_cfg.min_acknak_latency_timer != 0)
      begin
       
        tb_pcie_ref_design.root_x16.port0.dl0.SetMinAttachedAckNakLatency(model_cfg.min_acknak_latency_timer);
      end



    // set up the requester ids in the root port
    tb_pcie_ref_design.root_x16.driver0.SetRequesterID(16'h0100); 
    tb_pcie_ref_design.root_x16.port0.tl0.AddRequesterIdApplIdMapEntry(16'h0100, tb_pcie_ref_design.root_x16.APPL_ID_DRIVER, tx_error);

    tb_pcie_ref_design.root_x16.port0.dl0.link_enable = 1;
    
    $display("TEST_INFO waiting for root link_enable");
    case(model_cfg.pcie_ep_max_speed)
       "PIPE_RATE_2_5G":
       begin
               wait (tb_pcie_ref_design.root_x16.port0.pl0_phy_ready == 1  && (tb_pcie_ref_design.root_x16.port0.pl0.local_rate == PIPE_RATE_2_5G)); // phy ready and local_rate=gen1
               $display("TEST_INFO done root phy_ready == 1 and root.port0.pl0.local_rate == pipe_rate_2_5G");
       end
       "PIPE_RATE_5G":
       begin
               wait (tb_pcie_ref_design.root_x16.port0.pl0_phy_ready == 1  && (tb_pcie_ref_design.root_x16.port0.pl0.local_rate == PIPE_RATE_5G)); // phy ready and local_rate=gen2
               $display("TEST_INFO done root phy_ready == 1 and root.port0.pl0.local_rate == pipe_rate_5G");
       end
       "PIPE_RATE_8G":
       begin
               wait (tb_pcie_ref_design.root_x16.port0.pl0_phy_ready == 1  && (tb_pcie_ref_design.root_x16.port0.pl0.local_rate == PIPE_RATE_8G)); // phy ready and local_rate=gen3
               $display("TEST_INFO done root phy_ready == 1 and root.port0.pl0.local_rate == pipe_rate_8G");
       end
       "PIPE_RATE_16G":
       begin
               wait (tb_pcie_ref_design.root_x16.port0.pl0_phy_ready == 1  && (tb_pcie_ref_design.root_x16.port0.pl0.local_rate == PIPE_RATE_16G)); // phy ready and local_rate=gen4
               $display("TEST_INFO done root phy_ready == 1 and root.port0.pl0.local_rate == pipe_rate_16G");
       end
       "PIPE_RATE_32G":
       begin
               wait (tb_pcie_ref_design.root_x16.port0.pl0_phy_ready == 1  && (tb_pcie_ref_design.root_x16.port0.pl0.local_rate == PIPE_RATE_32G)); // phy ready and local_rate=gen5
               $display("TEST_INFO done root phy_ready == 1 and root.port0.pl0.local_rate == pipe_rate_32G");
       end
       "PIPE_RATE_64G":
       begin
               wait (tb_pcie_ref_design.root_x16.port0.pl0_phy_ready == 1  && (tb_pcie_ref_design.root_x16.port0.pl0.local_rate == PIPE_RATE_64G)); // phy ready and local_rate=gen6
               $display("TEST_INFO done root phy_ready == 1 and root.port0.pl0.local_rate == pipe_rate_64G");
       end     
    endcase            
    wait (tb_pcie_ref_design.root_x16.port0.dl0_status == 1); // DL ready
    $display("TEST_INFO done root dl0_status == 1"); 

endtask
