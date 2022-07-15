// ------------------------------------------------------------------
//
// Copyright (c) 2021  Achronix Semiconductor Corp.
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
// Check packets received from AXI bus
//      Use the same random generators as the axi_pkt_gen.  These will
//      then produce the same random sequence.  Removes requirement to
//      store values in local FIFOs.
//      Designed to read from NAPs, which will then exercise IP via the NOC
// ------------------------------------------------------------------

`include "7t_interfaces.svh"

module axi_pkt_chk
#(
    parameter   LINEAR_PKTS             = 0,        // Set to 1 to make packets have linear counts
    parameter   TGT_ADDR_WIDTH          = 0,        // Target address width.  This is less than the full NAP address width
                                                    // The full address is the concatenation of this address, and the TARGET_ID_ADDR
    parameter   TGT_ADDR_PAD_WIDTH      = 0,        // Target address padding.  Placed between target address and id
    parameter   TGT_ADDR_ID             = 0,        // Target address ID.  Page in NoC address mapping
                                                    // Width of this value + TGT_ADDR_PAD_WIDTH + TGT_ADDR_WIDTH = NAP_AXI_ADDR_WIDTH
    parameter   TGT_DATA_WIDTH          = 0,        // Target data width.
    parameter   AXI_ADDR_WIDTH          = 0         // Width of axi_if address field.  Necessary as synthesis unable to extract using $bits()
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
    logic [7:0]                 rid;
    logic                       data_enable;
    logic                       new_data_read;
    logic                       new_data_read_d;
    logic                       gen_new_value;
    logic                       pkt_compared;

    // Assign packet compared outputs
    assign o_pkt_compared = pkt_compared;

    // Same pulse to trigger data generator and to read address and length in
    assign o_xact_read = data_enable;

    // Instantiate a random sequence generator for the data.
    random_seq_gen #(
        .OUTPUT_WIDTH       (TGT_DATA_WIDTH),
        .WORD_WIDTH         (16),
        .LINEAR_COUNT       (0),        // Random data
        .COUNT_DOWN         (0)
    ) i_data_gen (
        // Inputs
        .i_clk              (i_clk),
        .i_reset_n          (i_reset_n),
        .i_start            (1'b0),
        .i_enable           (data_enable|gen_new_value),
        // Outputs
        .o_dout             (exp_axi_data)
    );

    // Signal when new data has been received
    assign new_data_read = ( axi_if.rvalid && axi_if.rready );

    // Capture the read data
    always @(posedge i_clk)
    begin
        if( new_data_read )
        begin
            rd_axi_data <= axi_if.rdata;
            rid         <= axi_if.rid;
        end
        // Don't create a new value from the last value read, as a new value is generated at the
        // start of a sequence, so new_data_read is looking ahead
        // Only assert when a new value has been read
        gen_new_value <= new_data_read & ~axi_if.rlast;
    end
    // -------------------------------------------------------------------------
    // State machine to read from AXI
    // -------------------------------------------------------------------------
    enum {RD_IDLE, RD_GEN_VALUES, RD_READ} rd_state;
    logic   [3:0] data_error;   // Pipeline to allow for retiming
    logic   id_error;
    // synthesis translate_off
    integer mismatch_message_count = 0;
    // synthesis translate_on

    // Data received check
    always @(posedge i_clk)
    begin
        data_error[3:1] <= data_error[2:0];
        pkt_compared <= 1'b0;
        // Allow for new data to be registered
        new_data_read_d <= new_data_read;
        if( ~i_reset_n )
            data_error[0] <= 1'b0;
        else if( new_data_read_d )
        begin
            // Use full explicit comparison to ensure that 'x' fails
            // This will issue a synthesis warning
            if( exp_axi_data !== rd_axi_data )
            begin
                // synthesis synthesis_off
                if( mismatch_message_count < 20 )
                begin
                    $error( "%t : Read AXI data mismatch.  Got %h Expected %h", $time, rd_axi_data, exp_axi_data );
                    mismatch_message_count <= mismatch_message_count + 1;
                end
                // synthesis synthesis_on
                data_error[0] <= 1'b1;
            end
            // We don't assert gen_new_value on the last word read in.  This can
            // be used to indicate that the final word of the packet has been compared
            if ( ~gen_new_value )
                pkt_compared <= 1'b1;
        end
    end

    always @(posedge i_clk)
    begin
        data_enable <= 1'b0;
        if( ~i_reset_n )
        begin
            rd_state <= RD_IDLE;
            read_axi_data();
        end
        else case (rd_state)
            RD_IDLE :
                if( i_xact_avail )
                begin
                    data_enable  <= 1'b1;
                    rd_state     <= RD_GEN_VALUES;
                end
                else
                    rd_state    <= RD_IDLE;

            RD_GEN_VALUES :
                // State to allow random_seq_gen to create data values.
                // Also allows FIFO to output the address and length
                rd_state <= RD_READ;

            RD_READ :
                begin
                    read_axi_data();    // This will take multiple cycles
                    rd_state <= RD_IDLE;
                end

            default :
                rd_state    <= RD_IDLE;
        endcase
    end

    assign o_pkt_error = data_error[3] | id_error;

    // Register AXI signals to improve timing.
    logic       arready_d /* synthesis syn_maxfan=4 */;
    logic       rvalid_d  /* synthesis syn_maxfan=4 */;
    logic       rlast_d   /* synthesis syn_maxfan=4 */;

    // Improve timing by registering signals
    always @(posedge i_clk)
    begin
        arready_d <= axi_if.arready;
        rvalid_d  <= axi_if.rvalid;
        rlast_d   <= axi_if.rlast;
    end

    // -------------------------------------------------------------------------
    // Task to read data from AXI
    // -------------------------------------------------------------------------
    // Calculate number of address bits used per data entry.
    localparam ADDR_BYTE_STEP = $clog2(TGT_DATA_WIDTH/8);
    localparam TGT_BURST_SIZE = $clog2(TGT_DATA_WIDTH/8);
    localparam ACTIVE_ADDR_WIDTH = AXI_ADDR_WIDTH-$bits(TGT_ADDR_ID)-TGT_ADDR_PAD_WIDTH-ADDR_BYTE_STEP;

    // This task is called within an always @(posedge clk) block
    task read_axi_data;
    begin
        if( ~i_reset_n )
        begin
            axi_if.arid     <= 0;
            axi_if.arqos    <= 0;
            axi_if.arlock   <= 1'b0;
            axi_if.arburst  <= 2'b01;
            axi_if.arregion <= 3'b000;
            axi_if.arprot   <= 3'b010;      // Unprivileged, Non-secure, data access
            axi_if.arcache  <= 4'h0;        // Non-bufferable, (i.e. standard memory access)

            // Do all handshake signals as non-blocking
            // to prevent simulation race conditions
            axi_if.arvalid <= 1'b0;
            axi_if.rready  <= 1'b0;
            id_error       <= 1'b0;
            return;
        end

        // Assert the address, length, size and valid
        axi_if.araddr   <= (TGT_ADDR_PAD_WIDTH>0) ? {TGT_ADDR_ID, {TGT_ADDR_PAD_WIDTH{1'b0}}, i_xact_addr[ACTIVE_ADDR_WIDTH-1:0],
                                                    {ADDR_BYTE_STEP{1'b0}} }:
                                                    {TGT_ADDR_ID, i_xact_addr[ACTIVE_ADDR_WIDTH-1:0], {ADDR_BYTE_STEP{1'b0}} };
        axi_if.arsize   <= TGT_BURST_SIZE;
        axi_if.arlen    <= i_xact_len;
        axi_if.arvalid  <= 1'b1;

        // Wait for ready signal to be asserted
        // Cannot use delayed version as that would issue multiple requests
        while (~axi_if.arready )
            @(posedge i_clk);

        // Clock cycle to register arready & arvalid
        @(posedge i_clk);

        // Clear the valid, otherwise multiple requests will be made
        axi_if.arvalid <= 1'b0;

        // Address registered.  Assert ready to receive
        axi_if.rready  <= 1'b1;

        // Stay in the task until the last byte is received
        while (~(rvalid_d && rlast_d))
            @(posedge i_clk);

        // rid is registered with rvalid & rlast
        if ( rid != axi_if.arid )
        begin
            // synthesis synthesis_off
            $error( "%t : AXI read response ID error. arid %0x rid %0x", $time, axi_if.arid, axi_if.rid );
            // synthesis synthesis_on
            id_error <= 1'b1;
        end

        // Clear the ready
        axi_if.rready <= 1'b0;

        // Increment wid
        axi_if.arid <= axi_if.arid + 8'h01;

    end
    endtask : read_axi_data

endmodule : axi_pkt_chk

