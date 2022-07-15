Simple dot-product macro, using a single MLP in "1x" mode (all inputs
directly from fabric).

The start and end of the dot-product are indicated by 'first' and 'last'
signals. The next dot-product can be computed without idle cycles.

MLP config:

             +-----------+
             |           |
             |   MLP     |<--- din[63:0] = {a[31:0], b[31:0}
             | sum of 4  |
             | int8*int8 |---> dout[47:0]
             |           |
             +-----------+

 
