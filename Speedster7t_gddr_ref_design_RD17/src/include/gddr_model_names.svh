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
// Speedster7t GDDR reference design (RD17)
//      Defines to create and connect logic to GDDR Model
// ------------------------------------------------------------------

/*
   RTL mode simulation requires use of the GDDR6 memory simulation models. 
   Achronix is not able to provide these models directly to the user.
   Rather, the user needs to acquire these models directly from their preferred vendor.

   The testbench and reference design were developed using models from Micron Technology Inc. 
   To obtain these models, the user should contact Micron Sales or Technical Support directly.

   The following sections shows Macro definition for a specific GDDR6 sim model, user may
   need to change these if a different model is used.
*/


`ifndef INCLUDE_GDDR_MODEL_NAMES
`define INCLUDE_GDDR_MODEL_NAMES

`define ACX_GDDR_MODEL_WIRE(S) \
wire ``S``_rref           ;\
wire ``S``_sd_clk_p       ;\
wire ``S``_sd_clk_n       ;\
wire ``S``_sd_reset_n     ;\
wire ``S``_c0_sd_cke_n    ;\
wire ``S``_c0_sd_ca_9     ;\
wire ``S``_c0_sd_ca_8     ;\
wire ``S``_c0_sd_ca_7     ;\
wire ``S``_c0_sd_ca_6     ;\
wire ``S``_c0_sd_ca_5     ;\
wire ``S``_c0_sd_ca_4     ;\
wire ``S``_c0_sd_ca_3     ;\
wire ``S``_c0_sd_ca_2     ;\
wire ``S``_c0_sd_ca_1     ;\
wire ``S``_c0_sd_ca_0     ;\
wire ``S``_c0_sd_cabi_n   ;\
wire ``S``_c0_sd_wck_p_1  ;\
wire ``S``_c0_sd_wck_p_0  ;\
wire ``S``_c0_sd_wck_n_1  ;\
wire ``S``_c0_sd_wck_n_0  ;\
wire ``S``_c1_sd_cke_n    ;\
wire ``S``_c1_sd_ca_9     ;\
wire ``S``_c1_sd_ca_8     ;\
wire ``S``_c1_sd_ca_7     ;\
wire ``S``_c1_sd_ca_6     ;\
wire ``S``_c1_sd_ca_5     ;\
wire ``S``_c1_sd_ca_4     ;\
wire ``S``_c1_sd_ca_3     ;\
wire ``S``_c1_sd_ca_2     ;\
wire ``S``_c1_sd_ca_1     ;\
wire ``S``_c1_sd_ca_0     ;\
wire ``S``_c1_sd_cabi_n   ;\
wire ``S``_c1_sd_wck_p_1  ;\
wire ``S``_c1_sd_wck_p_0  ;\
wire ``S``_c1_sd_wck_n_1  ;\
wire ``S``_c1_sd_wck_n_0  ;\
wire ``S``_c0_sd_dq_15    ;\
wire ``S``_c0_sd_dq_14    ;\
wire ``S``_c0_sd_dq_13    ;\
wire ``S``_c0_sd_dq_12    ;\
wire ``S``_c0_sd_dq_11    ;\
wire ``S``_c0_sd_dq_10    ;\
wire ``S``_c0_sd_dq_9     ;\
wire ``S``_c0_sd_dq_8     ;\
wire ``S``_c0_sd_dq_7     ;\
wire ``S``_c0_sd_dq_6     ;\
wire ``S``_c0_sd_dq_5     ;\
wire ``S``_c0_sd_dq_4     ;\
wire ``S``_c0_sd_dq_3     ;\
wire ``S``_c0_sd_dq_2     ;\
wire ``S``_c0_sd_dq_1     ;\
wire ``S``_c0_sd_dq_0     ;\
wire ``S``_c0_sd_dbi_n_1  ;\
wire ``S``_c0_sd_dbi_n_0  ;\
wire ``S``_c0_sd_edc_1    ;\
wire ``S``_c0_sd_edc_0    ;\
wire ``S``_c1_sd_dq_15    ;\
wire ``S``_c1_sd_dq_14    ;\
wire ``S``_c1_sd_dq_13    ;\
wire ``S``_c1_sd_dq_12    ;\
wire ``S``_c1_sd_dq_11    ;\
wire ``S``_c1_sd_dq_10    ;\
wire ``S``_c1_sd_dq_9     ;\
wire ``S``_c1_sd_dq_8     ;\
wire ``S``_c1_sd_dq_7     ;\
wire ``S``_c1_sd_dq_6     ;\
wire ``S``_c1_sd_dq_5     ;\
wire ``S``_c1_sd_dq_4     ;\
wire ``S``_c1_sd_dq_3     ;\
wire ``S``_c1_sd_dq_2     ;\
wire ``S``_c1_sd_dq_1     ;\
wire ``S``_c1_sd_dq_0     ;\
wire ``S``_c1_sd_dbi_n_1  ;\
wire ``S``_c1_sd_dbi_n_0  ;\
wire ``S``_c1_sd_edc_1    ;\
wire ``S``_c1_sd_edc_0    ;\
wire ``S``_atestca        ;\
wire ``S``_atestdql       ;\
wire ``S``_atestdqr
//wire ``S``_c0_sd_rfu_1    ;\
//wire ``S``_c0_sd_rfu_0    ;\
//wire ``S``_c1_sd_rfu_1    ;\
//wire ``S``_c1_sd_rfu_0

`define ACX_GDDR_PORT_CONNECT(A,B) \
.``A``_RREF(``B``_rref),\
.``A``_ATESTCA(``B``_atestca),\
.``A``_ATESTDQL(``B``_atestdql),\
.``A``_ATESTDQR(``B``_atestdqr),\
.``A``_SD_CLK_P(``B``_sd_clk_p),\
.``A``_SD_CLK_N(``B``_sd_clk_n),\
.``A``_SD_RESET_N(``B``_sd_reset_n),\
.``A``_C0_SD_CKE_N(``B``_c0_sd_cke_n),\
.``A``_C0_SD_CA({``B``_c0_sd_ca_9, ``B``_c0_sd_ca_8,``B``_c0_sd_ca_7,\
                                    ``B``_c0_sd_ca_6,``B``_c0_sd_ca_5, ``B``_c0_sd_ca_4,\
                                    ``B``_c0_sd_ca_3, ``B``_c0_sd_ca_2, ``B``_c0_sd_ca_1,\
                                    ``B``_c0_sd_ca_0}),\
