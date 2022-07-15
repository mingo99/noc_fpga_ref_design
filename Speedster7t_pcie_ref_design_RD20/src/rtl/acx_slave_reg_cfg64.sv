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
//     Function: AXI Slave Registers 
//               64-bit configuration register
// ------------------------------------------------------------------

module acx_slave_reg_cfg64 # (
    parameter TGT_ADDR_WIDTH    = 28,
    parameter TGT_DATA_WIDTH    = 64,
    parameter ADDR              = 0,
    parameter INIT              = 64'hDEADBEAFDEADBEAF
) 
(
     // Input
    input  wire                        i_clk,
    input  wire                        i_rstn,
    input  wire  [8-1:0]               i_wr,
    input  wire                        i_rd,
    input  wire  [TGT_ADDR_WIDTH-1:0]  i_addr,
    input  wire  [TGT_DATA_WIDTH-1:0]  i_write_data,

    // Output
    output reg                         o_addr_hit,
    output wire [TGT_DATA_WIDTH-1:0]   o_read_data,
    output wire [TGT_DATA_WIDTH-1:0]   o_cfg
);

    logic [TGT_DATA_WIDTH-1:0] register;

    // Need to register cs.  As many registers connected to a single
    // address bus, there has to some pipelining to allow for the decode
    // The address will be held until the o_addr_hit is asserted
    // This will add a cycle of latency, but this can be supported
    // Potential to reduce latency in the AXI to register interface
    logic cs;

    // Code to avoid 'x propogation
    always@(posedge i_clk)
        if (i_addr === ADDR)
            cs <= 1'b1;
        else
            cs <= 1'b0;
    
   // wire cs = (i_addr == ADDR);

   always@(posedge i_clk)
     begin
        if (~i_rstn) // reset
          o_addr_hit <= 1'b0;
        else
          o_addr_hit <= cs & ((i_wr !=0) | i_rd);
     end
   

    // Write
    always @ (posedge i_clk) begin
        if (~i_rstn) begin
            register <= INIT;
        end
        else if (cs & (i_wr != 0)) begin // bottom 32 bits
            if (i_wr[0]) begin
                register[7:0] <= i_write_data[7:0]; 
            end
            if (i_wr[1]) begin
                register[15:8] <= i_write_data[15:8]; 
            end
            if (i_wr[2]) begin
                register[23:16] <= i_write_data[23:16]; 
            end
            if (i_wr[3]) begin
                register[31:24] <= i_write_data[31:24]; 
            end
    //    end // if (cs & (i_wr != 0))
    //    else if ((cs_next & (i_wr != 0))) begin // top 32 bits
           if (i_wr[4]) begin
              register[7+32:0+32] <= i_write_data[7+32:0+32]; 
           end
           if (i_wr[5]) begin
              register[15+32:8+32] <= i_write_data[15+32:8+32]; 
           end
           if (i_wr[6]) begin
              register[23+32:16+32] <= i_write_data[23+32:16+32]; 
           end
           if (i_wr[7]) begin
              register[31+32:24+32] <= i_write_data[31+32:24+32]; 
           end
        end // if ((cs_next & (i_wr != 0)))
    end // always @ (posedge i_clk)
   
    assign o_read_data = register;
    assign o_cfg       = register;

endmodule : acx_slave_reg_cfg64

