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
// Speedster7t NoC reference design (RD22)
//      Top level
//      Demonstrates sending a data stream from one NAP to another
//      between 2 NAPs on a single row, 2 NAPs on a single column,
//      as well as between one slave AXI NAP and one master AXI NAP
//      
// ------------------------------------------------------------------

`include "nap_interfaces.svh"
`include "reg_control_defines.svh"

// To include SnapShot in the design, enable the define in either
// src/constraints/synplify_options.tcl, (batch flow), or
// src/syn/noc2d_ref_design_top.prj, (GUI flow)
`ifdef ACX_USE_SNAPSHOT
    `include "speedster7t/common/speedster7t_snapshot_v3.sv"
`endif


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
    input wire  i_send_clk,                 // Clock for sending data
    input wire  i_chk_clk,                  // Clock for checking data
    input wire  i_reg_clk,                  // Clock for the registered control block

    // System PLLs
    input wire  pll_send_clk_lock,          // Lock signal from PLL
    input wire  pll_chk_clk_lock,           // Lock signal from PLL

    // Outputs
    // VectorPath Rev-1 Board Signals
    `include "vectorpath_rev1_port_list.svh"

`ifdef ACX_USE_SNAPSHOT
    // Snapshot specific signals
    ,
    input  jtag_input_tp    i_jtag_in,
    output jtag_output_tp   o_jtag_out
`endif

    );

   localparam NAP_H_DATA_WIDTH         = `ACX_NAP_HORIZONTAL_DATA_WIDTH;    // Full horizontal width
   localparam NAP_V_DATA_WIDTH         = `ACX_NAP_VERTICAL_DATA_WIDTH;      // Full vertical width
   localparam NAP_AXI_DATA_WIDTH       = `ACX_NAP_AXI_DATA_WIDTH;           // Full AXI data width
   localparam NAP_AXI_SLAVE_ADDR_WIDTH = `ACX_NAP_AXI_SLAVE_ADDR_WIDTH;     // AXI addr width
   localparam NAP_AXI_MSTR_ADDR_WIDTH  = `ACX_NAP_AXI_MSTR_ADDR_WIDTH;      // AXI master addr width   
   localparam NAP_ARB_SCHED            = 32'hxxxxxxxx;                      // Default arbitration schedule
   
   // Internal wires
   wire     fail_row;                       // Will be asserted if read errors on row
   wire     fail_col;                       // Will be asserted if read errors on column
   wire     fail_axi;                       // Will be asserted if read errors on axi
   wire     xact_done;                      // AXI transactions done

   // Control and reset inputs from the register control block
   logic    start_axi;                      // Assert to start test for axi 
   logic    start_axi_reg;
   logic    start_h_send;                   // Assert to start test gen horizontal
   logic    start_h_send_reg;                    
   logic    start_v_send;                   // Assert to start test gen vertical
   logic    start_v_send_reg;       
   logic    start_h_chk;                    // Assert to start test check horizontal
   logic    start_h_chk_reg;                    
   logic    start_v_chk;                    // Assert to start test check vertical
   logic    start_v_chk_reg;
   // Resets below routed over the clock network        
   logic    nap_chk_rstn                    /* synthesis syn_keep=1 */;
   logic    nap_chk_rstn_reg;
   logic    nap_send_rstn                   /* synthesis syn_keep=1 */; 
   logic    nap_send_rstn_reg; 

   logic    start_chk;                      // Asserts when start_h_chk or start_v_chk is asserted

   logic    start_axi_pipe;                 // Pipeline stage for start_axi
   logic    start_h_send_pipe;              // Pipeline stage for start_h_send
   logic    start_v_send_pipe;              // Pipeline stage for start_v_send
   logic    start_h_chk_pipe;               // Pipeline stage for start_h_chk
   logic    start_v_chk_pipe;               // Pipeline stage for start_v_chk
   logic    fail_col_pipe;                  // Pipeline stage for fail_col
   logic    fail_row_pipe;                  // Pipeline stage for fail_row
   logic    xact_done_pipe;                 // Pipeline stage for xact_done
   logic    fail_axi_pipe;                  // Pipeline stage for fail_axi

   // Output enables
   // ------------------------
   // Fix all output enables active
   // ------------------------

    // Set output enables active
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

   // start_chk is output on an LED
   // Use the signals direct from the reg control block
   assign start_chk  = start_h_chk_pipe || start_v_chk_pipe;

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
       .RESET_OVER_CLOCK       (1)     // Set output to be reset over the clock network
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
   localparam      NUM_USER_REGS = 10;
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
   t_ACX_USER_REG  num_transactions_d;
  
   // Make top register a scratch register, loop back on itself
   assign user_regs_read[SCRATCH_REG_ADDR]          = user_regs_write[SCRATCH_REG_ADDR];

   // Control register, (RW)
   assign test_control                              = user_regs_write[CONTROL_REG_ADDR];
   assign user_regs_read[CONTROL_REG_ADDR]          = user_regs_write[CONTROL_REG_ADDR];
   // Status register, (RO)
   assign user_regs_read[STATUS_REG_ADDR]           = test_status;

   // AXI number of transactions register, (RW)
   assign num_transactions                          = user_regs_write[NUM_TRANSACTIONS_REG_ADDR];
   assign user_regs_read[NUM_TRANSACTIONS_REG_ADDR] = user_regs_write[NUM_TRANSACTIONS_REG_ADDR];
   always @(posedge i_reg_clk)
        num_transactions_d <= num_transactions;

   // Test control bits
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

   // Test counters
   logic [13 -1:0]                     test_gen_count /* synthesis syn_keep=1 */;    // Support up to 8K transactions
   logic [16 -1:0]                     test_rx_count;
   logic [16 -1:0]                     test_rx_count_d;
   logic                               axi_wr_enable;
   logic                               rx_count_msb_done;


   assign test_status      = {6'b0, rx_count_msb_done, axi_wr_enable, test_gen_count[7:0], test_rx_count[7:0],
                              2'b00, fail_axi, fail_col, fail_row, xact_done, pll_send_clk_lock_reg, pll_chk_clk_lock_reg};

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

   // Synchronize resets, which are then routed over the clock network.
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

    // ------------------------
    // LED outputs
    // ------------------------
    // Some LEDs have go diagonally across the die
    // Use reg_clk as slower, so less flops required.  No issue over CDC as only driving LED output
    shift_reg #( .LENGTH(12), .WIDTH(1) ) x_shift_led_start_axi     (.i_clk (i_reg_clk), .i_rstn (1'b1), .i_din (start_axi),    .o_dout (led_l[0]));
    shift_reg #( .LENGTH(8),  .WIDTH(1) ) x_shift_led_fail_axi      (.i_clk (i_reg_clk), .i_rstn (1'b1), .i_din (fail_axi),     .o_dout (led_l[1]));
    shift_reg #( .LENGTH(8),  .WIDTH(1) ) x_shift_led_start_h_send  (.i_clk (i_reg_clk), .i_rstn (1'b1), .i_din (start_h_send), .o_dout (led_l[2]));
    shift_reg #( .LENGTH(7),  .WIDTH(1) ) x_shift_led_start_v_send  (.i_clk (i_reg_clk), .i_rstn (1'b1), .i_din (start_v_send), .o_dout (led_l[3]));

    shift_reg #( .LENGTH(6),  .WIDTH(1) ) x_shift_led_start_chk     (.i_clk (i_reg_clk),  .i_rstn (1'b1), .i_din (start_chk),   .o_dout (led_l[4]));
    shift_reg #( .LENGTH(6),  .WIDTH(1) ) x_shift_led_fail_col      (.i_clk (i_reg_clk),  .i_rstn (1'b1), .i_din (fail_col),    .o_dout (led_l[5]));
    shift_reg #( .LENGTH(6),  .WIDTH(1) ) x_shift_led_fail_row      (.i_clk (i_reg_clk),  .i_rstn (1'b1), .i_din (fail_row),    .o_dout (led_l[6]));
    shift_reg #( .LENGTH(6),  .WIDTH(1) ) x_shift_led_xact_done     (.i_clk (i_reg_clk),  .i_rstn (1'b1), .i_din (xact_done),   .o_dout (led_l[7]));

   // Create 4 horizontal data streaming interfaces
   t_DATA_STREAM #(
                   .DATA_WIDTH (NAP_H_DATA_WIDTH),
                   .ADDR_WIDTH (`ACX_NAP_DS_ADDR_WIDTH)
                   )
   nap_row_ds_rx_1();

   t_DATA_STREAM #(
                   .DATA_WIDTH (NAP_H_DATA_WIDTH),
                   .ADDR_WIDTH (`ACX_NAP_DS_ADDR_WIDTH)
                   )
   nap_row_ds_tx_1();

   t_DATA_STREAM #(
                   .DATA_WIDTH (NAP_H_DATA_WIDTH),
                   .ADDR_WIDTH (`ACX_NAP_DS_ADDR_WIDTH)
                   )
   nap_row_ds_rx_2();

   t_DATA_STREAM #(
                   .DATA_WIDTH (NAP_H_DATA_WIDTH),
                   .ADDR_WIDTH (`ACX_NAP_DS_ADDR_WIDTH)
                   )
   nap_row_ds_tx_2();
   
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
   
   // Instantiate the associated horizontal NAPs communicate
   // via data streaming
   // NAP locations, (row and column), are specified in the testbench
   // and in /constraints/ace_placement.pdc
   nap_horizontal_wrapper #(
                            .E2W_ARB_SCHED (NAP_ARB_SCHED),
                            .W2E_ARB_SCHED (NAP_ARB_SCHED))
   i_nap_row_1 (
                // Inputs
                .i_clk         (i_send_clk),
                .i_reset_n     (nap_send_rstn),
                // Interfaces
                .if_ds_rx      (nap_row_ds_rx_1),
                .if_ds_tx      (nap_row_ds_tx_1),
                // Outputs
                .o_output_rstn (output_rstn_nap_1)
                );

   nap_horizontal_wrapper #(
                            .E2W_ARB_SCHED (NAP_ARB_SCHED),
                            .W2E_ARB_SCHED (NAP_ARB_SCHED))
   i_nap_row_2 (
                // Inputs
                .i_clk         (i_chk_clk),
                .i_reset_n     (nap_chk_rstn),
                // Interfaces
                .if_ds_rx      (nap_row_ds_rx_2),
                .if_ds_tx      (nap_row_ds_tx_2),
                // Outputs
                .o_output_rstn (output_rstn_nap_2)
                );

   // Instantiate the associated vertical NAPs that will communicate
   // via data streaming 
   // NAP locations, (row and column), are specified in the testbench
   // and in /constraints/ace_placement.pdc
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
   
   logic [3:0]  start_d_h;      // Pipeline to allow transition across the die
   logic        ds_send_en_h;   // enable sending data stream
   logic        ds_chk_en_h;    // enable checking data stream
   logic [7:0]  chk_pipe_h;     // delay pipe for checking data


   // Use shift register to get signal across the die
   // Make checker signal an extra 8 cycles, this allows for traffic to have been sent
   shift_reg #(.LENGTH(7), .WIDTH(1)) x_shift_reg_start_h (.i_clk (i_send_clk), .i_rstn (1'b1),
                                                            .i_din (start_h_send_pipe), .o_dout (start_h_send));

   shift_reg #(.LENGTH(16), .WIDTH(1)) x_shift_reg_chk_h   (.i_clk (i_chk_clk), .i_rstn (1'b1),
                                                            .i_din (start_h_chk_pipe), .o_dout (start_h_chk));   
   
   // kick off the test
   always @(posedge i_send_clk)
     begin
        start_d_h <= {start_d_h[2:0], start_h_send}; // grab start input
     end

   // flop enable signal for sending data
   always@(posedge i_send_clk)
     begin
        if(!nap_send_rstn) // reset
          ds_send_en_h <= 1'b0;
        else if ( start_d_h[2] & ~start_d_h[3] )
          ds_send_en_h <= 1'b1;
     end

   // Need to delay checker to ensure data is written before it's checked
   always @(posedge i_chk_clk)
     begin
        chk_pipe_h <= {chk_pipe_h[0 +: ($size(chk_pipe_h)-1)], start_h_chk};
     end
   

   // flop enable signal for checking data
   always@(posedge i_chk_clk)
     begin
        if(!nap_chk_rstn) // reset
          ds_chk_en_h <= 1'b0;
        else
          ds_chk_en_h <= chk_pipe_h[$high(chk_pipe_h)];
     end

   

   //-------------------------
   // Set up vertical logic
   //-------------------------
   
   logic [3:0]   start_d_v;     // Pipeline to allow transition across the die

   // Use shift register to get start and chk signals across the die
   // Make checker signal an extra 8 cycles, this allows for traffic to have been sent
   shift_reg #(.LENGTH(8), .WIDTH(1)) x_shift_reg_start_v (.i_clk (i_send_clk), .i_rstn (1'b1),
                                                            .i_din (start_v_send_pipe), .o_dout (start_v_send));   

   shift_reg #(.LENGTH(16), .WIDTH(1)) x_shift_reg_chk_v   (.i_clk (i_chk_clk), .i_rstn (1'b1),
                                                            .i_din (start_v_chk_pipe), .o_dout (start_v_chk));   

   logic         ds_send_en_v;  // enable sending data stream
   logic         ds_chk_en_v;   // enable checking data stream
   logic [7:0]   chk_pipe_v;    // delay pipe for checking data
   
   // kick off the test
   always @(posedge i_send_clk)
     begin
        start_d_v <= {start_d_v[2:0], start_v_send}; // grab start input
     end

   // flop enable signal for sending data
   always@(posedge i_send_clk)
     begin
        if(!nap_send_rstn) // reset
          ds_send_en_v <= 1'b0;
        else if ( start_d_v[2] & ~start_d_v[3] )
          ds_send_en_v <= 1'b1;
     end

   // Need to delay checker to ensure data is written before it's checked
   always @(posedge i_chk_clk)
     begin
        chk_pipe_v <= {chk_pipe_v[0 +: ($size(chk_pipe_v)-1)], start_v_chk};
     end
   

   // flop enable signal for checking data
   always@(posedge i_chk_clk)
     begin
        if(!nap_chk_rstn) // reset
          ds_chk_en_v <= 1'b0;
        else
          ds_chk_en_v <= chk_pipe_v[$high(chk_pipe_v)];
     end

   //-------------------------
   // Data streaming on rows
   //-------------------------
   
   // Generate the data to send
   data_stream_pkt_gen
     #(
       .LINEAR_PKTS     (LINEAR_PKTS_DS),   // Controls packets to be linear or randonmized.
       .TGT_DATA_WIDTH  (NAP_H_DATA_WIDTH)  // Target data width.
       )
   i_ds_row_pkt_gen (
                     // Inputs
                     .i_clk          (i_send_clk),
                     .i_reset_n      (nap_send_rstn),
                     .i_start        (start_h_send),     // Start sequence from beginning
                     .i_enable       (ds_send_en_h),     // Generate new packet
                     .i_dest_addr    (4'h9),             // sending to NAP at location 9
                     .if_data_stream (nap_row_ds_tx_1)   // data stream interface
                     );

   // Check the packets that are sent and see if they match
   data_stream_pkt_chk
     #(
       .LINEAR_PKTS     (LINEAR_PKTS_DS),   // Controls packets to be linear or randonmized. 
       .TGT_DATA_WIDTH  (NAP_H_DATA_WIDTH)  // Target data width.
       )
   i_ds_row_pkt_chk(
                    // Inputs
                    .i_clk                      (i_chk_clk),
                    .i_reset_n                  (nap_chk_rstn),
                    .i_start                    (start_h_chk),      // Start sequence from beginning
                    .i_enable                   (ds_chk_en_h),      // Generate new packet
                    .if_data_stream             (nap_row_ds_rx_2),  // data stream interface
                    .o_pkt_error                (fail_row_pipe),    // Assert if there is a mismatch
                    .o_total_transactions       (user_regs_read[6]),
                    .o_total_match_transactions (user_regs_read[7]),
                    .o_total_fail_transactions  (user_regs_read[8])
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
                     .i_clk                         (i_chk_clk),
                     .i_reset_n                     (nap_chk_rstn),
                     .i_start                       (start_v_chk),      // Start sequence from beginning
                     .i_enable                      (ds_chk_en_v),      // Generate new packet
                     .if_data_stream                (nap_col_ds_rx_4),  // data stream interface
                     .o_pkt_error                   (fail_col_pipe),    // Assert if there is a mismatch
                     .o_total_transactions          (user_regs_read[3]),
                     .o_total_match_transactions    (user_regs_read[4]),
                     .o_total_fail_transactions     (user_regs_read[5])
                     );


   // Add pipeline on output signals
   shift_reg #(.LENGTH(8),  .WIDTH(1)) x_shift_reg_fail_row (.i_clk (i_chk_clk),  .i_rstn (1'b1),
                                                             .i_din (fail_row_pipe), .o_dout (fail_row));
   shift_reg #(.LENGTH(16), .WIDTH(1)) x_shift_reg_fail_col (.i_clk (i_chk_clk), .i_rstn (1'b1),
                                                             .i_din (fail_col_pipe),  .o_dout (fail_col));

   //-------------------------
   // AXI NAP-to-NAP
   //-------------------------
   localparam AXI_RSP_ADDR_WIDTH = 16;  // Address width used for AXI NAP responder, 512 entries, 32-bytes wide

   logic                       output_rstn_nap_ml;
   logic                       error_valid_nap_ml;
   logic [2:0]                 error_info_nap_ml;


   // Slave logic responder
   // This includes an AXI master NAP instantiated within the module
   // NAP locations, (row and column), are specified in the testbench
   // and in /constraints/ace_placement.pdc
   axi_bram_responder
     #(
       .TGT_DATA_WIDTH      (NAP_AXI_DATA_WIDTH), // Target data width.
       .TGT_ADDR_WIDTH      (NAP_AXI_MSTR_ADDR_WIDTH),
       .NAP_N2S_ARB_SCHED   (NAP_ARB_SCHED),
       .NAP_S2N_ARB_SCHED   (NAP_ARB_SCHED)
       )
   i_axi_bram_rsp(
                  // Inputs
        // When using snapshot, put on same clock network as rest of AXI
        `ifdef ACX_USE_SNAPSHOT
                  .i_clk     (i_chk_clk),
                  .i_reset_n (nap_chk_rstn) // active low synchronous reset
        `else
                  // In normal operation have on different clock
                  .i_clk     (i_send_clk),
                  .i_reset_n (nap_send_rstn) // active low synchronous reset
        `endif
                  );



   // Create the NAP interface
   // This contains all the AXI signals for NAP
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
   
   
   // Values passed from writing block
   logic [AXI_RSP_ADDR_WIDTH-1:0]   wr_addr;
   logic [AXI_RSP_ADDR_WIDTH-1:0]   rd_addr;
   logic [7:0]                      wr_len;
   logic [7:0]                      rd_len;
   logic                            written_valid;
   logic                            pkt_compared;
   logic                            continuous_test;
   logic                            continuous_test_q;
   
   localparam MAX_FIFO_WIDTH = 72;     // Fixed port widths of 72
   localparam FIFO_WIDTH = 36;         // Either 36 or 72 allowed.  Set as parameter on FIFO
   
   // Values to pass through FIFO
   logic [MAX_FIFO_WIDTH -1:0]      fifo_data_in;
   logic [MAX_FIFO_WIDTH -1:0]      fifo_data_out;
   
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

   // Countinuous test is a static value, add pipelining to improve timing
   // Synthesis should be able to do retiming on this.
   always @(posedge i_send_clk)
   begin
        continuous_test_q <= (num_transactions_d == 0);
        continuous_test   <= continuous_test_q;
   end

   // Pipeline AXI start signal.  From middle to SW corner
