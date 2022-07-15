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
// Description : Read matrix from file
// ------------------------------------------------------------------


// Matrix type
class matrix #(
    parameter  string  name = "",
    parameter  integer int_width = 8,
    parameter  integer num_rows = 1,
    parameter  integer num_cols = 1
);
  logic signed [int_width-1 : 0] val[num_rows-1 : 0][num_cols-1 : 0];

  // Read matrix from file. If no file_nm specified, initialize with 0 elements
  function new (
      input string file_nm
  );
    if (file_nm == "")
      begin
        integer r, c;
        for (r = 0; r < num_rows; r = r + 1)
            for (c = 0; c < num_cols; c = c + 1)
                val[r][c] = {int_width {1'b0}};
      end
    else
      begin
        $readmemh(file_nm, val);
        if (val[0][0] === {int_width {1'bx}})
          begin
            $error("%s: file %s not found (or file contains 'x' data)", name, file_nm);
            $finish;
          end
      end
  endfunction

  // Print the matrix
  task show ();
    integer r, c;
    $display("matrix %s: %0dx%0d", name, num_rows, num_cols);
    for (r = 0; r < num_rows; r = r + 1)
      begin
        $write("[%3d] ", r);
        for (c = 0; c < num_cols; c = c + 1)
          begin
            if (c > 0 && c % 32 == 0)
                $write("\n      ");
            else if (c > 0 && c % 8 == 0)
                $write(" ");
            $write("%02h ", val[r][c]);
          end
        $write("\n");
      end
    $display("");
  endtask: show

endclass: matrix


                                
