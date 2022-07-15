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
//      Ethernet FIFO.  256 bits wide, (data) by 1K deep
//      FIFO uses the t_ETH_TYPE as it's ports and offers the same interface
//      as that available from the nap_ethernet_wrapper
//      Total data storage is 16KB which enables a whole jumbo frame to be stored
// ------------------------------------------------------------------

`timescale 1 ps / 1 ps

`include "7t_interfaces.svh"

module eth_fifo_256x512k #(
    parameter           AFULL_THRESHOLD  = 4,           // Threshold below full at which almost full is asserted
    parameter           AEMPTY_THRESHOLD = 4,           // Threshold at which almost empty is asserted
    parameter           FIFO_SYNC_MODE   = 1,           // Must be 1 currently. Asynchronous clocks not supported
    parameter           INREG_EN         = 1,           // Enable optional input register
    parameter           OUTREG_EN        = 1,           // Enable optional output register
    localparam          SEQ_ID_WIDTH     = 5            // Sequence id width

)
(
    // Control Inputs
    input  wire                     i_wr_clk,           // Write side clock, (same as NAP clk)
// REVISIT - coding of sequence id FIFO only supports synchronous clocks.  To be resolved
    input  wire                     i_rd_clk,           // Read side clock, (same as user logic clk)
    input  wire                     i_reset_n,          // Negative synchronous reset, synced to wr_clk

    // Streaming interfaces
    t_ETH_STREAM.rx                 if_eth_in,          // Input to FIFO
    t_ETH_STREAM.tx                 if_eth_out,         // Output from FIFO
    output wire [SEQ_ID_WIDTH -1:0] o_seq_id_rx,        // Lookahead sequence id of next packet
    output wire                     o_seq_id_dval,      // Validate lookahead sequence id of next packet
    output wire [8 -1:0]            o_stream_id_rx,     // Lookahead stream id of next packet

    // Status flags
    output wire                     o_empty,            // FIFO empty
    output wire                     o_aempty,           // FIFO almost empty
    output wire                     o_full,             // FIFO full
    output wire                     o_afull             // FIFO almost full

);

    // Data FIFO is composed of 2 BRAM72K FIFO, each set to 144 wide x 512 deep
    // Alongside is the sequence_id fifo which is 10 packets deep, (by 5 bits wide)
    localparam FIFO_DATA_WIDTH = 144;
    localparam NUM_FIFO        = 2;


    // FIFO connections
    logic [(NUM_FIFO*FIFO_DATA_WIDTH) -1:0] fifo_data_in;
    logic [(NUM_FIFO*FIFO_DATA_WIDTH) -1:0] fifo_data_in_d;
    logic [(NUM_FIFO*FIFO_DATA_WIDTH) -1:0] fifo_data_out;
    logic                                   fifo_wren;
    logic                                   fifo_wren_d;
    logic                                   fifo_rden;
    logic [NUM_FIFO -1:0]                   fifo_empty;
    logic [NUM_FIFO -1:0]                   fifo_full;
    logic [NUM_FIFO -1:0]                   fifo_almost_empty;
    logic [NUM_FIFO -1:0]                   fifo_almost_full;
    logic                                   fifos_afull_q;
    logic                                   fifos_afull;
    logic                                   fifo_rden_d;
    logic                                   fifo_dval;
    logic                                   fifo_dval_pend;
    logic                                   fifo_rd_frame;
    logic                                   fifo_rd_frame_q;
    logic                                   if_eth_out_ready_d;
    logic                                   seq_fifo_full;
    logic                                   seq_fifo_empty;

    // Total FIFO width is 288 bits.  Data is buffered as follows
    // [255:0] = data
    // [256]   = sop
    // [257]   = eop
    // When sop asserted [287:258] = timestamp (30 bits)
    // When not sop      [276:258] = {seq_id, err_stat, err, mod} (19 bits)

    // Data input to fifo
    always_comb
    begin
        fifo_data_in[0 +: `ACX_NAP_ETH_DATA_WIDTH] = if_eth_in.data;
        fifo_data_in[`ACX_NAP_ETH_DATA_WIDTH]      = if_eth_in.sop;
        fifo_data_in[`ACX_NAP_ETH_DATA_WIDTH + 1]  = if_eth_in.eop;
        if( if_eth_in.sop )
            fifo_data_in[`ACX_NAP_ETH_DATA_WIDTH + 2 +: 30]   = if_eth_in.timestamp;
        else
            fifo_data_in[`ACX_NAP_ETH_DATA_WIDTH + 2 +: 30]   = {11'b0, if_eth_in.flags.rx.seq_id, 
                                                                 if_eth_in.flags.rx.err_stat, 
                                                                 if_eth_in.flags.rx.err, 
                                                                 if_eth_in.mod} ;
    end

    // Data output from fifo
    always_comb
    begin
        if_eth_out.data      = fifo_data_out[0 +: `ACX_NAP_ETH_DATA_WIDTH];
        if_eth_out.sop       = fifo_data_out[`ACX_NAP_ETH_DATA_WIDTH];
        if_eth_out.eop       = fifo_data_out[`ACX_NAP_ETH_DATA_WIDTH + 1];
        if_eth_out.mod       = fifo_data_out[`ACX_NAP_ETH_DATA_WIDTH + 2 +: `ACX_NAP_ETH_MOD_WIDTH];
        if_eth_out.flags.rx  = (if_eth_out.sop) ? 30'b0 : fifo_data_out[(`ACX_NAP_ETH_DATA_WIDTH+2+`ACX_NAP_ETH_MOD_WIDTH) +: 25];
        if_eth_out.timestamp = (if_eth_out.sop) ? fifo_data_out[(`ACX_NAP_ETH_DATA_WIDTH+2) +: 30] : 30'b0;
    end

    // Pipeline afull signal to NAP ready as this was a critical path.
    // Use double pipeline to allow for signals to traverse die, retiming and fanout, (or fanin)
    // Set afull sufficiently before full, so that FIFO's don't overflow before ready deasserted
    // Downside is that it will take the FIFO 2 cycles longer to start to accept data, so this will
    // impact throughput if FIFO ever overflows.
    always @(posedge i_wr_clk)
    begin
        fifos_afull_q <= (|fifo_almost_full);
        fifos_afull   <= fifos_afull_q;
    end

    // Write to fifo
    // Combinatorial.  Can be registered to improve timing if necessary.  Will add 288 flops
    assign fifo_wren = (if_eth_in.valid & if_eth_in.ready);
    assign if_eth_in.ready = ~(fifos_afull || seq_fifo_full);

    // Input register
    always @(posedge i_wr_clk)
    begin
        fifo_wren_d    <= fifo_wren;
        fifo_data_in_d <= fifo_data_in;
    end

    // Read from fifo
    // Use of outreg_en enables FIFO to meet 507MHz timing
    always @(posedge i_rd_clk)
        fifo_rden_d  <= fifo_rden;

    assign fifo_rd_frame_q = (|fifo_empty == 1'b0) && (if_eth_out.ready == 1'b1) & ~seq_fifo_empty;

    always @(posedge i_rd_clk)
        if( i_reset_n != 1'b1 )
            fifo_rd_frame <= 1'b0;
        else if (if_eth_out.eop & if_eth_out.valid & if_eth_out.ready)
            fifo_rd_frame <= 1'b0;
        else if (fifo_rd_frame_q)
            fifo_rd_frame <= 1'b1;

    // Read whenever there is content and receiver is ready
    // Note seq_fifo_empty will be asserted as it is lookahead.
    assign fifo_rden =  (|fifo_empty == 1'b0) && (if_eth_out.ready == 1'b1) && (fifo_rd_frame | fifo_rd_frame_q);

    // Delay valid signal according to FIFO output register
    assign fifo_dval = (OUTREG_EN) ? fifo_rden_d : fifo_rden;    

    // Bus requires valid & ready together.
    // If OUTREG_EN, then fifo_dval is 1 cycle behind ready.  Need to account
    // for situation where ready is deasserted.
    always @(posedge i_rd_clk)
        if( i_reset_n != 1'b1 )
            fifo_dval_pend <= 1'b0;
        else if( fifo_dval & ~if_eth_out.ready && (OUTREG_EN != 0))
            fifo_dval_pend <= 1'b1;
        else if (if_eth_out.ready)
            fifo_dval_pend <= 1'b0;

    always @(posedge i_rd_clk)
        if_eth_out_ready_d <= if_eth_out.ready;

    // Do not assert valid when ready not asserted, downstream switch will fail.
    assign if_eth_out.valid = (fifo_dval | fifo_dval_pend) & if_eth_out.ready;

    generate for (genvar kk=0; kk < NUM_FIFO; kk++) begin : gb_fifo
        ACX_BRAM72K_FIFO #(
            .aempty_threshold    (AEMPTY_THRESHOLD),
            .afull_threshold     (AFULL_THRESHOLD),
            .ecc_decoder_enable  (0),
            .ecc_encoder_enable  (0),
            .fwft_mode           (0),
            .outreg_enable       (OUTREG_EN),
            .rdclk_polarity      ("rise"),
            .read_width          (FIFO_DATA_WIDTH),
            .sync_mode           (FIFO_SYNC_MODE),
            .wrclk_polarity      ("rise"),
            .write_width         (FIFO_DATA_WIDTH)
        ) i_fifo_l ( 
            .din                 ((INREG_EN==1) ?
                                     (fifo_data_in_d[(kk*FIFO_DATA_WIDTH) +: FIFO_DATA_WIDTH]) : 
                                     (fifo_data_in  [(kk*FIFO_DATA_WIDTH) +: FIFO_DATA_WIDTH]) ),
            .wrclk               (i_wr_clk),
            .rdclk               (i_rd_clk),
            .wren                ((INREG_EN==1)? fifo_wren_d : fifo_wren),
            .rden                (fifo_rden),
            .rstn                (i_reset_n),
            .dout                (fifo_data_out[(kk*FIFO_DATA_WIDTH) +: FIFO_DATA_WIDTH]),
            .sbit_error          (),
            .dbit_error          (),
            .almost_full         (fifo_almost_full[kk]),
            .full                (fifo_full[kk]),
            .almost_empty        (fifo_almost_empty[kk]),
            .empty               (fifo_empty[kk]),
            .write_error         (),
            .read_error          ()
        );
    end
    endgenerate

    // Sequence ID FIFO.  14 entries deep
    // Sequence ID FIFO can be made deeper.  BRAM fifo is storing 16KB data.
    // Sequence ID FIFO should then match average packet length.  If 1500 is used, the 14 should be sufficient.
    // Increasing the depth will add to the number of flops required, and possibly make timing closure more difficult
    localparam SEQ_ID_FIFO_DEPTH     = 14;
    localparam SEQ_ID_FIFO_PTR_WIDTH = $clog2(SEQ_ID_FIFO_DEPTH);

    logic [(SEQ_ID_WIDTH+8) -1:0]      seq_fifo [SEQ_ID_FIFO_DEPTH-1:0] /* synthesis syn_ramstyle="registers" */;
    logic [SEQ_ID_FIFO_PTR_WIDTH -1:0] seq_fifo_wr_ptr;
    logic [SEQ_ID_FIFO_PTR_WIDTH -1:0] seq_fifo_rd_ptr;
    logic [SEQ_ID_FIFO_PTR_WIDTH -1:0] next_seq_fifo_wr_ptr;
    logic [SEQ_ID_FIFO_PTR_WIDTH -1:0] seq_fifo_wr_ptr_plus2;   // Lookahead for full flag
    logic [SEQ_ID_FIFO_PTR_WIDTH -1:0] next_seq_fifo_rd_ptr;
    logic [SEQ_ID_WIDTH -1:0]          seq_id_rx;
    logic                              seq_id_dval;
    logic                              in_sop_d;
    logic                              seq_fifo_wr;
    logic                              seq_fifo_rd;
    logic [8 -1:0]                     stream_id_rx;
    logic [8 -1:0]                     stream_id_d;

    // First cycle after sop, extract seq_id
    // Delay stream id to match seq_id
    always @(posedge i_wr_clk)
        if( i_reset_n != 1'b1 )
            in_sop_d <= 0;
        else if( if_eth_in.valid & if_eth_in.ready )
        begin
            in_sop_d    <= if_eth_in.sop;
            // For this example design we are using the first 8 bits of the MAC address
            // as the stream ID. Customer designs may wish to use a different identifier
            if( if_eth_in.sop )
                stream_id_d <= if_eth_in.data[0 +: 8];
        end

    assign seq_fifo_wr = (in_sop_d & if_eth_in.valid & if_eth_in.ready);

    // Write to seq_id FIFO
    always @(posedge i_wr_clk)
    begin
        if( i_reset_n != 1'b1 )
            seq_fifo_wr_ptr <= 0;
        else if( seq_fifo_wr )
        begin
            // Advance write pointer each time sop is written
            seq_fifo[seq_fifo_wr_ptr] <= {stream_id_d, if_eth_in.flags.rx.seq_id};
            seq_fifo_wr_ptr <= next_seq_fifo_wr_ptr;
        end
    end

    assign seq_fifo_rd = (if_eth_out.sop & if_eth_out.valid & if_eth_out.ready);

    // Read from seq_id FIFO
    // REVISIT - currently coded to only support synchronous clocks.  To be extended in future release
    always @(posedge i_rd_clk)
    begin
        // Lookahead read of the next sequence id
        {stream_id_rx, seq_id_rx}  <= seq_fifo[seq_fifo_rd_ptr];
        seq_id_dval <= ~seq_fifo_empty;
        if( i_reset_n != 1'b1 )     // REVISIT - will need rd_clk synchronised reset
            seq_fifo_rd_ptr <= 0;
        else if( seq_fifo_rd )
            // Advance read pointer each time sop is read out
            seq_fifo_rd_ptr <= next_seq_fifo_rd_ptr;
    end

    // To improve timing, code full flag as synchronous
    always @(posedge i_wr_clk)
    begin
        if( i_reset_n != 1'b1 )
            seq_fifo_full <= 1'b0;
        // Lookahead, assert full if a write is about to occur that will fill the fifo
        // Code as parallel case rather than priority, this improves timing
        else
            case ( {seq_fifo_wr, seq_fifo_rd} )
                2'b00 : seq_fifo_full <= seq_fifo_full;
                2'b01 : seq_fifo_full <= 1'b0;
                2'b10 : seq_fifo_full <= (seq_fifo_wr_ptr_plus2 == seq_fifo_rd_ptr);
                2'b11 : seq_fifo_full <= seq_fifo_full;
            endcase
    end

    // Sequence ID FIFO flags
    // REVISIT - it is these that will need coding for asynchronous clocks
    //           Currently only set for synchronous clocks
    assign next_seq_fifo_wr_ptr  = (seq_fifo_wr_ptr == (SEQ_ID_FIFO_DEPTH-1)) ? 0 : (seq_fifo_wr_ptr + 1);
    assign next_seq_fifo_rd_ptr  = (seq_fifo_rd_ptr == (SEQ_ID_FIFO_DEPTH-1)) ? 0 : (seq_fifo_rd_ptr + 1);
    assign seq_fifo_wr_ptr_plus2 = (next_seq_fifo_wr_ptr == (SEQ_ID_FIFO_DEPTH-1)) ? 0 : (next_seq_fifo_wr_ptr + 1);
    assign seq_fifo_empty = (seq_fifo_wr_ptr == seq_fifo_rd_ptr);

    // Assign outputs
    assign o_seq_id_rx    = seq_id_rx;
    assign o_stream_id_rx = stream_id_rx;
    assign o_seq_id_dval  = seq_id_dval;
    assign o_afull        = fifos_afull;
    assign o_aempty       = (|fifo_almost_empty);
    assign o_empty        = (|fifo_empty || seq_fifo_empty);
    assign o_full         = (|fifo_full  || seq_fifo_full);

endmodule : eth_fifo_256x512k

