"""VUnit test runner for the uart RX and TX modules."""
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
## 2.0      07/01/2026  Timothee Charrier   Update entire interface
## =====================================================================================================================

import sys
from argparse import Namespace
from pathlib import Path

from vunit import VUnit, VUnitCLI
from vunit.ui.library import Library

sys.path.insert(0, str(object=(Path(__file__).parent.parent).resolve()))

from setup_vunit import Simulator, select_simulator

## =====================================================================================================================
# Define paths
## =====================================================================================================================

SRC_ROOT: Path = Path(__file__).parent.parent.parent / "sources"
BENCH_ROOT: Path = Path(__file__).parent / "test"
COVERAGE_SPEC_PATH: Path = Path(__file__).parent / "coverage.spec"

## =====================================================================================================================
# Parse command line arguments with custom --coverage flag
## =====================================================================================================================

cli = VUnitCLI()
cli.parser.add_argument("--coverage", action="store_true", help="Enable coverage collection and reporting")
args: Namespace = cli.parse_args()

## =====================================================================================================================
# Set up VUnit environment
## =====================================================================================================================

VU: VUnit = VUnit.from_args(args=args)
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
# Configure simulation
## =====================================================================================================================

if args.coverage:
    LIB_SRC.set_compile_option(name="enable_coverage", value=True)
    LIB_BENCH.set_compile_option(name="enable_coverage", value=True)
    LIB_BENCH.set_sim_option(name="enable_coverage", value=True)
    LIB_BENCH.set_sim_option(name="nvc.elab_flags", value=[f"--cover-spec={COVERAGE_SPEC_PATH}"])

## =====================================================================================================================
# Set up simulator
## =====================================================================================================================

simulator: Simulator = select_simulator(enable_coverage=args.coverage)
simulator.attach(VU).configure()

## =====================================================================================================================
# Run
## =====================================================================================================================

# Only set post_run callback if coverage is enabled
if args.coverage:
    VU.main(post_run=simulator.post_run)
else:
    VU.main()
