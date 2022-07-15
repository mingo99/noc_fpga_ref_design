// ------------------------------------------------------------------
//
// Copyright (c) 2020  Achronix Semiconductor Corp.
// All Rights Reserved.
//
//
// This software constitutes an unpublished work and contains
// valuable proprietary information and trade secrets belonging
// to Achronix Semiconductor Corp.
//
// This software may not be used, copied, distributed or disclosed
// without specific prior written authorization from
// Achronix Semiconductor Corp.
//
// The copyright notice above does not evidence any actual or intended
// publication of such software.
//
// ------------------------------------------------------------------
// Behavioural model of an MLP operating as 16 8x8 multipliers
// Used for side by side comparision during development
// ------------------------------------------------------------------

`timescale 1 ps / 1 ps

module tb_mlp_behavioural_16x_int8
#(
    parameter                           DATA_WIDTH = 64,    // Output data width
    parameter                           BRAM_ADDR_WIDTH = 10,
    parameter                           BRAM_DATA_WIDTH = 64
)
(
    // Inputs
    input  wire                         clk,
    input  wire                         reset_n,            // Negative synchronous reset

    input  wire [BRAM_ADDR_WIDTH-1:0]   bram_wr_addr,       // Double width output, so half the address
    input  wire [7 -1: 0]               bram_blk_wr_addr,   // This model only supports memory[0]

    input  wire [BRAM_DATA_WIDTH-1:0]   bram_din,
    input  wire                         bram_wren,

    input  wire                         mlp_din_sof,
    input  wire                         mlp_din_eof,
    input  wire [143:0]                 mlp_din,
    input  wire [BRAM_ADDR_WIDTH-2:0]   bram_rd_addr,       // Double width output, so half the address

    // Outputs
    output wire [DATA_WIDTH-1:0]        dout,
    output wire                         dout_valid

);

    wire            load;
    wire [11:0]     ce = 12'hfff;
    wire [7:0]      expb;
    wire [71:0]     fwdi_multa_h;
    wire [71:0]     fwdi_multb_h;
    wire [71:0]     fwdi_multa_l;
    wire [71:0]     fwdi_multb_l;
    wire [47:0]     fwdi_dout;
    wire [71:0]     mlpram_bramdin2mlpdin;
    wire [143:0]    mlpram_din2mlpdout;
    wire [5:0]      mlpram_rdaddr;
    wire [5:0]      mlpram_wraddr;
    wire            mlpram_dbit_error;
    wire            mlpram_rden;
    wire            mlpram_sbit_error;
    wire            mlpram_wren;
    wire [71:0]     dout_mlp;
    wire            error;
    wire            empty;
    wire            full;
    wire            almost_empty;
    wire            almost_full;
    wire            sbit_error;
    wire            dbit_error;
    wire            write_error;
    wire            read_error;
    wire [71:0]     fwdo_multa_h;
    wire [71:0]     fwdo_multb_h;
    wire [71:0]     fwdo_multa_l;
    wire [71:0]     fwdo_multb_l;
    wire [47:0]     fwdo_dout;
    wire [71:0]     mlpram_din;
    wire [143:0]    mlpram_dout;
    wire [8:0]      mlpram_we;
    wire [9:0]      wraddrhi;
    wire [9:0]      rdaddrhi;
    wire            wren;
    wire            rden;
    wire            wrmsel;
    wire            rdmsel;
    wire            outreg_rstn;
    wire            outlatch_rstn;
    wire            outreg_ce;
    wire [71:0]     din;
    wire [8:0]      we;


    // For now use a behavioural model
    // Behavioural memory
    logic [71:0]                bram [(2**BRAM_ADDR_WIDTH)-1:0];

    logic [BRAM_ADDR_WIDTH-1:0] bram_addr_even;
    logic [143:0]               bram_out;

    // ------------------------
    // BRAM72K
    // ------------------------

    // Programme RAM on power up
    integer i;

    reg [71:0] addr_reg;
    reg        we_reg;
    reg        rd_reg;

    initial
    begin
        rd_reg   = 1'b0;
        addr_reg = -1;
        while( reset_n !== 1'b1)
        begin
            @(posedge clk);
        end
        repeat(20) @(posedge clk);
        for( i=0; i<66;i=i+1 )  // Big enough to transfer kernel.txt
        begin
            addr_reg = addr_reg + 1;
            rd_reg   = 1'b1;
            @(posedge clk);
        end
        rd_reg   = 1'b0;
        addr_reg = 0;
    end

    always @(posedge clk)
        we_reg <= rd_reg;

    assign wren        = we_reg;
    assign we          = 9'h1ff;
    assign mlpram_we   = 9'h00;
    assign wraddrhi    = (addr_reg -1);
    assign mlpram_din  = 72'h0;
    assign mlpram_dout = 72'h0;  // An input named dout!
    assign din         = we_reg ? (~addr_reg[0] ? bram_out[143:72] : bram_out[71:0]) : 72'hdeadbeef012345678;

    // BRAM72K control signals
    // Currently load memory from a file, tie off inputs
    assign wrmsel     = 1'b0;   // LRAM or higher address area
    assign rdmsel     = 1'b0;   // LRAM or higher address area

    // Believe this to be the read address
    assign rdaddrhi = bram_addr_even;

    assign rden        = 1'b1;

    // Should be ignored as no register on output
    assign outreg_rstn   = reset_n;
    assign outlatch_rstn = reset_n;
    assign outreg_ce     = 1'b1;


    wire [13:0] fwdi_ram_wr_addr;
    wire [6:0] fwdi_ram_wblk_addr;
    wire [17:0] fwdi_ram_we;
    wire fwdi_ram_wren;
    wire [143:0] fwdi_ram_wr_data;
    wire [13:0] fwdi_ram_rd_addr;
    wire [6:0] fwdi_ram_rblk_addr;
    wire fwdi_ram_rden;
    wire fwdi_ram_rdmsel;
    wire fwdi_ram_wrmsel;

    wire [13:0] revi_ram_rd_addr;
    wire [6:0] revi_ram_rblk_addr;
    wire revi_ram_rden;
    wire [143:0] revi_ram_rd_data;
    wire revi_ram_rdval;
    wire revi_ram_rdmsel;
    wire [6:0] revi_rblk_addr;
    wire [6:0] revi_wblk_addr;

    wire [71:0] bram_dout;
    wire [71:0] bram72k_dout;
    wire bram_sbit_error;
    wire bram_dbit_error;
    wire bram_full;
    wire bram_almost_full;
    wire bram_empty;
    wire bram_almost_empty;
    wire bram_write_error;
    wire bram_read_error;

    wire [13:0] revo_ram_rd_addr;
    wire [6:0] revo_ram_rblk_addr;
    wire revo_ram_rden;
    wire revo_ram_rdmsel;
    wire [143:0] revo_ram_rd_data;
    wire revo_ram_rdval;
    wire [6:0] revo_rblk_addr;
    wire [6:0] revo_wblk_addr;

    wire [13:0] fwdo_ram_wr_addr;
    wire [6:0] fwdo_ram_wblk_addr;
    wire [17:0] fwdo_ram_we;
    wire fwdo_ram_wren;
    wire [143:0] fwdo_ram_wr_data;
    wire [13:0] fwdo_ram_rd_addr;
    wire [6:0] fwdo_ram_rblk_addr;
    wire fwdo_ram_rden;
    wire fwdo_ram_rdmsel;
    wire fwdo_ram_wrmsel;

    wire [71:0] mlpram_din2mlpdin;
    wire [143:0] mlpram_dout2mlp;

    ACX_BRAM72K #(
        .read_width                     (4'b0010)  // 144 bit read
    ) i_bram (
        .wrclk                          (clk),
        .rdclk                          (clk),
        .din                            (din),
        .we                             (we),
        .wrmsel                         (wrmsel),
        .rdmsel                         (rdmsel),
        .wren                           (wren),
        .wraddrhi                       (wraddrhi),
        .rden                           (rden),
        .rdaddrhi                       (rdaddrhi),
        .outreg_rstn                    (outreg_rstn),
        .outlatch_rstn                  (outlatch_rstn),
        .outreg_ce                      (outreg_ce),

        .fwdi_ram_wr_addr               (fwdi_ram_wr_addr),
        .fwdi_ram_wblk_addr             (fwdi_ram_wblk_addr),
        .fwdi_ram_we                    (fwdi_ram_we),
        .fwdi_ram_wren                  (fwdi_ram_wren),
        .fwdi_ram_wr_data               (fwdi_ram_wr_data),
        .fwdi_ram_rd_addr               (fwdi_ram_rd_addr),
        .fwdi_ram_rblk_addr             (fwdi_ram_rblk_addr),
        .fwdi_ram_rden                  (fwdi_ram_rden),
        .fwdi_ram_rdmsel                (fwdi_ram_rdmsel),
        .fwdi_ram_wrmsel                (fwdi_ram_wrmsel),
        .revi_ram_rd_addr               (revi_ram_rd_addr),
        .revi_ram_rblk_addr             (revi_ram_rblk_addr),
        .revi_ram_rden                  (revi_ram_rden),
        .revi_ram_rd_data               (revi_ram_rd_data),
        .revi_ram_rdval                 (revi_ram_rdval),
        .revi_ram_rdmsel                (revi_ram_rdmsel),
        .revi_rblk_addr                 (revi_rblk_addr),
        .revi_wblk_addr                 (revi_wblk_addr),

        .mlpram_din                     (mlpram_din),
        .mlpram_dout                    (mlpram_dout),
        .mlpram_we                      (mlpram_we),
        .dout                           (bram72k_dout),
        .sbit_error                     (bram_sbit_error),
        .dbit_error                     (bram_dbit_error),
        .full                           (bram_full),
        .almost_full                    (bram_almost_full),
        .empty                          (bram_empty),
        .almost_empty                   (bram_almost_empty),
        .write_error                    (bram_write_error),
        .read_error                     (bram_read_error),

        .revo_ram_rd_addr               (revo_ram_rd_addr),
        .revo_ram_rblk_addr             (revo_ram_rblk_addr),
        .revo_ram_rden                  (revo_ram_rden),
        .revo_ram_rdmsel                (revo_ram_rdmsel),
        .revo_ram_rd_data               (revo_ram_rd_data),
        .revo_ram_rdval                 (revo_ram_rdval),
        .revo_rblk_addr                 (revo_rblk_addr),
        .revo_wblk_addr                 (revo_wblk_addr),
        .fwdo_ram_wr_addr               (fwdo_ram_wr_addr),
        .fwdo_ram_wblk_addr             (fwdo_ram_wblk_addr),
        .fwdo_ram_we                    (fwdo_ram_we),
        .fwdo_ram_wren                  (fwdo_ram_wren),
        .fwdo_ram_wr_data               (fwdo_ram_wr_data),
        .fwdo_ram_rd_addr               (fwdo_ram_rd_addr),
        .fwdo_ram_rblk_addr             (fwdo_ram_rblk_addr),
        .fwdo_ram_rden                  (fwdo_ram_rden),
        .fwdo_ram_rdmsel                (fwdo_ram_rdmsel),
        .fwdo_ram_wrmsel                (fwdo_ram_wrmsel),

        .mlpram_mlp_dout                (),
        .mlpram_din2mlpdin              (mlpram_din2mlpdin),
        .mlpram_din2mlpdout             (mlpram_din2mlpdout),
        .mlpram_dout2mlp                (mlpram_dout2mlp),
        .mlpram_rdaddr                  (mlpram_rdaddr),
        .mlpram_wraddr                  (mlpram_wraddr),
        .mlpram_dbit_error              (mlpram_dbit_error),
        .mlpram_rden                    (mlpram_rden),
        .mlpram_sbit_error              (mlpram_sbit_error),
        .mlpram_wren                    (mlpram_wren),
        .mlpclk                         ()
    );

    // As BRAM is configured to double width read, ensure bottom bit of address is 0
    assign bram_addr_even = rd_reg ? {addr_reg[7:1], 1'b0} : {bram_rd_addr[BRAM_ADDR_WIDTH-2:0], 1'b0};

    wire [71:0] bram_out_even = bram[bram_addr_even];
    wire [71:0] bram_out_odd  = bram[bram_addr_even+1];

    // Double width bram output
    // Due to way the MLP is constructed, it used 64 from bottom half and 64 from top half
    always @(posedge clk)
        bram_out <= {bram_out_odd[63:0], bram_out_even[63:0]};

    // Only support memory 0 in this behavioural model
    always @(posedge clk)
        if( bram_wren && (bram_blk_wr_addr == 0) )
            bram[bram_wr_addr]<= {{(72-BRAM_DATA_WIDTH){1'b0}}, bram_din};


    // LRAM, 2306 bits, arranged as 32x72.
    // This can only store 32 results.  For 227x227, matrix 11x11, stride 4, we need 54 results.
    localparam NUM_MULTS = 16;
    
    // Intermediate multiplier results.  As 8x8 = 16 bit result
    reg [15:0]              mult_out [NUM_MULTS-1:0];
    reg [DATA_WIDTH-1:0]    mult_temp;
    reg [DATA_WIDTH-1:0]    sum_mult;
    reg [DATA_WIDTH-1:0]    sum_acc;

    // For now use int8 multiplies
    generate for (genvar ii=0; ii<NUM_MULTS; ii=ii+1 ) begin : gb_mult
        always @(posedge clk)
            mult_out[ii] <= mlp_din[((ii+1)*8)-1:ii*8] * bram_out[((ii+1)*8)-1:ii*8];
    end         
    endgenerate

    integer jj;
    always @(posedge clk)
    begin
        mult_temp = 0;
        for (jj=0; jj<NUM_MULTS; jj=jj+1 )
        begin
            mult_temp = mult_temp + mult_out[jj];
        end
        sum_mult <= mult_temp;
    end

    logic mlp_din_sof_d;

    // Accumulator stage
    always @(posedge clk)
    begin
        mlp_din_sof_d <= mlp_din_sof;
        if( mlp_din_sof_d )
            sum_acc <= 0;
        else
            sum_acc <= sum_acc + sum_mult;
    end

    // Add pipeline to match dot product
    logic [3:0]             data_valid_pipe;
    logic [DATA_WIDTH-1:0]  sum_acc_d;
             
    // Pipeline for valid signal
    always @(posedge clk)
        data_valid_pipe <= {data_valid_pipe[2:0], mlp_din_eof};

    // In our multi-mlp wrapper, we latch the output value with the valid signal
    always @(posedge clk)
        if( data_valid_pipe[2] )
            sum_acc_d <= sum_acc;


    assign dout       = sum_acc_d;
    assign dout_valid = data_valid_pipe[3];

endmodule : tb_mlp_behavioural_16x_int8


