# ------------------------------------------------------------------
#
# Copyright (c) 2019  Achronix Semiconductor Corp.
# All Rights Reserved.
#
#
# This software constitutes an unpublished work and contains
# valuable proprietary information and trade secrets belonging
# to Achronix Semiconductor Corp.
#
# This software may not be used, copied, distributed or disclosed
# without specific prior written authorization from
# Achronix Semiconductor Corp.
#
# The copyright notice above does not evidence any actual or intended
# publication of such software.
#
# ------------------------------------------------------------------
# Octave 2D convolution flow
# Debug matrix generation
# ------------------------------------------------------------------

# For help, at the prompt either
# > help <topic>
# or to get it in the doc viewer
# > doc <topic>

# Clear everything
clc
clear all

# -------------------------------------
# Define filenames
# -------------------------------------
input_nap_filename   = "nap_in.txt";
kernel_filename      = "kernel.txt";
output_nap_filename  = "nap_out.txt";
input_image_filename = "test_227x227.png";

# -------------------------------------
# Define memory map
# -------------------------------------
# Memory sizes are divided by 32 as that is the width of each entry
# This is set by the AXI_DATA_WIDTH
# As readmemh will place consecutive lines in the n+1 address, our
# addressing has to be based on 1 address = 32 bytes
kernel_mem_size          = 0x1000/32;
input_image_mem_location = 0x40000
image_line_mem_size      = 0x1000/32;

# -------------------------------------
# Define stride for convolution
# -------------------------------------
stride = 4;

# -------------------------------------
# If TEST_MATRIX is defined, then the input image
# and kernels are only defined for layer 1.
# Layers 2 & 3 are set to 0.  This mode is useful
# to aid RTL debug of signals through the design
# -------------------------------------
TEST_MATRIX = 0;

# -------------------------------------
# Input image size
# Note, rows & cols are functions and so reserved names
# -------------------------------------

if ( TEST_MATRIX == 1 )
    # This will create a dummy matrix with incrementing pixel values in one layer
    irows = 227;
    icols = 227;

    # Test matrix
    # Populate with effectively pixel number, which wraps as an 8 bit value
    # Used to track pixels through the data flow
    # Create zero version first, limit to uint8
    # First dimension is rows.

    M = zeros(irows,icols, "uint8");

    # Now populate just one layer
    for row = 1:irows
        for col = 1:icols
            M(row,col) = rem( (((row-1)*irows)+col), 256 );
        endfor
    endfor

    # printf("-------\nInput\n-------\n");
    # disp(M);

    # Need to pad line length to multiple of 4 as we store each pixel in groups of 4
    pad_columns = 0;
    if (rem(icols,4) == 0)
        pad_columns = 0;
    else
        pad_columns = (4 - rem(icols,4));
    endif

    # Create a padding vector
    PM = zeros(irows,pad_columns);

    # Append horizontally to current matrix
    N = [M, PM];

    # disp(N);

    # Write this out
    # Because save function does columns then rows, we want the transpose of that
    T = N';

    # disp(T)

    # Uncomment if a raw copy of the matrix is required
    save -text "conv_2D_test_matrix.txt" T

else

    # Read in a full image, with all 3 layers

    # Read our image
    # It will already be in uint8 format
    M = imread(input_image_filename);
    printf("Image read.  Dims = %i H = %i V = %i\n", ndims(M), rows(M), columns(M) );
    irows = rows(M);
    icols = columns(M);

    # Don't save to file, have a png file as input already

    # Need to pad line length to multiple of 4 as we store each pixel in groups of 4
    pad_columns = 0;
    if (rem(icols,4) == 0)
        pad_columns = 0;
    else
        pad_columns = (4 - rem(icols,4));
    endif

    # Create a padding vector
    PM = zeros(irows,pad_columns,3);

    # Append horizontally to current matrix
    N = [M, PM];

    # Need to cast to 32 bit value to allow for calculation of adding all 3 pixels together
    N32 = cast(N, "uint32");

    T = zeros(rows(N),columns(N), "uint32");

    # Need a vector so the image data can be written to the nap_in file
    # Each word of the vector needs to be 3 bytes, (one byte per layer)
    # T needed to be the transpose of N when using the vector to write the memory file
    # as the vector stacks columns first.  Now we write the file using row, col do not transpose
    for row = 1:rows(N)
        for col = 1:columns(N)
            T(row,col) = (N32(row,col,1) * 0x10000) + (N32(row,col,2) * 0x100) + N32(row,col,3);
        endfor
    endfor
    

endif


#------------------------------------
# Calculate Kernel matrix
#------------------------------------
krows = 11;
kcols = 11;
# K = zeros(krows,kcols,3, "uint8");

