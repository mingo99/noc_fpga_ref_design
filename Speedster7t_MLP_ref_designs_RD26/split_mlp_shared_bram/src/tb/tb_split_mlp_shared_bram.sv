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
// Speedster7t MLP reference designs (RD26)
//      Top level testbench for split_mlp_shared_bram
// ------------------------------------------------------------------


`define INJECT_PAUSE 0  // set to 1 to inject a single pause state

// matrix type
class matrix #(
    parameter  string  name = "",
    parameter  integer int_width = 8,
    parameter  integer num_rows = 1,
    parameter  integer num_cols = 1
);
  logic signed [int_width-1 : 0] val[num_rows-1 : 0][num_cols-1 : 0];

  // read matrix from file. If no file_nm specified, initialize with 0 elements
  function new (
      input string file_nm
  );
    if (file_nm == "")
      begin
        integer r, c;
        for (r = 0; r < num_rows; r = r + 1)
            for (c = 0; c < num_cols; c = c + 1)
                val[r][c] = '0;
      end
    else
        $readmemh(file_nm, val);
  endfunction

  // print the matrix
  task show ();
    integer r, c;
    $display("matrix %s: %0dx%0d", name, num_rows, num_cols);
    for (r = 0; r < num_rows; r = r + 1)
      begin
        for (c = 0; c < num_cols; c = c + 1)
          begin
            $write("%02h ", val[r][c]);
          end
        $write("\n");
      end
    $display("");
  endtask: show

endclass: matrix


// testbench -----------------------------------------------------------------
// ---------------------------------------------------------------------------

`timescale 1ps/1ps

`define TB_TESTNAME tb_split_mlp_shared_bram

module `TB_TESTNAME ();

  // clock -------------------------------------------------------------------
  localparam integer period = 1334;
  integer tick_count = 0;
  reg clk = 0;
  initial
    begin
      forever
      begin
          #(period/2) clk = 1'b1;
          tick_count = tick_count + 1;
          #(period/2) clk = 1'b0;
      end
    end


  // design under test -------------------------------------------------------
  localparam integer num_groups = 4;
  localparam integer index_width = $clog2(num_groups);
  localparam integer bram_a_wr_width = 64;    // 64, 72
  localparam integer bram_a_wraddr_width = 10;
  localparam integer bram_a_rdaddr_width = 9;
  localparam integer bram_b_wr_width = 128;   // 64, 72, 128, 144
  localparam integer bram_b_wraddr_width = (bram_b_wr_width > 72)? 9 : 10;
  localparam integer bram_b_rdaddr_width = 9;
  localparam integer mlp_dout_width = 48;  // or 24/16 for fp24/fp16
  localparam integer result_afull_threshold = 7'h1; // see LRAM documentation
  localparam integer result_aempty_threshold = 7'h2;

  logic [bram_a_wr_width-1 : 0]       bram_a_din;
  logic [bram_a_wraddr_width-1 : 0]   bram_a_wraddr;
  logic                               bram_a_wren;
  logic [index_width-1 : 0]           bram_b_group;
  logic [bram_b_wr_width-1 : 0]       bram_b_din;
  logic [bram_b_wraddr_width-1 : 0]   bram_b_wraddr;
  logic                               bram_b_wren;
  logic [bram_a_rdaddr_width-1 : 0]   bram_a_rdaddr;
  logic [bram_b_rdaddr_width-1 : 0]   bram_b_rdaddr;
  logic                               first;
  logic                               pause;
  logic                               last;
  logic                               result_rden;
  logic                               result_rstn;
  logic                               result_empty;
  logic                               result_full;
  logic                               result_almost_empty;
  logic                               result_almost_full;
  logic signed [mlp_dout_width-1 : 0] result;
  logic                               result_valid;

  split_mlp_shared_bram #(
