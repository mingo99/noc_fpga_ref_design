// ------------------------------------------------------------------
//
// Copyright (c) 2021  Achronix Semiconductor Corp.
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
//      Testbench utility functions
//      Initialise interfaces, define memory and NAP addresses
// ------------------------------------------------------------------


// -----------------------------------------------
// Initalize the PCIe x16 master and slave
// Set signals to 0
// -----------------------------------------------
task initialize_pciex16;
   pciex16_m_awid     = 'h0;
   pciex16_m_awaddr   = 'h0;
   pciex16_m_awlen    = 8'h0;
   pciex16_m_awsize   = 3'h0;
   pciex16_m_awburst  = 2'h0;
   pciex16_m_awlock   = 1'b0;
   pciex16_m_awqos    = 4'h0;
   pciex16_m_awvalid  = 1'b0;
   pciex16_m_wdata    = 'h0;
   pciex16_m_wstrb    = 'h0;
   pciex16_m_wlast    = 1'b0;
   pciex16_m_wvalid   = 1'b0;
   pciex16_m_bready   = 1'b0;
   pciex16_m_arid     = 'h0;
   pciex16_m_araddr   = 'h0;
   pciex16_m_arlen    = 8'h0;
   pciex16_m_arsize   = 3'h0;
   pciex16_m_arburst  = 2'h0;
   pciex16_m_arlock   = 1'b0;
   pciex16_m_arqos    = 4'h0;
   pciex16_m_arvalid  = 1'b0;
   
   pciex16_s_awid     = 'h0;
   pciex16_s_awaddr   = 'h0;
   pciex16_s_awlen    = 8'h0;
   pciex16_s_awsize   = 3'h0;
   pciex16_s_awburst  = 2'h0;
   pciex16_s_awlock   = 1'b0;
   pciex16_s_awqos    = 4'h0;
   pciex16_s_awvalid  = 1'b0;
   pciex16_s_wdata    = 'h0;
   pciex16_s_wstrb    = 'h0;
   pciex16_s_wlast    = 1'b0;
   pciex16_s_wvalid   = 1'b0;
   pciex16_s_bready   = 1'b0;
   pciex16_s_arid     = 'h0;
   pciex16_s_araddr   = 'h0;
   pciex16_s_arlen    = 8'h0;
   pciex16_s_arsize   = 3'h0;
   pciex16_s_arburst  = 2'h0;
   pciex16_s_arlock   = 1'b0;
   pciex16_s_arqos    = 4'h0;
   pciex16_s_arvalid  = 1'b0;
   pciex16_s_bresp    = 2'b00;
   pciex16_s_bid      = 'h0;

endtask; // initialize_pciex16

// -----------------------------------------------
// Initalize the PCIe x8 master and slave
// Set signals to 0
// -----------------------------------------------
task initialize_pciex8;
   pciex8_m_awid     = 'h0;
   pciex8_m_awaddr   = 'h0;
   pciex8_m_awlen    = 8'h0;
   pciex8_m_awsize   = 3'h0;
   pciex8_m_awburst  = 2'h0;
   pciex8_m_awlock   = 1'b0;
   pciex8_m_awqos    = 4'h0;
   pciex8_m_awvalid  = 1'b0;
   pciex8_m_wdata    = 'h0;
   pciex8_m_wstrb    = 'h0;
   pciex8_m_wlast    = 1'b0;
   pciex8_m_wvalid   = 1'b0;
   pciex8_m_bready   = 1'b0;
   pciex8_m_arid     = 'h0;
   pciex8_m_araddr   = 'h0;
   pciex8_m_arlen    = 8'h0;
   pciex8_m_arsize   = 3'h0;
   pciex8_m_arburst  = 2'h0;
   pciex8_m_arlock   = 1'b0;
   pciex8_m_arqos    = 4'h0;
   pciex8_m_arvalid  = 1'b0;

   pciex8_s_awid     = 'h0;
   pciex8_s_awaddr   = 'h0;
   pciex8_s_awlen    = 8'h0;
   pciex8_s_awsize   = 3'h0;
   pciex8_s_awburst  = 2'h0;
   pciex8_s_awlock   = 1'b0;
   pciex8_s_awqos    = 4'h0;
   pciex8_s_awvalid  = 1'b0;
   pciex8_s_wdata    = 'h0;
   pciex8_s_wstrb    = 'h0;
   pciex8_s_wlast    = 1'b0;
   pciex8_s_wvalid   = 1'b0;
   pciex8_s_bready   = 1'b0;
   pciex8_s_arid     = 'h0;
   pciex8_s_araddr   = 'h0;
   pciex8_s_arlen    = 8'h0;
   pciex8_s_arsize   = 3'h0;
   pciex8_s_arburst  = 2'h0;
   pciex8_s_arlock   = 1'b0;
   pciex8_s_arqos    = 4'h0;
   pciex8_s_arvalid  = 1'b0;
   pciex8_s_bresp    = 2'b00;
   pciex8_s_bid      = 'h0;

