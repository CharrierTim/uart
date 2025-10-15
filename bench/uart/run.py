"""VUnit test runner for the UART module."""
## =====================================================================================================================
##  ______ _                 _____            _
## |  ____| |               |  __ \          (_)
## | |__  | |___ _   _ ___  | |  | | ___  ___ _  __ _ _ __
## |  __| | / __| | | / __| | |  | |/ _ \/ __| |/ _` | '_ \
## | |____| \__ \ |_| \__ \ | |__| |  __/\__ \ | (_| | | | |
## |______|_|___/\__, |___/ |_____/ \___||___/_|\__, |_| |_|
##             __/ |                          __/ |
##             |___/                          |___/
##
## Copyright (c) 2025 Elsys Design
##
## =====================================================================================================================
## @project uart
## @file    run.py
## @version 1.0
## @brief   This module sets up the VUnit test environment, adds necessary source files, and runs the tests for the
##          UART module.
## @author  Timothee Charrier
## @date    10/10/2025
## =====================================================================================================================

import os
import shutil
import sys
from pathlib import Path

from vunit import VUnit
from vunit.ui.library import Library
from vunit.ui.source import SourceFileList

# Define the simulation tool:
#   1. NVC              (default)
#   2. GHDL             (fallback)
#   3. Questa/ModelSim  (fallback)

if shutil.which("nvc"):
    VUNIT_SIMULATOR: str = "nvc"
elif shutil.which("ghdl"):
    VUNIT_SIMULATOR: str = "ghdl"
elif shutil.which("vsim"):
    VUNIT_SIMULATOR: str = "vsim"
else:
    print("No supported simulator found")
    sys.exit(status=1)

os.environ["VUNIT_SIMULATOR"] = os.environ.get("VUNIT_SIMULATOR", default=VUNIT_SIMULATOR)

# Define the source and bench paths
SRC_ROOT: Path = Path(__file__).parent.parent.parent / "sources"
BENCH_ROOT: Path = Path(__file__).parent / "test"

# Define the libraries
src_library_name: str = "lib_rtl"
bench_library_name: str = "lib_bench"

# Initialize VUnit
argv: list[str] = sys.argv if len(sys.argv) > 1 else ["-v", "-p", "0"]
VU: VUnit = VUnit.from_argv(argv=argv)
VU.add_vhdl_builtins()

# Add the source files to the library
LIB_SRC: Library = VU.add_library(library_name=src_library_name)
LIB_SRC.add_source_files(pattern=SRC_ROOT / "**" / "*.vhd")

# Add the test library
LIB_BENCH: SourceFileList = VU.add_library(library_name=bench_library_name)
LIB_BENCH.add_source_files(pattern=BENCH_ROOT / "*.vhd")

# Reduce warnings from Vunit when compiling with GHDL
if VUNIT_SIMULATOR == "ghdl":
    VU.set_compile_option(name="ghdl.a_flags", value=["--warn-no-hide"])

# Disable IEEE warnings at 0 ns
VU.set_sim_option(name="disable_ieee_warnings", value=True)

# Enable code coverage
VU.set_sim_option(name="enable_coverage", value=True)

VU.main()
