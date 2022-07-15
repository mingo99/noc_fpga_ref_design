// ------------------------------------------------------------------
//
// Copyright (c) 2021 Achronix Semiconductor Corp.
// All Rights Reserved.
//
// This Software constitutes an unpublished work and contains
// valuable proprietary information and trade secrets belonging
// to Achronix Semiconductor Corp.
//
// Permission is hereby granted to use this Software including
// without limitation the right to copy, modify, merge or distribute
// copies of the software subject to the following condition:
//
// The above copyright notice and this permission notice shall
// be included in in all copies of the Software.
//
// The Software is provided “as is” without warranty of any kind
// expressed or implied, including  but not limited to the warranties
// of merchantability fitness for a particular purpose and non-infringement.
// In no event shall the copyright holder be liable for any claim,
// damages, or other liability for any damages or other liability,
// whether an action of contract, tort or otherwise, arising from, 
// out of, or in connection with the Software
//
// ------------------------------------------------------------------
// Generate random packets, to random or linear addresses using AXI bus
//      Designed to input to NAPs to then exercise IP via the NOC
// ------------------------------------------------------------------

`include "nap_interfaces.svh"

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

    parameter   AXI_ADDR_WIDTH          = 0,        // Width of axi_if address field.  Necessary as synthesis unable to extract using $bits()
    parameter logic [TGT_DATA_WIDTH-1:0] RAND_DATA_INIT = {TGT_DATA_WIDTH{1'b0}} // Random value to start the data at
                                                                           // Can be used to uniqify each axi_pkt_gen instance
)
(
    // Inputs
    input  wire                         i_clk,
    input  wire                         i_reset_n,      // Negative synchronous reset
    input  wire                         i_start,        // Start sequence from beginning
    input  wire                         i_enable,       // Generate new packet
    input  wire                         i_max_bursts,   // When set, generate MAX_BURST_LEN sized bursts
                                                        // When not set, increment bursts from 0 to MAX_BURST_LEN

    t_AXI4.master                       axi_if,         // AXI-4 interface.  This is a master

    // Outputs
    output logic                        o_wr_error,     // Asserted if there is an error writing
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
    logic                       write_error;

    // To ensure bursts from this generator do not overlap, pad the address by the maximum burst size.
    // This masking of addresses is purely to support this generator which has varying burst sizes
    // In a user design it is not necessary to pad the address if the user address controller
    // will ensure blocks of data do not overlap
    // clog2 returns the ceiling of the log2 funtion, so sufficient bits even if MAX_BURST_LEN is
    // not a 2^n value
    // This also gives the size of the various burst counters
    localparam MAX_BURST_BITS = $clog2(MAX_BURST_LEN);

    // Calculate number of address bits used per data entry.
    localparam ADDR_BYTE_STEP = $clog2(TGT_DATA_WIDTH/8);
    localparam TGT_BURST_SIZE = $clog2(TGT_DATA_WIDTH/8);

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
    assign o_wr_error           = write_error;

    // Instantiate two random sequence generators, one for data, one for address
    random_seq_gen #(
        .OUTPUT_WIDTH       (TGT_DATA_WIDTH),
        .WORD_WIDTH         (16),
        .LINEAR_COUNT       (LINEAR_PKTS),
        .COUNT_DOWN         (0),
        .INIT_VALUE         (RAND_DATA_INIT)
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
    enum {WR_IDLE, WR_GEN_VALUES, WR_WRITE_ADDR, WR_WRITE_DATA, WR_WAIT_HANDSHAKE, WR_CHK_ENABLE} wr_state;

    assign axi_addr_out = {gen_addr[TGT_ADDR_WIDTH-MAX_BURST_BITS-1:0], {MAX_BURST_BITS{1'b0}} };

    // Generate a new data value as each value is written to AXI, apart from the last value
    assign new_data_val = ~axi_if.wlast && axi_if.wvalid && axi_if.wready;

    // Pre-calculate burst values to improve timing
    always @(posedge i_clk)
        next_burst_len <= burst_len + { {(MAX_BURST_BITS-1){1'b0}}, 1'b1};

    // Must be combinatorial as can change on a cycle basis
    assign next_burst_counter = burst_counter - { {(MAX_BURST_BITS-1){1'b0}}, 1'b1};

    // If required to increment the bursts, then cycle from 0 to MAX_BURST_LEN-1
    // Otherwise fix length to the maximum to get greatest bandwidth
    logic update_burst_len;
    always @(posedge i_clk)
        if( ~i_reset_n || i_max_bursts)
            burst_len <= (MAX_BURST_LEN - 'd1);
        else if (update_burst_len)
        begin
            if (burst_len == (MAX_BURST_LEN - 'd1) )
                burst_len <= {MAX_BURST_BITS{1'b0}};
            else
                burst_len <= next_burst_len;
        end

    always @(posedge i_clk)
    begin
        data_enable      <= 1'b0;
        addr_enable      <= 1'b0;
        written_valid    <= 1'b0;
        update_burst_len <= 1'b0;
        if( ~i_reset_n )
        begin
            wr_state        <= WR_IDLE;
            axi_if.awsize   <= 3'h0;
            axi_if.awburst  <= 2'b00;

            // Not necessary to reset address and data buses
            // Will aid synthesis timing
            axi_if.awlen    <= 'h0;
            axi_if.awlock   <= 1'b0;
            axi_if.awqos    <= 1'b0;
            axi_if.awregion <= 3'h0;
            axi_if.awprot   <= 3'b010;      // Unprivileged, Non-secure, data access
            axi_if.awcache  <= 4'h0;        // Non-bufferable, (i.e. standard memory access)
            axi_if.awid     <= 'h0;

            // Do all handshake signals as non-blocking
            // to prevent simulation race conditions
            axi_if.awvalid  <= 1'b0;
            axi_if.wvalid   <= 1'b0;
            axi_if.bready   <= 1'b0;

        end
        else
        begin
            // Fixed values that do not change
            axi_if.awsize  <= TGT_BURST_SIZE;
            axi_if.awburst <= 2'b01;   // Incrementing bursts.  Fixed bursts are not supported

            case (wr_state)
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
                    begin
                        // State to allow random_seq_gen to create address and data values.
                        // Also sets initial address and data valids
                        wr_state       <= WR_WRITE_ADDR;

                        axi_if.awlen   <= burst_len;
                        axi_if.awvalid <= 1'b1;
                        axi_if.wvalid  <= 1'b1;
                        axi_if.wstrb   <= -1;       // Write to all lanes
                    end

                WR_WRITE_ADDR :
                    begin
                        // Write the address and first data word

                        // AXI spec dicates that valid should be asserted
                        // and should not wait for ready.  This is to prevent deadlocks

                        // Can only have a single cycle of ready & valid for both of address and data cycles.
                        if ( axi_if.awready )
                            axi_if.awvalid <= 1'b0;
                        if ( axi_if.wready )
                            axi_if.wvalid <= 1'b0;

                        // Transfer to data state if
                        //    a) both ready's are seen together
                        //    b) one ready has already been seen, (so valid cleared), and other now present
                        //    c) more than one data beat required
                        // Otherwise transfer to handshake state
                        if ( (axi_if.awready || ~axi_if.awvalid) && (axi_if.wready || ~axi_if.wvalid) )
                        begin
                            if ( axi_if.wlast )
                            begin
                                wr_state <= WR_WAIT_HANDSHAKE;
                                // Assert ready for write response
                                axi_if.bready <= 1'b1;
                                // Clear the valid, otherwise multiple writes will be made
                                axi_if.wvalid <= 1'b0;
                            end
                            else
                            begin
                                wr_state <= WR_WRITE_DATA;
                                axi_if.wvalid   <= 1'b1;
                            end
                        end
                    end


                WR_WRITE_DATA :
                    begin
                        if ( axi_if.wlast && axi_if.wvalid && axi_if.wready )
                        begin
                            wr_state <= WR_WAIT_HANDSHAKE;
                            // Assert ready for write response
                            axi_if.bready <= 1'b1;
                            // Clear the valid, otherwise multiple writes will be made
                            axi_if.wvalid <= 1'b0;
                        end
                        else
                        begin
                            wr_state <= WR_WRITE_DATA;
                            axi_if.wvalid   <= 1'b1;
                        end
                    end

                WR_WAIT_HANDSHAKE :
                    begin
                        // Wait for write response
                        if ( axi_if.bvalid )
                        begin
                            // Check response, issue simulation messages
                            // The write_error flag is set outside of this task
                            // synthesis synthesis_off
                            if ( axi_if.bresp != 0 )
                            begin
                                $error( "%t : AXI write response error %h", $time, axi_if.bresp );
                            end
                            if ( axi_if.bid != axi_if.awid )
                            begin
                                $error( "%t : AXI write response ID error. awid %0x bid %0x", $time, axi_if.awid, axi_if.bid );
                            end
                            // synthesis synthesis_on

                            // Deassert response ready
                            axi_if.bready <= 1'b0;
                            // Increment wid
                            axi_if.awid <= axi_if.awid + 8'h01;
                        

                            // Once data written
                            addr_written  <= axi_addr_out;
                            written_valid <= 1'b1;
                            len_written   <= burst_len;
                            wr_state      <= WR_CHK_ENABLE;
                            update_burst_len <= 1'b1;
                        end
                        else
                            wr_state <= WR_WAIT_HANDSHAKE;
                    end

                WR_CHK_ENABLE :
                    begin
                        // State to allow enable, (via fifo_full) to update
                        wr_state      <= WR_IDLE;
                    end

                default :
                    wr_state    <= WR_IDLE;
            endcase
        end
    end

    always @(posedge i_clk)
    begin
        if (wr_state == WR_GEN_VALUES)
            burst_counter <= burst_len;
        else if (axi_if.wvalid && axi_if.wready)
            burst_counter <= next_burst_counter;
    end

    // Create registed version of wlast
    // Consideratin is that this construct is deeper than (burst_counter == 0)
    // however registering wlast may improve later downstream timing

    // Original assignment
    // assign axi_if.wlast = (burst_counter == 0);
    // New assignment
    always @(posedge i_clk)
        if ( wr_state == WR_GEN_VALUES )
            axi_if.wlast <= (burst_len == 'h0);
        else if (axi_if.wvalid && axi_if.wready)
            axi_if.wlast <= (burst_counter == 'h1);

    // Assign write data
    assign axi_if.wdata = axi_data_out;

    // Synplify P-2019-03x does not support computing width of vector from an interface.
    // localparam ACTIVE_ADDR_WIDTH = $bits(axi_if.awaddr)-$bits(TGT_ADDR_ID)-TGT_ADDR_PAD_WIDTH-ADDR_BYTE_STEP;
    localparam ACTIVE_ADDR_WIDTH = AXI_ADDR_WIDTH-$bits(TGT_ADDR_ID)-TGT_ADDR_PAD_WIDTH-ADDR_BYTE_STEP;
    assign axi_if.awaddr = (TGT_ADDR_PAD_WIDTH>0) ? {TGT_ADDR_ID, {TGT_ADDR_PAD_WIDTH{1'b0}}, axi_addr_out[ACTIVE_ADDR_WIDTH-1:0],
                                                    {ADDR_BYTE_STEP{1'b0}} } :
                                                    {TGT_ADDR_ID, axi_addr_out[ACTIVE_ADDR_WIDTH-1:0], {ADDR_BYTE_STEP{1'b0}} };

    // Code up bid errors explicitly and pipeline
    logic   bid_error;
    // Prevent b_xact being merged with axi_reg_layer handshake signals
    logic   b_xact /* synthesis syn_preserve=1 */;

    // Compare 8 bits and 2 bits.
    always @(posedge i_clk)
        bid_error <= (( axi_if.bid != axi_if.awid ) || (axi_if.bresp != 0));

    always @(posedge i_clk)
        b_xact <= (axi_if.bready & axi_if.bvalid);

    always @(posedge i_clk)
        if ( ~i_reset_n )
            write_error    <= 1'b0;
        else if (b_xact & bid_error)
            write_error    <= 1'b1;

endmodule : axi_pkt_gen

