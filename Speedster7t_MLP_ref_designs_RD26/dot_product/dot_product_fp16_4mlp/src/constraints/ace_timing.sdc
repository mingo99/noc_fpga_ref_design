# ----------------------------------------
# Timing constraints for dot_product macro
# Target frequency 750 MHz
# ----------------------------------------

set CLK_PERIOD 1.3333

create_clock i_clk -name clk  -period $CLK_PERIOD

