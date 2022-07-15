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
//      400G configured as 8x50G packet mode top level
//      This design uses loopback only, sending a packet stream to the
//      400G MAC, which is sent to the device Serdes pins and looped back
// ------------------------------------------------------------------

`timescale 1 ps / 1 ps

`include "7t_interfaces.svh"

module ethernet_8x50g_pkt_mode_top
#(
    parameter   NUM_LOOPBACK_PKTS       = 1000              // Number of loopback packets generated
)
(
    // Clocks and resets
    input  wire                         i_reset_n,          // Negative synchronous reset
    input  wire                         i_start,            // Assert to start test
    input  wire                         i_eth_clk,          // All Ethernet NAPs must run at 507MHz
    input  wire                         pll_usr_lock,       // i_eth_clk PLL

    // System PLLs
    input  wire                         pll_eth_ref_lock,   // Ethernet reference clock PLL
    input  wire                         pll_eth_ff_lock,    // Ethernet FF clock PLL
    input  wire                         pll_noc_lock,       // NOC PLL

    // Packet checker results
    // Due to issues with ACE generating equivalent _oen signals, buses have to be defined as individual signals
    //    output wire [31:0]                  o_pkt_num,          // Count the number of received packets

    output wire                         o_pkt_num0,          // Count the number of received packets
    output wire                         o_pkt_num1,
    output wire                         o_pkt_num2,
    output wire                         o_pkt_num3,
    output wire                         o_pkt_num4,
    output wire                         o_pkt_num5,
    output wire                         o_pkt_num6,
    output wire                         o_pkt_num7,
    output wire                         o_pkt_num8,
    output wire                         o_pkt_num9,
    output wire                         o_pkt_num10,
    output wire                         o_pkt_num11,
    output wire                         o_pkt_num12,
    output wire                         o_pkt_num13,
    output wire                         o_pkt_num14,
    output wire                         o_pkt_num15,
    output wire                         o_pkt_num16,
    output wire                         o_pkt_num17,
    output wire                         o_pkt_num18,
    output wire                         o_pkt_num19,
    output wire                         o_pkt_num20,
    output wire                         o_pkt_num21,
    output wire                         o_pkt_num22,
    output wire                         o_pkt_num23,
    output wire                         o_pkt_num24,
    output wire                         o_pkt_num25,
    output wire                         o_pkt_num26,
    output wire                         o_pkt_num27,
    output wire                         o_pkt_num28,
    output wire                         o_pkt_num29,
    output wire                         o_pkt_num30,
    output wire                         o_pkt_num31,

    output wire                         o_checksum_error,   // Assert if check failed
    output wire                         o_pkt_size_error,   // Assert if packet size error
    output wire                         o_payload_error,    // Assert if there is a mismatch

    // Fabric GPIO signal output enables
    // output wire [31:0]                  o_pkt_num_oen,

    output wire                         o_pkt_num0_oen,
    output wire                         o_pkt_num1_oen,
    output wire                         o_pkt_num2_oen,
    output wire                         o_pkt_num3_oen,
    output wire                         o_pkt_num4_oen,
    output wire                         o_pkt_num5_oen,
    output wire                         o_pkt_num6_oen,
    output wire                         o_pkt_num7_oen,
    output wire                         o_pkt_num8_oen,
    output wire                         o_pkt_num9_oen,
    output wire                         o_pkt_num10_oen,
    output wire                         o_pkt_num11_oen,
    output wire                         o_pkt_num12_oen,
    output wire                         o_pkt_num13_oen,
    output wire                         o_pkt_num14_oen,
    output wire                         o_pkt_num15_oen,
    output wire                         o_pkt_num16_oen,
    output wire                         o_pkt_num17_oen,
    output wire                         o_pkt_num18_oen,
    output wire                         o_pkt_num19_oen,
    output wire                         o_pkt_num20_oen,
    output wire                         o_pkt_num21_oen,
    output wire                         o_pkt_num22_oen,
    output wire                         o_pkt_num23_oen,
    output wire                         o_pkt_num24_oen,
    output wire                         o_pkt_num25_oen,
    output wire                         o_pkt_num26_oen,
    output wire                         o_pkt_num27_oen,
    output wire                         o_pkt_num28_oen,
    output wire                         o_pkt_num29_oen,
    output wire                         o_pkt_num30_oen,
    output wire                         o_pkt_num31_oen,

    output wire                         o_checksum_error_oen,
    output wire                         o_pkt_size_error_oen,
    output wire                         o_payload_error_oen,

    // Ethernet ff divided clocks (unused)
    input  wire                         ethernet_1_m0_ff_clk_divby2,
    input  wire                         ethernet_1_m1_ff_clk_divby2,
    input  wire                         ethernet_1_ref_clk_divby2,

    // Ethernet MAC flow control signals
    // All unused in this design

    // 400G MAC 0 flow control
    input  wire  [7:0]                  ethernet_1_m0_pause_on,
    output wire                         ethernet_1_m0_tx_smhold,
    output wire  [7:0]                  ethernet_1_m0_xoff_gen,

    // 400G MAC 0 Status
    input  wire                         ethernet_1_m0_tx_ovr_err,
    input  wire                         ethernet_1_m0_tx_underflow,

    // 400G MAC 1 flow control
    input  wire  [7:0]                  ethernet_1_m1_pause_on,
    output wire                         ethernet_1_m1_tx_smhold,
    output wire  [7:0]                  ethernet_1_m1_xoff_gen,

    // 400G MAC 1 Status
    input  wire                         ethernet_1_m1_tx_ovr_err,
    input  wire                         ethernet_1_m1_tx_underflow,

    // 400G MAC 0 Buffer Levels
    input  wire  [3:0]                  ethernet_1_m0_rx_buffer0_at_threshold,
    input  wire  [3:0]                  ethernet_1_m0_rx_buffer1_at_threshold,
    input  wire  [3:0]                  ethernet_1_m0_rx_buffer2_at_threshold,
    input  wire  [3:0]                  ethernet_1_m0_rx_buffer3_at_threshold,
    input  wire  [3:0]                  ethernet_1_m0_tx_buffer0_at_threshold,
    input  wire  [3:0]                  ethernet_1_m0_tx_buffer1_at_threshold,
    input  wire  [3:0]                  ethernet_1_m0_tx_buffer2_at_threshold,
    input  wire  [3:0]                  ethernet_1_m0_tx_buffer3_at_threshold,

    // 400G MAC 1 Buffer Levels
    input  wire  [3:0]                  ethernet_1_m1_rx_buffer0_at_threshold,
    input  wire  [3:0]                  ethernet_1_m1_rx_buffer1_at_threshold,
    input  wire  [3:0]                  ethernet_1_m1_rx_buffer2_at_threshold,
    input  wire  [3:0]                  ethernet_1_m1_rx_buffer3_at_threshold,
    input  wire  [3:0]                  ethernet_1_m1_tx_buffer0_at_threshold,
    input  wire  [3:0]                  ethernet_1_m1_tx_buffer1_at_threshold,
    input  wire  [3:0]                  ethernet_1_m1_tx_buffer2_at_threshold,
    input  wire  [3:0]                  ethernet_1_m1_tx_buffer3_at_threshold,

    // Incorrectly included by ACE 8.2.  Will be removed in future releases
    input  wire                         ethernet_1_m0_serdes_tx_clk_ln0,
    input  wire                         ethernet_1_m0_serdes_tx_clk_ln1,
    input  wire                         ethernet_1_m0_serdes_tx_clk_ln2,
    input  wire                         ethernet_1_m0_serdes_tx_clk_ln3,
    input  wire                         ethernet_1_m1_serdes_tx_clk_ln0,
    input  wire                         ethernet_1_m1_serdes_tx_clk_ln1,
    input  wire                         ethernet_1_m1_serdes_tx_clk_ln2,
    input  wire                         ethernet_1_m1_serdes_tx_clk_ln3

);

    // ------------------------
    // Output enables
    // ------------------------
    // Fix all output enables active
    assign o_pkt_num0_oen = 1'b1;
    assign o_pkt_num1_oen = 1'b1;
    assign o_pkt_num2_oen = 1'b1;
    assign o_pkt_num3_oen = 1'b1;
    assign o_pkt_num4_oen = 1'b1;
    assign o_pkt_num5_oen = 1'b1;
    assign o_pkt_num6_oen = 1'b1;
    assign o_pkt_num7_oen = 1'b1;
    assign o_pkt_num8_oen = 1'b1;
    assign o_pkt_num9_oen = 1'b1;
    assign o_pkt_num10_oen = 1'b1;
    assign o_pkt_num11_oen = 1'b1;
    assign o_pkt_num12_oen = 1'b1;
    assign o_pkt_num13_oen = 1'b1;
    assign o_pkt_num14_oen = 1'b1;
    assign o_pkt_num15_oen = 1'b1;
    assign o_pkt_num16_oen = 1'b1;
    assign o_pkt_num17_oen = 1'b1;
    assign o_pkt_num18_oen = 1'b1;
    assign o_pkt_num19_oen = 1'b1;
    assign o_pkt_num20_oen = 1'b1;
    assign o_pkt_num21_oen = 1'b1;
    assign o_pkt_num22_oen = 1'b1;
    assign o_pkt_num23_oen = 1'b1;
    assign o_pkt_num24_oen = 1'b1;
    assign o_pkt_num25_oen = 1'b1;
    assign o_pkt_num26_oen = 1'b1;
    assign o_pkt_num27_oen = 1'b1;
    assign o_pkt_num28_oen = 1'b1;
    assign o_pkt_num29_oen = 1'b1;
    assign o_pkt_num30_oen = 1'b1;
    assign o_pkt_num31_oen = 1'b1;
    // assign o_pkt_num_oen         = {32{1'b1}};
    assign o_checksum_error_oen  = 1'b1;
    assign o_pkt_size_error_oen  = 1'b1;
    assign o_payload_error_oen   = 1'b1;

    // Concatentate individual outputs
    wire [31:0] o_pkt_num;

    assign { o_pkt_num31, o_pkt_num30, o_pkt_num29, o_pkt_num28, o_pkt_num27, o_pkt_num26, o_pkt_num25, o_pkt_num24,
             o_pkt_num23, o_pkt_num22, o_pkt_num21, o_pkt_num20, o_pkt_num19, o_pkt_num18, o_pkt_num17, o_pkt_num16,
             o_pkt_num15, o_pkt_num14, o_pkt_num13, o_pkt_num12, o_pkt_num11, o_pkt_num10, o_pkt_num9,  o_pkt_num8,
             o_pkt_num7,  o_pkt_num6,  o_pkt_num5,  o_pkt_num4,  o_pkt_num3,  o_pkt_num2,  o_pkt_num1,  o_pkt_num0} = o_pkt_num;

    // Drive flow control outputs
    assign ethernet_1_m0_tx_smhold = 1'b0;
    assign ethernet_1_m1_tx_smhold = 1'b0;
    assign ethernet_1_m0_xoff_gen  = 8'h0;
    assign ethernet_1_m1_xoff_gen  = 8'h0;

    // ------------------------
    // Clocks and resets
    // ------------------------

    // Create a reset for each ff_clk domain
    logic  eth_rstn;
    reset_processor #(
        .NUM_INPUT_RESETS   (5),    // Five reset sources
        .NUM_OUTPUT_RESETS  (1),    // One clock domain and reset
        .RST_PIPE_LENGTH    (8)     // Set reset pipeline to 8 stages
    ) i_reset_processor (
        .i_rstn_array       ({i_reset_n, pll_eth_ref_lock, pll_eth_ff_lock, pll_usr_lock, pll_noc_lock}),
        .i_clk              (i_eth_clk),
        .o_rstn_array       (eth_rstn)
    );  

    // Timestamp generator
    // This is based on 507MHz, so fractionally under 2ns per ts
    // If the user requires an accurate 2ns value, then a 500MHz clock will be required
    logic [30 -1:0] tx_ts;

    always @(posedge i_eth_clk)
        if ( ~eth_rstn )
            tx_ts <= 30'b0;
        else
            tx_ts <= tx_ts + {{29{1'b0}}, 1'b1};

    // ------------------------
    // System Defines
    // ------------------------

    // Define operating modes of Packet Generator and Checker
    localparam LINEAR_PAYLOAD   = 1;    // Payload is linearly increasing values
    localparam PKT_COUNT_ENABLE = 1;    // Insert and check for packet count in second byte of MAC address


    // 400G can be delivered in two methods
    // 1024-bit bus split across 4 NAPs; Quad segmented mode
    // 4 256-bit streams; Packet mode
    // This design uses packet mode, with a generator and checker for each of the 4 streams
    localparam IP_DATA_WIDTH     = 256;     // Data width per stream
    localparam NUM_STREAMS       = 4;

    // ------------------------
    // Ethernet traffic NAPs
    // ------------------------

    // Regarding clocks.  There is no requirement for the NAPs and user logic to
    // operate from the ff_clks.  As the NoC operates in it's own clock domain there
    // is clock crossing from (user logic & NAP) -> NoC -> (Ethernet subsystem).
    // The only requirement is that the user logic must not provide greater than the 
    // specified bandwidth of data.

    // Start blocks at different times
    logic [(2*NUM_STREAMS)-1:0] start_int;

    // Pipeline start signal so each block starts 2 cycles later than preceding block
    always @(posedge i_eth_clk)
        if( ~eth_rstn )
            start_int <= {(2*NUM_STREAMS){1'b0}};
        else
            start_int <= {start_int[(2*NUM_STREAMS)-2:0], i_start};

    // ------------------------
    // RX FIFO
    // ------------------------

    // Require a pair of Ethernet streams per NAP, one for transmit, one for receive
    t_ETH_STREAM eth_rx_fifo [NUM_STREAMS -1:0] ();
    t_ETH_STREAM eth_tx_nap  [NUM_STREAMS -1:0] ();

    logic [5 -1:0]              rx_seq_id    [NUM_STREAMS -1:0] /* synthesis syn_ramstyle=registers */;
    logic [8 -1:0]              rx_stream_id [NUM_STREAMS -1:0] /* synthesis syn_ramstyle=registers */;
    logic [NUM_STREAMS -1:0]    rx_seq_id_dval;
    logic [NUM_STREAMS -1:0]    rx_fifo_empty;
    logic [NUM_STREAMS -1:0]    rx_fifo_aempty;
    logic [NUM_STREAMS -1:0]    rx_fifo_full;
    logic [NUM_STREAMS -1:0]    rx_fifo_afull;

    // Signal for debug only
    // synthesis synthesis_off
    logic [5 -1:0]    rx_seq_id0;
    logic [5 -1:0]    rx_seq_id1;
    logic [5 -1:0]    rx_seq_id2;
    logic [5 -1:0]    rx_seq_id3;

    assign rx_seq_id0 = rx_seq_id[0];
    assign rx_seq_id1 = rx_seq_id[1];
    assign rx_seq_id2 = rx_seq_id[2];
    assign rx_seq_id3 = rx_seq_id[3];

    logic [8 -1:0]    rx_stream_id0;
    logic [8 -1:0]    rx_stream_id1;
    logic [8 -1:0]    rx_stream_id2;
    logic [8 -1:0]    rx_stream_id3;

    assign rx_stream_id0 = rx_stream_id[0];
    assign rx_stream_id1 = rx_stream_id[1];
    assign rx_stream_id2 = rx_stream_id[2];
    assign rx_stream_id3 = rx_stream_id[3];
    // synthesis synthesis_on

    // Generate 4 NAPs
    // Attach FIFO for the receive channel from each NAP
    genvar ii;
    generate for ( ii=0; ii<NUM_STREAMS; ii++ ) begin : gb_nap

        // Connection from NAP to FIFO
        t_ETH_STREAM eth_rx_nap ();

        // Instantiate NAPs
        nap_ethernet_wrapper i_nap_eth_lb (
            .i_clk                  (i_eth_clk),
            .i_reset_n              (eth_rstn),
            .if_eth_tx              (eth_tx_nap[ii]),
            .if_eth_rx              (eth_rx_nap),
            .o_output_rstn          ()
        );

        eth_fifo_256x512k i_nap_rx_fifo (
            // Clocks and resets
            .i_wr_clk               (i_eth_clk),    // REVISIT - currently only synchronous clocks supported
            .i_rd_clk               (i_eth_clk),
            .i_reset_n              (eth_rstn),
            // Streams
            .if_eth_in              (eth_rx_nap),
            .if_eth_out             (eth_rx_fifo[ii]),
            .o_seq_id_rx            (rx_seq_id[ii]),
            .o_stream_id_rx         (rx_stream_id[ii]),
            .o_seq_id_dval          (rx_seq_id_dval[ii]),
            // Flags
            .o_empty                (rx_fifo_empty[ii]),
            .o_aempty               (rx_fifo_aempty[ii]),
            .o_full                 (rx_fifo_full[ii]),
            .o_afull                (rx_fifo_afull[ii])
        );

    end
    endgenerate

    // ------------------------
    // TX 
    // ------------------------

    // Control sequence of transmit from generators.  Use round robin counter
    // This is only necessary in this example to ensure that the four separate generators
    // transmit in order.  This then allows the recieved packet sequence id to indicate which
    // generator the traffic originated from.
    // In a system with traffic being input from outside the device, the packet order will inherently
    // be correct as packets are input in a single stream in order

    // Control using interface ready signal
    logic [NUM_STREAMS -1:0] gen_enable_sel;
    logic [NUM_STREAMS -1:0] gen_enable_q;

    // One hot enable bit, to hold each generator in the sequence
    always @(posedge i_eth_clk)
        if( ~eth_rstn )
            gen_enable_sel <= { {(NUM_STREAMS-1){1'b0}}, 1'b1};
        else if ( |gen_enable_q )
            gen_enable_sel <= { gen_enable_sel[NUM_STREAMS-2:0], gen_enable_sel[NUM_STREAMS-1] };

    // Receive based rate control
    // In addition to the transmit rate control, if any of the receive FIFOs
    // asserts full, then this will block traffic down the column, which will
    // quickly cause data corruption, (the NAP FIFOs are shallow)
    // Therefore on any FIFO becoming full, hold off transmission on all channels
    // for a period
    // Due to the latency between packet transmission and reception, this has to be
    // a slow operating control, with a wide window to take effect.  Otherwise the 
    // control loop will be unstable
    // Note : This is only applicable in a loopback test system whereby RX can be
    // directly controlled by TX.
    localparam  RX_RATE_LIMIT_TC = 6'd32;

    logic [5:0] rx_rate_limit_count;
    logic       rx_rate_enable;

    assign rx_rate_enable = (rx_rate_limit_count >= RX_RATE_LIMIT_TC);

    always @(posedge i_eth_clk)
        if( ~eth_rstn )
            rx_rate_limit_count <= RX_RATE_LIMIT_TC;
        else if (|rx_fifo_full)
            rx_rate_limit_count <= 6'd0;
        else if (~rx_rate_enable)
            rx_rate_limit_count <= rx_rate_limit_count + 6'd1;


    // Instantiate generator
    generate for ( ii=0; ii<NUM_STREAMS; ii++ ) begin : gb_gen

        // Rate limiting traffic to 400Gb/s.
        // 1024 bits at 507MHz = 520Gb/s.  13/10 too fast.
        logic   tx_enable;

        tx_100g_rate_limit #(
            .ACTIVE_TC              (10),
            .LIMIT_TC               (13)
        ) i_eth_tx_limit (
            .i_clk                  (i_eth_clk),
            .i_reset_n              (eth_rstn),
            .i_start                (start_int[ii*2]),
            .if_eth_mon             (eth_tx_nap[ii]),
            .o_tx_enable            (tx_enable)
        );

        // Advance one_hot enable signal when eop output
        assign gen_enable_q[ii] = gen_enable_sel[ii] & eth_tx_nap[ii].eop & eth_tx_nap[ii].ready & eth_tx_nap[ii].valid;

        // Packet generator
        eth_pkt_gen #(
            .DATA_WIDTH             (IP_DATA_WIDTH),            // In pkt mode, 4 channels of 256 bits
            .LINEAR_PAYLOAD         (LINEAR_PAYLOAD),           // Set to 1 to make packets have linear counts
            .FIXED_PAYLOAD_LENGTH   (1500),                     // Fixed payload Length must be in the range of [46...9000] 
            .RANDOM_LENGTH          (1),                        // Set to 1 to generate packets with random length. 
                                                                // When set to 1, FIXED_PAYLOAD_LENGTH will be ignored.
            .PKT_NUM                (NUM_LOOPBACK_PKTS),        // Number of packets will be sent. The number must be less than 2^32.
                                                                // Set to 0 to make continuous packet generation
            .JUMBO_SUPPORT          (0),                        // Support up to 9k jumbo frame in random packet length mode
            .MAC_STREAM_ID          (8'h10 + ii),               // Specify MAC stream so received packets can be identified and
                                                                // directed to the appropriate receiver
            .PKT_COUNT_INSERT       (PKT_COUNT_ENABLE)          // Insert packet count in MAC address
        ) i_eth_tx_pkt_gen (
            .i_clk                  (i_eth_clk),
            .i_reset_n              (eth_rstn),                 // Negative synchronous reset
            .i_start                (start_int[ii*2]),
            .i_enable               (tx_enable & rx_rate_enable),
            .i_hold_eop             (1'b0),
            .if_eth_tx              (eth_tx_nap[ii])            // Ethernet stream interface
        );

        // Map flag signals to NAP interface
        // Apply timestamp to all transmit streams
        assign eth_tx_nap[ii].timestamp        = tx_ts;

        // REVISIT, synthesis does not support union with structs
        // Will need to be recoded
        // synthesis synthesis_off
        // Tie off unused flag signals
        assign eth_tx_nap[ii].flags.tx.id      = 0;
        assign eth_tx_nap[ii].flags.tx.frame   = 1'b0;
        assign eth_tx_nap[ii].flags.tx.error   = 1'b0;
        assign eth_tx_nap[ii].flags.tx.crc     = 1'b0;
        assign eth_tx_nap[ii].flags.tx.crc_inv = 1'b0;
        assign eth_tx_nap[ii].flags.tx.crc_ovr = 1'b0;
        assign eth_tx_nap[ii].flags.tx.class_a = 1'b0;
        assign eth_tx_nap[ii].flags.tx.class_b = 1'b0;
        assign eth_tx_nap[ii].flags.tx.unused  = 0;
        // synthesis synthesis_on

        // Throughput monitor (simulation only)
        // synthesis synthesis_off
        localparam string  STREAM_NAME = {"Transmit Stream ", (8'h30 + ii)};

        tb_eth_monitor #(
            .DATA_WIDTH             (IP_DATA_WIDTH),
            .STOP_COUNT             (NUM_LOOPBACK_PKTS),
            .AUTO_START             (1),
            .STREAM_NAME            (STREAM_NAME)
        ) i_tx_eth_mon (
            .i_clk                  (i_eth_clk),
            .i_reset_n              (eth_rstn),
            .i_start                (1'b0),
            .i_stop                 (1'b0),             // Use STOP_COUNT
            .i_enable               (1'b1),             // Monitor for whole test
            .if_eth_mon             (eth_tx_nap[ii])
        );
        // synthesis synthesis_on

    end
    endgenerate

    // ------------------------
    // RX Select and Check
    // ------------------------

    // Require a cross-point switch on reception, that directs the appopriate packet
    // to the appropriate checker.

    // Indicate to each switch what channels are already in use
    logic [NUM_STREAMS -1:0]    active_ch_sum;
    logic [NUM_STREAMS -1:0]    active_ch [NUM_STREAMS -1:0];

    // Simulation only debug signals
    // synthesis synthesis_off
    logic [NUM_STREAMS -1:0]    active_ch0;
    logic [NUM_STREAMS -1:0]    active_ch1;
    logic [NUM_STREAMS -1:0]    active_ch2;
    logic [NUM_STREAMS -1:0]    active_ch3;

    assign active_ch0 = active_ch[0];
    assign active_ch1 = active_ch[1];
    assign active_ch2 = active_ch[2];
    assign active_ch3 = active_ch[3];
    // synthesis synthesis_on

    always_comb
    begin
        active_ch_sum = {NUM_STREAMS{1'b0}};
        for( int jj=0; jj<NUM_STREAMS; jj++ )
            active_ch_sum |= active_ch[jj];
    end

    // Resolve ready signal to the four interfaces, based in active channel selection
    logic [NUM_STREAMS -1:0]    eth_rx_chk_ready;

    // Ready registered to meet timing
    // Adds one cycle delay to switching between streams
    generate for ( ii=0; ii<NUM_STREAMS; ii++ ) begin : gb_ready
        logic eth_rx_fifo_ready;
        always_comb
        begin
            eth_rx_fifo_ready = 1'b0;
            for( int mm=0; mm<NUM_STREAMS; mm++ )
                eth_rx_fifo_ready |= (eth_rx_chk_ready[mm] && active_ch[mm][ii]);
        end

        // Sync assert, asynch deassert
        always @(posedge i_eth_clk or negedge eth_rx_fifo_ready)
            if ( ~eth_rx_fifo_ready )
                eth_rx_fifo[ii].ready <= 1'b0;
            else
                eth_rx_fifo[ii].ready <= 1'b1;
    end
    endgenerate

    // Master sequence counter.  Checks each sequence number that arrives, and based on the stream ID
    // populates the relevant receive channel FIFO.  Each receive channel then reads it's respective FIFO
    // to know which rx data FIFO to download the packet from.
    logic [5 -1:0]              current_seq_id;
    logic [NUM_STREAMS -1:0]    seq_id_valid_ch;
    logic [2 -1:0]              seq_id_valid_match;
    logic [2 -1:0]              seq_id_valid_match_d;
    logic [8 -1:0]              stream_id_match;
    logic [NUM_STREAMS -1:0]    rx_channel_fifo_wr;

    // Check all available sequence IDs to see if any match our next value
    // Set a flag for the channel that matches, and set the matching stream ID
    always_comb
    begin
        seq_id_valid_ch = {NUM_STREAMS{1'b0}};
        seq_id_valid_match = 2'bxx;
        stream_id_match    = 8'hxx;
        for( int jj=0; jj<NUM_STREAMS; jj++ )
            if( (rx_seq_id[jj] == current_seq_id) && (rx_seq_id_dval[jj] == 1'b1) )
            begin
                seq_id_valid_ch[jj]  = 1'b1;
                seq_id_valid_match   = jj;
                stream_id_match      = rx_stream_id[jj];
                // rx_seq_id will only match the output from one NAP at a time
                break;
            end
    end

    always @(posedge i_eth_clk)
    begin
        rx_channel_fifo_wr   <= {NUM_STREAMS{1'b0}};
        seq_id_valid_match_d <= seq_id_valid_match;
        if( ~eth_rstn )
            current_seq_id <= 5'h0;
        else if (seq_id_valid_ch != {NUM_STREAMS{1'b0}})
        begin
            // The next sequence ID has been received
            // Determine which channel matches the relevant stream
            for( int kk=0; kk<NUM_STREAMS; kk++ )
                if( stream_id_match == (8'h10 + kk))
                begin
                    rx_channel_fifo_wr[kk] <= 1'b1;
                    break;
                end

            // rx_seq_id identified and relevant NAP written to FIFO
            // increment sequence ID
            current_seq_id <= current_seq_id + 5'h1;
        end
    end

    // Aggregate Packet checker results
    logic [31:0]            chk_pkt_num [NUM_STREAMS-1:0];
    logic [NUM_STREAMS-1:0] chk_checksum_error;
    logic [NUM_STREAMS-1:0] chk_pkt_size_error;
    logic [NUM_STREAMS-1:0] chk_payload_error;

    // Instantiate generators and checkers
    generate for ( ii=0; ii<NUM_STREAMS; ii++ ) begin : gb_chk

        logic [3 -1:0]              next_fifo_ch;
        logic                       frame_start;

        // Create 8 entry rx fifo that lists the NAPs with packets for this channel, in order
        logic [2 -1:0]  nap_id_fifo [8 -1:0];
        logic [2 -1:0]  nap_id_fifo_dout;
        logic [3 -1:0]  nap_id_fifo_wr_ptr;
        logic [3 -1:0]  nap_id_fifo_rd_ptr;
        logic [3 -1:0]  nap_id_fifo_wr_ptr_next;
        logic           nap_id_fifo_empty;
        logic           nap_id_fifo_full;

        // FIFO flags
        assign nap_id_fifo_wr_ptr_next = (nap_id_fifo_wr_ptr + 3'b001);
        assign nap_id_fifo_empty       = (nap_id_fifo_wr_ptr == nap_id_fifo_rd_ptr);
        assign nap_id_fifo_full        = (nap_id_fifo_wr_ptr_next == nap_id_fifo_rd_ptr);

        // Write to fifo when top level detects a packet for this channel
        always @(posedge i_eth_clk)
        begin
            if( ~eth_rstn )
                nap_id_fifo_wr_ptr <= 3'b000;
            else if (rx_channel_fifo_wr[ii] == 1'b1)
            begin
                nap_id_fifo[nap_id_fifo_wr_ptr] <= seq_id_valid_match_d;
                nap_id_fifo_wr_ptr <= nap_id_fifo_wr_ptr + 3'b001;
            end
        end

        // Have asynchronous output to speed up response
        assign nap_id_fifo_dout = nap_id_fifo[nap_id_fifo_rd_ptr];
        assign next_fifo_ch     = {nap_id_fifo_empty, nap_id_fifo_dout};

        // Read and advance fifo whenever channel is started to be processed
        always @(posedge i_eth_clk)
        begin
            if( ~eth_rstn )
                nap_id_fifo_rd_ptr <= 3'b000;
            else if (frame_start == 1'b1)
                nap_id_fifo_rd_ptr <= nap_id_fifo_rd_ptr + 3'b001;
        end

        // Connection from switch to checker
        t_ETH_STREAM eth_rx_chk ();
        // Ready signal driven from checker.  Input to top level mux.
        assign eth_rx_chk_ready[ii] = eth_rx_chk.ready;

        // 4 way switch feeding checker
        eth_rx_4way_switch i_eth_rx_4way_switch (
            .i_clk                  (i_eth_clk),
            .i_reset_n              (eth_rstn),                 // Negative synchronous reset
            .i_sel                  (next_fifo_ch),             // Frame selection
            .i_active_ch            (active_ch_sum),            // Channel active indicators
            .if_eth_in              (eth_rx_fifo),              // Ethernet stream interfaces from fifos
            .if_eth_out             (eth_rx_chk),               // Ethernet stream interface to checker
            .o_active_ch            (active_ch[ii]),            // This channel active indicator
            .o_frame_start          (frame_start)               // New frame started using i_sel
        );

        // Packet checker
        eth_pkt_chk #(
            .DATA_WIDTH             (IP_DATA_WIDTH),            // In pkt mode, 4 channels of 256 bits
            .LINEAR_PAYLOAD         (LINEAR_PAYLOAD),           // Set to 1 to make packets have linear counts
            .PKT_COUNT_CHECK        (PKT_COUNT_ENABLE),         // Check for packet count in MAC address
            .DOUBLE_REG_INPUT       (1)                         // Double register input signals for improved timing
        ) i_eth_pkt_chk (
            .i_clk                  (i_eth_clk),
            .i_reset_n              (eth_rstn),                 // Negative synchronous reset
            .if_eth_rx              (eth_rx_chk),               // Ethernet stream interface
            .o_pkt_num              (chk_pkt_num[ii]),          // Count the number of received packets
            .o_checksum_error       (chk_checksum_error[ii]),   // Assert if check failed
            .o_pkt_size_error       (chk_pkt_size_error[ii]),   // Assert if packet size error
            .o_payload_error        (chk_payload_error[ii])     // Assert if there is a mismatch
        );

        // Throughput monitor (simulation only)
        // synthesis synthesis_off
        localparam string  STREAM_NAME = {"Receive Stream ", (8'h30 + ii)};

        tb_eth_monitor #(
            .DATA_WIDTH             (IP_DATA_WIDTH),
            .STOP_COUNT             (NUM_LOOPBACK_PKTS),
            .AUTO_START             (1),
            .STREAM_NAME            (STREAM_NAME)
        ) i_rx_eth_mon (
            .i_clk                  (i_eth_clk),
            .i_reset_n              (eth_rstn),
            .i_start                (1'b0),
            .i_stop                 (1'b0),             // Use STOP_COUNT
            .i_enable               (1'b1),             // Monitor for whole test
            .if_eth_mon             (eth_rx_chk)
        );
        // synthesis synthesis_on

    end
    endgenerate


    // As pkt_num pins are distributed around the die
    // Need a pipeline to enable signals to traverse correctly
    localparam OP_PIPE_LEN = 4;
    logic [32 -1:0] pkt_num_pipe        [OP_PIPE_LEN+1:0] /* synthesis syn_ramstyle=registers */;
    logic           chksum_error_pipe   [OP_PIPE_LEN-1:0];
    logic           pkt_size_error_pipe [OP_PIPE_LEN-1:0];
    logic           payload_error_pipe  [OP_PIPE_LEN-1:0];

    // REVISIT - look to increase later to prevent overflow
    logic [31:0]    pkt_num_total;

    // Add the packet count from each checker
    always_comb
    begin
        pkt_num_total = 0;
        for( int jj=0; jj<NUM_STREAMS; jj++)
            pkt_num_total = pkt_num_total + chk_pkt_num[jj];
    end

    always @(posedge i_eth_clk)
    begin
        pkt_num_pipe        <= {pkt_num_pipe[OP_PIPE_LEN:0], pkt_num_total};
        chksum_error_pipe   <= {chksum_error_pipe[OP_PIPE_LEN-2:0], (|chk_checksum_error)};
        pkt_size_error_pipe <= {pkt_size_error_pipe[OP_PIPE_LEN-2:0], (|chk_pkt_size_error)};
        payload_error_pipe  <= {payload_error_pipe[OP_PIPE_LEN-2:0], (|chk_payload_error)};
    end

    assign o_pkt_num         = pkt_num_pipe[OP_PIPE_LEN+1];
    assign o_checksum_error  = chksum_error_pipe[OP_PIPE_LEN-1];
    assign o_pkt_size_error  = pkt_size_error_pipe[OP_PIPE_LEN-1];
    assign o_payload_error   = payload_error_pipe[OP_PIPE_LEN-1];


endmodule : ethernet_8x50g_pkt_mode_top

