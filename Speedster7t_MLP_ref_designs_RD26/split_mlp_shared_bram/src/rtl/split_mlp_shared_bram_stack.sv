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
//  Description: MLP stack with shared BRAMs, with each MLP split in two halves
//
// ----------------------------------------------------------------------

`timescale 1ps/1ps

`include "ram_width_encoding.sv"

module split_mlp_shared_bram_stack #(
    parameter  integer NUM_GROUPS               = 4,
    parameter  integer BRAM_A_WR_WIDTH          = 64,    // 64, 72
    parameter  integer BRAM_A_WRADDR_WIDTH      = 10,
    localparam integer BRAM_BYTE_WIDTH          = 8,
    localparam integer BRAM_A_WE_WIDTH          = BRAM_A_WR_WIDTH / BRAM_BYTE_WIDTH,
    localparam integer BRAM_A_RD_WIDTH          = 144,
    localparam integer BRAM_A_RDADDR_WIDTH      = 9,
    parameter  integer BRAM_B_WR_WIDTH          = 128,   // 64, 72, 128, 144
    parameter  integer BRAM_B_WRADDR_WIDTH      = (BRAM_B_WR_WIDTH > 72)? 9 : 10,
    localparam integer BRAM_B_WE_WIDTH          = BRAM_B_WR_WIDTH / BRAM_BYTE_WIDTH,
    localparam integer BRAM_B_RDADDR_WIDTH      = 9,
    parameter  integer MLP_DOUT_WIDTH           = 48,  // or 24/16 for fp24/fp16
    parameter  integer RESULT_AFULL_THRESHOLD   = 7'h1, // see LRAM documentation
    parameter  integer RESULT_AEMPTY_THRESHOLD  = 7'h2
) (
    // shared clock
    input  wire                             i_clk,
    // bram 'A' write
    input  wire [BRAM_A_WR_WIDTH-1 : 0]     i_bram_a_din,
    input  wire [BRAM_A_WRADDR_WIDTH-1 : 0] i_bram_a_wraddr,
    input  wire                             i_bram_a_wrmsel,
    input  wire                             i_bram_a_wren,
    input  wire [BRAM_A_WE_WIDTH-1 : 0]     i_bram_a_we,
    // bram 'B' write (per group)
    input  wire [BRAM_B_WR_WIDTH-1 : 0]     i_bram_b_din[NUM_GROUPS-1 : 0],
    input  wire [BRAM_B_WRADDR_WIDTH-1 : 0] i_bram_b_wraddr[NUM_GROUPS-1 : 0],
    input  wire [NUM_GROUPS-1 : 0]          i_bram_b_wrmsel,
    input  wire [NUM_GROUPS-1 : 0]          i_bram_b_wren,
    input  wire [BRAM_B_WE_WIDTH-1 : 0]     i_bram_b_we[NUM_GROUPS-1 : 0],
    // computation (bram data passed to MLP)
    input  wire [BRAM_A_RDADDR_WIDTH-1 : 0] i_bram_a_rdaddr,
    input  wire [BRAM_B_RDADDR_WIDTH-1 : 0] i_bram_b_rdaddr,
    input  wire                             i_first,
    input  wire                             i_pause,
    input  wire                             i_last,
    // results
    input  wire                             i_result_rden,
    input  wire                             i_result_rstn, // reset FIFO
    output wire                             o_result_empty,
    output wire                             o_result_full,
    output wire                             o_result_almost_empty,
    output wire                             o_result_almost_full,
    output wire [MLP_DOUT_WIDTH-1 : 0]      o_result_1[NUM_GROUPS-1 : 0], // from MLP1
    output wire [NUM_GROUPS-1 : 0]          o_result_1_valid,
    output wire [MLP_DOUT_WIDTH-1 : 0]      o_result_0[NUM_GROUPS-1 : 0], // from MLP0
    output wire [NUM_GROUPS-1 : 0]          o_result_0_valid
);

  localparam B_WIDTH        = 72;   // regular BRAM width
  localparam B_WE_WIDTH     = 9;    // we input width
  localparam B_ADDR_WIDTH   = 10;   // addr width
  localparam M_WIDTH        = 72;   // regular MLP/LRAM width

  // force pin to remain unconnected rather than tied off
  wire Open;
  ACX_FLOAT undriven(Open);


  /********** stack of groups (1 bram + 2 mlp per group) **********************/

  localparam MLP_DATA_WIDTH = 2*M_WIDTH;

  wire [BRAM_B_RDADDR_WIDTH-1 : 0] bram_b_rdaddr[NUM_GROUPS-1 : 0];
  wire [2*M_WIDTH-1 : 0]           mlp_fwdi_multa[NUM_GROUPS : 0];
  wire [MLP_DATA_WIDTH-1 : 0]      bram_a_dout2mlp;

  wire [NUM_GROUPS-1 : 0] ctrl_first;
  wire [NUM_GROUPS-1 : 0] ctrl_pause;
  wire [NUM_GROUPS-1 : 0] ctrl_last;
  wire [NUM_GROUPS-1 : 0] ctrl_result_rden;
  wire [NUM_GROUPS-1 : 0] ctrl_result_rstn;

  assign bram_b_rdaddr[0]  = i_bram_b_rdaddr;
  assign mlp_fwdi_multa[0] = { 2*M_WIDTH{Open} };
  
  // i_result_rden uses the 'B' BRAM to read a result, so requires that
  // input is paused for a cycle
  assign ctrl_first[0]       = i_first;
  assign ctrl_pause[0]       = i_pause | i_result_rden;
  assign ctrl_last[0]        = i_last & ~ctrl_pause[0];
  assign ctrl_result_rden[0] = i_result_rden & ~o_result_empty;
  assign ctrl_result_rstn[0] = i_result_rstn;

  for (genvar i = 0; i < NUM_GROUPS; i = i + 1)
  begin: stack
      wire empty, full, almost_empty, almost_full;
      reg [BRAM_B_RDADDR_WIDTH-1 : 0] reg_bram_b_rdaddr_d1;
      reg [BRAM_B_RDADDR_WIDTH-1 : 0] reg_bram_b_rdaddr_d2;
      always @(posedge i_clk)
      begin
          reg_bram_b_rdaddr_d1 <= bram_b_rdaddr[i];
          reg_bram_b_rdaddr_d2 <= reg_bram_b_rdaddr_d1;
      end
      if (i < NUM_GROUPS - 1)
        begin
          assign bram_b_rdaddr[i+1] = reg_bram_b_rdaddr_d2;

          pipeline #(
              .width    (5),
              .depth    (2)
          ) u_pipeline_ctrl (
              .i_clk    (i_clk),
              .i_din    ({ctrl_first[i], ctrl_pause[i], ctrl_last[i],
                          ctrl_result_rden[i], ctrl_result_rstn[i]}),
              .o_dout   ({ctrl_first[i+1], ctrl_pause[i+1], ctrl_last[i+1],
                          ctrl_result_rden[i+1], ctrl_result_rstn[i+1]})
          );
        end

      if (i == 0)
        begin
          assign o_result_empty        = empty;
          assign o_result_full         = full;
          assign o_result_almost_empty = almost_empty;
          assign o_result_almost_full  = almost_full;
        end

      group_2_mlp_1_bram #(
          .bottom_group                 (i == 0),                   // set for bottom group in stack
          .bram_wr_width                (BRAM_B_WR_WIDTH),          // 64, 72, 128, 144
          .mlp_dout_width               (48),                       // or 24/16 for fp24/fp16
          .lram_fifo_afull_threshold    (RESULT_AFULL_THRESHOLD),
          .lram_fifo_aempty_threshold   (RESULT_AEMPTY_THRESHOLD)
      ) u_group_2_mlp_1_bram (
          // shared clock
          .i_clk                        (i_clk),
          // bram write
          .i_bram_din                   (i_bram_b_din[i]),
          .i_bram_wraddr                (i_bram_b_wraddr[i]),
          .i_bram_wrmsel                (i_bram_b_wrmsel[i]),
          .i_bram_wren                  (i_bram_b_wren[i]),
          .i_bram_we                    (i_bram_b_we[i]),
          // bram read (data passed to MLPs)
          .i_bram_rdaddr                (reg_bram_b_rdaddr_d1),
          // MLP cascade:
          .i_fwdi_multa                 (mlp_fwdi_multa[i]),    // from group below (if !bottom_group)
          .o_fwdo_multa                 (mlp_fwdi_multa[i+1]),  // to group above
          // input of external BRAM, if bottom_group=1:
          .i_bottom_bram_dout2mlp_din   (i==0? bram_a_dout2mlp : {MLP_DATA_WIDTH{Open}}),
          // control
          .i_first                      (ctrl_first[i]),        // first fwdi data (start accumulation)
          .i_pause                      (ctrl_pause[i]),        // ignore fwdi data (pause accumulation)
          .i_last                       (ctrl_last[i]),         // last fwdi data (accumulation complete)
          // results
          .i_result_rden                (ctrl_result_rden[i]),
          .i_result_rstn                (ctrl_result_rstn[i]),
          .o_empty                      (empty),
          .o_full                       (full),
          .o_almost_empty               (almost_empty),
          .o_almost_full                (almost_full),
          .o_result_1                   (o_result_1[i]),        // from MLP1
          .o_result_1_valid             (o_result_1_valid[i]),
          .o_result_0                   (o_result_0[i]),        // from MLP0
          .o_result_0_valid             (o_result_0_valid[i])
      );

  end


  /********** bram A at bottom of the stack ***********************************/

  wire [B_WIDTH-1 : 0]      bram_a_din;
  wire [B_WE_WIDTH-1 : 0]   bram_a_we;
  wire [B_ADDR_WIDTH-1 : 0] bram_a_wraddr;
  wire [B_ADDR_WIDTH-1 : 0] bram_a_rdaddr;
  assign bram_a_din = { {B_WIDTH-BRAM_A_WR_WIDTH{1'b0}}, i_bram_a_din };
  assign bram_a_we = { {B_WE_WIDTH-BRAM_A_WE_WIDTH{1'b0}}, i_bram_a_we };
  assign bram_a_wraddr = { i_bram_a_wraddr, {B_ADDR_WIDTH-BRAM_A_WRADDR_WIDTH{1'b0}} };
  assign bram_a_rdaddr = { i_bram_a_rdaddr, {B_ADDR_WIDTH-BRAM_A_RDADDR_WIDTH{1'b0}} };
  

  ACX_BRAM72K #(
      // clock:
      .clk_sel_rd               (2'h2), // use mlpclk for read
      // read/write:
      .write_width              (ACX_bram72k_width_code(BRAM_A_WR_WIDTH)), // encoded
      .read_width               (ACX_bram72k_width_code(BRAM_A_RD_WIDTH)),  // encoded
      .wrmem_input_sel          (4'h0), // single BRAM
      .rdmem_input_sel          (4'h0), // single BRAM
      .outreg_enable            (1'h1),
      .outreg_sr_assertion      (1'h0),
      // input register:
      .del_fwdi_ram_wr_addr     (1'h0),
      .del_fwdi_ram_wr_data     (1'h0),
      .del_fwdi_ram_rd_addr     (1'h0),
      .ce_fwdi_ram_wr_addr      (1'h0),
      .ce_fwdi_ram_rd_addr      (1'h0),
      // memory initialization:
      .mem_init_file            ("")
      // .initd_0(72'hx), // init per address 0..1023
      //  ...
      // .initd_1023(72'hx),
  ) u_acx_bram72k (
      // write port:
      .din                      (bram_a_din),
      .wrmsel                   (i_bram_a_wrmsel),
      .wraddrhi                 (bram_a_wraddr),
      .we                       (bram_a_we),
      .wren                     (i_bram_a_wren),
      .wrclk                    (i_clk),

      // read port:
      .rdmsel                   (1'b0),
      .rdaddrhi                 (bram_a_rdaddr),
      .rden                     (1'b1),
      .rdclk                    (Open),             // use mlpclk instead
      .outreg_rstn              (1'b1),
      .outlatch_rstn            (1'b1),
      .outreg_ce                (1'b1),
      .dout                     (/*72*/),

      // direct connections from/to ACX_MLP72:
      .mlpclk                   (i_clk),            // connect to same driver as ACX_MLP72:clk
      .mlpram_din               ({72{Open}}),       // connect to ACX_MLP72:mlpram_din
      .mlpram_we                ({9{Open}}),        // connect to ACX_MLP72:mlpram_we
      .mlpram_dout              ({144{Open}}),      // connect to ACX_MLP72:mlpram_dout (LRAM output)
      .mlpram_mlp_dout          ({96{Open}}),       // connect to ACX_MLP72:mlpram_mlp_dout (MLP result)
      .mlpram_din2mlpdin        (/*72*/),           // connect to ACX_MLP72:mlpram_bramdin2mlpdin (BRAM din)
      .mlpram_dout2mlp          (bram_a_dout2mlp),  // connect to ACX_MLP72:mlpram_bramdout2mlp (BRAM dout)
      .mlpram_din2mlpdout       (/*144*/),          // connect to ACX_MLP72:mlpram_din2mlpdout (to LRAM din)
      .mlpram_wraddr            (/*6*/),            // connect to ACX_MLP72:mlpram_wraddr
      .mlpram_wren              (),                 // connect to ACX_MLP72:mlpram_wren
      .mlpram_rdaddr            (/*6*/),            // connect to ACX_MLP72:mlpram_rdaddr
      .mlpram_rden              (),                 // connect to ACX_MLP72:mlpram_rden
      .mlpram_sbit_error        (),                 // connect to ACX_MLP72:mlpram_sbit_error
      .mlpram_dbit_error        (),                 // connect to ACX_MLP72:mlpram_dbit_error

      // block address .
      .revi_wblk_addr           ({7{Open}}),        // from ACX_BRAM72K above
      .revi_rblk_addr           ({7{Open}}),        // from ACX_BRAM72K above
      .revo_wblk_addr           (/*7*/),            // to ACX_BRAM72K below
      .revo_rblk_addr           (/*7*/),            // to ACX_BRAM72K below

      // BRAM cascade (going up):
      .fwdi_ram_wr_addr         ({14{Open}}),
      .fwdi_ram_wblk_addr       ({7{Open}}),
      .fwdi_ram_wren            (Open),
      .fwdi_ram_we              ({18{Open}}),
      .fwdi_ram_wrmsel          (Open),
      .fwdi_ram_wr_data         ({144{Open}}),
      .fwdi_ram_rd_addr         ({14{Open}}),
      .fwdi_ram_rblk_addr       ({7{Open}}),
      .fwdi_ram_rden            (Open),
      .fwdi_ram_rdmsel          (Open),
      .fwdo_ram_wr_addr         (/*14*/),
      .fwdo_ram_wblk_addr       (/*7*/),
      .fwdo_ram_wren            (),
      .fwdo_ram_we              (/*18*/),
      .fwdo_ram_wrmsel          (),
      .fwdo_ram_wr_data         (/*144*/),
      .fwdo_ram_rd_addr         (/*14*/),
      .fwdo_ram_rblk_addr       (/*7*/),
      .fwdo_ram_rden            (),
      .fwdo_ram_rdmsel          (),

      // BRAM reverse cascade (going down):
      .revi_ram_rd_addr         ({14{Open}}),
      .revi_ram_rblk_addr       ({7{Open}}),
      .revi_ram_rden            (Open),
      .revi_ram_rd_data         ({144{Open}}),
      .revi_ram_rdval           (Open),
      .revi_ram_rdmsel          (Open),
      .revo_ram_rd_addr         (/*14*/),
      .revo_ram_rblk_addr       (/*7*/),
      .revo_ram_rden            (),
      .revo_ram_rd_data         (/*144*/),
      .revo_ram_rdval           (),
      .revo_ram_rdmsel          (),

      // BRAM FIFO:
      .full                     (),
      .almost_full              (),
      .empty                    (),
      .almost_empty             (),
      .write_error              (),
      .read_error               (),

      // ECC (error correction):
      .sbit_error               (),
      .dbit_error               ()
  );


endmodule : split_mlp_shared_bram_stack
