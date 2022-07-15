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
//               Counter register 
// ------------------------------------------------------------------

module acx_slave_reg_cnt # (
    parameter TGT_ADDR_WIDTH    = 28,
    parameter TGT_DATA_WIDTH    = 32,
    parameter ADDR              = 0,
    parameter INIT              = 32'h0
) 
(
     // Inputs
    input  wire                        i_clk,
    input  wire                        i_rstn,
    input  wire  [4-1:0]               i_wr,
    input  wire                        i_rd,
    input  wire  [TGT_ADDR_WIDTH-1:0]  i_addr,
    input  wire  [TGT_DATA_WIDTH-1:0]  i_write_data,

    input  wire  [TGT_DATA_WIDTH-1:0]  i_cnt_control,  // {'b0, down/up, start/stop, clear},
    input  wire                        i_cnt_en,

    // Outputs
    output reg                         o_addr_hit,
    output wire [TGT_DATA_WIDTH-1:0]   o_read_data,
    output wire [TGT_DATA_WIDTH-1:0]   o_cnt
);


    logic [TGT_DATA_WIDTH-1:0] counter;

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
            counter <= INIT;
        end
        else if (cs & (i_wr != 0)) begin
            if (i_wr[0]) begin
                counter[7:0] <= i_write_data[7:0]; 
            end
            if (i_wr[1]) begin
                counter[15:8] <= i_write_data[15:8]; 
            end
            if (i_wr[2]) begin
                counter[23:16] <= i_write_data[23:16]; 
            end
            if (i_wr[3]) begin
                counter[31:24] <= i_write_data[31:24]; 
            end
        end
        // Clear
        else if (i_cnt_control[0]) begin
            counter <= INIT;
        end
        // Counting
        else if (i_cnt_control[1] & i_cnt_en) begin
            if (i_cnt_control[2]) counter <= counter - 1'b1;
            else counter <= counter + 1'b1;
        end
    end

    // Read
    assign o_read_data = counter;
    assign o_cnt       = counter;

endmodule : acx_slave_reg_cnt


