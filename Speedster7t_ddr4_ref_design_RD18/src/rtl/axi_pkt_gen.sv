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
// Generate random packets, to random or linear addresses using AXI bus
//      Designed to input to NAPs to then exercise IP via the NOC
// ------------------------------------------------------------------

`include "7t_interfaces.svh"

module axi_pkt_gen
#(
    parameter   LINEAR_PKTS             = 0,        // Set to 1 to make packets have linear counts
    parameter   LINEAR_ADDR             = 0,        // Set to 1 to have linear addresses
    parameter   TGT_ADDR_WIDTH          = 0,        // Target address width.  This is less than the full NAP address width
                                                    // The full address is the concatenation of this address, and the TARGET_ID_ADDR
    parameter   TGT_ADDR_PAD_WIDTH      = 0,        // Target address padding.  Placed between target address and id
    parameter   TGT_ADDR_ID             = 0,        // Target address ID.  Page in NoC address mapping
                                                    // Width of this value + TGT_ADDR_PAD_WIDTH + TGT_ADDR_WIDTH = NAP_AXI_ADDR_WIDTH
    
    parameter   TGT_DATA_WIDTH          = 0,        // Target data width.
    parameter   MAX_BURST_LEN           = 0,        // Maximum number of AXI beats in a burst

    parameter   AXI_ADDR_WIDTH          = 0         // Width of axi_if address field.  Necessary as synthesis unable to extract using $bits()
)
(
    // Inputs
    input  wire                         i_clk,
    input  wire                         i_reset_n,  // Negative synchronous reset
    input  wire                         i_start,    // Start sequence from beginning
    input  wire                         i_enable,   // Generate new packet

    t_AXI4.master                       axi_if,     // AXI-4 interface.  This is a master

    // Outputs
    output logic [TGT_ADDR_WIDTH-1:0]   o_addr_written,
    output logic [7:0]                  o_len_written,
    output logic                        o_written_valid
);

    logic [TGT_DATA_WIDTH-1:0]  axi_data_out;
    logic [TGT_ADDR_WIDTH-1:0]  axi_addr_out;
    logic [TGT_ADDR_WIDTH-1:0]  addr_written;
    logic [7:0]                 len_written;
    logic                       written_valid;
    logic                       data_start;
    logic                       data_enable;
    logic                       new_data_val;
    logic                       addr_start;
    logic                       addr_enable;

    // To ensure bursts from this generator do not overlap, pad the address by the maximum burst size.
    // This masking of addresses is purely to support this generator which has varying burst sizes
    // In a user design it is not necessary to pad the address if the user address controller
    // will ensure blocks of data do not overlap
    // clog2 returns the ceiling of the log2 funtion, so sufficient bits even if MAX_BURST_LEN is
    // not a 2^n value
    // This also gives the size of the various burst counters
    localparam MAX_BURST_BITS = $clog2(MAX_BURST_LEN);

    // Increment the burst length. Have fixed length for now, later make random or incrementing
    logic [MAX_BURST_BITS-1:0]  burst_len;
    logic [MAX_BURST_BITS-1:0]  next_burst_len;
    logic [MAX_BURST_BITS-1:0]  burst_counter;
    logic [MAX_BURST_BITS-1:0]  next_burst_counter;

    // Random seq blocks commence immedately from start signal
    assign data_start  = i_start;
    assign addr_start  = i_start;

    // Assign outputs
    assign o_addr_written       = addr_written;
    assign o_len_written        = len_written;
    assign o_written_valid      = written_valid;

    // Instantiate two random sequence generators, one for data, one for address
    random_seq_gen #(
        .OUTPUT_WIDTH       (TGT_DATA_WIDTH),
        .WORD_WIDTH         (16),
        .LINEAR_COUNT       (LINEAR_PKTS),
        .COUNT_DOWN         (0)
    ) i_data_gen (
        // Inputs
        .i_clk              (i_clk),
        .i_reset_n          (i_reset_n),
        .i_start            (data_start),
        .i_enable           (data_enable|new_data_val),
        // Outputs
        .o_dout             (axi_data_out)
    );

    // The target address width may not be a multiple of 8, which is what random_seq_eng requires
    // So pad to next highest multiple of 8, and truncate output when used.
    localparam SEQ_ADDR_WIDTH = ((TGT_ADDR_WIDTH % 8) == 0 ) ? TGT_ADDR_WIDTH : (((TGT_ADDR_WIDTH/8)+1)*8);
    logic [SEQ_ADDR_WIDTH-1:0]  gen_addr;

    random_seq_gen #(
        .OUTPUT_WIDTH       (SEQ_ADDR_WIDTH),
        .WORD_WIDTH         (SEQ_ADDR_WIDTH),
        .LINEAR_COUNT       (LINEAR_ADDR),
        .COUNT_DOWN         (0)
    ) i_addr_gen (
        // Inputs
        .i_clk              (i_clk),
        .i_reset_n          (i_reset_n),
        .i_start            (addr_start),
        .i_enable           (addr_enable),
        // Outputs
        .o_dout             (gen_addr)
    );


    // -------------------------------------------------------------------------
    // State machine to write to AXI
    // -------------------------------------------------------------------------
    enum {WR_IDLE, WR_GEN_VALUES, WR_WRITE, WR_CHK_ENABLE} wr_state;

    assign axi_addr_out = {gen_addr[TGT_ADDR_WIDTH-MAX_BURST_BITS-1:0], {MAX_BURST_BITS{1'b0}} };

    // Generate a new data value as each value is written to AXI, apart from the last value
    assign new_data_val = ~axi_if.wlast && axi_if.wvalid && axi_if.wready;

    // Pre-calculate burst values to improve timing
    always @(posedge i_clk)
        next_burst_len <= burst_len + { {(MAX_BURST_BITS-1){1'b0}}, 1'b1};

    // Must be combinatorial as can change on a cycle basis
    assign next_burst_counter = burst_counter - { {(MAX_BURST_BITS-1){1'b0}}, 1'b1};

    always @(posedge i_clk)
    begin
        data_enable    <= 1'b0;
        addr_enable    <= 1'b0;
        written_valid  <= 1'b0;
        if( ~i_reset_n )
        begin
            wr_state  <= WR_IDLE;
            burst_len <= 0;
            write_axi_data();
        end
        else case (wr_state)
            WR_IDLE :
                if( i_enable )
                begin
                    data_enable <= 1'b1;
                    addr_enable <= 1'b1;
                    wr_state    <= WR_GEN_VALUES;
                end
                else
                    wr_state    <= WR_IDLE;

            WR_GEN_VALUES :
                // State to allow random_seq_gen to create address and data values.
                wr_state <= WR_WRITE;

            WR_WRITE :
                begin
                    write_axi_data();   // This will take multiple cycles
                                        // Control will not pass to the next statement until done
                    addr_written  <= axi_addr_out;
                    written_valid <= 1'b1;
                    len_written   <= burst_len;
                    wr_state      <= WR_CHK_ENABLE;
                end

            WR_CHK_ENABLE :
                begin
                    // State to allow enable, (via fifo_full) to update
                    wr_state      <= WR_IDLE;
                    // Update burst length for the next write
                    if( burst_len >= MAX_BURST_LEN-1 )
                        burst_len <= 0;
                    else
                        burst_len <= next_burst_len;
                end

            default :
                wr_state    <= WR_IDLE;
        endcase
    end

    always @(posedge i_clk)
    begin
        if (wr_state == WR_GEN_VALUES)
            burst_counter <= burst_len;
        else if (axi_if.wvalid && axi_if.wready)
            burst_counter <= next_burst_counter;
    end

    // -------------------------------------------------------------------------
    // Task to write to AXI
    // -------------------------------------------------------------------------
    // This task is called within an always @(posedge clk) block
    assign axi_if.wdata = axi_data_out;
    assign axi_if.wlast = (burst_counter == 0);

    // Calculate number of address bits used per data entry.
    localparam ADDR_BYTE_STEP = $clog2(TGT_DATA_WIDTH/8);
    localparam TGT_BURST_SIZE = $clog2(TGT_DATA_WIDTH/8);

    // Synplify P-2019-03x does not support computing width of vector from an interface.
//    localparam ACTIVE_ADDR_WIDTH = $bits(axi_if.awaddr)-$bits(TGT_ADDR_ID)-TGT_ADDR_PAD_WIDTH-ADDR_BYTE_STEP;
    localparam ACTIVE_ADDR_WIDTH = AXI_ADDR_WIDTH-$bits(TGT_ADDR_ID)-TGT_ADDR_PAD_WIDTH-ADDR_BYTE_STEP;
    assign axi_if.awaddr = (TGT_ADDR_PAD_WIDTH>0) ? {TGT_ADDR_ID, {TGT_ADDR_PAD_WIDTH{1'b0}}, axi_addr_out[ACTIVE_ADDR_WIDTH-1:0],
                                                    {ADDR_BYTE_STEP{1'b0}} } :
                                                    {TGT_ADDR_ID, axi_addr_out[ACTIVE_ADDR_WIDTH-1:0], {ADDR_BYTE_STEP{1'b0}} };
    task write_axi_data;
    begin
        if( ~i_reset_n )
        begin
            // Not necessary to reset address and data buses
            // Will aid synthesis timing
            axi_if.awsize   <= 3'h0;
            axi_if.awlen    <= 0;
            axi_if.awlock   <= 1'b0;
            axi_if.awburst  <= 2'b00;
            axi_if.awqos    <= 1'b0;
            axi_if.awregion <= 3'h0;
            axi_if.awprot   <= 3'b010;      // Unprivileged, Non-secure, data access
            axi_if.awcache  <= 4'h0;        // Non-bufferable, (i.e. standard memory access)
            axi_if.awid     <= 0;

            // Do all handshake signals as non-blocking
            // to prevent simulation race conditions
            axi_if.awvalid <= 1'b0;
            axi_if.wvalid  <= 1'b0;
            axi_if.bready  <= 1'b0;
            return;
        end

        // AXI spec dicates that valid should be asserted
        // and should not wait for ready.  This is to prevent deadlocks

        // Assert valid
        axi_if.awsize   <= TGT_BURST_SIZE;
        axi_if.awlen    <= burst_len;
        axi_if.awburst  <= 2'b01;   // Incrementing bursts.  Fixed bursts are not supported
        axi_if.awvalid  <= 1'b1;

        // Wait for ready to be asserted
        while (~axi_if.awready )
            @(posedge i_clk);

        // Clock cycle to register awready & awvalid
        @(posedge i_clk);

        // Clear the valid, otherwise multiple requests will be made
        axi_if.awvalid  <= 1'b0;

        // Address registered
        // Write data until wlast pulse is correctly transferred
        while( ~(axi_if.wlast && axi_if.wvalid && axi_if.wready) )
        begin
            // Assert data, valid and last if necessary
            axi_if.wstrb  <= -1;             // Write to all lanes
            axi_if.wvalid <= 1'b1;

            // Clock cycle per loop iteration
            @(posedge i_clk);
        end

        // Clear the valid, otherwise multiple writes will be made
        axi_if.wvalid <= 1'b0;

        // Assert ready for write response
        axi_if.bready <= 1'b1;

        // Wait for write response
        while( ~axi_if.bvalid )
            @(posedge i_clk);

        // Check response, for now issue simulation message
        // synthesis synthesis_off
        if ( axi_if.bresp != 0 )
            $error( "%t : AXI write response error %h", $time, axi_if.bresp );
        if ( axi_if.bid != axi_if.awid )
            $error( "%t : AXI write response ID error. awid %0x bid %0x", $time, axi_if.awid, axi_if.bid );
        // synthesis synthesis_on

        // Deassert response ready
        axi_if.bready <= 1'b0;
        // Increment wid
        axi_if.awid <= axi_if.awid + 8'h01;

    end
    endtask : write_axi_data

endmodule : axi_pkt_gen

