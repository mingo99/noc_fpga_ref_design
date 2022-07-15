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
//  Description: BRAM stack with deep write (single BRAM write), and
//               wide read to MLP.
//               Write-width = 64 (could be changed to 128), read_width = 128
//               Also includes din2mlpdin route-through of bottom BRAM,
//               for use as borrowed inputs by MLP.
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1 ps / 1 ps

module bram_deep_w #(
    parameter  integer M = 6,       // number BRAMs
    localparam integer W = 64,      // write width
    localparam integer A = 10,      // native address width
    localparam integer Ablk = 7,    // block address width
    localparam integer R = 128,     // read width
    localparam integer Ar = A-1     // read address width
) (
    input  wire             i_clk,
    // write
    input  wire [W-1 : 0]    i_wrdata,
    input  wire [A-1 : 0]    i_wraddr,
    input  wire [Ablk-1 : 0] i_wrblk_addr,
    input  wire              i_wren,
    // read
    input  wire [Ar-1 : 0]   i_rdaddr,
    output wire [M*R-1 : 0]  o_bram_dout2mlp_din, // parallel output
    // route-through of din for use by mlp
    input  wire [R/2-1 : 0]  i_mlp_data,
    output wire [R/2-1 : 0]  o_bram_din2mlp_din   // borrowed bram din -> mlp
);

  wire [13:0]  fwdi_ram_wr_addr[M : 0];
  wire [6:0]   fwdi_ram_wblk_addr[M : 0];;
  wire [17:0]  fwdi_ram_we[M : 0];
  wire         fwdi_ram_wren[M : 0];
  wire         fwdi_ram_wrmsel[M : 0];
  wire [143:0] fwdi_ram_wr_data[M : 0];
  wire [13:0]  fwdi_ram_rd_addr[M : 0];
  wire [6:0]   fwdi_ram_rblk_addr[M : 0]; // ignored
  wire         fwdi_ram_rden[M : 0];
  wire         fwdi_ram_rdmsel[M : 0];
  wire [6:0]   revi_wblk_addr[M-1 : -1];  // ignored except for bram[0]

  wire Open;
  ACX_FLOAT undriven(Open);

  assign fwdi_ram_wr_addr[0]   = { 14 {Open} }; // avoid warnings
  assign fwdi_ram_wblk_addr[0] = { 7 {Open} };  // avoid warnings
  assign fwdi_ram_we[0]        = { 18 {Open} }; // avoid warnings
  assign fwdi_ram_wren[0]      = Open;          // avoid warnings
  assign fwdi_ram_wrmsel[0]    = Open;          // avoid warnings
  assign fwdi_ram_wr_data[0]   = {144 {Open} }; // avoid warnings
  assign fwdi_ram_rd_addr[0]   = {14 {Open} };  // avoid warnings
  assign fwdi_ram_rblk_addr[0] = {7 {Open} };   // avoid warnings
  assign fwdi_ram_rden[0]      = Open;          // avoid warnings
  assign fwdi_ram_rdmsel[0]    = Open;          // avoid warnings
  assign revi_wblk_addr[M-1]   = { 7 {Open} };  // avoid warnings


  for (genvar i = 0; i < M; i = i + 1)
    begin: bram_stage
      //             bram[0]       bram[1]        bram[>1]
      // wrdata      i_wrdata      i_wrblk_addr     -
      // wraddr      i_wraddr         -             -
      // wren        i_wren           -             -
      // rdaddr      i_rdaddr     (i_rdblk_addr)    -
      // rddata      o_dout        o_dout         o_dout

      // deep write
      localparam bit [3:0] wrmem_input_sel = (i == 0)? 4'b0001 : 4'b0010;
      // wide read
      localparam bit [3:0] rdmem_input_sel = (i == 0)? 4'b1000 : 4'b1001;

      // din[49:43] of BRAM[1] is the block addr
      wire [W-1 : 0] wrdata = (i == 0)? (i_wren? i_wrdata : i_mlp_data) :
                              (i == 1)? { {W-50 {Open}}, i_wrblk_addr, {43 {Open}} }
                                      : {W {Open}};
      wire [A-1 : 0] wraddr = (i == 0)? i_wraddr : {A {Open}};
      wire           wren = (i == 0)? i_wren : Open;
      wire [A-1 : 0] rdaddr = (i == 0)? {i_rdaddr, 1'b0} : {A {Open}};
      wire [143 : 0] bram_dout2mlp_din;
      wire [71 : 0]  bram_din2mlp_din;
      

      assign o_bram_dout2mlp_din[i*R +: R] =
             { bram_dout2mlp_din[72 +: R/2], bram_dout2mlp_din[0 +: R/2] };

      if (i == 0)
          assign o_bram_din2mlp_din = bram_din2mlp_din[0 +: R/2];

      // BRAM used as 1024 x 64-wide for write, 512 x 128-wide for read.
      // We disable the outreg, and instead use the MLP input register
      (* syn_noprune = 1, must_keep=1 *) ACX_BRAM72K #(
          .write_width(4'b0001),           // 72-bit wide, 8-bit bytes
          .read_width(4'b0011),            // 144-bit wide, 8-bit bytes
          .wrmem_input_sel(wrmem_input_sel), // deep mode (fwdi)
          .rdmem_input_sel(rdmem_input_sel), // wide mode (fwdi -> fabric)
          .del_fwdi_ram_wr_addr(1'b1),     // input/casc register
          .del_fwdi_ram_wr_data(1'b1),     // input/casc register
          .ce_fwdi_ram_wr_addr(1'b1),      // there is no ce: same as del_
          .del_fwdi_ram_rd_addr(1'b1),     // input/casc register
          .ce_fwdi_ram_rd_addr(1'b1),      // there is no ce
          .blk_addr_enable(1'b1),          // fwdi mode
          .blk_addr_value(i),              // block id
          .blk_wraddr_mask(7'h7F),         // write single BRAM
          .blk_rdaddr_mask(7'h00),         // read all BRAMs (ignore rdblk_addr)
          .fifo_enable(1'b0),              // BRAM mode
          .ecc_bypass_encode(1'b1),        // no ECC
          .ecc_bypass_decode(1'b1),        // no ECC
          .outreg_enable(1'b0),            // disable outreg
          .dout_sel(1'b0)                  // no revi
      ) u_bram (
          .wrclk(i_clk),
          .wren(wren),
          .we(9'h0FF),               // enable 8 bytes
          .wraddrhi(wraddr),
          .wrmsel(1'b0),             // no special address mode
          .din({ {72-W {Open}}, wrdata }),
          .rdclk(i_clk),
          .rden(1'b1),               // always read
          .rdaddrhi(rdaddr),
          .rdmsel(1'b0),             // no special address mode
          .outlatch_rstn(1'b1),
          .outreg_rstn(1'b1),
          .outreg_ce(1'b1),
          .dout(),
          .mlpram_dout2mlp(bram_dout2mlp_din),   // BRAM output to MLP
          .mlpram_din2mlpdin(bram_din2mlp_din),  // route-through of din
          // fwd cascade
          .fwdi_ram_wr_addr(fwdi_ram_wr_addr[i]),
          .fwdi_ram_wblk_addr(fwdi_ram_wblk_addr[i]),
          .fwdi_ram_we(fwdi_ram_we[i]),
          .fwdi_ram_wren(fwdi_ram_wren[i]),
          .fwdi_ram_wrmsel(fwdi_ram_wrmsel[i]),
          .fwdi_ram_wr_data(fwdi_ram_wr_data[i]),
          .fwdi_ram_rd_addr(fwdi_ram_rd_addr[i]),
          .fwdi_ram_rblk_addr(fwdi_ram_rblk_addr[i]),
          .fwdi_ram_rden(fwdi_ram_rden[i]),
          .fwdi_ram_rdmsel(fwdi_ram_rdmsel[i]),
          .fwdo_ram_wr_addr(fwdi_ram_wr_addr[i+1]),
          .fwdo_ram_wblk_addr(fwdi_ram_wblk_addr[i+1]),
          .fwdo_ram_we(fwdi_ram_we[i+1]),
          .fwdo_ram_wren(fwdi_ram_wren[i+1]),
          .fwdo_ram_wrmsel(fwdi_ram_wrmsel[i+1]),
          .fwdo_ram_wr_data(fwdi_ram_wr_data[i+1]),
          .fwdo_ram_rd_addr(fwdi_ram_rd_addr[i+1]),
          .fwdo_ram_rblk_addr(fwdi_ram_rblk_addr[i+1]),
          .fwdo_ram_rden(fwdi_ram_rden[i+1]),
          .fwdo_ram_rdmsel(fwdi_ram_rdmsel[i+1]),
          // block address entry
          .revi_wblk_addr(revi_wblk_addr[i]),
          .revo_wblk_addr(revi_wblk_addr[i-1]),
          // unused pins
          .revi_ram_rd_addr({14{Open}}),
          .revi_ram_rblk_addr({7{Open}}),
          .revi_ram_rden(Open),
          .revi_ram_rd_data({144{Open}}),
          .revi_ram_rdval(Open),
          .revi_ram_rdmsel(Open),
          .revi_rblk_addr({7{Open}}),
          .mlpram_din({72{Open}}),
          .mlpram_dout({144{Open}}),
          .mlpram_we({9{Open}}),
          .mlpclk(Open),
          .mlpram_mlp_dout({96{Open}}),
          .sbit_error(),
          .dbit_error(),
          .full(),
          .almost_full(),
          .empty(),
          .almost_empty(),
          .write_error(),
          .read_error(),
          .revo_ram_rd_addr(),
          .revo_ram_rblk_addr(),
          .revo_ram_rden(),
          .revo_ram_rdmsel(),
          .revo_ram_rd_data(),
          .revo_ram_rdval(),
          .revo_rblk_addr(),
          .mlpram_din2mlpdout(),
          .mlpram_rdaddr(),
          .mlpram_wraddr(),
          .mlpram_dbit_error(),
          .mlpram_rden(),
          .mlpram_sbit_error(),
          .mlpram_wren()
      );

    end // for (genvar i)

endmodule : bram_deep_w

