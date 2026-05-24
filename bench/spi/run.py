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
## @version 2.4
## @brief   This module sets up the VUnit test environment, adds necessary source files, and runs the tests for the
##          SPI master module.
## @author  Timothee Charrier
## =====================================================================================================================
## REVISION HISTORY
##
## Version  Date        Author              Description
## -------  ----------  ------------------  ----------------------------------------------------------------------------
## 1.0      17/10/2025  Timothee Charrier   Initial release
## 2.0      12/01/2026  Timothee Charrier   Update entire interface
## 2.1      12/04/2026  Timothee Charrier   Add custom args and update paths
## 2.2      06/05/2026  Timothee Charrier   Add Questa or ModelSim support, fix `LIB_SRC` to `LIB_RTL`
## 2.3      14/05/2026  Timothee Charrier   Update results directory to be at the same level as the testbench directory
## 2.4      19/05/2026  Timothee Charrier   Improved `Simulator` class removing coverage flags from this file
##          23/05/2026  Timothee Charrier   Fix `post_run` callback that should be called regardless of coverage being
##                                          enabled or not for output results merge.
## =====================================================================================================================

import sys
from argparse import Namespace
from itertools import product
from pathlib import Path
from typing import Literal

from vunit import VUnit, VUnitCLI
from vunit.ui.library import Library
from vunit.ui.testbench import TestBench

sys.path.insert(0, str((Path(__file__).parent.parent).resolve()))

from setup_vunit import Simulator, select_simulator

## =====================================================================================================================
# Define paths
## =====================================================================================================================

THIS_DIR: Path = Path(__file__).resolve().parent
PRJ_ROOT: Path = THIS_DIR.parent.parent
SRC_ROOT: Path = PRJ_ROOT / "sources"
BENCH_ROOT: Path = THIS_DIR
MODELS_ROOT: Path = PRJ_ROOT / "bench" / "models"

## =====================================================================================================================
# Parse command line arguments
## =====================================================================================================================

cli = VUnitCLI()
cli.parser.add_argument("--coverage", action="store_true", help="Enable coverage collection and reporting")
cli.parser.add_argument("--ghdl", action="store_true", help="Use GHDL as the simulator")
cli.parser.add_argument("--modelsim", dest="questa", action="store_true", help="Use ModelSim/Questa as the simulator")
cli.parser.add_argument("--nvc", action="store_true", help="Use nvc as the simulator")
cli.parser.add_argument("--questa", dest="questa", action="store_true", help="Use Questa/ModelSim as the simulator")
args: Namespace = cli.parse_args()

## =====================================================================================================================
# Set up VUnit environment
## =====================================================================================================================

sim_name: Literal["nvc", "ghdl", "questa/modelsim"] | None = (
    "nvc" if args.nvc else "ghdl" if args.ghdl else "questa/modelsim" if args.questa else None
)
simulator: Simulator = select_simulator(name=sim_name, enable_coverage=args.coverage, run_file_dir=THIS_DIR)

VU: VUnit = VUnit.from_args(args=args)
VU.add_vhdl_builtins()
VU.add_verification_components()
VU.add_random()

# Add the source files to the library
LIB_RTL: Library = VU.add_library(library_name="lib_rtl")
LIB_RTL.add_source_files(pattern=SRC_ROOT / "spi" / "*.vhd")

# Add the test library
LIB_BENCH: Library = VU.add_library(library_name="lib_bench")
LIB_BENCH.add_source_files(pattern=BENCH_ROOT / "**" / "*.vhd")
LIB_BENCH.add_source_files(pattern=MODELS_ROOT / "**" / "*.vhd")

## =====================================================================================================================
# Set up simulator
## =====================================================================================================================

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


VU.main(post_run=simulator.post_run)