# Create random matrix
# Values will be between 0 & 1.
K = rand(krows,kcols,3);
# Scale
SK = sum(K(:));
disp(SK);
# Scale kernel, ensure all values are under 0xff
K = K * (0x8000/SK);
K = floor(K);
#SKF = sum(KF(:));
#disp(SKF);

# Check kernel values are in range
if ( max(K) >= 0xff )
    error("ERROR - kernel out of range = %i", max(K));
endif

printf("-------\nKernel\n-------\n");
disp(K);


# Again need to pad to multiples of 4 wide
if (rem(kcols,4) == 0)
    pad_kcol = 0;
else
    pad_kcol = (4 - rem(kcols,4));
endif

# Create a padding vector
if ( TEST_MATRIX == 1 )
    PK = zeros(krows,pad_kcol);
else
    PK = zeros(krows,pad_kcol,3);
endif

# PK(:) = 255;

# Append horizontally to current matrix
L = [K, PK];

# disp(L);

# Create vector, and transpose
if ( TEST_MATRIX == 1 )
    W = vec(L');
else
    L32 = cast(L, "uint32");
    for row = 1:rows(L)
        for col = 1:columns(L)
            W32(row,col) = (L32(row,col,1) * 0x10000) + (L32(row,col,2) * 0x100) + L32(row,col,3);
        endfor
    endfor
    W = vec(W32');
endif

#------------------------------------
# Calculate Second Kernel matrix
#------------------------------------
krows = 11;
kcols = 11;
#K = zeros(krows,kcols, "uint8");

# Create random matrix
if ( TEST_MATRIX == 1 )
    K2 = rand(krows,kcols);
else
    K2 = rand(krows,kcols,3);
endif

# Scale
SK2 = sum(K2(:));
disp(SK2);
# Scale kernel, ensure all values are under 0xff
K2 = K2 * (0x8000/SK2);
K2 = floor(K2);
#SKF2 = sum(KF2(:));
#disp(SKF2);

printf("-------\nKernel 2\n-------\n");
disp(K2);

# Check kernel values are in range
if ( max(K2) >= 0xff )
    error("ERROR - kernel out of range = %i", max(K2));
endif

# Again need to pad to multiples of 4 wide
if (rem(kcols,4) == 0)
    pad_kcol = 0;
else
    pad_kcol = (4 - rem(kcols,4));
endif

# Create a padding vector
if ( TEST_MATRIX == 1 )
    PK2 = zeros(krows,pad_kcol);
else
    PK2 = zeros(krows,pad_kcol,3);
endif

# PK2(:) = 255;

# Append horizontally to current matrix
L2 = [K2, PK2];

# disp(L2);

# Create vector, and transpose
if ( TEST_MATRIX == 1 )
    W2 = vec(L2');
else
    L32 = cast(L2, "uint32");
    for row = 1:rows(L)
        for col = 1:columns(L)
            W32(row,col) = (L32(row,col,1) * 0x10000) + (L32(row,col,2) * 0x100) + L32(row,col,3);
        endfor
    endfor
    W2 = vec(W32');
endif

#------------------------------------
# Write image hex file and Kernel files
#------------------------------------

# BRAM is 72 bytes wide, read out as 144, (18 bytes)
# For one line of matrix 12 bytes needed
# Write as 6 bytes per location, (2 values), with 3 bytes of padding.
# MLP dot product construct, does input words as 64 + 64.  Therefore top
# byte of first word is 0x00, to match the gap between 72 and 74.

foutk = fopen( kernel_filename, "w" );
foutm = fopen( input_nap_filename, "w" );

fprintf( foutm, "// Readmemh file.  Test input image\n");

# Require 60 kernels, as we have two separate kernels, write 60/2 - 1.
for kr = 0:29

    # Kernel 1
    # Write address 
    fprintf( foutk, "// Readmemh file.  Kernel %i\n", (kr * 2));
    fprintf( foutm, "@%04x\n", ((kr*2)*kernel_mem_size) );

    # Write each line.  4 values spread across two memory locations
    for row = 1:4:length(W)
        # Kernel file
        fprintf( foutk, "00%04x%06x%06x\n", bitand(W(row+2), 0xffff),W(row+1),W(row));
        fprintf( foutk, "0000000000%06x%02x\n", W(row+3), bitshift(W(row+2),-16));
        # Image file
        fprintf( foutm, "00%04x%06x%06x\n", bitand(W(row+2), 0xffff),W(row+1),W(row));
        fprintf( foutm, "0000000000%06x%02x\n", W(row+3), bitshift(W(row+2),-16));
    endfor

    # Write address 
    fprintf( foutm, "@%04x\n", (((kr*2)+1)*kernel_mem_size) );

    # Kernel 2
    fprintf( foutk, "// Readmemh file.  Kernel %i\n", ((kr*2)+1));
    # Write each line.  4 values spread across two memory locations
    for row = 1:4:length(W2)
        # Kernel file
        fprintf( foutk, "00%04x%06x%06x\n", bitand(W2(row+2), 0xffff),W2(row+1),W2(row));
        fprintf( foutk, "0000000000%06x%02x\n", W2(row+3), bitshift(W2(row+2),-16));
        # Image file
        fprintf( foutm, "00%04x%06x%06x\n", bitand(W2(row+2), 0xffff),W2(row+1),W2(row));
        fprintf( foutm, "0000000000%06x%02x\n", W2(row+3), bitshift(W2(row+2),-16));
    endfor

endfor

fprintf( foutk, "// end\n");
fclose( foutk );

# Image
# Write each line.
# As GDDR can only read a row, before needing a new burst, fit image into rows
# Also the image is read line by line.  So fit one line per row.
# Note that a row, (page size) is 2kB.  An image line is 227x3=681B.
# Could fit 3 image lines per row, but that would cause complexity for reading
# As plenty of GDDR space, use one row per line

# printf("T rows %d cols %d\n", rows(T), columns(T));

# In each line of memory place 12 bytes, 4 pixels * 3 layers
for row = 1:rows(T)
    # Write address of input image
    fprintf( foutm, "@%08x\n", (input_image_mem_location+((row-1)*image_line_mem_size)) );
    # Create a vector from the selected column
    V = vec(T(row,:));
    for pix = 1:4:length(V)
        # Need 4 words, (12 bytes), per memory location
        fprintf( foutm, "%06x%06x%06x%06x\n", V(pix+3),V(pix+2),V(pix+1),V(pix));
    endfor
endfor



fprintf( foutm, "// end\n");
fclose( foutm );

#------------------------------------
# Calculate result
#------------------------------------
# Do convolution
# Valid will limit size to that which matrix can fit in.
# So is correct size if stride = 1
# R = conv2(M,K);
if ( TEST_MATRIX == 1 )
    R  = convn(M,rot90(K,2),'valid');
    R2 = convn(M,rot90(K2,2),'valid');
else
    # Convolve each layer
    Rr  = convn(M(:,:,1),rot90(K(:,:,1),2),'valid');
    Rr2 = convn(M(:,:,1),rot90(K2(:,:,1),2),'valid');
    Rb  = convn(M(:,:,2),rot90(K(:,:,2),2),'valid');
    Rb2 = convn(M(:,:,2),rot90(K2(:,:,2),2),'valid');
    Rg  = convn(M(:,:,3),rot90(K(:,:,3),2),'valid');
    Rg2 = convn(M(:,:,3),rot90(K2(:,:,3),2),'valid');
    
    # Add sum of layers
    R  = Rr + Rb + Rg;
    R2 = Rr2 + Rb2 + Rg2;

    # Debug    
    # save -text "Rr.txt" Rr
    # save -text "Rb.txt" Rb
    # save -text "Rg.txt" Rg
    # save -text "R.txt" R

endif

#printf("-------\nFull Result 1\n-------\n");
#disp(R);
#printf("-------\nFull Result 2\n-------\n");
#disp(R2);

# R and R2 are same size so calculate once
[rrows, rcols] = size(R);

# Cannot find a function to reduce, for when doing strides, so do manually.
# Do transpose at the same time
for row = 1:((rrows/stride)+1)
    for col = 1:((rcols/stride)+1)
        O(row,col)  = R ( (((col-1)*stride)+1), (((row-1)*stride)+1) );
        O2(row,col) = R2( (((col-1)*stride)+1), (((row-1)*stride)+1) );
    endfor
endfor

#printf("-------\nResult after strides - Kernel 1\n-------\n");
#disp(O);
#printf("-------\nResult after strides - Kernel 2\n-------\n");
#disp(O2);

# Create vector, (result already transposed)
OV  = vec(O);
OV2 = vec(O2);

# Check the output vectors are in range.  They must be below 2^24
if ( (max(OV) > 0xffffff) || (max(OV2) > 0xffffff) )
    error("ERROR - Output vector out of range = %i : %i", max(OV), max(OV2));
endif

#------------------------------------
# Output validation file
#------------------------------------
fout = fopen( output_nap_filename, "w" );
fprintf( fout, "// Readmemh file.  Check results\n");
# Write each line.  Write as 16 bit, dropping bottom byte
for row = 1:length(OV)
    for col = 1:6  # Only 12 MLPs in some columns
        fprintf( fout, "%04x%04x", bitshift( bitand(OV2(row), 0x00ffff00), -8), bitshift( bitand(OV(row), 0x00ffff00), -8) );
    endfor
    fprintf( fout, "\n");
endfor

fprintf( fout, "// end\n");
fclose( fout );

