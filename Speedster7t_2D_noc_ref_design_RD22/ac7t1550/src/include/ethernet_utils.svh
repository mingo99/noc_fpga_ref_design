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

    // -------------------------------------------------------------------------
    // NAP_ETHERNET parameter defines
    // -------------------------------------------------------------------------
    // TX and RX modes
    `define ACX_ETH_MODE_10G        4'b0000
    `define ACX_ETH_MODE_25G        4'b0001
    `define ACX_ETH_MODE_40G        4'b0010
    `define ACX_ETH_MODE_50G        4'b0011
    `define ACX_ETH_MODE_100G       4'b0100
    `define ACX_ETH_MODE_200G_PKT   4'b0101
    `define ACX_ETH_MODE_200G_QSI   4'b0110
    `define ACX_ETH_MODE_400G_PKT   4'b0111
    `define ACX_ETH_MODE_400G_QSI   4'b1000

    // MAC IDs
    `define ACX_ETH_400G_MAC0       2'b00
    `define ACX_ETH_400G_MAC1       2'b01
    `define ACX_ETH_QUAD0           2'b10
    `define ACX_ETH_QUAD1           2'b11
    
    // EIU channels
    // Define base addresses only
    // For multichannel,  as will use addition to calcuate the intermediate values
    // NOTE : Values are in decimal not hex
    `define ACX_ETH_CH_SUB0         5'd0
    `define ACX_ETH_CH_SUB1         5'd8
    `define ACX_ETH_CH_QUAD0_PRE0   5'd16
    `define ACX_ETH_CH_QUAD0_EXP0   5'd20
    `define ACX_ETH_CH_QUAD1_PRE0   5'd24
    `define ACX_ETH_CH_QUAD1_EXP0   5'd28

    // -------------------------------------------------------------------------
    // NAP Arbitration defines
    // -------------------------------------------------------------------------
    // Arbitration required on S2N direction, (TX).  Not necessary for N2S, (RX)
    // NAP_1 is for the southern most NAP, (lowest row).
    // So table below is reversed in terms of the top term is the bottom NAP
    // Then each NAP above has the next define value
    // Upto a maximum of 8 NAPs in a column
    // Use in testbench, and pdc file.  Not in design RTL, (as that does not determine location)
    `define ACX_ETH_ARB_SCHED_NAP_1 32'h2aaaaaaa
    `define ACX_ETH_ARB_SCHED_NAP_2 32'h2aaaaaaa
    `define ACX_ETH_ARB_SCHED_NAP_3 32'h24924924
    `define ACX_ETH_ARB_SCHED_NAP_4 32'h48888888
    `define ACX_ETH_ARB_SCHED_NAP_5 32'h21084210
    `define ACX_ETH_ARB_SCHED_NAP_6 32'h20820820
    `define ACX_ETH_ARB_SCHED_NAP_7 32'h48102040
    `define ACX_ETH_ARB_SCHED_NAP_8 32'hc0808080

`endif // ACX_ETHERNET_UTILS
