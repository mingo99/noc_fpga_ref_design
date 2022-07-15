// ------------------------------------------------------------------
//
// Copyright (c) 2019  Achronix Semiconductor Corp.
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
//
// Only the arguments for mult0 are assigned, the other multipliers
// compute 0*0.
// mult0 computes i*(i+1) for i = 0 .. steps-1.
// The sum is assigned to 'expected'
// ------------------------------------------------------------------

task test_sequence_1 (
    input integer steps
);
  integer i;
  logic signed [N-1:0] v, v_next;
  integer sum;
  logic [M*N-1:0] a_int;
  logic [M*N-1:0] b_int;
  v = 0;
  sum = 0;
  first <= 1'b0;
  $display("test_sequence_1: %d clock ticks, SUM i*(i+1) for i = 0 .. %d",
            steps, steps-1);
  for (i=0; i < steps; i=i+1)
    begin
      integer j;
      a_int = { {(N-1)*M{1'b0}}, v};
      v_next = v + 1;
      b_int = { {(N-1)*M{1'b0}}, v_next};
      sum = sum + v * v_next;
      v = v_next;
      @(posedge clk)
        begin
          a <= a_int;
          b <= b_int;
          first <= (i == 0);
          last <= 1'b0;
          exp_valid <= 1'b0;
        end
    end
    exp_valid <= 1'b1;
    expected <= sum;
    last <= 1'b1;
    $display("end test_sequence_1");
endtask : test_sequence_1

// Computes SUM i*(i+1) for i = 0 .. M*steps-1, wher M is the number
// of parallel multipliers. E.g., with 4 multipliers, it computes
// (0*1) + (1*2) + (2*3) + (3*4)
// in the first clock tick, then continues with (4*5) etc. in the next
// clock tick.
// The sum is assigned to 'expected'
task test_sequence_2 (
    input integer steps
);
  integer i;
  logic signed [N-1:0] v, v_next;
  integer sum;
  logic [M*N-1:0] a_int;
  logic [M*N-1:0] b_int;
  v = 0;
  sum = 0;
  first <= 1'b0;
  $display("test_sequence_2: %d clock ticks, SUM i*(i+1) for i = 0 .. %d",
            steps, M*steps-1);
  for (i=0; i < steps; i=i+1)
    begin
      integer j;
      for (j=0; j < M; j=j+1)
        begin
          a_int[j*N +: N] = v;
          v_next = v + 1;
          b_int[j*N +: N] = v_next;
          sum = sum + v * v_next;
          v = v_next;
        end
      @(posedge clk)
        begin
          a <= a_int;
          b <= b_int;
          first <= (i == 0);
          last <= 1'b0;
          exp_valid <= 1'b0;
        end
    end
    exp_valid <= 1'b1;
    expected <= sum;
    last <= 1'b1;
    $display("end test_sequence_2");
endtask : test_sequence_2

task idle_sequence (
    input integer steps
);
  integer i;
  first <= 1'b0;
  for (i = 0; i < steps; i = i+1)
  begin
      @(posedge clk)
        begin
          last <= 1'b0;
          exp_valid <= 1'b0;
        end
  end
endtask : idle_sequence

task test_sequence;
    test_sequence_1(.steps(5));
    test_sequence_1(.steps(3));
    test_sequence_2(.steps(5));
    idle_sequence(5); // flush values

endtask : test_sequence

