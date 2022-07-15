// Fill the BRAM with 8-bit values 1, 2, ..., with 8 values per word.
// When interpreted as 2's complement, the sequence is
// 1, 2, ..., 127, -128, -127, ..., -2, -1, 0.
task test_fill_memory (
    input integer steps
);
  integer i;
  logic signed [N-1:0] v;
  logic signed [Mb*N-1:0] b_int;
  v = 1;
  $display("Filling BRAM, i = 1, 2, 3, ...; %d addresses (%d values)", steps, Mb*steps);
  for (i=0; i < steps; i=i+1)
    begin
      integer j;
      for (j=0; j < Mb; j=j+1)
        begin
          b_int[j*N +: N] = v;
          v = v + 1;
        end
      @(posedge clk)
        begin
          b <= b_int;
          wren <= 1'b1;
          b_addr <= i;
        end
    end
  @(posedge clk)
    begin
      b <= 8'bx;
      wren <= 1'b0;
    end
  $display("end filling BRAM");
endtask // test_fill_memory

// Only the arguments for mult0 are assigned, the other multipliers
// compute 0*0.
// Assume that the BRAM was prefilled for at least 'steps' addreses
// with test_fill_memory.
// mult0 computes i*(i+1) for i = 0 .. steps-1.
// The sum is assigned to 'expected'
task test_sequence_1 (
    input integer steps
);
  integer i;
  logic signed [N-1:0] v;
  logic signed [N-1:0] vb;
  integer sum;
  logic [M*N-1:0] a_int;
  v = 0;
  vb = 1;
  sum = 0;
  first <= 1'b0;
  $display("test_sequence_1: %d clock ticks, SUM i*(16*i+1) for i = 0 .. %d",
            steps, steps-1);
  for (i=0; i < steps; i=i+1)
    begin
      integer j;
      a_int = { {(N-1)*M{1'b0}}, v};
      sum = sum + v * vb;
      v = v + 1;
      @(posedge clk)
        begin
          a <= a_int;
          first <= (i == 0);
          last <= 1'b0;
          exp_valid <= 1'b0;
        end
      for (j=0; j < M; j=j+1)
        begin
          vb = vb + 1;
        end
    end
  exp_valid <= 1'b1;
  expected <= sum;
  last <= 1'b1;
  $display("end test_sequence_1 (expected = %d)", sum);
endtask // test_sequence_1

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
          sum = sum + v * v_next;
          v = v_next;
        end
      @(posedge clk)
        begin
          a <= a_int;
          first <= (i == 0);
          last <= 1'b0;
          exp_valid <= 1'b0;
        end
    end
    exp_valid <= 1'b1;
    expected <= sum;
    last <= 1'b1;
    $display("end test_sequence_2 (expected = %d)", sum);
endtask // test_sequence_2

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
endtask // idle_sequence

task test_sequence;
    test_fill_memory(.steps(32));
    test_sequence_1(.steps(5));
    test_sequence_1(.steps(3));
    test_sequence_2(.steps(5));
    // when steps = 8, the last multiply is 127 * -128
    // when steps = 17 etc., the arguments are < 0, but the mult is > 0.
    test_sequence_2(.steps(10));
    idle_sequence(8); // flush values
endtask // test_sequence
