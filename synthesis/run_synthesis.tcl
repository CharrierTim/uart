## =====================================================================================================================
##  MIT License
##
##  Copyright (c) 2026 Timothee Charrier
##
##  Permission is hereby granted, free of charge, to any person obtaining a copy
##  of this software and associated documentation files (the "Software"), to deal
##  in the Software without restriction, including without limitation the rights
##  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
##  copies of the Software, and to permit persons to whom the Software is
##  furnished to do so, subject to the following conditions:
##
##  The above copyright notice and this permission notice shall be included in all
##  copies or substantial portions of the Software.
##
##  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
##  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
##  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
##  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
##  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
##  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
##  SOFTWARE.
## =====================================================================================================================
## @project uart
## @file    run_synthesis.tcl
## @version 1.2
## @brief   Synthesis script for Vivado
## @author  Timothee Charrier
## @date    27/10/2025
## =====================================================================================================================
## REVISION HISTORY
##
## Version  Date        Author              Description
## -------  ----------  ------------------  ----------------------------------------------------------------------------
## 1.0      27/10/2025  Timothee Charrier   Initial release
## 1.1      05/01/2026  Timothee Charrier   Add VGA controller file
## 1.2      08/01/2026  Timothee Charrier   Remove deprecated 'resync_slv" module and add open-logic library
## =====================================================================================================================


## =====================================================================================================================
# Variables
## =====================================================================================================================

# Names
set    PROJECT_NAME "uart"
set      TOP_ENTITY "TOP_FPGA"

# FPGA selection
set       FPGA_PART "xc7z020clg484-1"

# Target language and VHDL standard
set TARGET_LANGUAGE "VHDL"
set   VHDL_STANDARD "VHDL 2008"

# Paths
set     CURRENT_DIR [file normalize "."]
set        ROOT_DIR [file normalize ".."]
set       CORES_DIR [file normalize "${ROOT_DIR}/cores"]
set     SOURCES_DIR [file normalize "${ROOT_DIR}/sources"]
set     PROJECT_DIR [file normalize "./${PROJECT_NAME}"]
set CONSTRAINTS_DIR [file normalize "./constraints"]
set     RESULTS_DIR [file normalize "./results"]

# Constraint files
set     PINOUT_FILE [file normalize "${CONSTRAINTS_DIR}/pinout.xdc"]
set     TIMING_FILE [file normalize "${CONSTRAINTS_DIR}/timing.xdc"]

## =====================================================================================================================
# Create Project
## =====================================================================================================================

# Create project directory if it doesn't exist
file mkdir  $PROJECT_DIR
cd          $PROJECT_DIR

create_project -force $PROJECT_NAME $PROJECT_DIR -part $FPGA_PART

set_property target_language $TARGET_LANGUAGE [current_project]

## =====================================================================================================================
# Read IP cores
## =====================================================================================================================

set IP_XCI_FILE "${CORES_DIR}/pll/clk_wiz_0.xci"

if {[file exists $IP_XCI_FILE]} {
    # Import IP into project
    import_ip $IP_XCI_FILE

    puts "Imported IP core: $IP_XCI_FILE"

    set_property GENERATE_SYNTH_CHECKPOINT false [get_files clk_wiz_0.xci]

    # Generate all target files
    generate_target all [get_files clk_wiz_0.xci]
} else {
    puts "ERROR: IP XCI file does not exist: $IP_XCI_FILE"
}

## =====================================================================================================================
# Add open-logic sources
## =====================================================================================================================

source $CORES_DIR/open-logic/tools/vivado/import_sources.tcl

## =====================================================================================================================
# Read VHDL files
## =====================================================================================================================

set VHDL_SOURCES [list \
    [list lib_rtl "$SOURCES_DIR/regfile/regfile_pkg.vhd" 2008] \
    [list lib_rtl "$SOURCES_DIR/regfile/regfile.vhd"     2008] \
    [list lib_rtl "$SOURCES_DIR/vga/vga_controller.vhd"  2008] \
    [list lib_rtl "$SOURCES_DIR/uart/uart_rx.vhd"        2008] \
    [list lib_rtl "$SOURCES_DIR/uart/uart_tx.vhd"        2008] \
    [list lib_rtl "$SOURCES_DIR/uart/uart.vhd"           2008] \
    [list lib_rtl "$SOURCES_DIR/spi/spi_master.vhd"      2008] \
    [list lib_rtl "$SOURCES_DIR/top_fpga/top_fpga.vhd"   2008] \
]

