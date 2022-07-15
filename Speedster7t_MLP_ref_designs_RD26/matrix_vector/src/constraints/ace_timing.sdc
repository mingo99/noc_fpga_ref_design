# -------------------------------------------------------------------------
# ACE timing constaint file
# All clocks, clock relationships, and IO timing constraints should be set
# in this file
# -------------------------------------------------------------------------

set CLK_PERIOD 1.335

create_clock i_clk -name clk  -period $CLK_PERIOD

