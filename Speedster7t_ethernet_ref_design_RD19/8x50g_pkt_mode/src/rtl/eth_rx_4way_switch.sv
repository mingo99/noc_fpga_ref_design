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
//      4-way switch.  Selects input from RX FIFO based on i_sel
//      Will only switch once channel is free, then indicates channel in use
//      Switches on packet boundaries
// ------------------------------------------------------------------

`timescale 1 ps / 1 ps

`include "7t_interfaces.svh"

module eth_rx_4way_switch #(
    // Module is fixed to 4 streams
    localparam NUM_STREAMS          = 4
)
(
    input  wire                     i_clk,
    input  wire                     i_reset_n,
    input  wire  [3 -1:0]           i_sel,          // Channel to switch to
    input  wire  [NUM_STREAMS -1:0] i_active_ch,    // Channels currently selected
    t_ETH_STREAM.rx                 if_eth_in [NUM_STREAMS -1:0],
    t_ETH_STREAM.tx                 if_eth_out,
    output wire  [NUM_STREAMS -1:0] o_active_ch,     // Channel selected by this switch
    output wire                     o_frame_start    // New frame started using i_sel
);


    logic                       valid_xfer;
    logic                       stream_busy;
    logic [2 -1:0]              frame_sel;
    logic [2 -1:0]              frame_sel_d;    // Pipeline to improve timing
    logic                       frame_start;
    logic [NUM_STREAMS -1:0]    active_ch;
    logic                       no_active_ch;
    logic [NUM_STREAMS -1:0]    valid_sel;

    // Indicate if the next selected channel is already in use
    // Or if there is no valid selection
    assign stream_busy = i_active_ch[i_sel[1:0]] | i_sel[2];

    // Select input valid signal.
    // Note that valid_sel can be asserted when there is no active channel
    always_comb
        case (frame_sel)
            2'b00 : valid_sel = if_eth_in[0].valid;
            2'b01 : valid_sel = if_eth_in[1].valid;
            2'b10 : valid_sel = if_eth_in[2].valid;
            2'b11 : valid_sel = if_eth_in[3].valid;
        endcase

    // Final output valid is gated by whether there is an active channel
    assign if_eth_out.valid = (valid_sel & ~no_active_ch);
    // Determine when a valid transfer occured
    assign valid_xfer = (if_eth_out.ready == 1'b1) && (if_eth_out.valid == 1'b1);

    // Switching state machine
    enum {SW_IDLE, SW_SEL, SW_FRAME} switch_state;

    always @(posedge i_clk)
    begin
        frame_sel_d <= frame_sel;
        frame_start <= 1'b0;
        if ( ~i_reset_n )
        begin
            switch_state <= SW_IDLE;
            active_ch    <= {NUM_STREAMS{1'b0}};
            no_active_ch <= 1'b1;
        end
        else
            case (switch_state)
                SW_IDLE : begin
                    if( if_eth_out.ready & (stream_busy == 1'b0) )
                    begin
                        frame_sel    <= i_sel;
                        switch_state <= SW_FRAME;
                        frame_start  <= 1'b1;
                        for( int ii=0; ii<NUM_STREAMS; ii++ )
                            if( i_sel == ii )
                                active_ch[ii] <= 1'b1;
                            else
                                active_ch[ii] <= 1'b0;
                        no_active_ch <= 1'b0;
                    end
                end
                SW_SEL : begin
                    // Allow selection to vary until ready is asserted
                    if( if_eth_out.ready )
                    begin
                        switch_state <= SW_FRAME;
                        frame_start  <= 1'b1;
                    end
                end
                SW_FRAME : begin
                    if( valid_xfer & if_eth_out.eop )
                        if (stream_busy == 1'b0)
                        begin
                            frame_sel    <= i_sel;  // Lookahead change
                            switch_state <= SW_SEL;
                            for( int jj=0; jj<NUM_STREAMS; jj++ )
                                if( i_sel == jj )
                                    active_ch[jj] <= 1'b1;
                                else
                                    active_ch[jj] <= 1'b0;
                            no_active_ch <= 1'b0;
                        end
                        else
                        begin
                            // Desired channel is in use, wait until free
                            switch_state <= SW_IDLE;
                            active_ch    <= {NUM_STREAMS{1'b0}};
                            no_active_ch <= 1'b1;
                        end
                end
                default : begin
                    switch_state <= SW_IDLE;
                    active_ch    <= {NUM_STREAMS{1'b0}};
                    no_active_ch <= 1'b1;
                end
            endcase
    end         

    // 4-way combinatorial mux
    // This mux only does the receive fields, it does not drive the ready signal
    // back to the if_eth_in.
    // Mux does not process the valid signal
    always_comb
    begin
        case (frame_sel_d)
            2'b00 : begin
                if_eth_out.data  = if_eth_in[0].data;
                if_eth_out.sop   = if_eth_in[0].sop;
                if_eth_out.eop   = if_eth_in[0].eop;
                if_eth_out.mod   = if_eth_in[0].mod;
                if_eth_out.flags = if_eth_in[0].flags;
            end
            2'b01 : begin
                if_eth_out.data  = if_eth_in[1].data;
                if_eth_out.sop   = if_eth_in[1].sop;
                if_eth_out.eop   = if_eth_in[1].eop;
                if_eth_out.mod   = if_eth_in[1].mod;
                if_eth_out.flags = if_eth_in[1].flags;
            end
            2'b10 : begin
                if_eth_out.data  = if_eth_in[2].data;
                if_eth_out.sop   = if_eth_in[2].sop;
                if_eth_out.eop   = if_eth_in[2].eop;
                if_eth_out.mod   = if_eth_in[2].mod;
                if_eth_out.flags = if_eth_in[2].flags;
            end
            2'b11 : begin
                if_eth_out.data  = if_eth_in[3].data;
                if_eth_out.sop   = if_eth_in[3].sop;
                if_eth_out.eop   = if_eth_in[3].eop;
                if_eth_out.mod   = if_eth_in[3].mod;
                if_eth_out.flags = if_eth_in[3].flags;
            end
        endcase
    end

    assign o_active_ch   = active_ch;
    assign o_frame_start = frame_start;

endmodule : eth_rx_4way_switch

