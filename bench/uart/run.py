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

import os
import shutil
import subprocess
import sys
from pathlib import Path

from vunit import VUnit
from vunit.ui.library import Library
from vunit.ui.source import SourceFileList


def generate_coverage_report_nvc(
    results, ncdb_file: Path = Path("vunit_out/coverage.ncdb"), output_folder: Path = Path("vunit_out/coverage_report")
) -> None:
    """Generate the coverage report in HTML format.

    Parameters
    ----------
    results : Any
        The VUnit test results.
    ncdb_file : Path
        The path to the NCDB file.
    output_folder : Path
        The path to the output folder.

    Raises
    ------
    FileNotFoundError
        If the nvc executable is not found in the PATH.
    RuntimeError
        If the coverage report generation fails.
    """
    # Check if the nvc executable is available
    nvc_path: str | None = shutil.which(cmd="nvc")
    if not nvc_path:
        error_message: str = "nvc executable not found in PATH"
        raise FileNotFoundError(error_message)

    # Create the output folder if it does not exist
    output_folder.mkdir(parents=True, exist_ok=True)

    # Define the command to generate the coverage report
    # nvc --cover-report -o html  report_dir ncdb_file
    nvc_coverage_cmd: list[str] = [
        nvc_path,
        "--cover-report",
        "-o",
        str(object=output_folder),
        str(object=ncdb_file),
    ]

    try:
        subprocess.run(
            args=nvc_coverage_cmd,
            check=True,
            shell=False,
        )

        sys.stdout.write(f"{' '.join(nvc_coverage_cmd)}\n")
        sys.stdout.write(f"Coverage report generated in {output_folder}\n")

    except subprocess.CalledProcessError as e:
        error_message: str = f"Failed to generate coverage report with error: {e}"
        raise RuntimeError(error_message) from e


# Define the simulation tool:
#   1. NVC              (default)
#   2. GHDL             (fallback)
#   3. Questa/ModelSim  (fallback)

if shutil.which("nvc"):
    VUNIT_SIMULATOR: str = "nvc"
elif shutil.which("ghdl"):
    VUNIT_SIMULATOR: str = "ghdl"
elif shutil.which("vsim"):
    VUNIT_SIMULATOR: str = "modelsim"
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
VU.add_verification_components()

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

# Enable code coverage if supported by the simulator
if VUNIT_SIMULATOR == "modelsim":
    VU.set_sim_option(name="enable_coverage", value=True)
elif VUNIT_SIMULATOR == "nvc":
    VU.set_sim_option(
        name="nvc.elab_flags",
        value=[
            "--cover=statement,branch,expression,fsm-state,count-from-undefined,exclude-unreachable",
            "--cover-file=vunit_out/coverage.ncdb",
        ],
    )

VU.main(post_run=generate_coverage_report_nvc)
