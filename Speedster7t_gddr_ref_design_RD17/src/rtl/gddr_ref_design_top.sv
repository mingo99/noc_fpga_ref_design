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
// Speedster7t GDDR6 reference design (RD17)
//      Top level
//      Demonstrates reading and writing to GDDR6 device
//      Supports behavioural model of NAP and fullchip BFM simulations
// ------------------------------------------------------------------

`include "7t_interfaces.svh"
`include "gddr_dci_port_names.svh"

module gddr_ref_design_top
#(
    parameter   GDDR6_NOC_CONFIG            = 8'b11111111,                // Number of GDDR6 interfaces accessed by NoC
    parameter   GDDR6_DCI_CONFIG            = 4'b1111,                // Number of GDDR6 interfaces acccessed by DCI

    // Control number of transactions written and read
    parameter   NUM_TRANSACTIONS        = 256               // Default value.  Can be upto 8K.
                                                            // If set to 0, then run continuously
)
(
   
     // Inputs
    input  wire                         i_clk,
    input  wire                         i_reset_n,          // Negative synchronous reset
    input  wire                         i_start,            // Assert to start test

    //PLL signals
    input wire                          pll_lock,           // Input clock PLL lock signal
    input wire                          pll_gddr_NE_lock,      // GDDR6 clocks PLL lock signal
    input wire                          pll_gddr_NW_lock,      // GDDR6 clocks PLL lock signal

    // Direct connection AXI interface
    // Signals named to reflect ACE generated <prefix>_* signal names
    `ACX_GDDR_DCI_INPUT(gddr6_1_dc0),
    `ACX_GDDR_DCI_INPUT(gddr6_2_dc0),
    `ACX_GDDR_DCI_INPUT(gddr6_5_dc0),
    `ACX_GDDR_DCI_INPUT(gddr6_6_dc0),
    `ACX_GDDR_DCI_OUTPUT(gddr6_1_dc0),
    `ACX_GDDR_DCI_OUTPUT(gddr6_2_dc0),
    `ACX_GDDR_DCI_OUTPUT(gddr6_5_dc0),
    `ACX_GDDR_DCI_OUTPUT(gddr6_6_dc0),
    
    // Outputs
    output logic                        o_fail /*synthesis syn_preserve=1,no_rewire=1*/,             // Will be asserted if read errors
    output logic                        o_fail_oe,         // Output enable for o_fail pin
    output logic                        o_xact_done /*synthesis syn_preserve=1,no_rewire=1*/,        // Assert when the number of transactions is complete
    output logic                        o_xact_done_oe     // Output enable for o_xact_done pin
);

    // GDDR6 target address ID.  Pages are defined in NoC User Guide, Address Mapping
    // Defined as 9 bit field.  9th bit(LSB) controls channel selection. All NoC interfaces are set to channel 1
    // Note that GDDR6 on the east side use even addresses for channel 1, whereas the west side uses odd addresses.
    localparam [71:0] GDDR6_ID_NOC  = {9'd10, 9'd2, 9'd6, 9'd14, 9'd9, 9'd1, 9'd5, 9'd13};

    // ------------------------
    // Status outputs
    // ------------------------
    logic [7:0]  nap_fail;
    logic [3:0]  dci_fail;
    logic [7:0]  nap_done;
    logic [3:0]  dci_done;

    // Tie output enables to high
    assign o_fail_oe        = 1'b1;
    assign o_xact_done_oe   = 1'b1;

    // GDDR6 memory width
    // 8Gb = 1GB device is 30 bits
    // Two controller, selected by the ID = 1 bit. 2 bytes wide = 1 bit
    // Bottom 4 bits, (x16 device), ignored as a burst is 32 bytes = AXI data width.
    // 24 bits remain
    localparam GDDR_ADDR_WIDTH   = 24;
    localparam GDDR_PAD_WIDTH    = 4;     // 42-9-24-5

    localparam MAX_FIFO_WIDTH    = 72;     // Fixed port widths of 72
    localparam FIFO_WIDTH        = 72;     // Address width are 42 or 33, + 8 for len.  So 72 required
   
    // ----------------------------------------------
    // Access CSR space via NAP using this module
    // Poll registers in GDDR6 controller to determine
    // if initial configuration has competed
    // ----------------------------------------------
    localparam POLL_REG_ADDR0        = 28'h000403c;
    localparam POLL_REG_ADDR1        = 28'h100403c;
    localparam EXPECTED_VAL0        = 32'h00000001;
    localparam EXPECTED_VAL1        = 32'h00000001;
    localparam NUM_OF_GDDR6        = 8;

    logic  cfg_wr_rdn;
    logic [3:0] poll_ptr;
    logic [27:0] cfg_addr;
    logic  cfg_req;
    logic [255:0] cfg_rdata;
    logic  cfg_ack;
    logic  gddr_ready /*synthesis syn_preserve=1,no_rewire=1*/;

    enum  {POLL_IDLE, POLL_0, LAUNCH_POLL_1, POLL_1} poll_state;

    // Reset Processor to create a common synchronized reset for all i_clk domain logic
    logic  rstn;
    reset_processor #(
        .NUM_INPUT_RESETS   (4),    // Three reset sources
        .NUM_OUTPUT_RESETS  (1),    // One clock domain and reset
        .RST_PIPE_LENGTH    (5)     // Set reset pipeline to 5 stages
    ) i_reset_processor (
        .i_rstn_array       ({i_reset_n, pll_lock, pll_gddr_NE_lock, pll_gddr_NW_lock}),
        .i_clk              (i_clk),
        .o_rstn_array       (rstn)
    );  


    axi_nap_csr_master #(
        .CFG_ADDR_WIDTH  (28),
        .CFG_DATA_WIDTH    (256)
    ) i_axi_nap_csr_master (
        .i_cfg_clk(i_clk),          // Config clock
        .i_cfg_reset_n(rstn),      // Config negative synchronous reset
        .i_cfg_tgt_id({poll_ptr[3:2], 2'b00, poll_ptr[1:0]}),         // Target ID is 6 bits
        .i_cfg_wr_rdn(cfg_wr_rdn),       // Write not read
        .i_cfg_addr(cfg_addr),         // Individual IP address space is 28 bits
        .i_cfg_wdata(256'h0),        // Write config data
        .i_cfg_req(cfg_req),          // Config request

    // Outputs
        .o_cfg_rdata(cfg_rdata),        // Read config data
        .o_cfg_ack(cfg_ack)           // Config acknowledge

    );  

    always @(posedge i_clk or negedge rstn)
    begin
        if (~rstn)
        begin
            poll_state  <= POLL_IDLE;
            cfg_wr_rdn <= 1'b0;
            poll_ptr  <= 0;
            cfg_addr  <= 0;
            cfg_req  <= 1'b0;
            gddr_ready  <= 1'b0;
            o_fail  <= 1'b0;
            o_xact_done  <= 1'b0;
        end
        else
        begin
            // Register the status output before sending to IO pad for easier timing
            // No need to synchronize signals from DCI clock domain because they are
            // from flops and only go from 0 to 1 once
            o_fail            <= (|nap_fail) | (|dci_fail);
            o_xact_done       <= (&nap_done) & (&dci_done);
            //
        `ifdef ACX_SIM_STANDALONE_MODE
            gddr_ready  <= 1'b1; //No need to poll GDDR registers for readiness in STANDALONE mode
        `else
            case (poll_state)
                POLL_IDLE :
                    begin
                      if (~gddr_ready) begin
                        if (poll_ptr < NUM_OF_GDDR6) begin
                          if (GDDR6_NOC_CONFIG[poll_ptr] |
                              (GDDR6_DCI_CONFIG[0] & (poll_ptr == 1)) |
                              (GDDR6_DCI_CONFIG[1] & (poll_ptr == 2)) |
                              (GDDR6_DCI_CONFIG[2] & (poll_ptr == 5)) |
                              (GDDR6_DCI_CONFIG[3] & (poll_ptr == 6))) begin
                            cfg_wr_rdn <= 1'b0;
                            cfg_addr  <= POLL_REG_ADDR0;
                            cfg_req  <= 1'b1;
                            poll_state <= POLL_0;
                          end
                          else begin
                            poll_ptr <= poll_ptr + 1;
                          end
                        end
                        else
                          gddr_ready <= 1'b1;
                      end
                    end

                POLL_0 :
                    begin
                      if (cfg_ack) begin
                        cfg_req <= 1'b0;
                        if (cfg_rdata[255:224] == EXPECTED_VAL0)
                          poll_state <= LAUNCH_POLL_1;
                        else
                          poll_state <= POLL_IDLE;
                      end
                    end

                LAUNCH_POLL_1 :
                    begin
                      cfg_wr_rdn <= 1'b0;
                      cfg_addr  <= POLL_REG_ADDR1;
                      cfg_req  <= 1'b1;
                      poll_state <= POLL_1;
                    end

                POLL_1 :
                    begin
                      if (cfg_ack) begin
                        cfg_req <= 1'b0;
                        if (cfg_rdata[255:224] == EXPECTED_VAL1) begin
                          poll_ptr <= poll_ptr + 1;
                          poll_state <= POLL_IDLE;
                        end
                        else
                          poll_state <= LAUNCH_POLL_1;
                      end
                    end

            endcase
        `endif
        end
    end
    // ----------------------------------------------
    // ----------------------------------------------

    // ------------------------
    // NAP interface
    // ------------------------

    // Instantiate the desired number of GDDRs with NoC interfaces
    genvar  i;
    generate    
        for (i=0;i<8;i=i+1) begin : gddr_gen_noc

        // Local parameters to define interface sizes
        localparam NAP_DATA_WIDTH = `ACX_NAP_AXI_DATA_WIDTH;
        localparam NAP_ADDR_WIDTH = `ACX_NAP_AXI_SLAVE_ADDR_WIDTH;
            
          if (GDDR6_NOC_CONFIG[i]) begin : noc_on
            // Generate a dedicated Reset Processorafor each NAP
            logic  nap_rstn;
            reset_processor #(
            .NUM_INPUT_RESETS   (4),    // Three reset sources
            .NUM_OUTPUT_RESETS  (1),    // One clock domain and reset
            .RST_PIPE_LENGTH    (5)     // Set reset pipeline to 5 stages
            ) i_reset_processor (
                .i_rstn_array       ({i_reset_n, pll_lock, pll_gddr_NE_lock, pll_gddr_NW_lock}),
                .i_clk              (i_clk),
                .o_rstn_array       (nap_rstn)
            );  

            // Instantiate AXI_4 interfaces for the nap
            t_AXI4 #(
                .DATA_WIDTH (NAP_DATA_WIDTH),
                .ADDR_WIDTH (NAP_ADDR_WIDTH),
                .LEN_WIDTH  (8),
                .ID_WIDTH   (8) )
            nap();
    
            // Non AXI signals from AXI NAP
            logic                         output_rstn_nap;
            logic                         error_valid_nap;
            logic [2:0]                   error_info_nap;
    
            nap_slave_wrapper i_axi_slave_wrapper (
                .i_clk                  (i_clk),
                .i_reset_n              (nap_rstn),
                .nap                    (nap),
                .o_output_rstn          (output_rstn_nap),
                .o_error_valid          (error_valid_nap),
                .o_error_info           (error_info_nap)
            );
    
            // Test control
            logic [12:0]                test_gen_count;    // Support up to 8K transactions
            logic [12:0]                test_rx_count;
            logic                       started /*synthesis syn_preserve=1,no_rewire=1*/;
            logic                       gddr_ready_nap /*synthesis syn_preserve=1,no_rewire=1*/;
            logic                       axi_wr_enable;
    
            // Values passed from writing block
            logic [GDDR_ADDR_WIDTH-1:0] wr_addr;
            logic [GDDR_ADDR_WIDTH-1:0] rd_addr;
            logic [7:0]                 wr_len;
            logic [7:0]                 rd_len;
            logic                       written_valid;
            logic                       pkt_compared;
            logic                       continuous_test;
    
            // Values to pass through FIFO
            logic [MAX_FIFO_WIDTH -1:0] fifo_data_in;
            logic [MAX_FIFO_WIDTH -1:0] fifo_data_out;
    
            // Assign values to and from FIFO
            // Structures would be ideal here, except cannot be used as ports to FIFO
            // Do in the one block so that they can be checked for consistency
            assign fifo_data_in     = {{(MAX_FIFO_WIDTH-$bits(wr_len)-$bits(wr_addr)){1'b0}}, wr_len, wr_addr};
            assign rd_addr          = fifo_data_out[$bits(rd_addr)-1:0];
            assign rd_len           = fifo_data_out[$bits(rd_addr)+$bits(rd_len)-1:$bits(rd_addr)];
    
            // FIFO control
            logic                         fifo_rden;
            logic                         fifo_empty;
            logic                         fifo_full;
    
            // Hold off writing transactions if transfer FIFO fills up        
            assign axi_wr_enable    = (test_gen_count != 13'h0) && ~fifo_full;
            assign continuous_test  = (NUM_TRANSACTIONS == 0);
    
            // Decrement the generate counter each time we write a transaction
            always @(posedge i_clk or negedge nap_rstn)
            begin
                if( ~nap_rstn ) begin
                    test_gen_count <= 13'h0;
                    started <= 1'b0;
                    gddr_ready_nap <= 1'b0;
                end
                else begin
                  gddr_ready_nap <= gddr_ready;
                  if ( i_start & ~started & gddr_ready_nap) begin
                    test_gen_count <= NUM_TRANSACTIONS;
                    started <= 1'b1;
                  end
                  else if (written_valid && ~continuous_test)
                    test_gen_count <= test_gen_count - 13'h1;
                end
            end
    
            // Increment the receive counter each time a transaction is compared
            always @(posedge i_clk or negedge nap_rstn)
            begin
                if( ~nap_rstn )
                    test_rx_count <= 13'h0;
                else if (pkt_compared)
                    test_rx_count <= test_rx_count + 13'h1;
            end
    
            // Generate done signal
            always @(posedge i_clk or negedge nap_rstn)
            begin
                if( ~nap_rstn )
                    nap_done[i] <= 1'b0;
                else
                    nap_done[i] <= (test_rx_count == NUM_TRANSACTIONS) && ~continuous_test;
            end
    
            // Instantiate AXI transaction generator
            axi_pkt_gen #(
                .LINEAR_PKTS                    (0),
                .LINEAR_ADDR                    (1),
                .TGT_ADDR_WIDTH                 (GDDR_ADDR_WIDTH),
                .TGT_ADDR_PAD_WIDTH             (GDDR_PAD_WIDTH),
                .TGT_ADDR_ID                    (GDDR6_ID_NOC[i*9+:9]),  // All NoC accesses to channel 1 of device
                .TGT_DATA_WIDTH                 (NAP_DATA_WIDTH),
                .MAX_BURST_LEN                  (15),   // 8Gb device supports burst of up to 64 beats x 32 bytes = 2kB
                .AXI_ADDR_WIDTH                 (NAP_ADDR_WIDTH)
            ) i_axi_pkt_gen_nap (
                // Inputs
                .i_clk                          (i_clk),
                .i_reset_n                      (nap_rstn),
                .i_start                        (started),
                .i_enable                       (axi_wr_enable),
                // Interfaces
                .axi_if                         (nap),
                // Outputs
                .o_addr_written                 (wr_addr),
                .o_len_written                  (wr_len),
                .o_written_valid                (written_valid)
            );
    
            // FIFO the address and length written, and then read out into the checker
            ACX_LRAM2K_FIFO #(
                .aempty_threshold               (6'h4),
                .afull_threshold                (6'h4),
                .fwft_mode                      (1'b0),     
                .outreg_enable                  (1'b1),
                .rdclk_polarity                 ("rise"),
                .read_width                     (FIFO_WIDTH),
                .sync_mode                      (1'b1),
                .wrclk_polarity                 ("rise"),
                .write_width                    (FIFO_WIDTH)
            ) i_xact_fifo_nap ( 
                .din                            (fifo_data_in),
                .rstn                           (nap_rstn),
                .wrclk                          (i_clk),
                .rdclk                          (i_clk),
                .wren                           (written_valid),
                .rden                           (fifo_rden),
                .outreg_rstn                    (nap_rstn),
                .outreg_ce                      (1'b1),
                .dout                           (fifo_data_out),
                .almost_full                    (),
                .full                           (fifo_full),
                .almost_empty                   (),
                .empty                          (fifo_empty),
                .write_error                    (),
                .read_error                     ()
            );
    
            // Instantiate AXI transaction checker
            // Must have the same configuration as the generator
            axi_pkt_chk #(
                .LINEAR_PKTS                    (0),
                .TGT_ADDR_WIDTH                 (GDDR_ADDR_WIDTH),
                .TGT_ADDR_PAD_WIDTH             (GDDR_PAD_WIDTH),
                .TGT_ADDR_ID                    (GDDR6_ID_NOC[i*9+:9]),
                .TGT_DATA_WIDTH                 (NAP_DATA_WIDTH),
                .AXI_ADDR_WIDTH                 (NAP_ADDR_WIDTH)
            ) i_axi_pkt_chk_nap (
                // Inputs
                .i_clk                           (i_clk),
                .i_reset_n                       (nap_rstn),
                .i_xact_avail                    (~fifo_empty),
                .i_xact_addr                     (rd_addr),
                .i_xact_len                      (rd_len),
    
                // Interfaces
                .axi_if                          (nap),
                // Outputs
                .o_xact_read                     (fifo_rden),
                .o_pkt_compared                  (pkt_compared),
                .o_pkt_error                     (nap_fail[i])
            );
          end
          else begin
            assign nap_fail[i] = 1'b0;
            assign nap_done[i] = 1'b1;
          end
        end
    endgenerate
    

    // ------------------------
    // Direct connect interface
    // ------------------------
    logic [3:0] dci_clk;
    logic [3:0] dci_input_rstn;
    
    assign dci_clk[0] = gddr6_1_dc0_clk;
    assign dci_clk[1] = gddr6_2_dc0_clk;
    assign dci_clk[2] = gddr6_5_dc0_clk;
    assign dci_clk[3] = gddr6_6_dc0_clk;
    assign dci_input_rstn[0] = gddr6_1_dc0_aresetn;
    assign dci_input_rstn[1] = gddr6_2_dc0_aresetn;
    assign dci_input_rstn[2] = gddr6_5_dc0_aresetn;
    assign dci_input_rstn[3] = gddr6_6_dc0_aresetn;

    // Generate an axi generator/checker per DCI 
    genvar j;
    generate    
        for (j=0;j<4;j=j+1) begin : gddr_gen_dci
            
        // Local parameters to define interface sizes
        localparam DCI_DATA_WIDTH  = `ACX_GDDR_DCI_AXI_DATA_WIDTH;
        localparam DCI_ADDR_WIDTH  = `ACX_GDDR_DCI_AXI_ADDR_WIDTH;
        
          if (GDDR6_DCI_CONFIG[j]) begin : dci_on
            // Instantiate AXI_4 interfaces for the direct connect interface
            // Note the ID width is only 7 bits with this interface
            t_AXI4 #(
                .DATA_WIDTH (DCI_DATA_WIDTH),
                .ADDR_WIDTH (DCI_ADDR_WIDTH-1),     // Top bit fixed to 1'b0 to select lower channel
                .LEN_WIDTH  (8),
                .ID_WIDTH   (7) )
            dci();
    
            // Reset Processor that supplies internal reset to each GDDR6 DCI interface.
            // Do not combine with NoC reset processor, as each DCI has it's own reset
            // input.  If this reset is asserted, then it would also reset all the NoC
            // interface traffic.
            logic dci_output_rstn;
    
            reset_processor #(
                .NUM_INPUT_RESETS       (5),    // Four reset sources
                .NUM_OUTPUT_RESETS      (1),    // Clock domain per DCI
                .RST_PIPE_LENGTH        (5)     // Set reset pipeline to 5 stages
            ) i_reset_processor (
                .i_rstn_array           ({dci_input_rstn[j],i_reset_n, pll_lock, pll_gddr_NE_lock, pll_gddr_NW_lock}),
                .i_clk                  (dci_clk[j]),
                .o_rstn_array           (dci_output_rstn)
            );         
            
    
            // Test control
            logic [12:0]                test_gen_count_dci;    // Support up to 8K transactions
            logic [12:0]                test_rx_count_dci;
            logic                       axi_wr_enable_dci;
    
            // Values passed from writing block
            logic [DCI_ADDR_WIDTH-1:0]  wr_addr_dci;
            logic [DCI_ADDR_WIDTH-1:0]  rd_addr_dci;
            logic [7:0]                 wr_len_dci;
            logic [7:0]                 rd_len_dci;
            logic                       written_valid_dci;
            logic                       pkt_compared_dci;
            logic                       continuous_test_dci;
    
            // Values to pass through FIFO
            logic [MAX_FIFO_WIDTH-1:0] fifo_data_in_dci;
            logic [MAX_FIFO_WIDTH-1:0] fifo_data_out_dci;
    
            // Assign values to and from FIFO
            // Structures would be ideal here, except cannot be used as ports to FIFO
            // Do in the one block so that they can be checked for consistency
            assign fifo_data_in_dci = {{(MAX_FIFO_WIDTH-$bits(wr_len_dci)-$bits(wr_addr_dci)){1'b0}}, wr_len_dci, wr_addr_dci};
            assign rd_addr_dci      = fifo_data_out_dci[$bits(rd_addr_dci)-1:0];
            assign rd_len_dci       = fifo_data_out_dci[$bits(rd_addr_dci)+$bits(rd_len_dci)-1:$bits(rd_addr_dci)];
    
           // FIFO control
            logic                       fifo_rden_dci  ;
            logic                       fifo_empty_dci  ;
            logic                       fifo_full_dci   ;
            logic                       started_dci /*synthesis syn_preserve=1,no_rewire=1*/;
    
            // Hold off writing transactions if transfer FIFO fills up        
            assign axi_wr_enable_dci   = (test_gen_count_dci != 13'h0) && ~fifo_full_dci;
            assign continuous_test_dci = (NUM_TRANSACTIONS == 0);
    
            // Synchronise the signals from i_clk domain across to the dci clock domain
            logic   start_dci_0 /*synthesis syn_preserve=1,no_rewire=1*/; 
            logic   start_dci_1 /*synthesis syn_preserve=1,no_rewire=1*/;
            logic   gddr_ready_0 /*synthesis syn_preserve=1,no_rewire=1*/;
            logic   gddr_ready_1 /*synthesis syn_preserve=1,no_rewire=1*/;
    
            always @(posedge dci_clk[j] or negedge dci_output_rstn)
            begin
                if( ~dci_output_rstn ) begin
                    start_dci_0    <= 1'b0;
                    start_dci_1    <= 1'b0;
                    gddr_ready_0   <= 1'b0;
                    gddr_ready_1   <= 1'b0;
        `ifdef ACX_SIM_STANDALONE_MODE
            // In standalone simulation mode, the DCI interface is not tested
            // In order to get a done output, assert dci_done
                    dci_done[j]   <= 1'b1;
        `else
            // Fullchip mode, DCI interface is tested
                    dci_done[j]   <= 1'b0;
        `endif
                end
                else begin
                    start_dci_0 <= i_start;
                    start_dci_1 <= start_dci_0;
                    gddr_ready_0 <= gddr_ready;
                    gddr_ready_1 <= gddr_ready_0;
        `ifndef ACX_SIM_STANDALONE_MODE
            // Fullchip mode, DCI interface is tested
                    dci_done[j] <= (test_rx_count_dci == NUM_TRANSACTIONS) && ~continuous_test_dci;
        `endif
                end
            end
    
            // Decrement the generate counter each time we write a transaction
            always @(posedge dci_clk[j] or negedge dci_output_rstn)
            begin
                if( ~dci_output_rstn ) begin
                    test_gen_count_dci <= 13'h0;
                    started_dci <= 1'b0;
                end
                else if ( start_dci_1 & ~started_dci & gddr_ready_1) begin
                    test_gen_count_dci <= NUM_TRANSACTIONS;
                    started_dci <= 1'b1;
                end
                else if (written_valid_dci && ~continuous_test_dci)
                    test_gen_count_dci <= test_gen_count_dci - 13'h1;
            end
    
            // Increment the receive counter each time a transaction is compared
            always @(posedge dci_clk[j] or negedge dci_output_rstn)
            begin
                if( ~dci_output_rstn )
                    test_rx_count_dci <= 13'h0;
                else if (pkt_compared_dci)
                    test_rx_count_dci <= test_rx_count_dci + 13'h1;
            end
    
            // Instantiate AXI transaction generator
            axi_pkt_gen #(
                .LINEAR_PKTS                   (0),
                .LINEAR_ADDR                   (1),
                .TGT_ADDR_WIDTH                (DCI_ADDR_WIDTH),    // No ID necessary for DCI access
                .TGT_ADDR_PAD_WIDTH            (0),
                .TGT_ADDR_ID                   (1'b0),
                .TGT_DATA_WIDTH                (DCI_DATA_WIDTH),
                .MAX_BURST_LEN                 (15),        // 8Gb device supports burst of up to 64 beats x 32 bytes = 2kB
                .AXI_ADDR_WIDTH                (DCI_ADDR_WIDTH-1)
            ) i_axi_pkt_gen_dci (
                // Inputs
                .i_clk                         (dci_clk[j]),
                .i_reset_n                     (dci_output_rstn),
                .i_start                       (started_dci),
                .i_enable                      (axi_wr_enable_dci),
                // Interfaces
                .axi_if                        (dci),
                // Outputs
                .o_addr_written                (wr_addr_dci),
                .o_len_written                 (wr_len_dci),
                .o_written_valid               (written_valid_dci)
            );
    
            // FIFO the address and length written, and then read out into the checker
            ACX_LRAM2K_FIFO #(
                .aempty_threshold              (6'h4),
                .afull_threshold               (6'h4),
                .fwft_mode                     (1'b0),
                .outreg_enable                 (1'b1),
                .rdclk_polarity                ("rise"),
                .read_width                    (FIFO_WIDTH),
                .sync_mode                     (1'b1),
                .wrclk_polarity                ("rise"),
                .write_width                   (FIFO_WIDTH)
            ) i_xact_fifo_dci ( 
                .din                           (fifo_data_in_dci),
                .rstn                          (dci_output_rstn),
                .wrclk                         (dci_clk[j]),
                .rdclk                         (dci_clk[j]),
                .wren                          (written_valid_dci),
                .rden                          (fifo_rden_dci),
                .outreg_rstn                   (dci_output_rstn),
                .outreg_ce                     (1'b1),
                .dout                          (fifo_data_out_dci),
                .almost_full                   (),
                .full                          (fifo_full_dci),
                .almost_empty                  (),
                .empty                         (fifo_empty_dci),
                .write_error                   (),
                .read_error                    ()
            );
    
            // Instantiate AXI transaction checker
            // Must have the same configuration as the generator
            axi_pkt_chk #(
                .LINEAR_PKTS                   (0),
                .TGT_ADDR_WIDTH                (DCI_ADDR_WIDTH),
                .TGT_ADDR_PAD_WIDTH            (0),
                .TGT_ADDR_ID                   (1'b0),      // All DCI accesses to channel 0 of device
                .TGT_DATA_WIDTH                (DCI_DATA_WIDTH),
                .AXI_ADDR_WIDTH                (DCI_ADDR_WIDTH-1)
            ) i_axi_pkt_chk_dci (
                // Inputs
                .i_clk                         (dci_clk[j]),
                .i_reset_n                     (dci_output_rstn),
                .i_xact_avail                  (~fifo_empty_dci),
                .i_xact_addr                   (rd_addr_dci),
                .i_xact_len                    (rd_len_dci),
    
                // Interfaces
                .axi_if                        (dci),
                // Outputs
                .o_xact_read                   (fifo_rden_dci),
                .o_pkt_compared                (pkt_compared_dci),
                .o_pkt_error                   (dci_fail[j])
            );
    
            // Assign the top level ports to the SV interface for GDDR6 DCI interfaces. 
            if (j == 0) begin `ACX_GDDR_DCI_ASSIGN(gddr6_1_dc0,gddr_gen_dci[0].dci_on) end
            else if (j == 1) begin `ACX_GDDR_DCI_ASSIGN(gddr6_2_dc0,gddr_gen_dci[1].dci_on) end
            else if (j == 2) begin `ACX_GDDR_DCI_ASSIGN(gddr6_5_dc0,gddr_gen_dci[2].dci_on) end
            else if (j == 3) begin `ACX_GDDR_DCI_ASSIGN(gddr6_6_dc0,gddr_gen_dci[3].dci_on) end
    
          end
          else begin
            assign dci_fail[j] = 1'b0;
            assign dci_done[j] = 1'b1;
          end
        end
    endgenerate

endmodule : gddr_ref_design_top
