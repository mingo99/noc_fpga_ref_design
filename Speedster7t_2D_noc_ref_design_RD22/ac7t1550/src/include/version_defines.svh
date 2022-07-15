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
// File : Version defines specific to this design
//        This file can be automatically updated by the build Makefile flow so that 
//        the REVISON_CONTROL_VERSION is upto date in the build
//---------------------------------------------------------------------------------
`timescale 1ps/1ps

`ifndef INCLUDE_VERSION_DEFINES_SVH
`define INCLUDE_VERSION_DEFINES_SVH

`define ACX_MAJOR_VERSION 1
`define ACX_MINOR_VERSION 0
`define ACX_PATCH_VERSION 0
// Following will be overwritten whenever simulation or build make is run
`define REVISON_CONTROL_VERSION 012345


`endif // INCLUDE_VERSION_DEFINES_SVH

