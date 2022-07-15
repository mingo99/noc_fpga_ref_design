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
// ------------------------------------------------------------------

module acx_slave_reg_dout_mux # (
                                 parameter NUM_REGS = 4,
                                 parameter TGT_DATA_WIDTH = 64
                                 ) (
                                    input wire                               i_clk,
                                    input wire                               i_rstn,
                                    input wire [NUM_REGS-1:0]                i_addr_hit,
                                    input wire [NUM_REGS*TGT_DATA_WIDTH-1:0] i_read_data,
                                    output reg [TGT_DATA_WIDTH-1:0]          o_read_data
                                    );

   // A fully parameterized synthesizable mux optimized for a one-hot input  wire (i.e. no priority encoding) 
   // using an OR tree. Note that the output is driven to 0 instead of 'z' if no input  wire is enabled:

   reg [TGT_DATA_WIDTH-1:0]                                                  out, out_d1;

   always @ (*)
     begin
        out = {TGT_DATA_WIDTH{1'b0}};
        for (int unsigned index = 0; index < NUM_REGS; index++)
          begin
             out |= {TGT_DATA_WIDTH{i_addr_hit[index]}} & i_read_data[TGT_DATA_WIDTH*index +: TGT_DATA_WIDTH];
          end
     end

   always @ (posedge i_clk) begin
      if (~i_rstn) begin
         o_read_data <= 'b0;
         out_d1 <= 'b0;
      end
      else begin
         out_d1 <= out;
         o_read_data <= out_d1;
      end
   end

endmodule : acx_slave_reg_dout_mux

