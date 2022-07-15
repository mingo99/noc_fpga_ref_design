# ----------------------------------------
# Timing constraints for split_mlp shared_bram
# Target frequency 695 MHz
# ----------------------------------------

set CLK_PERIOD 1.44

create_clock [get_ports i_clk] -name clk  -period $CLK_PERIOD
