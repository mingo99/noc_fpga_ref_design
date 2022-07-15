# ---------------------------------------------------------------------
#
# Copyright (c) 2021 Achronix Semiconductor Corp.
# All Rights Reserved.
#
# This Software constitutes an unpublished work and contains
# valuable proprietary information and trade secrets belonging
# to Achronix Semiconductor Corp.
#
# Permission is hereby granted to use this Software including
# without limitation the right to copy, modify, merge or distribute
# copies of the software subject to the following condition:
#
# The above copyright notice and this permission notice shall
# be included in in all copies of the Software.
#
# The Software is provided “as is” without warranty of any kind
# expressed or implied, including  but not limited to the warranties
# of merchantability fitness for a particular purpose and non-infringement.
# In no event shall the copyright holder be liable for any claim,
# damages, or other liability for any damages or other liability,
# whether an action of contract, tort or otherwise, arising from, 
# out of, or in connection with the Software
#
#
# ---------------------------------------------------------------------
# Description : Place and route reference design makefile
# ---------------------------------------------------------------------

# Define the top level module
TOP_LEVEL_MODULE := noc_2d_ref_design_top

# Set path to /src directory relative to this file
SRC_DIR := ../src
# Set filelist name. Path relative to the generated results directory
FILELIST_NAME := ../../../src/filelist.tcl

# Set whether to generate ioring files
# Options are yes, no and only.  Note that "only" is the same as running make ioring_only
GENERATE_IORING := "no"

#------------------------------------------------------------
# Following variables define the device and technology
#------------------------------------------------------------
TECHNOLOGY := "AchronixSpeedster7t"

# ------------------------------
# If targeting Speedster7t 7t1500 device, enable the lines below
# If using a Speedcore, disable this section
# ------------------------------
DEVICE     := "AC7t1550"
#DEVICE_ACE := $(DEVICE)
DEVICE_ACE := "AC7t1550ES0"
PACKAGE    := "F53"

# ------------------------------
# If targeting a Speedcore device, enable this section
# and disable the section above
# Note : Speedcore devices do not have the hard interface
# IP, nor do they contain the NOC or NAPs.
# ------------------------------
# DEVICE     := "AC7tFSC04A500"
## ACE requires the R1 suffix on a Speedcore device
# DEVICE_ACE := "${DEVICE}R1"
# PACKAGE    := "CORE"

# ------------------------------
# Set desired Speed Grade
# ------------------------------
SPEED_GRADE := "C2"

# -------------------------------------------------------
# Set number of parallel jobs if multiprocess is selected
# -------------------------------------------------------
PARALLEL_JOBS := 4

# ------------------------------
# Set output directory base
# ------------------------------
OUTDIR := results

# ---------------------------------------------------------------------
# Should not need to edit below here
# ---------------------------------------------------------------------

# Dervied directory names
ACE_BUILD_DIR := $(OUTDIR)/ace
SYN_BUILD_DIR := $(OUTDIR)/syn

# Following variables define the build environment, and should not need to be changed
REV_DIR  := rev_1
IMPL_DIR := impl_1

# ---------------------------------------------------------------------
# Makefile default, full run with generation of ioring files
# ---------------------------------------------------------------------
all :
	$(MAKE) run GENERATE_IORING=yes

# ---------------------------------------------------------------------
# Pattern rules
# ---------------------------------------------------------------------

# The % matches the project names and makes this a pattern rule
# ACE will always generate a timing_routed file, make this file dependent upon the input netlist
$(ACE_BUILD_DIR)/$(IMPL_DIR)/reports/$(TOP_LEVEL_MODULE)_timing_routed*.html : $(SYN_BUILD_DIR)/$(REV_DIR)/$(TOP_LEVEL_MODULE).vm | make_dirs
	@(if [ -d "$(ACE_BUILD_DIR)" ] ; then \
	    cd $(ACE_BUILD_DIR) ;\
	    ace -batch -script_file ../../../scripts/create_ace_project.tcl -script_args "$(TOP_LEVEL_MODULE) $(FILELIST_NAME) $(REV_DIR) $(IMPL_DIR) $(DEVICE_ACE) $(SPEED_GRADE) $(MULTIPROCESS) $(PARALLEL_JOBS) $(GENERATE_IORING)" ;\
	else \
	    echo "ERROR - failed to run ACE" \
	    echo "No such directory $(ACE_BUILD_DIR)" ;\
	fi ;\
	)

# Synthesis output is dependent upon source files
$(SYN_BUILD_DIR)/$(REV_DIR)/$(TOP_LEVEL_MODULE).vm : $(SRC_DIR)/rtl/*.v $(SRC_DIR)/rtl/*.sv $(SRC_DIR)/constraints/*.sdc | make_dirs
	@(if [ -d "$(SYN_BUILD_DIR)" ] ; then \
	    cd $(SYN_BUILD_DIR) ;\
	    synplify_pro -batch ../../../scripts/create_synth_project.tcl $(TOP_LEVEL_MODULE) $(FILELIST_NAME) $(REV_DIR) $(TECHNOLOGY) $(DEVICE) $(SPEED_GRADE) $(PACKAGE) ;\
	else \
	    echo "ERROR - failed to run Synplify Pro" \
	    echo "No such directory ./$(SYN_BUILD_DIR)" ;\
	fi ;\
	)

# ---------------------------------------------------------------------
# Individual rules to build each flow of the full test
# ---------------------------------------------------------------------

# Do place and route using ACE.  Makes use of the file pattern rule above
.PHONY : pnr
pnr : $(ACE_BUILD_DIR)/$(IMPL_DIR)/reports/$(TOP_LEVEL_MODULE)_timing_routed*.html


# Run synthesis
.PHONY : synthesis
synthesis : $(SYN_BUILD_DIR)/$(REV_DIR)/$(TOP_LEVEL_MODULE).vm

# By default, multiprocess is turned off
MULTIPROCESS = 0

# ---------------------------------------------------------------------
# Default flow.
# ---------------------------------------------------------------------
run : synthesis pnr

# ---------------------------------------------------------------------
# Default flow with multiprocess
# ---------------------------------------------------------------------
run_mp : 
	$(MAKE) run MULTIPROCESS=1

# ---------------------------------------------------------------------
# Only generate ioring files
# ---------------------------------------------------------------------
ioring_only : make_dirs
	@(if [ -d "$(ACE_BUILD_DIR)" ] ; then \
	    cd $(ACE_BUILD_DIR) ;\
	    ace -batch -script_file ../../../scripts/create_ace_project.tcl -script_args "$(TOP_LEVEL_MODULE) $(FILELIST_NAME) $(REV_DIR) $(IMPL_DIR) $(DEVICE_ACE) $(SPEED_GRADE) $(MULTIPROCESS) $(PARALLEL_JOBS) only" ;\
	else \
	    echo "ERROR - failed to run ACE" \
	    echo "No such directory $(ACE_BUILD_DIR)" ;\
	fi ;\
	)


# ---------------------------------------------------------------------
# Synthesis only
# ---------------------------------------------------------------------
syn_only : synthesis

# ---------------------------------------------------------------------
# Place and route only
# ---------------------------------------------------------------------
pnr_only : pnr

make_dirs :
	@if [ ! -d "$(OUTDIR)" ] ; then mkdir $(OUTDIR); fi;
	@cd $(OUTDIR); if [ ! -d ace ] ; then mkdir ace; fi;
	@cd $(OUTDIR); if [ ! -d syn ] ; then mkdir syn; fi;

clean:
	@rm -rf $(OUTDIR)

