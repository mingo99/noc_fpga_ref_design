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
// Check packets received from AXI bus
//      Use the same random generators as the axi_pkt_gen.  These will
//      then produce the same random sequence.  Removes requirement to
//      store values in local FIFOs.
//      Designed to read from NAPs, which will then exercise IP via the NOC
// ------------------------------------------------------------------

`include "nap_interfaces.svh"

module axi_pkt_chk
#(
    parameter   LINEAR_PKTS             = 0,        // Set to 1 to make packets have linear counts
    parameter   TGT_ADDR_WIDTH          = 0,        // Target address width.  This is less than the full NAP address width
                                                    // The full address is the concatenation of this address, and the TARGET_ID_ADDR
    parameter   TGT_ADDR_PAD_WIDTH      = 0,        // Target address padding.  Placed between target address and id
    parameter   TGT_ADDR_ID             = 0,        // Target address ID.  Page in NoC address mapping
                                                    // Width of this value + TGT_ADDR_PAD_WIDTH + TGT_ADDR_WIDTH = NAP_AXI_ADDR_WIDTH
    parameter   TGT_DATA_WIDTH          = 0,        // Target data width.
    parameter   AXI_ADDR_WIDTH          = 0,        // Width of axi_if address field.  Necessary as synthesis unable to extract using $bits()
    parameter logic [TGT_DATA_WIDTH-1:0] RAND_DATA_INIT = {TGT_DATA_WIDTH{1'b0}}, // Random value to start the data at
                                                                           // Can be used to uniqify each axi_pkt_gen instance
    parameter   NO_AR_LIMIT             = 0         // By default, AR's have a minimum gap to prevent GDDR/DDR pipeline reordering
                                                    // However, if this checker is used for just NAP to NAP communication, then this limit
                                                    // can be removed
)
(
    // Inputs
    input  wire                         i_clk,
    input  wire                         i_reset_n,      // Negative synchronous reset
    input  wire                         i_xact_avail,   // Write transaction available to read
    input  wire [TGT_ADDR_WIDTH-1:0]    i_xact_addr,
    input  wire [7:0]                   i_xact_len,

    t_AXI4.master                       axi_if,         // AXI-4 interface.  This is a master

    output logic                        o_xact_read,    // Read the transaction from the fifo
    output logic                        o_pkt_compared, // Assert at the end of each packet comparision
    output logic                        o_pkt_error     // Assert if there is a mismatch.
);

    logic [TGT_DATA_WIDTH-1:0]  exp_axi_data;
    logic [TGT_DATA_WIDTH-1:0]  rd_axi_data;
    logic [7:0]                 arid_pipe [1:0];        // Upto 2 AR's can be issued
    logic [7:0]                 next_arid;
    logic                       read_arid;
    logic                       write_arid;
    logic                       data_enable;
    logic                       data_enable_d;
    logic                       new_data_read;
    logic                       new_data_read_d;
    logic                       new_data_read_2d;
    logic                       new_data_read_3d;
    logic                       gen_new_value;
    logic                       gen_new_value_d;
    logic                       pkt_compared;
    logic                       outstanding_read;
    logic                       ar_issued;
    logic                       new_read_start;
    logic                       data_match;
    logic                       data_match_d;
    logic [6:0]                 ar_space_count;
    logic                       ar_space_count_zero;
    logic                       clear_ar_space_count;

    // Assign packet compared outputs
    assign o_pkt_compared = pkt_compared;

    // Same pulse to trigger data generator and to read address and length in
    assign o_xact_read = data_enable;

    // Instantiate a random sequence generator for the data.
    random_seq_gen #(
        .OUTPUT_WIDTH       (TGT_DATA_WIDTH),
        .WORD_WIDTH         (16),
        .LINEAR_COUNT       (0),        // Random data
        .COUNT_DOWN         (0),
        .INIT_VALUE         (RAND_DATA_INIT)
    ) i_data_gen (
        // Inputs
        .i_clk              (i_clk),
        .i_reset_n          (i_reset_n),
        .i_start            (1'b0),
        .i_enable           (new_read_start|gen_new_value),
        // Outputs
        .o_dout             (exp_axi_data)
    );

    // Signal when new data has been received
    assign new_data_read = ( axi_if.rvalid && axi_if.rready );

    // Capture the read data
    always @(posedge i_clk)
    begin
        rd_axi_data <= axi_if.rdata;

        // Don't create a new value from the last value read, as a new value is generated at the
        // start of a sequence, so new_data_read is looking ahead
        // Only assert when a new value has been read
        gen_new_value <= new_data_read & ~axi_if.rlast;
    end
    // -------------------------------------------------------------------------
    // State machine to read from AXI
    // -------------------------------------------------------------------------
    // -------------------------------------------------------------------------
    // Task to read data from AXI
    // -------------------------------------------------------------------------
    // Calculate number of address bits used per data entry.
    localparam ADDR_BYTE_STEP = $clog2(TGT_DATA_WIDTH/8);
    localparam TGT_BURST_SIZE = $clog2(TGT_DATA_WIDTH/8);
    localparam ACTIVE_ADDR_WIDTH = AXI_ADDR_WIDTH-$bits(TGT_ADDR_ID)-TGT_ADDR_PAD_WIDTH-ADDR_BYTE_STEP;

    enum {AR_IDLE, AR_GEN_VALUES, AR_ISSUE, AR_ACK} ar_state;
    enum {RD_IDLE, RD_WAIT_LAST} rd_state;

    logic           data_error_latch;
    logic   [2:0]   data_error_pipe;   // Pipeline to allow for retiming
    logic           data_error;
    logic           id_error;
    // synthesis synthesis_off
    integer         mismatch_message_count = 0;
    // synthesis synthesis_on

    // Make all flops in the pipeline the same, (i.e. no reset)
    // so that retiming can be done on the compare
    always @(posedge i_clk)
        data_error_pipe <= {data_error_pipe[1:0], data_error};

    always @(posedge i_clk)
        if( ~i_reset_n )
            data_error_latch <= 1'b0;
        else if ( data_error_pipe[2] | id_error )
            data_error_latch <= 1'b1;


    // Use full explicit comparison to ensure that 'x' fails
    // This will issue a synthesis warning
    // Double buffer match signal to allow for retiming
    always @(posedge i_clk)
    begin
        data_match_d <= data_match;
        data_match   <= ( exp_axi_data === rd_axi_data );
    end

    // Data received check
    always @(posedge i_clk)
    begin
        data_error   <= 1'b0;
        // Allow for new data to be registered
        // and for register cycle on data_match
        new_data_read_d  <= new_data_read;
        new_data_read_2d <= new_data_read_d;
        new_data_read_3d <= new_data_read_2d;
        if( new_data_read_3d )
        begin
            if( data_match_d != 1'b1 )
            begin
                // synthesis synthesis_off
                if( mismatch_message_count < 20 )
                begin
                    $error( "%t : Read AXI data mismatch.  Got %h Expected %h", $time, rd_axi_data, exp_axi_data );
                    mismatch_message_count <= mismatch_message_count + 1;
                end
                // synthesis synthesis_on
                data_error <= 1'b1;
            end
        end
    end

    // Indicate when a new packet has been compared
    always @(posedge i_clk)
    begin
        gen_new_value_d <= gen_new_value;
        // We don't assert gen_new_value on the last word read in.  This can
        // be used to indicate that the final word of the packet has been compared
        if( new_data_read_2d & ~gen_new_value_d)
            pkt_compared <= 1'b1;
        else        
            pkt_compared <= 1'b0;
    end

    // i_xact_addr and i_xact_len are only valid the cycle after data_enable is issued
    always @(posedge i_clk)
    begin
        data_enable_d <= data_enable;
        if ( data_enable_d )
        begin
            // Assert the address, length, size and valid
            axi_if.araddr   <= (TGT_ADDR_PAD_WIDTH>0) ? {TGT_ADDR_ID, {TGT_ADDR_PAD_WIDTH{1'b0}}, i_xact_addr[ACTIVE_ADDR_WIDTH-1:0],
                                                        {ADDR_BYTE_STEP{1'b0}} }:
                                                        {TGT_ADDR_ID, i_xact_addr[ACTIVE_ADDR_WIDTH-1:0], {ADDR_BYTE_STEP{1'b0}} };
            axi_if.arlen    <= i_xact_len;
        end
    end

    always @(posedge i_clk)
    begin
        data_enable   <= 1'b0;
        ar_issued     <= 1'b0;
        axi_if.arsize <= TGT_BURST_SIZE;

        if( ~i_reset_n )
        begin
            ar_state        <= AR_IDLE;
            write_arid      <= 1'b0;

            axi_if.arid     <= 'h0;
            axi_if.arqos    <= 'h0;
            axi_if.arlock   <= 1'b0;
            axi_if.arburst  <= 2'b01;
            axi_if.arregion <= 3'b000;
            axi_if.arprot   <= 3'b010;      // Unprivileged, Non-secure, data access
            axi_if.arcache  <= 4'h0;        // Non-bufferable, (i.e. standard memory access)
            axi_if.arvalid  <= 1'b0;

        end
        else case (ar_state)
            AR_IDLE :
                if( i_xact_avail )
                begin
                    data_enable  <= 1'b1;
                    ar_state     <= AR_GEN_VALUES;
                end
                else
                    ar_state     <= AR_IDLE;

            AR_GEN_VALUES :
                // State to allow random_seq_gen to create data values.
                // Also allows FIFO to output the address and length
                // Only issue an AR if we don't already have an outstanding read, (i.e. 2 AR's already issued)
                // Also limit AR's when possibility of back to back could be issued.  This causes GDDR/DDR
                // to reorder their read pipelines resulting in out of order responses.
                // Limit does not apply if previous transaction has completed.
                if ( ~outstanding_read && (NO_AR_LIMIT || ar_space_count_zero))
                    ar_state <= AR_ISSUE;

            AR_ISSUE :
                begin
                    axi_if.arvalid  <= 1'b1;
                    ar_state        <= AR_ACK;
                end

            AR_ACK :
                begin
                    // This state is to wait for the address to be transferred.

                    // Must only have a single cycle of awready & awvalid to ensure only single request issued.
                    if ( axi_if.arready )
                    begin
                        axi_if.arvalid <= 1'b0;
                        ar_issued      <= 1'b1;
                        arid_pipe[write_arid] <= axi_if.arid;
                        write_arid     <= ~write_arid;
                        axi_if.arid    <= axi_if.arid + 8'h01;
                        ar_state       <= AR_IDLE;
                    end
                end

            default :
                ar_state <= AR_IDLE;
        endcase
    end

    // AR limit counter
    // Limit AR requests rate, otherwise memory will reorder responses
    // Only bypass limit if no outstanding reads
    // Priority order important, don't clear counter if on same cycle as ar_issued.
    always @(posedge i_clk)
        if ( ~i_reset_n )
            ar_space_count <= 'd0;
        else if ( ar_issued )
            ar_space_count <= -'d1;
        else if ( clear_ar_space_count )
            ar_space_count <= 'd0;
        else if ( ~ar_space_count_zero )
            ar_space_count <= ar_space_count - 'd1;

    assign ar_space_count_zero = (ar_space_count == 'd0);

    // Read channel state machine
    always @(posedge i_clk)
    begin
        new_read_start       <= 1'b0;
        clear_ar_space_count <= 1'b0;
        if( ~i_reset_n )
        begin
            rd_state         <= RD_IDLE;
            axi_if.rready    <= 1'b0;
            outstanding_read <= 1'b0;
        end
        else case (rd_state)
            RD_IDLE : begin
                if (ar_issued | outstanding_read)
                begin
                    axi_if.rready    <= 1'b1;
                    outstanding_read <= 1'b0;
                    new_read_start   <= 1'b1;
                    rd_state         <= RD_WAIT_LAST;
                end
            end

            RD_WAIT_LAST : begin
                // If an AR is issued whilst we are waiting on a read to complete, then assert
                // outstanding_read.
                // No AR's will be issued whilst there is an outstanding read
                if (ar_issued)
                    outstanding_read <= 1'b1;

                // If end of read, then deassert rready
                // Clear the AR limit counter if there are no further reads
                if (axi_if.rready & axi_if.rvalid & axi_if.rlast)
                begin
                    axi_if.rready        <= 1'b0;
                    rd_state             <= RD_IDLE;
                    clear_ar_space_count <= (~outstanding_read & ~ar_issued);
                end
            end

            default :
                rd_state    <= RD_IDLE;
        endcase
    end

    // Register AXI signals to improve timing.
    logic       arready_d /* synthesis syn_maxfan=4 */;
    logic       rvalid_d  /* synthesis syn_maxfan=4 */;
    logic       rready_d  /* synthesis syn_maxfan=4 */;
    logic       rlast_d   /* synthesis syn_maxfan=4 */;
    logic [7:0] rid_d;

    // Improve timing by registering signals
    always @(posedge i_clk)
    begin
        arready_d <= axi_if.arready;
        rvalid_d  <= axi_if.rvalid;
        rready_d  <= axi_if.rready;
        rlast_d   <= axi_if.rlast;
        rid_d     <= axi_if.rid;
    end

    assign next_arid = arid_pipe[read_arid];

    // Check ID is correct
    always @(posedge i_clk)
    begin
        if( ~i_reset_n )
        begin
            id_error  <= 1'b0;
            read_arid <= 1'b0;
        end
        else if (rvalid_d && rlast_d && rready_d)
        begin
            // rid is registered with rvalid & rlast
            if ( next_arid != rid_d )
            begin
                // synthesis synthesis_off
                $error( "%t : AXI read response ID error. arid %0x rid %0x", $time, next_arid, rid_d );
                // synthesis synthesis_on
                id_error <= 1'b1;
            end
            read_arid <= ~read_arid;
        end
    end

    assign o_pkt_error = data_error_latch;

endmodule : axi_pkt_chk

