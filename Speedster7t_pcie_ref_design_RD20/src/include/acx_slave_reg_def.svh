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
//     Author:   kevin.yuan@achronix.com
// ------------------------------------------------------------------
//-------------------------------------------------------------

//`define DATA_WIDTH 64

//`define REG_NAP_COL 5
//`define REG_NAP_ROW 6

//`define REG_BASE (42'h040_0000_1000+(`REG_NAP_COL<<31)+(`REG_NAP_ROW<<28))
`define REG_BASE 28'h0

// ----|-global_address-|----------|-base_address-|-offset-|-bounary-|

// a) 8 registers read/write

`define REG_CFG_0_ADDR             (`REG_BASE +     ( 0    <<  6))
`define REG_CFG_1_ADDR             (`REG_BASE +     ( 1    <<  6))
`define REG_CFG_2_ADDR             (`REG_BASE +     ( 2    <<  6))
`define REG_CFG_3_ADDR             (`REG_BASE +     ( 3    <<  6))
`define REG_CFG_4_ADDR             (`REG_BASE +     ( 4    <<  6))
`define REG_CFG_5_ADDR             (`REG_BASE +     ( 5    <<  6))
`define REG_CFG_6_ADDR             (`REG_BASE +     ( 6    <<  6))
`define REG_CFG_7_ADDR             (`REG_BASE +     ( 7    <<  6))

// b) 8 registers read only. They require a fixed known value, this can be their address + bias value, (such as
// 32'hdeadbeef)

`define REG_STA_0_ADDR             (`REG_BASE +     ( 8    <<  6))
`define REG_STA_1_ADDR             (`REG_BASE +     ( 9    <<  6))
`define REG_STA_2_ADDR             (`REG_BASE +     (10    <<  6))
`define REG_STA_3_ADDR             (`REG_BASE +     (11    <<  6))
`define REG_STA_4_ADDR             (`REG_BASE +     (12    <<  6))
`define REG_STA_5_ADDR             (`REG_BASE +     (13    <<  6))
`define REG_STA_6_ADDR             (`REG_BASE +     (14    <<  6))
`define REG_STA_7_ADDR             (`REG_BASE +     (15    <<  6))

// c) 2 counter registers. Up counter, down counter. For each counter register a control register that clears the
// counter, starts and stops it. In total 4 registers

`define REG_CNT_0_ADDR             (`REG_BASE +     (16    <<  6))
`define REG_CNT_CFG_0_ADDR         (`REG_BASE +     (17    <<  6))
`define REG_CNT_1_ADDR             (`REG_BASE +     (18    <<  6))
`define REG_CNT_CFG_1_ADDR         (`REG_BASE +     (19    <<  6))

// d) IRQ mimic register. Randomly set bits within this register, (use LSFR). Have IRQ clear register which when
// written to will clear the respective bit. Have IRQ master register which if any of the bits is set, will set it's
// master IRQ bit to 1, (effectively an OR of the IRQ bits). Total 3 registers

`define REG_IRQ_0_ADDR             (`REG_BASE +     (20    <<  6))
`define REG_IRQ_CFG_0_ADDR         (`REG_BASE +     (21    <<  6))
`define REG_IRQ_MASTER_ADDR        (`REG_BASE +     (22    <<  6))

// e) Clear on read register. Randomly set bits within this register. Bit to be cleared on read, so second read of
// register will clear the bit. Total 1 reg.

`define REG_CLEAR_ON_RD_ADDR       (`REG_BASE +     (23    <<  6)) // NOT implemented yet

// f) 4 off 64-bit registers, read/write. 

`define REG_CFG64_0_ADDR           (`REG_BASE +     (24    <<  6))
`define REG_CFG64_1_ADDR           (`REG_BASE +     (25    <<  6))
`define REG_CFG64_2_ADDR           (`REG_BASE +     (26    <<  6))
`define REG_CFG64_3_ADDR           (`REG_BASE +     (27    <<  6))

// Update me whenever a register is added/removed
`define N_REGS 28
