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
// Speedster7t DDR reference design (RD18)
//      Top level
//      Demonstrates reading and writing to DDR4 device
//      Supports behavioural model of NAP and fullchip BFM simulations
// ------------------------------------------------------------------

`include "7t_interfaces.svh"

module ddr4_ref_design_top
#(
    parameter   DDR4_ADDR_ID            = 2'b01,            // DDR4 target address ID.  Page in NoC address mapping
                                                            // This is a 2 bit field, the remaining bits select the DDR4 address
    // Control number of transactions written and read
    parameter   NUM_TRANSACTIONS        = 256,              // Default value.  Can be upto 8K.
                                                            // If set to 0, then run continuously
    // Local parameters for Direct connection AXI  interface sizes
    localparam DCI_DATA_WIDTH           = (`ACX_NAP_AXI_DATA_WIDTH*2),  // Specific to DCI
    localparam DDR4_ADDR_WIDTH          = 40                // Maximum address width supported.  Common to both DCI and NAP
                                                            // Note : Not all devices will support this full width
)
(
    // Inputs
    input  wire                         i_clk,               // Clock for user logic set to 500Mhz
    input  wire                         i_reset_n,           // Negative synchronous reset
    input  wire                         i_start,             // Assert to start test
    input  wire                         i_training_clk,      // Clock for PHY and controller training through APB interface set to 250Mhz
    input  wire                         i_training_rstn,     // Training reset; if reset all calibration and training of the DDR4 subsystem will be reset


    // PLL signals
    input  wire                         pll_1_lock,         // Reference PLL lock signal
    input  wire                         pll_2_lock,         // System PLL lock signal

    // Direct connection AXI interface; 
    // Signals named to reflect ACE generated <prefix>_* signal names
    input  wire                         ddr4_1_clk,         // DCI specific clock
    input  wire [1:0]                   ddr4_1_clk_alt,     // Alternate DCI clocks. Same signal as the DCI clock but fanned out to connect to multiple branch
                                                            // clocks.User needs to connect this to the DCI clock in the user design logic.
    input  wire                         ddr4_1_rstn,        // DCI specific negative reset
    output wire                         ddr4_1_dc_awvalid,
    input  wire                         ddr4_1_dc_awready,
    output wire [DDR4_ADDR_WIDTH -1:0]  ddr4_1_dc_awaddr,
    output wire [8 -1:0]                ddr4_1_dc_awlen,
    output wire [8 -1:0]                ddr4_1_dc_awid,
    output wire [4 -1:0]                ddr4_1_dc_awqos,
    output wire [2 -1:0]                ddr4_1_dc_awburst,
    output wire                         ddr4_1_dc_awlock,
    output wire [3 -1:0]                ddr4_1_dc_awsize,
    output wire [4 -1:0]                ddr4_1_dc_awregion,
    output wire [4 -1:0]                ddr4_1_dc_awcache,
    output wire [3 -1:0]                ddr4_1_dc_awprot,
    output wire                         ddr4_1_dc_wvalid,
    input  wire                         ddr4_1_dc_wready,
    output wire [DCI_DATA_WIDTH -1:0]   ddr4_1_dc_wdata,
    output wire [(DCI_DATA_WIDTH/8)-1:0] ddr4_1_dc_wstrb,
    output wire                         ddr4_1_dc_wlast,
    input  wire                         ddr4_1_dc_arready,
    output wire                         ddr4_1_dc_arvalid,
    output wire [DDR4_ADDR_WIDTH -1:0]  ddr4_1_dc_araddr,
    output wire [8 -1:0]                ddr4_1_dc_arlen,
    output wire [8 -1:0]                ddr4_1_dc_arid,
    output wire [4 -1:0]                ddr4_1_dc_arqos,
    output wire [2 -1:0]                ddr4_1_dc_arburst,
    output wire                         ddr4_1_dc_arlock,
    output wire [3 -1:0]                ddr4_1_dc_arsize,
    output wire [4 -1:0]                ddr4_1_dc_arregion,
    output wire [4 -1:0]                ddr4_1_dc_arcache,
    output wire [3 -1:0]                ddr4_1_dc_arprot,
    output wire                         ddr4_1_dc_rready,
    input  wire                         ddr4_1_dc_rvalid,
    input  wire [DCI_DATA_WIDTH -1:0]   ddr4_1_dc_rdata,
    input  wire                         ddr4_1_dc_rlast,
    input  wire [2 -1:0]                ddr4_1_dc_rresp,
    input  wire [8 -1:0]                ddr4_1_dc_rid,
    input  wire                         ddr4_1_dc_bvalid,
    output wire                         ddr4_1_dc_bready,
    input  wire [2 -1:0]                ddr4_1_dc_bresp,
    input  wire [8 -1:0]                ddr4_1_dc_bid,
 
 // Unused DDR DCI ports
    // These must be included in the design even if unused so that they are correctly
    // connected to the DDR DCI interface.
    output wire                         ddr4_1_dc_arex_auto_precharge,
    output wire                         ddr4_1_dc_arex_parity,
    output wire                         ddr4_1_dc_arex_poison,
    output wire                         ddr4_1_dc_arex_urgent,
    input  wire [64 -1:0]               ddr4_1_dc_rex_parity,
    output wire                         ddr4_1_dc_awex_auto_precharge,
    output wire                         ddr4_1_dc_awex_parity,
    output wire                         ddr4_1_dc_awex_poison,
    output wire                         ddr4_1_dc_awex_urgent,
    output wire [64 -1:0]               ddr4_1_dc_wex_parity,
 
    // DCI Interrupts
    // (In future releases of ACE, these will be optional and hence will not
    //  be required to be instantiated in the design)
    input wire                          ddr4_1_dc_axi_arpoison_irq,
    input wire                          ddr4_1_dc_axi_awpoison_irq,
    input wire                          ddr4_1_dfi_alert_err_irq,
    input wire                          ddr4_1_ecc_corrected_err_irq,
    input wire                          ddr4_1_ecc_corrected_err_irq_fault,
    input wire                          ddr4_1_ecc_uncorrected_err_irq,
    input wire                          ddr4_1_ecc_uncorrected_err_irq_fault,
    input wire                          ddr4_1_noc_axi_arpoison_irq,
    input wire                          ddr4_1_noc_axi_awpoison_irq,    
    input wire                          ddr4_1_par_raddr_err_irq,
    input wire                          ddr4_1_par_raddr_err_irq_fault,
    input wire                          ddr4_1_par_rdata_err_irq,
    input wire                          ddr4_1_par_rdata_err_irq_fault,
    input wire                          ddr4_1_par_waddr_err_irq,
    input wire                          ddr4_1_par_waddr_err_irq_fault,
    input wire                          ddr4_1_par_wdata_err_irq,
    input wire                          ddr4_1_par_wdata_err_irq_fault,
    input wire                          ddr4_1_phy_irq_n,

    // Outputs
    output logic                        o_fail,             // Will be asserted if read errors
    output logic                        o_fail_oe,          // Output enable for o_fail pin; active high
    output logic                        o_xact_done,        // Assert when the number of transactions is complete
    output logic                        o_xact_done_oe,     // Output enable for o_xact_done pin; active high
    output logic                        o_training_done,    // Asserted when DDR PHY and controller training is complete
    output logic                        o_training_done_oe  // Output enable for o_training_done pin; active high
);


    // For DDR4, top 2 bits of the address define the DDR4 target ID
    localparam ADDR_ID_WIDTH = 2;

    // Check DDR4_ADDR_ID is correct size
    generate if ($bits(DDR4_ADDR_ID) != ADDR_ID_WIDTH) begin : gb_addr_id_error
        ERROR_ddr4_addr_id_wrong_size();
    end
    endgenerate

    // Status outputs
    logic   nap_fail;
    logic   dci_fail;
    logic   nap_done;
    logic   dci_done;

    // These combinatorial outputs are derived from different clock domains
    // For a production design they should be individually synchronised to the
    // selected output clock
    assign o_fail      = nap_fail | dci_fail;
    assign o_xact_done = nap_done & dci_done;
    // Tie output enables to high
    assign o_fail_oe          = 1'b1;
    assign o_xact_done_oe     = 1'b1;
    assign o_training_done_oe = 1'b1;

    // ------------------------
    // Unused DDR DCI ports
    // Drive all values to 0 as unused
    // ------------------------
    assign ddr4_1_dc_arex_auto_precharge = 1'b0;
    assign ddr4_1_dc_arex_parity         = 1'b0;
    assign ddr4_1_dc_arex_poison         = 1'b0;
    assign ddr4_1_dc_arex_urgent         = 1'b0;
    assign ddr4_1_dc_awex_auto_precharge = 1'b0;
    assign ddr4_1_dc_awex_parity         = 1'b0;
    assign ddr4_1_dc_awex_poison         = 1'b0;
    assign ddr4_1_dc_awex_urgent         = 1'b0;
    assign ddr4_1_dc_wex_parity          = 64'b0;


    // ------------------------
    // Create internal resets
    // Need to include PLL lock signals and external resets
    // ------------------------
    logic   dci_rstn;
    logic   nap_rstn;

    reset_processor #(
        .NUM_INPUT_RESETS   (4),    // Four reset sources
        .NUM_OUTPUT_RESETS  (2),    // Two clocks domains and hence two resets
        .RST_PIPE_LENGTH    (5)     // Set reset pipeline to 5 stages
    ) i_reset_processor (
        .i_rstn_array       ({ddr4_1_rstn, i_reset_n, pll_1_lock, pll_2_lock}),
        .i_clk              ({ddr4_1_clk, i_clk}),
        .o_rstn_array       ({dci_rstn, nap_rstn})
    );

    // ------------------------------
    // DDR4 Training block
    // ------------------------------
    // This is run after the bitstream is loaded
    // It performs read and write levelling
    // This only needs to be run once from power up, so it uses
    // it's own clock and reset to give the user individual control of the block


    // Synchronize reset to the training clock, and pipeline from edge of die
    // to where the training block is located
    logic       training_rstn_sync;
    logic [3:0] training_rstn_pipe;
    logic       train_done ;

    // Synchronize the reset
    ACX_SYNCHRONIZER x_sync_train_rstn (.din(1'b1), .dout(training_rstn_sync), .clk(i_training_clk), .rstn(i_training_rstn));

    // Pipeline the reset
    always @ (posedge i_training_clk)
        training_rstn_pipe <= {training_rstn_pipe[2:0], training_rstn_sync};

    // Instantiating the DDR4 training block //
    // Note : In simulation, when not using the DDR4 controller RTL, this block is held
    // in reset, and the train_done signal is forced to true.
    ddr4_training_polling_block i_ddr4_training_block (
        .i_clk          (i_training_clk),
        .i_resetn       (training_rstn_pipe[3]),
        .training_done  (train_done)
    );
    
    

    assign o_training_done = train_done ;

    // ------------------------
    // NAP interface
    // ------------------------

    // Local parameters to define interface sizes
    localparam NAP_DATA_WIDTH = `ACX_NAP_AXI_DATA_WIDTH;
    localparam NAP_ADDR_WIDTH = `ACX_NAP_AXI_SLAVE_ADDR_WIDTH;

    // Instantiate AXI_4 interfaces for nap
    t_AXI4 #(
        .DATA_WIDTH (NAP_DATA_WIDTH),
        .ADDR_WIDTH (NAP_ADDR_WIDTH),
        .LEN_WIDTH  (8),
        .ID_WIDTH   (8) )
    nap();
                               
    // Non AXI signals from AXI NAP
    logic                       output_rstn_nap;
    logic                       error_valid_nap;
    logic [2:0]                 error_info_nap;

    // Instantiate slave and connect ports to SV interface
    nap_slave_wrapper i_axi_slave_wrapper_in (
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
    logic                       start_d;
    logic                       axi_wr_enable;

    // Values passed from writing block
    logic [DDR4_ADDR_WIDTH-1:0] wr_addr;
    logic [DDR4_ADDR_WIDTH-1:0] rd_addr;
    logic [7:0]                 wr_len;
    logic [7:0]                 rd_len;
    logic                       written_valid;
    logic                       pkt_compared;
    logic                       continuous_test;

    localparam MAX_FIFO_WIDTH = 72;     // Fixed port widths of 72
    localparam FIFO_WIDTH     = 72;     // Either 36 or 72 allowed.  Set as parameter on FIFO

    // Values to pass through FIFO
    logic [MAX_FIFO_WIDTH -1:0] fifo_data_in;
    logic [MAX_FIFO_WIDTH -1:0] fifo_data_out;

    // Assign values to and from FIFO
    // Structures would be ideal here, except cannot be used as ports to FIFO
    // Do in the one block so that they can be checked for consistency
    assign fifo_data_in = {{(MAX_FIFO_WIDTH-$bits(wr_len)-$bits(wr_addr)){1'b0}}, wr_len, wr_addr};
    assign rd_addr      = fifo_data_out[$bits(rd_addr)-1:0];
    assign rd_len       = fifo_data_out[$bits(rd_addr)+$bits(rd_len)-1:$bits(rd_addr)];

    // Check the data fits into the current FIFO width
    generate if ( ($bits(wr_len) + $bits(wr_addr)) > FIFO_WIDTH ) ERROR_fifo_struct_to_wide(); endgenerate

    // FIFO control
    logic                       fifo_rden;
    logic                       fifo_empty;
    logic                       fifo_full;

    // Hold off writing packets if transfer FIFO fills up        
    assign axi_wr_enable = (test_gen_count != 13'h0) && ~fifo_full;
    assign continuous_test = (NUM_TRANSACTIONS == 0);

    // Decrement the generate counter each time we write a transaction
    always @(posedge i_clk or negedge nap_rstn)
    begin
        if( ~nap_rstn ) begin
            test_gen_count <= 13'h0;
            start_d        <= 1'b0 ;
        end else if ( (i_start & train_done) & ~start_d ) begin
            test_gen_count <= NUM_TRANSACTIONS;
            start_d        <= 1'b1 ;
        end else if (written_valid && ~continuous_test)
            test_gen_count <= test_gen_count - 13'h1;
    end

    // Increment the receive counter each time a packet is compared
    always @(posedge i_clk or negedge nap_rstn)
    begin
        if( ~nap_rstn )
            test_rx_count <= 13'h0;
        else if ( (i_start & train_done) & ~start_d )
            test_rx_count <= 0;
        else if (pkt_compared)
            test_rx_count <= test_rx_count + 13'h1;
    end

    assign nap_done = (test_rx_count == NUM_TRANSACTIONS) && ~continuous_test;

    // Instantiate AXI packet generator
    axi_pkt_gen #(
        .LINEAR_PKTS            (0),
        .LINEAR_ADDR            (1),
        .TGT_ADDR_WIDTH         (DDR4_ADDR_WIDTH),
        .TGT_ADDR_PAD_WIDTH     (0),
        .TGT_ADDR_ID            (DDR4_ADDR_ID),
        .TGT_DATA_WIDTH         (NAP_DATA_WIDTH),
        .MAX_BURST_LEN          (16),    // NoC support a maximum burst of 16 beats
        .AXI_ADDR_WIDTH         (NAP_ADDR_WIDTH)        
    ) i_axi_pkt_gen_nap (
        // Inputs
        .i_clk                  (i_clk),
        .i_reset_n              (nap_rstn),
        .i_start                (start_d),
        .i_enable               (axi_wr_enable),
        // Interfaces
        .axi_if                 (nap),
        // Outputs
        .o_addr_written         (wr_addr),
        .o_len_written          (wr_len),
        .o_written_valid        (written_valid)
    );

    // FIFO the address and length written, and then read out into the checker
    ACX_LRAM2K_FIFO #(
        .aempty_threshold       (6'h4),
        .afull_threshold        (6'h4),
        .fwft_mode              (1'b0),
        .outreg_enable          (1'b1),
        .rdclk_polarity         ("rise"),
        .read_width             (FIFO_WIDTH),
        .sync_mode              (1'b1),
        .wrclk_polarity         ("rise"),
        .write_width            (FIFO_WIDTH)
    ) i_xact_fifo_nap ( 
        .din                    (fifo_data_in),
        .rstn                   (nap_rstn),
        .wrclk                  (i_clk),
        .rdclk                  (i_clk),
        .wren                   (written_valid),
        .rden                   (fifo_rden),
        .outreg_rstn            (nap_rstn),
        .outreg_ce              (1'b1),
        .dout                   (fifo_data_out),
        .almost_full            (),
        .full                   (fifo_full),
        .almost_empty           (),
        .empty                  (fifo_empty),
        .write_error            (),
        .read_error             ()
    );

    // Instantiate AXI packet checker
    // Must have the same configuration as the generator
    axi_pkt_chk #(
        .LINEAR_PKTS            (0),
        .TGT_ADDR_WIDTH         (DDR4_ADDR_WIDTH),
        .TGT_ADDR_PAD_WIDTH     (0),
        .TGT_ADDR_ID            (DDR4_ADDR_ID),
        .TGT_DATA_WIDTH         (NAP_DATA_WIDTH),
        .AXI_ADDR_WIDTH         (NAP_ADDR_WIDTH)
    ) i_axi_pkt_chk_nap (
        // Inputs
        .i_clk                  (i_clk),
        .i_reset_n              (nap_rstn),
        .i_xact_avail           (~fifo_empty),
        .i_xact_addr            (rd_addr),
        .i_xact_len             (rd_len),

        // Interfaces
        .axi_if                 (nap),

        // Outputs
        .o_xact_read            (fifo_rden),
        .o_pkt_compared         (pkt_compared),
        .o_pkt_error            (nap_fail)
    );

    // ------------------------
    // Direct connect interface
    // ------------------------

    // Instantiate AXI_4 interfaces for direct connection
    t_AXI4 #(
        .DATA_WIDTH (DCI_DATA_WIDTH),
        .ADDR_WIDTH (DDR4_ADDR_WIDTH),
        .LEN_WIDTH  (8),
        .ID_WIDTH   (8) )
    dci();

    // Assign the top level ports to the SV interface
    assign ddr4_1_dc_awvalid  = dci.awvalid;
    assign ddr4_1_dc_awaddr   = dci.awaddr;
    assign ddr4_1_dc_awlen    = dci.awlen;
    assign ddr4_1_dc_awid     = dci.awid;
    assign ddr4_1_dc_awqos    = dci.awqos;
    assign ddr4_1_dc_awburst  = dci.awburst;
    assign ddr4_1_dc_awlock   = dci.awlock;
    //assign ddr4_1_dc_awsize   = dci.awsize;
    assign ddr4_1_dc_awsize   = 6 ;
    assign ddr4_1_dc_awregion = {1'b0, dci.awregion};
    assign ddr4_1_dc_awcache  = dci.awcache;
    assign ddr4_1_dc_awprot   = dci.awprot;
    assign ddr4_1_dc_wvalid   = dci.wvalid;
    assign ddr4_1_dc_wdata    = dci.wdata;
    assign ddr4_1_dc_wstrb    = dci.wstrb;
    assign ddr4_1_dc_wlast    = dci.wlast;
    assign ddr4_1_dc_arvalid  = dci.arvalid;
    assign ddr4_1_dc_araddr   = dci.araddr;
    assign ddr4_1_dc_arlen    = dci.arlen;
    assign ddr4_1_dc_arid     = dci.arid;
    assign ddr4_1_dc_arqos    = dci.arqos;
    assign ddr4_1_dc_arburst  = dci.arburst;
    assign ddr4_1_dc_arlock   = dci.arlock;
    //assign ddr4_1_dc_arsize   = dci.arsize;
    assign ddr4_1_dc_arsize   = 6 ;
    assign ddr4_1_dc_arregion = {1'b0, dci.arregion};
    assign ddr4_1_dc_arcache  = dci.arcache;
    assign ddr4_1_dc_arprot   = dci.arprot;
    assign ddr4_1_dc_rready   = dci.rready;
    assign ddr4_1_dc_bready   = dci.bready;
    assign dci.awready        = ddr4_1_dc_awready;
    assign dci.wready         = ddr4_1_dc_wready;
    assign dci.arready        = ddr4_1_dc_arready;
    assign dci.rvalid         = ddr4_1_dc_rvalid;
    assign dci.rdata          = ddr4_1_dc_rdata;
    assign dci.rlast          = ddr4_1_dc_rlast;
    assign dci.rresp          = ddr4_1_dc_rresp;
    assign dci.rid            = ddr4_1_dc_rid;
    assign dci.bvalid         = ddr4_1_dc_bvalid;
    assign dci.bresp          = ddr4_1_dc_bresp;
    assign dci.bid            = ddr4_1_dc_bid;

    // Test control
    logic [12:0]                test_gen_count_dci;    // Support up to 8K transactions
    logic [12:0]                test_rx_count_dci;
    logic                       axi_wr_enable_dci;
    logic                       start_dci;

    // As DCI has direct addressing and does not need to go through the NAP
    // then the generator TGT_ADDR_ID becomes the top address bits.
    // In addition we should ensure the DCI accesses do not clash with the same addresses used by the NAP
    // For the reference design, with a 16GB DIMM = 34 addressable bits, then set the top 7 bits
    // of the available 40 bits as the ID, [39:33].  Set bit 33 to 1'b1 to use the top half
    // of the memory
    // Reduce the rest of the memory by 7 to be the active addressable window
    localparam DCI_TOP_ADDR_PAGE     = 7'b000_0001;
    localparam DCI_ACTIVE_ADDR_WIDTH = DDR4_ADDR_WIDTH-7;

    // Values passed from writing block
    // See the memory width comments with the generators
    logic [DCI_ACTIVE_ADDR_WIDTH-1:0]   wr_addr_dci;
    logic [DCI_ACTIVE_ADDR_WIDTH-1:0]   rd_addr_dci;
    logic [7:0]                         wr_len_dci;
    logic [7:0]                         rd_len_dci;
    logic                               written_valid_dci;
    logic                               pkt_compared_dci;
    logic                               continuous_test_dci;

    // Values to pass through FIFO
    logic [MAX_FIFO_WIDTH -1:0] fifo_data_in_dci;
    logic [MAX_FIFO_WIDTH -1:0] fifo_data_out_dci;

    // Assign values to and from FIFO
    // Structures would be ideal here, except cannot be used as ports to FIFO
    // Do in the one block so that they can be checked for consistency
    assign fifo_data_in_dci = {{(MAX_FIFO_WIDTH-$bits(wr_len_dci)-$bits(wr_addr_dci)){1'b0}}, wr_len_dci, wr_addr_dci};
    assign rd_addr_dci      = fifo_data_out_dci[$bits(rd_addr_dci)-1:0];
    assign rd_len_dci       = fifo_data_out_dci[$bits(rd_addr_dci)+$bits(rd_len_dci)-1:$bits(rd_addr_dci)];

    // Check the data fits into the current FIFO width
    generate if ( ($bits(wr_len_dci) + $bits(wr_addr_dci)) > FIFO_WIDTH ) ERROR_dci_fifo_struct_to_wide(); endgenerate

    // FIFO control
    logic                       fifo_rden_dci;
    logic                       fifo_empty_dci;
    logic                       fifo_full_dci;

    // Hold off writing packets if transfer FIFO fills up        
    assign axi_wr_enable_dci   = (test_gen_count_dci != 13'h0) && ~fifo_full_dci;
    assign continuous_test_dci = (NUM_TRANSACTIONS == 0);

    // Synchronise the start signal across to the ddr4_1_clk domain
    logic   start_dci_sync_in;
    logic   start_dci_1;

    // Need to register combinatorial input to synchronizer
    always @(posedge i_clk)
        start_dci_sync_in <= (i_start & train_done);
	
    ACX_SYNCHRONIZER x_sync_start_dci (.din(start_dci_sync_in), .dout(start_dci_1), .clk(ddr4_1_clk), .rstn(dci_rstn));

    // Decrement the generate counter each time we write a transaction //
    always @(posedge ddr4_1_clk or negedge dci_rstn)
    begin
        if( ~dci_rstn ) begin
            test_gen_count_dci <= 13'h0;
            start_dci <= 1'b0 ;
        end else if ( start_dci_1 & ~start_dci ) begin
            test_gen_count_dci <= NUM_TRANSACTIONS;
            start_dci <= 1'b1 ;
        end else if (written_valid_dci && ~continuous_test_dci)
            test_gen_count_dci <= test_gen_count_dci - 13'h1;
    end

    // Increment the receive counter each time a packet is compared //
    always @(posedge ddr4_1_clk)
    begin
        if( ~dci_rstn )
            test_rx_count_dci <= 13'h0;
        else if ( start_dci_1 & ~start_dci )
            test_rx_count_dci <= 0;
        else if (pkt_compared_dci)
            test_rx_count_dci <= test_rx_count_dci + 13'h1;
    end

`ifdef ACX_SIM_STANDALONE_MODE
    // In standalone simulation mode, the DCI interface is not tested
    // In order to get a done output, assert dci_done
    assign dci_done = 1'b1;
`else
    // Fullchip mode, DCI interface is tested
    assign dci_done = (test_rx_count_dci == NUM_TRANSACTIONS) && ~continuous_test_dci;
`endif

    
    // Instantiate DCI AXI packet generator
    // The burst length can be longer as it is not constrained by the NoC to 16 beats
    axi_pkt_gen #(
        .LINEAR_PKTS            (0),
        .LINEAR_ADDR            (1),
        .TGT_ADDR_WIDTH         (DCI_ACTIVE_ADDR_WIDTH),    // Target address, lower bits
        .TGT_ADDR_PAD_WIDTH     (0),
        .TGT_ADDR_ID            (DCI_TOP_ADDR_PAGE),        // Appended to TGT_ADDR_WIDTH
        .TGT_DATA_WIDTH         (DCI_DATA_WIDTH),
        .MAX_BURST_LEN          (64),                       // Max AXI-4 length
        .AXI_ADDR_WIDTH         (DDR4_ADDR_WIDTH)           // Full width of address
    ) i_axi_pkt_gen_dci (
        // Inputs
        .i_clk                  (ddr4_1_clk),
        .i_reset_n              (dci_rstn),
        .i_start                (start_dci),
        .i_enable               (axi_wr_enable_dci),
        // Interfaces
        .axi_if                 (dci),
        // Outputs
        .o_addr_written         (wr_addr_dci),
        .o_len_written          (wr_len_dci),
        .o_written_valid        (written_valid_dci)
    );

    // FIFO the address and length written, and then read out into the checker
    ACX_LRAM2K_FIFO #(
        .aempty_threshold       (6'h4),
        .afull_threshold        (6'h4),
        .fwft_mode              (1'b0),
        .outreg_enable          (1'b1),
        .rdclk_polarity         ("rise"),
        .read_width             (FIFO_WIDTH),
        .sync_mode              (1'b1),
        .wrclk_polarity         ("rise"),
        .write_width            (FIFO_WIDTH)
    ) i_xact_fifo_dci ( 
        .din                    (fifo_data_in_dci),
        .rstn                   (dci_rstn),
        .wrclk                  (ddr4_1_clk),
        .rdclk                  (ddr4_1_clk),
        .wren                   (written_valid_dci),
        .rden                   (fifo_rden_dci),
        .outreg_rstn            (dci_rstn),
        .outreg_ce              (1'b1),
        .dout                   (fifo_data_out_dci),
        .almost_full            (),
        .full                   (fifo_full_dci),
        .almost_empty           (),
        .empty                  (fifo_empty_dci),
        .write_error            (),
        .read_error             ()
    );

    // Instantiate AXI packet checker
    // Must have the same configuration as the generator
    axi_pkt_chk #(
        .LINEAR_PKTS            (0),
        .TGT_ADDR_WIDTH         (DCI_ACTIVE_ADDR_WIDTH),
        .TGT_ADDR_PAD_WIDTH     (0),
        .TGT_ADDR_ID            (DCI_TOP_ADDR_PAGE),
        .TGT_DATA_WIDTH         (DCI_DATA_WIDTH),
        .AXI_ADDR_WIDTH         (DDR4_ADDR_WIDTH)
    ) i_axi_pkt_chk_dci (
        // Inputs
        .i_clk                  (ddr4_1_clk),
        .i_reset_n              (dci_rstn),
        .i_xact_avail           (~fifo_empty_dci),
        .i_xact_addr            (rd_addr_dci),
        .i_xact_len             (rd_len_dci),

        // Interfaces
        .axi_if                 (dci),
        // Outputs
        .o_xact_read            (fifo_rden_dci),
        .o_pkt_compared         (pkt_compared_dci),
        .o_pkt_error            (dci_fail)
    );

endmodule : ddr4_ref_design_top

