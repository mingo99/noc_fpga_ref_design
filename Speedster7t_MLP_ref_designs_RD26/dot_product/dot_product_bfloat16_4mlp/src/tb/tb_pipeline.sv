`default_nettype none
`timescale 1 ps / 1 ps
module tb_pipeline #(
    parameter integer width = 4,
    parameter integer depth = 6
) (
    input  wire               i_clk,
    input  wire [width-1 : 0] i_din,
    output wire [width-1 : 0] o_dout
);

  if (depth == 0)
      assign o_dout = i_din;
  else
    begin
      reg [depth*width-1 : 0] x;
      always @(posedge i_clk)
      begin
          x <= (x << width) | i_din;
      end
      assign o_dout = x[depth*width-1 -: width];
    end

endmodule // tb_pipeline
`default_nettype wire