// only set parameters for RTL sym, not after Synplify/ACE processing
`ifndef ACX_SIM_GATE
`ifndef ACX_SIM_ACE
      .NUM_GROUPS               (num_groups),
      .BRAM_A_WR_WIDTH          (bram_a_wr_width),
      .BRAM_A_WRADDR_WIDTH      (bram_a_wraddr_width),
      .BRAM_B_WR_WIDTH          (bram_b_wr_width),
      .BRAM_B_WRADDR_WIDTH      (bram_b_wraddr_width),
      .RESULT_AFULL_THRESHOLD   (result_afull_threshold),
      .RESULT_AEMPTY_THRESHOLD  (result_aempty_threshold),
      .MLP_DOUT_WIDTH           (mlp_dout_width)
`endif
`endif
  ) DUT (
      // shared clock
      .i_clk                    (clk),
      // bram 'A' write
      .i_bram_a_din             (bram_a_din),
      .i_bram_a_wraddr          (bram_a_wraddr),
      .i_bram_a_wren            (bram_a_wren),
      // bram 'B' write (to selected group)
      .i_bram_b_group           (bram_b_group),
      .i_bram_b_din             (bram_b_din),
      .i_bram_b_wraddr          (bram_b_wraddr),
      .i_bram_b_wren            (bram_b_wren),
      // computation (bram data passed to MLP)
      .i_bram_a_rdaddr          (bram_a_rdaddr),
      .i_bram_b_rdaddr          (bram_b_rdaddr),
      .i_first                  (first),
      .i_pause                  (pause),
      .i_last                   (last),
      // results
      .i_result_rden            (result_rden),
      .i_result_rstn            (result_rstn),
      .o_result_empty           (result_empty),
      .o_result_full            (result_full),
      .o_result_almost_empty    (result_almost_empty),
      .o_result_almost_full     (result_almost_full),
      .o_result                 (result), // in sequence
      .o_result_valid           (result_valid)
  );


  // test data ---------------------------------------------------------------
  localparam file_a_nm = "../../src/mem_init_files/matrix_a.txt";
  localparam file_b_nm = "../../src/mem_init_files/matrix_b.txt";

  localparam integer A_num_rows = 8;
  localparam integer A_num_cols = 32;
  localparam integer B_num_cols = 8;

  matrix #("matrix_a", 8, A_num_rows, A_num_cols) matrix_a;
  matrix #("matrix_b", 8, A_num_cols, B_num_cols) matrix_b;
  matrix #("matrix_c", mlp_dout_width, A_num_rows, B_num_cols) matrix_c;

  // read matrix_a and matrix_b, and set matrix_c to their product
  task read_test_data ();
      integer r, c, i;
      matrix_a = new(file_a_nm);
      matrix_b = new(file_b_nm);
      matrix_c = new("");
      matrix_a.show();
      matrix_b.show();
      // matrix multiplication: matrix_c = matrix_a * matrix_b
      for (r = 0; r < matrix_c.num_rows; r = r + 1)
          for (c = 0; c < matrix_c.num_cols; c = c + 1)
            begin
              logic signed [mlp_dout_width-1 : 0] dot_product;
              dot_product = 0;
              for (i = 0; i < matrix_a.num_cols; i = i + 1)
                  dot_product = dot_product + matrix_a.val[r][i] * matrix_b.val[i][c];
              matrix_c.val[r][c] = dot_product;
            end
      matrix_c.show();
  endtask: read_test_data


  // startup: send data to BRAMs ---------------------------------------------

  // write 'a' matrix to BRAM
  task write_matrix_a ();
      integer r, c, i;
      logic [bram_a_wr_width-1 : 0] a_l, a_h;
      logic [bram_a_wraddr_width-1 : 0] addr;
      addr = 0;
      bram_a_wren = 0;
      for (r = 0; r < matrix_a.num_rows; r = r + 2)
        begin
          for (c = 0; c < matrix_a.num_cols; c = c + 8)
            begin
              for (i = 0; i < 8; i = i + 1)
                begin
                  a_h[i*8 +: 8] = matrix_a.val[r][c+i];
                  a_l[i*8 +: 8] = matrix_a.val[r+1][c+i];
                end
              @(posedge clk)
                begin
                  bram_a_din <= a_l;
                  bram_a_wraddr <= addr;
                  bram_a_wren <= 1'b1;
                end
              addr = addr + 1;
              @(posedge clk)
                begin
                  bram_a_din <= a_h;
                  bram_a_wraddr <= addr;
                  bram_a_wren <= 1'b1;
                end
              addr = addr + 1;
            end
        end
      @(posedge clk)
          bram_a_wren <= 1'b0;
  endtask: write_matrix_a

  // write 'b' matrix to BRAM (transposed), distributed over the groups
  // (each group stores two columns)
  task write_matrix_b ();
      integer r, c, i;
      logic [bram_b_wr_width/2-1 : 0] b_l, b_h;
      logic [index_width-1 : 0] group;
      logic [bram_b_wraddr_width-1 : 0] addr;
      addr = 0;
      group = 0;
      bram_b_wren = 0;
      for (c = 0; c < matrix_b.num_cols; c = c + 2)
        begin
          for (r = 0; r < matrix_b.num_rows; r = r + 8)
            begin
              for (i = 0; i < 8; i = i + 1)
                begin
                  b_h[i*8 +: 8] = matrix_b.val[r+i][c];
                  b_l[i*8 +: 8] = matrix_b.val[r+i][c+1];
                end
              @(posedge clk)
                begin
                  bram_b_group <= group;
                  bram_b_din <= {b_h, b_l};
                  bram_b_wraddr <= addr;
                  bram_b_wren <= 1'b1;
                end
              addr = addr + 1;
            end
          group = group + 1;
          addr = 0;
        end
      @(posedge clk)
          bram_b_wren <= 1'b0;
  endtask: write_matrix_b


  // calculation: generate rd_addr and first/last ----------------------------

  // assuming the BRAMs have been loaded, perform a matrix multiplication
  task matrix_mul ();
      localparam num_mults = 8; // parallel mults for half MLP
      integer num_blocks; // cannot use localparam because depends on matrix_a
      integer r, c, i;
      logic pause_test, do_pause_test;
      logic [bram_a_rdaddr_width-1 : 0] a_rdaddr;
      logic [bram_a_rdaddr_width-1 : 0] a_start;
      logic [bram_b_rdaddr_width-1 : 0] b_rdaddr;
      num_blocks = matrix_a.num_cols / num_mults;
      a_rdaddr = 0;
      b_rdaddr = 0;
      pause = 0;
      do_pause_test = `INJECT_PAUSE; // set to 1 to inject a pause state in the test
      pause_test = 0;
      for (r = 0; r < matrix_a.num_rows; r = r + 2)
        begin
          b_rdaddr = 0;
          a_start = a_rdaddr;
          for (c = 0; c < matrix_b.num_cols; c = c + 2*num_groups)
            begin
              a_rdaddr = a_start;
              i = 0;
              while (i < num_blocks)
                begin
                  $display("MATRIX_MUL r=%0d, c=%0d, i=%0d: a_rdaddr = %0h, b_rdaddr = %0h",
                            r, c, i, a_rdaddr, b_rdaddr);
                  pause_test = (r == 0 && c == 0 && i == 2 && do_pause_test == 1);
                  @(posedge clk)
                    begin
                      bram_a_rdaddr <= a_rdaddr;
                      bram_b_rdaddr <= b_rdaddr;
                      first <= (i == 0);
                      last <= (i+1 >= num_blocks);
                      pause <= pause_test;
                    end
                  do_pause_test = do_pause_test && !pause_test;
                  // If a result_rden or pause is issued, then the current read
                  // input is ignored, so must be repeated the next cycle.
                  // The #1 delay is to let collect_result_group() assign
                  // result_rden before we evaluate it (this is a testbench
                  // issue, not an issue with the design)
                  #1 if (!result_rden && !pause_test)
                    begin
                      a_rdaddr = a_rdaddr + 1;
                      b_rdaddr = b_rdaddr + 1;
                      i = i + 1;
                    end
                end
            end
        end
      @(posedge clk)
        begin
          first <= 0;
          last <= 0;
          pause <= 0;
        end
  endtask: matrix_mul


  // results -----------------------------------------------------------------
  
  // collect two results from each group, corresponding to columns
  // c .. c + 2*num_groups-1. All correspond to row r.
  task collect_result_group (
      input integer r,
      input integer c,
      inout integer num_correct,
      inout integer num_errors
  );
    integer g;
    while (result_empty)
        @(posedge clk) ;
    result_rden <= 1'b1;
    @(posedge clk)
        result_rden <= 1'b0;
    g = 0;
    while (g < 2*num_groups)
        @(posedge clk)
            if (result_valid)
              begin
                logic signed [mlp_dout_width-1 : 0] expected;
                expected = matrix_c.val[r][c];
                if (result == expected)
                  begin
                    $display("CORRECT: result[%0d, %0d] = %6d = %h", r, c, result, result);
                    num_correct = num_correct + 1;
                  end
                else
                  begin
                    $display("ERROR:   result[%0d, %0d] = %6d = %h but expected %6d = %h",
                              r, c, result, result, expected, expected);
                    num_errors = num_errors + 1;
                  end
                g = g + 1;
                c = c + 1;
              end
  endtask: collect_result_group

  // collect all results from the matrix multiplication
  task collect_results ();
      integer r, c, r2;
      integer num_correct, num_errors;
      num_correct = 0;
      num_errors = 0;
      for (r = 0; r < matrix_a.num_rows; r = r + 2)
        begin
          for (c = 0; c < matrix_b.num_cols; c = c + 2*num_groups)
            begin
              for (r2 = 0; r2 < 2; r2 = r2 + 1)
                begin
                  collect_result_group(r+r2, c, num_correct, num_errors);
                end
            end
        end
      $display("");
      $display("%0t : Corrrect results: %0d", $time, num_correct);
      $display("%0t : Wrong results: %0d",    $time, num_errors);

      // Banner message for automated tool checking
      if ( (num_correct !=0) && (num_errors == 0) )
        $display("%0t : Test PASSED", $time );
      else
        $error("Test FAILED");

  endtask: collect_results


  // simulation --------------------------------------------------------------
  initial
  begin
      $display("---------- SIMULATION START ----------");
      read_test_data();
      bram_a_rdaddr = '0;
      bram_b_rdaddr = '0;
      first = 1'b0;
      pause = 1'b0;
      last = 1'b0;
      result_rden = 1'b0;
      result_rstn = 1'b1;
      #5000 ;
      @(clk) ;
      fork
          write_matrix_a();
          write_matrix_b();
      join
      // for debugging it may be easier to remove this fork/join, and do the
      // actions in sequence instead of in parallel:
      fork
          matrix_mul();
          collect_results();
      join
      #15000;
      $display("---------- SIMULATION END ------------");
      $finish;
  end


  // save waveform data ------------------------------------------------------
  initial
  begin
      `ifdef VCS
          $vcdplusfile("sim_output_pluson.vpd");  
          $vcdpluson(0,`TB_TESTNAME);
      `elsif MODEL_TECH   // Defined by QuestaSim
          // WLF filename is set by using the -wlf option to vsim
          // or else in the modelsim.ini file.
          $wlfdumpvars(0, `TB_TESTNAME);
          `ifdef SIMSTEP_fullchip_bs
              $wlfdumpvars(0,`TB_TESTNAME.DUT);
          `endif
      `endif
  end

endmodule : `TB_TESTNAME

                                
