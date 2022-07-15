# ---------------------------------------------------------------------
#
# Copyright (c) 2020  Achronix Semiconductor Corp.
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
#
# ---------------------------------------------------------------------
# Description : Place and route reference design makefile
# ---------------------------------------------------------------------

# Set variant.  Two forms, a single cluster version, (b60)
# and 40 instances of the same that fills the die (b60x40)
VARIANT := b60

# Top level module dependant upon variant chosen
# b60 top level
# b60x40 top level
ifeq ($(VARIANT), b60)
    TOP_LEVEL_MODULE := mlp_conv2d_top
else
    TOP_LEVEL_MODULE := mlp_conv2d_top_chip
endif

# Set path to /src directory relative to this file
SRC_DIR := ../src


#------------------------------------------------------------
# Set filelist name. Path relative to the generated results directory
#------------------------------------------------------------
FILELIST_NAME := ../../../src/filelist_$(VARIANT).tcl

#------------------------------------------------------------
# Following variables define the device and technology
#------------------------------------------------------------
TECHNOLOGY := "AchronixSpeedster7t"

# ------------------------------
# If targeting Speedster7t 7t1500 device, enable the lines below
# If using a Speedcore, disable this section
# ------------------------------
DEVICE     := "AC7t1500ES0"
DEVICE_ACE := $(DEVICE)
PACKAGE    := "F53A0"

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

#------------------------------------------------------------
# Set output directory base
#------------------------------------------------------------
OUTDIR := results_$(VARIANT)

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
# Pattern rules
# ---------------------------------------------------------------------

# The % matches the project names and makes this a pattern rule
# ACE will always generate a timing_routed file, make this file dependent upon the input netlist
$(ACE_BUILD_DIR)/$(IMPL_DIR)/reports/$(TOP_LEVEL_MODULE)_timing_routed*.html : $(SYN_BUILD_DIR)/$(REV_DIR)/$(TOP_LEVEL_MODULE).vm | make_dirs
	@(if [ -d "$(ACE_BUILD_DIR)" ] ; then \
	    cd $(ACE_BUILD_DIR) ;\
	    ace -batch -script_file ../../../scripts/create_ace_project.tcl -script_args "$(TOP_LEVEL_MODULE) $(FILELIST_NAME) $(REV_DIR) $(IMPL_DIR) $(DEVICE_ACE) $(SPEED_GRADE) $(MULTIPROCESS) $(PARALLEL_JOBS)" ;\
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
# Makefile default
# ---------------------------------------------------------------------
all : run

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

