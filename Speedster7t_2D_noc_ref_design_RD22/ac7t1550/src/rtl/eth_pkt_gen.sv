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
// Generate IPv4 packets with random or fixed size
// Packet size from 64Bytes to 9022Bytes(Jumbo frame support)
// No VLAN support
// Preamble and FCS insertion by the Ethernet MAC core
// ------------------------------------------------------------------

`include "nap_interfaces.svh"
`include "ethernet_utils.svh"

module eth_pkt_gen
  #(
    parameter   DATA_WIDTH              = `ACX_NAP_ETH_DATA_WIDTH,
    parameter   LINEAR_PAYLOAD          = 0,        // Set to 1 to make payloads have linear counts
    parameter   FIXED_PAYLOAD_LENGTH    = 46,       // Fixed payload Length must be in the range of [46...9000] 
    parameter   RANDOM_LENGTH           = 1,        // Set to 1 to generate packets with random length. When set to 1, FIXED_PAYLOAD_LENGTH will be ignored.
    parameter   JUMBO_SUPPORT           = 1,        // Support up to 9k jumbo frame in random packet length mode
    // Test
    parameter   MAC_STREAM_ID           = 0,        // If non-zero, value will be written to first byte of MAC address
                                                    // Used to identify streams in packet mode
    parameter   PKT_COUNT_INSERT        = 0,        // Insert a packet count to the second byte of MAC address
    parameter   NO_IP_HEADER            = 0         // Set to disable an IP header being included.
    )
    (
    // Inputs
    input wire                  i_clk,
    input wire                  i_reset_n,          // Negative synchronous reset
    input wire                  i_start,            // Start packet generator
    input wire                  i_enable,           // Enable packet generator.  Allows pausing the next packet start
    input wire [32 -1:0]        i_num_pkts,         // How many packets to generate.  If set to 0, then generator will run
                                                    // continously
    input wire                  i_hold_eop,         // Hold eop word output until released.  
                                                    // Enables packet ordering based on end of packet
    input wire                  i_ts_enable,        // Traffic shaper enable
    t_ETH_STREAM.tx             if_eth_tx,          // Ethernet stream interface

    // Outputs
    output logic                o_done              // Indicate when i_num_pkts have been transmitted
    );

    // Block is designed to interface to Ethernet NAP
    // However it supports quad mode where data is 1024 bits wide
    localparam int    BYTE_WIDTH     = DATA_WIDTH/8;
    localparam int    MOD_WIDTH      = $clog2(BYTE_WIDTH);

    // Interface signals
    logic                       pkt_send_sop /* synthesis syn_maxfan=8 */;
    logic                       pkt_send_eop;
    logic                       pkt_send_valid;
    logic                       pkt_send_ready;
    logic [DATA_WIDTH -1:0]     pkt_send_data;
    logic [DATA_WIDTH -1:0]     send_word;
    logic [MOD_WIDTH  -1:0]     pkt_send_mod;

    // Internal signals
    // Following create a 32-bit random value
    logic [15:0]                payload_len_rand_out; 
    logic [15:0]                payload_len_rand_out_d;
    logic [31:0]                payload_len_int;
    logic [31:0]                payload_len_int_d;

    logic [13:0]                payload_len;        // Random payload length from 46Bytes to 1500Bytes or
                                                    // 9000Bytes depending on JUMBO_SUPPORT
                                                    // 9K can be supported in a 14-bit counter, (16K)
    logic [13:0]                pkt_size_total;     // payload_len + 6Bytes Dest MAC + 6Bytes Src MAC + 2Bytes Length/Type
    logic [13:0]                pkt_byte_cnt;       // Number of remaining Bytes

    logic [8 -1:0]              pkt_cnt_slow1;       // Large counter split into four for timing
    logic [8 -1:0]              pkt_cnt_slow2;
    logic [8 -1:0]              pkt_cnt_slow3;
    logic                       pkt_cnt_slow1_co;
    logic                       pkt_cnt_slow2_co;
    logic                       pkt_cnt_slow3_co;
    logic [ 4 -1:0]             pkt_cnt_fast;
    logic [ 8 -1:0]             pkt_cnt_mac;

    logic [2 :0]                start_d;  
    logic                       pkt_gen_start;
    
    logic                       gen_payload;
    logic                       ready_not_valid;
    logic                       payload_enable;
    logic [DATA_WIDTH -1:0]     payload_stream_out;

    // Local variables which are modified within the header
    logic [15:0]                ip_total_len;
    logic [15:0]                ip_checksum;

    // Initialise headers
    t_MAC_HEADER                mac_header;
    t_IP_HEADER                 ip_header;

    // If MAC_STREAM is non-zero, then write this value as the first MAC byte
    // This is then used in multi-stream systems to identify the packet source
    always_comb
    begin
        mac_header = MAC_HEADER_DEFAULT;
        if (MAC_STREAM_ID != 0 )
            mac_header.mac_src_addr[47 -: 8] = MAC_STREAM_ID;
        if (PKT_COUNT_INSERT != 0 )
            mac_header.mac_src_addr[39 -: 8] = pkt_cnt_mac;
    end

    always @(ip_total_len)
    begin
        ip_header          = IP_HEADER_DEFAULT;
        ip_header.pkt_len  = ip_total_len;
        ip_checksum        = calculate_checksum(ip_header);  
        ip_header.checksum = ip_checksum;
    end

    assign pkt_send_ready = if_eth_tx.ready;
    
    // Generate start pulse
    always @(posedge i_clk)
    begin
        if( ~i_reset_n ) begin
            start_d        <= 3'h0;
            pkt_gen_start  <= 1'b0;
        end else begin
            start_d        <= {start_d[1:0], i_start}; 
            pkt_gen_start  <= start_d[1] & !start_d[2];           
        end    
    end    

    // Generate random or fixed packet size
    // Improve timing by registering signals
    always @(posedge i_clk)
    begin
        if( ~i_reset_n ) begin
            payload_len_rand_out   <= 16'h17C2;       //random seed
            payload_len_rand_out_d <= 16'h0;                 
        end else begin
            payload_len_rand_out   <= rand_payload_len(payload_len_rand_out);
            payload_len_rand_out_d <= payload_len_rand_out;    
        end    
    end    

    // Add pipelining to assist with timing
    always @(posedge i_clk)
    begin
        // Random payload length from 46 to 1500 if JUMBO_SUPPORT set to 0
        // Random payload length from 46 to 9000 if JUMBO_SUPPORT set to 1
        payload_len_int_d <= payload_len_int + {16'd46,16'd0};
        if( ~i_reset_n ) begin
            payload_len_int <= 32'h0;        
        end else if (JUMBO_SUPPORT == 0) begin
            payload_len_int <= payload_len_rand_out_d * 16'd1454;
        end else begin
            payload_len_int <= payload_len_rand_out_d * 16'd8954;
        end    
    end

    always @(posedge i_clk)
    begin
        if( ~i_reset_n ) begin
            payload_len <= 32'h0;        
        end else if (RANDOM_LENGTH == 1) begin
            payload_len <= payload_len_int_d[31:16] + payload_len_int_d[15];
        end else begin
            payload_len <= FIXED_PAYLOAD_LENGTH;
        end    
    end      

    assign pkt_size_total = payload_len + ($bits(t_MAC_HEADER)/8);     // Payload_len = pkt length + MAC header

    // -------------------------------------------------------------------------
    // State machine to generate IPv4 packets
    // -------------------------------------------------------------------------
    enum {PKT_SEND_IDLE, PKT_STATE_SOP, PKT_SEND_PAYLOAD, PKT_STATE_EOP, PKT_SEND_GAP}
            pkt_send_state;
    logic pkt_send_sop_eop;
    logic continuous_pkts;

    logic state_is_pkt_state_sop   /* synthesis syn_maxfan=32 syn_keep=1 */;
    logic state_is_pkt_state_sop_d /* synthesis syn_maxfan=32 */;
    logic state_is_eop_first_cycle;
    logic extend_eop_state;
    logic inc_mac_count;
    logic inc_pkt_count;

    always @(posedge i_clk)
        continuous_pkts <= (i_num_pkts == 0);
    
    always @(posedge i_clk)
    begin
        state_is_pkt_state_sop   <= 1'b0;
        state_is_eop_first_cycle <= 1'b0;
        inc_mac_count            <= 1'b0;
        inc_pkt_count            <= 1'b0;

        // Next state flag
        if (pkt_send_ready & i_enable & i_ts_enable)
            state_is_pkt_state_sop_d <= state_is_pkt_state_sop;

        if( ~i_reset_n )
        begin
            pkt_send_state   <= PKT_SEND_IDLE;
            o_done           <= 1'b0;
            extend_eop_state <= 1'b0;
        end
        else case(pkt_send_state)
            PKT_SEND_IDLE:
            begin
                if (pkt_gen_start) begin
                    pkt_send_state <= PKT_STATE_SOP;
                    state_is_pkt_state_sop <= 1'b1;
                end else begin
                    pkt_send_state <= PKT_SEND_IDLE;
                end
            end
            PKT_STATE_SOP:
            begin
                if (pkt_send_ready & i_enable & i_ts_enable) begin                
                    if (pkt_byte_cnt > (2*BYTE_WIDTH)) begin
                        pkt_send_state <= PKT_SEND_PAYLOAD;    
                    end else if (pkt_byte_cnt > (BYTE_WIDTH)) begin
                        // Less than a whole word once this one sent, so go to EoP
                        pkt_send_state <= PKT_STATE_EOP;    
                    end else begin
                        // pkt_cnt is incremented in this state, so cannot be read until next state
                        pkt_send_state <= PKT_SEND_GAP;
                        inc_mac_count  <= 1'b1;
                    end
                end else begin
                    pkt_send_state <= PKT_STATE_SOP;
                    state_is_pkt_state_sop <= 1'b1;
                end
            end
            PKT_SEND_PAYLOAD:
            begin
                if (pkt_send_ready & i_ts_enable & ~ready_not_valid) begin                
                    if (pkt_byte_cnt > (2*BYTE_WIDTH)) begin
                        pkt_send_state <= PKT_SEND_PAYLOAD;    
                    end else begin
                        pkt_send_state <= PKT_STATE_EOP;    
                        state_is_eop_first_cycle <= 1'b1;
                        extend_eop_state         <= 1'b0;
                    end
                end else begin
                    pkt_send_state <= PKT_SEND_PAYLOAD;
                end
            end
            PKT_STATE_EOP:
            begin
                // Catch case where pkt_send_ready is deasserted as PKT_STATE_EOP is entered
                // In this situation, stay in eop until the pending work is written
                if (state_is_eop_first_cycle & ~pkt_send_ready)
                    extend_eop_state <= 1'b1;
                else if (pkt_send_ready & i_ts_enable)
                    extend_eop_state <= 1'b0;

                if ( i_hold_eop != 1'b1 )
                begin
                    if (pkt_send_ready & i_ts_enable & ~extend_eop_state) begin
                        pkt_send_state <= PKT_SEND_GAP;
                        inc_mac_count  <= 1'b1;
                    end else begin
                        pkt_send_state <= PKT_STATE_EOP;
                    end
                end else begin
                    pkt_send_state <= PKT_STATE_EOP;
                end
            end
            PKT_SEND_GAP:
            begin
                // Have to account for ready being deasserted as PKT_SEND_GAP entered
                // Cannot progress until eop send
                if (pkt_send_ready & pkt_send_valid)    
                begin
                    if ( (pkt_cnt_slow3_co == 1'b1) && (pkt_cnt_fast == 4'hf) & ~continuous_pkts )
                    begin
                        pkt_send_state <= PKT_SEND_IDLE;
                        o_done         <= 1'b1;
                    end
                    else
                    begin
                        pkt_send_state <= PKT_STATE_SOP;
                        state_is_pkt_state_sop <= 1'b1;
                        inc_pkt_count          <= 1'b1;
                    end
                end
            end
            default : pkt_send_state <= PKT_SEND_IDLE;

        endcase    
    end    

    // Capture case where ready falls, but valid is asserted
    // Need this to prevent extra gen_playload pulse
    always @(posedge i_clk)
        if( ~i_reset_n )
            ready_not_valid <= 1'b0;
        else if (~pkt_send_ready & pkt_send_valid)
            ready_not_valid <= 1'b1;
        else if (gen_payload || (pkt_send_ready & pkt_send_valid & pkt_send_eop))
            ready_not_valid <= 1'b0;

    always_comb
    begin
        gen_payload = 1'b0;
        case(pkt_send_state)
            PKT_STATE_SOP:
            begin
                if (pkt_send_ready & i_enable & i_ts_enable) begin                
                    gen_payload = 1'b1;
                end
            end
            PKT_SEND_PAYLOAD:
            begin
                if (pkt_send_ready & i_ts_enable) begin                
                    gen_payload = 1'b1;
                end
            end
            PKT_STATE_EOP:
            begin
                if ( i_hold_eop != 1'b1 && pkt_send_ready & i_ts_enable)
                begin
                    gen_payload = 1'b1;
                end
            end
            default : gen_payload = 1'b0;
        endcase
    end    

    assign pkt_send_sop_eop = (state_is_pkt_state_sop) && ~(pkt_byte_cnt > BYTE_WIDTH);

    //Generate sop, eop and valid
    always @(posedge i_clk)
    begin
        if( ~i_reset_n ) begin
            pkt_send_sop       <= 1'b0;
        end else if (pkt_send_ready) begin
            if (pkt_send_state == PKT_STATE_SOP & i_ts_enable) begin
                pkt_send_sop   <= 1'b1;
            end else begin    
                pkt_send_sop   <= 1'b0;
            end
        end        
    end
    
    // Generate mod with eop
    always @(posedge i_clk)
    begin
        if( ~i_reset_n ) begin
            pkt_send_eop       <= 1'b0;
            pkt_send_mod   <= {MOD_WIDTH{1'b0}};
        end else if (pkt_send_ready & ~extend_eop_state) begin
            if ((pkt_send_state == PKT_STATE_EOP && (i_hold_eop != 1'b1) & i_ts_enable) || pkt_send_sop_eop) begin
                pkt_send_eop   <= 1'b1;
                if (pkt_byte_cnt == BYTE_WIDTH) begin
                    pkt_send_mod   <= {MOD_WIDTH{1'b0}};
                end else begin
                    pkt_send_mod   <= pkt_byte_cnt;
                end
            end else if ( pkt_send_eop & pkt_send_valid ) begin    
                pkt_send_eop   <= 1'b0;
                pkt_send_mod   <= {MOD_WIDTH{1'b0}};
            end
        end        
    end    
    
    always @(posedge i_clk)
    begin
        pkt_send_valid   <= 1'b0;

        case(pkt_send_state)
            PKT_STATE_SOP:
            begin
                if (pkt_send_ready & i_enable & i_ts_enable) begin                
                    pkt_send_valid <= 1'b1;
                end
            end
            PKT_SEND_PAYLOAD:
            begin
                if (pkt_send_ready & i_ts_enable) begin                
                    pkt_send_valid <= 1'b1;
                end
            end
            PKT_STATE_EOP:
            begin
                if (i_hold_eop != 1'b1 && pkt_send_ready & i_ts_enable) begin
                    pkt_send_valid <= 1'b1;
                end
            end
            PKT_SEND_GAP:
            begin
                // In this state, need a single cycle of ready & valid if ready got deasserted during PKT_STATE_EOP
                // Once ready & valid are asserted, the main state machine moves to PKT_STATE_SOP
                if (pkt_send_ready & i_ts_enable & ready_not_valid & ~pkt_send_valid) begin                
                    pkt_send_valid <= 1'b1;
                end
            end

            default : pkt_send_valid <= 1'b0;

        endcase    
    end        
    
    // Count the number of packets
    // Split the counter into a fast 4-bit counter than can be incremented on every cycle
    // (necessary when BYTE_WIDTH > 60, so a packet per cycle), and a slower 24-bit counter
    // made of 3x 8-bit counters which only increments every 16 packets.
    logic [24 -1:0] pkt_cnt_start_value;
    // CDC here, but i_num_pkts should be stable when pkt_gen_start is asserted
    assign pkt_cnt_start_value = (24'h00_0000 - {1'b0, i_num_pkts[26:4]});
    logic [3:0]     inc_pkt_cnt;

    always @(posedge i_clk)
        inc_pkt_cnt <= {inc_pkt_cnt[2:0], (inc_pkt_count && (pkt_cnt_fast == 4'h0))};

    always @(posedge i_clk)
    begin
        if( pkt_gen_start )
        begin
            pkt_cnt_slow1    <= pkt_cnt_start_value[7:0];
            pkt_cnt_slow1_co <= 1'b0;
        end
        else if (inc_pkt_cnt[0])
        begin
            pkt_cnt_slow1    <= pkt_cnt_slow1 + 8'd1;
            pkt_cnt_slow1_co <= (pkt_cnt_slow1 == 8'hff);
        end
    end

    always @(posedge i_clk)
    begin
        if( pkt_gen_start )
        begin
            pkt_cnt_slow2    <= pkt_cnt_start_value[15:8];
            pkt_cnt_slow2_co <= 1'b0;
        end
        else if (inc_pkt_cnt[1] )
        begin
            if (pkt_cnt_slow1_co)
            begin
                pkt_cnt_slow2    <= pkt_cnt_slow2 + 8'd1;
                pkt_cnt_slow2_co <= (pkt_cnt_slow2 == 8'hff);
            end
            else
            begin
                pkt_cnt_slow2    <= pkt_cnt_slow2;
                pkt_cnt_slow2_co <= 1'b0;
            end
        end
    end

    always @(posedge i_clk)
    begin
        if( pkt_gen_start )
        begin
            pkt_cnt_slow3    <= pkt_cnt_start_value[23:16];
            pkt_cnt_slow3_co <= 1'b0;
        end
        else if (inc_pkt_cnt[2])
        begin
            if (pkt_cnt_slow2_co)
            begin
                pkt_cnt_slow3    <= pkt_cnt_slow3 + 8'd1;
                pkt_cnt_slow3_co <= (pkt_cnt_slow3 == 8'hff);
            end
            else
            begin
                pkt_cnt_slow3    <= pkt_cnt_slow3;
                pkt_cnt_slow3_co <= 1'b0;
            end
        end
    end

    always @(posedge i_clk)
    begin
        if( pkt_gen_start ) begin
            pkt_cnt_fast <= 5'h10 - {1'b0, i_num_pkts[3:0]};  // CDC here, but i_num_pkts should be stable when pkt_gen_start is asserted
        end else if (inc_pkt_count) begin
            pkt_cnt_fast <= pkt_cnt_fast + 4'd1;
        end    
    end    

    // Count down bytes transmitted        
    always @(posedge i_clk)
    begin
        if( ~i_reset_n )
            pkt_byte_cnt   <= 14'b0;
        else if (pkt_gen_start || inc_mac_count)
            pkt_byte_cnt   <= pkt_size_total;
        else if ( gen_payload && ~ready_not_valid)
        begin
            pkt_byte_cnt[13:MOD_WIDTH] <= pkt_byte_cnt[13:MOD_WIDTH] - 'd1;
        end
    end

    // Create a counter to insert into the MAC header
    // Keep separate from the main counter to improve timing
    always @(posedge i_clk)
        if( ~i_reset_n )
            pkt_cnt_mac <= 8'd0;
        else if (inc_mac_count)
            pkt_cnt_mac <= pkt_cnt_mac + 8'd1;

    // Register payload length for the IP header
    always @(posedge i_clk)
        if( ~i_reset_n )
            ip_total_len   <= 16'b0;
        else if ( pkt_gen_start || inc_mac_count)
            ip_total_len   <= {2'b00, payload_len};
    
    assign payload_enable = (pkt_send_ready && gen_payload && ~ready_not_valid) || pkt_gen_start;

    // Instantiate random sequence generator for data
    random_seq_gen #(
            .OUTPUT_WIDTH       (DATA_WIDTH),
            .WORD_WIDTH         (8),
            .LINEAR_COUNT       (LINEAR_PAYLOAD),  
            .COUNT_DOWN         (0)
            ) 
    i_data_gen (
            // Inputs
            .i_clk              (i_clk),
            .i_reset_n          (i_reset_n),
            .i_start            (1'b1),
            .i_enable           (payload_enable),
            // Outputs
            .o_dout             (payload_stream_out)
            ); 

    // First two words vary based on data width
    localparam FIRST_WORD_OVERFLOW = ((NO_IP_HEADER) ? 0 : $bits(ip_header)) + $bits(mac_header) - DATA_WIDTH;

    // Instantiate byte order reverse module
    acx_byte_order_reverse #(.DATA_WIDTH(DATA_WIDTH)) i_acx_byte_order_reverse (.in(send_word), .rev(pkt_send_data));

    // Need generate loops for two cases of whether mac and ip header overflow the first word
    generate if( FIRST_WORD_OVERFLOW > 0 ) begin : gb_fw_pos
        always @(posedge i_clk)
        begin
            if( ~i_reset_n ) begin
                send_word <= {DATA_WIDTH{1'b0}};
            end else if (pkt_send_ready) begin
                if (state_is_pkt_state_sop) begin
                    send_word <= (NO_IP_HEADER) ? {mac_header[$bits(mac_header)-1:FIRST_WORD_OVERFLOW]} :
                                                  {mac_header, ip_header[$bits(ip_header)-1:FIRST_WORD_OVERFLOW]};
                end else if (state_is_pkt_state_sop_d ) begin
                    send_word <= (NO_IP_HEADER) ? 
                        {mac_header[FIRST_WORD_OVERFLOW-1:0], payload_stream_out[0 +: (DATA_WIDTH-FIRST_WORD_OVERFLOW)]} : 
                        {ip_header[FIRST_WORD_OVERFLOW-1:0], payload_stream_out[0 +: (DATA_WIDTH-FIRST_WORD_OVERFLOW)]};
                end else if (pkt_send_valid) begin
                    send_word     <= payload_stream_out;
                end
            end        
        end           
    end
    else
    begin : gb_fw_neg   //  FIRST_WORD_OVERFLOW <= 0
        always @(posedge i_clk)
        begin
            if( ~i_reset_n ) begin
                send_word <= {DATA_WIDTH{1'b0}};
            end else if (pkt_send_ready) begin
                if (state_is_pkt_state_sop) begin
                    send_word <= (NO_IP_HEADER) ? {mac_header, payload_stream_out[0 +: -FIRST_WORD_OVERFLOW]} :
                                                  {mac_header, ip_header, payload_stream_out[0 +: -FIRST_WORD_OVERFLOW]};
                end else if (pkt_send_valid) begin
                    send_word     <= payload_stream_out;
                end
            end        
        end           
    end
    endgenerate
  
    // -------------------------------------------------------------------------
    // Function to generate 16bit random data
    // -------------------------------------------------------------------------
    function [15:0] rand_payload_len;
        input [15:0] seed;
        begin
            rand_payload_len = seed;
            rand_payload_len = {(rand_payload_len[2] ^ rand_payload_len[4] ^ rand_payload_len[7]), 
                                 rand_payload_len[9] ^ rand_payload_len[13], 
                                 rand_payload_len[6] ^ rand_payload_len[1],
                                 rand_payload_len[15:3]};
        end
    endfunction
    
    assign if_eth_tx.addr   = 0;    // Overwritten by nap_ethernet_wrapper
    assign if_eth_tx.data   = pkt_send_data;
    assign if_eth_tx.mod    = pkt_send_mod;    
    assign if_eth_tx.valid  = pkt_send_valid; 
    assign if_eth_tx.sop    = pkt_send_sop;
    assign if_eth_tx.eop    = pkt_send_eop;
    // Do not drive flags, they can then be driven from outside the generator block
    
endmodule :eth_pkt_gen

