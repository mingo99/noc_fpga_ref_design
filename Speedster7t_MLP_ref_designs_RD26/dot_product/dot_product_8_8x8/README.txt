Simple dot-product macro, using a single MLP in "2x" mode.
The 'a' input is from the fabric, the 'b' input from the BRAM.

The BRAM must first be loaded with the 'b' arguments. The start and end of
the dot-product are indicated by 'first' and 'last' signals. The next
dot-product can be computed without idle cycles if it uses the same
BRAM contents.

BMLP config:

             +----------+           +------------+
             |          |           | MLP        |
  b[63:0] -->| BRAM     |  b[63:0]  |            |<--- a[63:0]
  wraddr  -->| 64-wide  |---------->| sum of 8   |
             |          |           | int8*int8  |---> dout[47:0]
  rdaddr  -->|          |           |            |
             +----------+           +------------+

