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
//  Description: Creates instance of split_mlp_shared_bram_stack for
//               placement and simulation.
//
//   NOTE: This is not the user macro: use split_mlp_shared_bram_stack instead
//
// ----------------------------------------------------------------------

`timescale 1ps/1ps
module split_mlp_shared_bram #(
    parameter  integer NUM_GROUPS               = 4,          // <= 32 for AC7t1500
    localparam integer INDEX_WIDTH              = $clog2(NUM_GROUPS),
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
    input  wire                             i_bram_a_wren,
    // bram 'B' write (to selected group)
    input  wire [INDEX_WIDTH-1 : 0]         i_bram_b_group,
    input  wire [BRAM_B_WR_WIDTH-1 : 0]     i_bram_b_din,
    input  wire [BRAM_B_WRADDR_WIDTH-1 : 0] i_bram_b_wraddr,
    input  wire                             i_bram_b_wren,
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
    output wire [MLP_DOUT_WIDTH-1 : 0]      o_result, // in sequence
    output wire                             o_result_valid
);

  /********** input/output registers *****************************************/
  // Put registers at inputs and outputs, to get more realistic timing. This
  // does increase the latency from/to the testbench.

  (* syn_allow_retiming=0, must_keep=1 *) reg [BRAM_A_WR_WIDTH-1 : 0]     reg_bram_a_din;
  (* syn_allow_retiming=0, must_keep=1 *) reg [BRAM_A_WRADDR_WIDTH-1 : 0] reg_bram_a_wraddr;
  (* syn_allow_retiming=0, must_keep=1 *) reg                             reg_bram_a_wren;
  (* syn_allow_retiming=0, must_keep=1 *) reg [INDEX_WIDTH-1 : 0]         reg_bram_b_group;
  (* syn_allow_retiming=0, must_keep=1 *) reg [BRAM_B_WR_WIDTH-1 : 0]     reg_bram_b_din;
  (* syn_allow_retiming=0, must_keep=1 *) reg [BRAM_B_WRADDR_WIDTH-1 : 0] reg_bram_b_wraddr;
  (* syn_allow_retiming=0, must_keep=1 *) reg                             reg_bram_b_wren;
  (* syn_allow_retiming=0, must_keep=1 *) reg [BRAM_A_RDADDR_WIDTH-1 : 0] reg_bram_a_rdaddr;
  (* syn_allow_retiming=0, must_keep=1 *) reg [BRAM_B_RDADDR_WIDTH-1 : 0] reg_bram_b_rdaddr;
  (* syn_allow_retiming=0, must_keep=1 *) reg                             reg_first;
  (* syn_allow_retiming=0, must_keep=1 *) reg                             reg_pause;
  (* syn_allow_retiming=0, must_keep=1 *) reg                             reg_last;
  (* syn_allow_retiming=0, must_keep=1 *) reg                             reg_result_rden;
  (* syn_allow_retiming=0, must_keep=1 *) reg                             reg_result_rstn;
  (* syn_allow_retiming=0, must_keep=1 *) reg                             reg_result_empty;
  (* syn_allow_retiming=0, must_keep=1 *) reg                             reg_result_full;
  (* syn_allow_retiming=0, must_keep=1 *) reg                             reg_result_almost_empty;
  (* syn_allow_retiming=0, must_keep=1 *) reg                             reg_result_almost_full;
  (* syn_allow_retiming=0, must_keep=1 *) reg [MLP_DOUT_WIDTH-1 : 0]      reg_result; // in sequence
  (* syn_allow_retiming=0, must_keep=1 *) reg                             reg_result_valid;


  wire                        result_empty;
  wire                        result_full;
  wire                        result_almost_empty;
  wire                        result_almost_full;
  wire [MLP_DOUT_WIDTH-1 : 0] result;
  wire                        result_valid;


  always @(posedge i_clk)
  begin
      reg_bram_a_din            <= i_bram_a_din;
      reg_bram_a_wraddr         <= i_bram_a_wraddr;
      reg_bram_a_wren           <= i_bram_a_wren;
      reg_bram_b_group          <= i_bram_b_group;
      reg_bram_b_din            <= i_bram_b_din;
      reg_bram_b_wraddr         <= i_bram_b_wraddr;
      reg_bram_b_wren           <= i_bram_b_wren;
      reg_bram_a_rdaddr         <= i_bram_a_rdaddr;
      reg_bram_b_rdaddr         <= i_bram_b_rdaddr;
      reg_first                 <= i_first;
      reg_pause                 <= i_pause;
      reg_last                  <= i_last;
      reg_result_rden           <= i_result_rden;
      reg_result_rstn           <= i_result_rstn;

      reg_result_empty          <= result_empty;
      reg_result_full           <= result_full;
      reg_result_almost_empty   <= result_almost_empty;
      reg_result_almost_full    <= result_almost_full;
      reg_result                <= result;
      reg_result_valid          <= result_valid;
  end

  assign o_result_empty        = reg_result_empty;
  assign o_result_full         = reg_result_full;
  assign o_result_almost_empty = reg_result_almost_empty;
  assign o_result_almost_full  = reg_result_almost_full;
  assign o_result              = reg_result;
  assign o_result_valid        = reg_result_valid;


  /********** writing 'B' BRAMs ***********************************************/

  // split_mlp_shared_bram_stack allows independent parallel writes to
  // the 'B' BRAMs, but to reduce the number of inputs during testing we fan
  // the same data out to all BRAMs, and select only one with bram_b_group.
  
  localparam B_PIPELINE_DEPTH = 3; // for timing

  wire [BRAM_B_WR_WIDTH-1 : 0]     bram_b_din;
  wire [BRAM_B_WRADDR_WIDTH-1 : 0] bram_b_wraddr;
  (* syn_preserve=1, must_keep=1 *)
  reg  [BRAM_B_WR_WIDTH-1 : 0]     bram_b_din_d[NUM_GROUPS-1 : 0];
  (* syn_preserve=1, must_keep=1 *)
  reg  [BRAM_B_WRADDR_WIDTH-1 : 0] bram_b_wraddr_d[NUM_GROUPS-1 : 0];
  wire [NUM_GROUPS-1 : 0]          bram_b_wren_selected;
  wire [NUM_GROUPS-1 : 0]          bram_b_wren;

  for (genvar i = 0; i < NUM_GROUPS; i = i + 1)
    begin
      assign bram_b_wren_selected[i] = (reg_bram_b_group == i)? reg_bram_b_wren : 1'b0;
    end

  pipeline #(
      .width    (BRAM_B_WR_WIDTH + BRAM_B_WRADDR_WIDTH),
      .depth    (B_PIPELINE_DEPTH-1)
  ) u_pipeline_bram_b_data (
      .i_clk    (i_clk),
      .i_din    ({reg_bram_b_din, reg_bram_b_wraddr}),
      .o_dout   ({bram_b_din, bram_b_wraddr})
  );

  // separate register for last pipeline stage, to meet timing
  for (genvar i = 0; i < NUM_GROUPS; i = i + 1)
    begin
      always @(posedge i_clk)
      begin
          bram_b_din_d[i]    <= bram_b_din;
          bram_b_wraddr_d[i] <= bram_b_wraddr;
      end
    end

  pipeline #(
      .width    (NUM_GROUPS),
      .depth    (B_PIPELINE_DEPTH)
  ) u_pipeline_bram_b_wren (
      .i_clk    (i_clk),
      .i_din    (bram_b_wren_selected),
      .o_dout   (bram_b_wren)
  );


  /********** reading results *************************************************/

  // split_mlp_shared_bram_stack outputs the results of all MLPs in parallel,
  // but to reduce the number of outputs during testing we sequence these
  // results with a pipeline. Since the results are produced in a staggered
  // fashion from the bottom to the top, and the result pipeline moves from
  // top to bottom, the results are separated by an undefined value.

  wire [MLP_DOUT_WIDTH-1 : 0] result_1[NUM_GROUPS-1 : 0]; // from group
  wire [NUM_GROUPS-1 : 0]     result_1_valid;
  wire [MLP_DOUT_WIDTH-1 : 0] result_0[NUM_GROUPS-1 : 0];
  wire [NUM_GROUPS-1 : 0]     result_0_valid;

  wire [MLP_DOUT_WIDTH-1 : 0] group_chain_result[NUM_GROUPS : 0]; // between groups
  wire [NUM_GROUPS : 0]     group_chain_result_valid;

  assign group_chain_result[NUM_GROUPS]       = {MLP_DOUT_WIDTH {1'b0}};
  assign group_chain_result_valid[NUM_GROUPS] = 1'b0;
  assign result                               = group_chain_result[0];
  assign result_valid                         = group_chain_result_valid[0];

  for (genvar i = 0; i < NUM_GROUPS; i = i + 1)
    begin: result_chain
      reg [MLP_DOUT_WIDTH-1 : 0] chain_result_1;
      reg                        chain_result_1_valid;
      reg [MLP_DOUT_WIDTH-1 : 0] chain_result_0;
      reg                        chain_result_0_valid;

      always @(posedge i_clk)
        begin
          chain_result_1 <= result_1_valid[i]? result_1[i]
                                             : group_chain_result[i+1];
          chain_result_1_valid <= result_1_valid[i] | group_chain_result_valid[i+1];
          chain_result_0 <= result_0_valid[i]? result_0[i]
                                             : chain_result_1;
          chain_result_0_valid <= result_0_valid[i] | chain_result_1_valid;
        end

      assign group_chain_result[i]       = chain_result_0;
      assign group_chain_result_valid[i] = chain_result_0_valid;
    end


  /********** main ************************************************************/

  wire [BRAM_B_WE_WIDTH-1 : 0] bram_b_we = {BRAM_B_WE_WIDTH {1'b1}};

  split_mlp_shared_bram_stack #(
      .NUM_GROUPS               (NUM_GROUPS),
      .BRAM_A_WR_WIDTH          (BRAM_A_WR_WIDTH),
      .BRAM_A_WRADDR_WIDTH      (BRAM_A_WRADDR_WIDTH),
      .BRAM_B_WR_WIDTH          (BRAM_B_WR_WIDTH),
      .BRAM_B_WRADDR_WIDTH      (BRAM_B_WRADDR_WIDTH),
      .MLP_DOUT_WIDTH           (MLP_DOUT_WIDTH),
      .RESULT_AFULL_THRESHOLD   (RESULT_AFULL_THRESHOLD),
      .RESULT_AEMPTY_THRESHOLD  (RESULT_AEMPTY_THRESHOLD)
  ) u_split_mlp_shared_bram_stack (
      // shared clock
      .i_clk                    (i_clk),
      // bram 'A' write
      .i_bram_a_din             (reg_bram_a_din),
      .i_bram_a_wraddr          (reg_bram_a_wraddr),
      .i_bram_a_wrmsel          (1'b0),
      .i_bram_a_wren            (reg_bram_a_wren),
      .i_bram_a_we              ({BRAM_A_WE_WIDTH {1'b1}}),
      // bram 'B' write (per group)
      .i_bram_b_din             (bram_b_din_d),
      .i_bram_b_wraddr          (bram_b_wraddr_d),
      .i_bram_b_wrmsel          ({NUM_GROUPS {1'b0}}),
      .i_bram_b_wren            (bram_b_wren),
      .i_bram_b_we              ('{NUM_GROUPS {bram_b_we}}),
      // bram 'A' read (data passed via MLP cascade)
      .i_bram_a_rdaddr          (reg_bram_a_rdaddr),
      .i_bram_b_rdaddr          (reg_bram_b_rdaddr),
      .i_first                  (reg_first),
      .i_pause                  (reg_pause),
      .i_last                   (reg_last),
      // results
      .i_result_rden            (reg_result_rden),
      .i_result_rstn            (reg_result_rstn),
      .o_result_empty           (result_empty),
      .o_result_full            (result_full),
      .o_result_almost_empty    (result_almost_empty),
      .o_result_almost_full     (result_almost_full),
      .o_result_1               (result_1),
      .o_result_1_valid         (result_1_valid),
      .o_result_0               (result_0),
      .o_result_0_valid         (result_0_valid)
  );



endmodule : split_mlp_shared_bram
