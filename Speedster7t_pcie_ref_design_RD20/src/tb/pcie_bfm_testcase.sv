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
//      BFM Mode Test case
// ------------------------------------------------------------------


`include "ac7t1500_utils.svh"
`include "pcie_defines.svh"



module pcie_bfm_testcase (

  input         reset_n,
  input         test_start,
  output logic  pciex8_bfm_test_done,
  output logic  pciex16_bfm_test_done
);

  // -------------------------
  localparam ADDR_WIDTH         = 42;
  localparam ID_WIDTH           = 5; 
  localparam DATA_WIDTH         = 512;
  localparam LEN_WIDTH          = 4;
  localparam STRB_WIDTH         = DATA_WIDTH/8;
  localparam SLAVE_ADDR_WIDTH   = 40;
  localparam SLAVE_ID_WIDTH     = 6;
   
  // AXI Interface
  `ACX_AXI_MASTER_PORT(pciex8);
  `ACX_AXI_SLAVE_PORT(pciex8);
  `ACX_AXI_MASTER_PORT(pciex16);
  `ACX_AXI_SLAVE_PORT(pciex16);

  logic [7:0]                 slavex16_write_id_queue[$];
  logic [(16*DATA_WIDTH)-1:0] slavex16_data[int];
  int                         slvx16_wr_num_bytes;
  logic [7:0]                 slavex16_data_bytes  [int];

  logic [7:0]                 bidx16;
  logic [9:0]                 slavex16_read_id_queue[$];
  int                         read_slvx16_num_bytes,read_id_x16;
  logic [7:0]                 slavex16_rid;

  int                         addr_count_pcie_x16;
  int                         reg_addr_count_pcie_x16;
  int                         num_bytes_x16;
  logic [31:0]                counter_value_x16;
  logic [31:0]                read_count_value_x16;

  logic [7:0]                 one_byte_data_x16  [int];
  logic [7:0]                 one_byte_read_data_x16  [int];

  logic [7:0]                 slavex8_write_id_queue[$];
  logic [(16*DATA_WIDTH)-1:0] slavex8_data[int];
  int                         slvx8_wr_num_bytes;
  logic [7:0]                 slavex8_data_bytes  [int];
  logic [7:0]                 bidx8;

  logic [9:0]                 slavex8_read_id_queue[$];
  int                         read_slvx8_num_bytes,read_id_x8;

  logic [7:0]                 slavex8_rid;
  logic [6:0]                 cnt = 0;

  logic [7:0]                 one_byte_data_x8  [int];
  logic [7:0]                 one_byte_read_data_x8  [int];

  int                         i, j;
  int                         addr_count;
  int                         reg_addr_count;
  int                         num_bytes;
  logic [31:0]                counter_value;
  logic [31:0]                read_count_value;
   
   
   // define packet and address packet types
   typedef struct                {
      bit [ ADDR_WIDTH:0]        addr;  
      bit [ DATA_WIDTH:0]        data; 
      bit [LEN_WIDTH :0]         len; 
      bit [3 -1 :0]              size;
      bit [2 -1 :0]              burst;
      bit [2 -1 :0]              resp;
   } packet_t;

   typedef struct                {
      bit [ ADDR_WIDTH:0]        addr;
      int                        len; 
      bit [3 -1 :0]              size;
      bit [2 -1 :0]              burst;
      bit [2 -1 :0]              resp;
   } dma_packet;

   typedef struct                {
      bit [ ADDR_WIDTH:0]        addr;  
      bit [200:0]                slave_info; 
   } addr_pkt;
   
   addr_pkt gddr_ddr_nap_addr[integer];

   //---------------------------


`include "acx_slave_reg_def.svh"   
`include "tb_pcie_ref_utils.sv"

   // set up the addresses for NAPs, GDDR6 subsystems, and DDR4
   initial begin 
      slave_address_array();
      $display("Total NAP is %d ",cnt);
      for( j =0; j <=5071; j++)
        begin 
           one_byte_data_x8[j] = $random;
           one_byte_data_x16[j] = $random;
        end
   end // initial begin
   
//===========================================================================
   // Start the BFM Mode test
//===========================================================================

