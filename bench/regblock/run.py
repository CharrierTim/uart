"""VUnit test runner for the regblock module."""
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
##          CSR regblock module.
## @author  Timothee Charrier
## =====================================================================================================================
## REVISION HISTORY
##
## Version  Date        Author              Description
## -------  ----------  ------------------  ----------------------------------------------------------------------------
## 1.0      17/10/2025  Timothee Charrier   Initial release
## 2.0      29/07/2026  Timothee Charrier   Apply changes from `setup_vunit.py` to improve portability.
##                                          Add new common library `common`.
## =====================================================================================================================

import sys
from pathlib import Path

from vunit.ui.library import Library

sys.path.insert(0, str((Path(__file__).parent.parent).resolve()))

from setup_vunit import create_vunit, create_vunit_cli

## =====================================================================================================================
# Define paths
## =====================================================================================================================

THIS_DIR: Path = Path(__file__).resolve().parent
PRJ_ROOT: Path = THIS_DIR.parent.parent
SRC_ROOT: Path = PRJ_ROOT / "sources"
CORES_ROOT: Path = PRJ_ROOT / "cores"
BENCH_ROOT: Path = THIS_DIR
COMMON_ROOT: Path = THIS_DIR.parent / "common"

## =====================================================================================================================
# Parse command line arguments
## =====================================================================================================================

cli = create_vunit_cli()
args = cli.parse_args()

## =====================================================================================================================
# Set up VUnit environment
## =====================================================================================================================

VU, simulator = create_vunit(args=args, run_file_dir=THIS_DIR)

# Add the source files to the library
LIB_RTL: Library = VU.add_library(library_name="lib_rtl")
LIB_RTL.add_source_files(pattern=SRC_ROOT / "regblock" / "*.vhd")

# Add the test library
LIB_BENCH: Library = VU.add_library(library_name="lib_bench")
LIB_BENCH.add_source_file(file_name=COMMON_ROOT / "tb_common_pkg.vhd")
LIB_BENCH.add_source_file(file_name=COMMON_ROOT / "tb_reg_map_pkg.vhd")
LIB_BENCH.add_source_files(pattern=BENCH_ROOT / "**" / "*.vhd")

## =====================================================================================================================
# Set up simulator
## =====================================================================================================================

simulator.attach(VU).configure()

## =====================================================================================================================
# Run
## =====================================================================================================================

VU.main(post_run=simulator.post_run)
