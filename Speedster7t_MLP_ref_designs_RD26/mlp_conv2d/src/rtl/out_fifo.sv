// ------------------------------------------------------------------
//
// Copyright (c) 2019  Achronix Semiconductor Corp.
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
// Output FIFO between convolution and NAP
// Captures convolution output, once full convolution done writes
// results to NAP
// Must be large enough to hold input image / STRIDE results
// ------------------------------------------------------------------

`timescale 1 ps / 1 ps

`include "7t_interfaces.svh"

module out_fifo
#(
    parameter       DATA_WIDTH      = 24,
    parameter       GDDR_ADDR_WIDTH = 30,   // 8Gb = 1GB
    parameter       GDDR_ADDR_ID    = 9'b0, // {5'b0, CTRL_ID}
    parameter       NUM_MLP         = 4,
    parameter       MAX_COLS        = 4
)
(
    // Inputs
    input  wire                     i_clk,
    input  wire                     i_reset_n,              // Negative synchronous reset
    input  t_mlp_out                i_data_in [MAX_COLS -1:0],
    input  wire [MAX_COLS -1:0]     i_wr_en, 
    t_AXI4.master                   nap_out,

    // Outputs
    output wire                     o_idle,
    output wire                     o_bresp_error
);

    t_mlp_out               data_in_d [MAX_COLS-1:0] /* syn_ramtype = registers */;
    t_mlp_out               data_hold;
    wire  [MAX_COLS -1:0]   wr_en;
    logic [6:0]             axi_idle_count;
    logic                   bresp_error;

    // Tie off unused signals in output NAP interface
    assign nap_out.arvalid  = 1'b0;
    assign nap_out.araddr   = 0;
    assign nap_out.arlen    = 0;
    assign nap_out.arid     = 0;
    assign nap_out.arqos    = 0;
    assign nap_out.arburst  = 2'b01;
    assign nap_out.arlock   = 1'b0;
    assign nap_out.arsize   = 0;
    assign nap_out.arregion = 0;
    assign nap_out.rready   = 1'b0;
    assign nap_out.awregion = 0;

    // Fix static signals
    assign nap_out.wstrb    = 32'hffffffff;     // t_mlp_out is 256 bits
    assign nap_out.awsize   = 3'h5;             // Fixed for 32 bytes
    assign nap_out.awlen    = 0;                // All transfers are single beat
    assign nap_out.awlock   = 1'b0;
    assign nap_out.awburst  = 2'b01;
    assign nap_out.awqos    = 1'b0;
    assign nap_out.wlast    = 1'b1;             // All transfers single beat, so wlast always asserted


    // Array of memory address offset values to add to address.
    // Top memory page is set by the addr_rom below
    logic [15:0] addr_offset      [MAX_COLS -1:0]  /* syn_ramtype = registers */;
    logic [15:0] addr_offset_next [MAX_COLS -1:0]  /* syn_ramtype = registers */;
    logic [3:0]  addr_offset_inc;

    // Create a function to initialise ROM array.  In a practical design this array 
    // would probably be set by a processor.
    // Rom points to the memory page within which the results for each column, (up to 16 convolutions), are stored
    localparam ROM_ENTRY_WIDTH = GDDR_ADDR_WIDTH - $bits(addr_offset) - 5;

    // Maximum size of GDDR supported
    localparam MAX_GDDR_ADDR_WIDTH = 33;

    typedef logic [ROM_ENTRY_WIDTH-1:0] rom_entry_t;
    typedef rom_entry_t rom_array_t [MAX_COLS-1:0];

    // Table of address to write results to
    rom_array_t addr_rom;

    // Initial loop allowed to initialise ROMs
    initial
    begin : gb_init_rom
        for( int k=0; k<MAX_COLS; k=k+1 )
            addr_rom[k] = (k * 'h1);
    end


    // Precalculate next value to improve timing.  This could also be multicycle.
    generate for (genvar ii=0; ii<MAX_COLS; ii=ii+1) begin : gb_addr_offset
        always @(posedge i_clk)
            addr_offset_next[ii] <= addr_offset[ii] + 1;
    
        // Latch the incoming data with its associated valid signal
        always @(posedge i_clk)
            if( i_wr_en[ii] )
                data_in_d[ii] <= i_data_in[ii];

        always @(posedge i_clk)
            if( ~i_reset_n )
                addr_offset[ii] <= 16'h0;
            else if ( addr_offset_inc[ii] == 1'b1 )
                addr_offset[ii] <= addr_offset_next[ii];

    end
    endgenerate

    // Purely for simulation visibility, pull data buses out individually
    // synthesis synthesis_off
    t_mlp_out data_in_d0;
    t_mlp_out data_in_d1;
    t_mlp_out data_in_d2;
    t_mlp_out data_in_d3;

    assign data_in_d0 = data_in_d[0];
    assign data_in_d1 = data_in_d[1];
    assign data_in_d2 = data_in_d[2];
    assign data_in_d3 = data_in_d[3];
    // synthesis synthesis_on

    // Assign inputs to internal signals
    assign wr_en = i_wr_en;

    // Create an arbiter for each column output
    // Maximum of 4 columns
    logic [MAX_COLS -1:0]           mlp_req;
    logic                           mlp_req_next;
    logic                           mlp_req_next_d;
    logic [MAX_COLS -1:0]           mlp_ack;
    logic [$clog2(MAX_COLS) -1:0]   arb_count;
    wire  [$clog2(MAX_COLS) -1:0]   arb_count_next;

    generate for( genvar jj=0; jj<MAX_COLS; jj=jj+1 ) begin : gb_arb
        always @(posedge i_clk)
        begin
            if( ~i_reset_n || mlp_ack[jj])
                mlp_req[jj] <= 1'b0;
            else if (wr_en[jj])
                mlp_req[jj] <= 1'b1;

            // Error checking
            // Need to ensure that req is cleared by the time a new wr_en is asserted
            /* synthesis synthesis_off */
            if( i_reset_n )
                as_write_overflow : assert ( !(wr_en[jj] && mlp_req[jj]) ) begin end 
                                        else $error( "%t : wr_en asserted whilst req still pending", $time);
            /* synthesis synthesis_on */

        end
    end
    endgenerate


    // Arbiter state machines
    enum {ADDR_IDLE, ADDR_XFER} addr_state;

    // Pre-calc count
    assign arb_count_next = arb_count + 1;

    // Pre-calc checking next arb
    // Will allow for retiming
    always @(posedge i_clk)
    begin
        mlp_req_next   <= mlp_req[arb_count_next];
        mlp_req_next_d <= mlp_req_next;
    end

    // Address state machine
    always @(posedge i_clk)
    begin
        mlp_ack <= {MAX_COLS{1'b0}};
        addr_offset_inc <= 4'b0000;
        if( ~i_reset_n )
        begin
            arb_count       <= 2'b00;
            addr_state      <= ADDR_IDLE;
            nap_out.awvalid <= 1'b0;
            nap_out.wvalid  <= 1'b0;
            nap_out.awid    <= 8'h00;
        end
        else case (addr_state)
            ADDR_IDLE :
                begin
                    if( mlp_req_next == 1'b1 )
                    begin
                        // As all transfers are single words, assign AW and W on the same cycle
                        // Address is per 32 byte memory location
                        nap_out.awaddr  <= {GDDR_ADDR_ID, {(MAX_GDDR_ADDR_WIDTH-GDDR_ADDR_WIDTH){1'b0}},
                                            addr_rom[arb_count], addr_offset[arb_count], 5'b0_0000};
                        nap_out.awid    <= nap_out.awid + 8'h01;    // Use increasing IDs. Will wrap.
                        nap_out.awvalid <= 1'b1;
                        nap_out.wdata   <= data_in_d[arb_count];
                        nap_out.wvalid  <= 1'b1;
                        addr_state      <= ADDR_XFER;
                    end
                    else
                    begin
                        nap_out.awvalid <= 1'b0;
                        nap_out.wvalid  <= 1'b0;
                        arb_count       <= arb_count_next;
                    end
                end
            ADDR_XFER :
                begin
                    // Parallel threads checking to see if address and data were both registered
                    // fork, join not working, probably as block re-entered on each cycle
                    if( nap_out.awready )
                        nap_out.awvalid <= 1'b0;
                    if( nap_out.wready )
                        nap_out.wvalid <= 1'b0;

                    // Conditions to move to the next state
                    if( (nap_out.awready && nap_out.wready)  ||     // Both ready's asserted
                        (nap_out.awready && ~nap_out.wvalid) ||     // Address ready, data already ack
                        (~nap_out.awvalid && nap_out.wready) )      // Address already ack, data ready
                    begin
                        // Clear the request once the data write has been acknowledged
                        // This will prevent multiple requests
                        // The data value is put into the data pipeline.
                        mlp_ack[arb_count]     <= 1'b1;
                        arb_count              <= arb_count_next;
                        case (arb_count)
                            2'b00 : addr_offset_inc <= 4'b0001;
                            2'b01 : addr_offset_inc <= 4'b0010;
                            2'b10 : addr_offset_inc <= 4'b0100;
                            2'b11 : addr_offset_inc <= 4'b1000;
                        endcase

                        addr_state             <= ADDR_IDLE;
                    end
                    else
                        addr_state <= ADDR_XFER;    // Stay in current state
                end    
        endcase
    end

    // The IDs are monotonically increased.  Therefore check the bresp is good and that the ID matches.
    // Temp for now to acknowledge any write response
    logic [7:0] exp_id;
    always @(posedge i_clk)
    begin
        nap_out.bready <= 1'b0;
        if ( ~i_reset_n )
        begin
            exp_id      <= 8'h01;   // First ID is 0x01
            bresp_error <= 1'b0;
        end
        else
        begin
            if ( nap_out.bvalid )
                nap_out.bready  <= 1'b1;    // Register the acknowledge.  Will clear bvalid

            // Check for correct bresp and ID
            if ( nap_out.bvalid & nap_out.bready )
            begin
                if( (exp_id != nap_out.bid) || (nap_out.bresp != 2'b00) )
                begin
                    bresp_error <= 1'b1;
                    /* synthesis synthesis_off */
                    $error( "%t. Error with Write ack.  Exp ID %02h Actual ID %02h bresp %01h", $time, exp_id, nap_out.bid, nap_out.bresp );
                    /* synthesis synthesis_on */
                end
                exp_id <= exp_id + 8'h01;
            end
        end
    end

    assign o_bresp_error = bresp_error;

    logic reset_idle_count /* synthesis syn_preserve=1 */;

    // Primarily for testbench, generate a signal when the output FIFO block is idle
    always @(posedge i_clk)
    begin
        if ((mlp_req != 0) || (addr_state != ADDR_IDLE) )
            reset_idle_count <= 1'b1;
        else
            reset_idle_count <= 1'b0;

        if ( ~i_reset_n )
            axi_idle_count <= -1;
        else if (reset_idle_count)
            axi_idle_count <= -1;
        else if (axi_idle_count != 0)            
            axi_idle_count <= axi_idle_count - 1;
    end    

    assign o_idle = (axi_idle_count == 0);

endmodule : out_fifo


