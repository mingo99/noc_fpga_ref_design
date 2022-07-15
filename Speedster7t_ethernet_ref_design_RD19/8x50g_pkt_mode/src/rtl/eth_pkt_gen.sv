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
// Generate IPv4 packets with random or fixed size
// Packet size from 64Bytes to 9022Bytes(Jumbo frame support)
// No VLAN support
// Preamble and FCS insertion by the Ethernet MAC core
// ------------------------------------------------------------------

`include "7t_interfaces.svh"
`include "ethernet_utils.svh"

module eth_pkt_gen
  #(
    parameter   DATA_WIDTH              = `ACX_NAP_ETH_DATA_WIDTH,
    parameter   LINEAR_PAYLOAD          = 0,        // Set to 1 to make payloads have linear counts
    parameter   FIXED_PAYLOAD_LENGTH    = 46,       // Fixed payload Length must be in the range of [46...9000] 
    parameter   RANDOM_LENGTH           = 1,        // Set to 1 to generate packets with random length. When set to 1, FIXED_PAYLOAD_LENGTH will be ignored.
    parameter   PKT_NUM                 = 0,        // Number of packets will be sent. The number must be less than 2^32=4294967296. Set to 0 to make continuous packet generation
    parameter   JUMBO_SUPPORT           = 1,        // Support up to 9k jumbo frame in random packet length mode
    // Test
    parameter   MAC_STREAM_ID           = 0,        // If non-zero, value will be written to first byte of MAC address
                                                    // Used to identify streams in packet mode
    parameter   PKT_COUNT_INSERT        = 0         // Insert a packet count to the second byte of MAC address
    )
    (
    // Inputs
    input wire                  i_clk,
    input wire                  i_reset_n,          // Negative synchronous reset
    input wire                  i_start,            // Start packet generator
    input wire                  i_enable,           // Enable packet generator.  Allows pausing the next packet start
    input wire                  i_hold_eop,         // Hold eop word output until released.  
                                                    // Enables packet ordering based on end of packet
    t_ETH_STREAM.tx             if_eth_tx           // Ethernet stream interface
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
    logic                       pkt_send_ready_d;
    logic [DATA_WIDTH -1:0]     pkt_send_data;
    logic [DATA_WIDTH -1:0]     send_word;
    logic [MOD_WIDTH  -1:0]     pkt_send_mod;

    // Internal signals
    logic [15:0]                payload_len_rand_out; 
    logic [15:0]                payload_len_rand_out_d;
    logic [31:0]                payload_len_int;
    logic [31:0]                payload_len_int_d;
    logic [15:0]                payload_len;        // Random payload length from 46Bytes to 1500Bytes or
                                                    // 9000Bytes depending on JUMBO_SUPPORT
    logic [15:0]                pkt_size_total;     // payload_len + 6Bytes Dest MAC + 6Bytes Src MAC + 2Bytes Length/Type
    logic [15:0]                pkt_byte_cnt;       // Number of remaining Bytes
    logic [32:0]                pkt_cnt;    

    logic [2 :0]                start_d;  
    logic                       pkt_gen_start;
    
    logic                       gen_payload;
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
            mac_header.mac_src_addr[39 -: 8] = (PKT_NUM + pkt_cnt);
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

    always @(posedge i_clk)
    begin
        if( ~i_reset_n )
            pkt_send_state <= PKT_SEND_IDLE;
        else case(pkt_send_state)
            PKT_SEND_IDLE:
            begin
                if (pkt_gen_start) begin
                    pkt_send_state <= PKT_STATE_SOP;
                end else begin
                    pkt_send_state <= PKT_SEND_IDLE;
                end
            end
            PKT_STATE_SOP:
            begin
                if (pkt_send_ready & i_enable) begin                
                    if (pkt_byte_cnt > (2*BYTE_WIDTH)) begin
                        pkt_send_state <= PKT_SEND_PAYLOAD;    
                    end else if (pkt_byte_cnt > (BYTE_WIDTH)) begin
                        // Less than a whole word once this one sent, so go to EoP
                        pkt_send_state <= PKT_STATE_EOP;    
                    end else begin
                        // pkt_cnt is incremented in this state, so cannot be read until next state
                        pkt_send_state <= PKT_SEND_GAP;
                    end
                end else begin
                    pkt_send_state <= PKT_STATE_SOP;
                end
            end
            PKT_SEND_PAYLOAD:
            begin
                if (pkt_send_ready) begin                
                    if (pkt_byte_cnt > (2*BYTE_WIDTH)) begin
                        pkt_send_state <= PKT_SEND_PAYLOAD;    
                    end else begin
                        pkt_send_state <= PKT_STATE_EOP;    
                    end
                end else begin
                    pkt_send_state <= PKT_SEND_PAYLOAD;
                end
            end
            PKT_STATE_EOP:
            begin
                if ( i_hold_eop != 1'b1 )
                begin
                    if (pkt_send_ready) begin
                        pkt_send_state <= PKT_SEND_GAP;
                    end else begin
                        pkt_send_state <= PKT_STATE_EOP;
                    end
                end else begin
                    pkt_send_state <= PKT_STATE_EOP;
                end
            end
            PKT_SEND_GAP:
            begin
                if ( (pkt_cnt[32] == 1'b1) && (PKT_NUM != 0) )
                    pkt_send_state <= PKT_SEND_IDLE;
                else
                    pkt_send_state <= PKT_STATE_SOP;
            end
            default : pkt_send_state <= PKT_SEND_IDLE;

        endcase    
    end    

    always_comb
    begin
        gen_payload = 1'b0;
        case(pkt_send_state)
            PKT_STATE_SOP:
            begin
                if (pkt_send_ready & i_enable) begin                
                    gen_payload = 1'b1;
                end
            end
            PKT_SEND_PAYLOAD:
            begin
                if (pkt_send_ready) begin                
                    gen_payload = 1'b1;
                end
            end
            PKT_STATE_EOP:
            begin
                if ( i_hold_eop != 1'b1 )
                begin
                    gen_payload = 1'b1;
                end
            end
            default : gen_payload = 1'b0;
        endcase
    end    

    assign pkt_send_sop_eop = (pkt_send_state == PKT_STATE_SOP) && ~(pkt_byte_cnt > BYTE_WIDTH);

    //Generate sop, eop and valid
    always @(posedge i_clk)
    begin
        if( ~i_reset_n ) begin
            pkt_send_sop       <= 1'b0;
        end else if (pkt_send_ready) begin
            if (pkt_send_state == PKT_STATE_SOP) begin
                pkt_send_sop   <= 1'b1;
            end else begin    
                pkt_send_sop   <= 1'b0;
            end
        end        
    end
    
    always @(posedge i_clk)
    begin
        if( ~i_reset_n ) begin
            pkt_send_eop       <= 1'b0;
        end else if (pkt_send_ready) begin
            if ((pkt_send_state == PKT_STATE_EOP && (i_hold_eop != 1'b1)) || pkt_send_sop_eop) begin
                pkt_send_eop   <= 1'b1;
            end else begin    
                pkt_send_eop   <= 1'b0;
            end
        end        
    end    
    
    always @(posedge i_clk)
    begin
        pkt_send_ready_d <= pkt_send_ready;
        if( ~i_reset_n ) begin
            pkt_send_valid   <= 1'b0;
        end else if (pkt_send_ready) begin
            if (pkt_send_state == PKT_STATE_SOP  & i_enable) begin
                pkt_send_valid   <= 1'b1;
            end else if (pkt_send_state == PKT_STATE_EOP)
            begin
                if (i_hold_eop == 1'b1)
                    pkt_send_valid   <= 1'b0;
                else
                    pkt_send_valid   <= 1'b1;
            end else if (pkt_send_eop) begin    
                pkt_send_valid   <= 1'b0;
            end
        end        
    end        
    
    // Count the number of packets
    always @(posedge i_clk)
    begin
        if( ~i_reset_n ) begin
            pkt_cnt   <= 33'h100000000 - PKT_NUM;        
        end else if ((pkt_send_state == PKT_STATE_SOP) && pkt_send_ready & i_enable) begin
            pkt_cnt   <= pkt_cnt + 1'b1;    
        end    
    end    
    
    // Count down bytes transmitted        
    always @(posedge i_clk)
    begin
        if( ~i_reset_n )
            pkt_byte_cnt   <= 16'b0;
        else if (pkt_gen_start || (pkt_send_state == PKT_SEND_GAP))
            pkt_byte_cnt   <= pkt_size_total;
        else if ( gen_payload )
            pkt_byte_cnt   <= pkt_byte_cnt - BYTE_WIDTH;
    end

    // Register payload length for the IP header
    always @(posedge i_clk)
        if( ~i_reset_n )
            ip_total_len   <= 16'b0;
        else if ( pkt_gen_start || (pkt_send_state == PKT_SEND_GAP))
            ip_total_len   <= payload_len;

    always @(posedge i_clk)
    begin
        if( ~i_reset_n ) begin
            pkt_send_mod       <= {MOD_WIDTH{1'b0}};
        end else if ((pkt_send_state == PKT_STATE_EOP || pkt_send_sop_eop) && (pkt_send_ready == 1'b1) && (i_hold_eop != 1'b1)) begin
            if (pkt_byte_cnt == BYTE_WIDTH) begin
                pkt_send_mod   <= {MOD_WIDTH{1'b0}};
            end else begin
                pkt_send_mod   <= pkt_byte_cnt;
            end
        end    
        else    
            pkt_send_mod   <= {MOD_WIDTH{1'b0}};
    end
    
    assign payload_enable = (pkt_send_ready && gen_payload) || pkt_gen_start;

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
    localparam FIRST_WORD_OVERFLOW = $bits(ip_header) + $bits(mac_header) - DATA_WIDTH;

    // Instantiate byte order reverse module
    acx_byte_order_reverse #(.DATA_WIDTH(DATA_WIDTH)) i_acx_byte_order_reverse (.in(send_word), .rev(pkt_send_data));

    // Need generate loops for two cases of whether mac and ip header overflow the first word
    generate if( FIRST_WORD_OVERFLOW > 0 ) begin : gb_fw_pos
        always @(posedge i_clk)
        begin
            if( ~i_reset_n ) begin
                send_word <= {DATA_WIDTH{1'b0}};
            end else if (pkt_send_ready) begin
                if (pkt_send_state == PKT_STATE_SOP) begin
                    send_word <= {mac_header, ip_header[$bits(ip_header)-1:FIRST_WORD_OVERFLOW]};
                end else if (pkt_send_sop ) begin
                    send_word     <= {ip_header[FIRST_WORD_OVERFLOW-1:0], payload_stream_out[0 +: (DATA_WIDTH-FIRST_WORD_OVERFLOW)]};
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
                if (pkt_send_state == PKT_STATE_SOP) begin
                    send_word <= {mac_header, ip_header, payload_stream_out[0 +: -FIRST_WORD_OVERFLOW]};
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
    assign if_eth_tx.valid  = (pkt_send_valid & pkt_send_ready_d); 
    assign if_eth_tx.sop    = pkt_send_sop;
    assign if_eth_tx.eop    = pkt_send_eop;
    // Do not drive flags, they can then be driven from outside the generator block
    
endmodule :eth_pkt_gen

