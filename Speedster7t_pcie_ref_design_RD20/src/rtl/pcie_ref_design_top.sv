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
//      Top level
//      Demonstrates reading and writing to PCIe device
// ------------------------------------------------------------------

`include "7t_interfaces.svh"

module pcie_ref_design_top
   (
    // Inputs
    input wire          i_clk,
    input wire          i_reset_n,                          // Negative synchronous reset
    input wire          i_start,                            // Assert to start test
    input wire          pll_1_lock,                         // PLL lock, used with reset input
    input wire [5:0]    pci_express_x16_status_ltssm_state, // Used to indicate that PCIe link is ready
    input wire [5:0]    pci_express_x8_status_ltssm_state,  // Used to indicate that PCIe link is ready

    // Unused Inputs
    input wire [3:0]    pci_express_x16_status_flr_pf_active,
    input wire          pci_express_x16_status_flr_vf_active,
 
    // Outputs
    output wire         o_mstr_test_complete,       // Assert when master logic complete
    output wire         o_mstr_test_complete_oe,    // Output enable, tie high
    output wire         o_fail,                     // Will be asserted if read errors
    output wire         o_fail_oe                   // Output enable, tie high
    );


   // Local system parameters
   localparam   PCIE0_ADDR_ID           = 9'b10000_0000;     // PCIe target address ID.  Page in NoC address mapping
   localparam   PCIE1_ADDR_ID           = 9'b11000_0000;     // PCIe target address ID.  Page in NoC address mapping

   localparam ADDR_ID_WIDTH             = 9;
   localparam NAP_AXI_DATA_WIDTH        = `ACX_NAP_AXI_DATA_WIDTH;          // Full AXI data width
   localparam NAP_AXI_SLAVE_ADDR_WIDTH  = `ACX_NAP_AXI_SLAVE_ADDR_WIDTH;    // AXI slave addr width
   localparam NAP_AXI_MSTR_ADDR_WIDTH   = `ACX_NAP_AXI_MSTR_ADDR_WIDTH;     // AXI master addr width   
   localparam LINK_STATE_WAIT_CYCLE     = 16'h0400;

   // Link control signals
   reg [15:0]   pcie16_link_ctr;
   reg [15:0]   pcie8_link_ctr;
   wire         pcie16_link_ready;
   wire         pcie8_link_ready;

   // Check PCIE_ADDR_ID is correct size
   generate if ($bits(PCIE0_ADDR_ID) != ADDR_ID_WIDTH) begin : gb_addr_id_error
      ERROR_pcie_addr_id_wrong_size();
   end
   endgenerate


   // Tie off output enable signals
   assign o_mstr_test_complete_oe = 1'b1;
   assign o_fail_oe = 1'b1;
   

   // ------------------------
   // Create internal resets
   // Need to include PLL lock signals and external resets
   // ------------------------
   logic [6:0]  nap_rstn;
   // Generate a reset per NAP
   genvar       j;
   generate    
      for (j=0;j<7;j=j+1) begin : gb_pcie_nap_reset
         reset_processor #(
                           .NUM_INPUT_RESETS   (2),    // Two reset sources
                           .NUM_OUTPUT_RESETS  (1),    // One clock domain and hence one reset
                           .RST_PIPE_LENGTH    (4)     // Set reset pipeline to 4 stages
                           ) i_reset_processor (
                                                .i_rstn_array       ({i_reset_n, pll_1_lock}),
                                                .i_clk              ({i_clk}),
                                                .o_rstn_array       ({nap_rstn[j]})
                                                )/* synthesis syn_noprune=1 */;
      end // block: pcie_nap_reset
   endgenerate


   
   //--------------------------------
   // BRAM responder
   // PCIe can write and read
   // to the memory
   // the slave logic responder
   // includes AXI master NAP inside
   //--------------------------------

   axi_bram_responder
     #(
       .TGT_DATA_WIDTH (NAP_AXI_DATA_WIDTH), // Target data width.
       .TGT_ADDR_WIDTH (NAP_AXI_MSTR_ADDR_WIDTH),
       .NAP_COL (),
       .NAP_ROW ()
       )
   i_axi_bram_rsp1(
                   // Inputs
                   .i_clk (i_clk),
                   .i_reset_n (nap_rstn[0]) // active low synchronous reset
                   );


   axi_bram_responder
     #(
       .TGT_DATA_WIDTH (NAP_AXI_DATA_WIDTH), // Target data width.
       .TGT_ADDR_WIDTH (NAP_AXI_MSTR_ADDR_WIDTH),
       .NAP_COL (),
       .NAP_ROW ()
       )
   i_axi_bram_rsp2(
                   // Inputs
                   .i_clk (i_clk),
                   .i_reset_n (nap_rstn[1]) // active low synchronous reset
                   );



   //----------------------------------------------------------------
   // Register Set that connects to
   // AXI master NAP
   // includes AXI master NAP inside
   // and a set of 28 registers
   //
   // 8 read/write registers
   // 8 read-only registers
   // 2 up/down counter registers with config
   //   register each for start/stop/clear (4 total)
   // 1 IRQ register + config and master (3 total)
   // 1 clear on read register
   // 4 64-bit registers
   //-----------------------------------------------------------------

   axi_nap_register_set 
     #(
       .TGT_DATA_WIDTH (NAP_AXI_DATA_WIDTH), // Target data width.
       .TGT_ADDR_WIDTH (NAP_AXI_MSTR_ADDR_WIDTH),
       .NAP_COL (),
       .NAP_ROW (),
       .NAP_N2S_ARB_SCHED (), // north-to-south arbitration schedule
       .NAP_S2N_ARB_SCHED ()  // south-to-north arbitration schedule
       )
   i_axi_nap_reg_set1(
                      // Clocks and reset
                      .i_clk (i_clk),
                      .i_reset_n (nap_rstn[2])
                      );


   axi_nap_register_set 
     #(
       .TGT_DATA_WIDTH (NAP_AXI_DATA_WIDTH), // Target data width.
       .TGT_ADDR_WIDTH (NAP_AXI_MSTR_ADDR_WIDTH),
       .NAP_COL (),
       .NAP_ROW (),
       .NAP_N2S_ARB_SCHED (), // north-to-south arbitration schedule
       .NAP_S2N_ARB_SCHED ()  // south-to-north arbitration schedule
       )
   i_axi_nap_reg_set2(
                      // Clocks and reset
                      .i_clk (i_clk),
                      .i_reset_n (nap_rstn[3])
                      );


   //----------------------------------------------------------------
   // Master logic to generate write data and send to
   // the PCIe slaves
   // Master logic to check the data written and send read
   // requests to the PCIe slaves
   //
   // The checker and generator both connect through the same
   // slave NAP
   //
   // One master sends transactions to PCIex8 and the other
   // sends transactions to PCIex16
   //-----------------------------------------------------------------

   
   // Pipeline start signal.  Comes from edge of die and needs to traverse
   // across and fanout to several instances spread around the die
   // Also the pipeline will allow for replication if necessary
   (* syn_preserve=1, must_keep=1 *) logic [5:0]    start_pipe_pcie8;
   (* syn_preserve=1, must_keep=1 *) logic [5:0]    start_pipe_pcie16;
   (* syn_preserve=1, must_keep=1 *) logic [5:0]    ready_del_pipe_pcie8;
   (* syn_preserve=1, must_keep=1 *) logic [5:0]    ready_del_pipe_pcie16;
   (* syn_preserve=1, must_keep=1 *) logic          start_del_pcie8  /* synthesis syn_maxfan=4 */;
   (* syn_preserve=1, must_keep=1 *) logic          start_del_pcie16 /* synthesis syn_maxfan=4 */;
   
   assign pcie8_link_ready  = (pcie8_link_ctr == LINK_STATE_WAIT_CYCLE);
   assign pcie16_link_ready = (pcie16_link_ctr == LINK_STATE_WAIT_CYCLE);

   always @(posedge i_clk) begin
     start_pipe_pcie8     <= {start_pipe_pcie8[4:0], i_start};
     start_pipe_pcie16    <= {start_pipe_pcie16[4:0], i_start};
     ready_del_pipe_pcie8 <= {ready_del_pipe_pcie8[4:0], pcie8_link_ready};
     ready_del_pipe_pcie16 <= {ready_del_pipe_pcie16[4:0], pcie16_link_ready};
   end


   always @(posedge i_clk)
     begin
        start_del_pcie8  <= start_pipe_pcie8[5] & ready_del_pipe_pcie8[5];
        start_del_pcie16 <= start_pipe_pcie16[5] & ready_del_pipe_pcie16[5];
     end
   
   always @(posedge i_clk or negedge nap_rstn[6])
     begin
       if (~nap_rstn[6]) begin
         pcie16_link_ctr <= 0;
         pcie8_link_ctr  <= 0;
       end
       else begin
        if ((pci_express_x16_status_ltssm_state == 6'h11) & (pcie16_link_ctr < LINK_STATE_WAIT_CYCLE))
          pcie16_link_ctr <= pcie16_link_ctr + 1;
        else if (pci_express_x16_status_ltssm_state != 6'h11)
          pcie16_link_ctr <= 0;

        if ((pci_express_x8_status_ltssm_state == 6'h11) & (pcie8_link_ctr < LINK_STATE_WAIT_CYCLE))
          pcie8_link_ctr <= pcie8_link_ctr + 1;
        else if (pci_express_x8_status_ltssm_state != 6'h11)
          pcie8_link_ctr <= 0;
       end
     end
   
   // Test status signals for master logic
   logic o_fail_x16;            // Pciex16 test failed
   logic o_fail_x8;             // Pciex8 test failed
   logic o_test_complete_x16;   // Pciex16 test finished
   logic o_test_complete_x8;    // Pciex8 test finished


   axi_gen_chk 
     #(
       .TGT_DATA_WIDTH      (NAP_AXI_DATA_WIDTH),
       .TGT_ADDR_WIDTH      (NAP_AXI_SLAVE_ADDR_WIDTH),
       .TGT_ADDR_ID         (PCIE0_ADDR_ID),        // Address ID of AXI destination
       .NUM_TRANSACTIONS    (8)                     // Number of transactions to send
       )
   i_pcie16_axi_gen_chk
     (
       .i_clk               (i_clk),
       .i_reset_n           (nap_rstn[4]),          // Negative synchronous reset
       .i_start             (start_del_pcie16),     // Start sequence from beginning

       .o_fail              (o_fail_x16),           // Checker failed
       .o_test_complete     (o_test_complete_x16)   // Test is complete
      );




   axi_gen_chk 
     #(
       .TGT_DATA_WIDTH      (NAP_AXI_DATA_WIDTH),
       .TGT_ADDR_WIDTH      (NAP_AXI_SLAVE_ADDR_WIDTH),
       .TGT_ADDR_ID         (PCIE1_ADDR_ID),        // Address ID of AXI destination
       .NUM_TRANSACTIONS    (256)                   // Number of transactions to send
       )
   i_pcie8_axi_gen_chk
     (
       .i_clk               (i_clk),
       .i_reset_n           (nap_rstn[5]),          // Negative synchronous reset
       .i_start             (start_del_pcie8),      // Start sequence from beginning

       .o_fail              (o_fail_x8),            // Checker failed
       .o_test_complete     (o_test_complete_x8)    // Test is complete
      );

   // Fail if either master logic sees a mismatch
   assign o_fail = o_fail_x8 | o_fail_x16;
   
   // Assert when both masters have completd their transactions
   assign o_mstr_test_complete = o_test_complete_x8 & o_test_complete_x16;

endmodule : pcie_ref_design_top

