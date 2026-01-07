"""VUnit test runner for the SPI master module."""
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
## @version 2.0
## @brief   This module sets up the VUnit test environment, adds necessary source files, and runs the tests for the
##          SPI master module.
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
from itertools import product
from pathlib import Path

from vunit import VUnit, VUnitCLI
from vunit.ui.library import Library
from vunit.ui.testbench import TestBench

sys.path.insert(0, str(object=(Path(__file__).parent.parent).resolve()))

from setup_vunit import Simulator, select_simulator

## =====================================================================================================================
# Define paths
## =====================================================================================================================

SRC_ROOT: Path = Path(__file__).parent.parent.parent / "sources"
BENCH_ROOT: Path = Path(__file__).parent / "test"
MODEL_ROOT: Path = Path(__file__).parent.parent / "models" / "spi"
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
LIB_SRC.add_source_files(pattern=SRC_ROOT / "spi" / "*.vhd")

# Add the test library
LIB_BENCH: Library = VU.add_library(library_name="lib_bench")
LIB_BENCH.add_source_files(pattern=BENCH_ROOT / "*.vhd")
LIB_BENCH.add_source_files(pattern=MODEL_ROOT / "*.vhd")

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
# Set up test
## =====================================================================================================================


def generate_spi_tests(obj, cpol_values, cpha_values):
    """
    Generate test by varying the SPI clock polarity and phase generics.

    Args:
        obj: VUnit test bench or test case object
        cpol_values: List of clock polarity values ([0, 1])
        cpha_values: List of clock phase values    ([0, 1])
    """
    for cpol, cpha in product(cpol_values, cpha_values):
        # SPI Mode mapping: Mode 0 (CPOL=0,CPHA=0), Mode 1 (CPOL=0,CPHA=1),
        #                   Mode 2 (CPOL=1,CPHA=0), Mode 3 (CPOL=1,CPHA=1)
        spi_mode = cpol * 2 + cpha
        config_name = f"SPI_Mode_{spi_mode}_CPOL={cpol}_CPHA={cpha}"

        obj.add_config(name=config_name, generics={"G_CLK_POLARITY": f"'{cpol}'", "G_CLK_PHASE": f"'{cpha}'"})


TB_SPI: TestBench = LIB_BENCH.test_bench("tb_spi_master")

# Generate tests for all SPI modes (CPOL=0/1, CPHA=0/1)
generate_spi_tests(TB_SPI, cpol_values=[0, 1], cpha_values=[0, 1])

## =====================================================================================================================
# Run
## =====================================================================================================================

# Only set post_run callback if coverage is enabled
if args.coverage:
    VU.main(post_run=simulator.post_run)
else:
    VU.main()
