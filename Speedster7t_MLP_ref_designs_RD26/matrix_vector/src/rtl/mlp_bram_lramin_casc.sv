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
//  Description: MLP stack configured as 16 int8xint8. Inputs from BRAM
//               (direct) and LRAM, output to dout cascade.
//               LRAM is written via MLP cascade, in wide mode.
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1 ps / 1 ps

module mlp_bram_lramin_casc #(
    parameter  integer M = 6,     // number MLPs
    localparam integer N = 8,     // integer size
    localparam integer B = 16,    // block size (number parallel multiplies)
    localparam integer W = 128,   // LRAM write width
    localparam integer R = 128,   // BRAM read width to MLP
    localparam integer S = 48     // bits in result
) (
    input  wire              i_clk,
    // LRAM write
    input  wire [W/2-1 : 0]  i_wrdata,
    input  wire [W/2-1 : 0]  i_bram_din2mlp_din, // borrowed bram din -> mlp
    input  wire              i_first, // first wrdata
    input  wire              i_last,  // last wrdata
    input  wire              i_pause, // ignore i_v
    // BRAM data
    input  wire [M*R-1 : 0]  i_bram_dout2mlp_din, // parallel, direct connect
    // Computation
    input  wire              i_read,     // generate LRAM addresses
    output wire [S-1 : 0]    o_sum,      // output vector item (2's compl)
    output wire              o_valid     // o_sum is valid
);

  localparam integer A = 4; // LRAM address width in 144-bit mode
  // Since V/B = 12, and 12/M = 2, we only need to write two entries per
  // LRAM, so one address bit is enough.
  localparam integer Alram = 1; // effective address width

  wire [71:0] fwdi_multb_h[M : 0];
  wire [71:0] fwdi_multb_l[M : 0];
  wire [47:0] fwdi_dout[M : 0];

  wire [M-1 : 0] wr_active;
  wire [M-1 : 0] wr_pause;
  wire [M-1 : 0] reading;
  assign reading[0] = i_read;

  wire Open;
  ACX_FLOAT undriven(Open);

  assign fwdi_multb_h[0] = {72 {Open}}; // avoid warning
  assign fwdi_multb_l[0] = {72 {Open}}; // avoid warning
  assign fwdi_dout[0]    = {48 {Open}}; // avoid warning


  for (genvar i = 0; i < M; i = i + 1)
    begin: mlp_stage
      localparam bit [1:0] mux_sel_multb_l = (i == 0)? 2'b00 : 2'b11;
      localparam bit [2:0] mux_sel_multb_h = (i == 0)? 3'b001 : 3'b111;
      localparam bit       add_accum_ab_bypass = (i == 0)? 1'b1 : 1'b0;
      localparam bit       add_accum_cd_bypass = (i == M-1)? 1'b0 : 1'b1;

      wire [W/2-1 : 0] wrdata_lo = (i == 0)? i_wrdata : {W/2 {Open}};
      wire [W/2-1 : 0] wrdata_hi = (i == 0)? i_bram_din2mlp_din : {W/2 {Open}};
      wire [143 : 0] bram_dout2mlp_din;

      assign bram_dout2mlp_din[71 : 0] = { {72-R/2 {Open}}, i_bram_dout2mlp_din[i*R +: R/2] };
      assign bram_dout2mlp_din[143 : 72] = { {72-R/2 {Open}}, i_bram_dout2mlp_din[i*R+R/2 +: R/2] };


      wire          load;
      wire [71 : 0] mlp_out;
      if (i == M-1)
          assign o_sum = mlp_out[0 +: S];

      wire [A-1 : 0] lram_wraddr;
      wire [A-1 : 0] lram_rdaddr;
      wire           lram_wren;

      wire [11:0] ce;
      wire [7:0] expb;
      assign ce[7] = lram_wren;
      assign ce[6] = 1'b1; // lram_rden
      assign expb[7:2] = {lram_wraddr, 2'b00}; // [1:0]=00 for 144-bit mode
      assign { expb[1:0], ce[11:8] } = {lram_rdaddr, 2'b00};
      assign ce[5:0] = Open;


      ACX_MLP72 #(
          /***** data flow *************************************************/
          // input selection:
          .mux_sel_multa_l(2'b10),       // input 'a_l' from BRAM[71:0]
          .mux_sel_multa_h(3'b101),      // input 'a_h' from BRAM[143:72]
          .mux_sel_multb_l(mux_sel_multb_l),  // input 'b_l' to LRAM
          .mux_sel_multb_h(mux_sel_multb_h),  // input 'b_h' to LRAM
          // input format:
          .bytesel_00_07(5'h01),         // int8_4x
          .bytesel_08_15(6'h21),         // int8_4x
          // multiplier operation:
          .multmode_00_07(5'h0),         // int8, 2's complement
          .multmode_08_15(5'h0),         // int8, 2's complement
          // adder tree:
          .add_00_07_bypass(1'b0),       // use mult 0..7
          .add_08_15_bypass(1'b0),       // use mult 8..15
          .add_00_15_sel(1'b1),          // use mult 0..15 (add both halves)
          // floating point:
          .fpmult_ab_bypass(1'b1),       // integer mode
          .fpmult_cd_bypass(1'b1),       // integer mode
          // accumulator:
          .fpadd_ab_dinb_sel(3'b001),    // fwdi_dout
          .fpadd_cd_dina_sel(1'b1),      // add_ab
          .fpadd_cd_dinb_sel(3'b000),    // accumulator mode
          .add_accum_ab_bypass(add_accum_ab_bypass), // bypass for MLP[0]
          .add_accum_cd_bypass(add_accum_cd_bypass), // bypass all but MLP[M-1]
          // output:
          .accum_ab_reg_din_sel(1'b0),   // integer mode
          .out_reg_din_sel(3'b011),      // use add_cd
          .dout_mlp_sel(2'b00),          // result/fwdo_dout = cd register
          .outmode_sel(2'b00),           // output = MLP result

          /***** registers *************************************************/
          // stage 0 registers:
          .del_multa_l(1'b1),            // enable stage0 register
          .del_multa_h(1'b1),            // enable stage0 register
          .del_multb_l(1'b1),            // enable stage0 register
          .del_multb_h(1'b1),            // enable stage0 register
          // stage 1 registers:
          // stage1 register for 'b' (from LRAM), to match delay of BRAM
          .del_mult00a(1'b0),
          .del_mult00b(1'b1),            // enable stage1 register
          .del_mult01a(1'b0),
          .del_mult01b(1'b1),            // enable stage1 register
          .del_mult02a(1'b0),
          .del_mult02b(1'b1),            // enable stage1 register
          .del_mult03a(1'b0),
          .del_mult03b(1'b1),            // enable stage1 register
          .del_mult04_07a(1'b0),
          .del_mult04_07b(1'b1),         // enable stage1 register
          .del_mult08_11a(1'b0),
          .del_mult08_11b(1'b1),         // enable stage1 register
          .del_mult12_15a(1'b0),
          .del_mult12_15b(1'b1),         // enable stage1 register
          // stage 2 registers:
          .del_add_00_07_reg(1'b1),      // enable stage2 reg 
          .del_add_08_15_reg(1'b1),      // enable stage2 reg 
          // delay match registers for stage0..3/4 (for int and fp sub/load):
          .del_rndsubload_ab_reg(3'd2),  // a: stage0 + stage2; or b: stage1 + stage2
          .del_rndsubload_reg(3'd2),     // a: stage0 + stage2; or b: stage1 + stage2
          // stage 4 registers:
          .del_accum_ab_reg(1'b0),
          .del_out_reg_00_15(1'b1),      // use cd register (accumulator/output)
          .del_out_reg_16_31(1'b1),      // use cd register (accumulator/output)
          .del_out_reg_32_47(1'b1),      // use cd register (accumulator/output)
          .del_out_reg_48_63(1'b0),      // unused bits

          // cesel for each register (use 4'd13 to tie high):
          // (to save power, leave at 0 for unused registers)
          .cesel_multa_l(4'd13),         // no ce
          .cesel_multa_h(4'd13),         // no ce
          .cesel_multb_l(4'd13),         // no ce
          .cesel_multb_h(4'd13),         // no ce
          .cesel_mult00b(4'd13),         // no ce
          .cesel_mult01b(4'd13),         // no ce
          .cesel_mult02b(4'd13),         // no ce
          .cesel_mult03b(4'd13),         // no ce
          .cesel_mult04_07b(4'd13),      // no ce
          .cesel_mult08_11b(4'd13),      // no ce
          .cesel_mult12_15b(4'd13),      // no ce
          .cesel_add_00_07_reg(4'd13),   // no ce
          .cesel_add_08_15_reg(4'd13),   // no ce
          .cesel_rndsubload_ab_reg(0),   // load=0, sub=0
          .cesel_rndsubload_reg(4'd13),  // no ce
          .cesel_out_reg_00_15(4'd13),   // no ce
          .cesel_out_reg_16_31(4'd13),   // no ce
          .cesel_out_reg_32_47(4'd13),   // no ce
          // rstsel for each register (use 3'd5 to tie high):
          // (to save power, leave at 0 for unused registers)
          .rstsel_multa_l(3'd5),         // no rstn
          .rstsel_multa_h(3'd5),         // no rstn
          .rstsel_multb_l(3'd5),         // no rstn
          .rstsel_multb_h(3'd5),         // no rstn
          .rstsel_mult00b(3'd5),         // no rstn
          .rstsel_mult01b(3'd5),         // no rstn
          .rstsel_mult02b(3'd5),         // no rstn
          .rstsel_mult03b(3'd5),         // no rstn
          .rstsel_mult04_07b(3'd5),      // no rstn
          .rstsel_mult08_11b(3'd5),      // no rstn
          .rstsel_mult12_15b(3'd5),      // no rstn
          .rstsel_add_00_07_reg(3'd5),   // no rstn
          .rstsel_add_08_15_reg(3'd5),   // no rstn
          .rstsel_rndsubload_ab_reg(0),  // load=0, sub=0
          .rstsel_rndsubload_reg(3'd5),  // no rstn
          .rstsel_out_reg_00_15(3'd5),   // no rstn
          .rstsel_out_reg_16_31(3'd5),   // no rstn
          .rstsel_out_reg_32_47(3'd5),   // no rstn

          /***** LRAM ****************************************************/
          // LRAM clock:
          .lram_clk_sel_wr(1'b1),        // use mlp clk
          .lram_clk_sel_rd(1'b1),        // use mlp clk
          .lram_sync_mode(1'b1),         // rdclk = wrclk
          // LRAM read/write:
          .lram_write_width(2'b10),      // 144 wide
          .lram_read_width(2'b10),       // 144 wide
          .lram_write_data_mode(2'b11),  // LRAM uses multb_h/l
          .lram_input_control_mode(2'b01), // wraddr and wren from fabric
          .lram_output_control_mode(2'b01), // rdaddr from fabric
          // LRAM output:
          .lram_reg_dout(1'b0),          // no read reg
          .lram_out2multb_l(1'b1),       // MLP uses LRAM for b_l
          .lram_out2multb_h(1'b1)        // MLP uses LRAM for b_h
      ) u_mlp (
          .clk(i_clk),
          .lram_wrclk(Open),
          .lram_rdclk(Open),
          .din({ {72-W/2 {Open}}, wrdata_lo }),
          .mlpram_bramdout2mlp(bram_dout2mlp_din),   // BRAM data
          .mlpram_bramdin2mlpdin({ {72-W/2 {Open}}, wrdata_hi }),
          .sub(1'b0),
          .load(load),
          .dout(mlp_out),
          .ce(ce),
          .expb(expb),
          // wrdata cascade
          .fwdi_multb_h(fwdi_multb_h[i]),
          .fwdi_multb_l(fwdi_multb_l[i]),
          .fwdo_multb_h(fwdi_multb_h[i+1]),
          .fwdo_multb_l(fwdi_multb_l[i+1]),
          // dout cascade
          .fwdi_dout(fwdi_dout[i]),
          .fwdo_dout(fwdi_dout[i+1]),
          // unused pins
          .sub_ab(Open),
          .load_ab(Open),
          .rstn({4{Open}}),
          .fwdi_multa_h({72{Open}}),
          .fwdi_multa_l({72{Open}}),
          .mlpram_din2mlpdout({144{Open}}),
          .mlpram_rdaddr({6{Open}}),
          .mlpram_wraddr({6{Open}}),
          .mlpram_dbit_error(Open),
          .mlpram_rden(Open),
          .mlpram_sbit_error(Open),
          .mlpram_wren(Open),
          .empty(),
          .full(),
          .almost_empty(),
          .almost_full(),
          .sbit_error(),
          .dbit_error(),
          .write_error(),
          .read_error(),
          .fwdo_multa_h(),
          .fwdo_multa_l(),
          .mlpram_din(),
          .mlpram_dout(),
          .mlpram_we(),
          .mlpram_mlp_dout()
      );


      /********** LRAM write logic *******************************************/

      wire [Alram-1 : 0] lram_wraddr_effective;
      lram_wr_ctrl #(
          .M(M),
          .id(i),
          .A(Alram)
      ) u_lram_wr_ctrl (
          .i_clk(i_clk),
          .i_active(wr_active[i]),
          .i_pause(wr_pause[i]),
          .o_wren(lram_wren),
          .o_wraddr(lram_wraddr_effective)
      );
      assign lram_wraddr = { {A-Alram {1'b0}}, lram_wraddr_effective };

      reg wr_ongoing = 1'b0;
      
      // Note: i_first arrives actually one cycle before the first data,
      // because the data goes through a stage0 register. So wr_active[i]
      // also arrives one cycle before the data at LRAM[i]. That works out
      // well, because that extra cycle allows wren to be registered.
      if (i == 0)
        begin
          always @(posedge i_clk)
          begin
              if (i_last)
                  wr_ongoing <= 1'b0;
              else if (i_first)
                  wr_ongoing <= 1'b1;
          end
          assign wr_active[0] = wr_ongoing || i_first;
          assign wr_pause[0] = i_pause;
        end
      else
        begin
          reg pause_reg;
          always @(posedge i_clk)
          begin
              wr_ongoing <= wr_active[i-1];
              pause_reg <= wr_pause[i-1];
          end
          assign wr_active[i] = wr_ongoing;
          assign wr_pause[i] = pause_reg;
        end


      /********** LRAM read logic, MLP computation ***************************/

      if (i > 0)
        begin
          reg mlp_reading = 1'b0;
          always @(posedge i_clk)
          begin
              mlp_reading <= reading[i-1];
          end
          assign reading[i] = mlp_reading;
        end

      (* syn_allow_retiming=0 *) reg [Alram-1 : 0] lram_rdaddr_effective;
      always @(posedge i_clk)
      begin
          if (!reading[i])
              lram_rdaddr_effective <= '0;
          else
              lram_rdaddr_effective <= lram_rdaddr_effective + 1'b1;
      end
      assign lram_rdaddr = { {A-Alram {1'b0}}, lram_rdaddr_effective };
      
      if (i == M-1)
        begin
          assign load = (lram_rdaddr_effective == '0);

          reg [2:0] valid;
          wire mlp_valid = (lram_rdaddr_effective == '1);
          always @(posedge i_clk)
          begin
              valid <= {valid[1:0], mlp_valid};
          end
          assign o_valid = valid[2];
        end
      else
          assign load = 1'b0;


    end // for (genvar i)



endmodule : mlp_bram_lramin_casc

