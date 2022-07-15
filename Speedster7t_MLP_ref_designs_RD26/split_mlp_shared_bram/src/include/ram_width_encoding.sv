//
//  Copyright (c) 2020  Achronix Semiconductor Corp.
//  All Rights Reserved.
//
//
//  This software constitutes an unpublished work and contains
//  valuable proprietary information and trade secrets belonging
//  to Achronix Semiconductor Corp.
//
//  This software may not be used, copied, distributed or disclosed
//  without specific prior written authorization from
//  Achronix Semiconductor Corp.
//
//  The copyright notice above does not evidence any actual or intended
//  publication of such software.
//
// ----------------------------------------------------------------------
//  Description: Functions to map BRAM/LRAM read/write width to the encoding
//               used by the ACX_BRAM72K and ACX_MLP72 width parameters
//
// ----------------------------------------------------------------------

`ifndef ACX_RAM_WIDTH_ENCODING
`define ACX_RAM_WIDTH_ENCODING

  // Map bram width (4, 8, 9, 16, 18, 32, 36, 64, 72, 128, 144) and
  // byte_width (8 or 9) to code to be used with read_width and write_width
  // parameters of ACX_BRAM72K. Set noc_mode (with bram_width=64, byte_width=8)
  // to enable the special NOC mode.
  function bit [3:0] ACX_bram72k_width_code (
      integer bram_width,
      integer byte_width = 8,
      bit noc_mode = 0
  );
      automatic bit [3:0] bram_byte = {3'b000, (byte_width == 8)};
      return (noc_mode)?                        4'b1100 :
             (bram_width == 4)?                 4'b1011 :
             (bram_width == byte_width)?        4'b1000 | bram_byte :
             (bram_width == 2*byte_width)?      4'b0110 | bram_byte :
             (bram_width == 4*byte_width)?      4'b0100 | bram_byte :
             (bram_width == 64 || bram_width == 72)?   4'b0000 | bram_byte :
             (bram_width == 128 || bram_width == 144)? 4'b0010 | bram_byte :
                 /* invalid */                  4'b1111;
  endfunction: ACX_bram72k_width_code


  // Map LRAM width (36, 72, 144) to code to be used with lram_read_width
  // and lram_write_width parameters of ACX_MLP72.
  function bit [1:0] ACX_lram2k_width_code (
      integer lram_width
  );
      return (lram_width == 36)?  2'b01 :
             (lram_width == 144)? 2'b10 :
                         /* 72 */ 2'b00;
  endfunction: ACX_lram2k_width_code

`endif // ACX_RAM_WIDTH_ENCODING

