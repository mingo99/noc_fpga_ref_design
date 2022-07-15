Description
===========

split_mlp_shared_bram_stack is a stack of MLPs, with BRAMs to store all
inputs. The configuration saves BRAMs by sharing one BRAM between two
MLPs. Outputs are buffered in the LRAM_FIFOs.

Structure
=========

Within the RTL, split_mlp_shared_bram_stack is the user macro

split_mlp_shared_bram is then a wrapper around split_mlp_shared_bram_stack .
This wrapper makes it easier to simulate, and also to place and route.
The split_mlp_shared_bram wrapper is not intended as user macro, because it reduces
the efficiency by serializing some inputs and outputs.

