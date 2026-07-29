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
## @version 2.5
## @brief   This module sets up the VUnit test environment, adds necessary source files, and runs the tests for the
##          UART modules.
## @author  Timothee Charrier
## =====================================================================================================================
## REVISION HISTORY
##
## Version  Date        Author              Description
## -------  ----------  ------------------  ----------------------------------------------------------------------------
## 1.0      17/10/2025  Timothee Charrier   Initial release
## 2.0      12/01/2026  Timothee Charrier   Update entire interface
## 2.1      13/04/2026  Timothee Charrier   Add custom args and update paths
## 2.2      06/05/2026  Timothee Charrier   Add Questa or ModelSim support, fix `LIB_SRC` to `LIB_RTL`
## 2.3      14/05/2026  Timothee Charrier   Update results directory to be at the same level as the testbench directory
## 2.4      19/05/2026  Timothee Charrier   Improved `Simulator` class removing coverage flags from this file
##          23/05/2026  Timothee Charrier   Fix `post_run` callback that should be called regardless of coverage being
##                                          enabled or not for output results merge.
## 2.5      29/07/2026  Timothee Charrier   Apply changes from `setup_vunit.py` to improve portability.
##                                          Add new common library `common`.
## =====================================================================================================================

import sys
from pathlib import Path

from vunit.ui.library import Library

sys.path.insert(0, str((Path(__file__).parent.parent.parent).resolve()))

from setup_vunit import create_vunit, create_vunit_cli

## =====================================================================================================================
# Define paths
## =====================================================================================================================

THIS_DIR: Path = Path(__file__).resolve().parent
PRJ_ROOT: Path = THIS_DIR.parent.parent.parent
SRC_ROOT: Path = PRJ_ROOT / "sources"
BENCH_ROOT: Path = PRJ_ROOT / "bench"
COMMON_ROOT: Path = BENCH_ROOT / "common"

## =====================================================================================================================
# Parse command line arguments
## =====================================================================================================================

cli = create_vunit_cli()
cli.parser.add_argument("--random-iterations", type=int, default=256, help="Number of random cases per random loop")
cli.parser.add_argument("--random-seed", type=int, default=1, help="Deterministic OSVVM random seed")
args = cli.parse_args()

## =====================================================================================================================
# Set up VUnit environment
## =====================================================================================================================

VU, simulator = create_vunit(args=args, run_file_dir=THIS_DIR)

# Add the source files to the library
LIB_RTL: Library = VU.add_library(library_name="lib_rtl")
LIB_RTL.add_source_files(pattern=SRC_ROOT / "uart" / "*.vhd")

# Add the test library
LIB_BENCH: Library = VU.add_library(library_name="lib_bench")
LIB_BENCH.add_source_file(file_name=COMMON_ROOT / "tb_common_pkg.vhd")
LIB_BENCH.add_source_files(pattern=THIS_DIR / "**" / "*.vhd")

for testbench_name in ("tb_uart_rx", "tb_uart_tx"):
    testbench = LIB_BENCH.test_bench(testbench_name)
    testbench.set_generic(name="G_RANDOM_ITERATIONS", value=args.random_iterations)
    testbench.set_generic(name="G_RANDOM_SEED", value=args.random_seed)

## =====================================================================================================================
# Set up simulator
## =====================================================================================================================

simulator.attach(VU).configure()

## =====================================================================================================================
# Run
## =====================================================================================================================


VU.main(post_run=simulator.post_run)