.``A``_C0_SD_CABI_N(``B``_c0_sd_cabi_n),\
.``A``_C0_SD_WCK_P({``B``_c0_sd_wck_p_1, ``B``_c0_sd_wck_p_0}),\
.``A``_C0_SD_WCK_N({``B``_c0_sd_wck_n_1,``B``_c0_sd_wck_n_0}),\
.``A``_C1_SD_CKE_N(``B``_c1_sd_cke_n),\
.``A``_C1_SD_CA({``B``_c1_sd_ca_9,``B``_c1_sd_ca_8,``B``_c1_sd_ca_7,``B``_c1_sd_ca_6,``B``_c1_sd_ca_5,\
``B``_c1_sd_ca_4,``B``_c1_sd_ca_3,``B``_c1_sd_ca_2,``B``_c1_sd_ca_1,``B``_c1_sd_ca_0}),\
.``A``_C1_SD_CABI_N(``B``_c1_sd_cabi_n),\
.``A``_C1_SD_WCK_P({``B``_c1_sd_wck_p_1 ,``B``_c1_sd_wck_p_0}),\
.``A``_C1_SD_WCK_N({``B``_c1_sd_wck_n_1 ,``B``_c1_sd_wck_n_0}),\
.``A``_C0_SD_DQ({``B``_c0_sd_dq_15 ,``B``_c0_sd_dq_14 ,``B``_c0_sd_dq_13 ,``B``_c0_sd_dq_12 ,``B``_c0_sd_dq_11 ,``B``_c0_sd_dq_10,\
``B``_c0_sd_dq_9 ,``B``_c0_sd_dq_8 ,``B``_c0_sd_dq_7 ,``B``_c0_sd_dq_6 ,``B``_c0_sd_dq_5 ,``B``_c0_sd_dq_4 ,``B``_c0_sd_dq_3,\
``B``_c0_sd_dq_2 ,``B``_c0_sd_dq_1 ,``B``_c0_sd_dq_0}),\
.``A``_C1_SD_DQ({``B``_c1_sd_dq_15 ,``B``_c1_sd_dq_14 ,``B``_c1_sd_dq_13 ,``B``_c1_sd_dq_12 ,``B``_c1_sd_dq_11 ,``B``_c1_sd_dq_10,\
``B``_c1_sd_dq_9 ,``B``_c1_sd_dq_8 ,``B``_c1_sd_dq_7 ,``B``_c1_sd_dq_6 ,``B``_c1_sd_dq_5 ,``B``_c1_sd_dq_4,\
``B``_c1_sd_dq_3 ,``B``_c1_sd_dq_2 ,``B``_c1_sd_dq_1 ,``B``_c1_sd_dq_0}),\
.``A``_C0_SD_DBI_N({``B``_c0_sd_dbi_n_1 ,``B``_c0_sd_dbi_n_0}),\
.``A``_C1_SD_DBI_N({``B``_c1_sd_dbi_n_1 ,``B``_c1_sd_dbi_n_0}),\
.``A``_C0_SD_EDC({``B``_c0_sd_edc_1, ``B``_c0_sd_edc_0}),\
.``A``_C1_SD_EDC({``B``_c1_sd_edc_1,``B``_c1_sd_edc_0})