foreach source $VHDL_SOURCES {
    lassign $source lib file std

    # Verify file exists before reading it
    if {![file exists $file]} {
        puts "ERROR: File does not exist: $file"
        continue
    }

    # Read VHDL file with specified standard
    read_vhdl -vhdl2008 $file

    # Set library property
    set_property library $lib [get_files [file tail $file]]
}

## =====================================================================================================================
# Getting GIT ID for internal registers
## =====================================================================================================================

set git_hash [exec git log -1 --pretty=%H]
set GIT_ID   [string range $git_hash 0 7]

set_property generic "G_GIT_ID=32'h$GIT_ID" [current_fileset]

## =====================================================================================================================
# Adding constraint
## =====================================================================================================================

proc add_constraint_file {xdc_file description} {
    if {![file exists $xdc_file]} {
        puts "ERROR: $description file does not exist: $xdc_file"
        return 0
    } else {
        read_xdc $xdc_file
        puts "Added $description constraints: $xdc_file"
        return 1
    }
}

add_constraint_file $PINOUT_FILE "pinout"
add_constraint_file $TIMING_FILE "timing"

## =====================================================================================================================
# Synthesis
## =====================================================================================================================

synth_design -top $TOP_ENTITY -part $FPGA_PART

# Create synthesis results directory if it doesn't exist
file mkdir "${RESULTS_DIR}/synth"

# Generate synthesis reports
report_timing_summary               -file "${RESULTS_DIR}/synth/${PROJECT_NAME}_timing_synth.rpt"
report_utilization    -hierarchical -file "${RESULTS_DIR}/synth/${PROJECT_NAME}_utilization_hierarchical_synth.rpt"
report_utilization                  -file "${RESULTS_DIR}/synth/${PROJECT_NAME}_utilization_synth.rpt"

# Optimize
opt_design -directive "default"

## =====================================================================================================================
# Implementation
## =====================================================================================================================

# Placement
place_design -directive "default"

# Create implementation results directory if it doesn't exist
file mkdir "${RESULTS_DIR}/impl"

# Generate placement reports
report_utilization       -hierarchical -file "${RESULTS_DIR}/impl/${PROJECT_NAME}_utilization_hierarchical_place.rpt"
report_utilization                     -file "${RESULTS_DIR}/impl/${PROJECT_NAME}_utilization_place.rpt"
report_io                              -file "${RESULTS_DIR}/impl/${PROJECT_NAME}_io.rpt"
report_control_sets      -verbose      -file "${RESULTS_DIR}/impl/${PROJECT_NAME}_control_sets.rpt"
report_clock_utilization               -file "${RESULTS_DIR}/impl/${PROJECT_NAME}_clock_utilization.rpt"

# Routing
route_design    -directive "default"
phys_opt_design -directive "default"

# Generate routing reports
report_timing_summary -no_header -no_detailed_paths
report_route_status                                 -file "${RESULTS_DIR}/impl/${PROJECT_NAME}_route_status.rpt"
report_drc                                          -file "${RESULTS_DIR}/impl/${PROJECT_NAME}_drc.rpt"
report_timing_summary -datasheet -max_paths 10      -file "${RESULTS_DIR}/impl/${PROJECT_NAME}_timing.rpt"
report_power                                        -file "${RESULTS_DIR}/impl/${PROJECT_NAME}_power.rpt"

## =====================================================================================================================
# Bitstream generation
## =====================================================================================================================

write_bitstream -force "${RESULTS_DIR}/${PROJECT_NAME}.bit"

## =====================================================================================================================
# Move the .log generated to the result folder
## =====================================================================================================================

# Verify file exists before moving it
if {![file exists $file]} {
    puts "ERROR: File does not exist: $file"
} else {
    file rename -force "$CURRENT_DIR/vivado.log" "$RESULTS_DIR/${PROJECT_NAME}.log"
}
