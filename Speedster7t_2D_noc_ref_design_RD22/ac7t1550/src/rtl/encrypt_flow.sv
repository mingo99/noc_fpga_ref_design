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
// Speedster7t NoC reference design (RD22)
//      Encryption flow module
//      This module generates a clear text stream and sends it through 
//      the cryptocore to be encrypted.
//      The stream is then sent via horizontal NAPs back to to the core
//      where it is decrypted
//      The decrypted stream is checked against the original source
//      
// ------------------------------------------------------------------

`include "nap_interfaces.svh"

module encrypt_flow #(
    parameter               DATA_WIDTH     = 128,           // Set width of all data streams
    localparam              MOD_WIDTH      = $clog2(DATA_WIDTH/8),  // Width of mod field
    parameter               LINEAR_PAYLOAD = 1              // Set packets to have a linear count in the payload
)
(
    // Inputs
    input  wire                     i_clk,                  // Clock
    input  wire                     i_reset_n,              // Negative synchronous reset
    input  wire                     i_start,                // Assert to start test
    input  wire  [DATA_WIDTH -1:0]  i_core_data_out,        // Data from core
    input  wire                     i_core_busy,            // Core is busy, (initialising)
    input  wire                     i_core_m_req,           // Core is busy, (initialising)

    t_DATA_STREAM.rx                ds_from_nap_encrypt,    // Encrypted data received from horizontal NAP
    t_DATA_STREAM.tx                ds_from_core_encrypt,   // Encrypted data sent to horizontal NAP

    output wire  [DATA_WIDTH -1:0]  o_core_data_in,         // Data to core
    output logic                    o_core_go,              // Start core transfer
    output logic                    o_core_mdata,           // Indicate message data transfer
    output logic                    o_core_last_w,          // Indicate last word to core
    output logic [MOD_WIDTH   -1:0] o_core_last_w_bytes,    // Number of bytes in last word to core
    output logic                    o_core_mode_decrypt,    // Mode core is operating in, (0 = encrypt, 1 = decrypt)
    output wire                     o_fail                  // Assert on data mismatch
);

    // ------------------------------------------------------------------
    // Local signals
    // ------------------------------------------------------------------
    logic   gen_enable;
    logic   chk_enable;

    // ------------------------------------------------------------------
    // Create local data streams for intermediate stages
    // Set to the data width of the core
    // ------------------------------------------------------------------
    t_ETH_STREAM #(
                   .DATA_WIDTH      (DATA_WIDTH),
                   .MOD_WIDTH       (MOD_WIDTH),
                   .ADDR_WIDTH      (`ACX_NAP_DS_ADDR_WIDTH)
    ) eth_from_gen_clear();

    t_ETH_STREAM #(
                   .DATA_WIDTH      (DATA_WIDTH),
                   .MOD_WIDTH       (MOD_WIDTH),
                   .ADDR_WIDTH      (`ACX_NAP_DS_ADDR_WIDTH)
    ) eth_from_core_clear();

    // Function to reverse data bus
    // Needed as mod works in reverse between the generator/checker, (LSB first)
    // and the core, (MSB first).
    function logic [DATA_WIDTH -1:0] reverse_bus ( input [DATA_WIDTH -1:0] in );
        logic [DATA_WIDTH -1:0] out;
        int i;
        for (i=0; i<DATA_WIDTH; i++)
            out[DATA_WIDTH-1-i] = in[i];

        return out;
    endfunction

    // ------------------------------------------------------------------
    // Generate the data to send
    // ------------------------------------------------------------------
    // Use eth_pkt_gen as that supports sop, eop, fixed packet lengths,
    // and new data on each cycle
    // Ethernet stream type is very similar to data streaming type, it
    // just has the addition of some flag fields, which will be disabled in
    // this application.
    eth_pkt_gen #(
        .DATA_WIDTH             (DATA_WIDTH),               // Target data width.
        .LINEAR_PAYLOAD         (LINEAR_PAYLOAD),           // Set to 1 to make packets have linear counts
        .FIXED_PAYLOAD_LENGTH   (242),                      // Fixed payload Length must be in the range of [46...9000] 
        .RANDOM_LENGTH          (1),                        // Set to 1 to generate packets with random length. 
                                                            // When set to 1, FIXED_PAYLOAD_LENGTH will be ignored.
        .JUMBO_SUPPORT          (0),                        // Support up to 9k jumbo frame in random packet length mode
        .PKT_COUNT_INSERT       (0),                        // Insert packet count in MAC address
        .NO_IP_HEADER           (1)                         // As only using 128-bit width, do not include an IP header
    ) i_eth_pkt_gen (
        .i_clk                  (i_clk),
        .i_reset_n              (i_reset_n),                // Negative synchronous reset
        .i_start                (i_start),
        .i_enable               (gen_enable),
        .i_ts_enable            (1'b1),                     // Traffic shaper enable when used for Ethernet packets
        .i_num_pkts             (32'h0),                    // Number of packets will be sent. The number must be less than 2^32.
                                                            // Set to 0 to make continuous packet generation
        .i_hold_eop             (1'b0),
        .if_eth_tx              (eth_from_gen_clear),       // Ethernet stream interface
        .o_done                 ( /* unused */)             // Set when i_num_pkts is completed.
    );

    // Tie-off unused fields of ethernet stream interface
    assign eth_from_gen_clear.timestamp = `ACX_NAP_ETH_FLAG_WIDTH'b0;
    assign eth_from_gen_clear.flags     = `ACX_NAP_ETH_FLAG_WIDTH'b0;

    // ------------------------------------------------------------------
    // Check the received cleartext data
    // ------------------------------------------------------------------
    logic           chk_checksum_error;
    logic           chk_pkt_size_error;
    logic           chk_payload_error;
    logic [32 -1:0] chk_pkt_num;            // Not used
    logic           no_chk_pkts;

    // Packet checker
    eth_pkt_chk #(
        .DATA_WIDTH             (DATA_WIDTH),               // Target data width.
        .LINEAR_PAYLOAD         (LINEAR_PAYLOAD),           // Set to 1 to make packets have linear counts
        .PKT_COUNT_CHECK        (0),                        // Check for packet count in MAC address
        .DOUBLE_REG_INPUT       (1),                        // Double pipeline inputs to improve timing
        .NO_IP_HEADER           (1)                         // As only using 128-bit width, do not include an IP header
    ) i_eth_pkt_chk (
        .i_clk                  (i_clk),
        .i_reset_n              (i_reset_n),                // Negative synchronous reset
        .if_eth_rx              (eth_from_core_clear),      // Ethernet stream interface
        .o_pkt_num              (chk_pkt_num),              // Count the number of received packets
        .o_checksum_error       (chk_checksum_error),       // Assert if check failed
        .o_pkt_size_error       (chk_pkt_size_error),       // Assert if packet size error
        .o_payload_error        (chk_payload_error)         // Assert if there is a mismatch
    );

    // Check that some packets have been transmitted
    always @(posedge i_clk)
        no_chk_pkts <= (chk_pkt_num == 32'b0);

    assign o_fail = chk_checksum_error | chk_pkt_size_error | chk_payload_error | no_chk_pkts;
   
    // ------------------------------------------------------------------
    // FIFO to buffer the data from the NAP
    // ------------------------------------------------------------------
    // This is required as the data to the core has to be muxed between the
    // encrypted data received at the NAP, and the cleartext generated data

    // Set BRAM FIFO to 144-bits to accomodate eop and sop
    localparam  FIFO_WIDTH = 144;
    localparam  FIFO_DATA_PAD = (FIFO_WIDTH - DATA_WIDTH - MOD_WIDTH - 2);

    logic [FIFO_WIDTH -1:0] fifo_data_in;
    logic [FIFO_WIDTH -1:0] fifo_data_out;
    logic                   fifo_wren;
    logic                   fifo_rden;
    logic                   fifo_full;
    logic                   fifo_afull;
    logic                   fifo_empty;

    // Store the eop and sop packet markers along with the data
    assign fifo_data_in = {{FIFO_DATA_PAD{1'b0}}, ds_from_nap_encrypt.data[128 +: MOD_WIDTH], ds_from_nap_encrypt.eop, 
                                                  ds_from_nap_encrypt.sop, ds_from_nap_encrypt.data[127:0]};
    assign fifo_wren    = ds_from_nap_encrypt.valid;
    assign ds_from_nap_encrypt.ready = ~fifo_afull;

    ACX_BRAM72K_FIFO #(
            .aempty_threshold       (6'h4),
            .afull_threshold        (6'h4),
            .fwft_mode              (1'b0),
            .outreg_enable          (1'b1),
            .rdclk_polarity         ("rise"),
            .read_width             (FIFO_WIDTH),
            .sync_mode              (1'b1),
            .wrclk_polarity         ("rise"),
            .write_width            (FIFO_WIDTH)
    ) i_encrypt_data_fifo ( 
            .din                    (fifo_data_in),
            .rstn                   (i_reset_n),
            .wrclk                  (i_clk),
            .rdclk                  (i_clk),
            .wren                   (fifo_wren),
            .rden                   (fifo_rden),
            .dout                   (fifo_data_out),
            .almost_full            (fifo_afull),
            .full                   (fifo_full),
            .almost_empty           (),
            .empty                  (fifo_empty),
            .write_error            (),
            .read_error             (),
            .sbit_error             (),
            .dbit_error             ()
            );

    // ------------------------------------------------------------------
    // State machine to control data flow
    // ------------------------------------------------------------------
    // Future enhancement : Improve throughput by overlapping key import and current transfer

    logic                   decrypt_eop;
    logic                   fifo_out_sop;
    logic                   fifo_out_eop;
    logic                   core_valid_data_out;
    logic                   core_valid_data_start;
    logic                   core_busy_d;
    logic                   gen_enable_fsm;
    logic                   fifo_rden_fsm;
    logic [MOD_WIDTH -1:0]  fifo_out_mod;

    assign  fifo_out_sop = fifo_data_out[DATA_WIDTH];
    assign  fifo_out_eop = fifo_data_out[DATA_WIDTH + 1];
    assign  fifo_out_mod = fifo_data_out[DATA_WIDTH + 2 +: MOD_WIDTH];
    assign  decrypt_eop  = (fifo_out_eop & fifo_rden & i_core_m_req);
    assign  o_core_last_w = eth_from_gen_clear.eop | decrypt_eop;

    enum { IDLE, WAIT_FOR_BUSY, WAIT_ON_BUSY, ENCRYPT_DATA, DECRYPT_DATA, REVERSE_MODE } cc_state;

    // Define encrypt and decryt states, (match definition of core)
    localparam CORE_ENCRYPT = 1'b0;
    localparam CORE_DECRYPT = 1'b1;

    // Generate pulse to start data to core.  Has to be asynchronous to meet 3 clock cycle window

    assign core_valid_data_start = (~i_core_busy & core_busy_d & (cc_state == WAIT_ON_BUSY));

    always @(posedge i_clk)
    begin
        o_core_go           <= 1'b0;
        core_busy_d         <= i_core_busy;

        if ( ~i_reset_n )
        begin
            cc_state             <= IDLE;
            o_core_mode_decrypt  <= CORE_ENCRYPT;
            o_core_mdata         <= 1'b1;           // Design only requests mdata
            fifo_rden_fsm        <= 1'b0;
            gen_enable_fsm       <= 1'b0;
            chk_enable           <= 1'b0;
        end
        else case ( cc_state )
            IDLE : begin
                // If core is idle, start a pass
                if ( ~i_core_m_req && ~i_core_busy && i_start )
                begin
                    // Start decryption cycle if fifo has data
                    // If set to encrypt, start immediately.
                    if ( ((o_core_mode_decrypt == CORE_DECRYPT) && ~fifo_empty && eth_from_core_clear.ready ) || 
                         ((o_core_mode_decrypt == CORE_ENCRYPT) && ds_from_core_encrypt.ready) )
                    begin
                        o_core_go <= 1'b1;
                        cc_state  <= WAIT_FOR_BUSY;
                    end
                end
            end

            WAIT_FOR_BUSY : begin
                if ( i_core_busy )
                    cc_state  <= WAIT_ON_BUSY;
            end

            WAIT_ON_BUSY : begin
                // Waiting on core to import the keys
                if ( ~i_core_busy )
                begin
                    if (o_core_mode_decrypt == CORE_DECRYPT)
                    begin
                        fifo_rden_fsm <= 1'b1;
                        cc_state      <= DECRYPT_DATA;
                    end
                    else
                    begin
                        gen_enable_fsm <= 1'b1;
                        cc_state       <= ENCRYPT_DATA;
                    end
                end
            end

            ENCRYPT_DATA : begin
                if ( eth_from_gen_clear.eop )
                begin
                    cc_state       <= REVERSE_MODE;
                    gen_enable_fsm <= 1'b0;
                end
            end

            DECRYPT_DATA : begin
                if ( fifo_out_eop == 1'b1 )
                begin
                    fifo_rden_fsm  <= 1'b0;
                    cc_state       <= REVERSE_MODE;
                end
                else
                    fifo_rden_fsm  <= 1'b1;

            end

            REVERSE_MODE : begin
                o_core_mode_decrypt <= ~o_core_mode_decrypt;
                cc_state            <= IDLE;
            end

        endcase
    end

    // gen_enable needs to start early enough to get data to core
    assign gen_enable = gen_enable_fsm | (core_valid_data_start & (o_core_mode_decrypt == CORE_ENCRYPT));
    assign fifo_rden  = fifo_rden_fsm  | (core_valid_data_start & (o_core_mode_decrypt == CORE_DECRYPT));


    // Generate a valid signal for when data should be sent to the core
    // Outside of this time need to output 0
    // Assert data one cycle after rising edge of m_req
    // So first 2 cycles of data that cores gets are 0
    // Deassert valid data after last word
    always @(posedge i_clk)
    begin
        if ( ~i_reset_n )
            core_valid_data_out <= 1'b0;
        else if ( core_valid_data_start )
            core_valid_data_out <= 1'b1;
        else if ( o_core_last_w )
            core_valid_data_out <= 1'b0;
    end

    assign eth_from_gen_clear.ready = gen_enable;

    // Output data mux to core
    // As mod is done in reverse, (from msb), reverse data into and out of core
    assign o_core_data_in = (~core_valid_data_out)                ? {DATA_WIDTH{1'b0}} : 
                            (o_core_mode_decrypt == CORE_DECRYPT) ? fifo_data_out[DATA_WIDTH -1:0] : 
                                                                    reverse_bus(eth_from_gen_clear.data);

    // For the ethernet packet generator, mod is the number of bytes in the last word, (0 = all bytes)
    // For the core, mod is number_of_bytes in the last word - 1. (0xf = all bytes)
    assign o_core_last_w_bytes = (eth_from_gen_clear.eop) ? (eth_from_gen_clear.mod - 4'd1) : 
                                 (decrypt_eop )           ? fifo_out_mod :
                                                            {MOD_WIDTH{1'b1}};

    // Construct the decrypted data stream to the checker
    // Delay from the control signals to the core is 2 cycles.
    logic [1:0] chk_sop_pipe;
    logic [1:0] chk_eop_pipe;
    logic [1:0] chk_valid_pipe;
    logic [MOD_WIDTH -1:0]  chk_mod_pipe [1:0];

    always @(posedge i_clk)
    begin
        chk_sop_pipe   <= {chk_sop_pipe[0],   fifo_out_sop};
        chk_eop_pipe   <= {chk_eop_pipe[0],   fifo_out_eop};
        chk_valid_pipe <= {chk_valid_pipe[0], fifo_rden_fsm};
        chk_mod_pipe   <= {chk_mod_pipe[0],   fifo_out_mod};
    end


    always @(posedge i_clk)
    begin
        // Mod works in reverse to generator and checker, (from MSB)
        // So data reversed into and out of core
        eth_from_core_clear.data  <= reverse_bus(i_core_data_out);
        eth_from_core_clear.sop   <= chk_sop_pipe[1];
        eth_from_core_clear.eop   <= chk_eop_pipe[1];
        eth_from_core_clear.valid <= chk_valid_pipe[1];
        eth_from_core_clear.mod   <= chk_mod_pipe[1] + 4'd1;
        eth_from_core_clear.addr  <= `ACX_NAP_DS_ADDR_WIDTH'b0;
    end

    // Tie-off unused fields of ethernet stream interface
    assign eth_from_core_clear.timestamp = `ACX_NAP_ETH_FLAG_WIDTH'b0;
    assign eth_from_core_clear.flags     = `ACX_NAP_ETH_FLAG_WIDTH'b0;

    // Construct the encrypted data stream to the NAP
    // Register signals to improve timing
    // Total delay through core is 2 cycles.  Add 2 to the control signals
    logic [1:0]             gen_sop_pipe;
    logic [1:0]             gen_eop_pipe;
    logic [1:0]             gen_valid_pipe;
    logic [MOD_WIDTH -1:0]  gen_mod_pipe [1:0];

    always @(posedge i_clk)
    begin
        gen_sop_pipe   <= {gen_sop_pipe[0],   eth_from_gen_clear.sop};
        gen_eop_pipe   <= {gen_eop_pipe[0],   eth_from_gen_clear.eop};
        gen_valid_pipe <= {gen_valid_pipe[0], eth_from_gen_clear.valid};
        gen_mod_pipe   <= {gen_mod_pipe[0],   eth_from_gen_clear.mod - 4'd1};
    end

    // Data bus to NAP is composed of data plus mod
    always @(posedge i_clk)
    begin
        ds_from_core_encrypt.data  <= {gen_mod_pipe[1], i_core_data_out};
        ds_from_core_encrypt.sop   <= gen_sop_pipe[1];
        ds_from_core_encrypt.eop   <= gen_eop_pipe[1];
        ds_from_core_encrypt.valid <= gen_valid_pipe[1];
    end
        
endmodule : encrypt_flow

