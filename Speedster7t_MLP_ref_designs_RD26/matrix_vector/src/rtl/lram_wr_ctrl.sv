//
//  Copyright (c) 2019  Achronix Semiconductor Corp.
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
//  Description: Generate control signals for LRAM write
//
///////////////////////////////////////////////////////////////////////////////

// i_active should go high when the first data item reaches LRAM 'id', and
// stay high as long as data is passed.
// The first write occurs when the last LRAM has been reached by an item. This
// can be computed locally based on the distance M-id to the last LRAM.
// After that, every M cycles a write occurs, until i_active goes low.

`timescale 1 ps / 1 ps

module lram_wr_ctrl #(
    parameter  integer M = 6,   // number of LRAMs
    parameter  integer id = 0,  // number of this LRAM
    parameter  integer A = 6    // address width
) (
    input  wire           i_clk,
    input  wire           i_active,
    input  wire           i_pause,
    output wire           o_wren,
    output wire [A-1 : 0] o_wraddr
);

  localparam integer counter_wd = $clog2(M);
  // we start the counter one value low, to account for the latency of
  // making wren a register.
  localparam bit [counter_wd-1 : 0] counter_start = (M - id - 1);
  localparam bit [counter_wd-1 : 0] counter_wrap = M - 1;
  reg [counter_wd-1 : 0] counter;
  reg [A-1 : 0] wraddr;
  (* syn_allow_retiming=0 *) reg wren;
  reg pause;

  assign o_wren = wren;
  assign o_wraddr = wraddr;

  wire [counter_wd : 0] counter_next = counter - 1'b1;
  wire counter_zero = counter_next[counter_wd]; // counter_next < 0

  always @(posedge i_clk)
  begin
      if (!i_active)
        begin
          wren <= 1'b0;
          wraddr <= '0;
          counter <= counter_start;
          pause <= 1'b0;
        end
      else
        begin
          if (counter_zero)
              wren <= 1'b1;
          else
              wren <= 1'b0;

          if (!i_pause)
            begin
              if (counter_zero)
                  counter <= counter_wrap;
              else
                  counter <= counter_next[0 +: counter_wd];
            end

          pause <= i_pause;
          if (wren && !pause)
              wraddr <= wraddr + 1'b1;
        end
  end

endmodule : lram_wr_ctrl