`define GDDR_MODEL_PORT_CONNECT(S) \
        .vrefc(1'b1),\
.ck_t(``S``_sd_clk_p),\
.ck_c(``S``_sd_clk_n),\
.reset_n(``S``_sd_reset_n),\
.cke_n_a(``S``_c0_sd_cke_n),\
.cke_n_b(``S``_c1_sd_cke_n),\
.ca_a({``S``_c0_sd_ca_9,``S``_c0_sd_ca_8,``S``_c0_sd_ca_7,``S``_c0_sd_ca_6,\
                ``S``_c0_sd_ca_5,``S``_c0_sd_ca_4,``S``_c0_sd_ca_3,``S``_c0_sd_ca_2,\
                ``S``_c0_sd_ca_1,``S``_c0_sd_ca_0}),\
.ca_b({``S``_c1_sd_ca_9,``S``_c1_sd_ca_8,``S``_c1_sd_ca_7,``S``_c1_sd_ca_6,\
                ``S``_c1_sd_ca_5,``S``_c1_sd_ca_4,``S``_c1_sd_ca_3,``S``_c1_sd_ca_2,\
                ``S``_c1_sd_ca_1,``S``_c1_sd_ca_0}),\
.cabi_n_a(``S``_c0_sd_cabi_n),\
.cabi_n_b(``S``_c1_sd_cabi_n),\
.wck0_t_a(``S``_c0_sd_wck_p_0),\
.wck0_t_b(``S``_c1_sd_wck_p_0),\
.wck1_t_a(``S``_c0_sd_wck_p_1),\
.wck1_t_b(``S``_c1_sd_wck_p_1),\
.wck0_c_a(``S``_c0_sd_wck_n_0),\
.wck0_c_b(``S``_c1_sd_wck_n_0),\
.wck1_c_a(``S``_c0_sd_wck_n_1),\
.wck1_c_b(``S``_c1_sd_wck_n_1),\
.dq_a({``S``_c0_sd_dq_15,``S``_c0_sd_dq_14,``S``_c0_sd_dq_13,``S``_c0_sd_dq_12,\
                ``S``_c0_sd_dq_11,``S``_c0_sd_dq_10,``S``_c0_sd_dq_9, ``S``_c0_sd_dq_8,\
                ``S``_c0_sd_dq_7, ``S``_c0_sd_dq_6, ``S``_c0_sd_dq_5, ``S``_c0_sd_dq_4,\
                ``S``_c0_sd_dq_3, ``S``_c0_sd_dq_2, ``S``_c0_sd_dq_1, ``S``_c0_sd_dq_0}),\
.dbi_n_a({``S``_c0_sd_dbi_n_1,``S``_c0_sd_dbi_n_0}),\
.edc_a({``S``_c0_sd_edc_1,``S``_c0_sd_edc_0}),\
.dq_b({``S``_c1_sd_dq_15,``S``_c1_sd_dq_14,``S``_c1_sd_dq_13,``S``_c1_sd_dq_12,\
                ``S``_c1_sd_dq_11,``S``_c1_sd_dq_10,``S``_c1_sd_dq_9, ``S``_c1_sd_dq_8,\
                ``S``_c1_sd_dq_7, ``S``_c1_sd_dq_6, ``S``_c1_sd_dq_5, ``S``_c1_sd_dq_4,\
                ``S``_c1_sd_dq_3, ``S``_c1_sd_dq_2, ``S``_c1_sd_dq_1, ``S``_c1_sd_dq_0}),\
.dbi_n_b({``S``_c1_sd_dbi_n_1,``S``_c1_sd_dbi_n_0}),\
.edc_b({``S``_c1_sd_edc_1,``S``_c1_sd_edc_0}),\
.zq_a(1'b0),\
.zq_b(1'b0),\
.tms(1'b0),\
.tdi(1'b0),\
.tck(1'b0),\
.tdo()

`endif // INCLUDE_GDDR_MODEL_NAMES