endtask; // initialize_pciex8


// -----------------------------------------
// Compare write transaction to the
// corresponding read transaction
// Tasks with references must be automatic
// -----------------------------------------
task automatic compare_dma_write_read_single;
   input [ADDR_WIDTH-1:0]        awaddr;
   input [ADDR_WIDTH-1:0]        araddr;
   ref   [7:0]                   dma_wdata[int];
   ref   [7:0]                   dma_rdata[int];
   input int                     write_awlen ;
   input [3 -1:0]                awsize;
   input [2 -1:0]                awburst;
   input [2 -1:0]                bresp;

   input int                     arlen ;
   input [3 -1:0]                arsize;
   input [2 -1:0]                arburst;
   input [2 -1:0]                rresp;

   int                           mod,mod_2;
   int                           len_count, total_len;

   
   dma_packet write_channel[$];
   dma_packet read_channel[$];

   write_channel.push_front( dma_packet'{addr: awaddr,  len :write_awlen, size: awsize, burst: awburst, resp:bresp } );
   read_channel.push_front(  dma_packet'{addr: araddr,  len :arlen, size: arsize, burst:arburst, resp:rresp} );

   $display("%0t : Write pkt queue print %p", $time, write_channel);
   $display("%0t : Read pkt queue print %p", $time, read_channel);

   $strobe("%0t : Write queue size  %d ", $time, write_channel.size() );
   $strobe("%0t : Read queue size  %d ", $time, read_channel.size() ); 

   if (write_channel[0] == read_channel[0]) begin
      $display("%0t : DMA address, size and resp match", $time);
   end else begin
      $fatal("DMA address, size and resp mismatch");
   end  
   

   mod = ((write_awlen % 64) == 0) ? 0 : 1;
   total_len = ( write_awlen/64) + mod;

   $display( "%0t : Compare task:: total_len  %d", $time,total_len );

   if (total_len > 15) begin 
      mod_2= ((total_len % 16) == 0) ? 0 : 1;
      len_count = ( total_len/16) + mod_2;
   end 
   else 
     len_count = 0;
   $display( "%0t : Compare task:: len_count  %d", $time,len_count );



   for (i =0; i<= (write_awlen-1) ; i++) begin 
      if (dma_wdata[i] !== dma_rdata[i]) begin
         $error("Index %d and Write data %h",i,dma_wdata[i]);
         $error("Index %d and Read data %h",i,dma_rdata[i]);
         $fatal("Write data to read data mismatch");
      end
   end
   $display("%0t : Write and read data match", $time);

   write_channel.delete();
   read_channel.delete();
endtask;





// ------------------------------------------
// Task to set up the addresses of all the
// AXI slaves in the system
// This includes the 16 GDDR6 channels, DDR4,
// and the AXI slave NAPs in the design
// ------------------------------------------
task slave_address_array;

   gddr_ddr_nap_addr[0].addr = `ACX_S7T1500_DDR4_BASE;
   gddr_ddr_nap_addr[1].addr = `ACX_S7T1500_GDDR6_0A_BASE;
   gddr_ddr_nap_addr[2].addr = `ACX_S7T1500_GDDR6_0B_BASE;
   gddr_ddr_nap_addr[3].addr = `ACX_S7T1500_GDDR6_1A_BASE;
   gddr_ddr_nap_addr[4].addr = `ACX_S7T1500_GDDR6_1B_BASE;
   gddr_ddr_nap_addr[5].addr = `ACX_S7T1500_GDDR6_2A_BASE;
   gddr_ddr_nap_addr[6].addr = `ACX_S7T1500_GDDR6_2B_BASE;
   gddr_ddr_nap_addr[7].addr = `ACX_S7T1500_GDDR6_3A_BASE;
   gddr_ddr_nap_addr[8].addr = `ACX_S7T1500_GDDR6_3B_BASE;
   gddr_ddr_nap_addr[9].addr = `ACX_S7T1500_GDDR6_4A_BASE;
   gddr_ddr_nap_addr[10].addr = `ACX_S7T1500_GDDR6_4B_BASE;
   gddr_ddr_nap_addr[11].addr = `ACX_S7T1500_GDDR6_5A_BASE;
   gddr_ddr_nap_addr[12].addr = `ACX_S7T1500_GDDR6_5B_BASE;
   gddr_ddr_nap_addr[13].addr = `ACX_S7T1500_GDDR6_6A_BASE;
   gddr_ddr_nap_addr[14].addr = `ACX_S7T1500_GDDR6_6B_BASE;
   gddr_ddr_nap_addr[15].addr = `ACX_S7T1500_GDDR6_7A_BASE;
   gddr_ddr_nap_addr[16].addr = `ACX_S7T1500_GDDR6_7B_BASE;

   gddr_ddr_nap_addr[0].slave_info = "DDR4       ";
   gddr_ddr_nap_addr[1].slave_info = "GDDR6 0A   "; 
   gddr_ddr_nap_addr[2].slave_info = "GDDR6 0B   "; 
   gddr_ddr_nap_addr[3].slave_info = "GDDR6 1A   "; 
   gddr_ddr_nap_addr[4].slave_info = "GDDR6 1B   "; 
   gddr_ddr_nap_addr[5].slave_info = "GDDR6 2A   "; 
   gddr_ddr_nap_addr[6].slave_info = "GDDR6 2B   "; 
   gddr_ddr_nap_addr[7].slave_info = "GDDR6 3A   "; 
   gddr_ddr_nap_addr[8].slave_info = "GDDR6 3B   "; 
   gddr_ddr_nap_addr[9].slave_info = "GDDR6 4A   "; 
   gddr_ddr_nap_addr[10].slave_info = "GDDR6 4B   "; 
   gddr_ddr_nap_addr[11].slave_info = "GDDR6 5A   "; 
   gddr_ddr_nap_addr[12].slave_info = "GDDR6 5B   "; 
   gddr_ddr_nap_addr[13].slave_info = "GDDR6 6A   "; 
   gddr_ddr_nap_addr[14].slave_info = "GDDR6 6B   "; 
   gddr_ddr_nap_addr[15].slave_info = "GDDR6 7A   "; 
   gddr_ddr_nap_addr[16].slave_info = "GDDR6 7B   ";


   // Set up the addresses for the NAPs connected to AXI slave NAPs
   // These will start at [17] and increment for each slave NAP
   i = 17; //[0:16] --> GDDR and DDR addr

   // AXI slave NAP at Column=7, Row=6
   gddr_ddr_nap_addr[i].addr   =  {7'b0001000,{4'h6},{3'h5},28'h0};
   gddr_ddr_nap_addr[i].slave_info = "NAP_COLUMN_7_NAP_ROW_6";
   $display("NAP row and column info  %s ", gddr_ddr_nap_addr[i].slave_info);
   $display("NAP to write address with index %d and address %h ",i, gddr_ddr_nap_addr[i].addr);
   $display("NAP to nap_row = %d and nap_column = %d ",6,7);
   i = i+1; // increment to next array element

   // AXI slave NAP at Column=3, Row=5
   gddr_ddr_nap_addr[i].addr   =  {7'b0001000,4'd2,3'd4,28'h0};
   gddr_ddr_nap_addr[i].slave_info = "NAP_COLUMN_3_NAP_ROW_5";
   $display("NAP row and column info  %s ", gddr_ddr_nap_addr[i].slave_info);
   $display("NAP to write address with index %d and address %h ",i, gddr_ddr_nap_addr[i].addr);
   $display("NAP to nap_row = %d and nap_column = %d ",5,3);
   i = i+1; // increment to next array element
   
   // AXI slave NAP at Column=5, Row=2
   gddr_ddr_nap_addr[i].addr   =  {7'b0001000,{4'h4},{3'h1},28'h0};
   gddr_ddr_nap_addr[i].slave_info = "NAP_COLUMN_5_NAP_ROW_2";
   $display("NAP row and column info  %s ", gddr_ddr_nap_addr[i].slave_info);
   $display("NAP to write address with index %d and address %h ",i, gddr_ddr_nap_addr[i].addr);
   $display("NAP to nap_row = %d and nap_column = %d ",2,5);
   i = i+1; // increment to next array element


   // AXI slave NAP at Column=1, Row=7
   gddr_ddr_nap_addr[i].addr   =  {7'b0001000,{4'h0},{3'h6},28'h0};
   gddr_ddr_nap_addr[i].slave_info = "NAP_COLUMN_1_NAP_ROW_7";
   $display("NAP row and column info  %s ", gddr_ddr_nap_addr[i].slave_info);
   $display("NAP to write address with index %d and address %h ",i, gddr_ddr_nap_addr[i].addr);
   $display("NAP to nap_row = %d and nap_column = %d ",7,1);
   i = i+1; // increment to next array element

   

endtask //
