"""VUnit test runner for the Top-level module."""
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
##          UART modules.
## @author  Timothee Charrier
## @date    17/10/2025
## =====================================================================================================================
## REVISION HISTORY
##
## Version  Date        Author              Description
## -------  ----------  ------------------  ----------------------------------------------------------------------------
## 1.0      17/10/2025  Timothee Charrier   Initial release
## =====================================================================================================================

import sys
from pathlib import Path

from vunit import VUnit
from vunit.ui.library import Library

# Add the directory containing the utils. py file to the Python path
sys.path.insert(0, str(object=(Path(__file__).parent.parent).resolve()))

from setup_vunit import Simulator, select_simulator

## =====================================================================================================================
# Set up the simulator environment
## =====================================================================================================================

simulator: Simulator = select_simulator()

## =====================================================================================================================
# Define library paths
## =====================================================================================================================

SRC_ROOT: Path = Path(__file__).parent.parent.parent / "sources"
BENCH_ROOT: Path = Path(__file__).parent / "test"

## =====================================================================================================================
# Set up VUnit environment
## =====================================================================================================================

VU: VUnit = VUnit.from_argv()
VU.add_vhdl_builtins()
VU.add_verification_components()
VU.add_random()

# Add the source files to the library
LIB_SRC: Library = VU.add_library(library_name="lib_rtl")
LIB_SRC.add_source_files(pattern=SRC_ROOT / "uart" / "*.vhd")

# Add the test library
LIB_BENCH: Library = VU.add_library(library_name="lib_bench")
LIB_BENCH.add_source_files(pattern=BENCH_ROOT / "*.vhd")

## =====================================================================================================================
# Configure and run the simulation
## =====================================================================================================================

if VU.get_simulator_name() == "nvc":
    coverage_specs: list[str] = [
        "# NVC Coverage Specification File",
        "# Collect coverage only on RTL sources, exclude testbench and models",
        "",
        "# Enable coverage on main RTL library",
        "+hierarchy LIB_BENCH.TB_UART_TX.DUT.*",
        "+hierarchy LIB_BENCH.TB_UART_RX.DUT.*",
        "",
        "# Exclude testbench model",
        "-hierarchy LIB_BENCH.TB_UART_TX.INST_UART_SLAVE.*",
        "-hierarchy LIB_BENCH.TB_UART_RX.INST_UART_MASTER.*",
        "",
    ]
    simulator.setup_coverage(VU=VU, specifications=coverage_specs)
elif VU.get_simulator_name() == "ghdl":
    simulator.setup_coverage(VU=VU, libraries=(LIB_SRC, LIB_BENCH))

simulator.configure(VU=VU)

VU.main(post_run=simulator.post_run)
