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
// 2D convolution top structure
//      Currently uses behavioural models
//      Will use real parts as they become available
// ------------------------------------------------------------------

`include "7t_interfaces.svh"

module mlp_conv2d_top
#(
    // Tensor flow parameters for 2D conv
    parameter   BATCH               = 4,
    parameter   IN_HEIGHT           = 227,
    parameter   IN_WIDTH            = 227,
    parameter   IN_CHANNELS         = 3,
    parameter   FILTER_HEIGHT       = 11,
    parameter   FILTER_WIDTH        = 11,
    parameter   OUT_CHANNELS        = 1,

    parameter   INF_DATA_WIDTH      = 144
)
(
    // Inputs
    input  wire                         i_clk,
    input  wire                         i_reset_n,      // Negative synchronous reset
    input  wire                         pll_1_lock,     // Reference PLL locked
    input  wire                         pll_2_lock,     // System PLL locked
    // Outputs
    output wire                         o_conv_done,    // Indicate when current convolution is complete
    output wire                         o_conv_done_oe, // Associated output enable
    output wire                         o_error,        // Indicates a write bresp error
    output wire                         o_error_oe      // Associated output enable
);

    // Check batch size is within limits.  The maximum this design can support is 60
    generate if (BATCH > 60) begin : gb_batch_overflow
        ERROR_batch_size_greater_than_60();
    end
    endgenerate

    // Fix output enables to always be on
    assign o_conv_done_oe = 1'b1;
    assign o_error_oe     = 1'b1;

    // Local parameter values
    localparam INF_ADDR_WIDTH      = 10;    // 227x(11+4) = 3.5KB.  Needs to be 144 bits wide
    localparam MLP_BRAM_ADDR_WIDTH = 10;
    localparam MLP_BRAM_DATA_WIDTH = 64;
    localparam MLP_OUT_DATA_WIDTH  = 48;
    localparam NAP_DATA_WIDTH      = 256;
    localparam NAP_ADDR_WIDTH      = 42;
    localparam GDDR_ADDR_WIDTH     = 30;            // 8Gb = 1GB
    localparam GDDR_ADDR_ID        = 9'b00000_0000; // 5'b0, CTRL_ID
    localparam MAX_COLS            = 4;

    // Function communicates to DDR via AXI_SLAVE primitive
    // AXI_SLAVE is on NOC, and connects to DDR.
    // Testbench emulates this by probing nap in this interface

    // Instantiate AXI_4 interfaces for nap in and out
    t_AXI4 #(
        .DATA_WIDTH (NAP_DATA_WIDTH),
        .ADDR_WIDTH (NAP_ADDR_WIDTH),
        .LEN_WIDTH  (8) )
    nap_in();

    t_AXI4 #(
        .DATA_WIDTH (NAP_DATA_WIDTH),
        .ADDR_WIDTH (NAP_ADDR_WIDTH),
        .LEN_WIDTH  (8) )
    nap_out();

    wire                        output_rstn_nap_in;
    wire                        error_valid_nap_in;
    wire [2:0]                  error_info_nap_in;
    wire                        output_rstn_nap_out;
    wire                        error_valid_nap_out;
    wire [2:0]                  error_info_nap_out;


    // NAP operates at the user design frequency, and with the user design reset.
    // Instantiate slave and connect ports to SV interface
    nap_slave_wrapper i_axi_slave_wrapper_in (
        .i_clk	            (i_clk),
        .i_reset_n          (i_reset_n),    // In later releases this will use sys_rstn.
                                            // Current bug in NAP means that it needs to be
                                            // released from reset several cycles before it is
                                            // accessed.  So use early reset signal
        .nap    	        (nap_in),
        .o_output_rstn      (output_rstn_nap_in),
        .o_error_valid      (error_valid_nap_in),
        .o_error_info       (error_info_nap_in)
    );

    nap_slave_wrapper i_axi_slave_wrapper_out (
        .i_clk	            (i_clk),
        .i_reset_n          (i_reset_n),    // In later releases this will use sys_rstn.
                                            // Current bug in NAP means that it needs to be
                                            // released from reset several cycles before it is
                                            // accessed.  So use early reset signal
        .nap    	        (nap_out),
        .o_output_rstn      (output_rstn_nap_out),
        .o_error_valid      (error_valid_nap_out),
        .o_error_info       (error_info_nap_out)
    );

    // Control block
    wire                            in_fifo_wr;
    wire                            in_fifo_rd_en;
    wire  [INF_ADDR_WIDTH-1:0]      in_fifo_rd_addr;
    wire                            in_fifo_wr_addr_reset;
    wire  [INF_DATA_WIDTH-1:0]      in_line_data;

    wire  [MLP_BRAM_ADDR_WIDTH-1:0] bram_wr_addr;
    wire  [7 -1: 0]                 bram_blk_wr_addr;
    wire                            bram_wren;

    wire  [MLP_OUT_DATA_WIDTH-1:0]  mlp_data_out;
    wire                            mlp_data_out_valid;

    t_mlp_out                       mlp_multi_data_out [MAX_COLS -1:0];
    wire  [MAX_COLS -1:0]           mlp_multi_data_out_valid;

    wire  [MLP_BRAM_ADDR_WIDTH-2:0] mlp_matrix_addr;

    wire                            in_line_data_sof;
    wire                            in_line_data_eof;
    wire                            matrix_done;
    wire                            out_fifo_idle;
    wire                            out_fifo_bresp_error;

    // ------------------------
    // Create internal resets
    // Need to include PLL lock signals and external resets
    // ------------------------
    logic   sys_rstn;

    reset_processor #(
        .NUM_INPUT_RESETS   (3),    // Three reset sources
        .NUM_OUTPUT_RESETS  (1),    // One clock domain and reset
        .RST_PIPE_LENGTH    (5)     // Set reset pipeline to 5 stages
    ) i_reset_processor (
        .i_rstn_array       ({i_reset_n, pll_1_lock, pll_2_lock}),
        .i_clk              (i_clk),
        .o_rstn_array       (sys_rstn)
    );

    assign o_error = out_fifo_bresp_error;

    // Correct finish signal could be more complex.
    // Assign to port as this is then present in synthesised netlist for full chip sim
    assign o_conv_done = matrix_done & out_fifo_idle;

    dataflow_control #(
//        .BATCH                  (BATCH),
        .BATCH                  (16),   // To enable a self-checking testbench, currently write same data in each column
                                        // A user would want to set the BATCH parameter to the top level BATCH parameter.
        .IN_HEIGHT              (IN_HEIGHT),
        .IN_WIDTH               (IN_WIDTH),
        .IN_CHANNELS            (IN_CHANNELS),
        .FILTER_HEIGHT          (FILTER_HEIGHT),
        .FILTER_WIDTH           (FILTER_WIDTH),
        .OUT_CHANNELS           (OUT_CHANNELS),

        .DATA_WIDTH             (INF_DATA_WIDTH),
        .GDDR_ADDR_WIDTH        (GDDR_ADDR_WIDTH),
        .GDDR_ADDR_ID           (GDDR_ADDR_ID),
        .INF_ADDR_WIDTH         (INF_ADDR_WIDTH)
    ) i_control (
        // Inputs
        .i_clk                  (i_clk),
        .i_reset_n              (sys_rstn),
        .nap_in                 (nap_in),
        .i_mlp_dout_valid       (mlp_data_out_valid),

        // Outputs
        .o_bram_wr_addr         (bram_wr_addr),
        .o_bram_blk_wr_addr     (bram_blk_wr_addr),
        .o_bram_wren            (bram_wren),

        .o_in_fifo_wr           (in_fifo_wr),
        .o_in_fifo_wr_addr_reset (in_fifo_wr_addr_reset),
        .o_in_fifo_rd_en        (in_fifo_rd_en),
        .o_in_fifo_rd_addr      (in_fifo_rd_addr),
        .o_mlp_matrix_addr      (mlp_matrix_addr),

        .o_mlp_din_sof          (in_line_data_sof),
        .o_mlp_din_eof          (in_line_data_eof),
        .o_matrix_done          (matrix_done)
    );

    // Instantiate input memory, large enough to store whole image.
    // Plays out as sets of lines
    line_fifo #(
        .DATA_WIDTH             (INF_DATA_WIDTH),
        .ADDR_WIDTH             (INF_ADDR_WIDTH)

    ) i_in_fifo (
        // Inputs
        .i_clk                  (i_clk),
        .i_reset_n              (sys_rstn),
        .i_wr_en                (in_fifo_wr),
        .i_wr_addr_reset        (in_fifo_wr_addr_reset),
        .i_data_in              (nap_in.rdata[INF_DATA_WIDTH-1:0]),

        .i_rd_en                (in_fifo_rd_en),
        .i_rd_addr              (in_fifo_rd_addr),

        // Outputs
        .o_data_out             (in_line_data)
    );


`ifdef SIMULATION
    // Instantiate MLP behavioural model
    // Used in development to compare calculation results on the fly
    // Full verification of the design is done at the top level testbench using
    // golden reference data files
    tb_mlp_behavioural_16x_int8 #(
        .DATA_WIDTH             (MLP_OUT_DATA_WIDTH),
        .BRAM_ADDR_WIDTH        (MLP_BRAM_ADDR_WIDTH)    // 72w x 1K deep
    ) i_mlp_beh (
        // Inputs
        .clk                    (i_clk),
        .reset_n                (sys_rstn),
        .mlp_din                (in_line_data),
        .mlp_din_sof            (in_line_data_sof),
        .mlp_din_eof            (in_line_data_eof),
        .bram_rd_addr           (mlp_matrix_addr),
        .bram_blk_wr_addr       (bram_blk_wr_addr),

        // Write to BRAM
        .bram_wr_addr           (bram_wr_addr),
        .bram_din               (nap_in.rdata[MLP_BRAM_DATA_WIDTH-1:0]),
        .bram_wren              (bram_wren),

        // Outputs
        .dout                   (mlp_data_out),
        .dout_valid             (mlp_data_out_valid)
    );

