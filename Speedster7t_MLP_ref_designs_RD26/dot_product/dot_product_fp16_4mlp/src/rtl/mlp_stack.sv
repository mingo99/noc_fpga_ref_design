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
//  Description: dot product using 4 MLPs, 1x mode, fp16 inputs and output
//
// ------------------------------------------------------------------
//
// Computes a dot product of arbitrary size vectors i_a and i_b.
//
// The dot product is SUM i_a[j]*i_b[j].
// Vectors i_a and i_b should each have a multiple of K*B=8 elements,
// where each element is a 16-bit fp16 number. Input is 8 i_a elements
// and 8 i_b lements per cycle.
//
// When passing in i_a and i_b:
// The first block (of M elements) should be indicated with i_start=1.
// The last block should be indicated with i_last=1.
// Output o_valid will be high for one cycle when o_sum is the dot-product.
//
// ------------------------------------------------------------------

`timescale 1 ps / 1 ps

module mlp_stack #(
    localparam integer K = 4,           // number of MLPs, must be >= 2
    localparam integer B = 2,           // number parallel multiplies for one MLP
    localparam integer FP = 16,         // floating point size (fp16)
    localparam integer E = 5,           // exponent size
    localparam integer P = FP - E       // fp precision
) (
    input  wire             i_clk,
    // input data
    input  wire [K*B*FP-1 : 0] i_a,     // parallel args for all MLPs (fp16)
    input  wire [K*B*FP-1 : 0] i_b,     // parallel args for all MLPs (fp16)
    input  wire                i_first, // high for first item of dotproduct
    input  wire                i_last,  // high for last item of dotproduct
    // output data
    output wire [FP-1 : 0]      o_sum,  // dot product (fp16)
    output wire                 o_valid // high when o_sum is the finished dotproduct
);

  localparam FP24 = 24; // bits for fp24 (dout cascade must use fp24)

  // First MLP has 5 stages delay, the other K-1 MLPs add 1 stage each, and
  // then the last one adds two more for the accumulator and format conversion,
  // so 5 + (K-1) + 2 = K+6 stages total
  localparam latency = 5 + K-1 + 2;
  reg [latency-1 : 0] last = {latency {1'b0}};
  always @(posedge i_clk)
  begin
      last <= {last[latency-2 : 0], i_last};
  end
  assign o_valid = last[latency-1];

  wire [K*B*FP-1 : 0] a_stage[K-1 : 0];     // a_stage[i] = 'a' input for stage i
  wire [K*B*FP-1 : 0] b_stage[K-1 : 0];     // b_stage[i] = 'b' input for stage i
  wire [FP24-1 : 0] dout_stage[K-1 : 0];    // dout_stage[i] = dout of stage i
  wire [K-1 : 0] load_stage;                // load_stage[i] = load of stage i

  assign a_stage[0] = i_a;
  assign b_stage[0] = i_b;
  assign load_stage[0] = i_first;
  assign o_sum = dout_stage[K-1][0 +: FP];

  // ---------------------------------------------
  // Cascade paths
  // ---------------------------------------------
  // Float wires for cascade signals
  wire float;    
  ACX_FLOAT X_ACX_FLOAT(.y(float));

  for (genvar i = 0; i < K; i = i + 1)
    begin: mlp_stage
      //                fpadd_casc     fpadd_ab         fpadd_cd
      // first stage:   (bypass)       (ab/bypass)      cd + fpadd_ab
      // middle stages: (bypass)       ab + casc        cd + fpadd_ab
      // last stage:    cd + casc      ab + fpadd_casc  fpadd_ab + accum
      localparam bit       fpadd_casc_bypass = (i == K-1)? 1'b0 : 1'b1;
      localparam bit [2:0] fpadd_ab_dinb_sel = (i == K-1)? 3'b001 : 3'b100;
      localparam bit       add_accum_ab_bypass  = (i == 0)? 1'b1 : 1'b0;
      localparam bit       accum_ab_reg_din_sel = !add_accum_ab_bypass;

      localparam integer stage_bits_in = K*B*FP - i*B*FP;
      localparam integer stage_bits_out = stage_bits_in - B*FP;

      wire [FP-1 : 0]       a0, a1, b0, b1; // B=2 inputs per MLP
      wire [72-1 : 0]       mlp_dout;
      wire [2*FP24-1 : 0]   cascade_in, cascade_out;
      wire                  load;

      assign a0 = a_stage[i][i*B*FP +: FP];
      assign a1 = a_stage[i][i*B*FP+FP +: FP];
      assign b0 = b_stage[i][i*B*FP +: FP];
      assign b1 = b_stage[i][i*B*FP+FP +: FP];
      assign load = (i == K-1)? load_stage[i] : 1'b0;

      if (i == 0)
          assign cascade_in = {2*FP24 {float}};
      else
          assign cascade_in = {dout_stage[i-1], {FP24 {float}}};


      // force pin to remain unconnected rather than tied off
      wire Open;
      ACX_FLOAT undriven(Open);

      ACX_MLP72 #(
          // input selection:
          .mux_sel_multa_h(3'b000),  // from fabric [71:0]
          .mux_sel_multa_l(2'b00),   // from fabric [71:0]
          .mux_sel_multb_h(3'b000),  // from fabric [71:0]
          .mux_sel_multb_l(2'b00),   // from fabric [71:0]
          // input format:
          .bytesel_00_07(5'h17),     // fp16_2x
          .bytesel_08_15(6'h17),     // fp16_2x
          // multiplier operation:
          .multmode_00_07(5'h10),    // u16xu16 (fp)
          .multmode_08_15(5'h10),    // u16xu16 (fp)
          // adder tree:
          .add_00_07_bypass(1'b1),   // mult 0-3 for one 16x16 for fp
          .add_08_15_bypass(1'b1),   // mult 8-11 for one 16x16 for fp
          // floating point:
          .fpadd_abcd_sel(1'b1),     // add fpmul_ab + fpmul_cd
          .fpmult_ab_bypass(1'b0),   // floating point mode
          .fpmult_ab_blockfp(1'b0),  // regular floating point
          .fpmult_ab_blockfp_mode(3'b000),  // not used
          .fpmult_ab_exp_size(1'b1), // fp16: 5-bit exponent
          .fpmult_cd_bypass(1'b0),   // floating point mode (not used)
          .fpmult_cd_blockfp(1'b0),  // regular floating point
          .fpmult_cd_blockfp_mode(3'b000), // not used
          .fpmult_cd_exp_size(1'b1), // fp16: 5-bit exponent
          // accumulator:
          .fpadd_ab_dinb_sel(3'b100), // fwdi_dout from fpadd_ab
          .fpadd_cd_dina_sel(1'b1),   // from fpadd_ab (top mlp only)
          .fpadd_cd_dinb_sel(3'b000), // accumulator (top mlp only)
          .add_accum_ab_bypass(add_accum_ab_bypass), // bypassed for bot mlp
          .add_accum_cd_bypass(1'b0), // adder used (top mlp only)
          .rndsubload_share(1'b0),
          // output:
          .accum_ab_reg_din_sel(accum_ab_reg_din_sel), // (applies to int and fp)
          .out_reg_din_sel(3'b010),    // fpadd_cd
          .fpadd_ab_output_format(2'b00), // fp24 (not used, output to fwdo_dout)
          .fpadd_cd_output_format(2'b10), // fp16
          .dout_mlp_sel(2'b01),       // {fpadd_ab, fpadd_cd}
          .outmode_sel(2'b11),        // fp with format conversion
          // stage 0 registers:
          .del_multa_h(1'b0),
          .del_multa_l(1'b0),
          .del_multb_h(1'b0),
          .del_multb_l(1'b0),
          .del_expb_din_reg(1'b0),
          // stage 1 registers:
          .del_mult00a(1'b1),
          .del_mult00b(1'b1),
          .del_mult01a(1'b1),
          .del_mult01b(1'b1),
          .del_mult02a(1'b1),
          .del_mult02b(1'b1),
          .del_mult03a(1'b1),
          .del_mult03b(1'b1),
          .del_mult04_07a(1'b0),      // mult 4-7 not used
          .del_mult04_07b(1'b0),
          .del_mult08_11a(1'b1),
          .del_mult08_11b(1'b1),
          .del_mult12_15a(1'b0),      // mult 12-15 not used
          .del_mult12_15b(1'b0),
          // stage 2 registers:
          .del_add_00_07_reg(1'b1),
          .del_add_08_15_reg(1'b1),
          // delay match registers for stage1..2 (for fp exp/sign):
          .del_expa_reg(2'd2), // 0..2   s1 and s2
          .del_expb_reg(2'd2), // 0..2
          .del_expc_reg(2'd2), // 0..2
          .del_expd_reg(2'd2), // 0..2
          // fp registers (stage 2.5 and stage 3):
          .del_fpmult_ab_pipe_reg(1'b1),
          .del_fpmult_cd_pipe_reg(1'b1),
          .del_fpmult_ab_reg(1'b1), // typically only used if fpadd_abcd_sel=1
          // delay match registers for stage0..3/4 (for int and fp sub/load):
          .del_rndsubload_ab_reg(3'd4), // 0..5  s1+s2+s2.5+s3
          .del_rndsubload_reg(3'd5), // 0..6     s1+s2+s2.5+s3+s4(ab)
          // stage 4 registers:
          .del_accum_ab_reg(1'b1),
          .del_out_reg_00_15(1'b1),
          .del_out_reg_16_31(1'b1),
          .del_out_reg_32_47(1'b0),
          .del_out_reg_48_63(1'b0),
          .del_fp_format_ab_reg(1'b0),
          .del_fp_format_cd_reg(1'b1),
          // cesel for each register (use 4'd13 for tie high):
          .cesel_multa_h(4'd0),
          .cesel_multa_l(4'd0),
          .cesel_multb_h(4'd0),
          .cesel_multb_l(4'd0),
          .cesel_expb_din_reg(4'd0),
          .cesel_mult00a(4'd13),
          .cesel_mult00b(4'd13),
          .cesel_mult01a(4'd13),
          .cesel_mult01b(4'd13),
          .cesel_mult02a(4'd13),
          .cesel_mult02b(4'd13),
          .cesel_mult03a(4'd13),
          .cesel_mult03b(4'd13),
          .cesel_mult04_07a(4'd0),
          .cesel_mult04_07b(4'd0),
          .cesel_mult08_11a(4'd13),
          .cesel_mult08_11b(4'd13),
          .cesel_mult12_15a(4'd0),
          .cesel_mult12_15b(4'd0),
          .cesel_add_00_07_reg(4'd13),
          .cesel_add_08_15_reg(4'd13),
          .cesel_expta_reg(4'd13),
          .cesel_exptb_reg(4'd13),
          .cesel_exptc_reg(4'd13),
          .cesel_exptd_reg(4'd13),
          .cesel_fpmult_ab_pipe_reg(4'd13),
          .cesel_fpmult_cd_pipe_reg(4'd13),
          .cesel_fpmult_ab_reg(4'd13),
          .cesel_rndsubload_ab_reg(4'd13), // could be 0, but this way it is timed
          .cesel_rndsubload_reg(4'd13),
          .cesel_accum_ab_reg(4'd13),
          .cesel_out_reg_00_15((i == K-1)? 4'd13 : 4'd0),
          .cesel_out_reg_16_31((i == K-1)? 4'd13 : 4'd0),
          .cesel_out_reg_32_47(4'd0),
          .cesel_out_reg_48_63(4'd0),
          .cesel_fp_format_ab_reg(4'd0),
          .cesel_fp_format_cd_reg(4'd13),
          // rstsel for each register (use 3'd5 for tie high):
          .rstsel_multa_h(3'd0),
          .rstsel_multa_l(3'd0),
          .rstsel_multb_h(3'd0),
          .rstsel_multb_l(3'd0),
          .rstsel_expb_din_reg(3'd0),
          .rstsel_mult00a(3'd5),
          .rstsel_mult00b(3'd5),
          .rstsel_mult01a(3'd5),
          .rstsel_mult01b(3'd5),
          .rstsel_mult02a(3'd5),
          .rstsel_mult02b(3'd5),
          .rstsel_mult03a(3'd5),
          .rstsel_mult03b(3'd5),
          .rstsel_mult04_07a(3'd0),
          .rstsel_mult04_07b(3'd0),
          .rstsel_mult08_11a(3'd5),
          .rstsel_mult08_11b(3'd5),
          .rstsel_mult12_15a(3'd0),
          .rstsel_mult12_15b(3'd0),
          .rstsel_add_00_07_reg(3'd5),
          .rstsel_add_08_15_reg(3'd5),
          .rstsel_expta_reg(3'd5),
          .rstsel_exptb_reg(3'd5),
          .rstsel_exptc_reg(3'd5),
          .rstsel_exptd_reg(3'd5),
          .rstsel_fpmult_ab_pipe_reg(3'd5),
          .rstsel_fpmult_cd_pipe_reg(3'd5),
          .rstsel_fpmult_ab_reg(3'd5),
          .rstsel_rndsubload_ab_reg(3'd5), // could be 0
          .rstsel_rndsubload_reg(3'd5),
          .rstsel_accum_ab_reg(3'd5),
          .rstsel_out_reg_00_15((i == K-1)? 3'd5 : 3'd0),
          .rstsel_out_reg_16_31((i == K-1)? 3'd5 : 3'd0),
          .rstsel_out_reg_32_47(3'd0),
          .rstsel_out_reg_48_63(3'd0),
          .rstsel_fp_format_ab_reg(3'd0),
          .rstsel_fp_format_cd_reg(3'd5),
          // placement:
          .location("")
      ) u_acx_mlp72 (
          // MLP:
          .clk(i_clk),
          .din({8'h00, b1, a1, b0, a0}),
          .fwdi_dout(cascade_in),
          .load_ab(1'b0),
          .load(load),
          .sub_ab(1'b0),
          .sub(1'b0),
          .ce({12{Open}}),
          .rstn({4{Open}}),
          .expb({8{Open}}),
          .dout(mlp_dout),
          .fwdo_dout(cascade_out),

          //*** unused pins, to reduce warnings: ***//

          // direct connections from/to ACX_BRAM72K:
          .mlpram_din(/*72*/),                // connect to ACX_BRAM72K:mlpram_din
          .mlpram_we(/*9*/),                  // connect to ACX_BRAM72K:mlpram_we
          .mlpram_dout(/*144*/),              // connect to ACX_BRAM72K:mlpram_dout
          .mlpram_mlp_dout(/*96*/),           // connect to ACX_BRAM72K:mlpram_mlp_dout (MLP result)
          .mlpram_bramdin2mlpdin({72{Open}}), // connect to ACX_BRAM72K:mlpram_din2mlpdin (BRAM din)
          .mlpram_bramdout2mlp({144{Open}}),  // connect to ACX_BRAM72K:mlpram_dout2mlp (BRAM dout)
          .mlpram_din2mlpdout({144{Open}}),   // connect to ACX_BRAM72K:mlpram_din2mlpdout (LRAM din)
          .mlpram_wraddr({6{Open}}),          // connect to ACX_BRAM72K:mlpram_wraddr
          .mlpram_wren(Open),                 // connect to ACX_BRAM72K:mlpram_wren
          .mlpram_rdaddr({6{Open}}),          // connect to ACX_BRAM72K:mlpram_rdaddr
          .mlpram_rden(Open),                 // connect to ACX_BRAM72K:mlpram_rden
          .mlpram_sbit_error(Open),           // connect to ACX_BRAM72K:mlpram_sbit_error
          .mlpram_dbit_error(Open),           // connect to ACX_BRAM72K:mlpram_dbit_error
          // ECC (pass-through from wide ACX_BRAM72K):
          .sbit_error(),
          .dbit_error(),

          // MLP cascade (going up):
          .fwdi_multa_h({72{Open}}),
          .fwdi_multa_l({72{Open}}),
          .fwdi_multb_h({72{Open}}),
          .fwdi_multb_l({72{Open}}),
          .fwdo_multa_h(/*72*/),
          .fwdo_multa_l(/*72*/),
          .fwdo_multb_h(/*72*/),
          .fwdo_multb_l(/*72*/),

          // LRAM FIFO:
          .lram_wrclk(Open),
          .lram_rdclk(Open),
          .empty(),
          .full(),
          .almost_empty(),
          .almost_full(),
          .write_error(),
          .read_error()
      );

      if (i < K-1)
        begin
          reg [K*B*FP-1 : K*B*FP-stage_bits_out] a_reg, b_reg;
          reg load_reg;
          always @(posedge i_clk)
          begin
              a_reg <= a_stage[i][K*B*FP-1 -: stage_bits_out];
              b_reg <= b_stage[i][K*B*FP-1 -: stage_bits_out];
              load_reg <= load_stage[i];
          end
          assign a_stage[i+1][K*B*FP-1 -: stage_bits_out] = a_reg;
          assign b_stage[i+1][K*B*FP-1 -: stage_bits_out] = b_reg;
          assign load_stage[i+1] = load_reg;
          assign dout_stage[i] = cascade_out[FP24 +: FP24]; // ab
        end
      else
          assign dout_stage[i] = mlp_dout[0 +: FP24]; // cd

    end // for (genvar i)

endmodule : mlp_stack


