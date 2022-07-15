Numerical Format
================

bfloat16 stands for "brain float" and is a 16-bit format introduced by
the Tensorflow package.
It has 16 bits: 1 sign bit, 8 exponent bits, and 7 mantissa bits. The
precision is 8 bits (7 mantissa bits + "hidden 1").

Note that Achronix also supports a computation method called "block floating point". 
Block floating point (blockfp) and bfloat16 are unrelated and have nothing to do with each other.
To avoid confusion, Achronix uses the term fp16e8 instead of bfloat16

Structure
=========

The attached design is a dot-product macro, for fp16e8 values.
The macro uses 4 MLPs connected with via 'dout' cascade. 
Each MLP is configured in "1x" mode (all inputs are taken directly from fabric).

The start and end of the dot-product are indicated by 'first' and 'last'
signals. The next dot-product can be computed without idle cycles.


MLP configuration
=================

inputs and outputs are fp16e8 (also called bfloat16)
(fwdo_dout/fwdi_dout are fp24)

       +-----------------+
       |                 |
       |   MLP           |---> dout[15:0]                              
       | sum of 2        |                                             
       | fp16e8 * fp16e8 |<--- din[63:0] = {b7, a7, b6, a6}   <--7,6---+
       |                 |                                             |
       +-----------------+                                             |
                     ^                                                 |
                     | fwdo_dout[23:0]                            reg[127:96]
       +-----------------+                                             ^
       |                 |                                             |
       |   MLP           |                                             |
       | sum of 2        |                                             |
       | fp16e8 * fp16e8 |<--- din[63:0] = {b5, a5, b4, a4}   <--5,3---+
       |                 |                                             |
       +-----------------+                                             |
                     ^                                                 |
                     | fwdo_dout[23:0]                            reg[127:64]
       +-----------------+                                             ^
       |                 |                                             |
       |   MLP           |                                             |
       | sum of 2        |                                             |
       | fp16e8 * fp16e8 |<--- din[63:0] = {b3, a3, b2, a2}   <--3,2---+
       |                 |                                             |
       +-----------------+                                             |
                     ^                                                 |
                     | fwdo_dout[23:0]                            reg[127:32]
       +-----------------+                                             ^
       |                 |                                             |
       |   MLP           |                                             |
       | sum of 2        |                                             |
       | fp16e8 * fp16e8 |<--- din[63:0] = {b1, a1, b0, a0}   <--1,0---+
       |                 |                                             |
       +-----------------+                                             |
                                                                       |
                                                       i_b[127:0] = {b7..b0}
                                                       i_a]127:0] = {a7..a0}

Internal:

([s1], [s2], [s2.5], [s3], [ab], [cd], [fpcd] stand for MLP registers)

Top stage: (latency=7)

  [s1] -> c*d [s2,2.5]                          +-> add_cd->[cd]->fp16e8->[fpcd]->out
                   >-> add_abcd [s3]-           |  (accum)<-/
  [s1] -> a*b [s2,2.5]            \->add_ab ->[ab]
                                                ^
                                                |
Middle stages: (latency=5)                      |
                                                |
  [s1] -> c*d [s2,2.5]                          |
                   >-> add_abcd [s3]-           |
  [s1] -> a*b [s2,2.5]            \->add_ab ->[ab]
                                                ^
                                                |
Bottom stage: (latency=5)                       |
                                                |
  [s1] -> c*d [s2,2.5]                          |
                   >-> add_abcd [s3] -          |
  [s1] -> a*b [s2,2.5]                \------>[ab]

