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
//      Top level
//      Demonstrates sending a data stream from one NAP to another
//      between 2 NAPs on a single row, 2 NAPs on a single column,
//      as well as between one slave AXI NAP and one master AXI NAP
//      This version also demonstrates encryption and decryption using
//      the AC7t1550 Crytocore.  Packets are encrypted in the core,
//      sent over the 2D NoC, and then decrypted.
//      
// ------------------------------------------------------------------

`include "nap_interfaces.svh"
`include "reg_control_defines.svh"

module noc_2d_ref_design_top
  #(parameter   LINEAR_PKTS_DS          = 0,      // Enable all data streaming generators, (horizontal and vertical), to send linear packets.
                                                  // If set to 0, then all data streaming generators send randomized packets.
                                                  // If set to 1, then all data streaming generators send linear packets (each packet being an incrementing count from the previous).

    parameter   LINEAR_PKTS_AXI         = 0,      // Enable AXI packet generator to send linear packets.
                                                  // If set to 0, then all AXI packets are randomized.
                                                  // If set to 1, then all AXI packets are an incrementing count from the previous.

    parameter   LINEAR_ADDR_AXI         = 1       // Enable AXI packet generator to send linear addresses.
                                                  // If set to 0, then all AXI packet addresses are randomized.
                                                  // If set to 1, then all AXI packet addresses are an incrementing count from the previous.
    )
   (
    // Inputs

    // Clocks
    input wire  i_send_clk,         // clock for sending data
    input wire  i_chk_clk,          // clock for checking data
    input wire  i_cc_clk,           // clock for crypto core
    input wire  i_reg_clk,          // clock for register control block

    // System PLLs
    input wire  pll_send_clk_lock,  // lock signal from PLL, 
    input wire  pll_chk_clk_lock,   // lock signal from PLL, 

    // Outputs
    // VectorPath Rev-1 Board Signals
    `include "vectorpath_rev1_port_list.svh"

    );

   localparam NAP_H_DATA_WIDTH         = `ACX_NAP_HORIZONTAL_DATA_WIDTH;    // full horizontal width
   localparam NAP_V_DATA_WIDTH         = `ACX_NAP_VERTICAL_DATA_WIDTH;      // full vertical width
   localparam NAP_AXI_DATA_WIDTH       = `ACX_NAP_AXI_DATA_WIDTH;           // full AXI data width
   localparam NAP_AXI_SLAVE_ADDR_WIDTH = `ACX_NAP_AXI_SLAVE_ADDR_WIDTH;     // AXI addr width
   localparam NAP_AXI_MSTR_ADDR_WIDTH  = `ACX_NAP_AXI_MSTR_ADDR_WIDTH;      // AXI master addr width   
   localparam NAP_ARB_SCHED            = 32'hxxxxxxxx;                      // default arbitration schedule
   
   // Internal wires
   wire         encrypt_flow_fail;  // data check failed on encrypt / decrypt flow
   wire         fail_col;           // data check failed on column
   wire         fail_row;           // data check failed on row
   wire         fail_axi;           // Failure for AXI transactions
   wire         xact_done;

   // Control and reset inputs from the register control block
   logic start_axi;                        // Assert to start test for axi 
   logic start_axi_reg;
   logic start_h_send;                     // Assert to start test gen horizontal
   logic start_h_send_reg;                    
   logic start_v_send;                     // Assert to start test gen vertical
   logic start_v_send_reg;       
   logic start_h_chk;                      // Assert to start test check horizontal
   logic start_h_chk_reg;                    
   logic start_v_chk;                      // Assert to start test check vertical
   logic start_v_chk_reg;        
   logic nap_chk_rstn                      /* synthesis syn_keep=1, must_keep=1 */;
   logic nap_chk_rstn_reg;
   logic nap_send_rstn                     /* synthesis syn_keep=1, must_keep=1 */; 
   logic nap_send_rstn_reg; 

   logic    start_axi_pipe;                // Pipeline stage for start_axi
   logic    start_h_send_pipe;             // Pipeline stage for start_h_send
   logic    start_v_send_pipe;             // Pipeline stage for start_v_send
   logic    start_h_chk_pipe;              // Pipeline stage for start_h_chk
   logic    start_v_chk_pipe;              // Pipeline stage for start_v_chk
   logic    fail_col_pipe;                 // Pipeline stage for fail_col
   logic    xact_done_pipe;                // Pipeline stage for xact_done
   logic    fail_axi_pipe;                 // Pipeline stage for fail_axi

   // Output enables
   // ------------------------
   // Fix all output enables active
   // ------------------------
    assign led_l_oe          = 8'hff;
    assign ext_gpio_dir_oe   = 8'hff;
    assign ext_gpio_oe_l_oe  = 1'b1;
    assign led_oe_l_oe       = 1'b1;
    assign fpga_avr_txd_oe   = 1'b1;
    assign irq_to_avr_oe     = 1'b1;
    assign fpga_ftdi_txd_oe  = 1'b1;
    assign fpga_i2c_req_l_oe = 1'b1;
    assign test_oe           = 2'b11;
    assign mcio_dir_oe       = 4'hf;
    assign mcio_dir_45_oe    = 1'b1;
    assign mcio_oe1_l_oe     = 1'b1;
    assign mcio_oe_45_l_oe   = 1'b1;

   // Drive LED outputs
   assign led_l[0] = start_axi_reg;
   assign led_l[1] = 1'b0;
   assign led_l[2] = fail_axi;
   assign led_l[3] = fail_col;
   assign led_l[6] = fail_row;
   assign led_l[7] = xact_done;

   // Create a self-reset signal for the register control block
   logic        reg_rstn;
   logic [31:0] reset_pipe = 16'h0;
 
   always @(posedge i_reg_clk)
       reset_pipe <= {reset_pipe[$bits(reset_pipe)-2 : 0], 1'b1};

   reset_processor_v2 #(
       .NUM_INPUT_RESETS       (3),    // Three reset sources
       .IN_RST_PIPE_LENGTH     (5),    // Length of input pipelines. Ignored when SYNC_INPUT_RESETS = 0
       .SYNC_INPUT_RESETS      (1),    // Synchronize reset inputs
       .OUT_RST_PIPE_LENGTH    (4),    // Output pipeline length. Ignored when RESET_OVER_CLOCK = 1
       .RESET_OVER_CLOCK       (0)     // Set output to be reset over the clock network
   ) i_reset_processor_reg (
       .i_rstn_array       ({reset_pipe[$bits(reset_pipe)-1], pll_send_clk_lock, pll_chk_clk_lock}),
       .i_clk              (i_reg_clk),
       .o_rstn             (reg_rstn)
   );

   //--------------------------------------------------------------------
   // Internal register and GPIO block
   //--------------------------------------------------------------------
   // Create a set of user registers
   // These can be used for either setting values or monitoring results
   // in the user design
   // user_regs_write is to write values to the user design
   // user_regs_read is to read values from the user design
   localparam      NUM_USER_REGS = 4;
   t_ACX_USER_REG  user_regs_write [NUM_USER_REGS -1:0];
   t_ACX_USER_REG  user_regs_read  [NUM_USER_REGS -1:0];

   // Define register addresses
   localparam  CONTROL_REG_ADDR              = 0;
   localparam  STATUS_REG_ADDR               = 1;
   localparam  NUM_TRANSACTIONS_REG_ADDR     = 2;
   localparam  SCRATCH_REG_ADDR              = NUM_USER_REGS-1;


   // Instantiate default register control block
   reg_control_block  #(
       .NUM_USER_REGS      (NUM_USER_REGS),    // Number of user registers
       .IN_REGS_PIPE       (2),                // Input register pipeline stages
       .OUT_REGS_PIPE      (2)                 // Output register pipeline stages
   ) i_reg_control_block (
       .i_clk              (i_reg_clk),  
       .i_reset_n          (reg_rstn),
       .i_user_regs_in     (user_regs_read),
       .o_user_regs_out    (user_regs_write)
   );

   // Registers to control and monitor the test    
   t_ACX_USER_REG  test_control;
   t_ACX_USER_REG  test_status;
   t_ACX_USER_REG  num_transactions;
  
   // Make top register a scratch register, loop back on itself
   assign user_regs_read[SCRATCH_REG_ADDR]          = user_regs_write[SCRATCH_REG_ADDR];

   assign test_control                              = user_regs_write[CONTROL_REG_ADDR];
   assign user_regs_read[CONTROL_REG_ADDR]          = user_regs_write[CONTROL_REG_ADDR];
   assign user_regs_read[STATUS_REG_ADDR]           = test_status;

   assign num_transactions                          = user_regs_write[NUM_TRANSACTIONS_REG_ADDR];
   assign user_regs_read[NUM_TRANSACTIONS_REG_ADDR] = user_regs_write[NUM_TRANSACTIONS_REG_ADDR];

   assign start_axi_reg     = test_control[0];
   assign start_h_send_reg  = test_control[1];
   assign start_v_send_reg  = test_control[2];
   assign start_h_chk_reg   = test_control[3];
   assign start_v_chk_reg   = test_control[4];
   assign nap_chk_rstn_reg  = test_control[5];
   assign nap_send_rstn_reg = test_control[6]; 

   // Test status outputs to the register control block
   logic pll_send_clk_lock_reg;
   logic pll_chk_clk_lock_reg;

   assign pll_send_clk_lock_reg = pll_send_clk_lock;
   assign pll_chk_clk_lock_reg  = pll_chk_clk_lock;

   assign test_status      = {26'b0, fail_axi, fail_col, fail_row, xact_done, pll_send_clk_lock_reg, pll_chk_clk_lock_reg};

   // Synchronize the start signal for the test and the resets for the blocks to the respective clocks
   // Not necessary to synchronize status signals as they are slow changing and the level is monitored
   // not the rising edge
   ACX_SYNCHRONIZER x_sync_start_axi (
                                      .din(start_axi_reg),
                                      .dout(start_axi_pipe),
                                      .clk(i_send_clk),
                                      .rstn(1'b1)
   );

   ACX_SYNCHRONIZER x_sync_start_h_send (
                                         .din(start_h_send_reg),
                                         .dout(start_h_send_pipe),
                                         .clk(i_send_clk),
                                         .rstn(1'b1)
   );

   ACX_SYNCHRONIZER x_sync_start_v_send (
                                         .din(start_v_send_reg),
                                         .dout(start_v_send_pipe),
                                         .clk(i_send_clk),
                                         .rstn(1'b1)
   );

   ACX_SYNCHRONIZER x_sync_start_h_chk (
                                        .din(start_h_chk_reg),
                                        .dout(start_h_chk_pipe),
                                        .clk(i_chk_clk),
                                        .rstn(1'b1)
   );

   ACX_SYNCHRONIZER x_sync_start_v_chk (
                                        .din(start_v_chk_reg),
                                        .dout(start_v_chk_pipe),
                                        .clk(i_chk_clk),
                                        .rstn(1'b1)
   );

   ACX_SYNCHRONIZER x_sync_nap_chk_rstn (
                                         .din(nap_chk_rstn_reg),
                                         .dout(nap_chk_rstn),
                                         .clk(i_chk_clk),
                                         .rstn(1'b1)
   );

   ACX_SYNCHRONIZER x_sync_nap_send_rstn (
                                          .din(nap_send_rstn_reg),
                                          .dout(nap_send_rstn),
                                          .clk(i_send_clk),
                                          .rstn(1'b1)
   );

   // Create 4 horizontal data streaming interfaces
   t_DATA_STREAM #(
                   .DATA_WIDTH (NAP_H_DATA_WIDTH),
                   .ADDR_WIDTH (`ACX_NAP_DS_ADDR_WIDTH)
                   )
   ds_nap_row_out_tx();

   t_DATA_STREAM #(
                   .DATA_WIDTH (NAP_H_DATA_WIDTH),
                   .ADDR_WIDTH (`ACX_NAP_DS_ADDR_WIDTH)
                   )
   ds_from_nap_encrypt();

   t_DATA_STREAM #(
                   .DATA_WIDTH (NAP_H_DATA_WIDTH),
                   .ADDR_WIDTH (`ACX_NAP_DS_ADDR_WIDTH)
                   )
   ds_nap_row_in_rx();

   t_DATA_STREAM #(
                   .DATA_WIDTH (NAP_H_DATA_WIDTH),
                   .ADDR_WIDTH (`ACX_NAP_DS_ADDR_WIDTH)
                   )
   ds_from_core_encrypt();

  
   // Create 4 vertical data streaming interfaces
   t_DATA_STREAM #(
                   .DATA_WIDTH (NAP_V_DATA_WIDTH),
                   .ADDR_WIDTH (`ACX_NAP_DS_ADDR_WIDTH)
                   )
   nap_col_ds_rx_3();

   t_DATA_STREAM #(
                   .DATA_WIDTH (NAP_V_DATA_WIDTH),
                   .ADDR_WIDTH (`ACX_NAP_DS_ADDR_WIDTH)
                   )
   nap_col_ds_tx_3();

   t_DATA_STREAM #(
                   .DATA_WIDTH (NAP_V_DATA_WIDTH),
                   .ADDR_WIDTH (`ACX_NAP_DS_ADDR_WIDTH)
                   )
   nap_col_ds_rx_4();

   t_DATA_STREAM #(
                   .DATA_WIDTH (NAP_V_DATA_WIDTH),
                   .ADDR_WIDTH (`ACX_NAP_DS_ADDR_WIDTH)
                   )
   nap_col_ds_tx_4();


   // Unused wires
   wire         output_rstn_nap_1;
   wire         output_rstn_nap_2;
   wire         output_rstn_nap_3;
   wire         output_rstn_nap_4;
   
   // Instantiate the associated horizontal NAPs that are used for the cryptocore
   // data streaming 
   // Encrypted data is output from this NAP
   nap_horizontal_wrapper #(
                            .E2W_ARB_SCHED (NAP_ARB_SCHED),
                            .W2E_ARB_SCHED (NAP_ARB_SCHED))
   i_nap_row_out (
                // Inputs
                .i_clk         (i_cc_clk),
                .i_reset_n     (nap_send_rstn),
                // Interfaces
                .if_ds_rx      (ds_from_nap_encrypt),
                .if_ds_tx      (ds_nap_row_out_tx),       // Unused, tied off
                // Outputs
                .o_output_rstn (output_rstn_nap_1)
                );

   // Encrypted data is input to this NAP
   nap_horizontal_wrapper #(
                            .E2W_ARB_SCHED (NAP_ARB_SCHED),
                            .W2E_ARB_SCHED (NAP_ARB_SCHED))
   i_nap_row_in (
                // Inputs
                .i_clk         (i_cc_clk),            // The encrypt subsystem works from a single clock
                .i_reset_n     (nap_chk_rstn),
                // Interfaces
                .if_ds_rx      (ds_nap_row_in_rx),      // Unused, tied off
                .if_ds_tx      (ds_from_core_encrypt),
                // Outputs
                .o_output_rstn (output_rstn_nap_2)
                );

    // Set the address from this NAP to the destination nap on the same row, (column 6)
    // This column must match the same assignments in both the testbench and the ace_placements.pdc
    assign ds_from_core_encrypt.addr = 4'h6;

    // Tie off the unused horizontal channels
    assign ds_nap_row_out_tx.data   = `ACX_NAP_HORIZONTAL_DATA_WIDTH'b0;
    assign ds_nap_row_out_tx.sop    = 1'b0;
    assign ds_nap_row_out_tx.eop    = 1'b0;
    assign ds_nap_row_out_tx.valid  = 1'b0;
    assign ds_nap_row_out_tx.addr   = `ACX_NAP_DS_ADDR_WIDTH'b0;

    assign ds_nap_row_in_rx.ready   = 1'b0;

   // Instantiate the associated vertical NAPs that will talk to
   // each other via data streaming 
   nap_vertical_wrapper #(
                          .N2S_ARB_SCHED (NAP_ARB_SCHED),
                          .S2N_ARB_SCHED (NAP_ARB_SCHED))
   i_nap_col_3 (
                // Inputs
                .i_clk         (i_send_clk),
                .i_reset_n     (nap_send_rstn),
                // Interfaces
                .if_ds_rx      (nap_col_ds_rx_3),
                .if_ds_tx      (nap_col_ds_tx_3),
                // Outputs
                .o_output_rstn (output_rstn_nap_3)
                );

   nap_vertical_wrapper #(
                          .N2S_ARB_SCHED (NAP_ARB_SCHED),
                          .S2N_ARB_SCHED (NAP_ARB_SCHED))
   i_nap_col_4 (
                // Inputs
                .i_clk         (i_chk_clk),
                .i_reset_n     (nap_chk_rstn),
                // Interfaces
                .if_ds_rx      (nap_col_ds_rx_4),
                .if_ds_tx      (nap_col_ds_tx_4),
                // Outputs
                .o_output_rstn (output_rstn_nap_4)
                );

   

   //-------------------------
   // Set up horizontal logic
   //-------------------------

   logic         start_h_send_cc;
   logic         start_h_send_cc_d;
   logic         start_h_send_cc_2d;
   logic         start_h_send_d;
   logic         start_h_chk_d;
   
   logic        ds_send_en_h;   // enable sending data stream
   logic        ds_chk_en_h;    // enable checking data stream


   // Use shift register to get signal across the die
   // Make checker signal an extra 8 cycles, this allows for traffic to have been sent
   shift_reg #(.LENGTH(7), .WIDTH(1)) x_shift_reg_start_h (.i_clk (i_send_clk), .i_rstn (1'b1), .i_din (start_h_send_pipe), .o_dout (start_h_send));

   // Synchronize start signal to i_cc_clk
   ACX_SYNCHRONIZER_N x_sync_start_h (.din(start_h_send), .dout(start_h_send_cc), .clk(i_cc_clk), .rstn(1'b1));

   // Add additional flops to allow for replication to drive the state machine in encrypt_flow
   always @(posedge i_cc_clk)
   begin
       start_h_send_cc_d  <= start_h_send_cc;
       start_h_send_cc_2d <= start_h_send_cc_d;
   end
   

   shift_reg #(.LENGTH(16), .WIDTH(1)) x_shift_reg_chk_h   (.i_clk (i_chk_clk), .i_rstn (1'b1), .i_din (start_h_chk_pipe), .o_dout (start_h_chk));   
   
   // flop enable signal for checking data
   always@(posedge i_chk_clk)
     begin
        start_h_chk_d <= start_h_chk;  // Edge detect start
        if(!nap_chk_rstn) // reset
          ds_chk_en_h <= 1'b0;
        else if ( start_h_send & ~start_h_send_d )
          ds_chk_en_h <= 1'b1;
     end

   

   //-------------------------
   // Set up vertical logic
   //-------------------------
   logic         start_v_send_d;
   logic         start_v_chk_d;

   // Use shift register to get start and chk signals across the die
   // Make checker signal an extra 8 cycles, this allows for traffic to have been sent
   shift_reg #(.LENGTH(14), .WIDTH(1)) x_shift_reg_start_v (.i_clk (i_send_clk), .i_rstn (1'b1),
                                                            .i_din (start_v_send_pipe), .o_dout (start_v_send));   

   shift_reg #(.LENGTH(22), .WIDTH(1)) x_shift_reg_chk_v   (.i_clk (i_chk_clk), .i_rstn (1'b1),
                                                            .i_din (start_v_chk_pipe), .o_dout (start_v_chk));   

   logic         ds_send_en_v;  // enable sending data stream
   logic         ds_chk_en_v;   // enable checking data stream
   
   // flop enable signal for sending data
   always@(posedge i_send_clk)
     begin
        start_v_send_d <= start_v_send;
        if(!nap_send_rstn) // reset
          ds_send_en_v <= 1'b0;
        else if ( start_v_send & ~start_v_send_d )
          ds_send_en_v <= 1'b1;
     end

   // flop enable signal for checking data
   always@(posedge i_chk_clk)
     begin
        start_v_chk_d <= start_v_chk;
        if(!nap_chk_rstn) // reset
          ds_chk_en_v <= 1'b0;
        else if ( start_v_chk & ~start_v_chk_d )
          ds_chk_en_v <= 1'b1;
     end

    //-------------------------------------------
    // Horizontal data streaming using cryptocore
    //-------------------------------------------

    // The horizontal data streaming uses the cryptocore to both encrypt and decrypt data streams
    // The core and NAPs are retained in this top level of the design
    // The stream generator, checker, and state machine to control the data flow are contained within
    // the encrypt_flow module

    // Core supports a data width of 128-bits
    localparam          CORE_DATA_WIDTH = 128;    

    // Core interface signals
    logic [CORE_DATA_WIDTH -1:0]    core_data_in;
    logic [CORE_DATA_WIDTH -1:0]    core_data_out;
    logic                           core_mode_decrypt;
    logic                           core_busy;
    logic                           core_go;
    logic                           core_mdata;
    logic                           core_m_req;
    logic                           core_last_w;
    logic [4 -1:0]                  core_last_w_bytes;

    // Fixed keys for core
    // The user will need to determine their key management design and flow.
    logic [128 -1:0]    i_key       = 128'h68656c6c6f20776f726c64;  // "hello world"
    logic [96 -1:0]     i_iv        = 96'h616368726f6e6978;         // "achronix"
   
    encrypt_flow  #(
        .DATA_WIDTH             (CORE_DATA_WIDTH)
    ) i_encrypt_flow (
        // Inputs
        .i_clk                  (i_cc_clk),
        .i_reset_n              (nap_send_rstn),
        .i_start                (start_h_send_cc_2d),      // Start sequence
        .i_core_data_out        (core_data_out),
        .i_core_busy            (core_busy),
        .i_core_m_req           (core_m_req),

        // Interfaces
        .ds_from_nap_encrypt    (ds_from_nap_encrypt),
        .ds_from_core_encrypt   (ds_from_core_encrypt),

        // Outputs
        .o_core_data_in         (core_data_in),
        .o_core_go              (core_go),
        .o_core_mdata           (core_mdata),
        .o_core_last_w          (core_last_w),
        .o_core_last_w_bytes    (core_last_w_bytes),
        .o_core_mode_decrypt    (core_mode_decrypt),
        .o_fail                 (encrypt_flow_fail)
    );
        
    // Instantiate the Cryptographic Core
    ACX_AESX_GCM_K i_ACX_AESX_GCM_K (
        .clk        (i_cc_clk),
        .rstn       (nap_send_rstn),                    // Active low asynchronous reset
        .en         (1'b1),                             // Enable the Cryptographic core 
        .go         (core_go),                          // Active high enable signal for Cryptographic operation
        .abort      (1'b0),                             // Active high to abort current operation
        .ksize      (2'b00),                            // Key size is set to 128 
                                                        //   (valid values are "00, 01, 02" selecting 128, 192 or 256-bit respectively
        .k192       (32'h00000000),                     // Unexpanded input key
        .kin        (i_key),                            // Input Encryption Key
        .iv         (i_iv),                             // 96-bit Initialization Vector
        .e_d        (core_mode_decrypt),                // Configure the cores in Encryption or Decryption mode
        .adata      (1'b0),                             // Additional data is input when high
        .mdata      (core_mdata),                       // Messages data will be input when high
        .k_req      (),                                 // Request for unexp key when high
        .a_req      (),                                 // Request for additional data when high 
        .m_req      (core_m_req),                       // Request for message data when high
        .din        (core_data_in),                     // Receiving the cleartext data from data stream 
        .ibyte      (core_last_w_bytes),                // Indicates number of valid bytes in the last DIN word
        .last_w     (core_last_w),                      // When high the last IV, adata, mdata is input
        .dout       (core_data_out),                    // Sending the data to NAP to send across Horizontal NoC
        .tag        (),                                 // Output authenticated tag value
        .tag_vld    (),                                 // Output authenticated tag value valid
        .ibusy      (core_busy)                         // Indicates core is in initialization phase when high
    );
  

   //---------------------------
   // Data streaming on columns
   //---------------------------
   
   // Generate the data to send
   data_stream_pkt_gen
     #(
       .LINEAR_PKTS     (LINEAR_PKTS_DS),   // Controls packets to be linear or randonmized.
       .TGT_DATA_WIDTH  (NAP_V_DATA_WIDTH)  // Target data width.
       )
   i_ds_col_pkt_gen (
                     // Inputs
                     .i_clk          (i_send_clk),
                     .i_reset_n      (nap_send_rstn),
                     .i_start        (start_v_send),     // Start sequence from beginning
                     .i_enable       (ds_send_en_v),     // Generate new packet
                     .i_dest_addr    (4'h7),             // sending to NAP at location 7
                     .if_data_stream (nap_col_ds_tx_3)   // data stream interface
                     );



   // Check the packets that are sent and see if they match
   data_stream_pkt_chk
     #(
       .LINEAR_PKTS     (LINEAR_PKTS_DS),   // Controls packets to be linear or randonmized.
       .TGT_DATA_WIDTH  (NAP_V_DATA_WIDTH)  // Target data width.
       )
   i_ds_col_pkt_chk (
                     // Inputs
                     .i_clk          (i_chk_clk),
                     .i_reset_n      (nap_chk_rstn),
                     .i_start        (start_v_chk),      // Start sequence from beginning
                     .i_enable       (ds_chk_en_v),      // Generate new packet
                     .if_data_stream (nap_col_ds_rx_4),  // data stream interface
                     .o_pkt_error    (fail_col_pipe)     // Assert if there is a mismatch
                     );

   // Add pipeline on output signals
   shift_reg #(.LENGTH(8),  .WIDTH(1)) x_shift_reg_fail_row (.i_clk (i_cc_clk),  .i_rstn (1'b1), .i_din (encrypt_flow_fail), .o_dout (fail_row));
   shift_reg #(.LENGTH(16), .WIDTH(1)) x_shift_reg_fail_col (.i_clk (i_chk_clk), .i_rstn (1'b1), .i_din (fail_col_pipe),     .o_dout (fail_col));

   //-------------------------
   // AXI NAP-to-NAP
   //-------------------------

   localparam AXI_RSP_ADDR_WIDTH = 16;  // Address width used for AXI NAP responder, 512 entries, 32-bytes wide

   logic                       output_rstn_nap_ml;
   logic                       error_valid_nap_ml;
   logic [2:0]                 error_info_nap_ml;


   // The slave logic responder
   // includes AXI master NAP inside
   axi_bram_responder
     #(
       .TGT_DATA_WIDTH      (NAP_AXI_DATA_WIDTH), // Target data width.
       .TGT_ADDR_WIDTH      (NAP_AXI_MSTR_ADDR_WIDTH),
       .NAP_N2S_ARB_SCHED   (NAP_ARB_SCHED),
       .NAP_S2N_ARB_SCHED   (NAP_ARB_SCHED)
       )
   i_axi_bram_rsp(
                  // Inputs
                  .i_clk     (i_chk_clk),
                  .i_reset_n (nap_chk_rstn) // active low synchronous reset
                  );



   // first make the NAP interface
   // this contains all the AXI signals for NAP
   // that connect to the master logic
   t_AXI4 #(
            .DATA_WIDTH (NAP_AXI_DATA_WIDTH),
            .ADDR_WIDTH (NAP_AXI_SLAVE_ADDR_WIDTH),
            .LEN_WIDTH  (8),
            .ID_WIDTH   (8))
   axi_slave_if();



   
   // Instantiate slave and connect ports to SV interface
   nap_slave_wrapper #(
                       .E2W_ARB_SCHED (NAP_ARB_SCHED),
                       .W2E_ARB_SCHED (NAP_ARB_SCHED))
   i_axi_slave_wrapper_in (
                           .i_clk             (i_send_clk),
                           .i_reset_n         (nap_send_rstn),
                           .nap               (axi_slave_if),
                           .o_output_rstn     (output_rstn_nap_ml),
                           .o_error_valid     (error_valid_nap_ml),
                           .o_error_info      (error_info_nap_ml)
                           );
   
   
   logic [12:0]                test_gen_count;    // Support up to 8K transactions
   logic [12:0]                test_rx_count;
   logic                       axi_wr_enable;
   
   
   // Values passed from writing block
   logic [AXI_RSP_ADDR_WIDTH-1:0] wr_addr;
   logic [AXI_RSP_ADDR_WIDTH-1:0] rd_addr;
   logic [7:0]                    wr_len;
   logic [7:0]                    rd_len;
   logic                          written_valid;
   logic                          pkt_compared;
   logic                          continuous_test;
   
   localparam MAX_FIFO_WIDTH = 72;     // Fixed port widths of 72
   localparam FIFO_WIDTH = 36;         // Either 36 or 72 allowed.  Set as parameter on FIFO
   
   // Values to pass through FIFO
   logic [MAX_FIFO_WIDTH -1:0]    fifo_data_in;
   logic [MAX_FIFO_WIDTH -1:0]    fifo_data_out;
   
   // Assign values to and from FIFO
   // Do in the one block so that they can be checked for consistency
   assign fifo_data_in = {{(MAX_FIFO_WIDTH-$bits(wr_len)-$bits(wr_addr)){1'b0}}, wr_len, wr_addr};
   assign rd_addr      = fifo_data_out[$bits(rd_addr)-1:0];
   assign rd_len       = fifo_data_out[$bits(rd_addr)+$bits(rd_len)-1:$bits(rd_addr)];
   
   // Check the data fits into the current FIFO width
   generate if ( ($bits(wr_len) + $bits(wr_addr)) > FIFO_WIDTH ) ERROR_fifo_struct_to_wide(); endgenerate
   
   // FIFO control
   logic                          fifo_rden;
   logic                          fifo_empty;
   logic                          fifo_full;
   
   // Hold off writing packets if transfer FIFO fills up        
   assign axi_wr_enable = (test_gen_count != 13'h0) && ~fifo_full;
   assign continuous_test = (num_transactions == 0);

   logic    start_axi_d;

   // Pipeline start signal.  16 stages needed so it can cross the whole die diagonally
   shift_reg #(.LENGTH(16), .WIDTH(1)) x_shift_reg_start_axi (.i_clk (i_send_clk),  .i_rstn (1'b1),
                                                              .i_din (start_axi_pipe), .o_dout (start_axi));
   
   // Decrement the generate counter each time we write a transaction
   always @(posedge i_send_clk)
     begin
        start_axi_d <= start_axi;
        if( ~nap_send_rstn )
          test_gen_count <= 13'h0;
        else if ( start_axi & ~start_axi_d )
          test_gen_count <= num_transactions;
        else if (written_valid && ~continuous_test)
          test_gen_count <= test_gen_count - 13'h1;
     end
   
   // Increment the receive counter each time a packet is compared
   always @(posedge i_send_clk)
     begin
        if( ~nap_send_rstn )
          test_rx_count <= 13'h0;
        else if ( start_axi & ~start_axi_d )
          test_rx_count <= 0;
        else if (pkt_compared)
          test_rx_count <= test_rx_count + 13'h1;
     end
   
   assign xact_done_pipe = (test_rx_count == num_transactions) && ~continuous_test;
   shift_reg #(.LENGTH(16), .WIDTH(1)) x_shift_reg_xact_done (.i_clk (i_send_clk), .i_rstn (1'b1), .i_din (xact_done_pipe), .o_dout (xact_done));
   
   // Instantiate AXI packet generator
   axi_pkt_gen #(
                 .LINEAR_PKTS            (LINEAR_PKTS_AXI),
                 .LINEAR_ADDR            (LINEAR_ADDR_AXI),
                 .TGT_ADDR_WIDTH         (AXI_RSP_ADDR_WIDTH),
                 .TGT_ADDR_PAD_WIDTH     (12),
                 .TGT_ADDR_ID            ({7'b0001000, 4'h8, 3'h7}), // send it to NAP col=9, row=8
                 .TGT_DATA_WIDTH         (NAP_AXI_DATA_WIDTH),
                 .MAX_BURST_LEN          (15),
                 .AXI_ADDR_WIDTH         (NAP_AXI_SLAVE_ADDR_WIDTH)
                 ) i_axi_pkt_gen (
                                  // Inputs
                                  .i_clk                  (i_send_clk),
                                  .i_reset_n              (nap_send_rstn),
                                  .i_start                (start_axi),
                                  .i_enable               (axi_wr_enable),
                                  // Interfaces
                                  .axi_if                 (axi_slave_if),
                                  // Outputs
                                  .o_addr_written         (wr_addr),
                                  .o_len_written          (wr_len),
                                  .o_written_valid        (written_valid)
                                  );

   // FIFO the address and length written, and then read out into the checker
   ACX_LRAM2K_FIFO #(
                     .aempty_threshold    (6'h4),
                     .afull_threshold     (6'h4),
                     .fwft_mode           (1'b0),
                     .outreg_enable       (1'b1),
                     .rdclk_polarity      ("rise"),
                     .read_width          (FIFO_WIDTH),
                     .sync_mode           (1'b1),
                     .wrclk_polarity      ("rise"),
                     .write_width         (FIFO_WIDTH)
                     ) i_xact_fifo ( 
                                     .din                 (fifo_data_in),
                                     .rstn                (nap_send_rstn),
                                     .wrclk               (i_send_clk),
                                     .rdclk               (i_send_clk),
                                     .wren                (written_valid),
                                     .rden                (fifo_rden),
                                     .outreg_rstn         (nap_send_rstn),
                                     .outreg_ce           (1'b1),
                                     .dout                (fifo_data_out),
                                     .almost_full         (),
                                     .full                (fifo_full),
                                     .almost_empty        (),
                                     .empty               (fifo_empty),
                                     .write_error         (),
                                     .read_error          ()
                                     );

   // Instantiate AXI packet checker
   // Must have the same configuration as the generator
   axi_pkt_chk #(
                 .LINEAR_PKTS            (LINEAR_PKTS_AXI),
                 .TGT_ADDR_WIDTH         (AXI_RSP_ADDR_WIDTH),
                 .TGT_ADDR_PAD_WIDTH     (12),
                 .TGT_ADDR_ID            ({7'b0001000, 4'h8, 3'h7}), // read from row=8, col=9
                 .TGT_DATA_WIDTH         (NAP_AXI_DATA_WIDTH),
                 .AXI_ADDR_WIDTH         (NAP_AXI_SLAVE_ADDR_WIDTH)
                 ) i_axi_pkt_chk (
                                  // Inputs
                                  .i_clk                  (i_send_clk),
                                  .i_reset_n              (nap_send_rstn),
                                  .i_xact_avail           (~fifo_empty),
                                  .i_xact_addr            (rd_addr),
                                  .i_xact_len             (rd_len),

                                  // Interfaces
                                  .axi_if                 (axi_slave_if),
                                  // Outputs
                                  .o_xact_read            (fifo_rden),
                                  .o_pkt_compared         (pkt_compared),
                                  .o_pkt_error            (fail_axi_pipe)
                                  );

   shift_reg #(.LENGTH(18), .WIDTH(1)) x_shift_reg_fail_axi (.i_clk (i_send_clk), .i_rstn (1'b1), .i_din (fail_axi_pipe), .o_dout (fail_axi));


   
endmodule : noc_2d_ref_design_top

