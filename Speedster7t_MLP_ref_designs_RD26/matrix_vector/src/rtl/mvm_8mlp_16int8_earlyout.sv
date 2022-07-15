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
//  Description: Matrix-vector multiply with 8 MLPs (4x mode); 256x256 matrix
//
///////////////////////////////////////////////////////////////////////////////

// Performs a matrix-vector multiplication, with a VxV matrix and a Vx1
// vector. Elements are int8.
//
// The matrix is stored in BRAM with Bw values per write (64-bit write; could
// be made twice as wide).
//
// The MLP operates in double-wide mode (16 multipliers). The vector is
// stored in LRAM, via the MLP cascade, and the MLP takes its multiplier
// inputs from the LRAM. One row-vector dot-product is computed at a time,
// using all MLPs, where the output cascade is used to do the accumulation.
//
// Output values are produced one value every two cycles. The first output
// is produced soon after the vector has been read in. Note that the entire
// vector is needed before computation starts.
//
// The current design works for the specific value of V only. However, it could
// easily be modified to allow smaller matrices/vectors as well, though in
// most cases that would be less efficient due to not all multipliers being
// used. However, (with modifications) V/2 would have the same efficiency,
// just with a quarter the latency.
//
// The interface for filling the BRAM simply takes the matrix in row-major
// order, and internally generates the addresses to distribute the data
// correctly. The vector input uses i_first and i_last to delimit the vector.
// Both matrix and vector input interfaces allow pausing the input when
// data is temporarily unavailable, as is needed when interfacing with external
// memory (via the NAP).
//