`ifndef ACX_PCIE_0_FULL
   //--------------------------------------
   // Kick off transactions from PCIe x8
   //--------------------------------------
   
   initial begin

      pciex8_bfm_test_done    <= 0;

      @(posedge reset_n);  // Wait for reset deassertion.
      
      initialize_pciex8();
      pciex8_m_awid    <= $urandom;
      pciex8_m_arid    <= $urandom;
      pciex8_m_awlen   <= 3'b000 ;
      pciex8_m_arlen   <= 3'b000 ;
      pciex8_m_awsize  <= 3'h5;
      pciex8_m_awburst <= 2'b01;
      pciex8_m_awlock  <= 1'b0;
      pciex8_m_awqos   <= 4'h0;
      pciex8_m_arsize  <= 3'h5;
      pciex8_m_arburst <= 2'b01;
      pciex8_m_arlock  <= 1'b0;
      pciex8_m_arqos   <= 4'h0;
      pciex8_m_wstrb   <= 64'h00000000ffffffff;
      

      //----------------------------------------
      // Run through the DMA writes and reads
      // using PCIex8 master
      //----------------------------------------
      
      for (addr_count= 0;  addr_count<19; addr_count++) begin 
         pciex8_m_awaddr <= gddr_ddr_nap_addr[addr_count].addr;
         if(addr_count < 17) // going to a NAP
           begin
              pciex8_m_awaddr[27:6] <=  22'h000000; //PCIe Narrow transfer : axi addr[5] = 0
              for (num_bytes=64; num_bytes <= (64*17); num_bytes=num_bytes+256)
                begin
                   pciex8_m_wdata[511:0] <= {16{$random}};
                   pciex8_m_awid    <= $urandom;
                   pciex8_m_arid    <= $urandom;

                   for(j =0; j <=num_bytes; j++)
                     begin 
                        one_byte_data_x8[j] = $random;
                     end

                   
                   ac7t1500.pcie1.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.
                   $strobe("PCIEX8 :: Write address %h ", pciex8_m_awaddr );
                   $strobe("PCIEx8 as master requesting to Write to %s",gddr_ddr_nap_addr[addr_count].slave_info);
                   
                   $display("PCIEX8 ::addr_count  %d ", addr_count );
                   $display("PCIEX8 ::Length  %d ", num_bytes );
                   

                   ac7t1500.pcie1.master.write_dma(pciex8_m_awaddr,one_byte_data_x8,num_bytes, pciex8_m_bresp);
                   
                   ac7t1500.pcie1.master.read_dma(pciex8_m_awaddr,num_bytes,one_byte_read_data_x8, pciex8_m_rresp);
                   
                   compare_dma_write_read_single(pciex8_m_awaddr,pciex8_m_awaddr,one_byte_data_x8,one_byte_read_data_x8,
                                                 num_bytes, pciex8_m_awsize,pciex8_m_awburst,pciex8_m_bresp,
                                                 num_bytes, pciex8_m_arsize,pciex8_m_arburst,pciex8_m_rresp);

                   pciex8_m_awaddr[27:6] <= pciex8_m_awaddr[27:6] + 8'h20; // increment
                   

                end // for (len=0; len < 16; len=len+1)
           end // if (addr_count <= 16)
         else // BRAM responder NAPs
           begin
              // skip over the address for NAP talking to PCIex16
              // need to change to different NAP that talks to PCIex8
              addr_count <= addr_count + 1;
              pciex8_m_awaddr <= gddr_ddr_nap_addr[addr_count].addr;
              pciex8_m_awaddr[27:6] <=  22'h000000; //PCIe Narrow transfer : axi addr[5] = 0
              pciex8_m_awid    <= $urandom;
              pciex8_m_arid    <= $urandom;
              
              for (num_bytes=64; num_bytes < (64*4); num_bytes=num_bytes+64)
                begin
                   ac7t1500.pcie1.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock
                   $strobe("PCIEX8 :: Write address %h ", pciex8_m_awaddr );
                   $strobe("PCIEx8 as master requesting to Write to %s",gddr_ddr_nap_addr[addr_count].slave_info);
                   
                   $display("PCIEX8 ::addr_count  %d ", addr_count );
                   $display("PCIEX8 ::Length  %d ", num_bytes );
                   
                   ac7t1500.pcie1.master.write_dma(pciex8_m_awaddr,one_byte_data_x8,num_bytes, pciex8_m_bresp);
                   
                   ac7t1500.pcie1.master.read_dma(pciex8_m_awaddr,num_bytes,one_byte_read_data_x8, pciex8_m_rresp);
                   compare_dma_write_read_single(pciex8_m_awaddr,pciex8_m_awaddr,one_byte_data_x8,
                                                 one_byte_read_data_x8,num_bytes, pciex8_m_awsize,
                                                 pciex8_m_awburst,pciex8_m_bresp,num_bytes, pciex8_m_arsize,
                                                 pciex8_m_arburst,pciex8_m_rresp);

                   pciex8_m_awaddr[27:6] <= pciex8_m_awaddr[27:6] + 8'h20; // increment
                   

                end // for (num_bytes=31; num_bytes < (16*4); num_bytes=num_bytes+32)
           end // else: !if(addr_count <= 16)
         
         
      end // for (addr_count= 0;  addr_count<19; addr_count++)



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
      
      
      for(reg_addr_count= 0; reg_addr_count<8; reg_addr_count++) begin
         num_bytes <= 4;
         pciex8_m_awaddr <= gddr_ddr_nap_addr[20].addr;
         pciex8_m_awaddr[27:0] <= `REG_CFG_0_ADDR + {reg_addr_count << 6};
         pciex8_m_wdata[255:0] <= {$random}   ;//GDDR, DDR and NAP supports 256 bits of data.
         pciex8_m_awid    <= $urandom;
         pciex8_m_arid    <= $urandom;
         for(j =0; j <num_bytes; j++)
           begin 
              one_byte_data_x8[j] = $random;
           end
         ac7t1500.pcie1.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock
         $strobe("PCIEX8 :: Write address %h ", pciex8_m_awaddr );
         $strobe("Pciex8 as master requesting to Write to %s",gddr_ddr_nap_addr[20].slave_info);
         
         $display("PCIEX8 ::reg_addr_count  %d ", reg_addr_count );
         
         ac7t1500.pcie1.master.write(pciex8_m_awaddr,one_byte_data_x8,num_bytes,pciex8_m_bresp);

         ac7t1500.pcie1.master.read(pciex8_m_awaddr,num_bytes,one_byte_read_data_x8,pciex8_m_rresp);

         $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[20].slave_info );
         $strobe("Pciex8 :: Read address %h", pciex8_m_awaddr); 

         compare_dma_write_read_single(pciex8_m_awaddr,pciex8_m_awaddr,one_byte_data_x8,
                                       one_byte_read_data_x8,num_bytes, pciex8_m_awsize,
                                       pciex8_m_awburst,pciex8_m_bresp,num_bytes, 
                                       pciex8_m_arsize,pciex8_m_arburst,pciex8_m_rresp);

      end // for (addr_count= 0;  addr_count<8; addr_count++)
      
      // -----------------------------------
      // loop through read/write registers
      // These are 4 64-bit registers
      // -----------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Writing and Reading the four 64-bit Registers");
      $display ("-------------------------------");
      
      for(reg_addr_count= 24; reg_addr_count<28; reg_addr_count++) begin
         num_bytes <= 8;
         pciex8_m_awaddr <= gddr_ddr_nap_addr[20].addr;
         pciex8_m_awaddr[27:0] <= `REG_CFG_0_ADDR + {reg_addr_count << 6};
         pciex8_m_awid    <= $urandom;
         pciex8_m_arid    <= $urandom;
         for(j =0; j <num_bytes; j++)
           begin 
              one_byte_data_x8[j] = $random;
           end
         ac7t1500.pcie1.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.
         $strobe("PCIEX8 :: Write address %h ", pciex8_m_awaddr );
         $strobe("Pciex8 as master requesting to Write to %s",gddr_ddr_nap_addr[20].slave_info);
         
         $display("PCIEX8 ::reg_addr_count  %d ", reg_addr_count );
         
         ac7t1500.pcie1.master.write(pciex8_m_awaddr,one_byte_data_x8,num_bytes,pciex8_m_bresp);

         ac7t1500.pcie1.master.read(pciex8_m_awaddr,num_bytes,one_byte_read_data_x8,pciex8_m_rresp);

         $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[20].slave_info );
         $strobe("Pciex8 :: Read address %h", pciex8_m_awaddr); 
         compare_dma_write_read_single(pciex8_m_awaddr,pciex8_m_awaddr,one_byte_data_x8,
                                       one_byte_read_data_x8,num_bytes, pciex8_m_awsize,
                                       pciex8_m_awburst,pciex8_m_bresp,num_bytes, 
                                       pciex8_m_arsize,pciex8_m_arburst,pciex8_m_rresp);
      end
      
      // -----------------------------------
      // loop through read-only registers
      // These are 8 32-bit registers
      // Excpected value is addr + bias
      // In this case, Addr + 0
      // -----------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Reading the 8 read-only Registers");
      $display ("-------------------------------");

      for(reg_addr_count= 8; reg_addr_count<16; reg_addr_count++) begin
         num_bytes <= 4;
         pciex8_m_awaddr <= gddr_ddr_nap_addr[20].addr;
         pciex8_m_awaddr[27:0] <= `REG_CFG_0_ADDR + {reg_addr_count << 6};
         pciex8_m_awid    <= $urandom;
         pciex8_m_arid    <= $urandom;
         pciex8_m_wdata[255:0] <= `REG_CFG_0_ADDR + {reg_addr_count << 6};// data is same as addr            
         ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 

         one_byte_data_x8[0] = pciex8_m_wdata[7:0];
         one_byte_data_x8[1] = pciex8_m_wdata[15:8];
         one_byte_data_x8[2] = pciex8_m_wdata[23:16];
         one_byte_data_x8[3] = pciex8_m_wdata[31:24];
         
         ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
         $strobe("PCIEX8 :: Read address %h ", pciex8_m_awaddr );
         $display("PCIEX8 ::reg_addr_count  %d ", reg_addr_count );
         
         ac7t1500.pcie1.master.read(pciex8_m_awaddr,num_bytes,one_byte_read_data_x8,pciex8_m_rresp);

         $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[20].slave_info );
         $strobe("Pciex8 :: Read address %h and read  data %h", pciex8_m_awaddr, pciex8_m_rdata); 

         compare_dma_write_read_single(pciex8_m_awaddr,pciex8_m_awaddr,one_byte_data_x8,
                                       one_byte_read_data_x8,num_bytes, pciex8_m_awsize,
                                       pciex8_m_awburst,pciex8_m_bresp,num_bytes, 
                                       pciex8_m_arsize,pciex8_m_arburst,pciex8_m_rresp);
      end
      

      //-------------------------------------
      // read on clear register
      // first write to set the value
      // then read it back
      // on second read it should be all 0s
      //-------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Writing and Reading the clear-on-read register");
      $display ("-------------------------------");

      num_bytes <= 4;
      pciex8_m_awaddr <= gddr_ddr_nap_addr[20].addr;
      pciex8_m_awaddr[27:0] <= `REG_CLEAR_ON_RD_ADDR;
      pciex8_m_awid    <= $urandom;
      pciex8_m_arid    <= $urandom;
      for(j =0; j <num_bytes; j++)
        begin 
           one_byte_data_x8[j] = $random;
        end

      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 

      $strobe("PCIEX8 :: Write address %h ", pciex8_m_awaddr );
      $strobe("Pciex8 as master requesting to Write to %s",gddr_ddr_nap_addr[20].slave_info);      
      $display("PCIEX8 ::reg_addr_count  %d ", reg_addr_count );
      
      ac7t1500.pcie1.master.write(pciex8_m_awaddr,one_byte_data_x8,num_bytes,pciex8_m_bresp);

      ac7t1500.pcie1.master.read(pciex8_m_awaddr,num_bytes,one_byte_read_data_x8,pciex8_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[20].slave_info );
      $strobe("Pciex8 :: Read address %h and read  data %h", pciex8_m_awaddr, pciex8_m_rdata); 
      compare_dma_write_read_single(pciex8_m_awaddr,pciex8_m_awaddr,one_byte_data_x8,
                                    one_byte_read_data_x8,num_bytes, pciex8_m_awsize,
                                    pciex8_m_awburst,pciex8_m_bresp,num_bytes, 
                                    pciex8_m_arsize,pciex8_m_arburst,pciex8_m_rresp);

      // Read a second time to clear the register, make sure the read result is 0
      pciex8_m_arid    <= $urandom;

      ac7t1500.pcie1.master.read(pciex8_m_awaddr,num_bytes,one_byte_read_data_x8,pciex8_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[20].slave_info );
      $strobe("Pciex8 :: Read address %h and read  data %h", pciex8_m_awaddr, pciex8_m_rdata); 
      // make sure it's 0 on 2nd read
      for(j =0; j <num_bytes; j++)
        begin 
           one_byte_data_x8[j] = 8'h00;
        end
      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      compare_dma_write_read_single(pciex8_m_awaddr,pciex8_m_awaddr,one_byte_data_x8,
                                    one_byte_read_data_x8,num_bytes, pciex8_m_awsize,
                                    pciex8_m_awburst,pciex8_m_bresp,num_bytes, 
                                    pciex8_m_arsize,pciex8_m_arburst,pciex8_m_rresp);

      

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

      num_bytes <= 4;
      pciex8_m_awaddr <= gddr_ddr_nap_addr[20].addr;
      pciex8_m_awaddr[27:0] <= `REG_IRQ_0_ADDR;
      pciex8_m_wdata[255:0] <= $random   ;// 32-bit random data
      pciex8_m_awid    <= $urandom;
      pciex8_m_arid    <= $urandom;

      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      one_byte_data_x8[0] = pciex8_m_wdata[7:0];
      one_byte_data_x8[1] = pciex8_m_wdata[15:8];
      one_byte_data_x8[2] = pciex8_m_wdata[23:16];
      one_byte_data_x8[3] = pciex8_m_wdata[31:24];
      
      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      $strobe("PCIEX8 :: Write address %h ", pciex8_m_awaddr );
      $strobe("PCIEX8 :: Write  data %h ",  pciex8_m_wdata);
      $strobe("Pciex8 as master requesting to Write to %s",gddr_ddr_nap_addr[20].slave_info);
      
      $display("PCIEX8 ::reg_addr_count  %d ", reg_addr_count );
      
      ac7t1500.pcie1.master.write(pciex8_m_awaddr,one_byte_data_x8,num_bytes,pciex8_m_bresp);

      ac7t1500.pcie1.master.read(pciex8_m_awaddr,num_bytes,one_byte_read_data_x8,pciex8_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[20].slave_info );
      $strobe("Pciex8 :: Read address %h and read  data %h", pciex8_m_awaddr, pciex8_m_rdata); 
      compare_dma_write_read_single(pciex8_m_awaddr,pciex8_m_awaddr,one_byte_data_x8,
                                    one_byte_read_data_x8,num_bytes, pciex8_m_awsize,
                                    pciex8_m_awburst,pciex8_m_bresp,num_bytes, 
                                    pciex8_m_arsize,pciex8_m_arburst,pciex8_m_rresp);

      // check that the Master IRQ register is set to 1
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Check the master IRQ register is set to 1");
      $display ("-------------------------------");

      pciex8_m_awaddr <= gddr_ddr_nap_addr[20].addr;
      pciex8_m_awaddr[27:0] <= `REG_IRQ_MASTER_ADDR;
      pciex8_m_awid    <= $urandom;
      pciex8_m_arid    <= $urandom;
      ac7t1500.pcie1.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.
      for(j =0; j < num_bytes; j++)
        begin
           if(j == 0) // first byte
             one_byte_data_x8[0] = 8'h01;
           else
             one_byte_data_x8[j] = 8'h00;
        end

      ac7t1500.pcie1.master.read(pciex8_m_awaddr,num_bytes,one_byte_read_data_x8,pciex8_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[20].slave_info );
      $strobe("Pciex8 :: Read address %h and read  data %h", pciex8_m_awaddr, pciex8_m_rdata); 
      compare_dma_write_read_single(pciex8_m_awaddr,pciex8_m_awaddr,one_byte_data_x8,
                                    one_byte_read_data_x8,num_bytes, pciex8_m_awsize,
                                    pciex8_m_awburst,pciex8_m_bresp,num_bytes, 
                                    pciex8_m_arsize,pciex8_m_arburst,pciex8_m_rresp);


      // Now clear the IRQ register
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Clear the IRQ register");
      $display ("-------------------------------");

      pciex8_m_awaddr <= gddr_ddr_nap_addr[20].addr;
      pciex8_m_awaddr[27:0] <= `REG_IRQ_CFG_0_ADDR;
      pciex8_m_awid    <= $urandom;
      pciex8_m_arid    <= $urandom;

      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      one_byte_data_x8[0] = pciex8_m_wdata[7:0];
      one_byte_data_x8[1] = pciex8_m_wdata[15:8];
      one_byte_data_x8[2] = pciex8_m_wdata[23:16];
      one_byte_data_x8[3] = pciex8_m_wdata[31:24];

      ac7t1500.pcie1.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.
      // use same data as before to clear the same bits

      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      $strobe("PCIEX8 :: Write address %h ", pciex8_m_awaddr );
      $strobe("PCIEX8 :: Write  data %h ",  pciex8_m_wdata);
      $strobe("Pciex8 as master requesting to Write to %s",gddr_ddr_nap_addr[20].slave_info);
      
      $display("PCIEX8 ::reg_addr_count  %d ", reg_addr_count );
      
      ac7t1500.pcie1.master.write(pciex8_m_awaddr,one_byte_data_x8,num_bytes,pciex8_m_bresp);

      ac7t1500.pcie1.master.read(pciex8_m_awaddr,num_bytes,one_byte_read_data_x8,pciex8_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[20].slave_info );
      $strobe("Pciex8 :: Read address %h and read  data %h", pciex8_m_awaddr, pciex8_m_rdata); 
      compare_dma_write_read_single(pciex8_m_awaddr,pciex8_m_awaddr,one_byte_data_x8,
                                    one_byte_read_data_x8,num_bytes, pciex8_m_awsize,
                                    pciex8_m_awburst,pciex8_m_bresp,num_bytes, 
                                    pciex8_m_arsize,pciex8_m_arburst,pciex8_m_rresp);

      ac7t1500.pcie1.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.

      // read the IRQ register and make sure it's been cleared
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Check the IRQ register has cleared");
      $display ("-------------------------------");

      pciex8_m_awaddr <= gddr_ddr_nap_addr[20].addr;
      pciex8_m_awaddr[27:0] <= `REG_IRQ_0_ADDR;
      pciex8_m_awid    <= $urandom;
      pciex8_m_arid    <= $urandom;
      ac7t1500.pcie1.master.wait_cycles(1); // Wait 1 clock cycle
      for(j =0; j <num_bytes; j++)
        begin
           one_byte_data_x8[j] = 8'h00;
        end
      

      ac7t1500.pcie1.master.read(pciex8_m_awaddr,num_bytes,one_byte_read_data_x8,pciex8_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[20].slave_info );
      $strobe("Pciex8 :: Read address %h and read  data %h", pciex8_m_awaddr, pciex8_m_rdata); 
      compare_dma_write_read_single(pciex8_m_awaddr,pciex8_m_awaddr,one_byte_data_x8,
                                    one_byte_read_data_x8,num_bytes, pciex8_m_awsize,
                                    pciex8_m_awburst,pciex8_m_bresp,num_bytes, 
                                    pciex8_m_arsize,pciex8_m_arburst,pciex8_m_rresp);
      
      ac7t1500.pcie1.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.


      // check that the Master IRQ register is set back to 0
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Check the master IRQ register is cleared");
      $display ("-------------------------------");
      pciex8_m_awaddr <= gddr_ddr_nap_addr[20].addr;
      pciex8_m_awaddr[27:0] <= `REG_IRQ_MASTER_ADDR;
      pciex8_m_awid    <= $urandom;
      pciex8_m_arid    <= $urandom;

      ac7t1500.pcie1.master.read(pciex8_m_awaddr,num_bytes,one_byte_read_data_x8,pciex8_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[20].slave_info );
      $strobe("Pciex8 :: Read address %h and read  data %h", pciex8_m_awaddr, pciex8_m_rdata); 
      // make sure it's 0 on 2nd read
      compare_dma_write_read_single(pciex8_m_awaddr,pciex8_m_awaddr,one_byte_data_x8,
                                    one_byte_read_data_x8,num_bytes, pciex8_m_awsize,
                                    pciex8_m_awburst,pciex8_m_bresp,num_bytes, 
                                    pciex8_m_arsize,pciex8_m_arburst,pciex8_m_rresp);
      
      ac7t1500.pcie1.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.



      

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

      num_bytes <= 4;
      pciex8_m_awaddr <= gddr_ddr_nap_addr[20].addr;
      pciex8_m_awaddr[27:0] <= `REG_CNT_0_ADDR;
      pciex8_m_wdata[255:0] <= $random   ;// 32-bit random data
      pciex8_m_awid    <= $urandom;
      pciex8_m_arid    <= $urandom;

      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      one_byte_data_x8[0] = pciex8_m_wdata[7:0];
      one_byte_data_x8[1] = pciex8_m_wdata[15:8];
      one_byte_data_x8[2] = pciex8_m_wdata[23:16];
      one_byte_data_x8[3] = pciex8_m_wdata[31:24];
      counter_value     <= pciex8_m_wdata[31:0];
      
      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      $strobe("PCIEX8 :: Write address %h ", pciex8_m_awaddr );
      $strobe("PCIEX8 :: Write  data %h ",  pciex8_m_wdata);
      $strobe("PCIEx8 as master requesting to Write to %s",gddr_ddr_nap_addr[19].slave_info);
      
      $display("PCIEX8 ::reg_addr_count  %d ", reg_addr_count );
      
      ac7t1500.pcie1.master.write(pciex8_m_awaddr,one_byte_data_x8,num_bytes,pciex8_m_bresp);

      ac7t1500.pcie1.master.read(pciex8_m_awaddr,num_bytes,one_byte_read_data_x8,pciex8_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[19].slave_info );
      $strobe("PCIEx8 :: Read address %h", pciex8_m_awaddr); 
      compare_dma_write_read_single(pciex8_m_awaddr,pciex8_m_awaddr,one_byte_data_x8,
                                    one_byte_read_data_x8,num_bytes, pciex8_m_awsize,
                                    pciex8_m_awburst,pciex8_m_bresp,num_bytes, 
                                    pciex8_m_arsize,pciex8_m_arburst,pciex8_m_rresp);
      
      
      //-------------------------------------------
      // Set the config register to count down
      // and enable the counter
      //-------------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Writing to counter config register");
      $display ("-------------------------------");

      num_bytes <= 4;
      pciex8_m_awaddr <= gddr_ddr_nap_addr[20].addr;
      pciex8_m_awaddr[27:0] <= `REG_CNT_CFG_0_ADDR;
      pciex8_m_wdata[31:0] <= {29'h0, 1'b1, 1'b1, 1'b0};
      pciex8_m_awid    <= $urandom;
      pciex8_m_arid    <= $urandom;

      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      one_byte_data_x8[0] = pciex8_m_wdata[7:0];
      one_byte_data_x8[1] = pciex8_m_wdata[15:8];
      one_byte_data_x8[2] = pciex8_m_wdata[23:16];
      one_byte_data_x8[3] = pciex8_m_wdata[31:24];
      
      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      $strobe("PCIEX8 :: Write address %h ", pciex8_m_awaddr );
      $strobe("PCIEX8 :: Write  data %h ",  pciex8_m_wdata);
      $strobe("PCIEx8 as master requesting to Write to %s",gddr_ddr_nap_addr[19].slave_info);
      
      $display("PCIEX8 ::reg_addr_count  %d ", reg_addr_count );
      
      ac7t1500.pcie1.master.write(pciex8_m_awaddr,one_byte_data_x8,num_bytes,pciex8_m_bresp);

      ac7t1500.pcie1.master.read(pciex8_m_awaddr,num_bytes,one_byte_read_data_x8,pciex8_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[20].slave_info );
      $strobe("PCIEx8 :: Read address %h", pciex8_m_awaddr); 
      compare_dma_write_read_single(pciex8_m_awaddr,pciex8_m_awaddr,one_byte_data_x8,
                                    one_byte_read_data_x8,num_bytes, pciex8_m_awsize,
                                    pciex8_m_awburst,pciex8_m_bresp,num_bytes, 
                                    pciex8_m_arsize,pciex8_m_arburst,pciex8_m_rresp);
      

      // Now stop the down counter
      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      pciex8_m_wdata[31:0] <= {29'h0, 1'b1, 1'b0, 1'b0};
      pciex8_m_awid    <= $urandom;
      pciex8_m_arid    <= $urandom;

      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      one_byte_data_x8[0] = pciex8_m_wdata[7:0];
      one_byte_data_x8[1] = pciex8_m_wdata[15:8];
      one_byte_data_x8[2] = pciex8_m_wdata[23:16];
      one_byte_data_x8[3] = pciex8_m_wdata[31:24];
      
      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      $strobe("PCIEX8 :: Write address %h ", pciex8_m_awaddr );
      $strobe("PCIEX8 :: Write  data %h ",  pciex8_m_wdata);
      $strobe("PCIEx8 as master requesting to Write to %s",gddr_ddr_nap_addr[20].slave_info);
      
      $display("PCIEX8 ::reg_addr_count  %d ", reg_addr_count );
      
      ac7t1500.pcie1.master.write(pciex8_m_awaddr,one_byte_data_x8,num_bytes,pciex8_m_bresp);

      ac7t1500.pcie1.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.

      //-----------------------------
      // read counter and check it's
      // value is smaller
      //-----------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Reading counter register");
      $display ("-------------------------------");

      num_bytes <= 4;
      pciex8_m_awaddr <= gddr_ddr_nap_addr[20].addr;
      pciex8_m_awaddr[27:0] <= `REG_CNT_0_ADDR;
      pciex8_m_awid    <= $urandom;
      pciex8_m_arid    <= $urandom;
      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 

      
      ac7t1500.pcie1.master.read(pciex8_m_awaddr,num_bytes,one_byte_read_data_x8,pciex8_m_rresp);

      for (i =0; i<4 ; i++) begin
         case(i)
           0: read_count_value[7:0]   <= one_byte_read_data_x8[0];
           1: read_count_value[15:8]  <= one_byte_read_data_x8[1];
           2: read_count_value[23:16] <= one_byte_read_data_x8[2];
           3: read_count_value[31:24] <= one_byte_read_data_x8[3];
         endcase // case (i)
      end
      

      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 


      if(read_count_value < counter_value) // check number decreased
        $strobe("PCIEx8 :: Counter old value %h > counter new value %h", counter_value, read_count_value);
      else begin
         $display(" ERROR:: Old counter %h",counter_value);
         $display(" ERROR:: New counter %h",read_count_value);
         $error("ERROR :: Old counter NOT > new counter value"); 
         $fatal("ERROR :: Old counter NOT > new counter value"); 
      end
      

      ac7t1500.pcie1.master.wait_cycles(1);

      

      //-------------------------------------------
      // Counter registers
      // Read counter to make sure the value is 0
      // then write the config reg and set up counter
      // then read counter again and see that it's higher
      //-------------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Writing to counter register");
      $display ("-------------------------------");

      num_bytes <= 4;
      pciex8_m_awaddr <= gddr_ddr_nap_addr[20].addr;
      pciex8_m_awaddr[27:0] <= `REG_CNT_1_ADDR;
      pciex8_m_wdata[255:0] <= 256'h0   ;// 32-bit random data
      counter_value     <= 32'h0;
      pciex8_m_awid    <= $urandom;
      pciex8_m_arid    <= $urandom;

      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      one_byte_data_x8[0] = pciex8_m_wdata[7:0];
      one_byte_data_x8[1] = pciex8_m_wdata[15:8];
      one_byte_data_x8[2] = pciex8_m_wdata[23:16];
      one_byte_data_x8[3] = pciex8_m_wdata[31:24];
      
      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      $strobe("PCIEX8 :: Write address %h ", pciex8_m_awaddr );
      $strobe("PCIEX8 :: Write  data %h ",  pciex8_m_wdata);
      $strobe("PCIEx8 as master requesting to Write to %s",gddr_ddr_nap_addr[20].slave_info);
      
      $display("PCIEX8 ::reg_addr_count  %d ", reg_addr_count );
      
      ac7t1500.pcie1.master.write(pciex8_m_awaddr,one_byte_data_x8,num_bytes,pciex8_m_bresp);

      ac7t1500.pcie1.master.read(pciex8_m_awaddr,num_bytes,one_byte_read_data_x8,pciex8_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[19].slave_info );
      $strobe("PCIEx8 :: Read address %h", pciex8_m_awaddr); 
      compare_dma_write_read_single(pciex8_m_awaddr,pciex8_m_awaddr,one_byte_data_x8,
                                    one_byte_read_data_x8,num_bytes, pciex8_m_awsize,
                                    pciex8_m_awburst,pciex8_m_bresp,num_bytes, 
                                    pciex8_m_arsize,pciex8_m_arburst,pciex8_m_rresp);
      
      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      
      //-------------------------------------------
      // Set the config register to count up
      // and enable the counter
      //-------------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Writing to counter config register");
      $display ("-------------------------------");

      num_bytes <= 4;
      pciex8_m_awaddr <= gddr_ddr_nap_addr[20].addr;
      pciex8_m_awaddr[27:0] <= `REG_CNT_CFG_1_ADDR;
      pciex8_m_wdata[31:0] <= {29'h0, 1'b0, 1'b1, 1'b0};
      pciex8_m_awid    <= $urandom;
      pciex8_m_arid    <= $urandom;

      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      one_byte_data_x8[0] = pciex8_m_wdata[7:0];
      one_byte_data_x8[1] = pciex8_m_wdata[15:8];
      one_byte_data_x8[2] = pciex8_m_wdata[23:16];
      one_byte_data_x8[3] = pciex8_m_wdata[31:24];
      
      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      $strobe("PCIEX8 :: Write address %h ", pciex8_m_awaddr );
      $strobe("PCIEX8 :: Write  data %h ",  pciex8_m_wdata);
      $strobe("PCIEx8 as master requesting to Write to %s",gddr_ddr_nap_addr[20].slave_info);
      
      $display("PCIEX8 ::reg_addr_count  %d ", reg_addr_count );
      
      ac7t1500.pcie1.master.write(pciex8_m_awaddr,one_byte_data_x8,num_bytes,pciex8_m_bresp);

      ac7t1500.pcie1.master.read(pciex8_m_awaddr,num_bytes,one_byte_read_data_x8,pciex8_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[19].slave_info );
      $strobe("PCIEx8 :: Read address %h and read", pciex8_m_awaddr); 
      compare_dma_write_read_single(pciex8_m_awaddr,pciex8_m_awaddr,one_byte_data_x8,
                                    one_byte_read_data_x8,num_bytes, pciex8_m_awsize,
                                    pciex8_m_awburst,pciex8_m_bresp,num_bytes, 
                                    pciex8_m_arsize,pciex8_m_arburst,pciex8_m_rresp);
      

      // Now stop the up counter
      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      pciex8_m_wdata[31:0] <= {29'h0, 1'b0, 1'b0, 1'b0};
      pciex8_m_awid    <= $urandom;
      pciex8_m_arid    <= $urandom;

      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      one_byte_data_x8[0] = pciex8_m_wdata[7:0];
      one_byte_data_x8[1] = pciex8_m_wdata[15:8];
      one_byte_data_x8[2] = pciex8_m_wdata[23:16];
      one_byte_data_x8[3] = pciex8_m_wdata[31:24];
      
      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 
      $strobe("PCIEX8 :: Write address %h ", pciex8_m_awaddr );
      $strobe("PCIEX8 :: Write  data %h ",  pciex8_m_wdata);
      $strobe("PCIEx8 as master requesting to Write to %s",gddr_ddr_nap_addr[19].slave_info);
      
      $display("PCIEX8 ::reg_addr_count  %d ", reg_addr_count );
      
      ac7t1500.pcie1.master.write(pciex8_m_awaddr,one_byte_data_x8,num_bytes,pciex8_m_bresp);

      ac7t1500.pcie1.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.

      

      //-----------------------------
      // read counter and check it's
      // value is smaller
      //-----------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex8 Reading counter register");
      $display ("-------------------------------");
      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 

      num_bytes <= 4;
      pciex8_m_awaddr <= gddr_ddr_nap_addr[20].addr;
      pciex8_m_awaddr[27:0] <= `REG_CNT_1_ADDR;
      pciex8_m_awid    <= $urandom;
      pciex8_m_arid    <= $urandom;
      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 


      ac7t1500.pcie1.master.read(pciex8_m_awaddr,num_bytes,one_byte_read_data_x8,pciex8_m_rresp);


      for (i =0; i<4 ; i++) begin
         case(i)
           0: read_count_value[7:0]   <= one_byte_read_data_x8[0];
           1: read_count_value[15:8]  <= one_byte_read_data_x8[1];
           2: read_count_value[23:16] <= one_byte_read_data_x8[2];
           3: read_count_value[31:24] <= one_byte_read_data_x8[3];
         endcase // case (i)
      end
      
      ac7t1500.pcie1.master.wait_cycles(1); // advance the clock 

      if(read_count_value > counter_value) // check number decreased
        $strobe("PCIEx8 :: Counter old value %h < counter new value %h", counter_value, read_count_value);
      else begin
         $display(" ERROR:: Old counter %h",counter_value);
         $display(" ERROR:: New counter %h",read_count_value);
         $error("ERROR :: Old counter NOT < new counter value"); 
         $fatal("ERROR :: Old counter NOT < new counter value"); 
      end
      

      $display ($time, ": ========================PCIex8 BFM Mode Test Completed =============================");

      pciex8_bfm_test_done = 1;
      
      
   end // initial begin


   //-----------------------------------
   // PCIe Slave tasks
   //-----------------------------------

   initial begin
      wait(test_start == 1)
        forever begin
           ac7t1500.pcie1.slave.get_write_request(pciex8_s_awaddr, slvx8_wr_num_bytes,slavex8_data_bytes, pciex8_s_awid);
           slavex8_write_id_queue.push_front(pciex8_s_awid);
        end
   end 

   initial  begin 
      wait(test_start == 1)
        forever 
          begin
             if (slavex8_write_id_queue.size() > 0) begin
                bidx8 = slavex8_write_id_queue.pop_back();
                ac7t1500.pcie1.slave.issue_write_response(pciex8_s_bresp,bidx8);
             end
             else
               ac7t1500.pcie1.slave.wait_cycles(1);
          end
   end
   
   //---------------------------
   // Wait for a read request
   //---------------------------

   initial begin
      wait(test_start == 1)
        forever begin
           ac7t1500.pcie1.slave.get_read_request(pciex8_s_araddr, read_slvx8_num_bytes, read_id_x8);
           slavex8_read_id_queue.push_front(read_id_x8);
        end
   end

   
   initial begin
      wait(test_start == 1)
        forever 
          begin
             if (slavex8_read_id_queue.size() > 0) begin
                {slavex8_rid} = slavex8_read_id_queue.pop_back();
                ac7t1500.pcie1.slave.issue_read_response(read_slvx8_num_bytes,slavex8_data_bytes,2'b00,slavex8_rid  );
             end
             else  
               ac7t1500.pcie1.slave.wait_cycles(1);
          end
   end
`else
      assign pciex8_bfm_test_done = 1;