`ifdef ACX_USE_SNAPSHOT
   logic snapshot_start_axi;
`endif

   shift_reg #(.LENGTH(10), .WIDTH(1)) x_shift_reg_start_axi (.i_clk (i_send_clk),  .i_rstn (1'b1),
`ifdef ACX_USE_SNAPSHOT
                                                              .i_din (start_axi_pipe | snapshot_start_axi), .o_dout (start_axi));
`else
                                                              .i_din (start_axi_pipe), .o_dout (start_axi));
`endif

   // Need separate pipeline to the two counters as they are placed away from the axi_pkt_gen/chk   
   logic    start_axi_d;
   logic    start_axi_2d;

   // Decrement the generate counter each time we write a transaction
   always @(posedge i_send_clk)
     begin
        start_axi_d  <= start_axi;
        start_axi_2d <= start_axi_d;
        if( ~nap_send_rstn )
          test_gen_count <= 13'h0;
        else if ( start_axi_d & ~start_axi_2d )
          test_gen_count <= num_transactions_d;       // CDC occuring here, but num_transactions should be stable
        else if (written_valid && ~continuous_test)
          test_gen_count <= test_gen_count - 13'h1;
     end
   
   // Increment the receive counter each time a packet is compared
   // Counter will count up to 0.
   always @(posedge i_send_clk)
     begin
        test_rx_count_d <= test_rx_count;
        if( ~nap_send_rstn )
          test_rx_count <= 16'h0000;    // Do not set to 16'h8000, otherwise xact_done is asserted when no packets run
        else if ( start_axi_d & ~start_axi_2d )
          // This has a CDC from num_transactions, but the value is static.
          test_rx_count <= 16'h8000 - {1'b0, num_transactions_d[14:0]};
        else if (pkt_compared)
          test_rx_count <= test_rx_count + 16'd1;
     end
   
   // Additional logic layer to allow for retiming.
   always @(posedge i_send_clk)
         rx_count_msb_done <= test_rx_count_d[15];

   assign xact_done_pipe = (test_rx_count[3:0] == 4'h0) & rx_count_msb_done & ~continuous_test;
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

`ifdef ACX_USE_SNAPSHOT
    // ------------------------
    // Snapshot
    // ------------------------

    localparam integer MONITOR_WIDTH = 48;
    localparam integer MONITOR_DEPTH = 2048;

    logic       snapshot_arm;           // Use to start AXI generator 

    logic       arm_d;
    logic       arm_2d;

    always @(posedge i_send_clk)
    begin
        arm_d <= snapshot_arm;
        arm_2d <= arm_d;
        snapshot_start_axi <= (arm_d & ~arm_2d);
    end

    logic       axi_wr_enable_d /* synthesis syn_keep=1 */;
    always @(posedge i_send_clk)
        axi_wr_enable_d <= axi_wr_enable;

    logic       bram_rsp_awready /* synthesis syn_keep=1 */;
    logic       bram_rsp_awvalid /* synthesis syn_keep=1 */;
    logic       bram_rsp_wready /* synthesis syn_keep=1 */;
    logic       bram_rsp_wvalid /* synthesis syn_keep=1 */;
    logic       bram_rsp_wlast /* synthesis syn_keep=1 */;
    logic       bram_rsp_bready /* synthesis syn_keep=1 */;
    logic       bram_rsp_bvalid /* synthesis syn_keep=1 */;
    logic       bram_rsp_arready /* synthesis syn_keep=1 */;
    logic       bram_rsp_arvalid /* synthesis syn_keep=1 */;
    logic       bram_rsp_rready /* synthesis syn_keep=1 */;
    logic       bram_rsp_rvalid /* synthesis syn_keep=1 */;
    logic       bram_rsp_rlast /* synthesis syn_keep=1 */;

    ACX_PROBE_CONNECT #(
        .width(12),
        .tag("bram_rsp")
    ) x_probe_bram_rsp (
        .dout({  
            bram_rsp_rlast, bram_rsp_rready, bram_rsp_rvalid,
            bram_rsp_arready, bram_rsp_arvalid,
            bram_rsp_bready, bram_rsp_bvalid,
            bram_rsp_wlast, bram_rsp_wready, bram_rsp_wvalid,
            bram_rsp_awready, bram_rsp_awvalid
            })
    );

    logic [3:0] pkt_gen_wr_state /* synthesis syn_keep=1 */;
    logic [3:0] bram_rsp_wr_state /* synthesis syn_keep=1 */;

    assign pkt_gen_wr_state = i_axi_pkt_gen.wr_state;
    assign bram_rsp_wr_state = i_axi_bram_rsp.wr_xact_state;
  
    localparam integer STIMULI_WIDTH = 9;
    wire [STIMULI_WIDTH-1 : 0] stimuli;
  
    ACX_SNAPSHOT #(
        .DUT_NAME       ("snapshot_axi"),
        .MONITOR_WIDTH  (MONITOR_WIDTH),
        .MONITOR_DEPTH  (MONITOR_DEPTH),
        .TRIGGER_WIDTH  (MONITOR_WIDTH < 40? MONITOR_WIDTH : 40),
        .STIMULI_WIDTH  (STIMULI_WIDTH),
        .ARM_DELAY      (3)
    ) x_snapshot (
        .i_jtag_in      (i_jtag_in),
        .o_jtag_out     (o_jtag_out),

        .i_user_clk     (i_send_clk),
        .i_monitor      ({
                        test_gen_count[3:0], rx_count_msb_done, test_rx_count[3:0],
                        bram_rsp_rlast, bram_rsp_rready, bram_rsp_rvalid,
                        bram_rsp_arready, bram_rsp_arvalid,
                        bram_rsp_wr_state, 
                        bram_rsp_bready, bram_rsp_bvalid,
                        bram_rsp_wlast, bram_rsp_wready, bram_rsp_wvalid,
                        bram_rsp_awready, bram_rsp_awvalid,
                        pkt_gen_wr_state,
                        axi_slave_if.rlast, axi_slave_if.rready, axi_slave_if.rvalid, 
                        axi_slave_if.arready, axi_slave_if.arvalid,
                        axi_slave_if.bresp, axi_slave_if.bvalid, axi_slave_if.bvalid,  
                        axi_slave_if.wlast, axi_slave_if.wready, axi_slave_if.wvalid, 
                        axi_slave_if.awready, axi_slave_if.awvalid,
                        pkt_compared, fifo_full, fifo_empty, fifo_rden, written_valid,
                        axi_wr_enable_d, start_axi 
                        }),
        .i_trigger      (), // not used if STANDARD_TRIGGERS = 1
        .o_stimuli      (stimuli),
        .o_stimuli_valid(),
        .o_arm          (snapshot_arm),
        .o_trigger      ()
    );
  
`endif


    // ----------------------------------------------------------------------
    // Support for the AC7t1550 device
    // ----------------------------------------------------------------------
    // If this design is intended to be targeted to the ac7t1550 device,
    // (which includes the hard-ip cryptocore), then it is necessary to
    // instantiate the core in the code, even if unused
    // If unrequred for an AC7t1550 design, then instantiate a bypass
    // instance of the core as shown below
    // For a design that demonstrates full use of the core, please see the
    // Speedster_2D_noc_ref_design_RD22/ac7t1550 design
    // ----------------------------------------------------------------------
    // The define ACX_DEVICE is set as follows :
    //      In simulation by the /sim/<simulator>/Makefile
    //      In GUI synthesis by the /src/syn/<project>.prj file
    //      In batch synthesis by the /src/constraints/synplify_options.tcl file
    // ----------------------------------------------------------------------
`ifdef ACX_DEVICE_AC7t1550
    ACX_AESX_GCM_K_BYPASS ();
`endif


   
endmodule : noc_2d_ref_design_top

