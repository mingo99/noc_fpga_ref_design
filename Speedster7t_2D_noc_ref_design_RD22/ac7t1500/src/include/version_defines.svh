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

/*
    Version Date        Author  Description
    0.1     12.1.21     SNL     Build for rev0 card. Add debug to column only.
    0.1.4   12.3.21     SNL     Fix xact_done being asserted when no AXI packets sent.
    0.1.13  12.16.21    SNL     Raise NoC to 1.5GHz and clocks to 400/410.  Build with 8.6.1 latest. Works
    1.1.0   12.16.21    SNL     Move back to rev1
    1.2.0   12.16.21    SNL     Tidy up, remove rev0 code, turn off snapshot
    1.3.0   12.16.21    SNL     Restore original H & V NAP positions to use full row and column
    1.4.0   02.04.22    SNL     Build with latest updates to common files
*/

`define ACX_MAJOR_VERSION 1
`define ACX_MINOR_VERSION 4
`define ACX_PATCH_VERSION 0
// Following will be overwritten whenever simulation or build make is run
`define REVISON_CONTROL_VERSION 293470


`endif // INCLUDE_VERSION_DEFINES_SVH

