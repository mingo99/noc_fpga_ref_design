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
//     Function: AXI Slave Registers 
// ------------------------------------------------------------------

module acx_slave_reg_if 
  # (
     parameter TGT_ADDR_WIDTH   = 28,
     parameter ID_WIDTH         = 8,
     parameter LEN_WIDTH        = 8,
     parameter BURST_WIDTH      = 2,
     parameter TGT_DATA_WIDTH   = 64, // 256,
     parameter STRB_WIDTH       = 8,  // 31,
     parameter RESP_WIDTH       = 2
     ) 
   (
    // Inputs
    input wire                      i_clk,
    input wire                      i_rstn,
    input wire                      i_axi_awvalid,
    input wire [TGT_ADDR_WIDTH-1:0] i_axi_awaddr,
    input wire [ID_WIDTH-1:0]       i_axi_awid,
    input wire [LEN_WIDTH-1:0]      i_axi_awlen,
    input wire [BURST_WIDTH-1:0]    i_axi_awburst,
    input wire                      i_axi_wvalid,
    input wire [TGT_DATA_WIDTH-1:0] i_axi_wdata,
    input wire [STRB_WIDTH-1:0]     i_axi_wstrb,
    input wire                      i_axi_wlast,
    input wire                      i_axi_bready,
    input wire                      i_axi_arvalid,
    input wire [TGT_ADDR_WIDTH-1:0] i_axi_araddr,
    input wire [ID_WIDTH-1:0]       i_axi_arid,
    input wire [LEN_WIDTH-1:0]      i_axi_arlen,
    input wire [BURST_WIDTH-1:0]    i_axi_arburst,
    input wire                      i_axi_rready,
    input wire                      i_reg_accept,
    input wire                      i_reg_ack,
    input wire                      i_reg_error,
    input wire [TGT_DATA_WIDTH-1:0] i_reg_read_data,
   
    // Outputs
    output reg                      o_axi_awready,
    output reg                      o_axi_wready,
    output reg                      o_axi_bvalid,
    output reg [RESP_WIDTH-1:0]     o_axi_bresp,
    output reg [ID_WIDTH-1:0]       o_axi_bid,
    output reg                      o_axi_arready,
    output reg                      o_axi_rvalid,
    output reg [TGT_DATA_WIDTH-1:0] o_axi_rdata,
    output reg [RESP_WIDTH-1:0]     o_axi_rresp,
    output reg [ID_WIDTH-1:0]       o_axi_rid,
    output reg                      o_axi_rlast,
    output reg [STRB_WIDTH-1:0]     o_reg_wr,
    output reg                      o_reg_rd,
    output reg [LEN_WIDTH-1:0]      o_reg_len,
    output reg [TGT_ADDR_WIDTH-1:0] o_reg_addr,
    output reg [TGT_DATA_WIDTH-1:0] o_reg_write_data
);

   localparam REQ_WIDTH = (1+1+ID_WIDTH);

   // make internal signals that are not flopped
   logic                        axi_awready_int;
   logic                        axi_wready_int;
   logic                        axi_bvalid_int;
   logic [RESP_WIDTH-1:0]       axi_bresp_int;
   logic [ID_WIDTH-1:0]         axi_bid_int;
   logic                        axi_arready_int;
   logic                        axi_rvalid_int;
   logic [TGT_DATA_WIDTH-1:0]   axi_rdata_int;
   logic [RESP_WIDTH-1:0]       axi_rresp_int;
   logic [ID_WIDTH-1:0]         axi_rid_int;
   logic                        axi_rlast_int;
   logic [STRB_WIDTH-1:0]       reg_wr_int;
   logic                        reg_rd_int;
   logic [LEN_WIDTH-1:0]        reg_len_int;
   logic [TGT_ADDR_WIDTH-1:0]   reg_addr_int;
   logic [TGT_DATA_WIDTH-1:0]   reg_write_data_int;
   

   // flop input  wires from AXI interface
   logic                        axi_awvalid_int;
   logic [TGT_ADDR_WIDTH-1:0]   axi_awaddr_int;
   logic [ID_WIDTH-1:0]         axi_awid_int;
   logic [LEN_WIDTH-1:0]        axi_awlen_int;
   logic [BURST_WIDTH-1:0]      axi_awburst_int;
   logic                        axi_wvalid_int;
   logic [TGT_DATA_WIDTH-1:0]   axi_wdata_int;
   logic [STRB_WIDTH-1:0]       axi_wstrb_int;
   logic                        axi_wlast_int;
   logic                        axi_bready_int;
   logic                        axi_arvalid_int;
   logic [TGT_ADDR_WIDTH-1:0]   axi_araddr_int;
   logic [ID_WIDTH-1:0]         axi_arid_int;
   logic [LEN_WIDTH-1:0]        axi_arlen_int;
   logic [BURST_WIDTH-1:0]      axi_arburst_int;
   logic                        axi_rready_int;   

   // flop the AXI input  wires to help timing
   always@(posedge i_clk)
     begin
        if (~i_rstn)
          begin
             axi_awvalid_int <= 1'b0;
             axi_wvalid_int  <= 1'b0;
             axi_wlast_int   <= 1'b0;
             axi_bready_int  <= 1'b0;
             axi_arvalid_int <= 1'b0;
             axi_rready_int  <= 1'b0;
          end
        else
          begin
             axi_awvalid_int <= i_axi_awvalid;
             axi_awaddr_int  <= i_axi_awaddr;
             axi_awid_int    <= i_axi_awid;
             axi_awlen_int   <= i_axi_awlen;
             axi_awburst_int <= i_axi_awburst;
             axi_wvalid_int  <= i_axi_wvalid;
             axi_wdata_int   <= i_axi_wdata;
             axi_wstrb_int   <= i_axi_wstrb;
             axi_wlast_int   <= i_axi_wlast;
             axi_bready_int  <= i_axi_bready;
             axi_arvalid_int <= i_axi_arvalid;
             axi_araddr_int  <= i_axi_araddr;
             axi_arid_int    <= i_axi_arid;
             axi_arlen_int   <= i_axi_arlen;
             axi_arburst_int <= i_axi_arburst;
             axi_rready_int  <= i_axi_rready;
          end // else: !if (~i_rstn)
     end // always@ (posedge i_clk)
   
   

   
   //-------------------------------------------------------------
   // calculate_addr_next
   //-------------------------------------------------------------
   function [TGT_ADDR_WIDTH-1:0] calculate_addr_next;
      input [TGT_ADDR_WIDTH-1:0]  addr;
      input [1:0]                 axtype;
      input [LEN_WIDTH-1:0]       axlen;

      reg [TGT_ADDR_WIDTH-1:0]    mask;
      begin
         mask = 0;

         case (axtype)
           2'd0: // AXI4_BURST_FIXED
             begin
                calculate_addr_next = addr;
             end
           2'd2: // AXI4_BURST_WRAP
             begin
                case (axlen)
                  8'd0:      mask = 'h03;
                  8'd1:      mask = 'h07;
                  8'd3:      mask = 'h0F;
                  8'd7:      mask = 'h1F;
                  8'd15:     mask = 'h3F;
                  default:   mask = 'h3F;
                endcase

                calculate_addr_next = (addr & ~mask) | ((addr + 4) & mask);
             end
           default: // AXI4_BURST_INCR
             calculate_addr_next = addr + 4;
         endcase
      end
   endfunction

   //-----------------------------------------------------------------
   // Registers / Wires
   //-----------------------------------------------------------------
   reg [LEN_WIDTH-1:0]          req_len_q;
   reg [TGT_ADDR_WIDTH-1:0]     req_addr_q;
   reg [TGT_ADDR_WIDTH-1:0]     req_addr_q_wr_start;
   reg [TGT_ADDR_WIDTH-1:0]     req_addr_q_rd_start;
