//---------------------------------------------------------------------
//  Copyright (c) 2020  Achronix Semiconductor Corp.
//  All Rights Reserved.
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
//---------------------------------------------------------------------
//  Description : Test sequences and functions for matrix maths
//---------------------------------------------------------------------


// V*V int8 matrix to store in BRAMs
matrix #("matrix_m", 8, V, V) matrix_m;

// Test vectors, for convenience stored as rows of a num_tests * V matrix
localparam integer num_tests = 3;
matrix #("vector_v", 8, num_tests, V) vector_v;

parameter string file_matrix_m = "../../src/mem_init_files/matrix_rand.txt";
parameter string file_vector_v = "../../src/mem_init_files/vector_rand.txt";

// Read matrix_m and test vectors (vector_v) from file
task read_test_data ();
    matrix_m = new(file_matrix_m);
    $display("Note: numbers are signed");
    matrix_m.show();
    vector_v = new(file_vector_v);
    $display("Note: each row represents a %0dx1 vector", vector_v.num_cols);
    $display("Note: numbers are signed");
    vector_v.show();   
endtask : read_test_data


// Write matrix_m to the BRAMs. Writing is done in blocks of Bw values.
task write_matrix_to_dut ();
  integer r, c;
  integer pause_cycles;
  logic running;

  $display("----------------------------------------");
  $display("Writing %s (%0dx%0d) to DUT", matrix_m.name, matrix_m.num_rows, matrix_m.num_rows);

  pause_cycles = 3;
  running = 1'b1;

  for (r=0; r < matrix_m.num_rows; r=r+1)
    begin
      for (c=0; c < matrix_m.num_cols; c=c + running*Bw)
        begin
          integer j;

          // Demo: pause 'pause_cycles' cycles when r==2 and c==6*Bw
          if (r == 2 && c == 6*Bw)
            begin
              if (pause_cycles > 0)
                begin
                  $display("pausing");
                  running = 1'b0;
                  pause_cycles = pause_cycles - 1;
                end
              else
                  running = 1'b1;
            end
          // end demo

          @(posedge clk)
            begin
              // send Bw column values per cycle
              $display("  writing %s[%0d][%0d:%0d]", matrix_m.name, r, c+Bw-1, c);
              for (j=0; j < Bw; j=j+1)
                begin
                  tb_i_matrix[j*N +: N] = matrix_m.val[r][c+j];
                end
              tb_i_matrix_wren <= 1'b1;
              tb_i_matrix_wrpause <= !running;
            end
        end // columns loop

    end // rows loop

  @(posedge clk)
    begin
      tb_i_matrix <= {Bw*N {1'bx}};
      tb_i_matrix_wren <= 1'b0;
    end
  $display("End writing %s", matrix_m.name);
endtask : write_matrix_to_dut


// Fill in the 'expected' vector for matrix_m * vector_v[v]
task mvm_expected (
    input integer v
);
  integer r, c;
  logic signed [S-1 : 0] sum;

  for (r = 0; r < matrix_m.num_rows; r = r + 1)
    begin
      sum = {S {1'b0}};
      for (c = 0; c < matrix_m.num_cols; c = c + 1)
        begin
          sum = sum + matrix_m.val[r][c] * vector_v.val[v][c];
        end
      expected[r] = sum;
    end

endtask : mvm_expected


// Write vector_v[v] to DUT
task write_vector_to_dut (
    input integer v
);

  integer c;
  integer pause_cycles;
  logic running;

  $display("----------------------------------------");
  $display("Writing %s[%0d] (%0dx1) to DUT", vector_v.name, v, vector_v.num_cols);

  pause_cycles = 2;
  running = 1'b1;

  tb_i_first <= 1'b0;
  
  for (c=0; c < vector_v.num_cols; c=c + running*B)
    begin
      integer j;

      // demo: pause 'pause_cycles' cycles when r==v and c==5*B
      if (v == 1 && c == 5*B)
        begin
          if (pause_cycles > 0)
            begin
              $display("pausing");
              running = 1'b0;
              pause_cycles = pause_cycles - 1;
            end
          else
              running = 1'b1;
        end
      // end demo

      @(posedge clk)
        begin
          // send B column values per cycle
          $display("  writing %s[%0d][%0d:%0d]", vector_v.name, v, c+B-1, c);
          for (j=0; j < B; j=j+1)
            begin
              tb_i_vector[j*N +: N] = vector_v.val[v][c+j];
            end
          tb_i_first <= (c == 0);
          tb_i_pause <= !running;
          tb_i_last <= (c + B) >= vector_v.num_cols;
        end
    end // columns loop

  mvm_expected(v);

  @(posedge clk)
      tb_i_last <= 1'b0;
      
  $display("End writing %s[%0d]", vector_v.name, v);
  $display("Computing ----------");

  // wait for completion of calculation
  while (!tb_o_last_sum)
    begin
      @(posedge clk) ;
    end

endtask : write_vector_to_dut


// Do nothing for 'steps' cycles
task idle_sequence (
    input integer steps
);
  integer i;
  for (i = 0; i < steps; i = i+1)
  begin
      @(posedge clk) ;
  end
endtask : idle_sequence



task test_sequence;
    read_test_data();
    write_matrix_to_dut();   
    idle_sequence(10);

    write_vector_to_dut(0);
    write_vector_to_dut(1);
    write_vector_to_dut(2);
    idle_sequence(50);

endtask : test_sequence

