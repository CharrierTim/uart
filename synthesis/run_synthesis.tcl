## =====================================================================================================================
##  MIT License
##
##  Copyright (c) 2025 Timothee Charrier
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
## @version 1.0
## @brief   Synthesis script for Vivado
## @author  Timothee Charrier
## @date    27/10/2025
## =====================================================================================================================


## =====================================================================================================================
# Variables
## =====================================================================================================================

# Names
set PROJECT_NAME    "uart"
set TOP_ENTITY      "TOP_FPGA"

# FPGA selection
set FPGA_PART       "xc7a35tcpg236-1"

# Target language and VHDL standard
set TARGET_LANGUAGE "VHDL"
set VHDL_STANDARD   "VHDL 2008"

# Paths - resolve to absolute paths before changing directory
set ROOT_DIR        [file normalize ".."]
set SOURCES_DIR     [file normalize "${ROOT_DIR}/sources"]
set PROJECT_DIR     [file normalize "./${PROJECT_NAME}"]
set CONSTRAINTS_DIR [file normalize "./constraints"]
set PINOUT_FILE     [file normalize "${CONSTRAINTS_DIR}/pinout.xdc"]
set TIMING_FILE     [file normalize "${CONSTRAINTS_DIR}/timing.xdc"]

## =====================================================================================================================
# Manual File and Library Specification
## =====================================================================================================================

# Define files with their libraries
# Format: {library_name file_path}
# Files are compiled in the order specified here

# Initialize empty list
set VHDL_FILES_WITH_LIBS {}

# Add files with their libraries (order matters for compilation)
lappend VHDL_FILES_WITH_LIBS [list lib_rtl "${SOURCES_DIR}/regfile/rtl/regfile_pkg.vhd"]
lappend VHDL_FILES_WITH_LIBS [list lib_rtl "${SOURCES_DIR}/resync/rtl/resync_slv.vhd"]
lappend VHDL_FILES_WITH_LIBS [list lib_rtl "${SOURCES_DIR}/regfile/rtl/regfile.vhd"]
lappend VHDL_FILES_WITH_LIBS [list lib_rtl "${SOURCES_DIR}/uart/rtl/uart_rx.vhd"]
lappend VHDL_FILES_WITH_LIBS [list lib_rtl "${SOURCES_DIR}/uart/rtl/uart_tx.vhd"]
lappend VHDL_FILES_WITH_LIBS [list lib_rtl "${SOURCES_DIR}/uart/rtl/uart.vhd"]
lappend VHDL_FILES_WITH_LIBS [list lib_rtl "${SOURCES_DIR}/top_fpga/rtl/top_fpga.vhd"]

puts ""
puts "================================================================================================================="
puts "File List Configuration"
puts "================================================================================================================="
puts ""
puts "Total files specified: [llength $VHDL_FILES_WITH_LIBS]"
puts ""
puts "Files and their libraries:"
foreach file_spec $VHDL_FILES_WITH_LIBS {
    set lib [lindex $file_spec 0]
    set file [lindex $file_spec 1]
    puts "  Library: [format "%-15s" $lib] File: $file"
}

## =====================================================================================================================
# Create Project
## =====================================================================================================================

puts ""
puts "================================================================================================================="
puts "Creating Vivado Project: $PROJECT_NAME"
puts "================================================================================================================="

# Close any open project
catch {close_project}

# Create project directory if it doesn't exist
file mkdir $PROJECT_DIR
cd         $PROJECT_DIR

# Create the project
create_project $PROJECT_NAME -part $FPGA_PART -force

# Set target language
set_property target_language $TARGET_LANGUAGE [current_project]

puts ""
puts "Project created successfully with $TARGET_LANGUAGE as target language"

## =====================================================================================================================
# Adding constraint files
## =====================================================================================================================

puts ""
puts "================================================================================================================="
puts "Adding constraint files"
puts "================================================================================================================="

if { [file exists $PINOUT_FILE] } {
    puts "Adding pinout file: $PINOUT_FILE"
    add_files -fileset constrs_1 $PINOUT_FILE
} else {
    puts "WARNING: Pinout file not found: $PINOUT_FILE"
}

if { [file exists $TIMING_FILE] } {
    puts "Adding timing file: $TIMING_FILE"
    add_files -fileset constrs_1 $TIMING_FILE
} else {
    puts "WARNING: Timing file not found: $TIMING_FILE"
}

## =====================================================================================================================
# Adding RTL files with library specification
## =====================================================================================================================

puts ""
puts "================================================================================================================="
puts "Adding RTL files to project with library assignments"
puts "================================================================================================================="

set file_count 0
foreach file_spec $VHDL_FILES_WITH_LIBS {
    set lib [lindex $file_spec 0]
    set file [lindex $file_spec 1]

    if { [file exists $file] } {
        puts "Adding file: [file tail $file] to library: $lib"
        add_files -fileset sources_1 $file

        # Set library property
        set file_obj [get_files $file]
        set_property library $lib $file_obj

        # Set VHDL 2008 standard
        set_property FILE_TYPE $VHDL_STANDARD $file_obj

        incr file_count
    } else {
        puts "ERROR: File not found: $file"
    }
}

puts ""
puts "Successfully added $file_count file(s) with library assignments"

## =====================================================================================================================
# Setting up Top Level
## =====================================================================================================================

puts ""
puts "================================================================================================================="
puts "Setting Top Level: $TOP_ENTITY"
puts "================================================================================================================="

set_property top $TOP_ENTITY [current_fileset]

## =====================================================================================================================
#  Get the git commit
## =====================================================================================================================

set git_hash [exec git log -1 --pretty='%h']
set GIT_ID $git_hash

set_property generic "G_GIT_ID=32'h$git_hash" [current_fileset]

puts ""
puts "================================================================================================================="
puts "Git commit hash: $GIT_ID"
puts "================================================================================================================="

puts ""
puts "================================================================================================================="
puts "Project setup complete!"
puts "================================================================================================================="
