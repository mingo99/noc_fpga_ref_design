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
// Pipeline shift register
//      Multitude of uses; including traversing signals across the die
//      By default it preserves the flops so they are not merged
//      In addition, by default, it only resets the first stage of the pipeline
//      If the reset lasts longer than the length of the pipeline, then
//      all stages will have been cleared by when reset is deasserted
// ------------------------------------------------------------------


module shift_reg
#(
    parameter   LENGTH      = 2,        // Number of stages, minimum of 2
    parameter   WIDTH       = 1,        // Width of input, minimum of 1
    parameter   NOKEEP      = 0,        // Do not apply keep attributes to registers
    parameter   RESET_ALL   = 0         // By default, only reset the first stage
                                        // If this is set, then reset all stages of the pipeline
)
(
    // Inputs
    input  wire                 i_clk,   // Input clock array
    input  wire                 i_rstn,  // Negative sense synchronous reset
    input  wire [WIDTH -1:0]    i_din,   // Data in

    // Outputs
    output wire [WIDTH -1:0]    o_dout   // Data out
);

    integer i;
    const logic [WIDTH -1:0] ZERO_WORD = {WIDTH{1'b0}};

    generate begin : gb
        // Check parameters
        if ( LENGTH < 2 )
            i_LENGTH_parameter_less_than_2 ERROR();

        if ( WIDTH < 1 )
            i_WIDTH_parameter_less_than_1 ERROR();

        if ( NOKEEP != 0 ) 
        begin : gb_nokeep
            // Define the pipeline
            // Use explicit name so it can be easily found in constraints
            logic [WIDTH -1:0] shift_reg_pipe [LENGTH -1:0] /* synthesis syn_ramstyle=registers */;

            // Synchronous reset shift register
            // Code for explicity 1'b1, prevents X's being propogated if reset unknown
            always @(posedge i_clk)
                if ( i_rstn !== 1'b1 )
                begin
                    if ( RESET_ALL == 0 )
                    begin
                        shift_reg_pipe[0] <= ZERO_WORD;
                        for (i=1; i < LENGTH; i++)
                            shift_reg_pipe[i] <= shift_reg_pipe[i-1];
                    end
                    else for (i=0; i < LENGTH; i++)
                        shift_reg_pipe[i] <= ZERO_WORD;
                end
                else
                begin
                    shift_reg_pipe[0] <= i_din;
                    for (i=1; i < LENGTH; i++)
                        shift_reg_pipe[i] <= shift_reg_pipe[i-1];
                end

            assign o_dout = shift_reg_pipe[LENGTH-1];
        end
        else
        begin : gb_keep
            // Define the pipeline
            // Use explicit name so it can be easily found in constraints
            (* must_keep=1 *) logic [WIDTH -1:0] shift_reg_pipe [LENGTH -1:0] /* synthesis syn_ramstyle=registers syn_preserve=1 */;

            // Synchronous reset shift register
            // Code for explicity 1'b1, prevents X's being propogated if reset unknown
            always @(posedge i_clk)
                if ( i_rstn !== 1'b1 )
                begin
                    if ( RESET_ALL == 0 )
                    begin
                        shift_reg_pipe[0] <= ZERO_WORD;
                        for (i=1; i < LENGTH; i++)
                            shift_reg_pipe[i] <= shift_reg_pipe[i-1];
                    end
                    else for (i=0; i < LENGTH; i++)
                        shift_reg_pipe[i] <= ZERO_WORD;
                end
                else
                begin
                    shift_reg_pipe[0] <= i_din;
                    for (i=1; i < LENGTH; i++)
                        shift_reg_pipe[i] <= shift_reg_pipe[i-1];
                end

            assign o_dout = shift_reg_pipe[LENGTH-1];
        end
    end
    endgenerate

endmodule : shift_reg

