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
//               Read-only, (or static) register 
// ------------------------------------------------------------------

module acx_slave_reg_sta # (
                            parameter TGT_ADDR_WIDTH = 28,
                            parameter TGT_DATA_WIDTH = 32, // 256,
                            parameter ADDR = 28'h0,
                            parameter INIT = 32'hDEADBEEF
                            ) 
   (
    // Inputs
     input  wire                        i_clk,
     input  wire                        i_rstn,
     input  wire                        i_rd,
     input  wire [TGT_ADDR_WIDTH-1:0]   i_addr,
     input  wire [TGT_DATA_WIDTH-1:0]   i_sta, 
                          
    // Outputs
     output reg                         o_addr_hit,
     output wire [(TGT_DATA_WIDTH-1):0] o_read_data,
     output wire [(TGT_DATA_WIDTH-1):0] o_sta 
    );


    logic [(TGT_DATA_WIDTH-1):0]      register;

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
          o_addr_hit <= cs & i_rd;
     end

   // Write
   always @ (posedge i_clk) begin
      if (~i_rstn) begin
         register <= ADDR + INIT;
      end
      else begin
         register <= i_sta;
      end
   end

   // Read
   assign o_read_data = register;
   assign o_sta       = register;
   
endmodule : acx_slave_reg_sta

