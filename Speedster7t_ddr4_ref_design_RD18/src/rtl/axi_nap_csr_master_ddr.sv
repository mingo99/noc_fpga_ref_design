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
// Configuration master
//      Uses AXI NAP to write to CSR space
// ------------------------------------------------------------------

`include "7t_interfaces.svh"

module axi_nap_csr_master_ddr
#(
    parameter CFG_ADDR_WIDTH = 28,
    parameter CFG_DATA_WIDTH = 256
)
(
    // Inputs
    input wire                            i_cfg_clk,     // Config clock
    input wire                            i_cfg_reset_n, // Config negative synchronous reset
    input wire [5:0]                     i_cfg_tgt_id, // Target ID of CSR is 6 bits
    input wire                            i_cfg_wr_rdn,  // Write not read
    input wire [CFG_ADDR_WIDTH -1:0]   i_cfg_addr,    // Individual IP address space is 28 bits
    input wire [CFG_DATA_WIDTH -1:0]   i_cfg_wdata,   // Write config data
    input wire                            i_cfg_req,     // Config request

    // Outputs
    output logic [CFG_DATA_WIDTH -1:0] o_cfg_rdata,   // Read config data
    output logic                        o_cfg_ack      // Config acknowledge
);

    // Local parameters to define SV interface sizes
    localparam NAP_DATA_WIDTH = `ACX_NAP_AXI_DATA_WIDTH;
    localparam NAP_ADDR_WIDTH = `ACX_NAP_AXI_SLAVE_ADDR_WIDTH;

    // Define CSR memory space
    localparam CSR_ADDR_ID = 8'h20;

    // Instantiate AXI_4 interfaces for configuration
    t_AXI4 #(
        .DATA_WIDTH (NAP_DATA_WIDTH),
        .ADDR_WIDTH (NAP_ADDR_WIDTH),
        .LEN_WIDTH  (8),
        .ID_WIDTH   (8) )
    csr_cfg();


    // Non-AXI signals from CSR config
    logic                       output_rstn_csr_cfg;
    logic                       error_valid_csr_cfg;
    logic [2:0]                 error_info_csr_cfg;

    // Instantiate slave nap and connect ports to SV interface
    nap_slave_wrapper #(
        .CSR_ACCESS_ENABLE(1'b1)
    ) i_axi_slave_wrapper_cfg (
        .i_clk                  (i_cfg_clk),
        .i_reset_n              (i_cfg_reset_n),
        .nap                    (csr_cfg),
        .o_output_rstn          (output_rstn_csr_cfg),
        .o_error_valid          (error_valid_csr_cfg),
        .o_error_info           (error_info_csr_cfg)
    );

    // State machine to write config values to master NAP
    enum  {CFG_IDLE, CFG_WRITE, CFG_READ, CFG_WAIT_REQ} cfg_state;

    bit                          req_dly         ;  // Cycle delay based on config request 
    bit [CFG_DATA_WIDTH-1:0]     i_cfg_wdata_reg ;  // To flop write data   
    bit                          i_cfg_wr_rdn_reg;    // Write-read signal which is at one cycle latency to match with awvalid/wvalid signals
    bit [CFG_ADDR_WIDTH-1:0]     i_cfg_wr_addr_reg1;  // Write address based on delay request and read/write latency delay, so that addresses match with AXI signals
    bit [CFG_ADDR_WIDTH-1:0]     i_cfg_rd_addr_reg1;  // Read address based on delay request and inversion of write/read latency, such that read address appears a cycle after write address
    bit [(CFG_DATA_WIDTH/8)-1:0] wstrb_net ;  // Used for CSR config based write strobe        

    bit [4:0]                    i_cfg_rd_addr_reg1_lsb_5bit; // Store lower five bits of read address to know position of incoming read data 
    
    // Inversion logic for write read signal 
    bit inv_i_cfg_wr_rdn_reg ; assign inv_i_cfg_wr_rdn_reg = ~i_cfg_wr_rdn_reg ;

    // Generation of control signals 
    always @ (posedge i_cfg_clk)
       begin
          if (i_cfg_reset_n == 1'b0)
             begin
                req_dly <= 1'b0 ;
                i_cfg_wdata_reg <= 0 ;
                i_cfg_wr_rdn_reg <= 1'b0 ;
                i_cfg_wr_addr_reg1 <= 0 ;
                i_cfg_rd_addr_reg1 <= 0 ;
             end
          else
             begin
                req_dly <= i_cfg_req ;
                i_cfg_wr_rdn_reg <= i_cfg_wr_rdn ;
                if ((i_cfg_req == 1'b1) && (req_dly == 1'b0))
                   begin
                      i_cfg_wdata_reg <= i_cfg_wdata ;
                   end
                if ((req_dly == 1'b0) && (i_cfg_wr_rdn_reg == 1'b1))   // Generation of write address 
                   i_cfg_wr_addr_reg1 <= i_cfg_addr ; 
                if ((req_dly == 1'b1) && (inv_i_cfg_wr_rdn_reg == 1'b1)) // Generation od read address
                   i_cfg_rd_addr_reg1 <= i_cfg_addr ; 
             end
    end

    assign csr_cfg.awaddr = {CSR_ADDR_ID, i_cfg_tgt_id, {(28-CFG_ADDR_WIDTH){1'b0}}, i_cfg_wr_addr_reg1[27:5], 5'd0};
    assign csr_cfg.araddr = {CSR_ADDR_ID, i_cfg_tgt_id, {(28-CFG_ADDR_WIDTH){1'b0}}, i_cfg_rd_addr_reg1};

    // Generation of write strobe and write data that goes to the config register 
    always @(*)
       begin
          csr_cfg.wdata[255:0] = 'd0;
          csr_cfg.wstrb[31:0]  = 'd0;
          casez(i_cfg_wr_addr_reg1[4:0])
             5'h00:
                begin
                   csr_cfg.wdata[31:0] = i_cfg_wdata_reg;
                   csr_cfg.wstrb[3:0]  = 4'hf;
                end
             5'h04:
                begin
                   csr_cfg.wdata[63:32] = i_cfg_wdata_reg;
                   csr_cfg.wstrb[7:4]   = 4'hf;
                end
             5'h08:
                begin
                   csr_cfg.wdata[95:64] = i_cfg_wdata_reg;
                   csr_cfg.wstrb[11:8]  = 4'hf;
                end
             5'h0C:
                begin
                   csr_cfg.wdata[127:96] = i_cfg_wdata_reg;
                   csr_cfg.wstrb[15:12]  = 4'hf;
                end
             5'h10:
                begin
                   csr_cfg.wdata[159:128] = i_cfg_wdata_reg;
                   csr_cfg.wstrb[19:16]   = 4'hf;
                end
             5'h14:
                begin
                   csr_cfg.wdata[191:160] = i_cfg_wdata_reg;
                   csr_cfg.wstrb[23:20]   = 4'hf;
                end
             5'h18:
                begin
                   csr_cfg.wdata[223:192] = i_cfg_wdata_reg;
                   csr_cfg.wstrb[27:24]   = 4'hf;
                end
             5'h1C:
                begin
                   csr_cfg.wdata[255:224] = i_cfg_wdata_reg;
                   csr_cfg.wstrb[31:28]   = 4'hf;
                end
          endcase
    end


    // Default values
    assign csr_cfg.arqos    = 0;        // Base QoR
    assign csr_cfg.arlock   = 1'b0;     // No lock
    assign csr_cfg.arburst  = 2'b01;    // Incrementing burst
    assign csr_cfg.arregion = 3'b000;   // Base region
    assign csr_cfg.arprot   = 3'b010;   // Unprivileged, Non-secure, data access
    assign csr_cfg.arcache  = 4'h0;     // Non-bufferable, (i.e. standard memory access)
    assign csr_cfg.arsize   = 3'h2;     // Transaction size fixed at 4 bytes
    assign csr_cfg.arlen    = 8'h0;     // Single beat transactions

    assign csr_cfg.awqos    = 0;        // Base QoR
    assign csr_cfg.awlock   = 1'b0;     // No lock
    assign csr_cfg.awburst  = 2'b01;    // Incrementing burst
    assign csr_cfg.awregion = 3'b000;   // Base region
    assign csr_cfg.awprot   = 3'b010;   // Unprivileged, Non-secure, data access
    assign csr_cfg.awcache  = 4'h0;     // Non-bufferable, (i.e. standard memory access)
    assign csr_cfg.awsize   = 3'h5;     // Data width fixed at 32 bytes
    assign csr_cfg.awlen    = 8'h0;     // Single beat transactions
    assign csr_cfg.wlast    = 1'b1;     // Always a single beat transactions


    always @(posedge i_cfg_clk)
    begin
        o_cfg_ack <= 1'b0;
        if (~i_cfg_reset_n)
        begin
            cfg_state       <= CFG_IDLE;
            csr_cfg.awvalid <= 1'b0;
            csr_cfg.wvalid  <= 1'b0;
            csr_cfg.bready  <= 1'b0;
            csr_cfg.arvalid <= 1'b0;
            csr_cfg.rready  <= 1'b0;
            csr_cfg.arid    <= 0;
            csr_cfg.awid    <= 0;
            // Initialize during reset //
            i_cfg_rd_addr_reg1_lsb_5bit <= 5'd0;
        end
        else
        begin
            case (cfg_state)
                CFG_IDLE :
                    begin
                        if ( i_cfg_req )
                        begin
                            if ( i_cfg_wr_rdn )
                            begin
                                cfg_state       <= CFG_WRITE;
                                csr_cfg.awvalid <= 1'b1;
                                csr_cfg.wvalid  <= 1'b1;
                                csr_cfg.bready  <= 1'b1;
                            end
                            else
                            begin
                                cfg_state       <= CFG_READ;
                                csr_cfg.arvalid <= 1'b1;
                                csr_cfg.rready  <= 1'b1;
                                i_cfg_rd_addr_reg1_lsb_5bit <= i_cfg_rd_addr_reg1[4:0] ;
                            end
                        end
                        else
                            cfg_state <= CFG_IDLE;
                    end

                CFG_WRITE :
                    begin
                        // Deassert each valid signal when equivalent ready is registered
                        if( csr_cfg.awready )
                            csr_cfg.awvalid <= 1'b0;
                        if( csr_cfg.wready )
                            csr_cfg.wvalid <= 1'b0;
                        if( csr_cfg.bvalid & (csr_cfg.bid == csr_cfg.awid) )
                        begin
                            o_cfg_ack <= 1'b1;
                            if ( i_cfg_req )
                                cfg_state  <= CFG_WAIT_REQ;
                            else
                                cfg_state  <= CFG_IDLE;
                            csr_cfg.awid <= csr_cfg.awid + 1;       // Value will wrap
                        end
                    end

                CFG_READ :
                    begin
                        // Deassert valid signal when equivalent ready is registered
                        if( csr_cfg.arready )
                            csr_cfg.arvalid <= 1'b0;
                        // When correct response is received issue ack
                        if( csr_cfg.rvalid & (csr_cfg.rid == csr_cfg.arid) )
                        begin
                            o_cfg_ack      <= 1'b1;
                            casez(i_cfg_rd_addr_reg1_lsb_5bit)
                               5'h00: o_cfg_rdata <= csr_cfg.rdata[31:0];
                               5'h04: o_cfg_rdata <= csr_cfg.rdata[63:32];
                               5'h08: o_cfg_rdata <= csr_cfg.rdata[95:64];
                               5'h0C: o_cfg_rdata <= csr_cfg.rdata[127:96];
                               5'h10: o_cfg_rdata <= csr_cfg.rdata[159:128];
                               5'h14: o_cfg_rdata <= csr_cfg.rdata[191:160];
                               5'h18: o_cfg_rdata <= csr_cfg.rdata[223:192];
                               5'h1C: o_cfg_rdata <= csr_cfg.rdata[255:224];
                            endcase

                            if ( i_cfg_req )
                                cfg_state  <= CFG_WAIT_REQ;
                            else
                                cfg_state  <= CFG_IDLE;
                            csr_cfg.arid   <= csr_cfg.arid + 1;     // Value will wrap
                            csr_cfg.rready <= 1'b0;                 // Deassert to prevent further transactions
                        end
                    end

                CFG_WAIT_REQ :
                    if ( ~i_cfg_req )
                        cfg_state <= CFG_IDLE;
            endcase
        end
    end

endmodule : axi_nap_csr_master_ddr

