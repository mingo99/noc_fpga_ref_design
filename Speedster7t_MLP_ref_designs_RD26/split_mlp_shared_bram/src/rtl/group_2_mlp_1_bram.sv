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
//  Description: Group of 2 MLPs driven by a single BRAM
//
// ----------------------------------------------------------------------

`timescale 1 ps / 1 ps

`include "ram_width_encoding.sv"

module group_2_mlp_1_bram #(
    parameter  bit bottom_group = 0,      // set for bottom group in stack
    parameter  integer bram_wr_width = 128,   // 64, 72, 128, 144
    parameter  integer bram_wraddr_width = (bram_wr_width > 72)? 9 : 10,
    localparam integer bram_byte_width = 8,
    localparam integer bram_we_width = bram_wr_width / bram_byte_width,
    localparam integer bram_rd_width = 144,
    localparam integer bram_rdaddr_width = 9,
    localparam integer mlp_data_width = 144,
    parameter  integer mlp_dout_width = 48,   // or 24 for fp
    parameter  integer lram_fifo_afull_threshold = 7'h1,
    parameter  integer lram_fifo_aempty_threshold = 7'h2,
    parameter  mlp0_location = "", // placement of bottom MLP of the group
    localparam B_width = 72, // regular BRAM width
    localparam M_width = 72  // regular MLP/LRAM width
) (
    // shared clock
    input  wire                           i_clk,
    // bram write
    input  wire [bram_wr_width-1 : 0]     i_bram_din,
    input  wire [bram_wraddr_width-1 : 0] i_bram_wraddr,
    input  wire                           i_bram_wrmsel,
    input  wire                           i_bram_wren,
    input  wire [bram_we_width-1 : 0]     i_bram_we,
    // bram read (data passed to MLPs)
    input  wire [bram_rdaddr_width-1 : 0] i_bram_rdaddr,
    // MLP cascade:
    input  wire [2*M_width-1 : 0]         i_fwdi_multa, // from group below (if !bottom_group)
    output wire [2*M_width-1 : 0]         o_fwdo_multa, // to group above
    // input of external BRAM, if bottom_group=1:
    input  wire [mlp_data_width-1 : 0]    i_bottom_bram_dout2mlp_din,
    // control
    input  wire                           i_first,  // first fwdi data (start accumulation)
    input  wire                           i_pause,  // ignore fwdi data (pause accumulation)
    input  wire                           i_last,   // last fwdi data (accumulation complete)
    // results
    input  wire                           i_result_rden,
    input  wire                           i_result_rstn, // reset FIFO
    output wire                           o_empty,  // from MLP0 LRAM_FIFO
    output wire                           o_full,
    output wire                           o_almost_empty,
    output wire                           o_almost_full,
    output wire [mlp_dout_width-1 : 0]    o_result_1,  // from MLP1
    output wire                           o_result_1_valid,
    output wire [mlp_dout_width-1 : 0]    o_result_0,  // from MLP0
    output wire                           o_result_0_valid
);


  /****************************************************************************/

  // force pin to remain unconnected rather than tied off
  wire Open;
  ACX_FLOAT undriven(Open);


  /********** BRAM ************************************************************/

  localparam B_we_width = 9; // we input width
  localparam B_addr_width = 10; // addr width

  // direct connections between BRAM and MLP (only the used connections are
  // made, though it would be harmless to make all such connections):
  wire [71:0]  mlpram1_din;            // from MLP:din, for wide BRAM
  wire [8:0]   mlpram1_we;             // from MLP inputs, for wide BRAM
  wire [143:0] mlpram1_dout;           // from LRAM:dout, for wide LRAM or read via BRAM
  wire [143:0] mlpram1_bramdout2mlp;   // from BRAM:dout to MLP:din

  // BRAM write:
  wire [B_width-1 : 0] bram_din;
  wire [B_width-1 : 0] mlp1_din;
  wire [2*B_we_width-1 : 0] bram_we;
  wire [B_addr_width-1 : 0] bram_wraddr;

  if (bram_wr_width <= 72) begin
      assign bram_din = { {B_width-bram_wr_width{1'b0}}, i_bram_din[bram_wr_width-1 : 0] };
      assign mlp1_din = {B_width{Open}};
      assign bram_we = { {18-bram_we_width{1'b0}}, i_bram_we };
  end else begin
      localparam bram_wr_half_width = bram_wr_width / 2;
      localparam bram_we_half_width = bram_we_width / 2;
      assign bram_din = { {B_width-bram_wr_half_width{1'b0}}, i_bram_din[bram_wr_half_width-1 : 0] };
      assign mlp1_din = { {B_width-bram_wr_half_width{1'b0}}, i_bram_din[bram_wr_width-1 : bram_wr_half_width] };
      assign bram_we[0 +: B_we_width] = { {B_we_width-bram_we_half_width{1'b0}}, i_bram_we[0 +: bram_we_half_width] };
      assign bram_we[9 +: B_we_width] = { {B_we_width-bram_we_half_width{1'b0}}, i_bram_we[bram_we_half_width +: bram_we_half_width] };
  end

  assign bram_wraddr = { i_bram_wraddr, {B_addr_width-bram_wraddr_width{1'b0}} };

  // BRAM read:
  wire                      bram_rd_lram_fifo; // read LRAM instead of BRAM
  wire [B_addr_width-1 : 0] bram_rdaddr;
  wire [B_addr_width-1 : 0] bram_rdaddr_mapped;
  wire                      bram_rdmsel;
  wire [2*B_width-1 : 0]    bram_dout;

  assign bram_rdaddr = { i_bram_rdaddr, {B_addr_width-bram_rdaddr_width{1'b0}} };
  // to read LRAM, assert rdmsel and rdaddr[7]:
  assign bram_rdmsel = bram_rd_lram_fifo;
  assign bram_rdaddr_mapped = bram_rdaddr | (bram_rd_lram_fifo << 7);

  localparam bram_rd_latency = 2; // including outreg

  ACX_BRAM72K #(
      // clock:
      .clk_sel_rd(2'b10), // use mlpclk for read
      // read/write:
      .write_width(ACX_bram72k_width_code(bram_wr_width, bram_byte_width)), // encoded
      .read_width(ACX_bram72k_width_code(bram_rd_width, bram_byte_width)),  // encoded
      .enable_wide_fabric_input(bram_wr_width > 72),
      .wrmem_input_sel(4'h0), // single BRAM
      .rdmem_input_sel(4'h0), // single BRAM
      .outreg_enable(1'b1),      
      .outreg_sr_assertion(1'b0),
      .enable_lram_read(1'b1),
      // input register:
      .del_fwdi_ram_wr_addr(1'b0),
      .del_fwdi_ram_wr_data(1'b0),
      .del_fwdi_ram_rd_addr(1'b0),
      .ce_fwdi_ram_wr_addr(1'b0),
      .ce_fwdi_ram_rd_addr(1'b0),
      // memory initialization:
      .mem_init_file("")
      // .initd_0(72'hx), // init per address 0..1023
      //  ...
      // .initd_1023(72'hx),
      // placement:
      // .location("")
  ) u_acx_bram72k_b (
      // write port:
      .din(bram_din),
      .wrmsel(i_bram_wrmsel),  
      .wraddrhi(bram_wraddr),
      .we(bram_we[8:0]),
      .wren(i_bram_wren),
      .wrclk(i_clk),

      // read port:
      .rdmsel(bram_rdmsel),
      .rdaddrhi(bram_rdaddr_mapped),
      .rden(1'b1),
      .rdclk(Open), // uses mlpclk instead
      .outreg_rstn(1'b1),
      .outlatch_rstn(1'b1),
      .outreg_ce(1'b1),
      .dout(bram_dout[0 +: B_width]),

      // direct connections from/to ACX_MLP72:
      .mlpclk(i_clk),               // connect to same driver as ACX_MLP72:clk
      .mlpram_din(mlpram1_din),      // connect to ACX_MLP72:mlpram_din
      .mlpram_we(mlpram1_we),        // connect to ACX_MLP72:mlpram_we
      .mlpram_dout(mlpram1_dout),    // connect to ACX_MLP72:mlpram_dout (LRAM output)
      .mlpram_mlp_dout({96{Open}}), // connect to ACX_MLP72:mlpram_mlp_dout (MLP result)
      .mlpram_din2mlpdin(/*72*/),   // connect to ACX_MLP72:mlpram_bramdin2mlpdin (BRAM din)
      .mlpram_dout2mlp(mlpram1_bramdout2mlp), // connect to ACX_MLP72:mlpram_bramdout2mlp (BRAM dout)
      .mlpram_din2mlpdout(/*144*/), // connect to ACX_MLP72:mlpram_din2mlpdout (LRAM din)
      .mlpram_wraddr(/*6*/),        // connect to ACX_MLP72:mlpram_wraddr
      .mlpram_wren(),               // connect to ACX_MLP72:mlpram_wren
      .mlpram_rdaddr(/*6*/),        // connect to ACX_MLP72:mlpram_rdaddr
      .mlpram_rden(),               // connect to ACX_MLP72:mlpram_rden
      .mlpram_sbit_error(),         // connect to ACX_MLP72:mlpram_sbit_error
      .mlpram_dbit_error(),         // connect to ACX_MLP72:mlpram_dbit_error

      // block address .
      .revi_wblk_addr({7{Open}}),   // from ACX_BRAM72K above
      .revi_rblk_addr({7{Open}}),   // from ACX_BRAM72K above
      .revo_wblk_addr(/*7*/),       // to ACX_BRAM72K below
      .revo_rblk_addr(/*7*/),       // to ACX_BRAM72K below

      // BRAM cascade (going up):
      .fwdi_ram_wr_addr({14{Open}}),
      .fwdi_ram_wblk_addr({7{Open}}),
      .fwdi_ram_wren(Open),
      .fwdi_ram_we({18{Open}}),
      .fwdi_ram_wrmsel(Open),
      .fwdi_ram_wr_data({144{Open}}),
      .fwdi_ram_rd_addr({14{Open}}),
      .fwdi_ram_rblk_addr({7{Open}}),
      .fwdi_ram_rden(Open),
      .fwdi_ram_rdmsel(Open),
      .fwdo_ram_wr_addr(/*14*/),
      .fwdo_ram_wblk_addr(/*7*/),
      .fwdo_ram_wren(),
      .fwdo_ram_we(/*18*/),
      .fwdo_ram_wrmsel(),
      .fwdo_ram_wr_data(/*144*/),
      .fwdo_ram_rd_addr(/*14*/),
      .fwdo_ram_rblk_addr(/*7*/),
      .fwdo_ram_rden(),
      .fwdo_ram_rdmsel(),

      // BRAM reverse cascade (going down):
      .revi_ram_rd_addr({14{Open}}),
      .revi_ram_rblk_addr({7{Open}}),
      .revi_ram_rden(Open),
      .revi_ram_rd_data({144{Open}}),
      .revi_ram_rdval(Open),
      .revi_ram_rdmsel(Open),
      .revo_ram_rd_addr(/*14*/),
      .revo_ram_rblk_addr(/*7*/),
      .revo_ram_rden(),
      .revo_ram_rd_data(/*144*/),
      .revo_ram_rdval(),
      .revo_ram_rdmsel(),

      // BRAM FIFO:
      .full(),
      .almost_full(),
      .empty(),
      .almost_empty(),
      .write_error(),
      .read_error(),

      // ECC (error correction):
      .sbit_error(),
      .dbit_error()
  );


  /********** MLP1 (top) ******************************************************/

  // MLP configuration:
  localparam bit [5:0] bytesel = 'h21;           // int8_4x
  localparam bit [4:0] multmode = 'h00;          // signed 8x8
  localparam bit       int_mode = 1;             // 0=fp/blockfp, 1=int
  localparam bit       blockfp = 0;              // 0=fp, 1=blockfp
  localparam bit [2:0] blockfp_mode = 3'b000;    // int8
  localparam bit       exp_size = 0;             // 0: 8 bits, 1: 5 bits
  localparam bit [1:0] fp_output_format = 2'b00; // 0=fp24 (only 0 for write to LRAM)

  localparam integer lram_wr_width = int_mode? 2*M_width : M_width; // both results
  localparam integer lram_rd_width = lram_wr_width / 2; // one result

  // register stages before accumulator ('a' input):
  localparam integer mlp_load_latency = int_mode? 3 /* s0,1,2 */ : 4 /* +s2.5 */;

  // MLP and FIFO control:
  wire [11:0] mlp1_ce;
  wire [3:0]  mlp1_rstn;
  wire        mlp1_load;
  wire        mlp1_accum_ce;
  wire        lram1_wren;
  wire        lram1_rden;
  wire        lram1_fifo_rstn;

  // cascade
  wire [M_width-1 : 0] fwdi_multa_h_0_to_1;
  wire [M_width-1 : 0] fwdi_multa_l_0_to_1;

  assign mlp1_ce[0] = 1'b1;          // ce for LRAM output reg 
  assign mlp1_ce[1] = mlp1_accum_ce; // ce for accumulator registers
  assign mlp1_ce[5:2] = 4'b0;        // unused
  assign mlp1_ce[6] = lram1_rden;
  assign mlp1_ce[7] = lram1_wren;
  assign mlp1_ce[11:8] = 4'b0;       // unused
  assign mlp1_rstn[0] = 1'b1;        // LRAM output reg
  assign mlp1_rstn[1] = lram1_fifo_rstn; // LRAM rd/wr pointers
  assign mlp1_rstn[3:2] = 2'b0;      // unused

  ACX_MLP72 #(
      // input selection:
      .mux_sel_multa_h(3'b111), // fwdi[143:72]
      .mux_sel_multa_l(2'b11),  // fwdi[71:0]
      .mux_sel_multb_h(3'b100), // bram[71:0]
      .mux_sel_multb_l(2'b10),  // bram[71:0]
      // input format:
      .bytesel_00_07(bytesel[4:0]),
      .bytesel_08_15(bytesel),
      // multiplier operation:
      .multmode_00_07(multmode),
      .multmode_08_15(multmode),
      // adder tree:
      .add_00_07_bypass(1'b0),
      .add_00_07_sub(1'b0),
      .add_08_15_bypass(1'b0),
      .add_08_15_sub(1'b0),
      .add_00_15_sel(1'b0),  // do not add upper to lower half
      // floating point:
      .fpadd_abcd_sel(1'b0), // do not add upper to lower half
      .fpmult_ab_bypass(int_mode),
      .fpmult_ab_blockfp(blockfp),
      .fpmult_ab_blockfp_mode(blockfp_mode),
      .fpmult_ab_exp_size(exp_size),
      .fpmult_cd_bypass(int_mode),
      .fpmult_cd_blockfp(blockfp),
      .fpmult_cd_blockfp_mode(blockfp_mode),
      .fpmult_cd_exp_size(exp_size),
      // accumulator:
      .fpadd_ab_dinb_sel(3'b000), // accumulator feedback (applies to int and fp)
      .fpadd_cd_dina_sel(1'b0), // from cd mult (applies to int and fp)
      .fpadd_cd_dinb_sel(3'b000), // accumulator feedback (applies to int and fp)
      .add_accum_ab_bypass(1'b0), // use accumulator
      .add_accum_cd_bypass(1'b0), // use accumulator
      .rndsubload_share(1'b1),  // use cd 'load' instead of load_ab
      // output:
      .accum_ab_reg_din_sel(!int_mode), // (applies to int and fp)
      .out_reg_din_sel(int_mode? 3'b011 : 3'b010), // (applies to int and fp)
      .fpadd_ab_output_format(fp_output_format),
      .fpadd_cd_output_format(fp_output_format),
      .dout_mlp_sel(2'b00), // not used: MLP output is to LRAM
      .outmode_sel(2'b10), // dout = BRAM:dout[143:72]
      // stage 0 registers:
      .del_multa_h(1'b1), // pipeline reg of cascade (for speed)
      .del_multa_l(1'b1), // pipeline reg of cascade (for speed)
      .del_multb_h(1'b1), // match a_h delay
      .del_multb_l(1'b1), // match a_l delay
      .del_expb_din_reg(1'b0),
      // stage 1 registers:
      .del_mult00a(1'b1), // enable stage 1 (input) registers, for speed
      .del_mult00b(1'b1),
      .del_mult01a(1'b1),
      .del_mult01b(1'b1),
      .del_mult02a(1'b1),
      .del_mult02b(1'b1),
      .del_mult03a(1'b1),
      .del_mult03b(1'b1),
      .del_mult04_07a(1'b1),
      .del_mult04_07b(1'b1),
      .del_mult08_11a(1'b1),
      .del_mult08_11b(1'b1),
      .del_mult12_15a(1'b1),
      .del_mult12_15b(1'b1),
      // stage 2 registers:
      .del_add_00_07_reg(1'b1), // enable s2 for speed
      .del_add_08_15_reg(1'b1),
      // delay match registers for stage1..2 (for fp exp/sign):
      .del_expa_reg(int_mode? 2'd0 : 2'd2), // 0..2
      .del_expb_reg(int_mode? 2'd0 : 2'd2), // 0..2
      .del_expc_reg(int_mode? 2'd0 : 2'd2), // 0..2
      .del_expd_reg(int_mode? 2'd0 : 2'd2), // 0..2
      // fp registers (stage 2.5 and stage 3):
      .del_fpmult_ab_pipe_reg(!int_mode),
      .del_fpmult_cd_pipe_reg(!int_mode),
      .del_fpmult_ab_reg(1'b0), // typically only used if fpadd_abcd_sel=1
      // delay match registers for stage0..3/4 (for int and fp sub/load):
      .del_rndsubload_ab_reg(3'd0), // use load (shared) instead of load_ab
      .del_rndsubload_reg(mlp_load_latency), // 0..6
      // stage 4 registers:
      .del_accum_ab_reg(1'b1), // output reg, for speed
      .del_out_reg_00_15(1'b1),
      .del_out_reg_16_31(1'b1),
      .del_out_reg_32_47(int_mode),
      .del_out_reg_48_63(1'b0),
      .del_fp_format_ab_reg(1'b0), // not used when writing to LRAM
      .del_fp_format_cd_reg(1'b0),
      // cesel for each register (use 4'd13 for tie high):
      .cesel_multa_h(4'd13),
      .cesel_multa_l(4'd13),
      .cesel_multb_h(4'd13),
      .cesel_multb_l(4'd13),
      .cesel_expb_din_reg(4'd0),
      .cesel_mult00a(4'd13),
      .cesel_mult00b(4'd13),
      .cesel_mult01a(4'd13),
      .cesel_mult01b(4'd13),
      .cesel_mult02a(4'd13),
      .cesel_mult02b(4'd13),
      .cesel_mult03a(4'd13),
      .cesel_mult03b(4'd13),
      .cesel_mult04_07a(4'd13),
      .cesel_mult04_07b(4'd13),
      .cesel_mult08_11a(4'd13),
      .cesel_mult08_11b(4'd13),
      .cesel_mult12_15a(4'd13),
      .cesel_mult12_15b(4'd13),
      .cesel_add_00_07_reg(4'd13),    
      .cesel_add_08_15_reg(4'd13),    
      .cesel_expta_reg(int_mode? 4'd0 : 4'd13),
      .cesel_exptb_reg(int_mode? 4'd0 : 4'd13),
      .cesel_exptc_reg(int_mode? 4'd0 : 4'd13),
      .cesel_exptd_reg(int_mode? 4'd0 : 4'd13),
      .cesel_fpmult_ab_pipe_reg(int_mode? 4'd0 : 4'd13),
      .cesel_fpmult_cd_pipe_reg(int_mode? 4'd0 : 4'd13),
      .cesel_fpmult_ab_reg(4'd0),
      .cesel_rndsubload_ab_reg(4'd0),
      .cesel_rndsubload_reg(4'd13),
      .cesel_accum_ab_reg(4'd2),  // accum_ab feedback, use ce[1]
      .cesel_out_reg_00_15(4'd2), // accum_cd feedback, use ce[1]
      .cesel_out_reg_16_31(4'd2), // accum_cd feedback, use ce[1]
      .cesel_out_reg_32_47(int_mode? 4'd2 : 4'd0),
      .cesel_out_reg_48_63(4'd0),
      .cesel_fp_format_ab_reg(4'd0),
      .cesel_fp_format_cd_reg(4'd0),
      // rstsel for each register (use 3'd5 for tie high):
      .rstsel_multa_h(3'd5),
      .rstsel_multa_l(3'd5),
      .rstsel_multb_h(3'd5),
      .rstsel_multb_l(3'd5),
      .rstsel_expb_din_reg(3'd0),
      .rstsel_mult00a(3'd5), // use rstn[0]
      .rstsel_mult00b(3'd5),
      .rstsel_mult01a(3'd5),
      .rstsel_mult01b(3'd5),
      .rstsel_mult02a(3'd5),
      .rstsel_mult02b(3'd5),
      .rstsel_mult03a(3'd5),
      .rstsel_mult03b(3'd5),
      .rstsel_mult04_07a(3'd5),
      .rstsel_mult04_07b(3'd5),
      .rstsel_mult08_11a(3'd5),
      .rstsel_mult08_11b(3'd5),
      .rstsel_mult12_15a(3'd5),
      .rstsel_mult12_15b(3'd5),
      .rstsel_add_00_07_reg(3'd5), 
      .rstsel_add_08_15_reg(3'd5), 
      .rstsel_expta_reg(int_mode? 3'd0 : 3'd5),
      .rstsel_exptb_reg(int_mode? 3'd0 : 3'd5),
      .rstsel_exptc_reg(int_mode? 3'd0 : 3'd5),
      .rstsel_exptd_reg(int_mode? 3'd0 : 3'd5),
      .rstsel_fpmult_ab_pipe_reg(int_mode? 3'd0 : 3'd5),
      .rstsel_fpmult_cd_pipe_reg(int_mode? 3'd0 : 3'd5),
      .rstsel_fpmult_ab_reg(3'd0),
      .rstsel_rndsubload_ab_reg(3'd0),
      .rstsel_rndsubload_reg(3'd5),
      .rstsel_accum_ab_reg(3'd5),
      .rstsel_out_reg_00_15(3'd5),
      .rstsel_out_reg_16_31(3'd5),
      .rstsel_out_reg_32_47(int_mode? 3'd5 : 3'd0),
      .rstsel_out_reg_48_63(3'd0),
      .rstsel_fp_format_ab_reg(3'd0),
      .rstsel_fp_format_cd_reg(3'd0),
      // LRAM clock:
      .lram_clk_sel_wr(1'b1), // use mlp_clk
      .lram_clk_sel_rd(1'b1), // use mlp_clk
      .lram_sync_mode(1'b1),  // wr_clk = rd_clk
      // LRAM read/write:
      .lram_write_width(ACX_lram2k_width_code(lram_wr_width)),
      .lram_read_width(ACX_lram2k_width_code(lram_rd_width)),
      .lram_accum_data_input_sel(!int_mode),
      .lram_write_data_mode(2'b10), // din from MLP
      .lram_input_control_mode(2'b10), // FIFO mode
      .lram_output_control_mode(2'b10), // FIFO mode
      // LRAM output:
      .lram_reg_dout(1'b1), // required for read via BRAM
      // LRAM FIFO mode:
      .lram_fifo_enable(1'b1),
      .lram_fifo_wrptr_maxval(7'h7F), // FIFO mode
      .lram_fifo_rdptr_maxval(7'h7F), // FIFO mode
      .lram_fifo_sync_mode(1'b1),
      .lram_fifo_afull_threshold(lram_fifo_afull_threshold),
      .lram_fifo_aempty_threshold(lram_fifo_aempty_threshold),
      // placement:
      .location("")
  ) u_acx_mlp72_1 (
      // MLP:
      .clk(i_clk),
      .din(mlp1_din),
      .load_ab(bram_we[9]), // for BRAM wide mode
      .load(mlp1_load),
      .sub_ab(1'b0),
      .sub(1'b0),
      .ce(mlp1_ce),
      .rstn(mlp1_rstn),
      .expb(bram_we[17:10]),
      .dout(bram_dout[B_width +: B_width]),

      // direct connections from/to ACX_BRAM72K:
      .mlpram_din(mlpram1_din),           // connect to ACX_BRAM72K:mlpram_din
      .mlpram_we(mlpram1_we),             // connect to ACX_BRAM72K:mlpram_we
      .mlpram_dout(mlpram1_dout),         // connect to ACX_BRAM72K:mlpram_dout
      .mlpram_mlp_dout(/*96*/),           // connect to ACX_BRAM72K:mlpram_mlp_dout (MLP result)
      .mlpram_bramdin2mlpdin({72{Open}}), // connect to ACX_BRAM72K:mlpram_din2mlpdin (BRAM din)
      .mlpram_bramdout2mlp(mlpram1_bramdout2mlp), // connect to ACX_BRAM72K:mlpram_dout2mlp (BRAM dout)
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
      .fwdi_multa_h(fwdi_multa_h_0_to_1),
      .fwdi_multa_l(fwdi_multa_l_0_to_1),
      .fwdi_multb_h({72{Open}}),
      .fwdi_multb_l({72{Open}}),
      .fwdi_dout({48{Open}}),
      .fwdo_multa_h(o_fwdo_multa[M_width +: M_width]),
      .fwdo_multa_l(o_fwdo_multa[0 +: M_width]),
      .fwdo_multb_h(/*72*/),
      .fwdo_multb_l(/*72*/),
      .fwdo_dout(/*48*/),

      // LRAM FIFO:
      .lram_wrclk(Open), // use i_clk instead
      .lram_rdclk(Open), // use i_clk instead
      .empty(),
      .full(),
      .almost_empty(),
      .almost_full(),
      .write_error(),
      .read_error()
  );


  /********** MLP0 (bottom) ***************************************************/

  wire [B_width-1 : 0] mlp0_din = bram_dout[B_width +: B_width];
  wire [B_width-1 : 0] mlp0_dout;

  // MLP and FIFO control
  wire [11:0] mlp0_ce;
  wire [3:0]  mlp0_rstn;
  wire        mlp0_load;
  wire        mlp0_accum_ce;
  wire        lram0_wren;
  wire        lram0_rden;
  wire        lram0_fifo_rstn;
  wire        lram0_empty;
  wire        lram0_full;
  wire        lram0_almost_empty;
  wire        lram0_almost_full;

  assign mlp0_ce[0] = 1'b1;          // ce for LRAM output reg 
  assign mlp0_ce[1] = mlp0_accum_ce; // ce for accumulator registers
  assign mlp0_ce[5:2] = 4'b0;        // unused
  assign mlp0_ce[6] = lram0_rden;
  assign mlp0_ce[7] = lram0_wren;
  assign mlp0_ce[11:8] = 4'b0;       // unused
  assign mlp0_rstn[0] = 1'b1;        // LRAM output reg
  assign mlp0_rstn[1] = lram0_fifo_rstn; // LRAM rd/wr pointers
  assign mlp0_rstn[3:2] = 2'b0;      // unused


  // The bottom-most group in a stack takes input from an external BRAM
  // via a direct connection; this is the entry point for the fwdi cascade.
  wire [143:0] mlpram0_bramdout2mlp;   // from BRAM:dout to MLP:din
  assign mlpram0_bramdout2mlp = bottom_group? i_bottom_bram_dout2mlp_din : {144{Open}};

  localparam bit [1:0] mux_sel_multa_l0 = bottom_group? 2'b10 /* bram[71:0] */ :
                                                        2'b11 /* fwdi[71:0] */;
  localparam bit [2:0] mux_sel_multa_h0 = bottom_group? 3'b101 /* bram[143:72] */ :
                                                        3'b111 /* fwdi[143:72] */;


  ACX_MLP72 #(
      // input selection:
      .mux_sel_multa_h(mux_sel_multa_h0),
      .mux_sel_multa_l(mux_sel_multa_l0),
      .mux_sel_multb_h(3'b000), // din[71:0]
      .mux_sel_multb_l(2'b00),  // din[71:0]
      // input format:
      .bytesel_00_07(bytesel[4:0]),
      .bytesel_08_15(bytesel),
      // multiplier operation:
      .multmode_00_07(multmode),
      .multmode_08_15(multmode),
      // adder tree:
      .add_00_07_bypass(1'b0),
      .add_00_07_sub(1'b0),
      .add_08_15_bypass(1'b0),
      .add_08_15_sub(1'b0),
      .add_00_15_sel(1'b0),  // do not add upper to lower half
      // floating point:
      .fpadd_abcd_sel(1'b0), // do not add upper to lower half
      .fpmult_ab_bypass(int_mode),
      .fpmult_ab_blockfp(blockfp),
      .fpmult_ab_blockfp_mode(blockfp_mode),
      .fpmult_ab_exp_size(exp_size),
      .fpmult_cd_bypass(int_mode),
      .fpmult_cd_blockfp(blockfp),
      .fpmult_cd_blockfp_mode(blockfp_mode),
      .fpmult_cd_exp_size(exp_size),
      // accumulator:
      .fpadd_ab_dinb_sel(3'b000), // accumulator feedback (applies to int and fp)
      .fpadd_cd_dina_sel(1'b0), // from cd mult (applies to int and fp)
      .fpadd_cd_dinb_sel(3'b000), // accumulator feedback (applies to int and fp)
      .add_accum_ab_bypass(1'b0), // use accumulator
      .add_accum_cd_bypass(1'b0), // use accumulator
      .rndsubload_share(1'b1),  // use cd 'load' instead of load_ab
      // output:
      .accum_ab_reg_din_sel(!int_mode), // (applies to int and fp)
      .out_reg_din_sel(int_mode? 3'b011 : 3'b010), // (applies to int and fp)
      .fpadd_ab_output_format(fp_output_format),
      .fpadd_cd_output_format(fp_output_format),
      .dout_mlp_sel(2'b00), // not used: MLP output is to LRAM
      .outmode_sel(2'b01),  // dout = LRAM:dout[71:0]
      // stage 0 registers:
      .del_multa_h(1'b1), // pipeline reg of cascade (for speed)
      .del_multa_l(1'b1), // pipeline reg of cascade (for speed)
      .del_multb_h(1'b0), // no delay, to arrive a cycle earlier than at mlp1
      .del_multb_l(1'b0), // no delay, to arrive a cycle earlier than at mlp1
      .del_expb_din_reg(1'b0),
      // stage 1 registers:
      .del_mult00a(1'b1), // enable stage 1 (input) registers, for speed
      .del_mult00b(1'b1),
      .del_mult01a(1'b1),
      .del_mult01b(1'b1),
      .del_mult02a(1'b1),
      .del_mult02b(1'b1),
      .del_mult03a(1'b1),
      .del_mult03b(1'b1),
      .del_mult04_07a(1'b1),
      .del_mult04_07b(1'b1),
      .del_mult08_11a(1'b1),
      .del_mult08_11b(1'b1),
      .del_mult12_15a(1'b1),
      .del_mult12_15b(1'b1),
      // stage 2 registers:
      .del_add_00_07_reg(1'b1), // enable s2 for speed
      .del_add_08_15_reg(1'b1),
      // delay match registers for stage1..2 (for fp exp/sign):
      .del_expa_reg(int_mode? 2'd0 : 2'd2), // 0..2
      .del_expb_reg(int_mode? 2'd0 : 2'd2), // 0..2
      .del_expc_reg(int_mode? 2'd0 : 2'd2), // 0..2
      .del_expd_reg(int_mode? 2'd0 : 2'd2), // 0..2
      // fp registers (stage 2.5 and stage 3):
      .del_fpmult_ab_pipe_reg(!int_mode),
      .del_fpmult_cd_pipe_reg(!int_mode),
      .del_fpmult_ab_reg(1'b0), // typically only used if fpadd_abcd_sel=1
      // delay match registers for stage0..3/4 (for int and fp sub/load):
      .del_rndsubload_ab_reg(3'd0), // use load (shared) instead of load_ab
      .del_rndsubload_reg(mlp_load_latency), // match 'a' input delay
      // stage 4 registers:
      .del_accum_ab_reg(1'b1), // output reg, for speed
      .del_out_reg_00_15(1'b1),
      .del_out_reg_16_31(1'b1),
      .del_out_reg_32_47(int_mode),
      .del_out_reg_48_63(1'b0),
      .del_fp_format_ab_reg(1'b0), // not used when writing LRAM
      .del_fp_format_cd_reg(1'b0),
      // cesel for each register (use 4'd13 for tie high):
      .cesel_multa_h(4'd13),
      .cesel_multa_l(4'd13),
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
      .cesel_mult04_07a(4'd13),
      .cesel_mult04_07b(4'd13),
      .cesel_mult08_11a(4'd13),
      .cesel_mult08_11b(4'd13),
      .cesel_mult12_15a(4'd13),
      .cesel_mult12_15b(4'd13),
      .cesel_add_00_07_reg(4'd13),    
      .cesel_add_08_15_reg(4'd13),    
      .cesel_expta_reg(int_mode? 4'd0 : 4'd13),
      .cesel_exptb_reg(int_mode? 4'd0 : 4'd13),
      .cesel_exptc_reg(int_mode? 4'd0 : 4'd13),
      .cesel_exptd_reg(int_mode? 4'd0 : 4'd13),
      .cesel_fpmult_ab_pipe_reg(int_mode? 4'd0 : 4'd13),
      .cesel_fpmult_cd_pipe_reg(int_mode? 4'd0 : 4'd13),
      .cesel_fpmult_ab_reg(4'd0),
      .cesel_rndsubload_ab_reg(4'd0),
      .cesel_rndsubload_reg(4'd13),
      .cesel_accum_ab_reg(4'd2),  // accum_ab feedback, use ce[1]
      .cesel_out_reg_00_15(4'd2), // accum_cd feedback, use ce[1]
      .cesel_out_reg_16_31(4'd2), // accum_cd feedback, use ce[1]
      .cesel_out_reg_32_47(int_mode? 4'd2 : 4'd0),
      .cesel_out_reg_48_63(4'd0),
      .cesel_fp_format_ab_reg(4'd0),
      .cesel_fp_format_cd_reg(4'd0),
      // rstsel for each register (use 3'd5 for tie high):
      .rstsel_multa_h(3'd5),
      .rstsel_multa_l(3'd5),
      .rstsel_multb_h(3'd0),
      .rstsel_multb_l(3'd0),
      .rstsel_expb_din_reg(3'd0),
      .rstsel_mult00a(3'd5), // use rstn[0]
      .rstsel_mult00b(3'd5),
      .rstsel_mult01a(3'd5),
      .rstsel_mult01b(3'd5),
      .rstsel_mult02a(3'd5),
      .rstsel_mult02b(3'd5),
      .rstsel_mult03a(3'd5),
      .rstsel_mult03b(3'd5),
      .rstsel_mult04_07a(3'd5),
      .rstsel_mult04_07b(3'd5),
      .rstsel_mult08_11a(3'd5),
      .rstsel_mult08_11b(3'd5),
      .rstsel_mult12_15a(3'd5),
      .rstsel_mult12_15b(3'd5),
      .rstsel_add_00_07_reg(3'd5), 
      .rstsel_add_08_15_reg(3'd5), 
      .rstsel_expta_reg(int_mode? 3'd0 : 3'd5), 
      .rstsel_exptb_reg(int_mode? 3'd0 : 3'd5),
      .rstsel_exptc_reg(int_mode? 3'd0 : 3'd5),
      .rstsel_exptd_reg(int_mode? 3'd0 : 3'd5),
      .rstsel_fpmult_ab_pipe_reg(int_mode? 3'd0 : 3'd5),
      .rstsel_fpmult_cd_pipe_reg(int_mode? 3'd0 : 3'd5),
      .rstsel_fpmult_ab_reg(3'd0),
      .rstsel_rndsubload_ab_reg(3'd0),
      .rstsel_rndsubload_reg(3'd5),
      .rstsel_accum_ab_reg(3'd5),
      .rstsel_out_reg_00_15(3'd5),
      .rstsel_out_reg_16_31(3'd5),
      .rstsel_out_reg_32_47(int_mode? 3'd5 : 3'd0),
      .rstsel_out_reg_48_63(3'd0),
      .rstsel_fp_format_ab_reg(3'd0),
      .rstsel_fp_format_cd_reg(3'd0),
      // LRAM clock:
      .lram_clk_sel_wr(1'b1), // use mlp_clk
      .lram_clk_sel_rd(1'b1), // use mlp_clk
      .lram_sync_mode(1'b1),  // wr_clk = rd_clk
      // LRAM read/write:
      .lram_write_width(ACX_lram2k_width_code(lram_wr_width)),
      .lram_read_width(ACX_lram2k_width_code(lram_rd_width)),
      .lram_accum_data_input_sel(!int_mode),
      .lram_write_data_mode(2'b10), // din from MLP
      .lram_input_control_mode(2'b10), // FIFO mode
      .lram_output_control_mode(2'b10), // FIFO mode
      // LRAM output:
      .lram_reg_dout(1'b1), // enabled for better timing (and match mlp1)
      // LRAM FIFO mode:
      .lram_fifo_enable(1'b1),
      .lram_fifo_wrptr_maxval(7'h7F), // FIFO mode
      .lram_fifo_rdptr_maxval(7'h7F), // FIFO mode
      .lram_fifo_sync_mode(1'b1),
      .lram_fifo_afull_threshold(lram_fifo_afull_threshold),
      .lram_fifo_aempty_threshold(lram_fifo_aempty_threshold),
      // placement:
      .location(mlp0_location)
  ) u_acx_mlp72_0 (
      // MLP:
      .clk(i_clk),
      .din(mlp0_din),
      .load_ab(Open),
      .load(mlp0_load),
      .sub_ab(1'b0),
      .sub(1'b0),
      .ce(mlp0_ce),
      .rstn(mlp0_rstn),
      .expb({8{Open}}),
      .dout(mlp0_dout),

      // direct connections from/to ACX_BRAM72K:
      .mlpram_din(/*72*/),                // connect to ACX_BRAM72K:mlpram_din
      .mlpram_we(/*9*/),                  // connect to ACX_BRAM72K:mlpram_we
      .mlpram_dout(/*144*/),              // connect to ACX_BRAM72K:mlpram_dout
      .mlpram_mlp_dout(/*96*/),           // connect to ACX_BRAM72K:mlpram_mlp_dout (MLP result)
      .mlpram_bramdin2mlpdin({72{Open}}), // connect to ACX_BRAM72K:mlpram_din2mlpdin (BRAM din)
      .mlpram_bramdout2mlp(mlpram0_bramdout2mlp), // connect to ACX_BRAM72K:mlpram_dout2mlp (BRAM dout)
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
      .fwdi_multa_h(i_fwdi_multa[M_width +: M_width]),
      .fwdi_multa_l(i_fwdi_multa[0 +: M_width]),
      .fwdi_multb_h({72{Open}}),
      .fwdi_multb_l({72{Open}}),
      .fwdi_dout({48{Open}}),
      .fwdo_multa_h(fwdi_multa_h_0_to_1),
      .fwdo_multa_l(fwdi_multa_l_0_to_1),
      .fwdo_multb_h(/*72*/),
      .fwdo_multb_l(/*72*/),
      .fwdo_dout(/*48*/),

      // LRAM FIFO:
      .lram_wrclk(Open), // use i_clk instead
      .lram_rdclk(Open), // use i_clk instead
      .empty(lram0_empty),
      .full(lram0_full),
      .almost_empty(lram0_almost_empty),
      .almost_full(lram0_almost_full),
      .write_error(),
      .read_error()
  );


  /********** control *********************************************************/

  localparam group_accum_latency = bram_rd_latency + mlp_load_latency;

  // dot-product control:
  // For mlp0:
  // i_first, i_pause, i_last apply to the input data, and follow that
  // data through the pipeline stages
  //   i_first causes 'load' of accumulator register
  //   i_pause causes disable (~ce) of accumulator register
  //   i_last causes wren of LRAM FIFO
  // For mlp1 these cycles should be delayed by 1 cycle

 
  // the load signal is aligned with the MLP input, because it has internal
  // delay registers to match the latency
  pipeline #(
      .width(1),
      .depth(bram_rd_latency)
  ) u_pipeline_0_load (
      .i_clk(i_clk),
      .i_din(i_first),
      .o_dout(mlp0_load)
  );

  // ce does not have internal delay registers, so we match the latency here
  pipeline #(
      .width(1),
      .depth(group_accum_latency)
  ) u_pipeline_0_ce (
      .i_clk(i_clk),
      .i_din(~i_pause),
      .o_dout(mlp0_accum_ce)
  );

  pipeline #(
      .width(1),
      .depth(group_accum_latency + 1)
  ) u_pipeline_0_wren (
      .i_clk(i_clk),
      .i_din(i_last),
      .o_dout(lram0_wren)
  );

  assign lram0_fifo_rstn = i_result_rstn;
  
  pipeline #(
      .width(4),
      .depth(1)
  ) u_pipeline_1_load_ce_wren (
      .i_clk(i_clk),
      .i_din({lram0_wren, mlp0_accum_ce, mlp0_load, lram0_fifo_rstn}),
      .o_dout({lram1_wren, mlp1_accum_ce, mlp1_load, lram1_fifo_rstn})
  );


  // Reading results:
  // mlp1 results are read via the 'B' BRAM, which has a latency of 2.
  // mlp0 results are read directly from the LRAM, which has a latency
  // of 1; we delay the rden once cycle to give an effective latency of 2.
  // The result of mlp1 will arrive one cycle later than for mlp0, just
  // as mlp1 does everything one cycle later.
  // The rden to the BRAM needs to coincide with the rden to the LRAM, so
  // that the BRAM expects data from the LRAM. (Normally the BRAM can pass
  // the rden to the LRAM, but that does not work in FIFO mode.)
  // When i_result_rden is asserted, the environment should assert i_pause,
  // because the BRAM cannot do a regular read while reading the FIFO.
  pipeline #(
      .width(1),
      .depth(1)
  ) u_pipeline_rden (
      .i_clk(i_clk),
      .i_din(i_result_rden),
      .o_dout(lram0_rden)
  );

  assign lram1_rden = lram0_rden;
  assign bram_rd_lram_fifo = lram1_rden;

  reg lram0_valid, lram1_valid;
  always @(posedge i_clk)
  begin
      lram0_valid <= lram0_rden;
      lram1_valid <= lram0_valid;
  end

  assign o_empty        = lram0_empty;
  assign o_full         = lram0_full;
  assign o_almost_empty = lram0_almost_empty;
  assign o_almost_full  = lram0_almost_full;

  assign o_result_1 = bram_dout[0 +: mlp_dout_width];
  assign o_result_0 = mlp0_dout[0 +: mlp_dout_width];
  assign o_result_1_valid = lram1_valid;
  assign o_result_0_valid = lram0_valid;


endmodule: group_2_mlp_1_bram