`endif


    mlp_wrapper_multi #(
        .IN_DATA_WIDTH          (INF_DATA_WIDTH),
        .BRAM_ADDR_WIDTH        (MLP_BRAM_ADDR_WIDTH),    // 72w x 1K deep
        .NUM_MLP                (BATCH),
        .MAX_COLS               (MAX_COLS)
    ) i_mlp_multi (
        // Inputs
        .clk                    (i_clk),
        .reset_n                (sys_rstn),
        .mlp_din                (in_line_data),
        .mlp_din_sof            (in_line_data_sof),
        .mlp_din_eof            (in_line_data_eof),
        .bram_rd_addr           (mlp_matrix_addr),

        // Write to BRAM
        .bram_wr_addr           (bram_wr_addr),
        .bram_blk_wr_addr       (bram_blk_wr_addr),

        .bram_din               (nap_in.rdata[MLP_BRAM_DATA_WIDTH-1:0]),
        .bram_wren              (bram_wren),

        // Outputs
        .dout                   (mlp_multi_data_out),
        .dout_valid             (mlp_multi_data_out_valid)
    );


    // Instantiate input memory, configured as a number of line fifos
    out_fifo #(
        .DATA_WIDTH             (NAP_DATA_WIDTH),
        .GDDR_ADDR_WIDTH        (GDDR_ADDR_WIDTH),
        .GDDR_ADDR_ID           (GDDR_ADDR_ID),
        .NUM_MLP                (BATCH),
        .MAX_COLS               (MAX_COLS)
    ) i_out_fifo (
        // Inputs
        .i_clk                  (i_clk),
        .i_reset_n              (sys_rstn),
        .i_data_in              (mlp_multi_data_out),
        .i_wr_en                (mlp_multi_data_out_valid),
        .nap_out                (nap_out),

        // Outputs
        .o_idle                 (out_fifo_idle),        // Indicates no AXI transitions
        .o_bresp_error          (out_fifo_bresp_error)
    );

endmodule : mlp_conv2d_top

