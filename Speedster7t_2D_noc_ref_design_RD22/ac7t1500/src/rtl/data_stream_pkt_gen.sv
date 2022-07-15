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
// Generate random packets, using data streaming bus
//      Designed to input to NAPs to then exercise a second NAP
//      via the NOC
// ------------------------------------------------------------------

`include "nap_interfaces.svh"

module data_stream_pkt_gen
  #(
    parameter   LINEAR_PKTS             = 0,        // Set to 1 to make packets have linear counts
    parameter   TGT_DATA_WIDTH          = 0         // Target data width.
    )
   (
    // Inputs
    input wire       i_clk,
    input wire       i_reset_n,          // Negative synchronous reset
    input wire       i_start,            // Start sequence from beginning
    input wire       i_enable,           // Generate new packet
    input wire [3:0] i_dest_addr,
    t_DATA_STREAM.tx if_data_stream      // data stream interface
    );
   
   
   logic [TGT_DATA_WIDTH-1:0] data_stream_out;
   logic [TGT_DATA_WIDTH-1:0] data_stream_reg;
   logic                      data_start;
   logic                      data_start_d;
   logic                      data_enable;
   logic                      data_enable_reg;
   logic                      config_enable; // set when the user config bit is set high
   logic                      start_edge_detect;
   logic                      gen_first_value;
   
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
                    .OUTPUT_WIDTH       (TGT_DATA_WIDTH),
                    .WORD_WIDTH         (8),
                    .LINEAR_COUNT       (LINEAR_PKTS),    // Future enhancement would be to set to random
                    .COUNT_DOWN         (0)
                    ) 
   i_data_gen (
               // Inputs
               .i_clk              (i_clk),
               .i_reset_n          (i_reset_n),
               .i_start            (data_start),
               .i_enable           (data_enable & config_enable),
               // Outputs
               .o_dout             (data_stream_out)
               );



   //----------------------------------------------------------------
   // set up the data_enable signal to always send new data as long
   // as there is no back-pressure on the data-stream interface
   // and the design is sending data (from config register)
   //----------------------------------------------------------------

   always@(posedge i_clk)
     begin
        if(~i_reset_n) // reset
          begin
             data_enable <= 1'b0;
             data_enable_reg <= 1'b0;
          end
        else
          begin
             data_enable <= i_start & if_data_stream.ready;
             data_enable_reg <= data_enable;
          end
     end // always@ (posedge i_clk)
   


   // store 1 data when ready is lowered
   // needed because of the 1-cycle latency on enable
   always@(posedge i_clk)
     begin
        if(!if_data_stream.ready & data_enable)
          data_stream_reg <= data_stream_out;
     end
   


   // set with the enable signal
   always@(posedge i_clk)
     begin
        if(~i_reset_n) // reset
          config_enable <= 1'b0;
        else // set based on user config bit
          config_enable <= i_enable;
     end
   


   // -------------------------------------------------------------------------
   // State machine to read a data stream (flit transfer)
   // -------------------------------------------------------------------------
   enum {GEN_IDLE, GEN_FIRST, GEN_RUNNING} gen_state;


    // State machine for checking the read data
    always @(posedge i_clk)
    begin
        gen_first_value      <= 1'b0;
        if( ~i_reset_n ) // reset
        begin
            gen_state <= GEN_IDLE; // set to Idle
        end
        else 
        begin
            case (gen_state) // read state machine, determine next state
                GEN_IDLE :
                    if( i_enable & i_start ) // enable is high
                    begin
                        if ( ~start_edge_detect )   // Start already issued, so do not require a new first value
                            gen_state <= GEN_RUNNING;   // Start to check data
                        else
                            gen_state <= GEN_FIRST; // Generate first value
                    end
                    else // Remain in idle
                        gen_state <= GEN_IDLE;

                GEN_FIRST :  // State to allow random_seq_gen to create first value.
                begin
                    if ( start_edge_detect )
                    begin
                        gen_first_value <= 1'b1;
                        gen_state <= GEN_RUNNING;
                    end
                end

                GEN_RUNNING : // Actively sending the data stream
                begin
                    if( i_start ) // Continue sending
                    begin
                        gen_state <= GEN_RUNNING;
                    end
                    else
                        gen_state <= GEN_IDLE; // Return to idle
                end

                default :
                    gen_state <= GEN_IDLE;
            endcase // case (rd_state)
        end // else: !if( ~i_reset_n )
    end // always @ (posedge i_clk)


   

   //---------------------------------------------------------------
   // set output signals for the data-streaming interface
   // want to always send new data as long as the interface is ready
   //---------------------------------------------------------------

   // first tie eop and sop high since these are not being used/checked
   assign if_data_stream.eop = 1'b0;
   assign if_data_stream.sop = 1'b0;
   assign if_data_stream.addr = i_dest_addr; // set to input destination
   
   // now set up the dat and valid signals
   // always send data when available, but hold it until ready is high
   always@(posedge i_clk)
     begin
        if(~i_reset_n) // reset
          begin
             if_data_stream.valid <= 1'b0;
          end
        else if(gen_state == GEN_IDLE) // start went away, start over
          begin
             if_data_stream.valid <= 1'b0;
             if_data_stream.data  <= data_stream_out;
             
          end
        else if(!if_data_stream.ready & if_data_stream.valid) // ready is low, hold the valid value
          begin
             if_data_stream.valid <= if_data_stream.valid;
             if_data_stream.data  <= if_data_stream.data;
          end
//        else if(!if_data_stream.ready & !data_enable & data_enable_reg)
        else if((gen_state == GEN_RUNNING) && config_enable & 
                ((!data_enable & data_enable_reg) ||
                 (if_data_stream.ready & !data_enable & !data_enable_reg)))
          begin // grab last generated data before ready asserted again
             if_data_stream.valid <= 1'b1;
             if_data_stream.data  <= data_stream_reg;
          end
        else
          begin  
             if_data_stream.valid <= (gen_state == GEN_RUNNING) & data_enable & config_enable;
             if_data_stream.data  <= data_stream_out;
          end
     end // always@ (posedge i_clk)
   

/*   

   // -------------------------------------------------------------------------
   // State machine to write a data stream (flit transfer)
   // -------------------------------------------------------------------------
   enum {WR_IDLE, WR_GEN_VALUES, WR_WRITE} wr_state; // 1-hot state machine
   
   always @(posedge i_clk)
     begin
//        data_enable <= 1'b0;
        if( ~i_reset_n ) // reset
          begin
             wr_state <= WR_IDLE;
//             write_data_stream();
          end
        else begin // out of reset
           case (wr_state) // check write state
             WR_IDLE : // in idle, waiting
               if( i_enable ) 
                 begin
//                    data_enable <= 1'b1;
                    wr_state    <= WR_GEN_VALUES;
                 end
               else
                 wr_state    <= WR_IDLE;
             
             WR_GEN_VALUES :
               // State to allow random_seq_gen to create data values.
               wr_state <= WR_WRITE;
             
             WR_WRITE : // write to data stream
               begin
//                  write_data_stream();   // This may take multiple cycles
                  // Control will not pass to the next statement until done
                  wr_state <= WR_IDLE; // go back to Idle
               end
             default :
               wr_state    <= WR_IDLE;
           endcase // case (wr_state)
        end // else: !if( ~i_reset_n )
     end // always @ (posedge i_clk)
   
  
   // -------------------------------------------------------------------------
   // Task to write data stream
   // -------------------------------------------------------------------------
   // This task is called within an always @(posedge clk) block
   task write_data_stream;
      begin
         if( ~i_reset_n ) // reset
           begin
              // Not necessary to reset data buses
              // Will aid synthesis timing
              if_data_stream.addr = 4'h0; // destination
              if_data_stream.eop  = 1'b0; // end of packet
              if_data_stream.sop  = 1'b0; // start of packet

              // Do all handshake signals as non-blocking
              // to prevent simulation race conditions
              if_data_stream.valid <= 1'b0; // valid
              return;
           end // if ( ~i_reset_n )
         else
           begin
              // set the valid along with other values to transfer
              if_data_stream.addr   = i_dest_addr; // the destination
              if_data_stream.data   = data_stream_out;
              if_data_stream.valid <= 1'b1;
              
              // wait for ready signal to be asserted
              while(~if_data_stream.ready)
                @(posedge i_clk);
              
              // advance the clock
              @(posedge i_clk);
              
              // clear the valid signal, otherwise multiple requests will be made
              if_data_stream.valid <= 1'b0;
              
           end // else: !if( ~i_reset_n )
      end
   endtask : write_data_stream
*/   
   
endmodule : data_stream_pkt_gen

