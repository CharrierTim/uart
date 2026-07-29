"""VUnit test runner for the Top-level module."""
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
## @version 2.6
## @brief   This module sets up the VUnit test environment, adds necessary source files, and runs the tests for the
##          Top-level module.
## @author  Timothee Charrier
## =====================================================================================================================
## REVISION HISTORY
##
## Version  Date        Author              Description
## -------  ----------  ------------------  ----------------------------------------------------------------------------
## 1.0      17/10/2025  Timothee Charrier   Initial release
## 2.0      12/01/2026  Timothee Charrier   Update entire interface
## 2.1      12/04/2026  Timothee Charrier   Add `vhdl_ls` file generation and minor fix
## 2.2      17/04/2026  Timothee Charrier   Add support for selecting simulator via command line and update coverage
##                                          collection implementation.
## 2.2      06/05/2026  Timothee Charrier   Add Questa or ModelSim support, fix `LIB_SRC` to `LIB_RTL`
## 2.3      10/05/2026  Timothee Charrier   Fix missing GHDL parser flag and add custom vhdl_ls.toml generation method
## 2.4      14/05/2026  Timothee Charrier   Update results directory to be at the same level as the testbench directory
## 2.5      19/05/2026  Timothee Charrier   Improved `Simulator` class removing coverage flags from this file
##          23/05/2026  Timothee Charrier   Fix `post_run` callback that should be called regardless of coverage being
##                                          enabled or not for output results merge.
##          24/05/2026  Timothee Charrier   Add support for a fast PLL model to quickly iterate without needing Vivado
##                                          PLL simulation files.
##          01/06/2026  Timothee Charrier   Rename `--fast_pll` flag to `--without_unisim`.
## 2.6      29/07/2026  Timothee Charrier   Apply changes from `setup_vunit.py` to improve portability.
##                                          Add new common library `common`.
## =====================================================================================================================

import sys
from pathlib import Path

from vunit.ui.library import Library

sys.path.insert(0, str((Path(__file__).parent.parent).resolve()))
sys.path.insert(0, str((Path(__file__).parent.parent.parent / "cores" / "open-logic" / "sim").resolve()))

from setup_vunit import create_vunit, create_vunit_cli

## =====================================================================================================================
# Define paths
## =====================================================================================================================

THIS_DIR: Path = Path(__file__).resolve().parent
PRJ_ROOT: Path = THIS_DIR.parent.parent
SRC_ROOT: Path = PRJ_ROOT / "sources"
CORES_ROOT: Path = PRJ_ROOT / "cores"
BENCH_ROOT: Path = THIS_DIR.parent
COMMON_ROOT: Path = BENCH_ROOT / "common"
MODELS_ROOT: Path = BENCH_ROOT / "models"

## =====================================================================================================================
# Parse command line arguments
## =====================================================================================================================

cli = create_vunit_cli()
cli.parser.add_argument("--vhdl_ls", action="store_true", help="Generate vhdl_ls configuration file")
cli.parser.add_argument(
    "--without_unisim",
    action="store_true",
    help="Use a custom behavioral PLL model (faster simulation without needing Vivado pre-compiled libraries)",
)
args = cli.parse_args()

## =====================================================================================================================
# Set up VUnit environment
## =====================================================================================================================

VU, simulator = create_vunit(args=args, run_file_dir=THIS_DIR, add_random=False)

# Open-logic libraries
OLO: Library = VU.add_library(library_name="olo")
OLO.add_source_files(pattern=CORES_ROOT / "open-logic" / "src" / "**" / "*.vhd")
OLO.add_source_files(pattern=CORES_ROOT / "open-logic" / "3rdParty/" / "en_cl_fix" / "hdl" / "*.vhd")
OLO.add_compile_option(name="nvc.a_flags", value=["--relaxed"])

# Add the source files to the library
LIB_RTL: Library = VU.add_library(library_name="lib_rtl")
LIB_RTL.add_source_files(pattern=SRC_ROOT / "**" / "*.vhd")

if not args.without_unisim:
    LIB_RTL.add_source_file(file_name=CORES_ROOT / "pll" / "clk_wiz_0_sim_netlist.vhd")
else:
    LIB_RTL.add_source_file(file_name=MODELS_ROOT / "pll" / "pll_fast_sim.vhd")

# Add the test library
LIB_BENCH: Library = VU.add_library(library_name="lib_bench")
LIB_BENCH.add_source_file(file_name=COMMON_ROOT / "tb_common_pkg.vhd")
LIB_BENCH.add_source_file(file_name=COMMON_ROOT / "tb_reg_map_pkg.vhd")
LIB_BENCH.add_source_files(pattern=MODELS_ROOT / "uart" / "*.vhd")
LIB_BENCH.add_source_files(pattern=MODELS_ROOT / "spi" / "*.vhd")
LIB_BENCH.add_source_files(pattern=THIS_DIR / "**" / "*.vhd")

## =====================================================================================================================
# Set up simulator
## =====================================================================================================================

simulator.attach(VU).configure()

if not args.without_unisim:
    simulator.add_library(library_name="unisim")
    simulator.add_library(library_name="unifast")

## =====================================================================================================================
# Generate vhdl_ls configuration if requested and exit
## =====================================================================================================================

if args.vhdl_ls:
    optional_files: list[tuple[Path | None, str]] = [
        (BENCH_ROOT / "ip_tb" / "**" / "*.vhd", "lib_bench"),
        (simulator.get_unifast_library_path(), "unifast"),
        (simulator.get_unisim_vcomp_library_path(), "unisim"),
        (simulator.get_unisim_vpkg_library_path(), "unisim"),
    ]
    files: list[tuple[Path, str]] = [(path, library) for path, library in optional_files if path is not None]
    simulator.generate_vhdl_ls_toml(external_libraries=files, output_path=PRJ_ROOT)
    sys.exit(0)

## =====================================================================================================================
# Run
## =====================================================================================================================

VU.main(post_run=simulator.post_run)
