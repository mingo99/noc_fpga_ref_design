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
// Synthesisable random sequence generator
//      Can generate a random sequence, or up down count
//      Can be used for data or address generation
// ------------------------------------------------------------------


module random_seq_gen
#(
    parameter   OUTPUT_WIDTH        = 32,           // Width of output
    parameter   WORD_WIDTH          = 0,            // Output word width.
                                                    // Limited to be a multiple of 8
    parameter   LINEAR_COUNT        = 0,            // Set to 1 to make a counter
    parameter   COUNT_DOWN          = 0,            // Set to 1 to count down.  Ignored if LINEAR_COUNT=0
    parameter   FIRST_WORD_LINEAR   = 1,            // Determine if the first word is linear, even if LINEAR_COUNT=0
    parameter logic [OUTPUT_WIDTH -1:0] INIT_VALUE 
                                    = {OUTPUT_WIDTH{1'b0}} // Start-up value when random.  When linear output is set to 0
)
(
    // Inputs
    input  wire                         i_clk,
    input  wire                         i_reset_n,  // Negative synchronous reset
    input  wire                         i_start,    // Start sequence from beginning
    input  wire                         i_enable,   // Generate new value

    output wire [OUTPUT_WIDTH-1:0]      o_dout      // Data out
);

    // Function to generate random value
    // Shift by an index value, then apply 8 bit LFSR
    // Example - n_XOR = (tx_data[10] ^ (tx_data[12] ^ (tx_data[13] ^ tx_data[15])));
    function [WORD_WIDTH-1:0] rand_word ( logic [WORD_WIDTH-1:0] data_in, integer idx );
    begin
        rand_word = (data_in << idx) | (data_in >> (WORD_WIDTH-idx));
        rand_word = {rand_word[1 +: (WORD_WIDTH-1)], (rand_word[2] ^ (rand_word[4] ^ (rand_word[5] ^ rand_word[7])))};
    end
    endfunction

    // Check parameters.  Instantiate error module if they are not set correctly
    generate
    begin : gb_param_error
        // Check WORD_WIDTH is a multiple of 8
        if ((WORD_WIDTH % 8) != 0 ) 
            ERROR_word_width_not_multiple_of_8();
        // Check WORD_WIDTH less than OUTPUT_WIDTH
        if (WORD_WIDTH > OUTPUT_WIDTH ) 
            ERROR_word_width_greater_than_output_width();
    end
    endgenerate

    // Set number of words in final output
    localparam NUM_WORDS = (OUTPUT_WIDTH + WORD_WIDTH - 1) / WORD_WIDTH;

    // Generate internal signals which are multiples of the WORD_WIDTH
    localparam OUTPUT_WIDTH_INT = NUM_WORDS * WORD_WIDTH;

    // As multiple words can be used to form the output, then these are equivalent
    // To prevent the output flops being merged, ensure they are kept through
    // both synthesis and simulation.
    (* must_keep=1 *) logic [OUTPUT_WIDTH_INT-1:0] dout_int /* synthesis syn_preserve=1 */;
    logic [OUTPUT_WIDTH_INT-1:0] next_dout_int;

    // Compute the next output value
    // Divide the full output up into words.
    // The first word is always a linear count, effectively a packet number
    // The subsequent words are either linear counts from that value, or else
    // random LFSR values dervived from that value.
    generate 
    begin : gb_next_dout
        if (FIRST_WORD_LINEAR == 1)
        begin : gb_first_word_linear
            // First word can be a count, even with random.  This allows for packet traceability
            assign next_dout_int[0 +: WORD_WIDTH] = dout_int[0 +: WORD_WIDTH] + 1;
        end

        // Generate subsequent words, in parallel, using loop index
        // If words were based on previous word, then logic would be too deep
        for( genvar ii=((FIRST_WORD_LINEAR == 1) ? 1 : 0); ii < NUM_WORDS; ii = ii + 1 ) begin : gb_words
            if( LINEAR_COUNT != 0 )
            begin : gb_linear
                if ( COUNT_DOWN != 1'b0 )
                    assign next_dout_int[(ii*WORD_WIDTH) +: WORD_WIDTH] = dout_int[0 +: WORD_WIDTH] - ii + 1;
                else
                    assign next_dout_int[(ii*WORD_WIDTH) +: WORD_WIDTH] = dout_int[0 +: WORD_WIDTH] + ii + 1;
            end
            else // Random sequence required
            begin : gb_random
                // Using remainder, %, is okay as WORD_WIDTH is set to be a multiple of 8.
                assign next_dout_int[(ii*WORD_WIDTH) +: WORD_WIDTH] = rand_word( dout_int[0 +: WORD_WIDTH], ((ii+5) % WORD_WIDTH) );
            end
        end
    end
    endgenerate

    // Reset sequence on rising edge of start
    logic   start_d;

    logic [OUTPUT_WIDTH_INT-1:0] temp_check;
    assign temp_check = rand_word( dout_int, 5 );

    always @(posedge i_clk)
    begin
        start_d <= i_start;
        // Have separate start signal, different from reset circuit
        if( ~i_reset_n || (i_start && ~start_d) )
            dout_int <= INIT_VALUE;
        else if ( i_enable )
            dout_int <= next_dout_int;
    end

    assign o_dout = dout_int[0+:OUTPUT_WIDTH];

endmodule : random_seq_gen

