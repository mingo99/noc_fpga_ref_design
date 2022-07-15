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
// 2D convolution dataflow control
// ------------------------------------------------------------------

`include "7t_interfaces.svh"

module dataflow_control
#(
    parameter       BATCH               = 4,
    parameter       IN_HEIGHT           = 227,
    parameter       IN_WIDTH            = 227,
    parameter       IN_CHANNELS         = 3,
    parameter       FILTER_HEIGHT       = 11,
    parameter       FILTER_WIDTH        = 11,
    parameter       OUT_CHANNELS        = 1,

    parameter       DATA_WIDTH          = 24,
    parameter       GDDR_ADDR_WIDTH     = 30,   // 8Gb = 1GB
    parameter       GDDR_ADDR_ID        = 9'b0, // {5'b0, CTRL_ID}
    parameter       INF_ADDR_WIDTH      = 11,
    parameter       MLP_BRAM_ADDR_WIDTH = 10
)
(
    // Inputs
    input  wire                             i_clk,
    input  wire                             i_reset_n,    // Negative synchronous reset

    t_AXI4.master                           nap_in,
    input  wire                             i_mlp_dout_valid,

    output wire [MLP_BRAM_ADDR_WIDTH-1:0]   o_bram_wr_addr,
    output wire                             o_bram_wren,
    output wire [7 -1: 0]                   o_bram_blk_wr_addr,

    output wire                             o_in_fifo_wr,
    output wire                             o_in_fifo_wr_addr_reset,
    output wire                             o_in_fifo_rd_en,
    output wire [INF_ADDR_WIDTH-1:0]        o_in_fifo_rd_addr,
    output wire [8:0]                       o_mlp_matrix_addr,

    output reg                              o_mlp_din_sof,
    output wire                             o_mlp_din_eof,

    output wire                             o_matrix_done

);


    localparam NUM_MEM_WORDS   = (IN_WIDTH + 3)/4; // Memory has 4 pixels per word, x3 colours
    localparam STRIDE          = 4;
    localparam IN_FIFO_LINES   = 16;        // Must be > than FILTER_HEIGHT + STRIDE
    localparam PIXELS_PER_WORD = 4;         // Number of pixels in a word, considered to include all layers
                                            // This must be less than or equal to, and divisible by STRIDE
    localparam MEM_WR_PER_WORD = 2;         // A word is 144 bits.  The memory is written as 72 bits

    // Deduce some local variables
    localparam NUM_OUT_H       = ((IN_WIDTH - FILTER_WIDTH)/STRIDE) + 1;
    localparam NUM_OUT_V       = ((IN_HEIGHT - FILTER_HEIGHT)/STRIDE) + 1;
    localparam MATRIX_MEM_LOCS = ((FILTER_WIDTH + PIXELS_PER_WORD-1)/PIXELS_PER_WORD);
    localparam INPUT_MEM_LOCS  = ((IN_WIDTH + PIXELS_PER_WORD-1)/PIXELS_PER_WORD);
    localparam MATRIX_WR_LOCS  = (MATRIX_MEM_LOCS * MEM_WR_PER_WORD * FILTER_HEIGHT);

    // Enumerate state machine states
    enum {IDLE_CALC, DO_CALC} matrix_calc_state;
    enum {IDLE_NAP_IN, LOAD_KERNEL, LOAD_KERNEL_WAIT1, LOAD_KERNEL_WAIT2, LOAD_IN_FIFO, LOAD_IN_FIFO_WAIT, LOAD_IN_FIFO_WAIT2}
            nap_in_state;
    enum {IDLE_NAP_OUT, WAIT_AWREADY, WAIT_WREADY, WAIT_BVALID} nap_out_state;

    wire                        in_fifo_wr;
    logic                       in_fifo_wr_addr_reset;
    logic                       in_fifo_rd_en;
    logic                       in_fifo_rd_en_d;
    logic [11:0]                lines_to_load;
    logic [11:0]                lines_to_load_m1;
    logic [11:0]                lines_to_load_ps;
    logic [11:0]                lines_to_load_ps_m1;
    logic                       lines_to_load_dec;
    logic                       lines_to_load_inc;
    logic [11:0]                lines_to_go;        // 12 bits allows for a 4k x 4k image
    logic [11:0]                lines_to_go_dec;
    logic [11:0]                matrix_v_start;
    logic [11:0]                matrix_v_start_next;
    logic [11:0]                matrix_h_start;
    logic [11:0]                matrix_h_start_next;
    logic [11:0]                mlp_matrix_addr;
    logic [11:0]                mlp_matrix_addr_d;
    logic [11:0]                mlp_matrix_addr_2d;

    // Address has to be big enough to read page of memory with image
    logic [16 -1:0]             nap_in_addr;        
    (* must_keep=1 *) logic [16 -1:0] nap_in_addr_inc /* synthesis syn_preserve=1 */;

    logic                       nap_in_addr_overflow;
    logic [GDDR_ADDR_WIDTH-$bits(nap_in_addr)-5:0] nap_in_page_addr;   // Indicates page in memory being used for either image or kernel
    logic [3:0]                 matrix_v_count;
    logic [2:0]                 matrix_h_count;
    logic [INF_ADDR_WIDTH-1:0]  in_fifo_rd_addr /* synthesis syn_dspstyle=logic */;
    // The fifo_rd_addr is the critical timing path, largely caused by the setup time into the BRAM
    // To resolve this, register the result, as setup into a flop is quicker
    // To prevent retiming, set syn_preserve and must_keep on the flops.
    (* must_keep=1 *) logic [INF_ADDR_WIDTH-1:0]  in_fifo_rd_addr_d /* synthesis syn_preserve=1 */;
    logic [11:0]                line_read_num;
    logic [11:0]                line_read_num_next;
    wire                        last_calc;

    logic                       matrix_done;
    logic                       mlp_din_eof_d;
    logic                       mlp_din_eof_2d;
    logic                       mlp_din_eof_3d;
    logic                       mlp_din_eof_4d;
    logic                       mlp_din_sof_d;
    logic                       mlp_din_sof_2d;
    logic                       mlp_din_sof_3d;
    logic                       first_calc;

    logic [MLP_BRAM_ADDR_WIDTH-1:0] bram_wr_addr;
    logic                           bram_wren;
    logic                           bram_loaded;
    logic [5:0]                     bram_sel;
    logic                           bram_wr_addr_rst;

    // Tie off unused signals from input NAP interface
    assign nap_in.awvalid   = 1'b0;
    assign nap_in.awaddr    = 0;
    assign nap_in.awlen     = 0;
    assign nap_in.awid      = 0;
    assign nap_in.awqos     = 0;
    assign nap_in.awburst   = 2'b01;
    assign nap_in.awlock    = 1'b0;
    assign nap_in.awsize    = 0;
    assign nap_in.awregion  = 0;
    assign nap_in.wvalid    = 1'b0;
    assign nap_in.wdata     = 0;
    assign nap_in.wstrb     = 0;
    assign nap_in.wlast     = 1'b0;
    assign nap_in.bready    = 1'b0;

    // Register AXI signals to improve timing.
    logic arready_d /* synthesis syn_maxfan=4 */;
    logic rready_d  /* synthesis syn_maxfan=4 */;
    logic rvalid_d  /* synthesis syn_maxfan=4 */;
    logic rlast_d   /* synthesis syn_maxfan=4 */;
    logic [8 - 1:0] rid_d;

    // Use pipelined version of state machine to improve timing
    // States overlap the write pulses by a suitable margin so writes will not be dropped
    logic load_in_fifo_state;
    logic load_kernel_state;

    always @(posedge i_clk)
    begin
        if (nap_in_state == LOAD_IN_FIFO)
            load_in_fifo_state <= 1'b1;
        else
            load_in_fifo_state <= 1'b0;

        if (nap_in_state == LOAD_KERNEL)
            load_kernel_state <= 1'b1;
        else
            load_kernel_state <= 1'b0;
    end

    assign in_fifo_wr = (nap_in.rvalid & nap_in.rready) && (load_in_fifo_state == 1'b1); // (nap_in_state_d == LOAD_IN_FIFO);
    assign bram_wren  = (nap_in.rvalid & nap_in.rready) && (load_kernel_state == 1'b1);  // (nap_in_state_d == LOAD_KERNEL);

    assign o_bram_blk_wr_addr = bram_sel;

    // Register to improve timing
    always @(posedge i_clk)
        bram_loaded <= (bram_sel == BATCH);

    // lines_to_go sum is currently critical path.  
    // Can be done in advance (as it takes multiple cycles for the AXI transaction)
    // If this fails, then set to multi_cycle
    // Can also generate flag for if new address will exceed burst length
    localparam GDDR_BURST_LEN_BIT = 11-5;     // If this bit toggles then burst will overflow column

    always @(posedge i_clk)
    begin
        lines_to_go_dec      <= lines_to_go - 1;
        // Kernels and image lines are based on 4kB boundaries, ('h1000) rows, which are 2kB long
        // As one access is per 32 bytes, then 4kB/32 = 128. This is the amount to increment as it is multiplied by 32 when applied
        nap_in_addr_inc      <= nap_in_addr + 16'h80;   // Next memory row
    end

    assign nap_in_addr_overflow = (nap_in_addr_inc[GDDR_BURST_LEN_BIT] ^ nap_in_addr[GDDR_BURST_LEN_BIT]);

    // Maximum size of GDDR supported
    localparam MAX_GDDR_ADDR_WIDTH = 33;

    // Read address is on 32 byte boundaries, as AXI interface is 256 bits.
    always @(posedge i_clk)
    begin
        nap_in.araddr <= {GDDR_ADDR_ID, {(MAX_GDDR_ADDR_WIDTH-GDDR_ADDR_WIDTH){1'b0}}, nap_in_page_addr, nap_in_addr, 5'b0_0000};
        nap_in.arsize <= 3'h5;     // Data width fixed at 32 bytes
    end

    // Improve timing by registering signals
    always @(posedge i_clk)
    begin
        arready_d <= nap_in.arready;
        rvalid_d  <= nap_in.rvalid;
        rlast_d   <= nap_in.rlast;
        if (nap_in.rvalid)
            rid_d <= nap_in.rid;
    end

    assign nap_in.rready = rready_d;

    logic lines_to_go_zero;
    logic lines_to_load_zero;
    always @(posedge i_clk)
    begin
        lines_to_go_zero   <= (lines_to_go == 0);
        lines_to_load_zero <= (lines_to_load == 0);
    end

    // Input memory read process
    always @(posedge i_clk)
    begin
        // Default value overwritten below
        lines_to_load_dec     <= 1'b0;
        in_fifo_wr_addr_reset <= 1'b0;
        bram_wr_addr_rst      <= 1'b0;

        if( ~i_reset_n )
        begin
            nap_in_addr           <= 0;
            nap_in_page_addr      <= 0;
            lines_to_go           <= 1;     // Load the kernel in a single burst
            in_fifo_wr_addr_reset <= 1'b1;
            get_in_data();                  // This call just resets variables
            nap_in_state          <= IDLE_NAP_IN;
            bram_sel              <= 6'h0;
        end
        else case (nap_in_state)
            IDLE_NAP_IN : // May need to loop around different kernels here
                begin
                    nap_in_addr           <= 0;
                    nap_in_page_addr      <= 0;
                    // Ensure we only run through the state machine once
                    if( ~bram_loaded )
                    begin
                        nap_in_state <= LOAD_KERNEL;
                        nap_in.arlen <= MATRIX_WR_LOCS-1;
                    end
                end

            LOAD_KERNEL :
                begin
                    if ( ~bram_loaded )
                    begin
                        if ( ~lines_to_go_zero )
                        begin
                            get_in_data();
                            nap_in_addr   <= nap_in_addr_inc;
                            lines_to_go   <= lines_to_go_dec;
                        end
                        else
                        begin
                            bram_wr_addr_rst <= 1'b1;
                            bram_sel         <= bram_sel + 1;
                            lines_to_go      <= 1;     // Load the kernel in a single burst
                        end
                        nap_in_state  <= LOAD_KERNEL_WAIT1;
                    end
                    else
                    begin
                        // Run after all BRAMs are loaded
                        in_fifo_wr_addr_reset <= 1'b1;
                        nap_in_addr           <= 0;       // Address where image is stored
                        nap_in_page_addr      <= 'h04;

                        lines_to_go  <= IN_HEIGHT;
                        nap_in_state <= LOAD_IN_FIFO;
                        nap_in.arlen <= NUM_MEM_WORDS-1;
                        // synthesis synthesis_off
                        $display("%t : All Kernels loaded into BRAM", $time );
                        // synthesis synthesis_on
                    end
                end

            LOAD_KERNEL_WAIT1 :  // Add delay to allow for registered values to update
                    nap_in_state <= LOAD_KERNEL_WAIT2;

            LOAD_KERNEL_WAIT2 :  // Add delay to allow for registered values to update
                    nap_in_state <= LOAD_KERNEL;

            LOAD_IN_FIFO :  // This runs repeatibly until the matrix is calculated 
                begin
                    if ( ~lines_to_load_zero && ~lines_to_go_zero && ~lines_to_load_dec)
                    begin
                        get_in_data();
                        nap_in_addr       <= nap_in_addr_inc;
                        lines_to_go       <= lines_to_go_dec;
                        lines_to_load_dec <= 1'b1;
                        nap_in_state      <= LOAD_IN_FIFO_WAIT;
                        // synthesis synthesis_off
//                        $display("%t : Lines to go %d", $time, lines_to_go );
                        // synthesis synthesis_on
                    end
                end

            LOAD_IN_FIFO_WAIT :  // Add delay to allow for registered values to update
                    nap_in_state <= LOAD_IN_FIFO_WAIT2;

            LOAD_IN_FIFO_WAIT2 : // Add delay to allow for registered values to update
                    nap_in_state <= LOAD_IN_FIFO;

            default
                    nap_in_state <= IDLE_NAP_IN;

        endcase
    end

    always @(posedge i_clk)
    begin
        if( ~i_reset_n || bram_wr_addr_rst)
            bram_wr_addr <= 0;
        else if ( bram_wren )
            bram_wr_addr <= bram_wr_addr + 1;
    end

    assign o_bram_wr_addr = bram_wr_addr;
    assign o_bram_wren    = bram_wren;

    // Pre-calc the lines to load
    always @(posedge i_clk)
    begin
        lines_to_load_m1    <= lines_to_load - 1;             // Decrement
        lines_to_load_ps    <= lines_to_load + STRIDE;        // Load another stride
        lines_to_load_ps_m1 <= lines_to_load + (STRIDE-1);    // Load another stride as we complete loading a line
    end

    // Lines to load process, can be accessed by both reading and writing sides
    always @(posedge i_clk)
    begin
        if( ~i_reset_n )
            lines_to_load <= FILTER_HEIGHT;
        else    // Have to handle the case where both processes collide
        begin
            case ({lines_to_load_dec, lines_to_load_inc})
                2'b00 : lines_to_load <= lines_to_load;
                2'b10 : lines_to_load <= lines_to_load_m1;          // Decrement
                2'b01 : lines_to_load <= lines_to_load_ps;          // Load another stride
                2'b11 : lines_to_load <= lines_to_load_ps_m1;       // Load another stride as we complete loading a line
            endcase
        end
    end

    // Pulse for when the last matrix calcuation is done
    assign last_calc = ( matrix_h_count == MATRIX_MEM_LOCS-1 ) && (matrix_v_count == FILTER_HEIGHT-1 );

    // Delay MLP sof and eof to match data latency from memories
    always @(posedge i_clk)
    begin
        mlp_din_eof_d  <= last_calc;
        mlp_din_eof_2d <= mlp_din_eof_d;
        mlp_din_eof_3d <= mlp_din_eof_2d;
        mlp_din_eof_4d <= mlp_din_eof_3d;
        mlp_din_sof_d  <= first_calc;
        mlp_din_sof_2d <= mlp_din_sof_d;
        mlp_din_sof_3d <= mlp_din_sof_2d;
    end

    assign o_mlp_din_sof = mlp_din_sof_3d;
    assign o_mlp_din_eof = mlp_din_eof_4d;

    // Pre-calc next matrix start address
    // Note : In this configuration, STRIDE=PIXELS_PER_WORD.
    always @(posedge i_clk)
    begin
        matrix_h_start_next <= matrix_h_start + (STRIDE/PIXELS_PER_WORD);
        matrix_v_start_next <= matrix_v_start + STRIDE;
        line_read_num_next  <= line_read_num  + STRIDE;
    end

    logic line_read_num_ls_height;
    logic matrix_v_start_ls_height;
    logic matrix_h_start_ls_width;
    always @(posedge i_clk)
    begin
        line_read_num_ls_height  <= (line_read_num < (IN_HEIGHT - FILTER_HEIGHT));
        matrix_v_start_ls_height <= (matrix_v_start <= (IN_HEIGHT - FILTER_HEIGHT));
        matrix_h_start_ls_width  <= (matrix_h_start < (INPUT_MEM_LOCS - MATRIX_MEM_LOCS ));
    end

    // State machine to control read out and MLP operation.
    always @(posedge i_clk)
    begin
        // Default values, overridden in states below
        lines_to_load_inc <= 1'b0;
        if( ~i_reset_n )
        begin
            matrix_calc_state <= IDLE_CALC;
            play_matrix();      // Resets all variables
            line_read_num     <= 0;
            matrix_done       <= 1'b0;
        end
        else case (matrix_calc_state)
            IDLE_CALC :
                begin
                    matrix_v_start <= 0;
                    matrix_h_start <= 0;
                    if( lines_to_load_zero && line_read_num_ls_height )
                    begin
                        // When starting to calculate current matrix row, if still lines to go, then
                        // Load next strides worth of lines
                        if( ~lines_to_go_zero )
                            lines_to_load_inc <= 1'b1;
                        matrix_calc_state <= DO_CALC;
                    end
                end
            DO_CALC :
                begin
                    matrix_done <= 1'b0;
                    if ( matrix_v_start_ls_height )
                    begin
                        if( matrix_h_start_ls_width )
                        begin
                            play_matrix();
                            matrix_h_start <= matrix_h_start_next;  
                        end
                        else
                        begin
                            matrix_v_start <= matrix_v_start_next;
                            line_read_num  <= line_read_num_next;
                            matrix_h_start <= 0;
                            // Completed current row with matrix, if still lines to go, then
                            // Load next strides worth of lines
                            if( ~lines_to_go_zero )
                                lines_to_load_inc <= 1'b1;
                        end
                    end
                    else
                    begin
                        matrix_calc_state <= IDLE_CALC;
                        matrix_done       <= 1'b1;
                    end
                end
        endcase 
    end


    // Data to read from input fifo
    // This address should wrap around, similar to the input fifo write address
    // When doing timing closure, it is expected that this will most likely be one of the critical path in timing
    always @(posedge i_clk)
    begin
        in_fifo_rd_addr   <= ((line_read_num+matrix_v_count) * INPUT_MEM_LOCS) + (matrix_h_count + matrix_h_start);
        in_fifo_rd_addr_d <= in_fifo_rd_addr;
        in_fifo_rd_en_d   <= in_fifo_rd_en;
    end

    // Matrix has 4 words, (x3 deep), per output location.  So we need (FILTER_WIDTH + 3)/4 entries per matrix
    always @(posedge i_clk)
    begin
        mlp_matrix_addr    <= (matrix_v_count * MATRIX_MEM_LOCS) + matrix_h_count;
        mlp_matrix_addr_d  <= mlp_matrix_addr;
        mlp_matrix_addr_2d <= mlp_matrix_addr_d;
    end
    
    assign o_in_fifo_wr            = in_fifo_wr;
    assign o_in_fifo_wr_addr_reset = in_fifo_wr_addr_reset;
    assign o_in_fifo_rd_en         = in_fifo_rd_en_d;
    assign o_in_fifo_rd_addr       = in_fifo_rd_addr_d;

    assign o_mlp_matrix_addr       = mlp_matrix_addr_2d;
    assign o_matrix_done           = matrix_done;

    // -------------------------------------------------------------------------
    // Task to read a line of the image from the NAP and write to the in_fifo
    // -------------------------------------------------------------------------
    // This task is always called within an @always(posedge clk) block
    task get_in_data;
    begin
        if( ~i_reset_n )
        begin
            rready_d        = 1'b0;
            nap_in.arvalid  <= 1'b0;
            nap_in.arid     = 8'h0;
            nap_in.arqos    = 0;
            nap_in.arlock   = 1'b0;
            nap_in.arburst  = 2'b01;
            nap_in.arregion = 3'b000;
            return;
        end

        // AXI spec states that valid must not wait for ready
        // Valid should be asserted, then deasserted 1 clock cycle after ready is asserted

        // Assert valid
        nap_in.arvalid <= 1'b1;
        // Hold for one cycle
        @(posedge i_clk);

        // Wait for ready to be asserted
        // Cannot use registered signal as that causes double requests to be issued.
        while ( ~nap_in.arready )
            @(posedge i_clk);

        // As ready was already asserted when valid asserted
        // Clear the valid, otherwise multiple requests will be made
        nap_in.arvalid <= 1'b0;

        // Address registered.  Assert ready to receive
        rready_d = 1'b1;

        // Stay in the task until the last byte is received
        while (~(rvalid_d && rlast_d))
            @(posedge i_clk);

        // synthesis synthesis_off
        if ( rid_d != nap_in.arid )
            $error("%t : Read IDs do not match. rid %0x arid %0x", $time, rid_d, nap_in.arid);
        // synthesis synthesis_on

        rready_d = 1'b0;

        // Increment the transaction ID
        nap_in.arid = nap_in.arid + 1;

    end
    endtask : get_in_data

    // -------------------------------------------------------------------------
    // Task to a matrix sized block of data from the in_fifo and to play it to the MLP
    // -------------------------------------------------------------------------
    // This task is always called within an @always(posedge clk) block
    task play_matrix;
    begin
        if( ~i_reset_n )
        begin
            matrix_v_count   <= 0;
            matrix_h_count   <= 0;
            in_fifo_rd_en    <= 1'b0;
            first_calc       <= 1'b0;
            return;
        end

        matrix_v_count  <= 0;
        matrix_h_count  <= 0;
        in_fifo_rd_en   <= 1'b1;
        first_calc      <= 1'b1;
        // Word_out_count is the top count, so only needs to get to LHS pixel of matrix
        // inner_matrix_count is added to this to reach the final pixels
        // Divide by 4 is because we have 4 pixels per word, which happens to equal our stride.
        while ( matrix_v_count < FILTER_HEIGHT )
        begin
            if( matrix_h_count < MATRIX_MEM_LOCS-1 )
                matrix_h_count <= matrix_h_count + 1;
            else
            begin
                matrix_h_count <= 0;
                matrix_v_count <= matrix_v_count + 1;
            end
            @(posedge i_clk);
            first_calc <= 1'b0;
        end
        // Reset values so correct when task next entered
        in_fifo_rd_en  <= 1'b0;
        matrix_h_count <= 0;
        matrix_v_count <= 0;
        first_calc     <= 1'b0;
    end
    endtask : play_matrix


endmodule : dataflow_control

