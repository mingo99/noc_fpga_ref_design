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
// Master reset processor
//      Combines up to 4 negative sense reset signals, 
//      Synchronizes them to an array of input clocks
//      Adds a pipeline to each output to allow for fanout and 
//      distribution through synthesis and place and route
// ------------------------------------------------------------------


module reset_processor
#(
    parameter   NUM_INPUT_RESETS        = 0,        // Number of clocks, (and hence resets).
    parameter   NUM_OUTPUT_RESETS       = 0,        // Number of output resets, (and hence clocks)
    parameter   RST_PIPE_LENGTH         = 2         // Length of reset flop pipeline, minimum of 2
)
(
    // Inputs
    input  wire [NUM_INPUT_RESETS  -1:0] i_rstn_array,   // Up to 4 negative sense reset inputs
    input  wire [NUM_OUTPUT_RESETS -1:0] i_clk,          // Input clock array

    // Outputs
    output wire [NUM_OUTPUT_RESETS -1:0] o_rstn_array    // Processed resets
);


    // Combine the input array into one master reset
    logic master_rstn;
    assign master_rstn = &i_rstn_array;

    // Generate synchronizer and pipeline per clock domain
    generate for (genvar ii=0; ii < NUM_OUTPUT_RESETS; ii = ii + 1) begin : gb_per_clk

        logic                       sync_rstn;      // Synchronised reset
        logic [RST_PIPE_LENGTH-1:0] pipe_rstn;      // Reset pipeline

        // Synchronise
        ACX_SYNCHRONIZER x_sync_mstr_rstn (.din(1'b1), .dout(sync_rstn), .clk(i_clk[ii]), .rstn(master_rstn));

        // Pipeline
        always @(posedge i_clk[ii] or negedge sync_rstn)
        begin
            if (~sync_rstn)
              pipe_rstn <= 0;
            else
              pipe_rstn <= {pipe_rstn[RST_PIPE_LENGTH-2:0], sync_rstn};
        end

        // Assign to output
        assign o_rstn_array[ii] = pipe_rstn[RST_PIPE_LENGTH-1];

    end
    endgenerate

endmodule : reset_processor

