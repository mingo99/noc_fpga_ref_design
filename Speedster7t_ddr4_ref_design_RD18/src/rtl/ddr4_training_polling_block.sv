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
//      DDR PHY Training block
//      This will perform write and read leveling after the DDR firmware
//      has been loaded.
// ------------------------------------------------------------------

`timescale 1ps/1ps

module ddr4_training_polling_block (
                                    // Inputs
                                    input wire        i_clk,
                                    input wire        i_resetn,
                                    // Output
                                    output wire       training_done
                                   );
   
 
/// Register and wire declaration ///

logic    [41:0]    cfg_addr         ;   /// Address to axi_nap_csr_master_ddr block
logic              cfg_wr_rdn       ;   /// Write or read signal for axi_nap_csr_master_ddr block
logic              cfg_req          ;   /// Request signal for axi_nap_csr_master_ddr block
logic              cfg_ack          ;   /// Acknowledgement coming from axi_nap_csr_master_ddr block
logic    [31:0]    cfg_rdata        ;   /// Reading data from APB clock through axi_nap_csr_master_ddr block
logic    [31:0]    cfg_wdata        ;   /// Write data to APB register through axi_nap_csr_master_ddr block
logic              train_done_reg   ;   /// Training done signal
logic              poll_dfi_status  ;   /// Check dfi status
logic              poll_sw_done     ;   /// Polling software done signal
logic              poll_op_mode     ;   /// Polling operation mode signal
logic              start_axi_reg    ;   /// Final stage after polling, full training is complete

logic    [5:0]     counter_block1   ;   // Counter to delay start of training sequence
                                        // After DDR is configured via FCU, there is a DDR reset issued internally
                                        // This block needs to wait until after that reset has been deasserted

localparam  WRITE1_REG_ADDR      = 42'h080_9134_0000 ;    // Write 0X1
localparam  WRITE2_REG_ADDR      = 42'h080_9134_0264 ;    // Write 0X9
localparam  WRITE3_REG_ADDR      = 42'h080_9134_0264 ;    // Write 0X1
localparam  WRITE4_REG_ADDR      = 42'h080_9134_0264 ;    // Write 0X0
localparam  POLL_TRAIN_ADDR      = 42'h080_9134_0010 ;    // Read  0X07; if we read 0XFF, then firmware fails
localparam  PMU_MSG_READ_ADDR_C8 = 42'h080_9134_00c8 ;    // If we read 0x2, then read PMU messages
localparam  PMU_MSG_READ_ADDR_C4 = 42'h080_9134_00c4 ;    // Set shadow flag to proceed after reading PMU messages
localparam  WRITE1_DFI_INIT      = 42'h080_9000_01b0 ;    // Write 0X71
localparam  POLL_DFI_STATUS      = 42'h080_9000_01bc ;    // Read DFI-STATUS. Read eithe of 01/10/11
localparam  WRITE2_DFI_MISC      = 42'h080_9000_01b0 ;    // Write 0X51
localparam  WRITE3_DBG_REG1      = 42'h080_9000_0304 ;    // Write 0X0
localparam  WRITE4_SW_CNTRL      = 42'h080_9000_0320 ;    // Write 0X0
localparam  POLL_SW_DONE         = 42'h080_9000_0324 ;    // READ  0X01, If read 0X01, then software polling is done, else stay in this state
localparam  POLL_OP_MODE         = 42'h080_9000_0004 ;    // READ  bits[1:0] == 0X01 OR 0X03. IF READ 0X01 OR 0X03, THEN OPERATING_MODE IS DONE. ELSE IN THIS STATE
localparam  WRITE1_MEMC          = 42'h080_9000_0490 ;    // Write 0X01
localparam  WRITE2_MEMC          = 42'h080_9000_0540 ;    // Write 0X01
localparam  WRITE3_MEMC          = 42'h080_9000_0030 ;    // Write 0x01. Exit from self refresh
localparam  WRITE4_FINAL         = 42'h080_9130_0200 ;    // Write 0X00. After this, "start_axi_reg" will be asserted to 1'b1

localparam  EXPECTED_VAL0        = 32'h0000_00FF     ;    // Read FF menas firmware failure
localparam  EXPECTED_CORR        = 32'h0000_0007     ;    // Read 07 means training done has happened


enum {TRAIN_IDLE, WAIT, WR1_REG, WAIT1, WR2_REG, WAIT2, WR3_REG, WAIT3, WR4_REG, WAIT4, POLL_TRAIN, POLL_TRAIN_WAIT5, POLL_TRAIN_3, RD_POLL_TRAIN_3, 
      POLL_TRAIN_2, RD_POLL_TRAIN_2, RD_ADDR_C8, WAIT_RD_ADDR_C8, WR0_ADDR_C4, WAIT_WR0_ADDR_C4, RD_NXT_POLL_TRAIN_2, WT_NXT_POLL_TRAIN_2, WR1_ADDR_C4, 
      WAIT_WR1_ADDR_C4, WR1_DFI_INIT, WAIT6, POLL_DFI_STAT, POLL_DFI_WAIT7, WR2_DFI_MISC, WAIT8, WR3_DBG_REG1, WAIT9, WR4_SW_CNTL, WAIT10, POLL_SW_DN, 
      POLL_SW_DN_WAIT11, POLL_OP_MD, POLL_OP_MD_WAIT12, WR1_MEMC, WAIT13, WR2_MEMC, WAIT14, WR3_MEMC, WAIT15, FINAL_WR, WAIT16, FINAL_ST, ERROR_ST} poll_state ;


// Counter block for 10cycles for write 
always @ (posedge i_clk or negedge i_resetn)
   begin
      if (i_resetn == 1'b0)
         counter_block1 <= 4'h0 ;
      else if (counter_block1 < 6'h3f)
         counter_block1 <= counter_block1 + 1 ;
end

// NAP Instantiation 
axi_nap_csr_master_ddr #(
                       .CFG_ADDR_WIDTH  (28)
                      ,.CFG_DATA_WIDTH  (32)
                    ) i_axi_nap_csr_master (
                       .i_cfg_clk       (i_clk)             // Config block
                      ,.i_cfg_reset_n   (i_resetn)          // Asynchronous config reset
                      ,.i_cfg_tgt_id    (6'b00_1001)
                      ,.i_cfg_wr_rdn    (cfg_wr_rdn)        // Write/read signl, 1'b1 for write and 1'b0 for read
                      ,.i_cfg_addr      (cfg_addr[27:0])    // DDR4 IP address for training
                      ,.i_cfg_wdata     (cfg_wdata)         // Config write data
                      ,.i_cfg_req       (cfg_req)           // Config request
                      ,.o_cfg_rdata     (cfg_rdata)         // Config read data
                      ,.o_cfg_ack       (cfg_ack)           // Config acknowledgement
                    ) ;

   
// Start FSM
// The state machine implements write-leveling and read-leveling algorithm

always @ (posedge i_clk or negedge i_resetn)
   begin
      if (i_resetn == 1'b0)
         begin
            poll_state      <= TRAIN_IDLE ;
            cfg_wr_rdn      <= 1'b0       ;
            cfg_addr        <= 42'd0      ;
            cfg_wdata       <= 32'd0      ;
            cfg_req         <= 1'b0       ;
            train_done_reg  <= 1'b0       ;
            poll_dfi_status <= 1'b0       ;
            poll_sw_done    <= 1'b0       ;
            poll_op_mode    <= 1'b0       ;
            start_axi_reg   <= 1'b0       ;
         end else begin    // if (i_resetn == 1'b1)
            casez (poll_state)
               // When bitsream write is completed and device is in USER-MODE. (chip_ready from FPGA will go high), the FSM will start
               TRAIN_IDLE:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin
                           if (counter_block1 == 6'h3d) begin
                              cfg_wr_rdn <= 1'b1 ;
                              cfg_addr   <= WRITE1_REG_ADDR ;
                              cfg_wdata  <= 32'h0000_0001;
                              poll_state <= WAIT ;
                              cfg_req    <= 1'b1 ;
                           end else
                              poll_state <= TRAIN_IDLE ;
                        end   // (start_axi_reg == 1'b0)
                  end  
              
               // This is a wait state to observe acknowledgement from previous request from previous state. IF ack comes then state will switch to next state
               WAIT:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin
                           cfg_wr_rdn <= 1'b0 ;
                           if (cfg_ack == 1'b1)
                              begin
                                 cfg_req    <= 1'b0 ;
                                 cfg_wr_rdn <= 1'b1 ;
                                 poll_state <= WR1_REG ;
                              end
                        end
                  end

               //  Writing to location 0X1340000 with a value of 0X0000_0001 //
               WR1_REG:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                              cfg_wr_rdn <=  1'b1 ;
                              cfg_addr   <=  WRITE1_REG_ADDR ;
                              cfg_wdata  <=  32'h0000_0001   ;
                              cfg_req    <=  1'b1            ;
                              poll_state <=  WAIT1           ;
                        end     // if (start_axi_reg == 1'b0)
                  end          
    
               // This is a wait state to observe acknowledgement from previous request from previous state. IF ack comes then state will switch to next state
               WAIT1:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin
                           cfg_wr_rdn <= 1'b0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req    <= 1'b0 ;
                              cfg_wr_rdn <= 1'b1 ;
                              cfg_addr   <= WRITE2_REG_ADDR ;
                              cfg_wdata  <= 32'h0000_0009;
                              poll_state <= WR2_REG ;
                           end else begin
                              poll_state <= WAIT1 ;
                           end
                        end
                  end
               
               // Writing to location with a value of 0X0000_0009
               WR2_REG:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                              cfg_wr_rdn <=  1'b1 ;
                              cfg_addr   <=  WRITE2_REG_ADDR ;
                              cfg_wdata  <=  32'h0000_0009 ;
                              cfg_req    <=  1'b1 ;
                              poll_state <=  WAIT2 ;
                        end
                  end

               // This is a wait state to observe acknowledgement from previous request from previous state. IF ack comes then state will switch to next state //
               WAIT2:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin
                           cfg_wr_rdn <= 1'b0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req    <= 1'b0 ;
                              cfg_addr   <= WRITE3_REG_ADDR ;
                              cfg_wr_rdn <= 1'b1 ;
                              cfg_wdata  <= 32'h0000_0001 ;
                              poll_state <= WR3_REG ;
                           end else begin
                              poll_state <= WAIT2 ;
                           end
                        end
                  end
               
               // Writing to location 0X1340264 with a value of 0X0000_0001
               WR3_REG:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                              cfg_wr_rdn <=  1'b1 ;
                              cfg_addr   <=  WRITE3_REG_ADDR ;
                              cfg_wdata  <=  32'h0000_0001   ;
                              cfg_req    <=  1'b1            ;
                              poll_state <=  WAIT3           ;
                        end
                  end

               // This is a wait state to observe acknowledgement from previous request from previous state. IF ack comes then state will switch to next state
               WAIT3:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin
                           cfg_wr_rdn <= 1'b0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req    <= 1'b0 ;
                              cfg_wr_rdn <= 1'b1 ;
                              cfg_addr   <= WRITE4_REG_ADDR ;
                              poll_state <= WR4_REG ;
                           end else begin
                              poll_state <= WAIT3 ;
                           end
                        end
                  end
               
               // Writing 0X0000_0000 to location 0X1340264
               WR4_REG:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                              cfg_wr_rdn <=  1'b1 ;
                              cfg_addr   <=  WRITE4_REG_ADDR ;
                              cfg_wdata  <=  32'd0           ;
                              cfg_req    <=  1'b1            ;
                              poll_state <=  WAIT4           ;
                        end
                  end

               // This is a wait state to observe acknowledgement from previous request from previous state. IF ack comes then state will switch to next state
               WAIT4:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin
                           cfg_wr_rdn <= 1'b0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req    <= 1'b0 ;
                              cfg_addr   <= POLL_TRAIN_ADDR ;
                              poll_state <= POLL_TRAIN ;
                           end else begin
                              poll_state <= WAIT4 ;
                           end
                        end
                  end
              
               // Based on the above address locations' written values, controller now does polling training to observe completion
               POLL_TRAIN:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                           cfg_wr_rdn <=  1'b0 ;
                           cfg_addr   <=  POLL_TRAIN_ADDR ;
                           cfg_wdata  <=  32'h0000_0003;
                           cfg_req    <=  1'b1            ;
                           poll_state <=  POLL_TRAIN_WAIT5  ;
                        end
                  end

               // In this state APB read data will observe 0X0000_0007, which is expected value and state machine will indicate firmware training is completed
               // and go to DFI interface for further training. If APB read data is 0X0000_00FF, this indicates firmware failed and config file will need amendment
               // If read data is 0X0000_0003, then move to "POLL-TRAIN-3" state for training based on algorithm
               POLL_TRAIN_WAIT5:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin  
                           cfg_wr_rdn <= 1'b0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req    <=  1'b0            ;
                              if (cfg_rdata[31:0] == EXPECTED_CORR) begin
                                 poll_state <=  WR1_DFI_INIT      ;
                                 cfg_wr_rdn <=  1'b1 ;
                                 cfg_addr   <=  WRITE1_DFI_INIT ;
                                 cfg_wdata  <=  32'h0000_0071  ;
                                 train_done_reg <= 1'b1  ;
                                 $display("%t : Firmware training completed. Advance to next step", $time);
                              end else if (cfg_rdata[31:0] == EXPECTED_VAL0) begin
                                 poll_state <= ERROR_ST ;
                                 train_done_reg <= 1'b0 ;
                                 $display("Firmware training failed at %t", $time);
                                 $stop ;
                              end else if (cfg_rdata[31:0] == 32'h3) begin
                                 poll_state <= POLL_TRAIN_3 ;
                                 train_done_reg <= 1'b0 ;
                              end else begin
                                 poll_state <= POLL_TRAIN ;
                                 train_done_reg <= 1'b0 ;
                              end
                           end
                     end
                  end   
               
               // In this state, algorithm will perform read delay center optimization
               POLL_TRAIN_3:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                           cfg_wr_rdn <=  1'b0 ;
                           cfg_addr   <=  POLL_TRAIN_ADDR ;
                           cfg_wdata  <=  32'h0000_0003 ;
                           cfg_req    <=  1'b1            ;
                           poll_state <=  RD_POLL_TRAIN_3  ;
                        end
                  end

               // FSM will move to end of read enable training
               RD_POLL_TRAIN_3:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin  
                           cfg_wr_rdn <= 1'b0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req    <=  1'b0            ;
                              if (cfg_rdata[31:0] == 32'h0000_0002) begin
                                 poll_state <=  POLL_TRAIN_2 ;
                                 cfg_wr_rdn <=  1'b0 ;
                                 cfg_addr   <=  POLL_TRAIN_ADDR ;
                                 cfg_wdata  <=  32'h0000_0002   ;
                              end else begin
                                 poll_state <= POLL_TRAIN_3 ;
                                 train_done_reg <= 1'b0 ;
                              end
                           end
                     end
                  end   

               // Algorithm will perform end of read enable training and move to streaming message mode
               POLL_TRAIN_2:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                           cfg_wr_rdn <=  1'b0 ;
                           cfg_addr   <=  POLL_TRAIN_ADDR ;
                           cfg_wdata  <=  32'h0000_0002 ;
                           cfg_req    <=  1'b1            ;
                           poll_state <=  RD_POLL_TRAIN_2  ;
                        end
                  end
 
               // Perform end of read enable training and move to streaming message mode
               RD_POLL_TRAIN_2:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin  
                           cfg_wr_rdn <= 1'b0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req    <=  1'b0            ;
                              if (cfg_rdata[31:0] == 32'h0000_0002) begin
                                 poll_state <=  RD_ADDR_C8 ;
                                 cfg_addr   <=  PMU_MSG_READ_ADDR_C8 ;
                                 cfg_wr_rdn <=  1'b0 ;
                              end else begin
                                 poll_state <= POLL_TRAIN_2 ;
                                 train_done_reg <= 1'b0 ;
                              end
                           end
                     end
                  end   

               // Algorithm will perform message mode read. FSM will wait and move to streaming message mode
               RD_ADDR_C8:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                           cfg_wr_rdn <=  1'b0 ;
                           cfg_addr   <=  PMU_MSG_READ_ADDR_C8 ;
                           cfg_wdata  <=  32'h0000_0002;
                           cfg_req    <=  1'b1            ;
                           poll_state <=  WAIT_RD_ADDR_C8  ;
                        end
                  end
 
               // If firmware is complete, then move 0X13400C4 address for read operation before going to DFI state
               WAIT_RD_ADDR_C8:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin  
                           cfg_wr_rdn <= 1'b0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req    <=  1'b0            ;
                              if (cfg_rdata[31:0] == 32'h0000_0007) begin
                                 poll_state <=  WR0_ADDR_C4      ;
                                 cfg_wr_rdn <=  1'b0 ;
                                 cfg_addr   <=  PMU_MSG_READ_ADDR_C4 ;
                                 train_done_reg <= 1'b1  ;
                                 $display("%t : Firmware training completed. Advance to next step", $time);
                              end else begin
                                 poll_state <=  WR0_ADDR_C4 ;
                                 cfg_wr_rdn <=  1'b1 ;
                                 cfg_addr   <= PMU_MSG_READ_ADDR_C4 ;
                              end
                           end 
                     end
                  end   
            
               // In this state writing value of 0X0000_0000 to the address location
               WR0_ADDR_C4:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                           cfg_wr_rdn <=  1'b1 ;
                           cfg_addr   <=  PMU_MSG_READ_ADDR_C4 ;
                           cfg_wdata  <=  32'd0 ;
                           cfg_req    <=  1'b1            ;
                           poll_state <=  WAIT_WR0_ADDR_C4  ;
                        end
                  end
 
               // Wait for ack to come and go to POLL-TRAIN value of 0x0000_0002
               WAIT_WR0_ADDR_C4:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin  
                           cfg_wr_rdn <= 1'b0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req    <=  1'b0            ;
                              poll_state <=  RD_NXT_POLL_TRAIN_2 ;
                              cfg_wr_rdn <=  1'b0 ;
                              cfg_addr   <=  POLL_TRAIN_ADDR ;
                              cfg_wdata  <=  32'h0000_0001  ;
                           end
                     end
                  end   

               // Reading a polling value of 0X0000_0002 from the address location
               RD_NXT_POLL_TRAIN_2:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                           cfg_wr_rdn <=  1'b0 ;
                           cfg_addr   <=  POLL_TRAIN_ADDR ;
                           cfg_wdata  <=  32'd0           ;
                           cfg_req    <=  1'b1            ;
                           poll_state <=  WT_NXT_POLL_TRAIN_2  ;
                        end
                  end
 
               // Once we polled a value of 0X0000_0002, move to 0X13400C4 address location
               // to write a value of 0X0000_0001 according to polling algorithm
               WT_NXT_POLL_TRAIN_2:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin  
                           cfg_wr_rdn <= 1'b0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req    <=  1'b0            ;
                              poll_state <=  WR1_ADDR_C4 ;
                              cfg_wr_rdn <=  1'b1 ;
                              cfg_addr   <=  PMU_MSG_READ_ADDR_C4 ;
                              cfg_wdata  <=  32'h0000_0001;
                           end
                     end
                  end   

               // Write a value of 0X0000_0001 to the address location
               WR1_ADDR_C4:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                           cfg_wr_rdn <=  1'b1 ;
                           cfg_addr   <=  PMU_MSG_READ_ADDR_C4 ;
                           cfg_wdata  <=  32'h0000_0001;
                           cfg_req    <=  1'b1            ;
                           poll_state <=  WAIT_WR1_ADDR_C4  ;
                        end
                  end
 
               // If "train_done_reg" is asserted, move to DFI-INIT state
               // Else go back to POLL_TRAIN state again
               WAIT_WR1_ADDR_C4:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin  
                           if (cfg_ack == 1'b1) begin
                              cfg_req    <=  1'b0            ;
                              if (train_done_reg == 1'b1) begin
                                 poll_state <=  WR1_DFI_INIT ;
                                 cfg_wr_rdn <= 1'b1 ;
                                 cfg_addr   <=  WRITE1_DFI_INIT ;
                                 cfg_wdata  <=  32'h0000_0071;
                              end else begin
                                 poll_state <=  POLL_TRAIN ;
                                 cfg_wr_rdn <=  1'b0 ;
                                 cfg_addr   <=  POLL_TRAIN_ADDR ;
                              end
                           end
                     end
                  end   

               // Write a value of 0X0000_0071 to DFI-INIT address
               WR1_DFI_INIT:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                              cfg_wr_rdn <=  1'b1 ;
                              cfg_addr   <=  WRITE1_DFI_INIT ;
                              cfg_wdata  <=  32'h0000_0071;
                              cfg_req    <=  1'b1            ;
                              poll_state <=  WAIT6   ;
                        end
                  end

               // In this wait state, writing a value of 0X0000_0071 to DFI-INIT address
               // and waiting for ack to come. Then go to DFI_stat state
               WAIT6:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin
                           cfg_wr_rdn <= 1'b0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req <= 1'b0 ;
                              cfg_addr   <=  POLL_DFI_STATUS ;
                              poll_state <= POLL_DFI_STAT ;
                              cfg_wdata  <=  32'd0          ;
                           end 
                        end
                  end

               // In DFI state for polling a non-zero value //
               POLL_DFI_STAT:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                           cfg_wr_rdn <=  1'b0            ;
                           cfg_addr   <=  POLL_DFI_STATUS ;
                           cfg_wdata  <=  32'd0          ;
                           cfg_req    <=  1'b1            ;
                           poll_state <=  POLL_DFI_WAIT7           ;
                        end
                  end
 
               // DFI state for polling a non-zero value. Then, move to DFI-MISC state
               POLL_DFI_WAIT7:
                  begin  
                     if (start_axi_reg == 1'b0)  
                        begin
                           cfg_wr_rdn <= 1'b0 ;
                           cfg_addr  <= POLL_DFI_STATUS;
                           if (cfg_ack == 1'b1) begin
                              cfg_req    <=  1'b0            ;
                              if (cfg_rdata[31:0] != 0) begin
                                 poll_dfi_status <= 1'b1        ;
                                 poll_state <=  WR2_DFI_MISC    ;
                                 cfg_wr_rdn <=  1'b1 ;
                              end else begin
                                 poll_dfi_status <= 1'b0 ;
                                 poll_state <= POLL_DFI_STAT ;
                              end
                           end
                        end
                  end

               // Writing a value of 0X0000_0051
               WR2_DFI_MISC:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                              cfg_wr_rdn <=  1'b1 ;
                              cfg_addr   <=  WRITE2_DFI_MISC ;
                              cfg_wdata  <=  32'h0000_0051;
                              cfg_req    <=  1'b1            ;
                              poll_state <=  WAIT8    ;
                        end
                  end
               
               // After waiting, moving to debug register1 to write a value 0X0000_0000
               WAIT8:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin
                           cfg_wr_rdn <= 1'b0 ;
                           cfg_addr  <= 42'd0 ;
                           cfg_wdata <= 32'd0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req <= 1'b0 ;
                              poll_state <= WR3_DBG_REG1 ;
                              cfg_addr   <=  WRITE3_DBG_REG1 ;
                              cfg_wr_rdn <=  1'b1 ;
                           end 
                        end
                  end

               // Writing a value of 0X0000_0000 to the address
               WR3_DBG_REG1:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                              cfg_wr_rdn <=  1'b1 ;
                              cfg_addr   <=  WRITE3_DBG_REG1 ;
                              cfg_wdata  <=  32'h0          ;
                              cfg_req    <=  1'b1            ;
                              poll_state <=  WAIT9           ;
                        end
                  end

               // After this wait state we are moving to software done polling to a value of 0X0000_0001
               WAIT9:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin
                           cfg_wr_rdn <= 1'b0 ;
                           cfg_addr  <= 42'd0 ;
                           cfg_wdata <= 32'd0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req <= 1'b0 ;
                              poll_state <= WR4_SW_CNTL ;
                              cfg_wr_rdn <=  1'b1 ;
                              cfg_addr   <=  WRITE4_SW_CNTRL ;
                              cfg_wdata  <=  32'h1          ;
                           end
                        end
                  end

               // Writing a value of 0X0000_0001
               WR4_SW_CNTL:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                              cfg_wr_rdn <=  1'b1 ;
                              cfg_addr   <=  WRITE4_SW_CNTRL ;
                              cfg_wdata  <=  32'h0000_0001   ;
                              cfg_req    <=  1'b1            ;
                              poll_state <=  WAIT10          ;
                        end
                  end

               // Bringing memory controller to software polling mode
               WAIT10:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin
                           cfg_wr_rdn <= 1'b0 ;
                           cfg_addr  <= 28'd0 ;
                           cfg_wdata <= 32'd0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req <= 1'b0 ;
                              poll_state <= POLL_SW_DN ;
                              cfg_addr   <=  POLL_SW_DONE    ;
                              cfg_wdata  <=  32'd0          ;
                           end
                        end
                  end

               POLL_SW_DN:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                           cfg_wr_rdn <=  1'b0            ;
                           cfg_addr   <=  POLL_SW_DONE    ;
                           cfg_wdata  <=  32'd0          ;
                           cfg_req    <=  1'b1            ;
                           poll_state <=  POLL_SW_DN_WAIT11          ;
                        end
                  end
     
               // After this wait state, bring controller to normal operation mode
               // Check if config read data status is non-zero or not. If not, stay in POLL_SW_DN state
               POLL_SW_DN_WAIT11:
                  begin 
                     if (start_axi_reg == 1'b0)
                        begin
                           cfg_wr_rdn <= 1'b0 ;
                           cfg_addr  <= POLL_SW_DONE ;
                           cfg_wdata <= 32'd0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req    <=  1'b0            ;
                              if (cfg_rdata[31:0] != 0) begin
                                 poll_sw_done <= 1'b1        ;
                                 cfg_addr   <=  POLL_OP_MODE    ;
                                 cfg_wdata  <=  32'd0          ;
                                 poll_state <=  POLL_OP_MD   ;
                              end else begin
                                 poll_dfi_status <= 1'b0  ;
                                 poll_state <= POLL_SW_DN ;
                              end
                           end 
                        end
                  end
               
               // After this wait state bring controller to normal operation mode
               POLL_OP_MD:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                           cfg_wr_rdn <=  1'b0 ;
                           cfg_addr   <=  POLL_OP_MODE    ;
                           cfg_wdata  <=  32'd0          ;
                           cfg_req    <=  1'b1            ;
                           poll_state <=  POLL_OP_MD_WAIT12          ;
                        end
                  end
              
               // After this wait state controller goes to final write operate step
               // Check if config read data is 1 or 3. If not, stay in POLL_OP_MD state
               POLL_OP_MD_WAIT12:
                  begin 
                     if (start_axi_reg == 1'b0)
                        begin
                           cfg_wr_rdn <= 1'b0 ;
                           cfg_addr  <= POLL_OP_MODE ;
                           cfg_wdata <= 32'd0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req    <=  1'b0            ;
                              if (cfg_rdata[1:0] == 1 || cfg_rdata[1:0] == 3) begin
                                 poll_op_mode <= 1'b1     ;
                                 poll_state <=  WR1_MEMC  ;
                                 cfg_wr_rdn <=  1'b1 ;
                                 cfg_addr   <=  WRITE1_MEMC     ;
                              end else begin
                                 poll_op_mode <= 1'b0     ;
                                 poll_state   <= POLL_OP_MD   ;
                              end
                           end
                        end
                  end

               // In this state writing a value of 0X0000_0001 to the first controller address location
               WR1_MEMC:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                              cfg_wr_rdn <=  1'b1 ;
                              cfg_addr   <=  WRITE1_MEMC     ;
                              cfg_wdata  <=  32'h0000_0001;
                              cfg_req    <=  1'b1            ;
                              poll_state <=  WAIT13          ;
                        end
                  end

               WAIT13:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin
                           cfg_wr_rdn <= 1'b0 ;
                           cfg_addr  <= 28'd0 ;
                           cfg_wdata <= 256'd0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req <= 1'b0 ;
                              poll_state <= WR2_MEMC ;
                              cfg_wr_rdn <=  1'b1 ;
                              cfg_addr   <=  WRITE2_MEMC     ;
                           end
                        end
                  end

               // In this state writing a value of 0X0000_0001 to the second controller address location
               WR2_MEMC:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                              cfg_wr_rdn <=  1'b1 ;
                              cfg_addr   <=  WRITE2_MEMC     ;
                              cfg_wdata  <=  32'h0000_0001;
                              cfg_req    <=  1'b1            ;
                              poll_state <=  WAIT14          ;
                        end
                  end

               WAIT14:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin
                           cfg_wr_rdn <= 1'b0 ;
                           cfg_addr  <= 28'd0 ;
                           cfg_wdata <= 256'd0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req <= 1'b0 ;
                              cfg_wr_rdn <=  1'b1 ;
                              cfg_addr   <=  WRITE3_MEMC     ;
                              poll_state <= WR3_MEMC ;
                           end
                        end
                  end

               // In this state writing a value of 0X0000_0001 to the third controller address location
               WR3_MEMC:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                              cfg_wr_rdn <=  1'b1 ;
                              cfg_addr   <=  WRITE3_MEMC     ;
                              cfg_wdata  <=  32'h0000_0001;
                              cfg_req    <=  1'b1            ;
                              poll_state <=  WAIT15          ;
                        end       // if (start_axi_reg == 1'b0)
                  end             

               WAIT15:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin
                           cfg_wr_rdn <= 1'b0 ;
                           cfg_addr  <= 28'd0 ;
                           cfg_wdata <= 32'd0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req <= 1'b0 ;
                              cfg_wr_rdn <=  1'b1 ;
                              cfg_addr   <=  WRITE4_FINAL    ;
                              cfg_wdata  <=  32'd0          ;
                              poll_state <= FINAL_WR ;
                           end
                        end
                  end

               // In this state writing a value of 0X0000_0001 to the final controller address location
               FINAL_WR:
                  begin
                     if (start_axi_reg == 1'b0)  
                        begin
                              cfg_wr_rdn <=  1'b1 ;
                              cfg_addr   <=  WRITE4_FINAL    ;
                              cfg_wdata  <=  32'd0          ;
                              cfg_req    <=  1'b1            ;
                              poll_state <=  WAIT16          ;
                        end      // if (start_axi_reg == 1'b0)
                  end  

               WAIT16:
                  begin
                     if (start_axi_reg == 1'b0)
                        begin
                           cfg_wr_rdn <= 1'b0 ;
                           cfg_addr  <= 28'd0 ;
                           cfg_wdata <= 32'd0 ;
                           if (cfg_ack == 1'b1) begin
                              cfg_req <= 1'b0 ;
                              poll_state <= FINAL_ST ;
                              start_axi_reg <= 1'b1 ;
                           end
                        end
                  end

                  // Final state
                  FINAL_ST: 
                    begin
                       start_axi_reg <= 1'b1       ;
                       poll_state    <= FINAL_ST   ;
                       if (start_axi_reg == 1'b0) begin
                          poll_state <= TRAIN_IDLE ;
                          cfg_addr   <= 28'd0 ;
                       end 
                    end 

                  ERROR_ST: 
                     begin
                         $error("DDR Training state machine has entered error state"); 
                     end 
            endcase
         end     
end

// End FSM

// The actual training block is completed once the internal start_axi_reg is set.
assign training_done = start_axi_reg ;

endmodule
