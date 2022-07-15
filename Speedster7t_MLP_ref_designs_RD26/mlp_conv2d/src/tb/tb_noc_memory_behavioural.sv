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
// Behavioural model of an idealised NOC and memory device
// Use NAP AXI slave to communicate with memory
// ------------------------------------------------------------------

`timescale 1 ps / 1 ps

module tb_noc_memory_behavioural
#(
    parameter               INIT_FILE_NAME      = "",
    parameter               MEM_TYPE            = "gddr",   // Options are gddr and ddr.
    parameter               DST_DATA_WIDTH      = 24,
    parameter               VERBOSITY           = 4         // Control number of messages
)
(
    // Inputs
    input  wire             i_clk,
    input  wire             i_reset_n,                      // Negative synchronous reset
    input  wire             i_write_result                  // Write checker file
);

    // ----------------------------------------------------------------------------
    // This model is for a NAP accessing a memory device
    // The data and address widths are determined by the NAPs and are fixed
    // ----------------------------------------------------------------------------
    localparam NAP_ADDR_WIDTH = 42;
    localparam NAP_DATA_WIDTH = 256;
    localparam NAP_STRB_WIDTH = (NAP_DATA_WIDTH/8);
    localparam NAP_LEN_WIDTH  = 8;
    localparam NAP_ID_WIDTH   = 8;

    // ----------------------------------------------------------------------------
    // Define array
    // Associative array, reduces simulator memory requirements
    // Index has to be longint as address width is greater than 32 bits
    // ----------------------------------------------------------------------------
    reg    [NAP_DATA_WIDTH-1:0] mem_array [longint];
    reg    [3:0]                nap_req_del;
    reg                         nap_ready;

    // Initialise memory if file specified
    generate if ( INIT_FILE_NAME != "" )
        initial
            $readmemh( INIT_FILE_NAME, mem_array );
    endgenerate

    integer i, j;

    // AR signals
    logic   [NAP_ID_WIDTH   -1:0]   t_arid;
    logic   [NAP_ADDR_WIDTH -1:0]   t_araddr;
    logic   [NAP_LEN_WIDTH  -1:0]   t_arlen;
    logic   [3  -1:0]               t_arsize;
    logic   [2  -1:0]               t_arburst;
    logic                           t_arlock;
    logic   [4  -1:0]               t_arqos;

    // AW signals
    logic   [NAP_ADDR_WIDTH -1:0]   t_awaddr;
    logic   [NAP_LEN_WIDTH  -1:0]   t_awlen;
    logic   [3  -1:0]               t_awsize;
    // Unused AW signals
    logic   [NAP_ID_WIDTH  -1:0]    t_awid;
    logic   [2  -1:0]               t_awburst;
    logic                           t_awlock;
    logic   [4  -1:0]               t_awqos;

    // W signals
    logic [NAP_DATA_WIDTH-1:0]      t_wdata;
    logic [NAP_STRB_WIDTH-1:0]      t_wstrb;
    logic                           t_wlast;

    int                             outstanding_xact = 0;   // Count transactions to go to mimic G/DDR pipeline

    // ----------------------------------------------------------------------------
    // Function to check that the burst length will not overflow a GDDR column
    // In the enoc this is set as the bottom 12 bits of the address.  This could support memories with 4kB pages.
    // However GDDR data sheet suggests 11 bits for the 8Gb device - each row is 2kB.
    // ToDo : This should be reduced to 11 bits, and the dataflow control updated to load each kernel in 2 bursts.
    // ----------------------------------------------------------------------------
    localparam GDDR_BURST_OVERFLOW_BIT = 12;
    function void check_burst_length ( input [NAP_ADDR_WIDTH-1:0] addr, input [NAP_LEN_WIDTH-1:0] len, input string trans );
        // Create a mask where the necessary bottom bits are 0
        const var [NAP_ADDR_WIDTH-1:0] ADDR_MASK = (-42'h1<<GDDR_BURST_OVERFLOW_BIT);
        // The address is per byte.  The length is per AXI beat.  As each AXI beat is 32 bytes
        // the length has to be multiplied by 32 to give a per byte calculation
        if ( ((addr + {(len+1), 5'b0} - 1) & ADDR_MASK) != (addr & ADDR_MASK) )
        begin
            $error( "GDDR %s burst will overflow.  Addr %0x. Length %0x (hex) AXI beats", trans, addr, len);
            $stop(1);
        end
        // Use the same task to ensure the any GDDR address is in range, see assignments to mem_read/write_addr below
        if (MEM_TYPE=="gddr") begin : gb_gddr_type
            if ( (addr[4:0] != 0) || (addr[32:30] != 0) )
            begin
                $warning( "GDDR %s address has bits that will be ignored.  Addr %0x", trans, addr);
            end
        end
    endfunction

    // ----------------------------------------------------------------------------
    // Structure for issuing a response
    // ----------------------------------------------------------------------------
    typedef struct {
        logic [1:0]                 resp;
        logic [NAP_ID_WIDTH   -1:0] id;
        logic [NAP_DATA_WIDTH -1:0] rdata;  // If DCI to be supported would need double width.
        logic                       rlast;
        time                        time_in;
    } t_RESP;

    // ----------------------------------------------------------------------------
    // Structure for storing access values
    // ----------------------------------------------------------------------------
    typedef struct {
        logic [NAP_ADDR_WIDTH -1:0]     addr;
        logic [NAP_LEN_WIDTH  -1:0]     len;
        logic [1:0]                     burst;
        logic [NAP_ID_WIDTH   -1:0]     id;
    } t_MEM_ACCESS;


    // ----------------------------------------------------------------------------
    // Access via the NAP is per 32 bits.  So bottom 5 bits are ignored.
    // This also matches readmemh operation, which will populate the assoicative array on a
    // sequential entry basis, regardless of the width.  So each 32 bytes is in the next+1
    // memory location.
    // Addressing width depends on memory type
    // ----------------------------------------------------------------------------
    function [NAP_ADDR_WIDTH -1:0] convert_mem_addr( input [NAP_ADDR_WIDTH -1:0] addr );
        if (MEM_TYPE=="gddr") begin : gb_gddr_type
            // Set GDDR device to be 8Gb = 1GB, so 30 bits of address
            // GDDR CTRL ID is 4 bits in locations [36:33].
            // Top bits of address [41:37] have to be 0 to access a GDDR.
            convert_mem_addr  = {5'b0, addr[36:33],  3'b000, addr[29:5]};
        end
        else
        begin : gb_ddr_type
            // Set DDR device uses all 40 bits of address
            // DDR_CTRL ID is top 2 bits in locations [41:40].
            convert_mem_addr  = addr[41:0];
        end
    endfunction

    // ----------------------------------------------------------------------------
    // Associate array function has to called in a procedural context
    // Wrap memory reads within a function, called from the relevant tasks.
    // ----------------------------------------------------------------------------
    function [NAP_DATA_WIDTH-1:0] mem_array_out (input longint addr);
        longint addr_int;

        addr_int = longint'(convert_mem_addr(addr));
        if ( NAP_DATA_WIDTH == DST_DATA_WIDTH )
            mem_array_out = (mem_array.exists(addr_int)) ? mem_array[addr_int] : {NAP_DATA_WIDTH{1'bx}};
        else
            mem_array_out = (mem_array.exists(addr_int)) ? {{(NAP_DATA_WIDTH-DST_DATA_WIDTH){1'b0}}, mem_array[addr_int]} :
                                                           {NAP_DATA_WIDTH{1'bx}};
    endfunction

    // ----------------------------------------------------------------------------
    // Write to memory function.  Handles write strobe
    // ----------------------------------------------------------------------------
    // Called twice for double width dci writes
    function static void write_mem (input [NAP_ADDR_WIDTH -1:0] addr, 
                                    input [NAP_DATA_WIDTH -1:0] data, 
                                    input [NAP_STRB_WIDTH -1:0] strb);

        logic [NAP_DATA_WIDTH -1:0] current;
        int                         wbyte;
        longint addr_int;

        addr_int = longint'(convert_mem_addr(addr));

        // Get current memory contents
        current = (mem_array.exists(addr_int)) ? mem_array[addr_int] : {NAP_DATA_WIDTH{1'bx}};

        // Update bytes where strb is set
        for ( wbyte = 0; wbyte < NAP_STRB_WIDTH; wbyte = wbyte + 1 )
            if( strb[wbyte] == 1'b1 )
                current[(wbyte*8)+:8] = data[(wbyte*8)+:8];

        // Write back to memory
        mem_array[addr_int] = current;

    endfunction

    // Support read requests
    // Have overlapping address and data phases
    t_MEM_ACCESS queue_AR0[$];
    t_RESP       queue_R0[$];

    // Continually run get_AR.  Push any requests into a queue
    // Note that get_AR and issue_R both have one cycle delays
    initial
    begin
        repeat (10) @(posedge i_clk);
        while(i_reset_n !== 1'b1)
            @(posedge i_clk);
        forever
        begin
            if( outstanding_xact < 32 ) 
            begin
                // Blocking call.  Task will only complete when request made
                get_AR(t_arid, t_araddr, t_arlen, t_arsize, t_arburst, t_arlock, t_arqos);
                check_burst_length(t_araddr, t_arlen, "read");
                queue_AR0.push_back('{t_araddr, t_arlen, t_arburst, t_arid});
                outstanding_xact++;
                if( VERBOSITY > 2 )
                    $display( "@%0t AR: ID=%02h, ADR=%010h, LEN=%02h", $time, t_arid, t_araddr, t_arlen );
            end
            else
                @(posedge i_clk);
        end
    end

    t_MEM_ACCESS this_read;
    initial
    begin
        repeat (10) @(posedge i_clk);
        while(i_reset_n !== 1'b1)
            @(posedge i_clk);
        forever
        begin
            // Check for read request
            while( queue_AR0.size() == 0 )
            begin
                @(posedge i_clk);
            end

            // Store local copies of the variables
            this_read = queue_AR0[0];

            // Average GDDR read latency through the NAP is ~ 100ns.
            #100ns;

            begin
                for( i=this_read.len; i>0; i=i-1 )
                begin
                    issue_R(this_read.id,mem_array_out(this_read.addr),2'b00,1'b0);
                    if( VERBOSITY > 3 )
                        $display( "@%0t R:  ID=%02h, ADR=%010h, DATA=%64h", $time, this_read.id, this_read.addr,
                                                                            mem_array_out(this_read.addr) );
                    case( this_read.burst )
                        // Increment is 'h20 as each memory location is 32 bytes
                        2'b01 : if( this_read.addr[29:5] != -1 ) this_read.addr = this_read.addr + 42'h20;    // INCR
                        2'b10 : this_read.addr = this_read.addr + 42'h20; // WRAP
                    endcase
                end
                issue_R(this_read.id,mem_array_out(this_read.addr),2'b00,1'b1);
                if( VERBOSITY > 3 )
                    $display( "@%0t R:  ID=%02h, ADR=%010h, DATA=%64h", $time, this_read.id, this_read.addr,
                                                                        mem_array_out(this_read.addr) );
            end

            // Increment the current AR queue once the last beat of the burst is read
            void'(queue_AR0.pop_front());
            // Decrement the outstanding requests
            outstanding_xact--;
        end
    end

    // Support write requests
    // Have overlapping address and data phases
    t_MEM_ACCESS queue_AW0[$];
    t_RESP       queue_B0[$];

    // Continually run get_AW.  Push any requests into a queue
    initial
    begin
        repeat (10) @(posedge i_clk);
        while(i_reset_n !== 1'b1)
            @(posedge i_clk);
        forever
        begin
            if( outstanding_xact < 32 ) 
            begin
                get_AW(t_awid, t_awaddr, t_awlen, t_awsize, t_awburst, t_awlock, t_awqos);
                queue_AW0.push_back('{t_awaddr, t_awlen, t_awburst, t_awid});
                check_burst_length(t_awaddr, t_awlen, "write");
                outstanding_xact++;
                if( VERBOSITY > 2 )
                    $display( "@%0t AW: ID=%02h, ADR=%010h, LEN=%02h", $time, t_awid, t_awaddr, t_awlen );
            end
            else
                @(posedge i_clk);
        end
    end

    logic        bresp_error;
    t_MEM_ACCESS this_write;
    initial
    begin
        repeat (10) @(posedge i_clk);
        while(i_reset_n !== 1'b1)
            @(posedge i_clk);
        forever
        begin
            bresp_error = 1'b0;
            // Do a write burst as a series of write transactions
            // Get the current front of the AW queue values
            get_W(t_wdata, t_wstrb, t_wlast);

            // Insert small wait in case get_W and get_AW were on the same clock cycle
            # 10ps;
            while( queue_AW0.size() == 0 )
            begin
                @(posedge i_clk);
            end

            // Store local copies of the variables
            this_write = queue_AW0[0];

            // Have first write word, and transaction details.

            // Enter for loop if burst longer than a single beat.
            // Write request logged
            for( j=this_write.len; j>0; j=j-1 )
            begin
                if( t_wlast )
                begin
                    $error("wlast asserted during burst. %d strides to go", j);
                    bresp_error = 1'b0;
                end
                // Write into behavioural memory model
                write_mem(this_write.addr, t_wdata, t_wstrb);
                if( VERBOSITY > 3 )
                    $display( "@%0t W:  ID=%02h, ADR=%010h, DATA=%64h", $time, this_write.id, this_write.addr, t_wdata );

                case( this_write.burst )
                    // Increment is 'h20 as each memory location is 32 bytes
                    2'b01 : if( this_write.addr[29:5] != -1 ) this_write.addr = this_write.addr + 42'h20;    // INCR
                    2'b10 : this_write.addr = this_write.addr + 42'h20; // WRAP
                endcase

                // Get new write value
                get_W(t_wdata, t_wstrb, t_wlast);
            end

            // Write last value
            write_mem(this_write.addr, t_wdata, t_wstrb);
            if( VERBOSITY > 3 )
                $display( "@%0t W:  ID=%02h, ADR=%010h, DATA=%64h", $time, this_write.id, this_write.addr, t_wdata );

            // Increment the current AW queue once the last beat of the burst is written
            void'(queue_AW0.pop_front());

            if( ~t_wlast || bresp_error )
            begin
                $error("wlast not asserted on last stride");
                queue_B0.push_back('{2'b01, this_write.id, 0, 0, $time});
            end
            else
                queue_B0.push_back('{2'b00, this_write.id, 0, 0, $time});

        end
    end

    // Average GDDR write latency to bresp through the NAP is approximately 75ns.
    int bresp_timeout;
    initial
    begin
        repeat (10) @(posedge i_clk);
        while(i_reset_n !== 1'b1)
            @(posedge i_clk);
        forever
        begin
            if( queue_B0.size() > 0 )
            begin
                bresp_timeout = 0;
                // Wait sufficient time for bresp
                while( (($time - queue_B0[0].time_in) < 75ns) && (bresp_timeout < 200) )
                begin
                    @(posedge i_clk);
                    bresp_timeout = bresp_timeout + 1;
                end
                // Issue bresp
                issue_B(queue_B0[0].id, queue_B0[0].resp);
                if( VERBOSITY > 2 )
                    $display( "@%0t B:  ID=%02h, RESP=%02h", $time, queue_B0[0].id, queue_B0[0].resp );
                // Remove entry from queue
                void'(queue_B0.pop_front());
                // Decrement the outstanding requests
                outstanding_xact--;
            end
            @(posedge i_clk);
        end
    end

endmodule : tb_noc_memory_behavioural


