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
// Check IPv4 packets generated from associated packet generator
// ------------------------------------------------------------------

`include "7t_interfaces.svh"
`include "ethernet_utils.svh"

module eth_pkt_chk
  #(
    parameter   DATA_WIDTH              = `ACX_NAP_ETH_DATA_WIDTH,
    parameter   LINEAR_PAYLOAD          = 0,        // Set to 1 to make packets have linear counts
    parameter   PKT_COUNT_CHECK         = 0,        // Check the packet count in the second byte of MAC address
    parameter   DOUBLE_REG_INPUT        = 0         // Enable to double register input signals for improved timing
    )
    (
    // Inputs
    input wire                  i_clk,
    input wire                  i_reset_n,          // Negative synchronous reset
    t_ETH_STREAM.rx             if_eth_rx,          // Data stream interface
    output wire [31:0]          o_pkt_num,          // Count the number of received packets
    output wire                 o_checksum_error,   // Assert if check failed
    output wire                 o_pkt_size_error,   // Assert if packet size error
    output wire                 o_payload_error     // Assert if there is a mismatch
    );

    // Block is designed to interface to Ethernet NAP
    // However it supports quad mode where data is 1024 bits wide
    localparam int    BYTE_WIDTH     = DATA_WIDTH/8;
    localparam int    MOD_WIDTH      = $clog2(BYTE_WIDTH);
   
    // Interface signals
    logic                       pkt_recv_sop_q;
    logic                       pkt_recv_eop_q;
    logic                       pkt_recv_valid_q;
    logic [DATA_WIDTH -1:0]     pkt_recv_data_q;
    logic [MOD_WIDTH  -1:0]     pkt_recv_mod_q;

    logic                       pkt_recv_sop;
    logic                       pkt_recv_eop;
    logic                       pkt_recv_valid /* synthesis syn_maxfan=16 */;
    logic [DATA_WIDTH -1:0]     pkt_recv_data;
    logic [DATA_WIDTH -1:0]     recv_data_rev;
    logic [MOD_WIDTH  -1:0]     pkt_recv_mod;
    logic                       pkt_recv_ready;    
    
    // Internal signals  
    logic [31:0]                pkt_num;    
    logic [DATA_WIDTH -1:0]     pkt_recv_data_d;
    logic                       pkt_recv_2nd_beat_en;
    // Check checksum
    logic                       pkt_checksum_chk_en;    
    logic [15:0]                ip_checksum;
    logic                       checksum_error;
    // Check packet size
    logic [15:0]                pkt_size_cnt;
    logic [15:0]                act_pkt_size;
    logic                       pkt_size_chk_en;    
    logic                       pkt_size_error;
    // Check payload
    logic [DATA_WIDTH -1:0]     exp_payload_stream;
    logic                       exp_payload_en;
    logic [DATA_WIDTH -1:0]     pkt_recv_data_shift_d; 
    logic                       payload_error;
    logic                       payload_chk_en;

    // Headers
    t_MAC_HEADER                mac_header;
    t_IP_HEADER                 ip_header;
    
    // Create a mask based on the mod value
    logic [BYTE_WIDTH -1:0]     mod_bytemask;
    logic [DATA_WIDTH -1:0]     mod_bitmask_d;
    logic [3:0]                 compare_fail;
    logic                       compare_fail_d;
    logic                       payload_chk_en_d;
    logic                       rx_pkt_count_err;

    
    // Instantiate byte order reverse module
    acx_byte_order_reverse #(.DATA_WIDTH(DATA_WIDTH)) i_acx_byte_order_reverse (.in(if_eth_rx.data), .rev(recv_data_rev));

    // Improve timing by registering signals
    always @(posedge i_clk)
    begin
        pkt_recv_valid_q <= if_eth_rx.valid;
        pkt_recv_eop_q   <= if_eth_rx.eop;
        pkt_recv_sop_q   <= if_eth_rx.sop;
        pkt_recv_mod_q   <= if_eth_rx.mod;
        pkt_recv_data_q  <= recv_data_rev;
    end

    // If necessary, double register signals for timing
    generate if (DOUBLE_REG_INPUT) begin : gb_dbl_reg
        always @(posedge i_clk)
        begin
            pkt_recv_valid    <= pkt_recv_valid_q;
            pkt_recv_eop      <= pkt_recv_eop_q;
            pkt_recv_sop      <= pkt_recv_sop_q;
            pkt_recv_mod      <= pkt_recv_mod_q;
            pkt_recv_data     <= pkt_recv_data_q;
        end
    end
    else
    begin : gb_sgl_reg
        assign pkt_recv_valid = pkt_recv_valid_q;
        assign pkt_recv_eop   = pkt_recv_eop_q;
        assign pkt_recv_sop   = pkt_recv_sop_q;
        assign pkt_recv_mod   = pkt_recv_mod_q;
        assign pkt_recv_data  = pkt_recv_data_q;
    end
    endgenerate

    // Checker is always ready to receive data   
    assign pkt_recv_ready = 1'b1;
    assign if_eth_rx.ready = pkt_recv_ready;  
    
    // Count the number of received packets
    // Delay packet count by one beat, improves timing due to load
    // on control signals
    logic pkt_num_inc;
    always @(posedge i_clk)
    begin
        pkt_num_inc <= (pkt_recv_eop && pkt_recv_ready && pkt_recv_valid);
        if( ~i_reset_n ) begin
            pkt_num   <= 32'b0;
        end else if (pkt_num_inc) begin
            pkt_num   <= pkt_num + 1'b1;
        end    
    end    

    // If enabled, check rx packet count
    // This matches the count being inserted in the packet generators
    generate if ( PKT_COUNT_CHECK != 0 ) begin : gb_pkt_cnt_chk
        logic [7:0] rx_pkt_count;
        logic [7:0] pkt_count_recv;

        assign pkt_count_recv = pkt_recv_data[DATA_WIDTH-16 +: 8];

        always @(posedge i_clk)
        begin
            if( ~i_reset_n )
            begin
                rx_pkt_count     <= 0;
                rx_pkt_count_err <= 1'b0;
            end
            else if (pkt_recv_sop && pkt_recv_ready && pkt_recv_valid)
            begin
                if ( pkt_count_recv != rx_pkt_count )
                begin
                    // synthesis synthesis_off
                    $error( "Packet count mismatch : Got %02h : Expected %02h", pkt_count_recv, rx_pkt_count);
                    // synthesis synthesis_on
                    rx_pkt_count_err <= 1'b1;
                end
                else 
                    rx_pkt_count_err <= 1'b0;

                // Update to current received value
                rx_pkt_count <= pkt_count_recv + 8'h01;
            end
        end
    end
    else begin : gb_no_pkt_cnt_chk
        assign rx_pkt_count_err = 1'b0;
    end        
    endgenerate

    // -------------------------------------------------------------------------
    // Check packet size
    // -------------------------------------------------------------------------
    always @(posedge i_clk)
    begin
        if( ~i_reset_n ) begin
            pkt_size_cnt         <= 16'b0;
        end else if (pkt_recv_ready && pkt_recv_valid) begin
            if (pkt_recv_eop) begin
                // Trap case where eop and sop are on the same cycle
                if (pkt_recv_sop) begin
                    // eop & sop
                    if (|pkt_recv_mod == 1'b0) begin
                        pkt_size_cnt <= BYTE_WIDTH;
                    end else begin
                        pkt_size_cnt <= pkt_recv_mod;
                    end
                end else begin
                    // eop & ~sop
                    if (|pkt_recv_mod == 1'b0) begin
                        pkt_size_cnt <= pkt_size_cnt + BYTE_WIDTH;
                    end else begin
                        pkt_size_cnt <= pkt_size_cnt + pkt_recv_mod;
                    end
                end
            end else if (pkt_recv_sop) begin
                pkt_size_cnt     <= BYTE_WIDTH;
            end else begin
                pkt_size_cnt     <= pkt_size_cnt + BYTE_WIDTH;
            end
        end    
    end

    
    assign act_pkt_size = pkt_size_cnt - ($bits(t_MAC_HEADER)/8);  // IP total length = packet total length - MAC header

    always @(posedge i_clk)
    begin
        if( ~i_reset_n ) begin
            pkt_size_chk_en    <= 1'b0;
        end else if (pkt_recv_eop && pkt_recv_ready && pkt_recv_valid) begin
            pkt_size_chk_en    <= 1'b1;
        end else begin
            pkt_size_chk_en    <= 1'b0;
        end    
    end
    
    // synthesis synthesis_off
    integer pkt_size_message_count = 0;
    // synthesis synthesis_on
    
    always @(posedge i_clk)
    begin
        if( ~i_reset_n ) begin
            pkt_size_error        <= 1'b0;
        end else if (pkt_size_chk_en) begin
            if (act_pkt_size != ip_header.pkt_len) begin
                pkt_size_error    <= 1'b1;
                // synthesis synthesis_off
                if( pkt_size_message_count < 20 )
                begin
                    $error( "Received packet size error.  Got %0h Expected %0h", act_pkt_size, ip_header.pkt_len );
                    pkt_size_message_count    <= pkt_size_message_count + 1;
                end    
                // synthesis synthesis_on                
            end
        end    
    end    
    
    // -------------------------------------------------------------------------
    // Check checksum
    // -------------------------------------------------------------------------
    // Capture ip_header
    always @(posedge i_clk)
    begin
        if( ~i_reset_n ) begin
            pkt_recv_2nd_beat_en        <= 1'b0;
        end else if (pkt_recv_ready && pkt_recv_valid) begin
            if (pkt_recv_sop) begin
                pkt_recv_2nd_beat_en    <= 1'b1; 
            end else begin
                pkt_recv_2nd_beat_en    <= 1'b0;     
            end    
        end    
    end

    always @(posedge i_clk)
    begin
        if (pkt_recv_sop && pkt_recv_ready && pkt_recv_valid) begin
            pkt_recv_data_d    <= pkt_recv_data;
        end    
    end

    // IP header can either be in the first word, or spread across the first two
    // dependent upon DATA_WIDTH
    localparam FIRST_WORD_OVERFLOW = $bits(ip_header) + $bits(mac_header) - DATA_WIDTH;

    // Need generate loops for two cases of whether mac and ip header overflow the first word
    generate if( FIRST_WORD_OVERFLOW > 0 ) begin : gb_fw_pos_hdr
        always @(posedge i_clk)
        begin
            pkt_checksum_chk_en    <= 1'b0;
            if( ~i_reset_n ) begin
                ip_header              <= {$bits(t_IP_HEADER){1'b0}};
                mac_header             <= {$bits(t_MAC_HEADER){1'b0}};
            end else if ( pkt_recv_2nd_beat_en && pkt_recv_ready && pkt_recv_valid ) begin
                // Headers are spread across two words.  MAC header always in the first word.
                mac_header             <= pkt_recv_data_d[DATA_WIDTH-1 -: $bits(t_MAC_HEADER)];
                ip_header[$bits(t_IP_HEADER)-1 : FIRST_WORD_OVERFLOW] <= pkt_recv_data_d[DATA_WIDTH-$bits(t_MAC_HEADER)-1 : 0];
                ip_header[FIRST_WORD_OVERFLOW -1 :0]                  <= pkt_recv_data[DATA_WIDTH-1 -: FIRST_WORD_OVERFLOW];
                pkt_checksum_chk_en    <= 1'b1;
            end
        end
    end
    else
    begin : gb_fw_neg_hdr   //  FIRST_WORD_OVERFLOW <= 0
        always @(posedge i_clk)
        begin
            pkt_checksum_chk_en    <= 1'b0;
            if( ~i_reset_n ) begin
                ip_header              <= {$bits(t_IP_HEADER){1'b0}};
                mac_header             <= {$bits(t_MAC_HEADER){1'b0}};
            end else if ( pkt_recv_sop && pkt_recv_ready && pkt_recv_valid ) begin
                // First word contains all of MAC header and IP header
                mac_header             <= pkt_recv_data[DATA_WIDTH-1 -: $bits(t_MAC_HEADER)];
                ip_header              <= pkt_recv_data[DATA_WIDTH-$bits(t_MAC_HEADER)-1 -: $bits(t_IP_HEADER)];
                pkt_checksum_chk_en    <= 1'b1;
            end
        end
    end
    endgenerate
    
    // synthesis synthesis_off
    integer checksum_message_count = 0;
    // synthesis synthesis_on
    
    always @(posedge i_clk)
    begin
        if( ~i_reset_n ) begin
            checksum_error        <= 1'b0;
        end else if (pkt_checksum_chk_en) begin
            // Calculate the checksum, with the sent checksum the result
            // should be 0.
            ip_checksum            = calculate_checksum(ip_header);
            if (|ip_checksum != 1'b0) begin
                checksum_error    <= 1'b1;
                // synthesis synthesis_off
                if( checksum_message_count < 20 )
                begin
                    $error( "Received packet checksum error.  Got %0h", ip_checksum);
                    checksum_message_count    <= checksum_message_count + 1;
                end    
                // synthesis synthesis_on                
            end
        end    
    end

    // -------------------------------------------------------------------------
    // Check to see if expected payload matches or not
    // -------------------------------------------------------------------------

    // Create mask to only compare the payload
    // Words received start from the LSB.
    // Need generate loops for two cases of whether mac and ip header overflow the first word
    generate if( FIRST_WORD_OVERFLOW > 0 ) begin : gb_fw_pos
        // MAC and IP headers are wider than the data width
        always_comb
        begin
            // First word is all headers
            if( pkt_recv_sop && pkt_recv_ready && pkt_recv_valid )
                mod_bytemask = {BYTE_WIDTH{1'b0}};
            else if (pkt_recv_2nd_beat_en)
            begin
                // If packets are less than or equal to 64 bytes, then second word can have eop
                // If eop and mod is less than full bytes
                if (pkt_recv_eop && (pkt_recv_mod != {MOD_WIDTH{1'b0}}) )
                    mod_bytemask = ((2**pkt_recv_mod)-1'b1);    // EoP and mod!=0
                else
                    mod_bytemask = {BYTE_WIDTH{1'b1}};  // Default

                // Mask off for the header
                mod_bytemask &= { {(BYTE_WIDTH-(FIRST_WORD_OVERFLOW/8)){1'b1}}, {(FIRST_WORD_OVERFLOW/8){1'b0}} };
            end
            else if (pkt_recv_eop)
            begin
                if( pkt_recv_mod == {MOD_WIDTH{1'b0}} )
                    mod_bytemask = {BYTE_WIDTH{1'b1}};          // EoP and mod==0
                else
                    mod_bytemask = ((2**pkt_recv_mod)-1'b1);    // EoP and mod!=0
            end
            else
                mod_bytemask = {BYTE_WIDTH{1'b1}};
        end
    end
    else
    begin : gb_fw_neg   //  FIRST_WORD_OVERFLOW <= 0
        // MAC and IP headers are narrower than the data width
        always_comb
        begin
            // First word has header and data
            if( pkt_recv_sop && pkt_recv_ready && pkt_recv_valid )
            begin
                // Need to support case of sop and eop on the same word, so some header and some data
                if (pkt_recv_eop)
                begin
                    // Generate normal mask
                    if( pkt_recv_mod == {MOD_WIDTH{1'b0}} )
                        mod_bytemask = {BYTE_WIDTH{1'b1}};          // EoP and mod==0
                    else
                        mod_bytemask = ((2**pkt_recv_mod)-1'b1);    // EoP and mod!=0
                    // Mask off for the header
                    mod_bytemask &= { {(0-(FIRST_WORD_OVERFLOW/8)){1'b1}}, {(BYTE_WIDTH+(FIRST_WORD_OVERFLOW/8)){1'b0}} };
                end
                else    // sop & ~eop
                    mod_bytemask = { {(0-(FIRST_WORD_OVERFLOW/8)){1'b1}}, {(BYTE_WIDTH+(FIRST_WORD_OVERFLOW/8)){1'b0}} };
            end
            else if (pkt_recv_eop)
            begin
                if( pkt_recv_mod == {MOD_WIDTH{1'b0}} )
                    mod_bytemask = {BYTE_WIDTH{1'b1}};          // EoP and mod==0
                else
                    mod_bytemask = ((2**pkt_recv_mod)-1'b1);    // EoP and mod!=0
            end
            else
                mod_bytemask = {BYTE_WIDTH{1'b1}};
        end
    end
    endgenerate

    always @(posedge i_clk)
    begin
        if( ~i_reset_n ) begin
            payload_chk_en    <= 1'b0;
        end else begin
            payload_chk_en    <= exp_payload_en;    
        end    
    end
    
    // Improve timing by registering signals
    always @(posedge i_clk)
    begin
        if (exp_payload_en)
        begin
            pkt_recv_data_shift_d         <= pkt_recv_data;     // This aligns with exp_payload_stream.
            // Reverse mask as bytes reversed
            for( int jj=0; jj<BYTE_WIDTH; jj++)
                mod_bitmask_d[(DATA_WIDTH-(8*jj)-1) -: 8] <= {8{mod_bytemask[jj]}};
        end
    end    

    // Break very wide comparison into four, in order to meet 600MHz timing
    // Always run compare, reduces logic levels
    // Reverse mask as bytes reversed
    always @(posedge i_clk)
    begin
        // Add register stage to aid timing
        compare_fail_d <= |compare_fail;
        for( int ii=0; ii<4; ii++)
            compare_fail[ii] <= |((pkt_recv_data_shift_d      [ii*(DATA_WIDTH/4) +: (DATA_WIDTH/4)] ^ 
                                   exp_payload_stream         [ii*(DATA_WIDTH/4) +: (DATA_WIDTH/4)] ) 
                                 & mod_bitmask_d              [ii*(DATA_WIDTH/4) +: (DATA_WIDTH/4)] );
    end
                                       
    // synthesis synthesis_off
    // Variables for message only
    integer mismatch_message_count = 0;
    logic [DATA_WIDTH -1:0] pkt_recv_data_shift_2d;
    logic [DATA_WIDTH -1:0] exp_payload_stream_shift_2d;
    logic [DATA_WIDTH -1:0] pkt_recv_data_shift_3d;
    logic [DATA_WIDTH -1:0] exp_payload_stream_shift_3d;
    // synthesis synthesis_on

    always @(posedge i_clk)
    begin
        // synthesis synthesis_off
        // Values for simulation display only
        pkt_recv_data_shift_2d      <= pkt_recv_data_shift_d;
        exp_payload_stream_shift_2d <= exp_payload_stream;
        pkt_recv_data_shift_3d      <= pkt_recv_data_shift_2d;
        exp_payload_stream_shift_3d <= exp_payload_stream_shift_2d;
        // synthesis synthesis_on

        // Delay check enable to match delayed compare signal
        payload_chk_en_d <= payload_chk_en;

        if( ~i_reset_n ) begin
            payload_error        <= 1'b0;
        end else if (payload_chk_en_d) begin
            if ( compare_fail_d ) begin
                payload_error    <= 1'b1;
                // synthesis synthesis_off
                if( mismatch_message_count < 20 )
                begin
                    $error( "Received packet mismatch.\nGot %0h\nExpected %0h", 
                             pkt_recv_data_shift_3d, exp_payload_stream_shift_3d );
                    mismatch_message_count <= mismatch_message_count + 1;
                end
                // synthesis synthesis_on                    
            end            
        end    
    end

    assign exp_payload_en = (pkt_recv_valid && pkt_recv_ready);

    // Instantiate random sequence for checking received payload
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
            .i_enable           (exp_payload_en),
            // Outputs
            .o_dout             (exp_payload_stream)
            );            
   
    assign o_checksum_error = checksum_error;
    assign o_pkt_num        = pkt_num;
    assign o_payload_error  = payload_error | rx_pkt_count_err;
    assign o_pkt_size_error = pkt_size_error;

endmodule : eth_pkt_chk

