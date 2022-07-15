Simple dot-product macro, using a single MLP in "4x" mode.
The 'a' input is from the fabric, the 'b' input from the BRAM.

The BRAM must first be loaded with the 'b' arguments. The start and end of
the dot-product are indicated by 'first' and 'last' signals. The next
dot-product can be computed without idle cycles if it uses the same
BRAM contents.

The BRAM is written in 64-bit mode, but read in 128-bit mode.
During computation of the dot-product, the BRAM input pins are used as
high-order MLP 'a' inputs.

BMLP config:

                    +----------+  a[127:64]  +------------+                    
                    | ........>|------------>|            |
  a[127:64] --|\    |/         |             | MLP        |
  b[63:0] ----| |-->| BRAM     |  b[127:0]   |            |<--- a[63:0]
              |/    | wr:64    |------------>| sum of 16  |
    wraddr -------->| rd:128   |             | int8*int8  |---> dout[47:0]
    rdaddr -------->|          |             |            |
                    |          |             |            |
                    +----------+             +------------+

