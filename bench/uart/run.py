"""VUnit test runner for the UART module."""
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
## @file    run.py
## @version 1.0
## @brief   This module sets up the VUnit test environment, adds necessary source files, and runs the tests for the
##          UART module.
## @author  Timothee Charrier
## @date    17/10/2025
## =====================================================================================================================

import sys
from pathlib import Path
from typing import Literal

from vunit import VUnit
from vunit.ui.library import Library
from vunit.ui.source import SourceFileList

# Add the directory containing the utils.py file to the Python path
sys.path.insert(0, str(object=(Path(__file__).parent.parent).resolve()))

from utils import generate_coverage_report_nvc, setup_ghdl, setup_modelsim, setup_nvc, setup_simulator

## =====================================================================================================================
# Set up the simulator environment
## =====================================================================================================================

VUNIT_SIMULATOR: Literal["nvc", "ghdl", "modelsim"] = setup_simulator()

## =====================================================================================================================
# Define paths and libraries
## =====================================================================================================================

SRC_ROOT: Path = Path(__file__).parent.parent.parent / "sources"
BENCH_ROOT: Path = Path(__file__).parent / "test"

# Define the libraries
src_library_name: str = "lib_rtl"
bench_library_name: str = "lib_bench"

## =====================================================================================================================
# Set up VUnit environment
## =====================================================================================================================

VU: VUnit = VUnit.from_argv()
VU.add_vhdl_builtins()
VU.add_verification_components()

# Add the source files to the library
LIB_SRC: Library = VU.add_library(library_name=src_library_name)
LIB_SRC.add_source_files(pattern=SRC_ROOT / "**" / "*.vhd")

# Add the test library
LIB_BENCH: SourceFileList = VU.add_library(library_name=bench_library_name)
LIB_BENCH.add_source_files(pattern=BENCH_ROOT / "*.vhd")

## =====================================================================================================================
# Configure compile and simulation options
## =====================================================================================================================

# Disable IEEE warnings at 0 ns
VU.set_sim_option(name="disable_ieee_warnings", value=True)

if VUNIT_SIMULATOR == "nvc":
    setup_nvc(VU)
elif VUNIT_SIMULATOR == "ghdl":
    setup_ghdl(VU)
elif VUNIT_SIMULATOR == "modelsim":
    setup_modelsim(VU)

VU.main(post_run=generate_coverage_report_nvc)
