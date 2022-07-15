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
//  Description: dot product using MLP, 4x mode
//
///////////////////////////////////////////////////////////////////////////////

// Computes a dot product of variable size vectors i_a and i_b (up to
// 8k elements per vector).
//
// The dot product is SUM i_a[j]*i_b[j].
// Vector i_a[...] should have a multiple of M=16 elements, where each
// element is an N=8 bit signed integer. Input is M elements per cycle.
//
// Vector i_b[...] must be stored in the BRAM, as M/2 = 8 byte wide words, at
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

// Multiple cascaded version of dot product

`timescale 1 ps / 1 ps

`include "7t_interfaces.svh"

module dot_product_16_8x8_multi #(
    parameter           NUM_MLP  = 4,           // Can expand to 64 later
    parameter           MAX_COLS = 4,           // Maximum number of MLP columns
    parameter           MAX_ROWS = 16,          // Maximum number of MLP rows
    localparam integer  N        = 8,           // integer size
    localparam integer  M        = 16,          // number parallel multiplies
    localparam integer  Mb       = M / 2,       // number items in BRAM write
    localparam integer  A        = 10,          // BRAM address bits
    localparam integer  S        = 48           // bits in result
) (
    input  wire                 i_clk,
    input  wire                 i_reset_n,
    // BRAM inputs
    input  wire [Mb*N-1 : 0]    i_b,            // M N-bit integers (2's compl)
    input  wire [A -1: 0]       i_b_wraddr,     // BRAM address bits
    input  wire [A -2: 0]       i_b_rdaddr,     // BRAM address bits
    input  wire [7 -1: 0]       i_blk_wr_addr,  // BRAM block write address
    input  wire                 i_wren,         // BRAM write enable

    // input data for dot-product
    input  wire [M*N-1 : 0]     i_a,            // M N-bit integers (2's compl)
    input  wire                 i_first,        // high for first item of dotproduct
    input  wire                 i_last,         // high for last item of dotproduct
    // output data
    output t_mlp_out            o_sum [MAX_COLS -1:0],    // Word of results from full column.
    output wire [MAX_COLS -1:0] o_valid          // Valid to write word from column
);


    // Create BRAM write data
    logic [72  -1:0] bram_wr_data;
    always @(posedge i_clk)
        if( i_wren )
            bram_wr_data <= {8'b0, i_b};
        else
            bram_wr_data <= {8'b0, i_a[M*N-1 : M*N/2]};

    // Need to delay i_a, i_first and i_b_wraddr to match delay in bram_wr_data
    logic [M*N-1 : 0]   a_del;
    logic               first_del;
    logic               wren_del;
    logic [A -1: 0]     wraddr_del;
    logic [A -2: 0]     rdaddr_del;
    
    always @(posedge i_clk)
    begin
        a_del      <= i_a;
        first_del  <= i_first;
        wren_del   <= i_wren;
        wraddr_del <= i_b_wraddr;
        rdaddr_del <= i_b_rdaddr;
    end

    // Input block addresses, write = pins [49:43], read = pins [42:36]
    wire [72  -1:0] blk_wr_addr = {22'h0, i_blk_wr_addr, 43'h0};

    // ---------------------------------------------
    // Cascade paths
    // ---------------------------------------------
    // Float wires for cascade signals
    wire float;    
    ACX_FLOAT X_ACX_FLOAT(.y(float));

    // ---------------------------------------------
    // Start and end signals
    // ---------------------------------------------
    logic [NUM_MLP-1:0] first_pipe;

    // Need a matching delay on i_first to match input delays
    always @(posedge i_clk)
        first_pipe <= {first_pipe[NUM_MLP-2:0], i_first};

    // MLP is configured for 4 cycles delay
    logic [2:0] last_del = 3'b000;
    always @(posedge i_clk)
    begin
        last_del <= {last_del[1:0], i_last};
    end

    // Pipeline needed for last signals
    logic [NUM_MLP:0] last_pipe;

    always @(posedge i_clk)
        last_pipe <= {last_pipe[NUM_MLP-1:0], last_del[2]};

    // ---------------------------------------------
    // MLP loop
    // ---------------------------------------------
    // Lay out MLP in columns of 16.  4 BRAM needed for in and out FIFO.
    // Data input only into the bottom of each column, both for image data and BRAM programming
    // Structure supports up to 12 MLP, or 28, 44 and 60.
    localparam MLP_W = ((NUM_MLP+4) + MAX_ROWS-1) / MAX_ROWS;

    generate for( genvar col=0; col<MLP_W; col=col+1 ) begin : gb_mlp_col

        // First and last columns are 14 to allow for in FIFO and out FIFO
        // All other columns are 16.
        localparam MLP_H = (MLP_W > 1) ? (((col==0) || (col==(MLP_W-1))) ? 14 : 16 )
                                       : NUM_MLP;

        // Cascades are per column
        wire [13:0]     rev_ram_rd_addr     [MLP_H:0];
        wire [6:0]      rev_ram_rblk_addr   [MLP_H:0];
        wire            rev_ram_rden        [MLP_H:0];
        wire            rev_ram_rdmsel      [MLP_H:0];
        wire [143:0]    rev_ram_rd_data     [MLP_H:0];
        wire            rev_ram_rdval       [MLP_H:0];
        wire [6:0]      rev_rblk_addr       [MLP_H:0];
        wire [6:0]      rev_wblk_addr       [MLP_H:0];

        wire [13:0]     fwd_ram_wr_addr     [MLP_H:0];
        wire [6:0]      fwd_ram_wblk_addr   [MLP_H:0];
        wire [17:0]     fwd_ram_we          [MLP_H:0];
        wire            fwd_ram_wren        [MLP_H:0];
        wire [143:0]    fwd_ram_wr_data     [MLP_H:0];
        wire [13:0]     fwd_ram_rd_addr     [MLP_H:0];
        wire [6:0]      fwd_ram_rblk_addr   [MLP_H:0];
        wire            fwd_ram_rden        [MLP_H:0];
        wire            fwd_ram_rdmsel      [MLP_H:0];
        wire            fwd_ram_wrmsel      [MLP_H:0];

        wire [71:0]     fwd_multa_h         [MLP_H:0];
        wire [71:0]     fwd_multb_h         [MLP_H:0];
        wire [71:0]     fwd_multa_l         [MLP_H:0];
        wire [71:0]     fwd_multb_l         [MLP_H:0];
        wire [47:0]     fwd_dout            [MLP_H:0];


        // Cascade inputs to first elements are floats
        assign fwd_ram_wr_addr[0]          = {14{float}};
        assign fwd_ram_wblk_addr[0]        = {7{float}};
        assign fwd_ram_we[0]               = {18{float}};
        assign fwd_ram_wren[0]             = float;
        assign fwd_ram_wr_data[0]          = {144{float}};
        assign fwd_ram_rd_addr[0]          = {14{float}};
        assign fwd_ram_rblk_addr[0]        = {7{float}};
        assign fwd_ram_rden[0]             = float;
        assign fwd_ram_rdmsel[0]           = float;
        assign fwd_ram_wrmsel[0]           = float;

        assign rev_ram_rd_addr[MLP_H]      = {14{float}};
        assign rev_ram_rblk_addr[MLP_H]    = {7{float}};
        assign rev_ram_rden[MLP_H]         = float;
        assign rev_ram_rdmsel[MLP_H]       = float;
        assign rev_ram_rd_data[MLP_H]      = {144{float}};
        assign rev_ram_rdval[MLP_H]        = float;
        assign rev_rblk_addr[MLP_H]        = {7{float}};
        assign rev_wblk_addr[MLP_H]        = {7{float}};

        assign fwd_multa_h[0]              = {72{float}};
        assign fwd_multb_h[0]              = {72{float}};
        assign fwd_multa_l[0]              = {72{float}};
        assign fwd_multb_l[0]              = {72{float}};
        assign fwd_dout[0]                 = {48{float}};

        // Create a wire that will have a value from each MLP
        logic [15:0]    mlp_dout_result [15:0];
        wire  [255:0]   mlp_dout_wide;

        for( genvar row=0; row<MLP_H; row=row+1 ) begin : gb_mlp_row

            // Local wires per MLP pair
            // Route through of BRAM din to MLP din.
            wire [72  -1:0] mlp_a_hi;
            // Dout from BRAM to MLP input
            wire [144 -1:0] mlp_b;
            // Only write enable into bottom BRAM
            wire bram_wren = (row==0) ? wren_del : 1'b0;      // Memories selected using blk_addr
            // Output from mlp
            wire [71:0] mlp_out;

            /* REVISIT - It will be necessary in a full design to write a different kernel to each BRAM
            // For this requirement, the block address should changed, providing a unique address for each memory.
            localparam [6:0]  blk_addr_val = row + (col*MAX_ROWS);
            */

            // Current process, same memory number in each column.
            localparam [6:0]  blk_addr_val = row;

            // For writes, the first BRAM up the chain has the write address
            // Data only needs to go into the first BRAM.
            wire [71:0] bram_din =  (row==0) ? bram_wr_data :
                                   ((row==1) ? blk_wr_addr  : 72'h0);
            // Address only goes to the bottom BRAM
            wire [A -1: 0] wraddr_in = (row==0) ? wraddr_del         : {A{1'b0}};
            wire [A -1: 0] rdaddr_in = (row==0) ? {rdaddr_del, 1'b0} : {A{1'b0}};
            // Wires between MLP and BRAM
            wire [143:0] mlpram_din2mlpdout;
            wire [95:0]  mlpram_mlp_dout;
            wire [143:0] mlpram_dout;
            wire [71:0]  mlpram_din;

            // Set write input select.  Bottom memory from fabric, rest from fwdi
            // This is DEEP_WRITE mode.  This automatically routes blk_wr_addr from bram[1].
            localparam [3:0]  wrmem_input_sel = (row==0) ? 4'b0001 :     // FWDI write, bottom memory
                                                           4'b0010 ;     // FWDI write, mid/top memory
            // Set read input select.  Bottom memory from fabric, rest from fwdi
            // This is FWDI_READ mode.
            localparam [3:0]  rdmem_input_sel = (row==0) ? 4'b0011 :     // FWDI read, bottom memory
                                                           4'b0100 ;     // FWDI read, mid/top memory

            localparam        del_fwdi_ram_rd_addr = (row==0) ? 1'b0 : 1'b1;
            localparam        del_fwdi_ram_wr_addr = (row==0) ? 1'b0 : 1'b1;

            // BRAM used as 1024 x 64-wide for write, 512 x 128-wide for read.
            // Disable the outreg, and instead use the MLP input register

            ACX_BRAM72K #(
                .write_width                    (4'b0001),          // 72-bit wide, 8-bit bytes
                .read_width                     (4'b0011),          // 144-bit wide, 8-bit bytes
                .wrmem_input_sel                (wrmem_input_sel),  // Write port input
                .rdmem_input_sel                (rdmem_input_sel),  // Read port input
                .blk_rdaddr_mask                (7'b0000000),       // All reads in parallel, all BRAM selected
                .blk_wraddr_mask                (7'b0001111),       // Writes staggered, each BRAM has a different kernel.  This supports 16 BRAM
                .blk_addr_value                 (blk_addr_val),     // Number each BRAM
                .blk_addr_enable                (1'b1),             // Enable block addresses
                .del_fwdi_ram_wr_addr           (del_fwdi_ram_wr_addr), // pipeline the write cascade
                .del_fwdi_ram_wr_data           (del_fwdi_ram_wr_addr), // pipeline the write cascade
                .del_fwdi_ram_rd_addr           (del_fwdi_ram_rd_addr), // Add delay to read address cascade, to match data delay through MLPs
                .ce_fwdi_ram_rd_addr            (del_fwdi_ram_rd_addr),  // Always enable flop CE
                .ce_fwdi_ram_wr_addr            (del_fwdi_ram_wr_addr),  // Always enable flop CE
                .fifo_enable                    (1'b0),             // BRAM mode
                .ecc_bypass_encode              (1'b1),             // no ECC
                .ecc_bypass_decode              (1'b1),             // no ECC
                .outreg_enable                  (1'b0),             // disable outreg
                .dout_sel                       (1'b0)              // no revi

            ) i_bram (

                .wrclk                          (i_clk),
                .wren                           (bram_wren),
                .we                             (9'h1FF),           // enable all 9 bytes.  We tie off the top entry to 8'h0.
                .wraddrhi                       (wraddr_in),
                .wrmsel                         (1'b0),             // no special address mode
                .din                            (bram_din),
                .rdclk                          (i_clk),
                .rden                           (1'b1),             // always read
                .rdaddrhi                       (rdaddr_in),
                .rdmsel                         (1'b0),             // no special address mode
                .outlatch_rstn                  (1'b1),
                .outreg_rstn                    (1'b1),
                .outreg_ce                      (1'b1),
                .dout                           (),
                .mlpram_dout2mlp                (mlp_b),            // BRAM output to MLP
                .mlpram_mlp_dout                (mlpram_mlp_dout),  // 96 bit input
                .mlpram_din2mlpdin              (mlp_a_hi),         // route-through of din
                .mlpclk                         (),                 // Leave open.

                // Unused pins, instantiated to remove warnings
                // Used by MLP internal LRAM
                .mlpram_we                      (9'h0),
                .sbit_error                     (),
                .dbit_error                     (),
                .full                           (),
                .almost_full                    (),
                .empty                          (),
                .almost_empty                   (),
                .write_error                    (),
                .read_error                     (),

                .mlpram_din2mlpdout             (mlpram_din2mlpdout),   // Output
                .mlpram_din                     (mlpram_din),
                .mlpram_dout                    (mlpram_dout),

                // MLP LRAM control signals
                .mlpram_rdaddr                  (),
                .mlpram_wraddr                  (),
                .mlpram_dbit_error              (),
                .mlpram_rden                    (),
                .mlpram_sbit_error              (),
                .mlpram_wren                    (),

                .fwdi_ram_wr_addr               (fwd_ram_wr_addr[row]),
                .fwdi_ram_wblk_addr             (fwd_ram_wblk_addr[row]),
                .fwdi_ram_we                    (fwd_ram_we[row]),
                .fwdi_ram_wren                  (fwd_ram_wren[row]),
                .fwdi_ram_wr_data               (fwd_ram_wr_data[row]),
                .fwdi_ram_rd_addr               (fwd_ram_rd_addr[row]),
                .fwdi_ram_rblk_addr             (fwd_ram_rblk_addr[row]),
                .fwdi_ram_rden                  (fwd_ram_rden[row]),
                .fwdi_ram_rdmsel                (fwd_ram_rdmsel[row]),
                .fwdi_ram_wrmsel                (fwd_ram_wrmsel[row]),

                .revi_ram_rd_addr               (rev_ram_rd_addr[row+1]),
                .revi_ram_rblk_addr             (rev_ram_rblk_addr[row+1]),
                .revi_ram_rden                  (rev_ram_rden[row+1]),
                .revi_ram_rd_data               (rev_ram_rd_data[row+1]),
                .revi_ram_rdval                 (rev_ram_rdval[row+1]),
                .revi_ram_rdmsel                (rev_ram_rdmsel[row+1]),
                .revi_rblk_addr                 (rev_rblk_addr[row+1]),
                .revi_wblk_addr                 (rev_wblk_addr[row+1]),

                .revo_ram_rd_addr               (rev_ram_rd_addr[row]),
                .revo_ram_rblk_addr             (rev_ram_rblk_addr[row]),
                .revo_ram_rden                  (rev_ram_rden[row]),
                .revo_ram_rdmsel                (rev_ram_rdmsel[row]),
                .revo_ram_rd_data               (rev_ram_rd_data[row]),
                .revo_ram_rdval                 (rev_ram_rdval[row]),
                .revo_rblk_addr                 (rev_rblk_addr[row]),
                .revo_wblk_addr                 (rev_wblk_addr[row]),

                .fwdo_ram_wr_addr               (fwd_ram_wr_addr[row+1]),
                .fwdo_ram_wblk_addr             (fwd_ram_wblk_addr[row+1]),
                .fwdo_ram_we                    (fwd_ram_we[row+1]),
                .fwdo_ram_wren                  (fwd_ram_wren[row+1]),
                .fwdo_ram_wr_data               (fwd_ram_wr_data[row+1]),
                .fwdo_ram_rd_addr               (fwd_ram_rd_addr[row+1]),
                .fwdo_ram_rblk_addr             (fwd_ram_rblk_addr[row+1]),
                .fwdo_ram_rden                  (fwd_ram_rden[row+1]),
                .fwdo_ram_rdmsel                (fwd_ram_rdmsel[row+1]),
                .fwdo_ram_wrmsel                (fwd_ram_wrmsel[row+1])
            );

            // a input data is cascaded up the column of MLPs, only input to the lowest MLP
            localparam [1:0] mux_sel_multa_l = (row==0) ? 2'b00  : 2'b11;
            localparam [2:0] mux_sel_multa_h = (row==0) ? 3'b001 : 3'b111;

            // b input data comes from the linked bram.
            localparam [1:0] mux_sel_multb_l = 2'b10;
            localparam [2:0] mux_sel_multb_h = 3'b101;

            // Only send data to first MLP, data is then cascaded up the column
            wire [71:0] mlp_din = (row==0) ? {8'b0, a_del[M*N/2-1 : 0]} : 72'h0;

            // The BRAM has rdaddr -> dout has a cycle latency. If 'a' input and
            // rdaddr are issued simultaneously, then the 'a' input needs an extra
            // cycle latency. Therefore, for 'a' we use a stage0 and stage1 register,
            // but for 'b' only a stage0 register.
            ACX_MLP72 #(
                .mux_sel_multa_l                (mux_sel_multa_l),  // input 'a_l' from fabric
                .mux_sel_multa_h                (mux_sel_multa_h),  // input 'a_h' from BRAM din (fabric)
                .mux_sel_multb_l                (mux_sel_multb_l),  // input 'b_l' from BRAM[71:0]
                .mux_sel_multb_h                (mux_sel_multb_h),  // input 'b_h' from BRAM[143:72]

                .del_multa_l                    (1'b1),     // enable stage0 register
                .del_multa_h                    (1'b1),     // enable stage0 register
                .del_multb_l                    (1'b1),     // enable stage0 register
                .del_multb_h                    (1'b1),     // enable stage0 register
                .cesel_multa_l                  (4'd13),    // no ce
                .cesel_multa_h                  (4'd13),    // no ce
                .cesel_multb_l                  (4'd13),    // no ce
                .cesel_multb_h                  (4'd13),    // no ce
                .rstsel_multa_l                 (3'd5),     // no rstn
                .rstsel_multa_h                 (3'd5),     // no rstn
                .rstsel_multb_l                 (3'd5),     // no rstn
                .rstsel_multb_h                 (3'd5),     // no rstn

                // BRAM data arriving early, so no stage1 delay
                .del_mult00a                    (1'b0),     // enable stage1 register
                .del_mult01a                    (1'b0),     // enable stage1 register
                .del_mult02a                    (1'b0),     // enable stage1 register
                .del_mult03a                    (1'b0),     // enable stage1 register
                .del_mult04_07a                 (1'b0),     // enable stage1 register
                .del_mult08_11a                 (1'b0),     // enable stage1 register
                .del_mult12_15a                 (1'b0),     // enable stage1 register

                .cesel_mult00a                  (4'd13),    // no ce
                .cesel_mult01a                  (4'd13),    // no ce
                .cesel_mult02a                  (4'd13),    // no ce
                .cesel_mult03a                  (4'd13),    // no ce
                .cesel_mult04_07a               (4'd13),    // no ce
                .cesel_mult08_11a               (4'd13),    // no ce
                .cesel_mult12_15a               (4'd13),    // no ce
                .rstsel_mult00a                 (3'd5),     // no rstn
                .rstsel_mult01a                 (3'd5),     // no rstn
                .rstsel_mult02a                 (3'd5),     // no rstn
                .rstsel_mult03a                 (3'd5),     // no rstn
                .rstsel_mult04_07a              (3'd5),     // no rstn
                .rstsel_mult08_11a              (3'd5),     // no rstn
                .rstsel_mult12_15a              (3'd5),     // no rstn

                .bytesel_00_07                  (5'h01),    // int8, 4x mode
                .bytesel_08_15                  (6'h21),    // int8, 4x mode
                .multmode_00_07                 (5'h01),    // int8, unsigned
                .multmode_08_15                 (5'h01),    // int8, unsigned
                .add_00_07_bypass               (1'b0),     // use mult 0..7
                .add_08_15_bypass               (1'b0),     // use mult 8..15

                .del_add_00_07_reg              (1'b1),     // enable stage2 reg 
                .del_add_08_15_reg              (1'b1),     // enable stage2 reg 
                .cesel_add_00_07_reg            (4'd13),    // no ce
                .cesel_add_08_15_reg            (4'd13),    // no celast
                .rstsel_add_00_07_reg           (3'd5),     // no rstn
                .rstsel_add_08_15_reg           (3'd5),     // no rstn

                .add_00_15_sel                  (1'b1),     // use mult 0..15 (add both halves)
                .fpmult_ab_bypass               (1'b1),     // integer mode
                .fpmult_cd_bypass               (1'b1),     // integer mode
                .fpadd_ab_dinb_sel              (3'b000),   // accumulator mode
                .add_accum_ab_bypass            (1'b0),     // use AB int accumulator
                .accum_ab_reg_din_sel           (1'b0),     // integer mode

                .del_accum_ab_reg               (1'b1),     // use AB register (accumulator/output)
                .cesel_accum_ab_reg             (4'd13),    // no ce
                .rstsel_accum_ab_reg            (3'd5),     // no rstn

                .rndsubload_share               (1'b1),     // use regular load etc. pin for AB reg
                .del_rndsubload_reg             (3'd2),     // delay match for load etc. - currently load one cycle too late
                .cesel_rndsubload_reg           (4'd13),    // no ce
                .rstsel_rndsubload_reg          (3'd5),     // no rstn

                .dout_mlp_sel                   (2'b10),    // result = AB register
                .outmode_sel                    (2'b00)     // output = MLP result

            ) i_mlp (

                .clk                            (i_clk),
//                .mlpram_mlpclk                  (),                 // Scan clock output.  Do not connect
                .din                            (mlp_din),
                .mlpram_bramdout2mlp            (mlp_b),            // BRAM data
                .mlpram_bramdin2mlpdin          (mlp_a_hi),         // route-through of BRAM din
                .mlpram_mlp_dout                (mlpram_mlp_dout),  // 96 bit output

                .sub                            (1'b0),
                .load                           (first_pipe[row]),

                .sub_ab                         (1'b0),             // As rndsubload_share is set, these inputs ignored
                .load_ab                        (1'b0),

                .dout                           (mlp_out),

                // Unused pins, instantiated to remove warnings
                // Control signals for local LRAM
                .sbit_error                     (),
                .dbit_error                     (),
                .full                           (),
                .almost_full                    (),
                .empty                          (),
                .almost_empty                   (),
                .write_error                    (),
                .read_error                     (),

                .fwdo_multa_h                   (fwd_multa_h[row+1]),
                .fwdo_multb_h                   (fwd_multb_h[row+1]),
                .fwdo_multa_l                   (fwd_multa_l[row+1]),
                .fwdo_multb_l                   (fwd_multb_l[row+1]),
                .fwdo_dout                      (fwd_dout[row+1]),
                .mlpram_din                     (mlpram_din),
                .mlpram_dout                    (mlpram_dout),
                .mlpram_we                      (),

                .fwdi_multa_h                   (fwd_multa_h[row]),
                .fwdi_multb_h                   (fwd_multb_h[row]),
                .fwdi_multa_l                   (fwd_multa_l[row]),
                .fwdi_multb_l                   (fwd_multb_l[row]),
                .fwdi_dout                      (fwd_dout[row]),

                .mlpram_din2mlpdout             (mlpram_din2mlpdout),   // Input

                // LRAM not used, tie off inputs
                .mlpram_rdaddr                  (6'b0),
                .mlpram_wraddr                  (6'b0),
                .mlpram_dbit_error              (1'b0),
                .mlpram_rden                    (1'b0),
                .mlpram_sbit_error              (1'b0),
                .mlpram_wren                    (1'b0),

                .lram_wrclk                     (1'b0),
                .lram_rdclk                     (1'b0),

                .ce                             (12'hfff),
                .rstn                           ({4{1'b1}}),
                .expb                           (8'h00)
            );

            // For demonstration builds, fix data output to 16 bits
            // Accumulate each result into a 16 bit lane in a 256-bit word.
            // Write each 256 bit word once all MLP's complete.
            // Users may wish to consider adding the folling to create a full AlexNet system
            //   Add an activation layer, probably ReLu.  If data can be shrunk to 10 bits, then could use ROM
            //   otherwise follow with an MLP
            //   Consider how data would be read from memory for next stage.  MLP ideally structured for 16 pixels
            //   So writing result as 16 layers would match.

            // To support coefficients up to 256, divide final result by 256
            // Write the result to a register
            always @(posedge i_clk)
                if( last_pipe[row] )
                    mlp_dout_result[row] <= mlp_out[23:8];

        end // generate row < MLP_H

        // -------------------------
        // Per column processing
        // -------------------------

        // If less than MAX_ROWS, set output values to 0
        if ( MLP_H < MAX_ROWS ) begin : gb_empty_rows
            for ( genvar empty_row=MLP_H; empty_row < MAX_ROWS; empty_row = empty_row + 1 )
            begin
                always @(posedge i_clk)
                    mlp_dout_result[empty_row] <= 0;
            end
        end

        // Mux all the mlp results in a single 256 wide vector
        for ( genvar full=0; full < MAX_ROWS; full = full + 1 ) begin : gb_full_op
            if( full > MLP_H )
                assign mlp_dout_wide[((full+1)*16)-1:(full*16)] = 16'h0000;
            else
                assign mlp_dout_wide[((full+1)*16)-1:(full*16)] = mlp_dout_result[full];
        end

        // Final output sum is the wide word from each column
        // Use the valid from the last MLP to signal that the word is ready to write            
        assign o_sum[col]   = mlp_dout_wide;
        assign o_valid[col] = last_pipe[MLP_H];

    end
    endgenerate // col < MLP_W

    // If not assigning the maximum columns, tie off the unused outputs
    generate if ( MLP_W < MAX_COLS ) begin : gb_empty_col
        for ( genvar empty_col=MLP_W; empty_col < MAX_COLS; empty_col = empty_col + 1 )
        begin
            assign o_sum[empty_col]   = 0;
            assign o_valid[empty_col] = 1'b0;
        end
    end
    endgenerate // less than MAX_COLS used

endmodule : dot_product_16_8x8_multi


