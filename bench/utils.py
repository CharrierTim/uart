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

import shutil
import subprocess
import sys
from pathlib import Path


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
