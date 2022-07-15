Matrix-vector multiplier, (256x256) matrix times (256x1) vector.

Uses 8 BRAMs + 8 MLPs.

See doc/ directory for details.


filelist.tcl: one mvm (8 MLP, 8 BRAM)
filelist_nap.tcl: one mvm + NAP for matrix (8 MLP, 8 BRAM, 1 NAP)
filelist_4.tcl: 4 mvm + 1 NAP for matrices (32 MLP, 32 BRAM, 1 NAP)
