"""Utility functions for the VUnit test environment."""

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
## @brief   This module provides utility functions for the VUnit test environment.
## @author  Timothee Charrier
## @date    18/10/2025
## =====================================================================================================================

import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Literal

import vunit


def setup_simulator() -> Literal["nvc", "ghdl", "modelsim"]:
    """Set up the simulator environment based on the available simulator.

        - The current supported simulators are:
            1. NVC              (default)
            2. GHDL             (fallback)
            3. Questa/ModelSim  (fallback)

    Returns
    -------
    Literal["nvc", "ghdl", "modelsim"]
        The name of the selected simulator.
    """
    global VUNIT_SIMULATOR

    if shutil.which("nvc"):
        VUNIT_SIMULATOR = "nvc"
    elif shutil.which("ghdl"):
        VUNIT_SIMULATOR = "ghdl"
    elif shutil.which("vsim"):
        VUNIT_SIMULATOR = "modelsim"
    else:
        print("No supported simulator found")
        sys.exit(status=1)

    # Set the VUNIT_SIMULATOR environment variable
    os.environ["VUNIT_SIMULATOR"] = os.environ.get("VUNIT_SIMULATOR", default=VUNIT_SIMULATOR)

    return VUNIT_SIMULATOR


def setup_nvc(VU: vunit) -> None:
    """Set up the NVC simulator environment."""
    # Enable coverage collection
    VU.set_sim_option(
        name="nvc.elab_flags",
        value=[
            "--cover=statement,branch,expression,fsm-state,count-from-undefined,exclude-unreachable",
            "--cover-file=vunit_out/coverage.ncdb",
        ],
    )


def setup_ghdl(VU: vunit) -> None:
    """Set up the GHDL simulator environment."""
    # Warn on unused signals and variables
    VU.set_compile_option(name="ghdl.a_flags", value=["--warn-no-hide"])


def setup_modelsim(VU: vunit) -> None:
    """Set up the ModelSim simulator environment."""
    # Enable coverage collection
    VU.set_sim_option(name="enable_coverage", value=True)


def generate_coverage_report_nvc(
    results,
    ncdb_file: Path = Path("vunit_out/coverage.ncdb"),
    output_folder: Path = Path("vunit_out/coverage_report"),
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


def copy_to_result_dir(
    ncdb_file: Path = Path("vunit_out/coverage.ncdb"),
    output_folder: Path = Path("vunit_out/test_output"),
    result_dir: Path = Path("bench/results"),
) -> None:
    """Copy the NCDB file and output.txt file to the result directory.

    Parameters
    ----------
    ncdb_file : Path
        The path to the NCDB coverage file to copy.
    output_folder : Path
        The path to the folder containing the output.txt file.
    result_dir : Path
        The destination directory where files will be copied.

    Raises
    ------
    OSError
        If the result directory cannot be created.
    PermissionError
        If there are insufficient permissions to copy files.
    """
    # Create result directory if it doesn't exist
    try:
        result_dir.mkdir(parents=True, exist_ok=True)
    except OSError as e:
        sys.stderr.write(f"Error creating result directory {result_dir}: {e}\n")
        raise

    # Copy NCDB file to result directory
    if ncdb_file.exists():
        try:
            shutil.copy2(src=ncdb_file, dst=result_dir / ncdb_file.name)
            sys.stdout.write(f"Copied {ncdb_file} to {result_dir}\n")
        except (OSError, PermissionError) as e:
            sys.stderr.write(f"Error copying NCDB file {ncdb_file}: {e}\n")
    else:
        sys.stdout.write(f"Warning: NCDB file not found at {ncdb_file}\n")

    # Find and copy output.txt file from subdirectory
    try:
        output_files = list(output_folder.glob("**/output.txt"))
        if output_files:
            # Take the first match (should only be one)
            output_file = output_files[0]
            try:
                shutil.copy2(src=output_file, dst=result_dir / "output.txt")
                sys.stdout.write(f"Copied {output_file} to {result_dir}\n")
            except (OSError, PermissionError) as e:
                sys.stderr.write(f"Error copying output file {output_file}: {e}\n")
        else:
            sys.stdout.write(f"Warning: No output.txt file found in {output_folder}\n")
    except OSError as e:
        sys.stderr.write(f"Error searching for output.txt in {output_folder}: {e}\n")


def post_run_callback(results, VUNIT_SIMULATOR: Literal["nvc", "ghdl", "modelsim"] = "nvc"):
    """Post-run callback that works for all simulators.

    Parameters
    ----------
    results : Any
        The VUnit test results.
    """
    # Generate coverage report only for NVC simulator
    if VUNIT_SIMULATOR == "nvc":
        generate_coverage_report_nvc(results)

    # Copy files to result directory (runs for all simulators)
    copy_to_result_dir()
