// ------------------------------------------------------------------
//
// Copyright (c) 2020  Achronix Semiconductor Corp.
// All Rights Reserved.
//
//
// This software constitutes an unpublished work and contains
// valuable proprietary information and trade secrets belonging
// to Achronix Semiconductor Corp.
//
// This software may not be used, copied, distributed or disclosed
// without specific prior written authorization from
// Achronix Semiconductor Corp.
//
// The copyright notice above does not evidence any actual or intended
// publication of such software.
//
// ------------------------------------------------------------------
// Speedster7t Ethenet reference design (RD19)
//      Rate limiter block.
//      Configured for NAPs running on 507MHz.
//      Theoretical max rate is then 130 Gbps.  This block limits rate to 100G
// ------------------------------------------------------------------

`timescale 1 ps / 1 ps

`include "7t_interfaces.svh"

module tx_100g_rate_limit #(
    parameter int                       ACTIVE_TC = 10,     // Number of cycles of active
    parameter int                       LIMIT_TC  = 13      // Number of cycles of limiter
)
(
    // Control Inputs
    input  wire                         i_clk,              // All Ethernet NAPs must run at 507MHz
    input  wire                         i_reset_n,          // Negative synchronous reset
    input  wire                         i_start,            // Assert to start test

    // Ethernet stream
    t_ETH_STREAM.monitor                if_eth_mon,

    output wire                         o_tx_enable         // Assert if there is a mismatch
);

    // Rate limiting traffic to 400Gb/s.
    // 1024 bits at 507MHz = 520Gb/s.  13/10 too fast.

    // Count active cycles in base of 10.  
    // At the end of a packet, allow the base 13 count to catch up
    logic [3:0] active_cycles;
    logic       active_cycles_tc;
    logic [3:0] limit_cycles;
    logic       limit_cycles_tc;
    logic [3:0] rate_offset;        // Signed comparisons didn't work with byte,
                                    // Code expressions explicitly
    logic       active_tx;
    logic       valid_xfer;
    logic       tx_enable;
    logic       limit_phase;
    logic       active_phase;

    // Support odd values for limit counters
    localparam [3:0] ACTIVE_TC_LOW  = (ACTIVE_TC/2) - 1;
    localparam [3:0] ACTIVE_TC_HIGH = (ACTIVE_TC % 2) ? ((ACTIVE_TC+1)/2) - 1 : (ACTIVE_TC/2) - 1;
    localparam [3:0] LIMIT_TC_LOW   = (LIMIT_TC/2) - 1;
    localparam [3:0] LIMIT_TC_HIGH  = (LIMIT_TC % 2)  ? ((LIMIT_TC+1)/2) - 1  : (LIMIT_TC/2) - 1;

    assign active_cycles_tc = (active_phase) ? (active_cycles == ACTIVE_TC_LOW) : (active_cycles == ACTIVE_TC_HIGH);
    assign limit_cycles_tc  = (limit_phase)  ? (limit_cycles == LIMIT_TC_LOW)   : (limit_cycles == LIMIT_TC_HIGH);

    assign valid_xfer = (if_eth_mon.valid & if_eth_mon.ready);

    // Active divider counters
    always @(posedge i_clk)
        if( ~i_reset_n )
        begin
            active_cycles <= 4'd0;
            active_phase  <= 1'b0;
        end
        else if (valid_xfer)
        begin
            if ( active_cycles_tc )
            begin
                active_cycles <= 4'd0;
                active_phase  <= ~active_phase;
            end
            else
                active_cycles <= active_cycles + 4'd1;
        end
                
    // For these tests, i_start begins the test at which point the transmit is active
    always @(posedge i_clk)
        if( ~i_reset_n )
            active_tx <= 1'b0;
        else if (i_start)
            active_tx <= 1'b1;

    always @(posedge i_clk)
        if( ~i_reset_n )
        begin
            limit_cycles <= 4'd0;
            limit_phase  <= 1'b0;
        end
        else if (active_tx)
        begin
            if ( limit_cycles_tc )
            begin
                limit_cycles <= 4'd0;
                limit_phase  <= ~limit_phase;
            end
            else
                limit_cycles <= limit_cycles + 4'd1;
        end

    // Count difference
    // Limit range to prevent overrate being applied after a long gap
    always @(posedge i_clk)
        if( ~i_reset_n )
            rate_offset <= 4'd0;
        else
            case ( {(active_tx & limit_cycles_tc), (valid_xfer & active_cycles_tc)} )
                2'b00 : rate_offset <= rate_offset;
                2'b01 : if ( rate_offset != 4'h4 ) rate_offset <= rate_offset + 4'd1;      // Over rate
                2'b10 : if ( rate_offset != 4'hc ) rate_offset <= rate_offset - 4'd1;      // Under rate
                2'b11 : rate_offset <= rate_offset;
            endcase

    // If over rate, hold until back level
    always @(posedge i_clk)
        if( ~i_reset_n )
            tx_enable <= 1'b1;
        else if ( valid_xfer & if_eth_mon.eop )
        begin
            // Signed comparison not working, (even with 'sd).  So code explicity
            if ( (rate_offset > 4'h0) && (rate_offset < 4'h8))
                tx_enable <= 1'b0;
        end
        else if ( tx_enable == 1'b0 )
        begin
            // Lookahead, usually difference is just 1
            // In which instance, re-enable as counter is about to be set back to 0
            if( (rate_offset == 4'd1) && (active_tx & limit_cycles_tc) )
                tx_enable <= 1'b1;
            else if( (rate_offset >= 4'h8) || (rate_offset == 4'h0) )
                tx_enable <= 1'b1;
        end

    // Assign output
    assign o_tx_enable = tx_enable;

endmodule : tx_100g_rate_limit

