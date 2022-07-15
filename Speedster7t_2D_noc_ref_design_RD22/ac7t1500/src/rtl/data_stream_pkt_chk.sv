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
// Check packets received from data stream bus
//      Use the same random generators as the data_stream_pkt_gen.  These will
//      then produce the same random sequence.  Removes requirement to
//      store values in local FIFOs.
//      Designed to read from NAPs sent from other NAP via the NOC
// ------------------------------------------------------------------

`include "nap_interfaces.svh"

module data_stream_pkt_chk
  #(
    parameter   LINEAR_PKTS             = 0,        // Set to 1 to make packets have linear counts
    parameter   TGT_DATA_WIDTH          = 0,        // Target data width.
    parameter   FIRST_WORD_LINEAR       = 1,        // Determine if the first word is linear, even if LINEAR_PKTS=0
    parameter logic [TGT_DATA_WIDTH -1:0] INIT_VALUE 
                                        = {TGT_DATA_WIDTH{1'b0}} // Start-up value when random. Active when LINEAR_PKTS=0
    )
   (
    // Inputs
    input wire            i_clk,
    input wire            i_reset_n,                  // Negative synchronous reset
    input wire            i_start,                    // Start sequence from beginning
    input wire            i_enable,                   // Enable packet generation
    t_DATA_STREAM.rx if_data_stream,                  // data stream interface
    output wire           o_pkt_error,                // Assert if there is a mismatch
    output wire [32 -1:0] o_total_transactions,       // total number of transactions checked
    output wire [32 -1:0] o_total_match_transactions, // total number of correct transactions
    output wire [32 -1:0] o_total_fail_transactions   // total number of mismatched transactions
    );
   
   
   logic [TGT_DATA_WIDTH-1:0] exp_data_stream;
   logic [TGT_DATA_WIDTH-1:0] rd_data_stream;
   logic                      data_start;
   logic                      data_start_d;
   logic                      start_edge_detect;
   logic                      data_enable;
   logic                      gen_first_value;
   
   // Register data streaming signals to improve timing.
   logic                      rx_ready_d   /* synthesis syn_maxfan=4 */;
   logic                      rx_valid_d   /* synthesis syn_maxfan=4 */;
   logic                      rx_eop_d     /* synthesis syn_maxfan=4 */;
   logic                      rx_sop_d     /* synthesis syn_maxfan=4 */;
   logic [3:0]                rx_src_d     /* synthesis syn_maxfan=4 */;
   
   // logic for matching the data, done in stages
   logic [18:0]               data_match_stg1;
   logic [3:0]                data_match_stg2;
   logic                      rdy_and_valid_d1;
   logic                      rdy_and_valid_d2;
   


   // Start the data
   assign data_start  = i_start;

   // Random sequence generator will reset to INIT_VALUE on rising edge of start
   // It then needs to generate the first value to match the output of the ds_pkt_gen block
   always@(posedge i_clk)
     begin
        data_start_d <= data_start;
        if( ~i_reset_n ) // reset
          start_edge_detect <= 1'b0;
        else if (data_start & ~data_start_d)
          start_edge_detect <= 1'b1;
        else if (gen_first_value)
          start_edge_detect <= 1'b0;
     end

   // Instantiate random sequence generator for data
   random_seq_gen #(
                    .OUTPUT_WIDTH      (TGT_DATA_WIDTH),
                    .WORD_WIDTH        (8),
                    .LINEAR_COUNT      (LINEAR_PKTS),
                    .COUNT_DOWN        (0),
                    .FIRST_WORD_LINEAR (FIRST_WORD_LINEAR),
                    .INIT_VALUE        (INIT_VALUE)
                    ) 
   i_data_gen (
               // Inputs
               .i_clk              (i_clk),
               .i_reset_n          (i_reset_n),
               .i_start            (data_start),
               .i_enable           (data_enable | gen_first_value),
               // Outputs
               .o_dout             (exp_data_stream)
               );
   


   // Capture the read data 
   always@(posedge i_clk)
     begin
          rd_data_stream <= if_data_stream.data;
     end
   
   // -------------------------------------------------------------------------
   // State machine to read a data stream (flit transfer)
   // -------------------------------------------------------------------------
   enum {CHK_IDLE, CHK_GEN_FIRST, CHK_RUNNING} chk_state;

   logic pkt_error;
   logic [2:0] pkt_error_pipe; // Pipeline to allow for retiming
   logic       pkt_error_latch;
   logic       pkt_error_final;
   logic       pkt_sample;
   
   // synthesis synthesis_off
   integer     mismatch_message_count = 0;
   // synthesis synthesis_on


   // State machine for checking the read data
   always @(posedge i_clk)
     begin
        gen_first_value      <= 1'b0;
        //        if_data_stream.ready <= 1'b0;
        if( ~i_reset_n ) // reset
          begin
             chk_state <= CHK_IDLE; // set to Idle
             if_data_stream.ready <= 1'b0;
          end
        else 
          begin
             case (chk_state) // read state machine, determine next state
               CHK_IDLE :
                 if( i_enable ) // enable is high
                   begin
                      if ( ~start_edge_detect )   // Start already issued, so do not require a new first value
                        chk_state <= CHK_RUNNING;   // Start to check data
                      else
                        chk_state <= CHK_GEN_FIRST; // Generate first value
                   end
                 else // Remain in idle
                   begin
                      chk_state <= CHK_IDLE;
                      if(start_edge_detect) // lower ready until pattern starts up
                        if_data_stream.ready <= 1'b0;
                   end

               CHK_GEN_FIRST :  // State to allow random_seq_gen to create first value.
                 begin
                    if ( start_edge_detect )
                      begin
                         gen_first_value <= 1'b1;
                         chk_state <= CHK_RUNNING;
                         if_data_stream.ready <= 1'b0;
                      end
                 end

               CHK_RUNNING : // Actively checking the received data stream
                 begin
                    if( i_enable ) // Continue checking
                      begin
                         if_data_stream.ready <= 1'b1;
                         chk_state <= CHK_RUNNING;
                      end
                    else
                      chk_state <= CHK_IDLE; // Return to idle
                 end

               default :
                 chk_state <= CHK_IDLE;
             endcase // case (rd_state)
          end // else: !if( ~i_reset_n )
     end // always @ (posedge i_clk)


   // Enable next expected data
   // Set when plan to read next piece of data from NAP
   always@(posedge i_clk)
     data_enable <= (if_data_stream.valid && if_data_stream.ready);
   

   // Pipeline error detection to allow for retiming
   always @(posedge i_clk)
     pkt_error_pipe <= {pkt_error_pipe[1:0], pkt_error};

   // Only reset the output flop, latch any error 
   always @(posedge i_clk)
     if(!i_reset_n) // reset
       pkt_error_latch <= 1'b0;
     else if ( pkt_error_pipe[2] )
       pkt_error_latch <= 1'b1;

   // Check to see if there is at least one sample
   always @(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          pkt_sample <= 1'b0; // no samples
        else if(rx_ready_d && rx_valid_d) // valid and ready
          pkt_sample <= 1'b1;
     end // always@ (posedge i_clk)

   // Check to see if expected data matches or not
   always @(posedge i_clk)
     begin
        pkt_error <= 1'b0;
        if(rx_ready_d && rx_valid_d) // valid and ready
          begin
             if(exp_data_stream !== rd_data_stream ) // data doesn't match
               begin // flag an error
                  // synthesis synthesis_off
                  if( mismatch_message_count < 20 )
                    begin
                       $error( "%t : Read data stream mismatch.  Got %h Expected %h", $time, rd_data_stream, exp_data_stream );
                       mismatch_message_count <= mismatch_message_count + 1;
                    end
                  // synthesis synthesis_on
                  // mismatch, increment failed transaction number
                  pkt_error <= 1'b1;
               end // if (exp_data_stream !== rd_data_stream )
          end // if (rx_ready_d && rx_valid_d)
     end // always@ (posedge i_clk)

   // flop the ready and valid for stages
   always@(posedge i_clk)
     begin
        rdy_and_valid_d1 <= (rx_ready_d && rx_valid_d);
        rdy_and_valid_d2 <= rdy_and_valid_d1;
     end // always@ (posedge i_clk)
   


   
   // check if the data matches in groups
   // break it down into sections so that it's easier to meet timing
   always@(posedge i_clk)
     begin
        if(!i_reset_n) // reset
          begin
             data_match_stg1[17:0] <= 18'h0;
          end // if (!i_reset_n)
        else if(rx_ready_d && rx_valid_d) // valid and ready
          begin
             data_match_stg1[0] <= (exp_data_stream[(16*1)-1:(16*0)] == rd_data_stream[(16*1)-1:(16*0)]);
             data_match_stg1[1] <= (exp_data_stream[(16*2)-1:(16*1)] == rd_data_stream[(16*2)-1:(16*1)]);
             data_match_stg1[2] <= (exp_data_stream[(16*3)-1:(16*2)] == rd_data_stream[(16*3)-1:(16*2)]);
             data_match_stg1[3] <= (exp_data_stream[(16*4)-1:(16*3)] == rd_data_stream[(16*4)-1:(16*3)]);
             data_match_stg1[4] <= (exp_data_stream[(16*5)-1:(16*4)] == rd_data_stream[(16*5)-1:(16*4)]);
             data_match_stg1[5] <= (exp_data_stream[(16*6)-1:(16*5)] == rd_data_stream[(16*6)-1:(16*5)]);
             data_match_stg1[6] <= (exp_data_stream[(16*7)-1:(16*6)] == rd_data_stream[(16*7)-1:(16*6)]);
             data_match_stg1[7] <= (exp_data_stream[(16*8)-1:(16*7)] == rd_data_stream[(16*8)-1:(16*7)]);
             data_match_stg1[8] <= (exp_data_stream[(16*9)-1:(16*8)] == rd_data_stream[(16*9)-1:(16*8)]);
             data_match_stg1[9] <= (exp_data_stream[(16*10)-1:(16*9)] == rd_data_stream[(16*10)-1:(16*9)]);
             data_match_stg1[10] <= (exp_data_stream[(16*11)-1:(16*10)] == rd_data_stream[(16*11)-1:(16*10)]);
             data_match_stg1[11] <= (exp_data_stream[(16*12)-1:(16*11)] == rd_data_stream[(16*12)-1:(16*11)]);
             data_match_stg1[12] <= (exp_data_stream[(16*13)-1:(16*12)] == rd_data_stream[(16*13)-1:(16*12)]);
             data_match_stg1[13] <= (exp_data_stream[(16*14)-1:(16*13)] == rd_data_stream[(16*14)-1:(16*13)]);
             data_match_stg1[14] <= (exp_data_stream[(16*15)-1:(16*14)] == rd_data_stream[(16*15)-1:(16*14)]);
             data_match_stg1[15] <= (exp_data_stream[(16*16)-1:(16*15)] == rd_data_stream[(16*16)-1:(16*15)]);
             data_match_stg1[16] <= (exp_data_stream[(16*17)-1:(16*16)] == rd_data_stream[(16*17)-1:(16*16)]);
             data_match_stg1[17] <= (exp_data_stream[(16*18)-1:(16*17)] == rd_data_stream[(16*18)-1:(16*17)]);
             //`ifdef(TGT_DATA_WIDTH > 288)
             //             data_match_stg1[18] <= (exp_data_stream[TGT_DATA_WIDTH-1:(16*18)] == rd_data_stream[TGT_DATA_WIDTH-1:(16*18)]);
             //`else
             //             data_match_stg1[18] <= 1'b1; // just set to 1 if not there
             //`endif
          end // if (rx_ready_d && rx_valid_d)
     end // always@ (posedge i_clk)


   generate
      if(TGT_DATA_WIDTH > 288)
        begin
           always@(posedge i_clk)
             begin
                if(!i_reset_n)
                  data_match_stg1[18] <= 1'b0;
                else if(rx_ready_d && rx_valid_d) // valid and ready
                  data_match_stg1[18] <= (exp_data_stream[TGT_DATA_WIDTH-1:(16*18)] == rd_data_stream[TGT_DATA_WIDTH-1:(16*18)]);
             end
        end
      else
        begin
           always@(posedge i_clk)
             begin
                data_match_stg1[18] <= 1'b1; // just set to 1 if not there
             end
        end // else: !if(TGT_DATA_WIDTH > 288)
   endgenerate
   

   
   
   // combine match signals in stage 2
   always@(posedge i_clk)
     begin
        if(!i_reset_n)
          data_match_stg2 <= 4'h0;
        else if(rdy_and_valid_d1) // valid and ready
          begin
             data_match_stg2[0] <= &(data_match_stg1[4:0]);
             data_match_stg2[1] <= &(data_match_stg1[9:5]);
             data_match_stg2[2] <= &(data_match_stg1[14:10]);
             data_match_stg2[3] <= &(data_match_stg1[18:15]);
          end
     end // always@ (posedge i_clk)

   // Counters   
   logic [16 -1:0]     total_low_count;
   logic [16 -1:0]     total_low_count_d;
   logic [16 -1:0]     total_high_count;
   logic [16 -1:0]     match_low_count;
   logic [16 -1:0]     match_low_count_d;
   logic [16 -1:0]     match_high_count;
   logic [16 -1:0]     fail_low_count;
   logic [16 -1:0]     fail_low_count_d;
   logic [16 -1:0]     fail_high_count;
   logic               total_low_carry;
   logic               match_low_carry;
   logic               fail_low_carry;

   assign o_total_transactions       = {total_high_count, total_low_count_d};
   assign o_total_match_transactions = {match_high_count, match_low_count_d};
   assign o_total_fail_transactions  = {fail_high_count,  fail_low_count_d};
   
   // Low bit counters
   always @(posedge i_clk)
     begin
        total_low_count_d <= total_low_count;
        match_low_count_d <= match_low_count;
        fail_low_count_d  <= fail_low_count;
        total_low_carry   <= 1'b0;
        match_low_carry   <= 1'b0;
        fail_low_carry    <= 1'b0;
        if(!i_reset_n) // reset
          begin
             total_low_count  <= 16'd0;
             match_low_count  <= 16'd0;
             fail_low_count   <= 16'd0;
          end
        else if(rdy_and_valid_d2) // valid and ready
          begin
             total_low_count <= total_low_count + 16'd1;
             total_low_carry <= (total_low_count == 16'hffff);

             if(&data_match_stg2[3:0]) // data all matches
               begin
                  match_low_count <= match_low_count + 16'd1;
                  match_low_carry <= (match_low_count == 16'hffff);
               end
             else
               begin // flag an error
                  fail_low_count <= fail_low_count + 16'd1;
                  fail_low_carry <= (fail_low_count == 16'hffff);
               end
          end // if (rdy_and_valid_d2)
     end // always @ (posedge i_clk)

   // High bit counters   
   always @(posedge i_clk)
     if(!i_reset_n) // reset
       total_high_count <= 16'd0;
     else if (total_low_carry)
       total_high_count <= total_high_count + 16'd1;

   always @(posedge i_clk)
     if(!i_reset_n) // reset
       match_high_count <= 16'd0;
     else if (match_low_carry)
       match_high_count <= match_high_count + 16'd1;

   always @(posedge i_clk)
     if(!i_reset_n) // reset
       fail_high_count <= 16'd0;
     else if (fail_low_carry)
       fail_high_count <= fail_high_count + 16'd1;



   // Set error if there is a data mismatch, or else no samples
   always @(posedge i_clk)
     pkt_error_final <= pkt_error_latch | (!pkt_sample);

   assign o_pkt_error = pkt_error_final;

   // Improve timing by registering signals
   always @(posedge i_clk)
     begin
        rx_valid_d   <= if_data_stream.valid;
        rx_ready_d   <= if_data_stream.ready;
        rx_eop_d     <= if_data_stream.eop;
        rx_sop_d     <= if_data_stream.sop;
        rx_src_d     <= if_data_stream.addr;
     end
   /*   
    assign if_data_stream.ready = rx_ready_d;

    // set ready output high
    always@(posedge i_clk)
    begin
    if(~i_reset_n) // reset
    rx_ready_d <= 1'b0;
    else // set high once out of reset
    rx_ready_d <= 1'b1;
     end
    */   

   /*
    
    // -------------------------------------------------------------------------
    // Task to read data stream from NAP (flit transfer)
    // -------------------------------------------------------------------------
    // This task is called within an always @(posedge clk) block
    task read_data_stream;
    begin
    if( ~i_reset_n ) // reset
    begin
    rx_ready_d        <= 1'b0; // set not ready
    return;
           end
    else
    begin
    // Assert ready to receive the read data
    rx_ready_d <= 1'b1;
    
    // wait to see if a valid read
    while(!rx_valid_d)
    @(posedge i_clk);
    
    // advance the clock
    @(posedge i_clk);
    
    rx_ready_d <= 1'b0; // lower ready
           end // else: !if( ~i_reset_n )
      end
   endtask : read_data_stream
    */   
endmodule : data_stream_pkt_chk