//   reg [TGT_ADDR_WIDTH-1:0]     req_addr_q_inc;
   reg                          req_rd_q;
   (* must_keep=1 *)   reg      req_wr_q /* synthesis syn_preserve=1 syn_maxfan=10 */;
   reg [ID_WIDTH-1:0]           req_id_q;
   reg [1:0]                    req_axburst_q;
   reg [LEN_WIDTH-1:0]          req_axlen_q;
   reg                          req_prio_q;
   reg                          req_hold_rd_q;
   reg                          req_hold_wr_q;
   wire                         req_fifo_accept_w;

   reg [TGT_ADDR_WIDTH-1:0]   req_addr_q_d1;
   reg                        req_rd_q_d1;
   (* must_keep=1 *)   reg    req_wr_q_d1 /* synthesis syn_preserve=1 syn_maxfan=10 */;
   reg                        write_active_w_d1;
   reg                        read_active_w_d1;
   logic [TGT_ADDR_WIDTH-1:0] axi_awaddr_int_d1;
   logic [TGT_ADDR_WIDTH-1:0] axi_araddr_int_d1;
   logic                      axi_wvalid_int_d1;
   logic                      axi_awvalid_int_d1;
   logic                      axi_arvalid_int_d1;
   logic [LEN_WIDTH-1:0]      axi_arlen_int_d1;
   logic [LEN_WIDTH-1:0]      axi_awlen_int_d1;
   logic [TGT_DATA_WIDTH-1:0] axi_wdata_int_d1;
   logic [STRB_WIDTH-1:0]     axi_wstrb_int_d1;


   logic                      axi_awready_int_d1;
   logic                      axi_wready_int_d1;
   logic                      axi_arready_int_d1;
   logic                      axi_rvalid_int_d1;
   logic [TGT_DATA_WIDTH-1:0] axi_rdata_int_d1;
   logic [RESP_WIDTH-1:0]     axi_rresp_int_d1;
   logic [ID_WIDTH-1:0]       axi_rid_int_d1;
   logic                      axi_rlast_int_d1;

   //-----------------------------------------------------------------
   // Sequential
   //-----------------------------------------------------------------
   always @ (posedge i_clk)
   begin
     // Precalculate starting addresses
     req_addr_q_wr_start <= calculate_addr_next(axi_awaddr_int, axi_awburst_int, axi_awlen_int);
     req_addr_q_rd_start <= calculate_addr_next(axi_araddr_int, axi_arburst_int, axi_arlen_int);
