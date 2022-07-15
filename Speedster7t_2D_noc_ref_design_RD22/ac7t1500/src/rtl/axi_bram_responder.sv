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
// Slave logic that connects to an AXI master NAP.
//      Uses a BRAM to store write data and sends back
//      the read data on a read transaction. Designed to
//      connect to an AXI master NAP and communicate on the NoC
// ------------------------------------------------------------------

`include "nap_interfaces.svh"

module axi_bram_responder
  #(
    parameter TGT_DATA_WIDTH = 0, // Target data width.
    parameter TGT_ADDR_WIDTH = 0,
    parameter NAP_COL        = 4'hx,
    parameter NAP_ROW        = 4'hx,
    parameter NAP_N2S_ARB_SCHED  = 32'hxxxxxxxx, // north-to-south arbitration schedule
    parameter NAP_S2N_ARB_SCHED  = 32'hxxxxxxxx  // south-to-north arbitration schedule
    )
   (
    // Inputs
    input wire i_clk,
    input wire i_reset_n // Negative synchronous reset
    );



   localparam AXI4_ID_WIDTH         = 8;
   localparam AXI4_SLAVE_ADDR_WIDTH = 9;                // BRAM for transactions is 512 deep
   localparam NAP_DATA_WIDTH        = TGT_DATA_WIDTH;
   localparam NAP_ADDR_WIDTH        = TGT_ADDR_WIDTH;



   logic [NAP_DATA_WIDTH-1:0] xact_r_dout; // read data
   logic [AXI4_ID_WIDTH-1:0] xact_ar_id; // AR transaction ID
   logic [AXI4_SLAVE_ADDR_WIDTH-1:0] xact_ar_addr;      // AR transaction address
   logic [7:0]                       xact_ar_len;       // AR transaction length, limit of 16
   logic [1:0]                       xact_ar_burst;     // Burst type for AR transaction
   logic                             xact_rd_en;        // Set read enable on BRAM
   logic                             xact_read_valid;   // Handling a valid read

   logic [1:0]                       xact_rd_avail;     // 2-pipe stage to when read data available
   logic [3:0]                       xact_ar_len_d1;    // delay 1 cycle
   logic [3:0]                       xact_ar_len_d2;    // delay 2 cycles to match with read out
   
   logic [NAP_DATA_WIDTH-1:0]        xact_r_dout_d1;    // read data flop, needed to buffer on ready low
   logic [NAP_DATA_WIDTH-1:0]        xact_r_dout_d2;    // read data flop, needed to buffer on ready low
   logic [1:0]                       r_dout_valid;      // which data buffers are valid
   logic                             hold_read;         // ready low while vaild high
   
   // synthesis synthesis_off
   // Following signal does not drive any loads, kept for simulation purposes only
   logic                             read_conflict;     // Trying to read at same address as current write
   // synthesis synthesis_on
   

   logic [NAP_DATA_WIDTH-1:0]        xact_w_din;        // Write data
   logic [AXI4_ID_WIDTH-1:0] xact_aw_id;                // AW transaction ID
   logic [AXI4_SLAVE_ADDR_WIDTH-1:0] xact_aw_addr;      // AW transaction address
   logic [7:0]                       xact_aw_len;       // AW transaction length, limit of 16
   logic [1:0]                       xact_aw_burst;     // Burst type for AW transaction
   logic [31:0]                      xact_wstrb;        // Write byte strobe
   logic                             xact_wr_en;        // Set write enable on BRAM
   logic                             xact_write_valid;  // Handling a valid write
   logic                             xact_wlast;
   
   logic                             write_conflict;    // Trying to write at same address as current read
   
   logic [1:0]                       xact_sbit_error_0;
   logic [1:0]                       xact_sbit_error_1;
   logic [1:0]                       xact_dbit_error_0;
   logic [1:0]                       xact_dbit_error_1;
   logic                             nap_output_rstn;
   logic                             nap_error_valid;
   logic [2:0]                       nap_error_info;


   // Create NAP interface
   // This contains all the AXI signals for NAP
   t_AXI4 #(
            .DATA_WIDTH (NAP_DATA_WIDTH),
            .ADDR_WIDTH (NAP_ADDR_WIDTH),
            .LEN_WIDTH  (8),
            .ID_WIDTH   (8))
   axi_if_mas() /* synthesis syn_keep=1 */;

   // Instantiate the NAP
   nap_master_wrapper
     #(
       .COLUMN (NAP_COL),
       .ROW    (NAP_ROW),
       .N2S_ARB_SCHED (NAP_N2S_ARB_SCHED),
       .S2N_ARB_SCHED (NAP_S2N_ARB_SCHED)
       )
   i_axi_master_nap(
                    // Inputs
                    .i_clk          (i_clk),
                    .i_reset_n      (i_reset_n),    // Negative synchronous reset
                    .nap            (axi_if_mas),   // Module is a master
                    // Outputs
                    .o_output_rstn  (nap_output_rstn),
                    .o_error_valid  (nap_error_valid),
                    .o_error_info   (nap_error_info)
                    );


   //-----------------------------------
   // Simple dual-port memory to
   // respond to write and read
   // transactions
   // address for this will be 9 bits
   // so that it fits nicely in a BRAM
   //-----------------------------------
   logic [31:0]                      dummy_dout; // unused data bits

   
   ACX_BRAM72K_SDP 
     #(
       .byte_width             (        8),
       .read_width             (      144),
       .write_width            (      144),
       .outreg_enable          (        1),
       .outreg_sr_assertion    ("clocked")
       ) 
   xact_mem_lo (
    .wrclk                  (i_clk         ),
    .din                    (xact_w_din[143:0]),
    .we                     (xact_wstrb[17:0]),
    .wren                   (xact_wr_en),
    .wraddr                 ({xact_aw_addr, 5'h00}),
    .wrmsel                 (1'b0),
    .rdclk                  (i_clk),
    .rden                   (xact_rd_en),
    .rdaddr                 ({xact_ar_addr, 5'h00}),
    .rdmsel                 (1'b0),
    .outlatch_rstn          (i_reset_n),
    .outreg_rstn            (i_reset_n),
    .outreg_ce              (1'b1),
    .dout                   (xact_r_dout[143:0]),
    .sbit_error             (xact_sbit_error_0),
    .dbit_error             (xact_dbit_error_0)
);

   ACX_BRAM72K_SDP 
     #(
       .byte_width             (        8),
       .read_width             (      144),
       .write_width            (      144),
       .outreg_enable          (        1),
       .outreg_sr_assertion    ("clocked")
       ) 
   xact_mem_hi (
    .wrclk                  (i_clk),
    .din                    ({32'h0, xact_w_din[255:144]}),
    .we                     ({4'h0, xact_wstrb[31:18]}),
    .wren                   (xact_wr_en),
    .wraddr                 ({xact_aw_addr, 5'h00}),
    .wrmsel                 (1'b0),
    .rdclk                  (i_clk),
    .rden                   (xact_rd_en),
    .rdaddr                 ({xact_ar_addr, 5'h00}),
    .rdmsel                 (1'b0),
    .outlatch_rstn          (i_reset_n),
    .outreg_rstn            (i_reset_n),
    .outreg_ce              (1'b1),
    .dout                   ({dummy_dout, xact_r_dout[255:144]}),
    .sbit_error             (xact_sbit_error_1),
    .dbit_error             (xact_dbit_error_1)
);


   // Register the data out if rready is low
   // Data has to be captured as it cannot be transmitted yet
   always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          r_dout_valid <= 2'b00;
        else if(axi_if_mas.rready && hold_read && !r_dout_valid[1]) // only 1 flopped, and ready again
          begin // keep one valid, but grab data from BRAM output
             xact_r_dout_d1 <= xact_r_dout;
             xact_r_dout_d2 <= xact_r_dout_d1;
          end
        else if((axi_if_mas.rvalid && axi_if_mas.rready) ||
                !xact_rd_avail[1]) // shift out valid data indicator
          r_dout_valid <= {1'b0, r_dout_valid[1]};
        else if(xact_rd_avail[1] && 
                (axi_if_mas.rvalid && !axi_if_mas.rready)) // data avail, but not ready
          begin
             xact_r_dout_d1 <= xact_r_dout;
             xact_r_dout_d2 <= xact_r_dout_d1;
             r_dout_valid <= {r_dout_valid[0], 1'b1};
          end
     end // always@ (posedge i_clk)

   // Indicate when a read hold occurs to handle the pipes
   always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          hold_read <= 1'b0;
        else if(axi_if_mas.rvalid && !axi_if_mas.rready) // indicate hold next cycle
          hold_read <= 1'b1;
        else // can release
          hold_read <= 1'b0;
     end
   
   
   //-----------------------------------
   // Process read transaction
   // grab the ID, address, length,
   // and burst type. For now 
   // ignores burst size, lock, and 
   // qos signals
   //
   // Then send out read data in
   // response
   //
   // This uses a BRAM to store write
   // data and read back the read
   // data, using the address
   //
   // Uses a state machine to track
   // the transaction until complete
   //-----------------------------------
   enum  {RD_IDLE, RD_CAPTURE, RD_SEND} rd_xact_state;   
   
   //------------------------------------------------
   // State machine for processing read transactions
   //------------------------------------------------
   always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          rd_xact_state <= RD_IDLE;
        else 
          begin
             case (rd_xact_state)
               RD_IDLE: // wait for the next transaction
                 begin
                    if(axi_if_mas.arvalid && axi_if_mas.arready) // both ready and valid
                      rd_xact_state <= RD_CAPTURE;
                    else // wait until valid transaction
                      rd_xact_state <= RD_IDLE;
                 end
               RD_CAPTURE: // capture the signals, check there is no conflict with write
                 begin // burst is 16 at most, check if top address matches at all
                    if((xact_ar_addr[8:4] == xact_aw_addr[8:4]) &&
                       xact_write_valid)// conflict detected
                      rd_xact_state <= RD_CAPTURE; // wait here, don't read yet
                    else // perform the read
                      rd_xact_state <= RD_SEND;
                 end
               RD_SEND: // send out read until burst is complete
                 begin
                    if((xact_ar_len == 8'h00) && axi_if_mas.rready) // read full burst
                      rd_xact_state <= RD_IDLE;
                    else // keep reading
                      rd_xact_state <= RD_SEND;
                 end
               default: rd_xact_state <= RD_IDLE;
             endcase // case (rd_xact_state)
          end // else: !if(!i_reset_n)
     end // always@ (posedge i_clk)

   assign xact_rd_en = (rd_xact_state == RD_SEND);

   // Create pipe to determine when read data is available
   always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          xact_rd_avail[1:0] <= 2'b00;
        else if(axi_if_mas.rready) // don't shift if holding
          xact_rd_avail[1:0] <= {xact_rd_avail[0], xact_rd_en};
     end


   // Monitor for any read conflict
   // Does not drive any loads, but was featuring in critical path.
   // Remove from synthesised designs for clarity
   // synthesis synthesis_off
   assign read_conflict = ((xact_ar_addr[8:4] == xact_aw_addr[8:4]) &&
                           (rd_xact_state == RD_CAPTURE) &&
                           xact_write_valid);
   // synthesis synthesis_on


   //--------------------------------
   // Register the transaction signals
   //--------------------------------
   always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          begin
             xact_ar_addr <= {AXI4_SLAVE_ADDR_WIDTH{1'b0}};  // AR transaction address
          end
        else if(axi_if_mas.arready && axi_if_mas.arvalid) // capture transaction signals from NAP
          begin
             xact_ar_addr <= axi_if_mas.araddr[13:5]; // AR transaction starting address
          end
        else if((rd_xact_state == RD_SEND) && axi_if_mas.rready) // still have more burst reads
          begin
             xact_ar_addr <= xact_ar_addr + 1; // increment address
          end
     end // always@ (posedge i_clk)

   always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          begin
             xact_ar_len <= 8'h00;   // AR transaction length, limit of 16
          end
        else if(axi_if_mas.arready && axi_if_mas.arvalid) // capture transaction signals from NAP
          begin
             xact_ar_len <= axi_if_mas.arlen;   // length of read burst
          end
        else if((rd_xact_state == RD_SEND) && (|(xact_ar_len[7:0])) && axi_if_mas.rready) // still have more burst reads
          begin
             xact_ar_len <= xact_ar_len - 1; // decrement after read
          end
     end // always@ (posedge i_clk)

   always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          begin
             xact_ar_id <= {AXI4_ID_WIDTH{1'b0}}; // AR transaction ID
             xact_ar_burst <= 2'b00; // burst type for AR transaction
          end
        else if(axi_if_mas.arready && axi_if_mas.arvalid) // capture transaction signals from NAP
          begin
             xact_ar_id <= axi_if_mas.arid; // AR transaction ID
             xact_ar_burst <= axi_if_mas.arburst; // type of read burst
          end
     end // always@ (posedge i_clk)

    always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          begin
             xact_read_valid <= 1'b0;
          end
        else if(axi_if_mas.arready && axi_if_mas.arvalid) // capture transaction signals from NAP
          begin
             xact_read_valid <= 1'b1;
          end
        else if(rd_xact_state == RD_IDLE) // not reading
          begin
             xact_read_valid <= 1'b0;
          end
     end // always@ (posedge i_clk)

   // flop the length counter to match with read output
   always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          begin
             xact_ar_len_d1 <= 4'h0;
             xact_ar_len_d2 <= 4'h0;
          end
        else if(axi_if_mas.rready) // only need 4 bits since length can only be 16 beats
          begin
             xact_ar_len_d1 <= xact_ar_len[3:0];
             xact_ar_len_d2 <= xact_ar_len_d1;
          end
     end // always@ (posedge i_clk)

   // Drive AR ready
   always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          begin
             axi_if_mas.arready <= 1'b0; // keep ready low while in reset
          end
        else if((rd_xact_state == RD_IDLE) && !axi_if_mas.arvalid && !xact_rd_avail[1]) // waiting for new transaction
          begin
             axi_if_mas.arready <= 1'b1;
          end
        else // keep low until getting new transaction
          begin
             axi_if_mas.arready <= 1'b0;
          end
     end // always@ (posedge i_clk)

   // Drive read output signals
   always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          begin
             axi_if_mas.rvalid <= 1'b0;
          end
        else if(!axi_if_mas.rready) // not ready, hold values
          begin
             axi_if_mas.rresp <= axi_if_mas.rresp;
             axi_if_mas.rid <= axi_if_mas.rid;
             axi_if_mas.rvalid <= axi_if_mas.rvalid;
             axi_if_mas.rlast <= axi_if_mas.rlast;
          end // if (!axi_if_mas.rready)
        else if(xact_rd_avail[1] && (xact_ar_len_d2 == 4'h0)) // the data is valid, and last data
          begin
             axi_if_mas.rresp <= 2'b00; // response is ok
             axi_if_mas.rid <= xact_ar_id;
             axi_if_mas.rvalid <= 1'b1;
             axi_if_mas.rlast <= 1'b1;
          end // if (xact_rd_avail[1] && (xact_ar_len_d2 == 4'h0))
        else if(xact_rd_avail[1]) // send out read
          begin
             axi_if_mas.rresp <= 2'b00; // response is ok
             axi_if_mas.rid <= xact_ar_id;
             axi_if_mas.rvalid <= 1'b1;
             axi_if_mas.rlast <= 1'b0;
          end // if (xact_rd_avail[1])
        else
          axi_if_mas.rvalid <= 1'b0;
     end // always@ (posedge i_clk)

   // Drive read output signals
   always@(posedge i_clk)
     begin
        if(!axi_if_mas.rready) // not ready, hold values
          begin
             axi_if_mas.rdata <= axi_if_mas.rdata;
          end // if (!axi_if_mas.rready)
        else if(hold_read && (xact_ar_len_d2 == 4'h0)) // holding on last data, grab from BRAM output
          axi_if_mas.rdata <= xact_r_dout;
        else //if(xact_rd_avail[1])
          begin // grab the valid flopped data
             case(r_dout_valid[1:0])
               2'b01: axi_if_mas.rdata <= xact_r_dout_d1;
               2'b11: axi_if_mas.rdata <= xact_r_dout_d2;
               default: axi_if_mas.rdata <= xact_r_dout;
             endcase // case (r_dout_valid[1:0])
          end
     end // always@ (posedge i_clk)

   //-------------------------------------------------
   // Process write transaction
   // grab the ID, address, length,
   // and burst type. For now 
   // ignores burst size, lock, and 
   // qos signals
   //
   // Then write the data and send out
   // the write response
   //
   // This uses a BRAM to store write
   // data and read back the read
   // data, using the address
   //
   // Uses a state machine to track
   // the transaction until complete
   //-----------------------------------
   enum  {WR_IDLE, WR_CAPTURE, WR_DATA, WR_RSP} wr_xact_state;   
   
   //------------------------------------------------
   // state machine for processing write transactions
   //------------------------------------------------
   always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          wr_xact_state <= WR_IDLE;
        else 
          begin
             case (wr_xact_state)
               WR_IDLE: // wait for the next transaction
                 begin
                    if(axi_if_mas.awvalid && axi_if_mas.awready &&
                       axi_if_mas.wvalid && axi_if_mas.wready && axi_if_mas.wlast) // both addr and write valid, skip capture
                      wr_xact_state <= WR_DATA;
                    else if(axi_if_mas.awvalid && axi_if_mas.awready) // both ready and valid
                      wr_xact_state <= WR_CAPTURE;
                    else // wait until valid transaction
                      wr_xact_state <= WR_IDLE;
                 end
               WR_CAPTURE: // capture the signals, check there is no conflict with read
                 begin // burst is 16 at most, check if top address matches at all
                    wr_xact_state <= WR_DATA;
                 end
               WR_DATA: // write data into BRAM until burst is complete
                 begin
                    if(xact_wlast && !write_conflict) // write full burst
                      wr_xact_state <= WR_RSP;
                    else // keep reading
                      wr_xact_state <= WR_DATA;
                 end
               WR_RSP: // send out the write response
                 begin
                    if(axi_if_mas.bready) // done sending response
                      wr_xact_state <= WR_IDLE;
                    else // wait for ready
                      wr_xact_state <= WR_RSP;
                 end
               default: wr_xact_state <= WR_IDLE;
             endcase // case (wr_xact_state)
          end // else: !if(!i_reset_n)
     end // always@ (posedge i_clk)


   // Check if incoming write conflicts with on-going read
   assign write_conflict = ((xact_ar_addr[8:4] == xact_aw_addr[8:4]) &&
                            ((wr_xact_state == WR_CAPTURE) || (wr_xact_state == WR_DATA)) &&
                            xact_read_valid);

   //------------------------------------
   // capture transaction signals
   //------------------------------------

   always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          begin
             xact_aw_id <= {AXI4_ID_WIDTH{1'b0}}; // AR transaction ID
             xact_aw_addr <= {AXI4_SLAVE_ADDR_WIDTH{1'b0}};  // AR transaction address
             xact_aw_len <= 8'h00;   // AR transaction length, limit of 16
             xact_aw_burst <= 2'b00; // burst type for AR transaction
             xact_write_valid <= 1'b0;
          end
        else if(axi_if_mas.awready && axi_if_mas.awvalid) // capture transaction signals from NAP
          begin
             xact_aw_id <= axi_if_mas.awid; // AR transaction ID
             xact_aw_addr <= axi_if_mas.awaddr[13:5]; // AR transaction starting address
             xact_aw_len <= axi_if_mas.awlen;   // length of write burst
             xact_aw_burst <= axi_if_mas.awburst; // type of write burst
             xact_write_valid <= 1'b1;
          end
        else if(xact_wr_en) // still have more burst writes
          begin
             xact_aw_addr <= xact_aw_addr + 1;
          end
        else if(wr_xact_state == WR_IDLE) // waiting for new write
          begin
             xact_write_valid <= 1'b0;
          end
     end // always@ (posedge i_clk)


   // Capture write data
   always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          begin
             xact_wr_en <= 1'b0;
             xact_wstrb <= 32'h0;
             xact_wlast <= 1'b0;
          end
        else if(axi_if_mas.wvalid && axi_if_mas.wready) // data is valid and ready
          begin
             xact_wr_en <= 1'b1;
             xact_wstrb <= axi_if_mas.wstrb;
             xact_wlast <= axi_if_mas.wlast;
             xact_w_din <= axi_if_mas.wdata;
          end
        else if(write_conflict) // there is write conflict
          begin // hold the data, don't write it
             xact_wr_en <= 1'b0;
             xact_wstrb <= xact_wstrb;
             xact_wlast <= xact_wlast;
             xact_w_din <= xact_w_din;
          end
        else if(xact_wlast)
          begin
             xact_wr_en <= 1'b1; // write last data
             xact_wstrb <= 32'h0;
             xact_wlast <= 1'b0;
          end
        else
          begin
             xact_wr_en <= 1'b0;
             xact_wstrb <= 32'h0;
             xact_wlast <= 1'b0;
          end  
     end // always@ (posedge i_clk)

   // Drive AW ready
   always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          begin
             axi_if_mas.awready <= 1'b0; // keep low during reset
          end
        else if((wr_xact_state == WR_IDLE) && !axi_if_mas.awvalid) // waiting for a new write request
          begin
             axi_if_mas.awready <= 1'b1;
          end
        else
          begin
             axi_if_mas.awready <= 1'b0; // keep low otherwise
          end
     end // always@ (posedge i_clk)

   // Drive W ready
   always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          begin
             axi_if_mas.wready  <= 1'b0; // keep low during reset
          end
        else if((wr_xact_state == WR_IDLE) && !axi_if_mas.wvalid) // waiting for a new write request
          begin
             axi_if_mas.wready  <= 1'b1;
          end
        else if(((wr_xact_state == WR_CAPTURE) && axi_if_mas.wvalid && axi_if_mas.wlast) ||
                write_conflict)
          begin // last data or conflicting address with on-going read
             axi_if_mas.wready <= 1'b0; // got last data, lower until next write
          end
        else if(axi_if_mas.wvalid && write_conflict) // haven't gotten last data
          begin
             axi_if_mas.wready <= 1'b0;
          end
        else if(axi_if_mas.wvalid && !write_conflict && (!axi_if_mas.wlast || !axi_if_mas.wready)) // haven't gotten last data
          begin // or there was a conflict and grabbing the last data now
             axi_if_mas.wready <= 1'b1;
          end
        else
          begin
             axi_if_mas.wready <= 1'b0; // keep low otherwise
          end
     end // always@ (posedge i_clk)

   // Drive write response signals
   always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          begin
             axi_if_mas.bvalid <= 1'b0;
          end
        else if(wr_xact_state == WR_RSP) // send out write response signals
          begin
             axi_if_mas.bvalid <= 1'b1;
             axi_if_mas.bid <= xact_aw_id;
             axi_if_mas.bresp <= 2'b00;
          end
        else
          begin
             axi_if_mas.bvalid <= 1'b0;
          end
     end // always@ (posedge i_clk)

`ifdef ACX_USE_SNAPSHOT

    ACX_PROBE_POINT #(
        .width  (12),
        .tag    ("bram_rsp")
    ) x_probe_snapshot (
        .din({
            axi_if_mas.rlast,  axi_if_mas.rready,  axi_if_mas.rvalid,
            axi_if_mas.arready, axi_if_mas.arvalid,
            axi_if_mas.bready,  axi_if_mas.bvalid,
            axi_if_mas.wlast,  axi_if_mas.wready,  axi_if_mas.wvalid,
            axi_if_mas.awready, axi_if_mas.awvalid
            })
    );

`endif
   
endmodule : axi_bram_responder

