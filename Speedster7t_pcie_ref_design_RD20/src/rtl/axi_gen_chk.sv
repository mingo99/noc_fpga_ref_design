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
// Speedster7t PCIe reference design (RD20)
//      AXI generator and checker
//      Generates data and sends to an AXI endpoint
//      Then reads the data back and checks it
// ------------------------------------------------------------------

`include "7t_interfaces.svh"

module axi_gen_chk 
  #(
    parameter TGT_DATA_WIDTH = 0, // Target data width for AXI transactions
    parameter TGT_ADDR_WIDTH = 0, // Target address width for AXI slave
    parameter TGT_ADDR_ID    = 0,  // Address ID of AXI destination
    parameter NUM_TRANSACTIONS = 256 // number of transactions to send
    )
   (
    input wire   i_clk,
    input wire   i_reset_n, // Negative synchronous reset
    input wire   i_start, // Start sequence from beginning

    output logic o_fail, // checker failed
    output logic o_test_complete // test is complete
    );

   localparam AXI_PCI_ADDR_WIDTH = 16;  // Address width used for PCIe

   
   // Instantiate AXI_4 interfaces for nap in and out
   t_AXI4 #(
            .DATA_WIDTH (TGT_DATA_WIDTH),
            .ADDR_WIDTH (TGT_ADDR_WIDTH),
            .LEN_WIDTH  (8),
            .ID_WIDTH   (8)
            )
   nap_in();

   // Non AXI signals from AXI NAP
   wire          output_rstn_nap_in;
   wire          error_valid_nap_in;
   wire [2:0]    error_info_nap_in;
   wire          output_rstn_nap_out;
   wire          error_valid_nap_out;
   wire [2:0]    error_info_nap_out;



   // Instantiate slave and connect ports to SV interface
   nap_slave_wrapper 
     i_axi_slave_wrapper_in (
                             .i_clk           (i_clk),
                             .i_reset_n       (i_reset_n),
                             .nap             (nap_in),
                             .o_output_rstn   (output_rstn_nap_in),
                             .o_error_valid   (error_valid_nap_in),
                             .o_error_info    (error_info_nap_in)
                             );

   logic [12:0]  test_count; // Support 8K transactions
   (* syn_preserve=1, must_keep=1 *)   logic        start_d;
   logic         axi_wr_enable;
   logic         test_complete_d;


   // Values passed from writing block
   logic [AXI_PCI_ADDR_WIDTH-1:0] wr_addr;
   logic [AXI_PCI_ADDR_WIDTH-1:0] rd_addr;
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
   generate 
      if ( ($bits(wr_len) + $bits(wr_addr)) > FIFO_WIDTH ) ERROR_fifo_struct_to_wide(); 
   endgenerate
   
   // FIFO control
   logic                          fifo_rden;
   logic                          fifo_empty;
   logic                          fifo_full;
   logic                          fifo_almost_full;
   
   // Hold off writing packets if transfer FIFO fills up        
   always@(posedge i_clk)
     begin
        if(~i_reset_n) // reset
          axi_wr_enable <= 1'b0;
        else if(test_count != 13'h0) // still sending transactions
          axi_wr_enable <= !fifo_almost_full;
        else
          axi_wr_enable <= 1'b0;
     end
   
   
   assign continuous_test = (NUM_TRANSACTIONS == 0);
   

   always @(posedge i_clk)
     begin
        start_d <= i_start;
        if( ~i_reset_n )
          test_count <= 13'h0;
        else if(o_test_complete | test_complete_d)
          test_count <= 13'h0;
        else if ( i_start & ~start_d )
          test_count <= -13'h1;
        else if (axi_wr_enable)
          test_count <= test_count - 13'h1;
     end

   // Instantiate AXI packet generator
   axi_pkt_gen #(
                 .LINEAR_PKTS            (0),
                 .LINEAR_ADDR            (1),
                 .TGT_ADDR_WIDTH         (AXI_PCI_ADDR_WIDTH),
                 .TGT_ADDR_PAD_WIDTH     (12),          
                 .TGT_DATA_WIDTH         (TGT_DATA_WIDTH),
                 .TGT_ADDR_ID            (TGT_ADDR_ID),
                 .MAX_BURST_LEN          (15),
                 .AXI_ADDR_WIDTH         (TGT_ADDR_WIDTH)
                 ) i_axi_pkt_gen (
                                  // Inputs
                                  .i_clk                  (i_clk),
                                  .i_reset_n              (i_reset_n),
                                  .i_start                (i_start),
                                  .i_enable               (axi_wr_enable),
                                  // Interfaces
                                  .axi_if                 (nap_in),
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
                                     .rstn                (i_reset_n),
                                     .wrclk               (i_clk),
                                     .rdclk               (i_clk),
                                     .wren                (written_valid),
                                     .rden                (fifo_rden),
                                     .outreg_rstn         (i_reset_n),
                                     .outreg_ce           (1'b1),
                                     .dout                (fifo_data_out),
                                     .almost_full         (fifo_almost_full),
                                     .full                (fifo_full),
                                     .almost_empty        (),
                                     .empty               (fifo_empty),
                                     .write_error         (),
                                     .read_error          ()
                                     );



   // Instantiate AXI packet checker
   // Must have the same configuration as the generator
   axi_pkt_chk #(
                 .LINEAR_PKTS            (0),
                 .TGT_ADDR_WIDTH         (AXI_PCI_ADDR_WIDTH),
                 .TGT_DATA_WIDTH         (TGT_DATA_WIDTH),
                 .TGT_ADDR_PAD_WIDTH     (12),
                 .TGT_ADDR_ID            (TGT_ADDR_ID),
                 .AXI_ADDR_WIDTH         (TGT_ADDR_WIDTH)
                 ) i_axi_pkt_chk (
                                  // Inputs
                                  .i_clk                  (i_clk),
                                  .i_reset_n              (i_reset_n),
                                  .i_xact_avail           (~fifo_empty),
                                  .i_xact_addr            (rd_addr),
                                  .i_xact_len             (rd_len),
                                  // Interfaces
                                  .axi_if                 (nap_in),
                                  // Outputs
                                  .o_xact_read            (fifo_rden),
                                  .o_pkt_compared         (pkt_compared),
                                  .o_pkt_error            (o_fail)
                                  );


   // set test complete
   always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          begin
             o_test_complete <= 1'b0;
             test_complete_d <= 1'b0;
          end
        else
          begin
             o_test_complete <= (test_count == 13'h0) & start_d;
             test_complete_d <= o_test_complete;
          end
     end

   
endmodule // axi_gen_chk
