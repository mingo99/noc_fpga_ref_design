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
// Register control block
//      Provides a set of default system registers at address 0xfff_0000
//      Provides a set of user registers from address 0x0
//      Provides optional pipelining of input and output registers
// ------------------------------------------------------------------

`include "nap_interfaces.svh"
`include "reg_control_defines.svh"
`include "version_defines.svh"

module reg_control_block
#(
    parameter   NUM_USER_REGS       = 2,        // Number of user registers
    parameter   IN_REGS_PIPE        = 0,        // Stages of pipeline for input registers
    parameter   OUT_REGS_PIPE       = 0         // Stages of pipeline for output registers
)
(
    // Inputs
    input  wire             i_clk,
    input  wire             i_reset_n,
    input  t_ACX_USER_REG   i_user_regs_in[NUM_USER_REGS -1:0],

    // Outputs
    output t_ACX_USER_REG   o_user_regs_out[NUM_USER_REGS -1:0]
);

    //------------------------------------------------------------
    // AXI master NAP and interface
    //------------------------------------------------------------
    logic       output_rstn_nap_master;
    logic       error_valid_nap_master;
    logic [2:0] error_info_nap_master;

    // AXI master interface
    t_AXI4 #(
            .DATA_WIDTH (`ACX_NAP_AXI_DATA_WIDTH),
            .ADDR_WIDTH (`ACX_NAP_AXI_MSTR_ADDR_WIDTH),
            .LEN_WIDTH  (8),
            .ID_WIDTH   (8))
    axi_master_if();

    // Set location in pdc file / testbench bind statement
    nap_master_wrapper #(
    ) i_axi_master (
        .i_clk              (i_clk),
        .i_reset_n          (i_reset_n),
        .nap                (axi_master_if),
        .o_output_rstn      (output_rstn_nap_master),
        .o_error_valid      (error_valid_nap_master),
        .o_error_info       (error_info_nap_master)
        );

    //------------------------------------------------------------
    // Input pipelining
    //------------------------------------------------------------
    t_ACX_USER_REG   user_regs_in_post_pipe [NUM_USER_REGS -1:0];

    generate if ( IN_REGS_PIPE != 0 ) begin : gb_in_pipe

        // Define pipeline registers as 2D array.  Actually 3D when you include the bits in the register
        t_ACX_USER_REG user_regs_in_d [NUM_USER_REGS -1:0][IN_REGS_PIPE -1:0];

        for ( genvar ur=0; ur < NUM_USER_REGS; ur++ ) begin : gb_in_per_ur

            // Connect first stage
            always @(posedge i_clk)
                user_regs_in_d[ur][0] <= i_user_regs_in[ur];

            // Additional pipeline if specified
            for ( genvar ii=1; ii < IN_REGS_PIPE; ii++ ) begin : gb_in_pipe_del
                always @(posedge i_clk)
                    user_regs_in_d[ur][ii] <= user_regs_in_d[ur][ii-1];
            end
        
            // Connect output of pipeline
            assign user_regs_in_post_pipe[ur] = user_regs_in_d[ur][IN_REGS_PIPE -1];
        end

    end
    else
    begin : gb_no_in_pipe
        assign user_regs_in_post_pipe = i_user_regs_in;
    end
    endgenerate

    //------------------------------------------------------------
    // AXI NAP register read and write sequence
    //------------------------------------------------------------
    // Simple sequence from nap master when written to via FCU
    // Get AW followed by W, usually on the next cycle
    // Do not (normally), get the two on the same cycle

    t_ACX_USER_REG_AXI_ADDR reg_addr;
    t_ACX_USER_REG          reg_wr_data;
    t_ACX_USER_REG          reg_rd_data;
    logic                   new_write;
    logic                   new_read;

    enum {AXI_IDLE, AXI_WRITE_RESP, AXI_WRITE_PENDING, AXI_GET_VALUE, AXI_READ} axi_state;

    always @(posedge i_clk)
    begin
        if ( ~i_reset_n )
        begin
            axi_state <= AXI_IDLE;
            axi_master_if.awready <= 1'b0;
            axi_master_if.wready  <= 1'b0;
            axi_master_if.arready <= 1'b0;
            axi_master_if.rvalid  <= 1'b0;
            axi_master_if.rlast   <= 1'b0;
            axi_master_if.bvalid  <= 1'b0;
        end
        else
        begin
            case (axi_state)
                AXI_IDLE : begin
                    new_write             <= 1'b0;
                    new_read              <= 1'b0;
                    axi_master_if.awready <= 1'b1;
                    axi_master_if.wready  <= 1'b1;
                    axi_master_if.arready <= 1'b1;
                    axi_master_if.rvalid  <= 1'b0;
                    axi_master_if.rlast   <= 1'b0;
                    axi_master_if.bvalid  <= 1'b0;
                    if ( axi_master_if.awvalid & axi_master_if.awready )
                    begin
                        axi_master_if.awready <= 1'b0;
                        axi_master_if.arready <= 1'b0;
                        reg_addr              <= axi_master_if.awaddr[27:0];
                        axi_master_if.bid     <= axi_master_if.awid;
                        if ( axi_master_if.wvalid & axi_master_if.wready )
                        begin
                            // Need to mux the 32-bits from the 256 bits based on the byte lane
                            case (axi_master_if.wstrb)
                                32'h0000_000f : reg_wr_data <= axi_master_if.wdata[(0*32) +: 32];
                                32'h0000_00f0 : reg_wr_data <= axi_master_if.wdata[(1*32) +: 32];
                                32'h0000_0f00 : reg_wr_data <= axi_master_if.wdata[(2*32) +: 32];
                                32'h0000_f000 : reg_wr_data <= axi_master_if.wdata[(3*32) +: 32];
                                32'h000f_0000 : reg_wr_data <= axi_master_if.wdata[(4*32) +: 32];
                                32'h00f0_0000 : reg_wr_data <= axi_master_if.wdata[(5*32) +: 32];
                                32'h0f00_0000 : reg_wr_data <= axi_master_if.wdata[(6*32) +: 32];
                                32'hf000_0000 : reg_wr_data <= axi_master_if.wdata[(7*32) +: 32];
                            endcase
                            new_write            <= 1'b1;
                            axi_master_if.wready <= 1'b0;
                            axi_state            <= AXI_WRITE_RESP;
                            axi_master_if.bvalid <= 1'b1;
                        end
                        else
                        begin
                            axi_state <= AXI_WRITE_PENDING;
                        end
                    end
                    else if ( axi_master_if.arvalid & axi_master_if.arready )
                    begin
                        reg_addr              <= axi_master_if.araddr[27:0];
                        axi_state             <= AXI_GET_VALUE;
                        new_read              <= 1'b1;
                        axi_master_if.awready <= 1'b0;
                        axi_master_if.arready <= 1'b0;
                        axi_master_if.wready  <= 1'b0;
                        axi_master_if.rid     <= axi_master_if.arid;
                    end
                    else
                        axi_state <= AXI_IDLE;
                end
                AXI_WRITE_RESP : begin
                    if ( axi_master_if.bready )
                    begin
                        axi_master_if.bvalid <= 1'b0;
                        axi_state            <= AXI_IDLE;
                    end
                end
                AXI_WRITE_PENDING : begin
                    if ( axi_master_if.wvalid & axi_master_if.wready )
                    begin
                        // Need to mux the 32-bits from the 256 bits based on the byte lane
                        case (axi_master_if.wstrb)
                            32'h0000_000f : reg_wr_data <= axi_master_if.wdata[(0*32) +: 32];
                            32'h0000_00f0 : reg_wr_data <= axi_master_if.wdata[(1*32) +: 32];
                            32'h0000_0f00 : reg_wr_data <= axi_master_if.wdata[(2*32) +: 32];
                            32'h0000_f000 : reg_wr_data <= axi_master_if.wdata[(3*32) +: 32];
                            32'h000f_0000 : reg_wr_data <= axi_master_if.wdata[(4*32) +: 32];
                            32'h00f0_0000 : reg_wr_data <= axi_master_if.wdata[(5*32) +: 32];
                            32'h0f00_0000 : reg_wr_data <= axi_master_if.wdata[(6*32) +: 32];
                            32'hf000_0000 : reg_wr_data <= axi_master_if.wdata[(7*32) +: 32];
                        endcase
                        axi_master_if.wready <= 1'b0;
                        new_write            <= 1'b1;
                        axi_state            <= AXI_WRITE_RESP;
                        axi_master_if.bvalid <= 1'b1;
                    end
                    else
                        axi_state <= AXI_WRITE_PENDING;
                end
                AXI_GET_VALUE : begin
                    // Single cycle state to get value from register array
                    axi_state            <= AXI_READ;
                    axi_master_if.rvalid <= 1'b1;
                    // All reads are a single word
                    axi_master_if.rlast  <= 1'b1;
                end
                AXI_READ : begin
                    if (axi_master_if.rready)
                    begin
                        axi_state            <= AXI_IDLE;
                        axi_master_if.rvalid <= 1'b0;
                    end
                end
                default : axi_state <= AXI_IDLE;
            endcase
        end
    end

    // Assign internal read register to AXI
    // Below is the "correct" way to do this.  If this becomes
    // timing problematic, then just repeat reg_rd_data across
    // all 8 lanes of rdata - the FCU will select the lane it requires
    always_comb
    begin
        axi_master_if.rdata = {256{1'b0}};
        case (reg_addr[4:2])
            3'b000 : axi_master_if.rdata[(32*0) +: 32] = reg_rd_data;
            3'b001 : axi_master_if.rdata[(32*1) +: 32] = reg_rd_data;
            3'b010 : axi_master_if.rdata[(32*2) +: 32] = reg_rd_data;
            3'b011 : axi_master_if.rdata[(32*3) +: 32] = reg_rd_data;
            3'b100 : axi_master_if.rdata[(32*4) +: 32] = reg_rd_data;
            3'b101 : axi_master_if.rdata[(32*5) +: 32] = reg_rd_data;
            3'b110 : axi_master_if.rdata[(32*6) +: 32] = reg_rd_data;
            3'b111 : axi_master_if.rdata[(32*7) +: 32] = reg_rd_data;
        endcase
    end

    //------------------------------------------------------------
    // System registers
    //------------------------------------------------------------
    // Read only
    // Hard coded to locations 0x0fff_0000 to 0x0fff_0010
    t_ACX_USER_REG  sys_reg_major_version = `ACX_MAJOR_VERSION;
    t_ACX_USER_REG  sys_reg_minor_version = `ACX_MINOR_VERSION;
    t_ACX_USER_REG  sys_reg_patch_version = `ACX_PATCH_VERSION;
    t_ACX_USER_REG  sys_reg_p4_version    = `REVISON_CONTROL_VERSION;    // Auto-derived

    //------------------------------------------------------------
    // User registers
    //------------------------------------------------------------

    // Write decode bit per register
    logic [NUM_USER_REGS -1:0] write_addr_sel;

    generate begin : gb_decode
        int jj;
        always @(posedge i_clk)
        begin
            write_addr_sel      <= {NUM_USER_REGS{1'b0}};           // No address decoded
            axi_master_if.bresp <= 2'b10;                           // Slave error
            axi_master_if.rresp <= 2'b10;                           // Slave error
            reg_rd_data         <= '0;
            for ( jj=0; jj < (NUM_USER_REGS+4); jj++ )
                if ( jj < NUM_USER_REGS )
                begin
                    if ( reg_addr == (jj*4) )
                    begin
                        axi_master_if.bresp <= 2'b00;               // Good write decode
                        axi_master_if.rresp <= 2'b00;               // Good read decode
                        write_addr_sel[jj]  <= (axi_state == AXI_WRITE_RESP);   
                                                                    // Valid address decoded
                                                                    // Only write on a single cycle
                        reg_rd_data <= user_regs_in_post_pipe[jj];  // Read data
                    end
                end
                else
                begin
                    if ( reg_addr == (((jj-NUM_USER_REGS)*4) + 32'h0fff_0000) )     // System register offset
                    begin
                        axi_master_if.rresp <= 2'b00;               // Good read decode
                        case ( jj )
                            NUM_USER_REGS   : reg_rd_data <= sys_reg_major_version;
                            NUM_USER_REGS+1 : reg_rd_data <= sys_reg_minor_version;
                            NUM_USER_REGS+2 : reg_rd_data <= sys_reg_patch_version;
                            NUM_USER_REGS+3 : reg_rd_data <= sys_reg_p4_version;
                        endcase
                    end
                end
        end
    end
    endgenerate

    t_ACX_USER_REG   user_regs_out_pre_pipe [NUM_USER_REGS -1:0];

    generate for (genvar ii=0; ii < NUM_USER_REGS; ii++ ) begin : gb_user_regs

        // Write to user register
        always @(posedge i_clk)
            if ( write_addr_sel[ii] && new_write )
            begin
                user_regs_out_pre_pipe[ii] <= reg_wr_data;
            end

        // Purely to give visibility in simulation
        // synthesis synthesis_off
        t_ACX_USER_REG   sim_monitor_reg_out;
        t_ACX_USER_REG   sim_monitor_reg_in;

        assign sim_monitor_reg_out = o_user_regs_out[ii];
        assign sim_monitor_reg_in  = i_user_regs_in[ii];
        // synthesis synthesis_on

    end
    endgenerate

    //------------------------------------------------------------
    // Output pipelining
    //------------------------------------------------------------

    generate if ( OUT_REGS_PIPE != 0 ) begin : gb_out_pipe

        // Define output pipeline registers as 2D array
        t_ACX_USER_REG user_regs_out_d [NUM_USER_REGS -1:0][OUT_REGS_PIPE -1:0];

        for ( genvar uro=0; uro < NUM_USER_REGS; uro++ ) begin : gb_out_per_ur

            // Connect first stage
            always @(posedge i_clk)
                user_regs_out_d[uro][0] <= user_regs_out_pre_pipe[uro];

            for ( genvar jj=1; jj < OUT_REGS_PIPE; jj++ ) begin : gb_out_pipe_del
                // Pipeline other stages if specified
                always @(posedge i_clk)
                    user_regs_out_d[uro][jj] <= user_regs_out_d[uro][jj-1];
            end
            
            // Connect output of pipeline
            assign o_user_regs_out[uro] = user_regs_out_d[uro][OUT_REGS_PIPE -1];
        end
    end
    else
    begin : gb_no_out_pipe
        assign o_user_regs_out = user_regs_out_pre_pipe;
    end
    endgenerate

endmodule : reg_control_block

