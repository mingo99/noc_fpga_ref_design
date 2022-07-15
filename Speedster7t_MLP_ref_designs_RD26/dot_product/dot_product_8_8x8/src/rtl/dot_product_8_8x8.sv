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
//  Description: dot product using MLP, 2x mode
//
// ------------------------------------------------------------------
//
// Computes a dot product of variable size vectors i_a and i_b (up to
// 8k elements per vector).
//
// The dot product is SUM i_a[j]*i_b[j].
// Vector i_a[...] should have a multiple of M=8 elements, where each
// element is an N=8 bit signed integer. Input is M=8 elements per cycle.
//
// Vector i_b[...] must be stored in the BRAM, as M=8 byte wide words, at
// consecutive addresses starting from 0. The max address is 1023, so
// the max vector size is 8k elements. i_b must have at least as many
// elements as i_a, and can be used for multiple dot products. i_b must be
// stored before starting the dot product computation.
//
// When passing in i_a:
// The first block (of M elements) should be indicated with i_start=1.
// The last block should be indicated with i_last=1.
// Output o_valid will be high for one cycle when o_sum is the dot-product.
//
// ------------------------------------------------------------------

`timescale 1 ps / 1 ps

module dot_product_8_8x8 #(
    localparam integer N = 8,       // integer size
    localparam integer M = 8,       // number parallel multiplies
    localparam integer A = 10,      // BRAM address bits
    localparam integer S = 48       // bits in result
) (
    input  wire             i_clk,
    // BRAM inputs
    input  wire [M*N-1 : 0] i_b,       // M N-bit integers (2's compl)
    input  wire [A-1 : 0]   i_b_addr,  // BRAM address bits
    input  wire             i_wren,    // BRAM write enable
    // input data for dot-product
    input  wire [M*N-1 : 0] i_a,       // M N-bit integers (2's compl)
    input  wire             i_first,   // high for first item of dotproduct
    input  wire             i_last,    // high for last item of dotproduct
    // output data
    output wire [S-1 : 0]   o_sum,     // dot product (2's compl)
    output wire             o_valid    // high when o_sum is finished dotproduct
);

    reg  [A-1 : 0] rdaddr = '0;
    wire [143 : 0] mlp_b; // only [71:0] is used

    // ---------------------------------------------
    // Cascade paths
    // ---------------------------------------------
    // Float wires for cascade signals
    wire float;    
    ACX_FLOAT X_ACX_FLOAT(.y(float));

    // BRAM used as 1024 x 64-wide
    // We disable the outreg, and instead use the MLP input register
    ACX_BRAM72K #(
        .write_width            (4'b0001),      // 72-bit wide, 8-bit bytes
        .read_width             (4'b0001),      // 72-bit wide, 8-bit bytes
        .wrmem_input_sel        (2'b00),        // write port input: from fabric
        .rdmem_input_sel        (2'b00),        // read port input: from fabric
        .fifo_enable            (1'b0),         // BRAM mode
        .ecc_bypass_encode      (1'b1),         // no ECC
        .ecc_bypass_decode      (1'b1),         // no ECC
        .outreg_enable          (1'b0),         // disable outreg
        .dout_sel               (1'b0)          // no revi
    ) u_bram (
        .wrclk                  (i_clk),
        .wren                   (i_wren),
        .we                     (9'h0FF),       // enable 8 bytes
        .wraddrhi               (i_b_addr),
        .wrmsel                 (1'b0),         // no special address mode
        .din                    ({8'b0, i_b}),
        .rdclk                  (i_clk),
        .rden                   (1'b1),         // always read
        .rdaddrhi               (rdaddr),
        .rdmsel                 (1'b0),         // no special address mode
        .outlatch_rstn          (1'b1),
        .outreg_rstn            (1'b1),
        .outreg_ce              (1'b1),
        .dout                   (),
        .mlpram_dout2mlp        (mlp_b),         // output to MLP

        // Unused pins, instantiated to remove simulation warnings
        .mlpram_we              (),
        .sbit_error             (),
        .dbit_error             (),
        .full                   (),
        .almost_full            (),
        .empty                  (),
        .almost_empty           (),
        .write_error            (),
        .read_error             (),

        //.bram_mlpclk            (),
        .mlpram_din2mlpdin      (),
        .mlpram_din2mlpdout     (),
        .mlpram_mlp_dout        (),
        .mlpram_din             (),
        .mlpram_dout            (),
        .mlpram_rdaddr          (),
        .mlpram_wraddr          (),
        .mlpram_dbit_error      (),
        .mlpram_rden            (),
        .mlpram_sbit_error      (),
        .mlpram_wren            (),

        .fwdi_ram_wr_addr       ({14{float}}),
        .fwdi_ram_wblk_addr     ({7{float}}),
        .fwdi_ram_we            ({18{float}}),
        .fwdi_ram_wren          (float),
        .fwdi_ram_wr_data       ({144{float}}),
        .fwdi_ram_rd_addr       ({14{float}}),
        .fwdi_ram_rblk_addr     ({7{float}}),
        .fwdi_ram_rden          (float),
        .fwdi_ram_rdmsel        (float),
        .fwdi_ram_wrmsel        (float),

        .revi_ram_rd_addr       ({14{float}}),
        .revi_ram_rblk_addr     ({7{float}}),
        .revi_ram_rden          (float),
        .revi_ram_rd_data       ({144{float}}),
        .revi_ram_rdval         (float),
        .revi_ram_rdmsel        (float),
        .revi_rblk_addr         ({7{float}}),
        .revi_wblk_addr         ({7{float}}),

        .revo_ram_rd_addr       (),
        .revo_ram_rblk_addr     (),
        .revo_ram_rden          (),
        .revo_ram_rdmsel        (),
        .revo_ram_rd_data       (),
        .revo_ram_rdval         (),
        .revo_rblk_addr         (),
        .revo_wblk_addr         (),

        .fwdo_ram_wr_addr       (),
        .fwdo_ram_wblk_addr     (),
        .fwdo_ram_we            (),
        .fwdo_ram_wren          (),
        .fwdo_ram_wr_data       (),
        .fwdo_ram_rd_addr       (),
        .fwdo_ram_rblk_addr     (),
        .fwdo_ram_rden          (),
        .fwdo_ram_rdmsel        (),
        .fwdo_ram_wrmsel        ()

        //.dft_0                  ()

    );

    wire [71:0] mlp_out;
    assign o_sum = mlp_out[S-1:0];

  // The BRAM has rdaddr -> dout has a cycle latency. If 'a' input and
  // rdaddr are issued simultaneously, then the 'a' input needs an extra
  // cycle latency. Therefore, for 'a' we use a stage0 and stage1 register,
  // but for 'b' only a stage0 register.
    ACX_MLP72 #(
        .mux_sel_multa_l        (2'b00),        // input 'a' from fabric
        .mux_sel_multb_l        (2'b10),        // input 'b' from BRAM

        .del_multa_l            (1'b1),         // enable stage0 register
        .del_multb_l            (1'b1),         // enable stage0 register
        .cesel_multa_l          (4'd13),        // no ce
        .cesel_multb_l          (4'd13),        // no ce
        .rstsel_multa_l         (3'd5),         // no rstn
        .rstsel_multb_l         (3'd5),         // no rstn

        // enable stage1 register for 'a', to match latency of the BRAM
        .del_mult00a            (1'b1),         // enable stage1 register
        .del_mult01a            (1'b1),         // enable stage1 register
        .del_mult02a            (1'b1),         // enable stage1 register
        .del_mult03a            (1'b1),         // enable stage1 register
        .del_mult04_07a         (1'b1),         // enable stage1 register
        .cesel_mult00a          (4'd13),        // no ce
        .cesel_mult01a          (4'd13),        // no ce
        .cesel_mult02a          (4'd13),        // no ce
        .cesel_mult03a          (4'd13),        // no ce
        .cesel_mult04_07a       (4'd13),        // no ce
        .rstsel_mult00a         (3'd5),         // no rstn
        .rstsel_mult01a         (3'd5),         // no rstn
        .rstsel_mult02a         (3'd5),         // no rstn
        .rstsel_mult03a         (3'd5),         // no rstn
        .rstsel_mult04_07a      (3'd5),         // no rstn

        .bytesel_00_07          (5'h01),        // int8, 2x mode
        .multmode_00_07         (5'h0),         // int8, 2's complement
        .add_00_07_bypass       (1'b0),         // use mult 0..7

        .del_add_00_07_reg      (1'b1),         // enable stage2 reg 
        .cesel_add_00_07_reg    (4'd13),        // no ce
        .rstsel_add_00_07_reg   (3'd5),         // no rstn

        .add_00_15_sel          (1'b0),         // use mult 0..7
        .fpmult_ab_bypass       (1'b1),         // integer mode
        .fpmult_cd_bypass       (1'b1),         // integer mode
        .fpadd_ab_dinb_sel      (3'b000),       // accumulator mode
        .add_accum_ab_bypass    (1'b0),         // use AB int accumulator
        .accum_ab_reg_din_sel   (1'b0),         // integer mode

        .del_accum_ab_reg       (1'b1),         // use AB register (accumulator/output)
        .cesel_accum_ab_reg     (4'd13),        // no ce
        .rstsel_accum_ab_reg    (3'd5),         // no rstn

        .rndsubload_share       (1'b1),         // use regular load etc. pin for AB reg
        .del_rndsubload_reg     (3'd3),         // delay match for load etc.
        .cesel_rndsubload_reg   (4'd13),        // no ce
        .rstsel_rndsubload_reg  (3'd5),         // no rstn

        .dout_mlp_sel           (2'b10),        // result = AB register
        .outmode_sel            (2'b00)         // output = MLP result
    ) u_mlp (
        .clk                    (i_clk),
        .din                    ({8'b0, i_a}),
        .mlpram_bramdout2mlp    (mlp_b),
        .sub                    (1'b0),
        .load                   (i_first),
        .dout                   (mlp_out),


        // Unused pins, included to remove simulation warnings
        .sub_ab                 (1'b0),
        .load_ab                (1'b0),
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
        .expb                   (8'h00)

        //.dft_0                  (1'b0),
        //.dft_1                  (1'b0),
        //.dft_2                  (1'b0)

    );

  // MLP is configured for 4 cycles delay
  reg [3:0] last = 2'b0;
  always @(posedge i_clk)
  begin
      last <= {last[2:0], i_last};
  end
  assign o_valid = last[3];


  // BRAM read address generation:
  // register is initialized to 0
  // when i_first, register starts incrementing
  //    - When i_first=1, rdaddr = 0, BRAM. It takes two cycles for B[0]
  //      to reach the mult input (1 cycle for BRAM + 1 cycle for stage0 reg)
  //    - When i_first=1, mlp din = A[0]. Likewise, it takes two cycles for A[0]
  //      to reach the mult input (stage0 + stage1 regs)
  // when i_last, register is set back to 0 and stops incrementing
  reg incrementing = 1'b0;
  always @(posedge i_clk)
  begin
      if (i_last)
          incrementing <= 1'b0;
      else if (i_first)
          incrementing <= 1'b1;
          
      if (i_last)
          rdaddr <= '0;
      else if (i_first || incrementing)
          rdaddr <= rdaddr + 1'b1;
  end
 
endmodule : dot_product_8_8x8


