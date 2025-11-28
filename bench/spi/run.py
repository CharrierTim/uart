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
##          Top-level module.
## @author  Timothee Charrier
## @date    17/10/2025
## =====================================================================================================================

import sys
from itertools import product
from pathlib import Path

from vunit import VUnit
from vunit.ui.library import Library
from vunit.ui.testbench import TestBench

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
MODEL_ROOT: Path = Path(__file__).parent.parent / "models" / "spi"

## =====================================================================================================================
# Set up VUnit environment
## =====================================================================================================================

VU: VUnit = VUnit.from_argv()
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
# Configure and run the simulation
## =====================================================================================================================

if VU.get_simulator_name() == "nvc":
    coverage_specs: list[str] = [
        "# NVC Coverage Specification File",
        "# Collect coverage only on RTL sources, exclude testbench and models",
        "",
        "# Enable coverage on main RTL library",
        "+hierarchy LIB_BENCH.TB_SPI.DUT.*",
        "",
        "# Exclude testbench model",
        "-hierarchy LIB_BENCH.TB_SPI_MASTER.INST_SPI_SLAVE_MODEL.*",
        "",
    ]
    simulator.setup_coverage(VU=VU, specifications=coverage_specs)
elif VU.get_simulator_name() == "ghdl":
    simulator.setup_coverage(VU=VU, libraries=(LIB_SRC, LIB_BENCH))

simulator.configure(VU=VU)


def generate_spi_tests(obj, cpol_values, cpha_values):
    """
    Generate test by varying the SPI clock polarity and phase generics.

    Args:
        obj: VUnit test bench or test case object
        cpol_values: List of clock polarity values (typically [0, 1])
        cpha_values: List of clock phase values (typically [0, 1])
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

VU.main(post_run=simulator.post_run)
