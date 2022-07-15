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
// Ethernet reference design, RD019
//      Utility function header
//      Defines common IP packet structures and
//      functions for checksum and byte reversal
// ------------------------------------------------------------------

// `include "7t_interfaces.svh"
`ifndef ACX_ETHERNET_UTILS
`define ACX_ETHERNET_UTILS

    // ------------------------------------------------------------------
    // MAC and IP headers structure definitions
    // ------------------------------------------------------------------
    typedef struct packed {
        logic [47:0]            mac_src_addr;   // Source MAC address
        logic [47:0]            mac_dest_addr;  // Destination MAC address
        logic [15:0]            mac_type;       // 0x0800-IP
    } t_MAC_HEADER;


    typedef struct packed {
        // IP header    
        logic [3:0]             version;     // 0100-IPv4  0110-IPv6
        logic [3:0]             header_len;  // Fixed to 20 Bytes
        logic [7:0]             tos;         // Type of service
        logic [15:0]            pkt_len;     // Total length of IP packet
        logic [15:0]            identifier;  // Identifier
        logic [2:0]             flag;        // Don't fragment
        logic [12:0]            frag_offset; // Fragment offset
        logic [7:0]             ttl;         // Time to live
        logic [7:0]             protocol;    // Protocol
        logic [15:0]            checksum;    // Checksum.  Default for calculation
        logic [31:0]            src_addr;    // Source IP address 192.168.1.2
        logic [31:0]            dest_addr;   // Destination IP address 192.168.1.3
    } t_IP_HEADER;


    // ------------------------------------------------------------------
    // Create default headers
    // Capitalize as these are constants
    // ------------------------------------------------------------------
    const t_MAC_HEADER MAC_HEADER_DEFAULT = {48'h01_02_03_04_05_06, 48'h0a_0b_0c_0d_0e_0f, 16'h0800};

    const t_IP_HEADER  IP_HEADER_DEFAULT  = {4'b0100, 4'd5, 8'b0, 16'h0000, 16'h3543, 3'b010, 13'b0, 8'd128, 8'b0, 
                                             16'h0000, 32'hC0_A8_01_02, 32'hC0_A8_01_03};
   
    // -------------------------------------------------------------------------
    // Function to calculate ip header checksum
    // -------------------------------------------------------------------------
    function [15:0] calculate_checksum;
        input [$bits(t_IP_HEADER)-1:0] hdr;
        begin
            logic [19:0] sum;
            integer i;            
            sum = 20'b0;
            for (i=0; i<($bits(t_IP_HEADER)/16); i++)
            begin
                sum = sum + hdr[i*16+:16];  
            end      
            calculate_checksum = ~(sum[19:16] + sum[15:0]);
        end
    endfunction
 
    // -------------------------------------------------------------------------
    // Function to reverse byte order.  
    // Needed as header and packet definitions are done with the first bytes on
    // the wire defined in the MSB locations of any header or word
    // As SV does not support parameterized functions, create as a parameterized module
    // -------------------------------------------------------------------------
    module acx_byte_order_reverse #(
        parameter DATA_WIDTH = 256
    )
    (   input  wire [DATA_WIDTH -1:0]    in,
        output wire [DATA_WIDTH -1:0]    rev
    );

        function [DATA_WIDTH -1:0] byte_order_reverse;
            input [DATA_WIDTH -1:0] data;
            begin
                integer i;
                for (i=0; i< (DATA_WIDTH/8); i=i+1)
                begin
                    byte_order_reverse[i*8+:8] = data[((DATA_WIDTH/8)-1-i)*8+:8];     
                end
            end
        endfunction

        assign rev = byte_order_reverse(in);

    endmodule : acx_byte_order_reverse
    
`endif // ACX_ETHERNET_UTILS