`endif

`ifndef ACX_PCIE_1_FULL

   //----------------------------------------------------------------------------------------------------------
   // Kick off transactions from PCIe x16
   //----------------------------------------------------------------------------------------------------------
   
   initial begin

      pciex16_bfm_test_done    <= 0;

      @(posedge reset_n);  // Wait for reset deassertion.
      
      initialize_pciex16();
      pciex16_m_awid    <= $urandom;
      pciex16_m_arid    <= $urandom;
      pciex16_m_awlen   <= 3'b000 ;
      pciex16_m_arlen   <= 3'b000 ;
      pciex16_m_awsize  <= 3'h5;
      pciex16_m_awburst <= 2'b01;
      pciex16_m_awlock  <= 1'b0;
      pciex16_m_awqos   <= 4'h0;
      pciex16_m_arsize  <= 3'h5; //32 byte address
      pciex16_m_arburst <= 2'b01;
      pciex16_m_arlock  <= 1'b0;
      pciex16_m_arqos   <= 4'h0;
      pciex16_m_wstrb   <= 64'h00000000ffffffff;  //32 byte lane 


      //----------------------------------------
      // Run through the DMA writes and reads
      // using PCIex16 master
      //----------------------------------------

      
      for (addr_count_pcie_x16= 0;  addr_count_pcie_x16<19; addr_count_pcie_x16++) begin 
         pciex16_m_awaddr <= gddr_ddr_nap_addr[addr_count_pcie_x16].addr;
         if(addr_count_pcie_x16 < 17) // going to a NAP
           begin
              pciex16_m_awaddr[27:6] <=  22'h200000; //PCIe Narrow transfer : axi addr[5] = 0
              for (num_bytes_x16=64; num_bytes_x16 <= (64*17); num_bytes_x16=num_bytes_x16+256)
                begin
                   pciex16_m_wdata[511:0] <= {16{$random}};
                   pciex16_m_awid    <= $urandom;
                   pciex16_m_arid    <= $urandom;

                   for(j =0; j <=num_bytes_x16; j++)
                     begin 
                        one_byte_data_x16[j] = $random;
                     end

                   
                   ac7t1500.pcie0.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.
                   $strobe("PCIEX16 :: Write address %h ", pciex16_m_awaddr );
                   $strobe("PCIEx16 as master requesting to Write to %s",gddr_ddr_nap_addr[addr_count_pcie_x16].slave_info);
                   
                   $display("PCIEX16 ::addr_count_pcie_x16  %d ", addr_count_pcie_x16 );
                   $display("PCIEX16 ::Length  %d ", num_bytes_x16 );
                   
                   ac7t1500.pcie0.master.write_dma(pciex16_m_awaddr,one_byte_data_x16,num_bytes_x16, pciex16_m_bresp);
                   
                   ac7t1500.pcie0.master.read_dma(pciex16_m_awaddr,num_bytes_x16,one_byte_read_data_x16, pciex16_m_rresp);
                   
                   compare_dma_write_read_single(pciex16_m_awaddr,pciex16_m_awaddr,one_byte_data_x16,
                                                 one_byte_read_data_x16,num_bytes_x16, pciex16_m_awsize,
                                                 pciex16_m_awburst,pciex16_m_bresp,num_bytes_x16, 
                                                 pciex16_m_arsize,pciex16_m_arburst,pciex16_m_rresp);

                   pciex16_m_awaddr[27:6] <= pciex16_m_awaddr[27:6] + 8'h20; // increment
                   

                end // for (len=0; len < 16; len=len+1)
           end // if (addr_count_pcie_x16 <= 16)
         else // BRAM responder NAPs
           begin
              pciex16_m_awaddr[27:6] <=  22'h000000; //PCIe Narrow transfer : axi addr[5] = 0
              pciex16_m_awid    <= $urandom;
              pciex16_m_arid    <= $urandom;
              
              for (num_bytes_x16=64; num_bytes_x16 < (64*4); num_bytes_x16=num_bytes_x16+64)
                begin
                   ac7t1500.pcie0.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock
                   $strobe("PCIEX16 :: Write address %h ", pciex16_m_awaddr );
                   $strobe("PCIEx16 as master requesting to Write to %s",gddr_ddr_nap_addr[addr_count_pcie_x16].slave_info);
                   
                   $display("PCIEX16 ::addr_count_pcie_x16  %d ", addr_count_pcie_x16 );
                   $display("PCIEX16 ::Length  %d ", num_bytes_x16 );
                   
                   ac7t1500.pcie0.master.write_dma(pciex16_m_awaddr,one_byte_data_x16,num_bytes_x16, pciex16_m_bresp);
                   
                   ac7t1500.pcie0.master.read_dma(pciex16_m_awaddr,num_bytes_x16,one_byte_read_data_x16, pciex16_m_rresp);
                   compare_dma_write_read_single(pciex16_m_awaddr,pciex16_m_awaddr,one_byte_data_x16,
                                                 one_byte_read_data_x16,num_bytes_x16, pciex16_m_awsize,
                                                 pciex16_m_awburst,pciex16_m_bresp,num_bytes_x16, 
                                                 pciex16_m_arsize,pciex16_m_arburst,pciex16_m_rresp);

                   pciex16_m_awaddr[27:6] <= pciex16_m_awaddr[27:6] + 8'h20; // increment
                   

                end // for (num_bytes_x16=31; num_bytes_x16 < (16*4); num_bytes_x16=num_bytes_x16+32)
           end // else: !if(addr_count_pcie_x16 <= 16)
         
         
      end // for (addr_count_pcie_x16= 0;  addr_count_pcie_x16<19; addr_count_pcie_x16++)


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
         num_bytes_x16 <= 4;
         pciex16_m_awaddr <= gddr_ddr_nap_addr[19].addr;
         pciex16_m_awaddr[27:0] <= `REG_CFG_0_ADDR + {reg_addr_count_pcie_x16 << 6};
         pciex16_m_wdata[255:0] <= {$random}   ;//GDDR, DDR and NAP supports 256 bits of data.
         pciex16_m_awid    <= $urandom;
         pciex16_m_arid    <= $urandom;
         for(j =0; j <num_bytes_x16; j++)
           begin 
              one_byte_data_x16[j] = $random;
           end
         ac7t1500.pcie0.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock
         $strobe("PCIEX16 :: Write address %h ", pciex16_m_awaddr );
         $strobe("PCIEx16 as master requesting to Write to %s",gddr_ddr_nap_addr[19].slave_info);
         
         $display("PCIEX16 ::reg_addr_count_pcie_x16  %d ", reg_addr_count_pcie_x16 );
         
         ac7t1500.pcie0.master.write(pciex16_m_awaddr,one_byte_data_x16,num_bytes_x16,pciex16_m_bresp);

         ac7t1500.pcie0.master.read(pciex16_m_awaddr,num_bytes_x16,one_byte_read_data_x16,pciex16_m_rresp);

         $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[19].slave_info );
         $strobe("PCIEx16 :: Read address %h", pciex16_m_awaddr); 

         compare_dma_write_read_single(pciex16_m_awaddr,pciex16_m_awaddr,one_byte_data_x16,
                                       one_byte_read_data_x16,num_bytes_x16, pciex16_m_awsize,
                                       pciex16_m_awburst,pciex16_m_bresp,num_bytes_x16, 
                                       pciex16_m_arsize,pciex16_m_arburst,pciex16_m_rresp);

      end // for (addr_count_pcie_x16= 0;  addr_count_pcie_x16<8; addr_count_pcie_x16++)
      
      // -----------------------------------
      // loop through read/write registers
      // These are 4 64-bit registers
      // -----------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Writing and Reading the four 64-bit Registers");
      $display ("-------------------------------");
      
      for(reg_addr_count_pcie_x16= 24; reg_addr_count_pcie_x16<28; reg_addr_count_pcie_x16++) begin
         num_bytes_x16 <= 8;
         pciex16_m_awaddr <= gddr_ddr_nap_addr[19].addr;
         pciex16_m_awaddr[27:0] <= `REG_CFG_0_ADDR + {reg_addr_count_pcie_x16 << 6};
         pciex16_m_awid    <= $urandom;
         pciex16_m_arid    <= $urandom;
         for(j =0; j <num_bytes_x16; j++)
           begin 
              one_byte_data_x16[j] = $random;
           end
         ac7t1500.pcie0.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.
         $strobe("PCIEX16 :: Write address %h ", pciex16_m_awaddr );
         $strobe("PCIEx16 as master requesting to Write to %s",gddr_ddr_nap_addr[19].slave_info);
         
         $display("PCIEX16 ::reg_addr_count_pcie_x16  %d ", reg_addr_count_pcie_x16 );
         
         ac7t1500.pcie0.master.write(pciex16_m_awaddr,one_byte_data_x16,num_bytes_x16,pciex16_m_bresp);

         ac7t1500.pcie0.master.read(pciex16_m_awaddr,num_bytes_x16,one_byte_read_data_x16,pciex16_m_rresp);

         $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[19].slave_info );
         $strobe("PCIEx16 :: Read address %h", pciex16_m_awaddr); 
         compare_dma_write_read_single(pciex16_m_awaddr,pciex16_m_awaddr,one_byte_data_x16,
                                       one_byte_read_data_x16,num_bytes_x16, pciex16_m_awsize,
                                       pciex16_m_awburst,pciex16_m_bresp,num_bytes_x16, 
                                       pciex16_m_arsize,pciex16_m_arburst,pciex16_m_rresp);
      end
      
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
         num_bytes_x16 <= 4;
         pciex16_m_awaddr <= gddr_ddr_nap_addr[19].addr;
         pciex16_m_awaddr[27:0] <= `REG_CFG_0_ADDR + {reg_addr_count_pcie_x16 << 6};
         pciex16_m_wdata[255:0] <= `REG_CFG_0_ADDR + {reg_addr_count_pcie_x16 << 6};// data is same as addr            
         pciex16_m_awid    <= $urandom;
         pciex16_m_arid    <= $urandom;
         ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 

         one_byte_data_x16[0] = pciex16_m_wdata[7:0];
         one_byte_data_x16[1] = pciex16_m_wdata[15:8];
         one_byte_data_x16[2] = pciex16_m_wdata[23:16];
         one_byte_data_x16[3] = pciex16_m_wdata[31:24];
         
         ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
         $strobe("PCIEX16 :: Read address %h ", pciex16_m_awaddr );
         $display("PCIEX16 ::reg_addr_count_pcie_x16  %d ", reg_addr_count_pcie_x16 );
         
         ac7t1500.pcie0.master.read(pciex16_m_awaddr,num_bytes_x16,one_byte_read_data_x16,pciex16_m_rresp);

         $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[19].slave_info );
         $strobe("PCIEx16 :: Read address %h", pciex16_m_awaddr); 
         compare_dma_write_read_single(pciex16_m_awaddr,pciex16_m_awaddr,one_byte_data_x16,
                                       one_byte_read_data_x16,num_bytes_x16, pciex16_m_awsize,
                                       pciex16_m_awburst,pciex16_m_bresp,num_bytes_x16, 
                                       pciex16_m_arsize,pciex16_m_arburst,pciex16_m_rresp);
      end
      

      //-------------------------------------
      // read on clear register
      // first write to set the value
      // then read it back
      // on second read it should be all 0s
      //-------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Writing and Reading the clear-on-read register");
      $display ("-------------------------------");

      num_bytes_x16 <= 4;
      pciex16_m_awaddr <= gddr_ddr_nap_addr[19].addr;
      pciex16_m_awaddr[27:0] <= `REG_CLEAR_ON_RD_ADDR;
      pciex16_m_awid    <= $urandom;
      pciex16_m_arid    <= $urandom;
      for(j =0; j <num_bytes_x16; j++)
        begin 
           one_byte_data_x16[j] = $random;
        end

      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 

      $strobe("PCIEX16 :: Write address %h ", pciex16_m_awaddr );
      $strobe("PCIEx16 as master requesting to Write to %s",gddr_ddr_nap_addr[19].slave_info);
      
      $display("PCIEX16 ::reg_addr_count_pcie_x16  %d ", reg_addr_count_pcie_x16 );
      
      ac7t1500.pcie0.master.write(pciex16_m_awaddr,one_byte_data_x16,num_bytes_x16,pciex16_m_bresp);

      ac7t1500.pcie0.master.read(pciex16_m_awaddr,num_bytes_x16,one_byte_read_data_x16,pciex16_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[19].slave_info );
      $strobe("PCIEx16 :: Read address %h", pciex16_m_awaddr); 
      compare_dma_write_read_single(pciex16_m_awaddr,pciex16_m_awaddr,one_byte_data_x16,
                                    one_byte_read_data_x16,num_bytes_x16, pciex16_m_awsize,
                                    pciex16_m_awburst,pciex16_m_bresp,num_bytes_x16, 
                                    pciex16_m_arsize,pciex16_m_arburst,pciex16_m_rresp);

      pciex16_m_arid    <= $urandom;
      // Read a second time to clear the register, make sure the read result is 0
      ac7t1500.pcie0.master.read(pciex16_m_awaddr,num_bytes_x16,one_byte_read_data_x16,pciex16_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[19].slave_info );
      $strobe("PCIEx16 :: Read address %h", pciex16_m_awaddr); 
      // make sure it's 0 on 2nd read
      for(j =0; j <num_bytes_x16; j++)
        begin 
           one_byte_data_x16[j] = 8'h00;
        end
      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      compare_dma_write_read_single(pciex16_m_awaddr,pciex16_m_awaddr,one_byte_data_x16,
                                    one_byte_read_data_x16,num_bytes_x16, pciex16_m_awsize,
                                    pciex16_m_awburst,pciex16_m_bresp,num_bytes_x16, 
                                    pciex16_m_arsize,pciex16_m_arburst,pciex16_m_rresp);
      

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

      num_bytes_x16 <= 4;
      pciex16_m_awaddr <= gddr_ddr_nap_addr[19].addr;
      pciex16_m_awaddr[27:0] <= `REG_IRQ_0_ADDR;
      pciex16_m_wdata[255:0] <= $random   ;// 32-bit random data
      pciex16_m_awid    <= $urandom;
      pciex16_m_arid    <= $urandom;

      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      one_byte_data_x16[0] = pciex16_m_wdata[7:0];
      one_byte_data_x16[1] = pciex16_m_wdata[15:8];
      one_byte_data_x16[2] = pciex16_m_wdata[23:16];
      one_byte_data_x16[3] = pciex16_m_wdata[31:24];
      
      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      $strobe("PCIEX16 :: Write address %h ", pciex16_m_awaddr );
      $strobe("PCIEX16 :: Write  data %h ",  pciex16_m_wdata);
      $strobe("PCIEx16 as master requesting to Write to %s",gddr_ddr_nap_addr[19].slave_info);
      
      $display("PCIEX16 ::reg_addr_count_pcie_x16  %d ", reg_addr_count_pcie_x16 );
      
      ac7t1500.pcie0.master.write(pciex16_m_awaddr,one_byte_data_x16,num_bytes_x16,pciex16_m_bresp);

      ac7t1500.pcie0.master.read(pciex16_m_awaddr,num_bytes_x16,one_byte_read_data_x16,pciex16_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[19].slave_info );
      $strobe("PCIEx16 :: Read address %h", pciex16_m_awaddr); 
      compare_dma_write_read_single(pciex16_m_awaddr,pciex16_m_awaddr,one_byte_data_x16,
                                    one_byte_read_data_x16,num_bytes_x16, pciex16_m_awsize,
                                    pciex16_m_awburst,pciex16_m_bresp,num_bytes_x16, 
                                    pciex16_m_arsize,pciex16_m_arburst,pciex16_m_rresp);

      // check that the Master IRQ register is set to 1
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Check the master IRQ register is set to 1");
      $display ("-------------------------------");

      pciex16_m_awaddr <= gddr_ddr_nap_addr[19].addr;
      pciex16_m_awaddr[27:0] <= `REG_IRQ_MASTER_ADDR;
      pciex16_m_awid    <= $urandom;
      pciex16_m_arid    <= $urandom;
      ac7t1500.pcie0.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.
      for(j =0; j < num_bytes_x16; j++)
        begin
           if(j == 0) // first byte
             one_byte_data_x16[0] = 8'h01;
           else
             one_byte_data_x16[j] = 8'h00;
        end

      ac7t1500.pcie0.master.read(pciex16_m_awaddr,num_bytes_x16,one_byte_read_data_x16,pciex16_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[19].slave_info );
      $strobe("PCIEx16 :: Read address %h", pciex16_m_awaddr); 
      compare_dma_write_read_single(pciex16_m_awaddr,pciex16_m_awaddr,one_byte_data_x16,
                                    one_byte_read_data_x16,num_bytes_x16, pciex16_m_awsize,
                                    pciex16_m_awburst,pciex16_m_bresp,num_bytes_x16, 
                                    pciex16_m_arsize,pciex16_m_arburst,pciex16_m_rresp);

      // Now clear the IRQ register
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Clear the IRQ register");
      $display ("-------------------------------");

      pciex16_m_awaddr <= gddr_ddr_nap_addr[19].addr;
      pciex16_m_awaddr[27:0] <= `REG_IRQ_CFG_0_ADDR;
      pciex16_m_awid    <= $urandom;
      pciex16_m_arid    <= $urandom;

      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      one_byte_data_x16[0] = pciex16_m_wdata[7:0];
      one_byte_data_x16[1] = pciex16_m_wdata[15:8];
      one_byte_data_x16[2] = pciex16_m_wdata[23:16];
      one_byte_data_x16[3] = pciex16_m_wdata[31:24];

      ac7t1500.pcie0.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.
      // use same data as before to clear the same bits

      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      $strobe("PCIEX16 :: Write address %h ", pciex16_m_awaddr );
      $strobe("PCIEX16 :: Write  data %h ",  pciex16_m_wdata);
      $strobe("PCIEx16 as master requesting to Write to %s",gddr_ddr_nap_addr[19].slave_info);
      
      $display("PCIEX16 ::reg_addr_count_pcie_x16  %d ", reg_addr_count_pcie_x16 );
      
      ac7t1500.pcie0.master.write(pciex16_m_awaddr,one_byte_data_x16,num_bytes_x16,pciex16_m_bresp);

      ac7t1500.pcie0.master.read(pciex16_m_awaddr,num_bytes_x16,one_byte_read_data_x16,pciex16_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[19].slave_info );
      $strobe("PCIEx16 :: Read address %h", pciex16_m_awaddr); 
      compare_dma_write_read_single(pciex16_m_awaddr,pciex16_m_awaddr,one_byte_data_x16,
                                    one_byte_read_data_x16,num_bytes_x16, pciex16_m_awsize,
                                    pciex16_m_awburst,pciex16_m_bresp,num_bytes_x16, 
                                    pciex16_m_arsize,pciex16_m_arburst,pciex16_m_rresp);

      ac7t1500.pcie0.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.

      // read the IRQ register and make sure it's been cleared
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Check the IRQ register has cleared");
      $display ("-------------------------------");

      pciex16_m_awaddr <= gddr_ddr_nap_addr[19].addr;
      pciex16_m_awaddr[27:0] <= `REG_IRQ_0_ADDR;
      pciex16_m_awid    <= $urandom;
      pciex16_m_arid    <= $urandom;
      ac7t1500.pcie0.master.wait_cycles(1); // Wait ten clock cycle on the PCIe master's clock, to get aligned.
      for(j =0; j <num_bytes_x16; j++)
        begin
           one_byte_data_x16[j] = 8'h00;
        end
      

      ac7t1500.pcie0.master.read(pciex16_m_awaddr,num_bytes_x16,one_byte_read_data_x16,pciex16_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[19].slave_info );
      $strobe("PCIEx16 :: Read address %h", pciex16_m_awaddr); 
      compare_dma_write_read_single(pciex16_m_awaddr,pciex16_m_awaddr,one_byte_data_x16,
                                    one_byte_read_data_x16,num_bytes_x16, pciex16_m_awsize,
                                    pciex16_m_awburst,pciex16_m_bresp,num_bytes_x16, 
                                    pciex16_m_arsize,pciex16_m_arburst,pciex16_m_rresp);
      
      ac7t1500.pcie0.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.


      // check that the Master IRQ register is set back to 0
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Check the master IRQ register is cleared");
      $display ("-------------------------------");
      pciex16_m_awaddr <= gddr_ddr_nap_addr[19].addr;
      pciex16_m_awaddr[27:0] <= `REG_IRQ_MASTER_ADDR;
      pciex16_m_awid    <= $urandom;
      pciex16_m_arid    <= $urandom;
      ac7t1500.pcie0.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.

      ac7t1500.pcie0.master.read(pciex16_m_awaddr,num_bytes_x16,one_byte_read_data_x16,pciex16_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[19].slave_info );
      $strobe("PCIEx16 :: Read address %h", pciex16_m_awaddr); 
      // make sure it's 0 on 2nd read
      compare_dma_write_read_single(pciex16_m_awaddr,pciex16_m_awaddr,one_byte_data_x16,
                                    one_byte_read_data_x16,num_bytes_x16, pciex16_m_awsize,
                                    pciex16_m_awburst,pciex16_m_bresp,num_bytes_x16, 
                                    pciex16_m_arsize,pciex16_m_arburst,pciex16_m_rresp);
      
      ac7t1500.pcie0.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.

      

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

      num_bytes_x16 <= 4;
      pciex16_m_awaddr <= gddr_ddr_nap_addr[19].addr;
      pciex16_m_awaddr[27:0] <= `REG_CNT_0_ADDR;
      pciex16_m_wdata[255:0] <= $random   ;// 32-bit random data
      pciex16_m_awid    <= $urandom;
      pciex16_m_arid    <= $urandom;

      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      one_byte_data_x16[0] = pciex16_m_wdata[7:0];
      one_byte_data_x16[1] = pciex16_m_wdata[15:8];
      one_byte_data_x16[2] = pciex16_m_wdata[23:16];
      one_byte_data_x16[3] = pciex16_m_wdata[31:24];
      counter_value_x16     <= pciex16_m_wdata[31:0];
      
      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      $strobe("PCIEX16 :: Write address %h ", pciex16_m_awaddr );
      $strobe("PCIEX16 :: Write  data %h ",  pciex16_m_wdata);
      $strobe("PCIEx16 as master requesting to Write to %s",gddr_ddr_nap_addr[19].slave_info);
      
      $display("PCIEX16 ::reg_addr_count_pcie_x16  %d ", reg_addr_count_pcie_x16 );
      
      ac7t1500.pcie0.master.write(pciex16_m_awaddr,one_byte_data_x16,num_bytes_x16,pciex16_m_bresp);

      ac7t1500.pcie0.master.read(pciex16_m_awaddr,num_bytes_x16,one_byte_read_data_x16,pciex16_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[19].slave_info );
      $strobe("PCIEx16 :: Read address %h", pciex16_m_awaddr); 
      compare_dma_write_read_single(pciex16_m_awaddr,pciex16_m_awaddr,one_byte_data_x16,
                                    one_byte_read_data_x16,num_bytes_x16, pciex16_m_awsize,
                                    pciex16_m_awburst,pciex16_m_bresp,num_bytes_x16, 
                                    pciex16_m_arsize,pciex16_m_arburst,pciex16_m_rresp);
      
      
      //-------------------------------------------
      // Set the config register to count down
      // and enable the counter
      //-------------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Writing to counter config register");
      $display ("-------------------------------");

      num_bytes_x16 <= 4;
      pciex16_m_awaddr <= gddr_ddr_nap_addr[19].addr;
      pciex16_m_awaddr[27:0] <= `REG_CNT_CFG_0_ADDR;
      pciex16_m_wdata[31:0] <= {29'h0, 1'b1, 1'b1, 1'b0};
      pciex16_m_awid    <= $urandom;
      pciex16_m_arid    <= $urandom;

      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      one_byte_data_x16[0] = pciex16_m_wdata[7:0];
      one_byte_data_x16[1] = pciex16_m_wdata[15:8];
      one_byte_data_x16[2] = pciex16_m_wdata[23:16];
      one_byte_data_x16[3] = pciex16_m_wdata[31:24];
      
      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      $strobe("PCIEX16 :: Write address %h ", pciex16_m_awaddr );
      $strobe("PCIEX16 :: Write  data %h ",  pciex16_m_wdata);
      $strobe("PCIEx16 as master requesting to Write to %s",gddr_ddr_nap_addr[19].slave_info);
      
      $display("PCIEX16 ::reg_addr_count_pcie_x16  %d ", reg_addr_count_pcie_x16 );
      
      ac7t1500.pcie0.master.write(pciex16_m_awaddr,one_byte_data_x16,num_bytes_x16,pciex16_m_bresp);

      ac7t1500.pcie0.master.read(pciex16_m_awaddr,num_bytes_x16,one_byte_read_data_x16,pciex16_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[19].slave_info );
      $strobe("PCIEx16 :: Read address %h", pciex16_m_awaddr); 
      compare_dma_write_read_single(pciex16_m_awaddr,pciex16_m_awaddr,one_byte_data_x16,
                                    one_byte_read_data_x16,num_bytes_x16, pciex16_m_awsize,
                                    pciex16_m_awburst,pciex16_m_bresp,num_bytes_x16, 
                                    pciex16_m_arsize,pciex16_m_arburst,pciex16_m_rresp);
      


      // Now stop the down counter
      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      pciex16_m_wdata[31:0] <= {29'h0, 1'b1, 1'b0, 1'b0};
      pciex16_m_awid    <= $urandom;
      pciex16_m_arid    <= $urandom;
      num_bytes_x16 <= 4;
      
      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      one_byte_data_x16[0] = pciex16_m_wdata[7:0];
      one_byte_data_x16[1] = pciex16_m_wdata[15:8];
      one_byte_data_x16[2] = pciex16_m_wdata[23:16];
      one_byte_data_x16[3] = pciex16_m_wdata[31:24];
      
      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      $strobe("PCIEX16 :: Write address %h ", pciex16_m_awaddr );
      $strobe("PCIEX16 :: Write  data %h ",  pciex16_m_wdata);
      $strobe("PCIEx16 as master requesting to Write to %s",gddr_ddr_nap_addr[19].slave_info);
      
      ac7t1500.pcie0.master.write(pciex16_m_awaddr,one_byte_data_x16,num_bytes_x16,pciex16_m_bresp);

      ac7t1500.pcie0.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.

      
      //-----------------------------
      // read counter and check it's
      // value is smaller
      //-----------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Reading counter register");
      $display ("-------------------------------");
      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 

      num_bytes_x16 <= 4;
      pciex16_m_awaddr <= gddr_ddr_nap_addr[19].addr;
      pciex16_m_awaddr[27:0] <= `REG_CNT_0_ADDR;
      pciex16_m_awid    <= $urandom;
      pciex16_m_arid    <= $urandom;
      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 

      ac7t1500.pcie0.master.read(pciex16_m_awaddr,num_bytes_x16,one_byte_read_data_x16,pciex16_m_rresp);


      for (i =0; i<4 ; i++) begin
         case(i)
           0: read_count_value_x16[7:0]   <= one_byte_read_data_x16[0];
           1: read_count_value_x16[15:8]  <= one_byte_read_data_x16[1];
           2: read_count_value_x16[23:16] <= one_byte_read_data_x16[2];
           3: read_count_value_x16[31:24] <= one_byte_read_data_x16[3];
         endcase // case (i)
      end
      
      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 

      if(read_count_value_x16 < counter_value_x16) // check number decreased
        $strobe("PCIEx16 :: Counter old value %h > counter new value %h", counter_value_x16, read_count_value_x16);
      else begin
         $display(" ERROR:: Old counter %h",counter_value_x16);
         $display(" ERROR:: New counter %h",read_count_value_x16);
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

      num_bytes_x16 <= 4;
      pciex16_m_awaddr <= gddr_ddr_nap_addr[19].addr;
      pciex16_m_awaddr[27:0] <= `REG_CNT_1_ADDR;
      pciex16_m_wdata[255:0] <= 256'h0   ;// 32-bit random data
      counter_value_x16     <= 32'h0;
      pciex16_m_awid    <= $urandom;
      pciex16_m_arid    <= $urandom;

      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      one_byte_data_x16[0] = pciex16_m_wdata[7:0];
      one_byte_data_x16[1] = pciex16_m_wdata[15:8];
      one_byte_data_x16[2] = pciex16_m_wdata[23:16];
      one_byte_data_x16[3] = pciex16_m_wdata[31:24];
      
      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      $strobe("PCIEX16 :: Write address %h ", pciex16_m_awaddr );
      $strobe("PCIEX16 :: Write  data %h ",  pciex16_m_wdata);
      $strobe("PCIEx16 as master requesting to Write to %s",gddr_ddr_nap_addr[19].slave_info);
      
      $display("PCIEX16 ::reg_addr_count_pcie_x16  %d ", reg_addr_count_pcie_x16 );
      
      ac7t1500.pcie0.master.write(pciex16_m_awaddr,one_byte_data_x16,num_bytes_x16,pciex16_m_bresp);

      ac7t1500.pcie0.master.read(pciex16_m_awaddr,num_bytes_x16,one_byte_read_data_x16,pciex16_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[19].slave_info );
      $strobe("PCIEx16 :: Read address %h", pciex16_m_awaddr); 
      compare_dma_write_read_single(pciex16_m_awaddr,pciex16_m_awaddr,one_byte_data_x16,
                                    one_byte_read_data_x16,num_bytes_x16, pciex16_m_awsize,
                                    pciex16_m_awburst,pciex16_m_bresp,num_bytes_x16, 
                                    pciex16_m_arsize,pciex16_m_arburst,pciex16_m_rresp);
      
      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      
      //-------------------------------------------
      // Set the config register to count up
      // and enable the counter
      //-------------------------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Writing to counter config register");
      $display ("-------------------------------");

      num_bytes_x16 <= 4;
      pciex16_m_awaddr <= gddr_ddr_nap_addr[19].addr;
      pciex16_m_awaddr[27:0] <= `REG_CNT_CFG_1_ADDR;
      pciex16_m_wdata[31:0] <= {29'h0, 1'b0, 1'b1, 1'b0};
      pciex16_m_awid    <= $urandom;
      pciex16_m_arid    <= $urandom;

      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      one_byte_data_x16[0] = pciex16_m_wdata[7:0];
      one_byte_data_x16[1] = pciex16_m_wdata[15:8];
      one_byte_data_x16[2] = pciex16_m_wdata[23:16];
      one_byte_data_x16[3] = pciex16_m_wdata[31:24];
      
      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      $strobe("PCIEX16 :: Write address %h ", pciex16_m_awaddr );
      $strobe("PCIEX16 :: Write  data %h ",  pciex16_m_wdata);
      $strobe("PCIEx16 as master requesting to Write to %s",gddr_ddr_nap_addr[19].slave_info);
      
      $display("PCIEX16 ::reg_addr_count_pcie_x16  %d ", reg_addr_count_pcie_x16 );
      
      ac7t1500.pcie0.master.write(pciex16_m_awaddr,one_byte_data_x16,num_bytes_x16,pciex16_m_bresp);

      ac7t1500.pcie0.master.read(pciex16_m_awaddr,num_bytes_x16,one_byte_read_data_x16,pciex16_m_rresp);

      $strobe("PCIE as master requesting to Read from  %s", gddr_ddr_nap_addr[19].slave_info );
      $strobe("PCIEx16 :: Read address %h", pciex16_m_awaddr); 
      compare_dma_write_read_single(pciex16_m_awaddr,pciex16_m_awaddr,one_byte_data_x16,
                                    one_byte_read_data_x16,num_bytes_x16, pciex16_m_awsize,
                                    pciex16_m_awburst,pciex16_m_bresp,num_bytes_x16, 
                                    pciex16_m_arsize,pciex16_m_arburst,pciex16_m_rresp);
      


      // Now stop the up counter
      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      pciex16_m_wdata[31:0] <= {29'h0, 1'b0, 1'b0, 1'b0};
      pciex16_m_awid    <= $urandom;
      pciex16_m_arid    <= $urandom;

      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      one_byte_data_x16[0] = pciex16_m_wdata[7:0];
      one_byte_data_x16[1] = pciex16_m_wdata[15:8];
      one_byte_data_x16[2] = pciex16_m_wdata[23:16];
      one_byte_data_x16[3] = pciex16_m_wdata[31:24];
      
      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 
      $strobe("PCIEX16 :: Write address %h ", pciex16_m_awaddr );
      $strobe("PCIEX16 :: Write  data %h ",  pciex16_m_wdata);
      $strobe("PCIEx16 as master requesting to Write to %s",gddr_ddr_nap_addr[19].slave_info);
      
      $display("PCIEX16 ::reg_addr_count  %d ", reg_addr_count_pcie_x16 );
      
      ac7t1500.pcie0.master.write(pciex16_m_awaddr,one_byte_data_x16,num_bytes_x16,pciex16_m_bresp);

      ac7t1500.pcie0.master.wait_cycles(1); // Wait one clock cycle on the PCIe master's clock, to get aligned.


      //-----------------------------
      // read counter and check it's
      // value is smaller
      //-----------------------------
      $display ("-------------------------------");
      $display ($time, ": PCIex16 Reading counter register");
      $display ("-------------------------------");
      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 

      num_bytes_x16 <= 4;
      pciex16_m_awaddr <= gddr_ddr_nap_addr[19].addr;
      pciex16_m_awaddr[27:0] <= `REG_CNT_1_ADDR;
      pciex16_m_awid    <= $urandom;
      pciex16_m_arid    <= $urandom;
      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 

      ac7t1500.pcie0.master.read(pciex16_m_awaddr,num_bytes_x16,one_byte_read_data_x16,pciex16_m_rresp);


      for (i =0; i<4 ; i++) begin
         case(i)
           0: read_count_value_x16[7:0]   <= one_byte_read_data_x16[0];
           1: read_count_value_x16[15:8]  <= one_byte_read_data_x16[1];
           2: read_count_value_x16[23:16] <= one_byte_read_data_x16[2];
           3: read_count_value_x16[31:24] <= one_byte_read_data_x16[3];
         endcase // case (i)
      end
      
      ac7t1500.pcie0.master.wait_cycles(1); // advance the clock 

      if(read_count_value_x16 > counter_value_x16) // check number decreased
        $strobe("PCIEx16 :: Counter old value %h < counter new value %h", counter_value_x16, read_count_value_x16);
      else begin
         $display(" ERROR:: Old counter %h",counter_value_x16);
         $display(" ERROR:: New counter %h",read_count_value_x16);
         $error("ERROR :: Old counter NOT < new counter value"); 
         $fatal("ERROR :: Old counter NOT < new counter value"); 
      end

      $display ($time, ": ========================PCIex8 BFM Mode Test Completed =============================");
      pciex16_bfm_test_done = 1;

   end // initial begin

   //-----------------------------------
   // PCIe Slave tasks
   //-----------------------------------

   //---------------------------
   // Wait for a write request
   // collect the data
   // and send a write response

   initial begin
      wait(test_start == 1)
        forever begin
           ac7t1500.pcie0.slave.get_write_request(pciex16_s_awaddr, slvx16_wr_num_bytes,slavex16_data_bytes, pciex16_s_awid);
           slavex16_write_id_queue.push_front(pciex16_s_awid);
        end
   end 

   initial  begin 
      wait(test_start == 1)
        forever 
          begin
             if (slavex16_write_id_queue.size() > 0) begin
                bidx16 = slavex16_write_id_queue.pop_back();
                ac7t1500.pcie0.slave.issue_write_response(pciex16_s_bresp,bidx16);
             end
             else
               ac7t1500.pcie0.slave.wait_cycles(1);
          end
   end
   


   initial begin
      wait(test_start == 1)
        forever begin
           ac7t1500.pcie0.slave.get_read_request(pciex16_s_araddr, read_slvx16_num_bytes, read_id_x16);
           slavex16_read_id_queue.push_front(read_id_x16);
        end
   end

   initial begin
      wait(test_start == 1)
        forever 
          begin
             if (slavex16_read_id_queue.size() > 0) begin
                {slavex16_rid} = slavex16_read_id_queue.pop_back();
                ac7t1500.pcie0.slave.issue_read_response(read_slvx16_num_bytes,slavex16_data_bytes,2'b00,slavex16_rid  );
             end
             else  
               ac7t1500.pcie0.slave.wait_cycles(1);
          end
   end

`else
      assign pciex16_bfm_test_done = 1;
`endif


endmodule
