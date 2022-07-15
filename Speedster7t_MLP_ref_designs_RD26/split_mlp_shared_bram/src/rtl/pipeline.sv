//
//  Copyright (c) 2020  Achronix Semiconductor Corp.
//  All Rights Reserved.
//
//
//  This software constitutes an unpublished work and contains
//  valuable proprietary information and trade secrets belonging
//  to Achronix Semiconductor Corp.
//
//  This software may not be used, copied, distributed or disclosed
//  without specific prior written authorization from
//  Achronix Semiconductor Corp.
//
//  The copyright notice above does not evidence any actual or intended
//  publication of such software.
//
// ----------------------------------------------------------------------
//  Description: Pipeline with configurable width and depth
//
// ----------------------------------------------------------------------

`timescale 1 ps / 1 ps
module pipeline #(
    parameter integer width = 1,
    parameter integer depth = 0
) (
    input  wire               i_clk,
    input  wire [width-1 : 0] i_din,
    output wire [width-1 : 0] o_dout
);

  if (depth == 0)
      assign o_dout = i_din;
  else
    begin: pipeline
      wire [width-1 : 0] d[depth : 0];
      assign d[0] = i_din;
      for (genvar i = 0; i < depth; i = i + 1)
        begin: p
          reg [width-1 : 0] r;
          always @(posedge i_clk)
              r <= d[i];
          assign d[i+1] = r;
        end
      assign o_dout = d[depth];
    end

endmodule: pipeline

