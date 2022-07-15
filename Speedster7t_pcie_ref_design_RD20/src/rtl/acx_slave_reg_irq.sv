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
//               Interrupt register with set and clear 
// ------------------------------------------------------------------

module acx_slave_reg_irq # (
                            parameter TGT_ADDR_WIDTH = 28,
                            parameter TGT_DATA_WIDTH = 32,
                            parameter ADDR = 0,
                            parameter INIT = 32'h0
                            ) 
   (
     // Inputs
    input  wire                       i_clk,
    input  wire                       i_rstn,
    input  wire [4-1:0]               i_wr,
    input  wire                       i_rd,
    input  wire [TGT_ADDR_WIDTH-1:0]  i_addr,
    input  wire [TGT_DATA_WIDTH-1:0]  i_write_data,
    input  wire [TGT_DATA_WIDTH-1:0]  i_irq_set, 
    input  wire [TGT_DATA_WIDTH-1:0]  i_irq_clear,
    
    // Outputs
    output reg                        o_addr_hit,
    output wire [TGT_DATA_WIDTH-1:0]  o_read_data,
    output wire [TGT_DATA_WIDTH-1:0]  o_irq 
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

    integer i;

    // Write
    always @ (posedge i_clk) begin
        if (~i_rstn) begin
            register <= INIT;
        end
        else if (cs & (i_wr != 0)) begin
            if (i_wr[0]) begin
                register[7:0]   <= i_write_data[7:0]; 
            end
            if (i_wr[1]) begin
                register[15:8]  <= i_write_data[15:8]; 
            end
            if (i_wr[2]) begin
                register[23:16] <= i_write_data[23:16]; 
            end
            if (i_wr[3]) begin
                register[31:24] <= i_write_data[31:24]; 
            end
        end
        else begin
            for (i=0; i<32; i=i+1) begin
                // Clear
                if (i_irq_clear[i]) begin
                    register[i] <= 1'b0;
                end
                // Set
                else if (i_irq_set[i]) begin
                    register[i] <= 1'b1;
                end
            end // for
        end
    end

    // Read
    assign o_read_data = register;
    assign o_irq       = register;

endmodule : acx_slave_reg_irq


