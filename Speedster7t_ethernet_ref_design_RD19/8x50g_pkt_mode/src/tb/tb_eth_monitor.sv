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
// Speedster7t Ethernet reference design (RD19)
//      Ethernet stream monitor
//          Validate correct sequence
//          Count packets
//          Print throughput
// ------------------------------------------------------------------

`timescale 1 ps / 1 ps

`include "7t_interfaces.svh"
`include "ethernet_utils.svh"

module tb_eth_monitor
#(
    parameter int    DATA_WIDTH  = `ACX_NAP_ETH_DATA_WIDTH,
    parameter int    STOP_COUNT  = 0,               // If non-zero, stop measuring on this number of packets
                                                    // Ignore i_stop
    parameter int    AUTO_START  = 0,               // If enabled, start counting when first valid sop received
                                                    // Ignore i_start
    parameter string STREAM_NAME = ""               // Name of the stream being monitored.
)
(
    // Inputs
    input wire                  i_clk,
    input wire                  i_reset_n,          // Negative synchronous reset
    input wire                  i_start,            // Start monitor
    input wire                  i_stop,             // Stop monitor, print results
    input wire                  i_enable,           // Enable monitoring sequence
    t_ETH_STREAM.monitor        if_eth_mon          // Ethernet stream interface
);

    localparam BYTE_WIDTH = DATA_WIDTH/8;

    logic   check_seq;
    logic   test_state;
    logic   valid_xfer;
    logic   valid_frame;
    logic   one_beat_frame;
    logic   stop_int;
    logic   start_int;
    int     packet_count;
    int     byte_count;
    int     packet_count_report;
    int     byte_count_report;

    assign stop_int  = (STOP_COUNT != 0) ? (packet_count==STOP_COUNT) : i_stop;
    assign start_int = (AUTO_START != 0) ? (valid_xfer & if_eth_mon.sop & ~test_state) : i_start;

    always @(posedge i_clk)
        if( ~i_reset_n || stop_int )
            test_state <= 1'b0;
        else if (start_int)
            test_state <= 1'b1;

    assign check_seq  = ((start_int && ~stop_int) || test_state) & i_enable;
    assign valid_xfer = (if_eth_mon.ready & if_eth_mon.valid);

    // Count packets
    always @(posedge i_clk)
        if( ~check_seq )
            packet_count <= 0;
        else if( valid_xfer & if_eth_mon.eop )
            packet_count <= packet_count + 1;

    // Count bytes
    always @(posedge i_clk)
        if( ~check_seq )
            byte_count <= 0;
        else if( valid_xfer )
        begin
            if ( if_eth_mon.eop )
                byte_count <= byte_count + if_eth_mon.mod;
            else
                byte_count <= byte_count + BYTE_WIDTH;
        end

    // Capture case of single beat frame.  Only possible if data width greater than shortest packet
    assign one_beat_frame = (if_eth_mon.eop & if_eth_mon.sop & ~valid_frame) & (BYTE_WIDTH >= 64);

    // Check valid sequence
    always @(posedge i_clk)
    begin
        if( check_seq & valid_xfer)
        begin
            valid_eop : assert (valid_frame  | ~if_eth_mon.eop | one_beat_frame) else
                            $error( "EoP outside of a valid frame" );
            valid_sop : assert (~valid_frame | ~if_eth_mon.sop | one_beat_frame) else
                            $error( "SoP inside of a valid frame" );
        end

        // Code to support eop and sop on the same cycle
        if( ~check_seq )
            valid_frame <= 1'b0;
        else if ( valid_xfer & if_eth_mon.eop )
            valid_frame <= 1'b0;
        else if ( valid_xfer & if_eth_mon.sop )
            valid_frame <= 1'b1;
    end

    // Capture start and end of sequence
    logic   start_d;
    logic   stop_d;
    time    start_time;
    time    end_time;
    time    diff_time;
    real    diff_time_ns;
    real    data_rate;   

    always @(posedge i_clk)
    begin
        start_d <= start_int;
        stop_d  <= stop_int;

        if( start_int & ~start_d )
            start_time = $time;

        if( stop_int & ~stop_d )
        begin
            end_time = $time;

            // Print stats, assuming start had been asserted
            if ( start_time != 0 )
            begin
                diff_time = end_time - start_time;
                diff_time_ns = real'(diff_time)/1000.0;
                data_rate = (real'(byte_count)*8.0*1000.0)/real'(diff_time);
                packet_count_report = packet_count;
                byte_count_report   = byte_count;
                // Display results at the end of simulation, so they are easy to access
                // $display( "%0t : %0m\n    %0d Packets measured : %0d Bytes measured : %0.3f ns elapsed time : %0.3f Gbps", 
                //             $time, packet_count_report, byte_count_report, diff_time_ns, data_rate );
            end
        end
    end

    // Print stats at end of sim
    final
        $display( "%0m : Ethernet stream %s\n    %0d Packets measured : %0d Bytes measured : %0.3f ns elapsed time : %0.3f Gbps", 
                    STREAM_NAME, packet_count_report, byte_count_report, diff_time_ns, data_rate );

endmodule : tb_eth_monitor

