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

module acx_axi_req_fifo #(
    parameter WIDTH   = 8,
    parameter DEPTH   = 4,
    parameter ADDR_W  = 2
) (
    // Inputs
     input  wire             i_clk
    ,input  wire             i_rstn
    ,input  wire[WIDTH-1:0]  data_in_i
    ,input  wire             i_push
    ,input  wire             i_pop

    // Outputs
    ,output wire[WIDTH-1:0]  data_out_o
    ,output reg              o_accept
    ,output wire             o_valid
);

    //-----------------------------------------------------------------
    // Local Params
    //-----------------------------------------------------------------
    localparam COUNT_W = ADDR_W + 1;

    //-----------------------------------------------------------------
    // Registers
    //-----------------------------------------------------------------
    reg [WIDTH-1:0]         ram [DEPTH-1:0] /* synthesis syn_ramstyle=registers */;
    reg [ADDR_W-1:0]        rd_ptr;
    reg [ADDR_W-1:0]        wr_ptr;
//    reg [COUNT_W-1:0]       count /* synthesis syn_allow_retiming=0 */  ;
    reg [COUNT_W-1:0]       count /* synthesis syn_allow_retiming=0 */  ;

    //-----------------------------------------------------------------
    // Sequential
    //-----------------------------------------------------------------
    always @ (posedge i_clk)
    if (~i_rstn)
    begin
        count   <= {(COUNT_W) {1'b0}};
        rd_ptr  <= {(ADDR_W)  {1'b0}};
        wr_ptr  <= {(ADDR_W)  {1'b0}};
    end
    else
    begin
        // Push
        if (i_push & o_accept)
        begin
            ram[wr_ptr] <= data_in_i;
            wr_ptr      <= wr_ptr + 1;
        end

        // Pop
        if (i_pop & o_valid)
            rd_ptr      <= rd_ptr + 1;

        // Count up
        if ((i_push & o_accept) & ~(i_pop & o_valid))
            count <= count + 1;
        // Count down
        else if (~(i_push & o_accept) & (i_pop & o_valid))
            count <= count - 1;
    end

    //-------------------------------------------------------------------
    // Combinatorial
    //-------------------------------------------------------------------
    //assign o_accept   = (count != DEPTH);
    wire o_accept_i  ;
    assign o_accept_i = (count < (DEPTH-1));
    assign o_valid    = (count != 0);

    assign data_out_o = ram[rd_ptr];

    always @ (posedge i_clk)
    if (~i_rstn)
    begin
        o_accept <= 1'b0;
    end 
    else begin
        o_accept <= o_accept_i;
    end

endmodule : acx_axi_req_fifo

