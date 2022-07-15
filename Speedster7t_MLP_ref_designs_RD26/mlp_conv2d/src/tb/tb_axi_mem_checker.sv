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
// AXI mem checker.  Compares writes to an AXI interface against a
//                   memory file.  Writes the contents of the AXI writes
//                   to another memory file.
// ------------------------------------------------------------------

`timescale 1 ps / 1 ps

`include "7t_interfaces.svh"

module tb_axi_mem_checker
#(
    parameter       WRITE_FILE_NAME  = "",
    parameter       CHECK_FILE_NAME  = "",
    parameter       AXI_DATA_WIDTH   = 24,
    parameter       AXI_ADDR_WIDTH   = 20,
    parameter       ADDR_MASK_BITS   = 16,          // Number of bits of address to compare against
    parameter       DATA_MASK_BITS   = 16           // Number of bits of word to check
)
(
    // Inputs
    input  wire                     i_clk,
    input  wire                     i_reset_n,      // Negative synchronous reset
    input  wire                     i_write_result,

    // Design supports two types of AXI interface
    // AXI port
`ifdef AXI_MEM_CHECK_AXI4_PORT
    t_AXI4.monitor                  axi,            // Monitor AXI interface
`else
    t_ACX_AXI4                      axi,
`endif

    // Outputs
    output wire                     o_error
);

    // ---------------------------------------------------
    // Define Memories
    // mem_array is to write values into, and is written out
    // mem_check_array is populated with a check file.  All
    // writes to mem_array are checked against this memory
    // ---------------------------------------------------
    // Define memory word type
    typedef logic [AXI_DATA_WIDTH-1:0] t_MEM_WORD; 
    // Define array, use longint as address can be greater than 32 words
    t_MEM_WORD  mem_array [longint];

    t_MEM_WORD  axi_data_chk;
    logic [AXI_ADDR_WIDTH-1:0]  mem_addr_int;

    // Check array
    // Needs to be full width, to allow for initialisation file
    t_MEM_WORD  mem_check_array [longint];

    logic                   write_file;
    logic                   error;
    integer                 good_compares = 0;
    logic                   wr_en_d;
    t_MEM_WORD              data_d;

    // Write memory file
    initial
        $readmemh( CHECK_FILE_NAME, mem_check_array );

    // Function to write to associative array.
    // For this checker do not support strobes.  Could be added as feature if required.
    function static void write_mem (input [AXI_ADDR_WIDTH -1:0] addr, t_MEM_WORD data);
        longint addr_int;

        // Convert address
        addr_int = longint'(addr);
        // Write to memory
        mem_array[addr_int] = data;

    endfunction

    // Function to read from associative array
    function [AXI_DATA_WIDTH-1:0] read_chk_mem (input [AXI_ADDR_WIDTH -1:0] addr);
        longint addr_int;

        // Convert address
        addr_int = longint'(addr);
        read_chk_mem = (mem_check_array.exists(addr_int)) ? mem_check_array[addr_int] : {AXI_DATA_WIDTH{1'bx}};
    endfunction

    // Can write the file after the last word received
    always @(posedge i_clk)
        write_file <= i_write_result;

    // Write memory file
    initial
    begin
        // Wait for reset to be cleared
        @( ~i_reset_n );   
        @(posedge i_reset_n);
        // Wait for write file signal
        @(posedge write_file);
        $writememh( WRITE_FILE_NAME, mem_array );
    end

    // Create masks for address and data bit checking
    wire [AXI_ADDR_WIDTH-1:0] addr_mask = (2**ADDR_MASK_BITS)-1;
    t_MEM_WORD                data_mask = (2**DATA_MASK_BITS)-1;

    localparam AXI_DATA_BYTES = AXI_DATA_WIDTH/8;
    localparam ADDR_SHIFT = $clog2(AXI_DATA_BYTES);

    // Configure address
    always @(posedge i_clk)
    begin
        if ( ~i_reset_n )
            mem_addr_int <= {AXI_ADDR_WIDTH{1'b0}};
        else
        begin
            if ( axi.awvalid & axi.awready )
                mem_addr_int <= ((axi.awaddr & addr_mask) >> ADDR_SHIFT);   // Ignore address pages.  Shift to allow for word width
            else if (axi.wvalid & axi.wready & (axi.awburst != 2'b00))
                mem_addr_int <= mem_addr_int + 1;           // Increment address
        end
    end

    // Write data to local memory
    always @(posedge i_clk)
    begin
        wr_en_d <= (axi.wvalid & axi.wready);
        data_d  <= axi.wdata;
        if ( wr_en_d )
            write_mem(mem_addr_int, data_d);
    end


    // As well as writing to array, compare data on the fly
    always @(posedge i_clk)
    begin
        if ( ~i_reset_n )
            error <= 1'b0;
        else if ( wr_en_d )
        begin
            // Assign variable first.
            axi_data_chk = read_chk_mem(mem_addr_int);
            // REVISIT - A limitation of this checker is that it currently only compares the bottom word
            // A future improvement would be to check the whole word
            if( (data_d & data_mask) !== (axi_data_chk & data_mask) )
            begin
                $error( "%m : Data mismatch.  Input %08x.  Expected %08x. Addr %08x", (data_d & data_mask), (axi_data_chk & data_mask),
                                                                                      mem_addr_int);
                error <= 1'b1;
            end
            else
                good_compares++;
        end
    end

    // Block will output error until at least one good compare has been done
    assign o_error = (error || (good_compares==0));

endmodule : tb_axi_mem_checker


