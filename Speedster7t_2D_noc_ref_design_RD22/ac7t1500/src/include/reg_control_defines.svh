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
//

//---------------------------------------------------------------------------------
// File : Register Control block defines
//---------------------------------------------------------------------------------
`timescale 1ps/1ps

`ifndef INCLUDE_REG_CONTROL_DEFINES_SVH
`define INCLUDE_REG_CONTROL_DEFINES_SVH

// Default user register size is 32 bits
typedef logic [31:0] t_ACX_USER_REG;
typedef logic [27:0] t_ACX_USER_REG_AXI_ADDR;

`endif // INCLUDE_REG_CONTROL_DEFINES_SVH

