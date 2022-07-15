// ------------------------------------------------------------------
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
//  Description: dot product using MLP, 1x mode
//
// ------------------------------------------------------------------
//
// Computes a dot product of arbitrary size vectors i_a and i_b.
//
// The dot product is SUM i_a[j]*i_b[j].
// Vector i_a[...] should have a multiple of M=4 elements, where each
// element is an N=8 bit signed integer. Input is M=4 elements per cycle.
// Likewise for i_b[...].
//
// When passing in i_a and i_b:
// The first block (of M elements) should be indicated with i_start=1.
// The last block should be indicated with i_last=1.
// Output o_valid will be high for one cycle when o_sum is the dot-product.
//
// ------------------------------------------------------------------


`timescale 1 ps / 1 ps

module dot_product_4_8x8 #(
    localparam integer N = 8,       // integer size
    localparam integer M = 4,       // number parallel multiplies
    localparam integer S = 48       // bits in result
) (
    input  wire             i_clk,
    // input data
    input  wire [M*N-1 : 0] i_a,       // M N-bit integers (2's compl)
    input  wire [M*N-1 : 0] i_b,       // M N-bit integers (2's compl)
    input  wire             i_first,   // high for first item of dotproduct
    input  wire             i_last,    // high for last item of dotproduct
    // output data
    output wire [S-1 : 0]   o_sum,     // dot product (2's compl)
    output wire             o_valid    // high when o_sum is finished dotproduct
);

  wire [71:0] mlp_out;
  assign o_sum = mlp_out[S-1:0];

  // MLP is configured for 2 cycles delay
  reg [1:0] last = 2'b0;
  always @(posedge i_clk)
  begin
      last <= {last[0], i_last};
  end
  assign o_valid = last[1];

    // ---------------------------------------------
    // Cascade paths
    // ---------------------------------------------
    // Float wires for cascade signals
    wire float;    
    ACX_FLOAT X_ACX_FLOAT(.y(float));

    ACX_MLP72 #(
        .mux_sel_multa_l        (2'b00),    // input 'a' from fabric
        .mux_sel_multb_l        (2'b00),    // input 'b' from fabric
        .bytesel_00_07          (5'h0),     // int8, 1x mode
        .multmode_00_07         (5'h0),     // int8, 2's complement
        .add_00_07_bypass       (1'b1),     // use mult 0..3
        .add_00_15_sel          (1'b0),     // use mult 0..3
        .fpmult_ab_bypass       (1'b1),     // integer mode
        .del_add_00_07_reg      (1'b1),     // enable stage2 reg
        .cesel_add_00_07_reg    (4'd13),    // no ce
        .rstsel_add_00_07_reg   (3'd5),     // no rstn
        .fpadd_ab_dinb_sel      (3'b000),   // accumulator mode
        .add_accum_ab_bypass    (1'b0),     // use AB int accumulator
        .accum_ab_reg_din_sel   (1'b0),     // integer mode
        .del_accum_ab_reg       (1'b1),     // use AB register (accumulator)
        .cesel_accum_ab_reg     (4'd13),    // no ce
        .rstsel_accum_ab_reg    (3'd5),     // no rstn
        .rndsubload_share       (1'b1),     // use regular load etc. pin for AB reg
        .del_rndsubload_reg     (3'd1),     // delay match for load etc.
        .cesel_rndsubload_reg   (4'd13),    // no ce
        .rstsel_rndsubload_reg  (3'd5),     // no rstn
        .dout_mlp_sel           (2'b10),    // result = AB register
        .outmode_sel            (2'b00)     // output = MLP result
    ) u_mlp (
        .clk                    (i_clk),
        .din                    ({8'b0, i_a, i_b}),
        .sub                    (1'b0),
        .load                   (i_first),
        .dout                   (mlp_out),

        // Unused pins, included to remove simulation warnings
        .sub_ab                 (1'b0),
        .load_ab                (1'b0),
        .mlpram_bramdout2mlp    (),
        .mlpram_bramdin2mlpdin  (),
        .mlpram_mlp_dout        (),

        .sbit_error             (),
        .dbit_error             (),
        .full                   (),
        .almost_full            (),
        .empty                  (),
        .almost_empty           (),
        .write_error            (),
        .read_error             (),

        .fwdo_multa_h           (),
        .fwdo_multb_h           (),
        .fwdo_multa_l           (),
        .fwdo_multb_l           (),
        .fwdo_dout              (),
        .mlpram_din             (),
        .mlpram_dout            (),
        .mlpram_we              (),

        .fwdi_multa_h           ({72{float}}),
        .fwdi_multb_h           ({72{float}}),
        .fwdi_multa_l           ({72{float}}),
        .fwdi_multb_l           ({72{float}}),
        .fwdi_dout              ({48{float}}),

        .mlpram_din2mlpdout     (),
        .mlpram_rdaddr          (),
        .mlpram_wraddr          (),
        .mlpram_dbit_error      (),
        .mlpram_rden            (),
        .mlpram_sbit_error      (),
        .mlpram_wren            (),

        .lram_wrclk             (i_clk),
        .lram_rdclk             (i_clk),
        .ce                     (12'hfff),
        .rstn                   ({4{1'b1}}),
        .expb                   ()

        //.dft_0                  (1'b0),
        //.dft_1                  (1'b0),
        //.dft_2                  (1'b0)

    );


endmodule : dot_product_4_8x8