//     req_addr_q_inc      <= calculate_addr_next(req_addr_q, req_axburst_q, req_axlen_q);

     if (~i_rstn)
       begin
          req_len_q     <= 'b0;
          req_addr_q    <= 'b0;
          req_wr_q      <= 'b0;
          req_rd_q      <= 'b0;
          req_id_q      <= 'b0;
          req_axburst_q <= 'b0;
          req_axlen_q   <= 'b0;
          req_prio_q    <= 'b0;
       end
     else
       begin
          // Burst continuation
          if ((reg_wr_int != 'b0 || reg_rd_int) && i_reg_accept)
            begin
               if (req_len_q == 8'd0)
                 begin
                    req_rd_q   <= 1'b0;
                    req_wr_q   <= 1'b0;
                 end
               else
                 begin
                    req_addr_q <= calculate_addr_next(req_addr_q, req_axburst_q, req_axlen_q);
                    req_len_q  <= req_len_q - 8'd1;
                 end
            end

          // Write command accepted
          if (axi_awvalid_int && axi_awready_int)
            begin
               // Data ready?
               if (axi_wvalid_int && axi_wready_int)
                 begin
                    req_wr_q      <= !axi_wlast_int;
                    req_len_q     <= axi_awlen_int - 8'd1;
                    req_id_q      <= axi_awid_int;
                    req_axburst_q <= axi_awburst_int;
                    req_axlen_q   <= axi_awlen_int;
//                    req_addr_q    <= calculate_addr_next(axi_awaddr_int, axi_awburst_int, axi_awlen_int);
                    req_addr_q    <= req_addr_q_wr_start;
                 end
               // Data not ready
               else
                 begin
                    req_wr_q      <= 1'b1;
                    req_len_q     <= axi_awlen_int;
                    req_id_q      <= axi_awid_int;
                    req_axburst_q <= axi_awburst_int;
                    req_axlen_q   <= axi_awlen_int;
                    req_addr_q    <= axi_awaddr_int;
                 end
               req_prio_q    <= !req_prio_q;
            end
          // Read command accepted
          else if (axi_arvalid_int && axi_arready_int)
            begin
               req_rd_q      <= (axi_arlen_int != 0);
               req_len_q     <= axi_arlen_int - 8'd1;
//               req_addr_q    <= calculate_addr_next(axi_araddr_int, axi_arburst_int, axi_arlen_int);
               req_addr_q    <= req_addr_q_rd_start;
               req_id_q      <= axi_arid_int;
               req_axburst_q <= axi_arburst_int;
               req_axlen_q   <= axi_arlen_int;
               req_prio_q    <= !req_prio_q;
            end
       end
   end


   always @ (posedge i_clk)
     if (~i_rstn)
       begin
          req_hold_rd_q   <= 1'b0;
          req_hold_wr_q   <= 1'b0;
       end
     else
       begin
          if (reg_rd_int && !i_reg_accept)
            req_hold_rd_q   <= 1'b1;
          else if (i_reg_accept)
            req_hold_rd_q   <= 1'b0;

          if ((|reg_wr_int) && !i_reg_accept)
            req_hold_wr_q   <= 1'b1;
          else if (i_reg_accept)
            req_hold_wr_q   <= 1'b0;
       end

   //-----------------------------------------------------------------
   // Request tracking
   //-----------------------------------------------------------------
   reg req_push_w;
   always@(posedge i_clk)
     begin
        if (~i_rstn) // reset
          req_push_w <= 1'b0;
        else
          req_push_w <= (reg_rd_int || (reg_wr_int != 'b0)) && i_reg_accept;
     end
   
   reg [REQ_WIDTH-1:0]  req_in_r;
   wire                 req_out_valid_w;
   wire [REQ_WIDTH-1:0] req_out_w;
   wire                 resp_accept_w;

   always@(posedge i_clk)
     begin
        if (~i_rstn) // reset
          req_in_r <= 'b0;

        // First cycle of read burst
        else if (axi_arvalid_int && axi_arready_int)
          req_in_r <= {1'b1, (axi_arlen_int == 8'd0), axi_arid_int};
        // First cycle of write burst
        else if (axi_awvalid_int && axi_awready_int)
          req_in_r <= {1'b0, (axi_awlen_int == 8'd0), axi_awid_int};
        // In burst
        else
          req_in_r <= {reg_rd_int, (req_len_q == 8'd0), req_id_q};
     end

   acx_axi_req_fifo
     #( .WIDTH      (REQ_WIDTH) )
   u_requests
     (
      .i_clk        (i_clk),
      .i_rstn       (i_rstn),

      // input  wire
      .data_in_i    (req_in_r),
      .i_push       (req_push_w),
      .o_accept     (req_fifo_accept_w),

      // Output
      .i_pop        (resp_accept_w),
      .data_out_o   (req_out_w),
      .o_valid      (req_out_valid_w)
      );

   wire resp_is_write_w = req_out_valid_w ? ~req_out_w[ID_WIDTH+1] : 1'b0;
   wire resp_is_read_w  = req_out_valid_w ? req_out_w[ID_WIDTH+1]  : 1'b0;
   wire resp_is_last_w  = req_out_w[ID_WIDTH];  
   wire [ID_WIDTH-1:0] resp_id_w = req_out_w[ID_WIDTH-1:0];

   //-----------------------------------------------------------------
   // Response buffering
   //-----------------------------------------------------------------
   wire                resp_valid_w;

   acx_axi_req_fifo
     #( .WIDTH(TGT_DATA_WIDTH) )
   u_response
     (
      .i_clk(i_clk),
      .i_rstn(i_rstn),

      // input  wire
      .data_in_i(i_reg_read_data),
      .i_push(i_reg_ack),
      .o_accept(),

      // Output
      .i_pop(resp_accept_w),
      .data_out_o(axi_rdata_int),
      .o_valid(resp_valid_w)
      );

   //-----------------------------------------------------------------
   // Register Request
   //-----------------------------------------------------------------

   // Round robin priority between read and write
   //wire                write_prio_w   = ((req_prio_q  & !req_hold_rd_q) | req_hold_wr_q);
   //wire                read_prio_w    = ((!req_prio_q & !req_hold_wr_q) | req_hold_rd_q);

   logic               write_prio_w   ;
   logic               read_prio_w    ;

   always@(posedge i_clk) begin
      write_prio_w   <= ((req_prio_q  & !req_hold_rd_q) | req_hold_wr_q);
      read_prio_w    <= ((!req_prio_q & !req_hold_wr_q) | req_hold_rd_q);
   end


   wire                write_active_w  = (axi_awvalid_int || req_wr_q) && !req_rd_q && req_fifo_accept_w &&
                       (write_prio_w || req_wr_q || !axi_arvalid_int);
   wire                read_active_w   = (axi_arvalid_int || req_rd_q) && !req_wr_q && req_fifo_accept_w &&
                       (read_prio_w || req_rd_q || !axi_awvalid_int);

   assign axi_awready_int = write_active_w && !req_wr_q && i_reg_accept && req_fifo_accept_w;
   assign axi_wready_int  = write_active_w &&              i_reg_accept && req_fifo_accept_w;
   assign axi_arready_int = read_active_w  && !req_rd_q && i_reg_accept && req_fifo_accept_w;

   // flop outputs to help timing
   always@(posedge i_clk)
     begin
        if (~i_rstn)
          begin
             o_axi_awready <= 1'b0;
             o_axi_wready <= 1'b0;
             o_axi_arready <= 1'b0;
             //axi_awready_int_d1 <= 1'b0;
             //axi_wready_int_d1  <= 1'b0;
             //axi_arready_int_d1 <= 1'b0;
          end
        else
          begin
             axi_awready_int_d1 <= axi_awready_int;
             axi_wready_int_d1  <= axi_wready_int;
             axi_arready_int_d1 <= axi_arready_int;
             o_axi_awready <= axi_awready_int_d1;
             o_axi_wready  <= axi_wready_int_d1;
             o_axi_arready <= axi_arready_int_d1;
          end // else: !if (~i_rstn)
     end // always@ (posedge i_clk)
   
   always@(posedge i_clk) begin
      if (~i_rstn) begin
         //req_wr_q_d1          <= 'b0;
         //req_rd_q_d1          <= 'b0;
         //req_addr_q_d1        <= 'b0;
         //write_active_w_d1    <= 'b0;
         //read_active_w_d1     <= 'b0;
         //axi_awaddr_int_d1    <= 'b0;
         //axi_araddr_int_d1    <= 'b0;
         //axi_wvalid_int_d1    <= 'b0;
         //axi_awvalid_int_d1   <= 'b0;
         //axi_arvalid_int_d1   <= 'b0;
         //axi_arlen_int_d1     <= 'b0;
         //axi_awlen_int_d1     <= 'b0;
         //axi_wdata_int_d1     <= 'b0;
         //axi_wstrb_int_d1     <= 'b0;
      end
      else begin
         req_wr_q_d1          <= req_wr_q          ;
         req_rd_q_d1          <= req_rd_q          ;
         req_addr_q_d1        <= req_addr_q        ;
         write_active_w_d1    <= write_active_w    ;
         read_active_w_d1     <= read_active_w     ;
         axi_awaddr_int_d1    <= axi_awaddr_int    ;
         axi_araddr_int_d1    <= axi_araddr_int    ;
         axi_wvalid_int_d1    <= axi_wvalid_int    ;
         axi_awvalid_int_d1   <= axi_awvalid_int   ;
         axi_arvalid_int_d1   <= axi_arvalid_int   ;
         axi_arlen_int_d1     <= axi_arlen_int     ;
         axi_awlen_int_d1     <= axi_awlen_int     ;
         axi_wdata_int_d1     <= axi_wdata_int;
         axi_wstrb_int_d1     <= axi_wstrb_int;
      end
   end
   
   wire [TGT_ADDR_WIDTH-1:0] addr_w   = ((req_wr_q_d1 || req_rd_q_d1) ? req_addr_q_d1:
                                         write_active_w_d1 ? axi_awaddr_int_d1 : axi_araddr_int_d1);
   wire                      wr_w     = write_active_w_d1 && axi_wvalid_int_d1;
   wire                      rd_w     = read_active_w_d1;
   
   // Register if
   assign reg_addr_int       = addr_w;
   assign reg_write_data_int = axi_wdata_int_d1;
   assign reg_rd_int         = rd_w;
   assign reg_wr_int         = wr_w ? axi_wstrb_int_d1 :  'b0;
   assign reg_len_int        = axi_awvalid_int_d1 ? axi_awlen_int_d1:
                               axi_arvalid_int_d1 ? axi_arlen_int_d1 :  'b0;
   // flop outputs to help timing
   always@(posedge i_clk)
     begin
        o_reg_addr       <= reg_addr_int;
        o_reg_write_data <= reg_write_data_int;
        o_reg_rd         <= reg_rd_int;
        o_reg_wr         <= reg_wr_int;
        o_reg_len        <= reg_len_int;
     end
   
   //-----------------------------------------------------------------
   // Response
   //-----------------------------------------------------------------
   assign axi_bvalid_int  = resp_valid_w & resp_is_write_w & resp_is_last_w;
   assign axi_bresp_int   = 'b0;
   assign axi_bid_int     = resp_id_w;

   assign axi_rvalid_int  = resp_valid_w & resp_is_read_w;
   assign axi_rresp_int   = 'b0;
   assign axi_rid_int     = resp_id_w;
   assign axi_rlast_int   = resp_is_last_w;


   // flop outputs to help timing
   always@(posedge i_clk)
     begin
        if (~i_rstn)
          begin
             o_axi_bvalid <= 1'b0;
             o_axi_rvalid <= 1'b0;
             o_axi_rlast  <= 1'b0;
          end
        else
          begin
             o_axi_bvalid  <= axi_bvalid_int;
             o_axi_bresp   <= axi_bresp_int;
             o_axi_bid     <= axi_bid_int;

             axi_rvalid_int_d1  <= axi_rvalid_int;
             axi_rresp_int_d1   <= axi_rresp_int;
             axi_rid_int_d1     <= axi_rid_int;
             axi_rlast_int_d1   <= axi_rlast_int;
             axi_rdata_int_d1   <= axi_rdata_int;
             
             o_axi_rvalid  <= axi_rvalid_int_d1;
             o_axi_rresp   <= axi_rresp_int_d1;
             o_axi_rid     <= axi_rid_int_d1;
             o_axi_rlast   <= axi_rlast_int_d1;
             o_axi_rdata   <= axi_rdata_int_d1;
          end
     end // always@ (posedge i_clk)
   
   
   assign resp_accept_w    = (axi_rvalid_int & axi_rready_int) | 
                             (axi_bvalid_int & axi_bready_int) |
                             (resp_valid_w & resp_is_write_w & !resp_is_last_w); // Ignore write resps mid burst

   
endmodule : acx_slave_reg_if

