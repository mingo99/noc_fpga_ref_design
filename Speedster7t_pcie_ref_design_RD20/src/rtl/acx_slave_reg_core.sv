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

`include "acx_slave_reg_def.svh"


module acx_slave_reg_core # (
     parameter TGT_ADDR_WIDTH   = 28,
     parameter LEN_WIDTH        = 8,
     parameter TGT_DATA_WIDTH   = 64, // 256,
     parameter STRB_WIDTH       = 8   // 31,
) 
(
    // Inputs
    input wire                          i_clk,
    input wire                          i_rstn,
    input wire [STRB_WIDTH-1:0]         i_wr,
    input wire                          i_rd,
    input wire [LEN_WIDTH-1:0]          i_len,
    input wire [TGT_ADDR_WIDTH-1:0]     i_addr,
    input wire [TGT_DATA_WIDTH-1:0]     i_write_data,
   
    // Output
    output wire                         o_accept,
    output wire                         o_ack,
    output wire                         o_error,
    output wire [TGT_DATA_WIDTH-1:0]    o_read_data
);

   //-----------------------------------------------------------------
   // External Interface
   //-----------------------------------------------------------------

   reg         accept_i;
   reg         ack_i;

   assign o_accept = accept_i;
   assign o_ack = ack_i;
   assign o_error = 1'b0;

   reg [STRB_WIDTH-1:0] wr_d1;
   reg                  rd_d1, rd_d2;

   wire                 wr_req = |(i_wr & ~wr_d1);
   //wire rd_req = i_rd & ~rd_d1;
   wire                 rd_req = rd_d1 & ~rd_d2;

   always @ (posedge i_clk) begin
      if (~i_rstn) begin
         wr_d1 <= 'b0;
         rd_d1 <= 'b0;
         rd_d2 <= 'b0;
         accept_i <= 'b0;
         ack_i <= 'b0;
      end
      else begin
         wr_d1 <= i_wr;
         rd_d1 <= i_rd;
         rd_d2 <= rd_d1;
         accept_i <= wr_req | rd_req;
         ack_i <= accept_i;
      end
   end


   //-----------------------------------------------------------------
   // Registers
   //-----------------------------------------------------------------

   //-----------------------------------------------------------------
   // Register: cfg_0

   wire cfg_0_addr_hit_o;
   wire [31:0] cfg_0_read_data_o, cfg_0_o;

   acx_slave_reg_cfg # (
                .TGT_ADDR_WIDTH    (TGT_ADDR_WIDTH),
                .TGT_DATA_WIDTH    (32),
                .ADDR              (`REG_CFG_0_ADDR), 
                .INIT              (32'h0)
   ) i_reg_cfg_0 (
                .i_clk             (i_clk        ), 
                .i_rstn            (i_rstn       ),
                .i_wr              (i_wr[3:0]    ),
                .i_rd              (i_rd         ),
                .i_addr            (i_addr       ),
                .i_write_data      (i_write_data[31:0] ),
                .o_addr_hit        (cfg_0_addr_hit_o),
                .o_read_data       (cfg_0_read_data_o  ),
                .o_cfg             (cfg_0_o)
                );


   //-----------------------------------------------------------------
   // Register: cfg_1

   wire        cfg_1_addr_hit_o;
   wire [31:0] cfg_1_read_data_o, cfg_1_o;

   acx_slave_reg_cfg # (
                .TGT_ADDR_WIDTH    (TGT_ADDR_WIDTH),
                .TGT_DATA_WIDTH    (32),
                .ADDR              (`REG_CFG_1_ADDR), 
                .INIT              (32'h0)
   ) i_reg_cfg_1 (
                .i_clk             (i_clk        ), 
                .i_rstn            (i_rstn       ),
                .i_wr              (i_wr[3:0]    ),
                .i_rd              (i_rd         ),
                .i_addr            (i_addr       ),
                .i_write_data      (i_write_data[31:0] ),
                .o_addr_hit        (cfg_1_addr_hit_o),
                .o_read_data       (cfg_1_read_data_o  ),
                .o_cfg             (cfg_1_o)
                );


   //-----------------------------------------------------------------
   // Register: cfg_2

   wire        cfg_2_addr_hit_o;
   wire [31:0] cfg_2_read_data_o, cfg_2_o;

   acx_slave_reg_cfg # (
                .TGT_ADDR_WIDTH    (TGT_ADDR_WIDTH),
                .TGT_DATA_WIDTH    (32),
                .ADDR              (`REG_CFG_2_ADDR), 
                .INIT              (32'h0)
   ) i_reg_cfg_2 (
                .i_clk             (i_clk        ), 
                .i_rstn            (i_rstn       ),
                .i_wr              (i_wr[3:0]    ),
                .i_rd              (i_rd         ),
                .i_addr            (i_addr       ),
                .i_write_data      (i_write_data[31:0] ),
                .o_addr_hit        (cfg_2_addr_hit_o),
                .o_read_data       (cfg_2_read_data_o  ),
                .o_cfg             (cfg_2_o)
                );


   //-----------------------------------------------------------------
   // Register: cfg_3

   wire        cfg_3_addr_hit_o;
   wire [31:0] cfg_3_read_data_o, cfg_3_o;

   acx_slave_reg_cfg # (
                .TGT_ADDR_WIDTH    (TGT_ADDR_WIDTH),
                .TGT_DATA_WIDTH    (32),
                .ADDR              (`REG_CFG_3_ADDR), 
                .INIT              (32'h0)
   ) i_reg_cfg_3 (
                .i_clk             (i_clk        ), 
                .i_rstn            (i_rstn       ),
                .i_wr              (i_wr[3:0]    ),
                .i_rd              (i_rd         ),
                .i_addr            (i_addr       ),
                .i_write_data      (i_write_data[31:0] ),
                .o_addr_hit        (cfg_3_addr_hit_o),
                .o_read_data       (cfg_3_read_data_o  ),
                .o_cfg             (cfg_3_o)
                );


   //-----------------------------------------------------------------
   // Register: cfg_4

   wire        cfg_4_addr_hit_o;
   wire [31:0] cfg_4_read_data_o, cfg_4_o;

   acx_slave_reg_cfg # (
                .TGT_ADDR_WIDTH    (TGT_ADDR_WIDTH),
                .TGT_DATA_WIDTH    (32),
                .ADDR              (`REG_CFG_4_ADDR), 
                .INIT              (32'h0)
   ) i_reg_cfg_4 (
                .i_clk             (i_clk        ), 
                .i_rstn            (i_rstn       ),
                .i_wr              (i_wr[3:0]    ),
                .i_rd              (i_rd         ),
                .i_addr            (i_addr       ),
                .i_write_data      (i_write_data[31:0] ),
                .o_addr_hit        (cfg_4_addr_hit_o),
                .o_read_data       (cfg_4_read_data_o  ),
                .o_cfg             (cfg_4_o)
                );


   //-----------------------------------------------------------------
   // Register: cfg_5

   wire        cfg_5_addr_hit_o;
   wire [31:0] cfg_5_read_data_o, cfg_5_o;

   acx_slave_reg_cfg # (
                .TGT_ADDR_WIDTH    (TGT_ADDR_WIDTH),
                .TGT_DATA_WIDTH    (32),
                .ADDR              (`REG_CFG_5_ADDR), 
                .INIT              (32'h0)
   ) i_reg_cfg_5 (
                .i_clk             (i_clk        ), 
                .i_rstn            (i_rstn       ),
                .i_wr              (i_wr[3:0]    ),
                .i_rd              (i_rd         ),
                .i_addr            (i_addr       ),
                .i_write_data      (i_write_data[31:0] ),
                .o_addr_hit        (cfg_5_addr_hit_o),
                .o_read_data       (cfg_5_read_data_o  ),
                .o_cfg             (cfg_5_o)
                );


   //-----------------------------------------------------------------
   // Register: cfg_6

   wire        cfg_6_addr_hit_o;
   wire [31:0] cfg_6_read_data_o, cfg_6_o;

   acx_slave_reg_cfg # (
                .TGT_ADDR_WIDTH    (TGT_ADDR_WIDTH),
                .TGT_DATA_WIDTH    (32),
                .ADDR              (`REG_CFG_6_ADDR), 
                .INIT              (32'h0)
   ) i_reg_cfg_6 (
                .i_clk             (i_clk        ), 
                .i_rstn            (i_rstn       ),
                .i_wr              (i_wr[3:0]    ),
                .i_rd              (i_rd         ),
                .i_addr            (i_addr       ),
                .i_write_data      (i_write_data[31:0] ),
                .o_addr_hit        (cfg_6_addr_hit_o),
                .o_read_data       (cfg_6_read_data_o  ),
                .o_cfg             (cfg_6_o)
                );


   //-----------------------------------------------------------------
   // Register: cfg_7

   wire        cfg_7_addr_hit_o;
   wire [31:0] cfg_7_read_data_o, cfg_7_o;

   acx_slave_reg_cfg # (
                .TGT_ADDR_WIDTH    (TGT_ADDR_WIDTH),
                .TGT_DATA_WIDTH    (32),
                .ADDR              (`REG_CFG_7_ADDR), 
                .INIT              (32'h0)
   ) i_reg_cfg_7 (
                .i_clk             (i_clk        ), 
                .i_rstn            (i_rstn       ),
                .i_wr              (i_wr[3:0]    ),
                .i_rd              (i_rd         ),
                .i_addr            (i_addr       ),
                .i_write_data      (i_write_data[31:0] ),
                .o_addr_hit        (cfg_7_addr_hit_o),
                .o_read_data       (cfg_7_read_data_o  ),
                .o_cfg             (cfg_7_o)
                );


   //-----------------------------------------------------------------
   // Register: sta_0

   wire        sta_0_addr_hit_o;
   wire [31:0] sta_0_i, sta_0_o, sta_0_read_data_o ;

   acx_slave_reg_sta # (
                .TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                .TGT_DATA_WIDTH (32),
                .ADDR           (`REG_STA_0_ADDR),
                .INIT           (32'h0 ) 
   ) i_reg_sta_0 (
                .i_clk          (i_clk        ), 
                .i_rstn         (i_rstn       ),
                .i_rd           (i_rd         ),
                .i_addr         (i_addr       ),
                .i_sta          (sta_0_i      ),
                .o_addr_hit     (sta_0_addr_hit_o),
                .o_read_data    (sta_0_read_data_o  ),
                .o_sta          (sta_0_o )
                );                                 

   // assign a static value to the register
   assign sta_0_i = `REG_STA_0_ADDR;
   
   

   //-----------------------------------------------------------------
   // Register: sta_1

   wire        sta_1_addr_hit_o;
   wire [31:0] sta_1_i, sta_1_o, sta_1_read_data_o ;

   acx_slave_reg_sta # (
                .TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                .TGT_DATA_WIDTH (32),
                .ADDR           (`REG_STA_1_ADDR),
                .INIT           (32'h0 ) 
   ) i_reg_sta_1 (
                .i_clk        (i_clk        ), 
                .i_rstn       (i_rstn       ),
                .i_rd         (i_rd         ),
                .i_addr       (i_addr       ),
                .i_sta        (sta_1_i      ),
                .o_addr_hit   (sta_1_addr_hit_o),
                .o_read_data  (sta_1_read_data_o  ),
                .o_sta        (sta_1_o )
                );                                 

   // assign a static value to the register
   assign sta_1_i = `REG_STA_1_ADDR;

   //-----------------------------------------------------------------
   // Register: sta_2

   wire        sta_2_addr_hit_o;
   wire [31:0] sta_2_i, sta_2_o, sta_2_read_data_o ;

   acx_slave_reg_sta # (
                .TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                .TGT_DATA_WIDTH (32),
                .ADDR           (`REG_STA_2_ADDR),
                .INIT           (32'h0 ) 
   ) i_reg_sta_2 (
                .i_clk        (i_clk        ), 
                .i_rstn       (i_rstn       ),
                .i_rd         (i_rd         ),
                .i_addr       (i_addr       ),
                .i_sta        (sta_2_i      ),
                .o_addr_hit   (sta_2_addr_hit_o),
                .o_read_data  (sta_2_read_data_o  ),
                .o_sta        (sta_2_o )
                );                                 

   // assign a static value to the register
   assign sta_2_i = `REG_STA_2_ADDR;

   //-----------------------------------------------------------------
   // Register: sta_3

   wire        sta_3_addr_hit_o;
   wire [31:0] sta_3_i, sta_3_o, sta_3_read_data_o ;

   acx_slave_reg_sta # (
                .TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                .TGT_DATA_WIDTH (32),
                .ADDR           (`REG_STA_3_ADDR),
                .INIT           (32'h0 ) 
   ) i_reg_sta_3 (
                .i_clk        (i_clk        ), 
                .i_rstn       (i_rstn       ),
                .i_rd         (i_rd         ),
                .i_addr       (i_addr       ),
                .i_sta        (sta_3_i      ),
                .o_addr_hit   (sta_3_addr_hit_o),
                .o_read_data  (sta_3_read_data_o  ),
                .o_sta        (sta_3_o )
                );                                 

   // assign a static value to the register
   assign sta_3_i = `REG_STA_3_ADDR;

   //-----------------------------------------------------------------
   // Register: sta_4

   wire        sta_4_addr_hit_o;
   wire [31:0] sta_4_i, sta_4_o, sta_4_read_data_o ;

   acx_slave_reg_sta # (
                .TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                .TGT_DATA_WIDTH (32),
                .ADDR           (`REG_STA_4_ADDR),
                .INIT           (32'h0 ) 
   ) i_reg_sta_4 (
                .i_clk        (i_clk        ), 
                .i_rstn       (i_rstn       ),
                .i_rd         (i_rd         ),
                .i_addr       (i_addr       ),
                .i_sta        (sta_4_i      ),
                .o_addr_hit   (sta_4_addr_hit_o),
                .o_read_data  (sta_4_read_data_o  ),
                .o_sta        (sta_4_o )
                );                                 

   // assign a static value to the register
   assign sta_4_i = `REG_STA_4_ADDR;

   //-----------------------------------------------------------------
   // Register: sta_5

   wire        sta_5_addr_hit_o;
   wire [31:0] sta_5_i, sta_5_o, sta_5_read_data_o ;

   acx_slave_reg_sta # (
                .TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                .TGT_DATA_WIDTH (32),
                .ADDR           (`REG_STA_5_ADDR),
                .INIT           (32'h0 ) 
   ) i_reg_sta_5 (
                .i_clk        (i_clk        ), 
                .i_rstn       (i_rstn       ),
                .i_rd         (i_rd         ),
                .i_addr       (i_addr       ),
                .i_sta        (sta_5_i      ),
                .o_addr_hit   (sta_5_addr_hit_o),
                .o_read_data  (sta_5_read_data_o  ),
                .o_sta        (sta_5_o )
                );                                 

   // assign a static value to the register
   assign sta_5_i = `REG_STA_5_ADDR;

   //-----------------------------------------------------------------
   // Register: sta_6

   wire        sta_6_addr_hit_o;
   wire [31:0] sta_6_i, sta_6_o, sta_6_read_data_o ;

   acx_slave_reg_sta # (
                .TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                .TGT_DATA_WIDTH (32),
                .ADDR           (`REG_STA_6_ADDR),
                .INIT           (32'h0 ) 
   ) i_reg_sta_6 (
                .i_clk        (i_clk        ), 
                .i_rstn       (i_rstn       ),
                .i_rd         (i_rd         ),
                .i_addr       (i_addr       ),
                .i_sta        (sta_6_i      ),
                .o_addr_hit   (sta_6_addr_hit_o),
                .o_read_data  (sta_6_read_data_o  ),
                .o_sta        (sta_6_o )
                );                                 

   // assign a static value to the register
   assign sta_6_i = `REG_STA_6_ADDR;

   //-----------------------------------------------------------------
   // Register: sta_7

   wire        sta_7_addr_hit_o;
   wire [31:0] sta_7_i, sta_7_o, sta_7_read_data_o ;

   acx_slave_reg_sta # (
                .TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                .TGT_DATA_WIDTH (32),
                .ADDR           (`REG_STA_7_ADDR),
                .INIT           (32'h0 ) 
   ) i_reg_sta_7 (
                .i_clk        (i_clk        ), 
                .i_rstn       (i_rstn       ),
                .i_rd         (i_rd         ),
                .i_addr       (i_addr       ),
                .i_sta        (sta_7_i      ),
                .o_addr_hit   (sta_7_addr_hit_o),
                .o_read_data  (sta_7_read_data_o  ),
                .o_sta        (sta_7_o )
                );                                 

   // assign a static value to the register
   assign sta_7_i = `REG_STA_7_ADDR;

   //-----------------------------------------------------------------
   // Register: irq_0, i_reg_irq_clear_0

   wire        irq_0_addr_hit_o, irq_cfg_0_addr_hit_o;
   wire [31:0] irq_0_set_i, irq_0_clear_i, irq_0_read_data_o, irq_0_o, irq_cfg_0_read_data_o;

   acx_slave_reg_irq # (.TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                        .TGT_DATA_WIDTH (32),
                        .ADDR (`REG_IRQ_0_ADDR), 
                        .INIT (32'h0)
                        )
   i_reg_irq_0 (
                .i_clk            (i_clk        ), 
                .i_rstn           (i_rstn       ),
                .i_wr             (i_wr[3:0]    ),
                .i_rd             (i_rd         ),
                .i_addr           (i_addr       ),
                .i_write_data     (i_write_data[31:0] ),
                .i_irq_set        (irq_0_set_i),
                .i_irq_clear      (irq_0_clear_i),
                .o_addr_hit       (irq_0_addr_hit_o),
                .o_read_data      (irq_0_read_data_o  ),
                .o_irq            (irq_0_o  )
                );

   // for now keep IRQ set as 0
   assign irq_0_set_i = 32'h0;
   

   acx_slave_reg_cfg # (.TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                        .TGT_DATA_WIDTH (32),
                        .ADDR (`REG_IRQ_CFG_0_ADDR), 
                        .INIT (32'h0)
                        )
   i_reg_irq_clear_0 (
                      .i_clk             (i_clk        ), 
                      .i_rstn            (i_rstn       ),
                      .i_wr              (i_wr[3:0]    ),
                      .i_rd              (i_rd         ),
                      .i_addr            (i_addr       ),
                      .i_write_data      (i_write_data[31:0] ),
                      .o_addr_hit        (irq_cfg_0_addr_hit_o),
                      .o_read_data       (irq_cfg_0_read_data_o  ),
                      .o_cfg             (irq_0_clear_i)
                      );


   //-----------------------------------------------------------------
   // Register: irq_master

   wire        irq_master_addr_hit_o;
   wire [31:0] irq_master_i, irq_master_o, irq_master_read_data_o ;

   acx_slave_reg_sta # (.TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                        .TGT_DATA_WIDTH (32),
                        .ADDR (`REG_IRQ_MASTER_ADDR),
                        .INIT (32'h0) 
                        ) 
   i_reg_irq_master (
                     .i_clk        (i_clk        ), 
                     .i_rstn       (i_rstn       ),
                     .i_rd         (i_rd         ),
                     .i_addr       (i_addr       ),
                     .i_sta        (irq_master_i ),
                     .o_addr_hit   (irq_master_addr_hit_o),
                     .o_read_data  (irq_master_read_data_o  ),
                     .o_sta        (irq_master_o )
                     );                                 

   assign irq_master_i = {31'b0, |{irq_0_o}};   


   //-----------------------------------------------------------------
   // Register: clear_on_rd

   wire        irq_rc_addr_hit_o;
   wire [31:0] irq_rc_set_i, irq_rc_read_data_o, irq_rc_reg_o;

   acx_slave_reg_irq_rc # (.TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                           .TGT_DATA_WIDTH (32),
                           .ADDR (`REG_CLEAR_ON_RD_ADDR), 
                           .INIT (32'h0)
                           )
   i_reg_irq_rc (
                 .i_clk             (i_clk        ), 
                 .i_rstn            (i_rstn       ),
                 .i_wr              (i_wr[3:0]    ),
                 .i_rd              (i_rd         ),
                 .i_addr            (i_addr       ),
                 .i_write_data      (i_write_data[31:0] ),
                 .i_irq_set         (irq_rc_set_i),
                 .o_addr_hit        (irq_rc_addr_hit_o),
                 .o_read_data       (irq_rc_read_data_o  ),
                 .o_irq             (irq_rc_reg_o)
                 );

   // set to all 0s
   assign irq_rc_set_i = 32'h0;
   

   
   //-----------------------------------------------------------------
   // Register: cnt_0, cnt_cfg_0

   wire        cnt_0_en_i, cnt_0_addr_hit_o, cnt_cfg_0_addr_hit_o;
   wire [31:0] cnt_0_control_i, cnt_0_read_data_o, cnt_0_o, cnt_cfg_0_read_data_o;

   acx_slave_reg_cnt # (.TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                        .TGT_DATA_WIDTH (32),
                        .ADDR (`REG_CNT_0_ADDR), 
                        .INIT (32'h0)
                        )
   i_reg_cnt_0 (
                .i_clk             (i_clk        ), 
                .i_rstn            (i_rstn       ),
                .i_wr              (i_wr[3:0]    ),
                .i_rd              (i_rd         ),
                .i_addr            (i_addr       ),
                .i_write_data      (i_write_data[31:0] ),
                .i_cnt_control     (cnt_0_control_i),
                .i_cnt_en          (cnt_0_en_i  ),
                .o_addr_hit        (cnt_0_addr_hit_o),
                .o_read_data       (cnt_0_read_data_o  ),
                .o_cnt             (cnt_0_o  )
                );

   // set it to enable
   assign cnt_0_en_i = 1'b1;
   
   
   acx_slave_reg_cfg # (.TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                        .TGT_DATA_WIDTH (32),
                        .ADDR (`REG_CNT_CFG_0_ADDR), 
                        .INIT (32'h0)
                        )
   i_reg_cnt_cfg_0 (
                    .i_clk             (i_clk        ), 
                    .i_rstn            (i_rstn       ),
                    .i_wr              (i_wr[3:0]    ),
                    .i_rd              (i_rd         ),
                    .i_addr            (i_addr       ),
                    .i_write_data      (i_write_data[31:0] ),
                    .o_addr_hit        (cnt_cfg_0_addr_hit_o),
                    .o_read_data       (cnt_cfg_0_read_data_o  ),
                    .o_cfg             (cnt_0_control_i)
                    );

   //-----------------------------------------------------------------
   // Register: cnt_1, cnt_cfg_1

   wire        cnt_1_en_i, cnt_1_addr_hit_o, cnt_cfg_1_addr_hit_o;
   wire [31:0] cnt_1_control_i, cnt_1_read_data_o, cnt_1_o, cnt_cfg_1_read_data_o;

   acx_slave_reg_cnt # (.TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                        .TGT_DATA_WIDTH (32),
                        .ADDR (`REG_CNT_1_ADDR), 
                        .INIT (32'h0)
                        )
   i_reg_cnt_1 (
                .i_clk             (i_clk        ), 
                .i_rstn            (i_rstn       ),
                .i_wr              (i_wr[3:0]    ),
                .i_rd              (i_rd         ),
                .i_addr            (i_addr       ),
                .i_write_data      (i_write_data[31:0] ),
                .i_cnt_control     (cnt_1_control_i),
                .i_cnt_en          (cnt_1_en_i  ),
                .o_addr_hit        (cnt_1_addr_hit_o),
                .o_read_data       (cnt_1_read_data_o  ),
                .o_cnt             (cnt_1_o  )
                );

   // set it to enable
   assign cnt_1_en_i = 1'b1;
   
   acx_slave_reg_cfg # (.TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                        .TGT_DATA_WIDTH (32),
                        .ADDR (`REG_CNT_CFG_1_ADDR), 
                        .INIT (32'h0)
                        )
   i_reg_cnt_cfg_1 (
                    .i_clk             (i_clk        ), 
                    .i_rstn            (i_rstn       ),
                    .i_wr              (i_wr[3:0]    ),
                    .i_rd              (i_rd         ),
                    .i_addr            (i_addr       ),
                    .i_write_data      (i_write_data[31:0] ),
                    .o_addr_hit        (cnt_cfg_1_addr_hit_o),
                    .o_read_data       (cnt_cfg_1_read_data_o  ),
                    .o_cfg             (cnt_1_control_i)
                    );

   //-----------------------------------------------------------------
   // Register: cfg64_0

   wire        cfg64_0_addr_hit_o;
   wire [64-1:0] cfg64_0_read_data_o, cfg64_0_o;

   acx_slave_reg_cfg64 # (.TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                          .TGT_DATA_WIDTH (TGT_DATA_WIDTH),
                          .ADDR (`REG_CFG64_0_ADDR), 
                          .INIT (64'h0)
                          )
   i_reg_cfg64_0 (
                  .i_clk             (i_clk        ), 
                  .i_rstn            (i_rstn       ),
                  .i_wr              (i_wr         ),
                  .i_rd              (i_rd         ),
                  .i_addr            (i_addr       ),
                  .i_write_data      (i_write_data ),
                  .o_addr_hit        (cfg64_0_addr_hit_o),
                  .o_read_data       (cfg64_0_read_data_o  ),
                  .o_cfg             (cfg64_0_o)
                  );

   //-----------------------------------------------------------------
   // Register: cfg64_1

   wire          cfg64_1_addr_hit_o;
   wire [64-1:0] cfg64_1_read_data_o, cfg64_1_o;

   acx_slave_reg_cfg64 # (.TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                          .TGT_DATA_WIDTH (TGT_DATA_WIDTH),
                          .ADDR (`REG_CFG64_1_ADDR), 
                          .INIT (64'h0)
                          )
   i_reg_cfg64_1 (
                  .i_clk             (i_clk        ), 
                  .i_rstn            (i_rstn       ),
                  .i_wr              (i_wr         ),
                  .i_rd              (i_rd         ),
                  .i_addr            (i_addr       ),
                  .i_write_data      (i_write_data ),
                  .o_addr_hit        (cfg64_1_addr_hit_o),
                  .o_read_data       (cfg64_1_read_data_o  ),
                  .o_cfg             (cfg64_1_o)
                  );


   //-----------------------------------------------------------------
   // Register: cfg64_2

   wire          cfg64_2_addr_hit_o;
   wire [64-1:0] cfg64_2_read_data_o, cfg64_2_o;

   acx_slave_reg_cfg64 # (.TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                          .TGT_DATA_WIDTH (TGT_DATA_WIDTH),
                          .ADDR (`REG_CFG64_2_ADDR), 
                          .INIT (64'h0)
                          )
   i_reg_cfg64_2 (
                  .i_clk             (i_clk        ), 
                  .i_rstn            (i_rstn       ),
                  .i_wr              (i_wr         ),
                  .i_rd              (i_rd         ),
                  .i_addr            (i_addr       ),
                  .i_write_data      (i_write_data ),
                  .o_addr_hit        (cfg64_2_addr_hit_o),
                  .o_read_data       (cfg64_2_read_data_o  ),
                  .o_cfg             (cfg64_2_o)
                  );


   //-----------------------------------------------------------------
   // Register: cfg64_3

   wire          cfg64_3_addr_hit_o;
   wire [64-1:0] cfg64_3_read_data_o, cfg64_3_o;

   acx_slave_reg_cfg64 # (.TGT_ADDR_WIDTH (TGT_ADDR_WIDTH),
                          .TGT_DATA_WIDTH (TGT_DATA_WIDTH),
                          .ADDR (`REG_CFG64_3_ADDR), 
                          .INIT (64'h0)
                          )
   i_reg_cfg64_3 (
                  .i_clk             (i_clk        ), 
                  .i_rstn            (i_rstn       ),
                  .i_wr              (i_wr         ),
                  .i_rd              (i_rd         ),
                  .i_addr            (i_addr       ),
                  .i_write_data      (i_write_data ),
                  .o_addr_hit        (cfg64_3_addr_hit_o),
                  .o_read_data       (cfg64_3_read_data_o  ),
                  .o_cfg             (cfg64_3_o)
                  );


   //-----------------------------------------------------------------
   // Register: read data mux

   acx_slave_reg_dout_mux # (
                             .NUM_REGS (`N_REGS), 
                             .TGT_DATA_WIDTH (TGT_DATA_WIDTH)
                             ) 
   i_reg_dout_mux (
                   .i_clk             (i_clk        ),
                   .i_rstn            (i_rstn       ),
                   .i_addr_hit        ({
                                        cfg_2_addr_hit_o,
                                        cfg_3_addr_hit_o,
                                        cfg_4_addr_hit_o,
                                        cfg_5_addr_hit_o,
                                        cfg_6_addr_hit_o,
                                        cfg_7_addr_hit_o,
                                        sta_0_addr_hit_o,
                                        sta_1_addr_hit_o,
                                        sta_2_addr_hit_o,
                                        sta_3_addr_hit_o,
                                        sta_4_addr_hit_o,
                                        sta_5_addr_hit_o,
                                        sta_6_addr_hit_o,
                                        sta_7_addr_hit_o,
                                        cnt_0_addr_hit_o, 
                                        cnt_cfg_0_addr_hit_o,
                                        cnt_1_addr_hit_o, 
                                        cnt_cfg_1_addr_hit_o,
                                        irq_0_addr_hit_o, 
                                        irq_cfg_0_addr_hit_o,
                                        irq_master_addr_hit_o,
                                        irq_rc_addr_hit_o,
                                        cfg64_0_addr_hit_o,
                                        cfg64_1_addr_hit_o,
                                        cfg64_2_addr_hit_o,
                                        cfg64_3_addr_hit_o,
                                        cfg_1_addr_hit_o,
                                        cfg_0_addr_hit_o
                                        }),
                   .i_read_data       ({
                                        {32'b0, cfg_2_read_data_o},
                                        {32'b0, cfg_3_read_data_o},
                                        {32'b0, cfg_4_read_data_o},
                                        {32'b0, cfg_5_read_data_o},
                                        {32'b0, cfg_6_read_data_o},
                                        {32'b0, cfg_7_read_data_o},
                                        {32'b0, sta_0_read_data_o},
                                        {32'b0, sta_1_read_data_o},
                                        {32'b0, sta_2_read_data_o},
                                        {32'b0, sta_3_read_data_o},
                                        {32'b0, sta_4_read_data_o},
                                        {32'b0, sta_5_read_data_o},
                                        {32'b0, sta_6_read_data_o},
                                        {32'b0, sta_7_read_data_o},
                                        {32'b0, cnt_0_read_data_o},
                                        {32'b0, cnt_cfg_0_read_data_o},
                                        {32'b0, cnt_1_read_data_o},
                                        {32'b0, cnt_cfg_1_read_data_o},
                                        {32'b0, irq_0_read_data_o}, 
                                        {32'b0, irq_cfg_0_read_data_o},
                                        {32'b0, irq_master_read_data_o},
                                        {32'b0, irq_rc_read_data_o},
                                        cfg64_0_read_data_o,
                                        cfg64_1_read_data_o,
                                        cfg64_2_read_data_o,
                                        cfg64_3_read_data_o,
                                        {32'b0, cfg_1_read_data_o},
                                        {32'b0, cfg_0_read_data_o}
                                        }),
                   .o_read_data       (o_read_data)
                   );

endmodule :acx_slave_reg_core

