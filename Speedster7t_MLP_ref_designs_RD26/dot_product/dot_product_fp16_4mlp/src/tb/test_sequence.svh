// ------------------------------------------------------------------
//
//  Copyright (c) 2019  Achronix Semiconductor Corp.
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
// ------------------------------------------------------------------
// Description : 
// Performs dot-product over 'steps' cycles, meaning the sum over steps*8
// products.
// The 'a' input (8 fp16 numbers) for cycle i is all 0.0, except for
//         element [i] which is 1.0. This is convenient for debugging.
// The 'b' input (8 fp16 numbers) is the same for each cycle, with
//         b[0] = 1.5 and b[i+1] = b[i]*bfactor.
// ------------------------------------------------------------------

task test_sequence_1 (
    input integer steps,
    input real bfactor
);
  integer i, j;
  fp16 va, vb, sum_fp16;
  fp24 prod, sum;
  logic [K*B*FP-1 : 0] a_int;
  logic [K*B*FP-1 : 0] b_int;
  va = new(1.0);
  vb = new(1.0);
  prod = new(0.0);
  sum = new(0.0);
  sum_fp16 = new(0.0);
  first <= 1'b0;
  $display("test_sequence_1: %d clock ticks", steps);
  for (i=0; i < steps; i=i+1)
    begin
      integer j;
      vb.set(1.5);
      $display("step %0d: sum = %f = %s = 24'h%06h", i, sum.as_real, sum.as_string, sum.as_vector);
      for (j = 0; j < K*B; j = j+1)
        begin
          if (i % (K*B) == j)
              va.set(1.0);
          else
              va.set(0.0);
          a_int[j*FP +: FP] = va.as_vector;
          b_int[j*FP +: FP] = vb.as_vector;
          prod.set(va.as_real);
          prod.mult_real(vb.as_real);
          sum.add(prod);
          $display("  [%0d] = %f (16'h%04h) * %f (16'h%04h) = %f (24'h%06h) -> %f (24'h%06h)", j, va.as_real, va.as_vector, vb.as_real, vb.as_vector,
                      prod.as_real, prod.as_vector, sum.as_real, sum.as_vector);
          vb.mult_real(bfactor);
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
    sum_fp16.set(sum.as_real);
    expected <= sum_fp16.as_vector;
    last <= 1'b1;
    $display("end test_sequence_1, sum = %f = %s = 24'h%06h", sum.as_real, sum.as_string, sum.as_vector);
    $display("                sum_fp16 = %f = %s = 16'h%04h", sum_fp16.as_real, sum_fp16.as_string, sum_fp16.as_vector);
endtask : test_sequence_1


// Performs dot-product over 'steps' cycles, meaning the sum over steps*8
// products.
// While not random, the vectors have variations of values and signs.
task test_sequence_2 (
    input integer steps,
    input real bfactor
);
  integer i, j;
  fp16 va, vb, sum_fp16;
  fp24 prod, sum;
  logic [K*B*FP-1 : 0] a_int;
  logic [K*B*FP-1 : 0] b_int;
  va = new(1.0);
  vb = new(1.0);
  prod = new(0.0);
  sum = new(0.0);
  sum_fp16 = new(0.0);
  first <= 1'b0;
  $display("test_sequence_2: %d clock ticks", steps);
  for (i=0; i < steps; i=i+1)
    begin
      integer j;
      vb.set(1.5*(i+1));
      va.mult_real(-1.0);
      $display("step %0d: sum = %f = %s = 24'h%06h", i, sum.as_real, sum.as_string, sum.as_vector);
      for (j = 0; j < K*B; j = j+1)
        begin
          a_int[j*FP +: FP] = va.as_vector;
          b_int[j*FP +: FP] = vb.as_vector;
          prod.set(va.as_real);
          prod.mult_real(vb.as_real);
          sum.add(prod);
          $display("  [%0d] = %f (16'h%04h) * %f (16'h%04h) = %f (24'h%06h) -> %f (24'h%06h)", j, va.as_real, va.as_vector, vb.as_real, vb.as_vector,
                      prod.as_real, prod.as_vector, sum.as_real, sum.as_vector);
          va.add_real(2.1);
          vb.mult_real(bfactor);
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
    sum_fp16.set(sum.as_real);
    expected <= sum_fp16.as_vector;
    last <= 1'b1;
    $display("end test_sequence_1, sum = %f = %s = 24'h%06h", sum.as_real, sum.as_string, sum.as_vector);
    $display("                sum_fp16 = %f = %s = 16'h%04h", sum_fp16.as_real, sum_fp16.as_string, sum_fp16.as_vector);
endtask : test_sequence_2


// Generate idle sequence to flush pipelines
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


// Actual test sequence.
// The log file has details about the actual values, and result comparison.
task test_sequence;
    test_sequence_1(.steps(5), .bfactor(1.5));
    test_sequence_1(.steps(5), .bfactor(-0.6)); // output valid 5 cycles after prev valid
    test_sequence_2(.steps(8), .bfactor(0.3));
    idle_sequence(20); // flush values
endtask : test_sequence