`timescale 1 ps / 1 ps

module mvm_8mlp_16int8_earlyout #(
    localparam integer      V = 256,        // VxV matrix
    localparam integer      M = 8,          // number BRAMs, number MLPs
    localparam integer      N = 8,          // integer size
    localparam integer      B = 16,         // block size (number parallel multiplies)
    localparam integer      Bw = 8,         // block size for writing BRAM
    localparam integer      S = 48          // bits in result
) (
    input  wire              i_clk,
    // matrix inputs
    input  wire [Bw*N-1 : 0] i_matrix,      // Bw N-bit integers (2's compl)
    input  wire              i_matrix_wren, // while writing matrix data
    input  wire              i_matrix_wrpause, // pause writing
    // vector inputs
    input  wire [B*N-1 : 0]  i_v,           // B N-bit integers (2's compl)
    input  wire              i_first,       // high for first vector item
    input  wire              i_last,        // high for last vector item
    input  wire              i_pause,       // ignore i_v
    // output data
    output wire [S-1 : 0]    o_sum,         // output vector item (2's compl)
    output wire              o_first,       // high for first output item
    output wire              o_last,        // high for last output item
    output wire              o_pause        // high when o_sum should be ignored
);

  localparam integer W = Bw*N;    // write width (wrblock size)
  localparam integer A = 10;      // native address width
  localparam integer Ablk = 7;    // block address width
  localparam integer R = B*N;     // read width (rdblock size)
  localparam integer Ar = A-1;    // read address width


  wire [B*N/2-1 : 0] v_lo = i_v[0 +: B*N/2];
  wire [B*N/2-1 : 0] v_hi = i_v[B*N/2 +: B*N/2];


  /********** BRAM wraddr generation ******************************************/

  localparam integer ROW_WRBLOCKS = V / Bw; // wrblocks per row
  localparam integer ROW_RDBLOCKS = V / B;  // rdblocks per row

  // Each row consists of ROW_WRBLOCKS words of W bits. These are distributed
  // over the BRAMs in such a way that they match the distribution of vector
  // rdblocks over LRAMs. Note that the LRAMs store rdblocks.
  // In term of rdblocks, we write from BRAM[M-1] to BRAM[0], all at the
  // same address, then repeat. Whenever we start at BRAM[M-1] again, we
  // increment the address.
  // However, because we need to write two wrblocks for each rdblock, we
  // actually do two writes to each BRAM before moving to the next BRAM.
  reg               wr_lsb;         // count wrblocks per rdblock
  reg  [A-1 : 1]    wr_base;        // address without lsb
  reg  [Ablk-1 : 0] wrblk_addr;     // write bram[wrblk_addr]
  wire [A-1 : 0]    wraddr = {wr_base, wr_lsb};

  wire [Ablk : 0]   wrblk_addr_next = wrblk_addr - 1'b1;   

  always @(posedge i_clk)
  begin
      if (!i_matrix_wren)
        begin
          wr_lsb <= 1'b0;
          wr_base <= {A-1 {1'b0}};
          wrblk_addr <= Ablk'(M-1);
        end
      else if (!i_matrix_wrpause)
        begin
          wr_lsb <= ~wr_lsb;
          if (wr_lsb)
            begin
              if (wrblk_addr_next[Ablk]) // same as wrblk_addr == 0
                begin
                  wrblk_addr <= Ablk'(M-1);
                  wr_base <= wr_base + 1'b1;
                end
              else
                  wrblk_addr <= wrblk_addr_next[0 +: Ablk];
            end
        end
  end

  
  /********** BRAM/LRAM rdaddr generation *************************************/
 
  // LRAM: The first read (of LRAM[0]) can overlap with the last write
  // (of LRAM[1]), because they are to different addresses. i_last is one
  // cycle ahead of the last write (because the wrdata was delayed by the
  // mlp stage0 register), so we start reading the cycle after i_last.
  // Each LRAM has its own rdaddr counter, which we synchronize with
  // lram_reading. This is set low when we have read sufficient values, to
  // prevent generating too many sum_valid events.
  // 
  // BRAM: The BRAM always has an extra cycle latency relative to the LRAM,
  // and we also have enabled the BRAM input register (del_fwdi_ram_rd_addr).
  // Therefore, the BRAM should start reading two cycles before the LRAM.
  // This is done by counting from i_first: we initialize the rdaddr counter
  // so it is at 0 when reading should start.

  localparam integer COUNT_INIT = - (V / B - 3);        // to align bram_raddr = 0
  // number of operations for MLP = (blocks per row) * (rows per BRAM):
  localparam integer NUM_OPS = (V / B) * (V / M);
  localparam integer MLP_LATENCY = 3;                   // stage1, stage2, stage4
  localparam integer TOTAL_CYCLES = V/B + MLP_LATENCY + M - 1 + NUM_OPS;
  localparam integer COUNT_MAX = TOTAL_CYCLES - 1 + COUNT_INIT - 1;
  localparam integer COUNT_BITS = $clog2(COUNT_MAX);

  reg                           computing = 1'b0;       // matrix-vector mult ongoing
  reg                           lram_reading = 1'b0;    // values are being read from LRAM[0]
  reg signed [COUNT_BITS : 0]   cycle_count;
  wire [Ar-1 : 0]               bram_rdaddr = cycle_count[Ar-1 : 0];
  wire                          sum_valid;              // sum is valid

  reg                           waiting_first = 1'b0;   // waiting for first result
  reg                           output_active = 1'b0;

  // We could more easily count results (sum_valid events) to determine when
  // computing <= 1'b0, but with the help of some timing diagrams we can
  // save the counter and use cycle_count instead.

  // Technically, the negative and positive values of cycle_count don't
  // overlap, so we could have omitted the sign bit.
  always @(posedge i_clk)
  begin
      if (i_first)
          computing <= 1'b1;
      else if (cycle_count == (COUNT_BITS+1)'(COUNT_MAX-1))
          computing <= 1'b0;

      if (!computing)
          cycle_count <= (COUNT_BITS+1)'(COUNT_INIT);
      else if (!i_pause)
          cycle_count <= cycle_count + 1'b1;

      if (i_last)
          lram_reading <= 1'b1;
      else if (cycle_count == (COUNT_BITS+1)'(NUM_OPS + 1)) // --> lram0_rdaddr == num_ops-1
          lram_reading <= 1'b0;

      if (i_last)
          waiting_first <= 1'b1;
      else if (sum_valid)
          waiting_first <= 1'b0;

      if (o_first)
          output_active <= 1'b1;
      else if (o_last)
          output_active <= 1'b0;
  end

  assign o_first = waiting_first && sum_valid;
  assign o_last  = !computing && sum_valid;
  assign o_pause = output_active && !sum_valid;


  /********** BRAM stack ******************************************************/

  wire [B*N/2-1 : 0] bram_din2mlp_din;
  wire [M*B*N-1 : 0] bram_dout2mlp_din;

  bram_deep_w #(
      .M                    (M)
  ) u_bram_deep_w (
      .i_clk                (i_clk),
      // write
      .i_wrdata             (i_matrix),
      .i_wraddr             (wraddr),
      .i_wrblk_addr         (wrblk_addr),
      .i_wren               (i_matrix_wren),
      // read
      .i_rdaddr             (bram_rdaddr),
      .o_bram_dout2mlp_din  (bram_dout2mlp_din),
      // route-through of din for use by mlp
      .i_mlp_data           (v_hi),
      .o_bram_din2mlp_din   (bram_din2mlp_din)
  );

  /********** MLP stack *******************************************************/

  mlp_bram_lramin_casc #(
      .M                    (M)
  ) u_mlp_bram_lramin_casc (
      .i_clk                (i_clk),
      // LRAM write
      .i_wrdata             (v_lo),
      .i_bram_din2mlp_din   (bram_din2mlp_din),     // borrowed bram din -> mlp
      .i_first              (i_first),
      .i_last               (i_last),
      .i_pause              (i_pause),
      // BRAM data
      .i_bram_dout2mlp_din  (bram_dout2mlp_din),    // parallel, direct connect
      // Computation
      .i_read               (lram_reading),
      .o_sum                (o_sum),                // output vector item (2's compl)
      .o_valid              (sum_valid)
  );



endmodule : mvm_8mlp_16int8_earlyout

