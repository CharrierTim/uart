"""Script linting all HDL files specified."""
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
## @file    lint.py
## @version 1.0
## @brief   Script linting all HDL files specified.
#           https://github.com/open-logic/open-logic/blob/main/lint/script/script.py
## @author  Timothee Charrier
## =====================================================================================================================
## REVISION HISTORY
##
## Version  Date        Author              Description
## -------  ----------  ------------------  ----------------------------------------------------------------------------
## 1.0      18/11/2025  Timothee Charrier   Initial release
## =====================================================================================================================

import argparse
import os
from pathlib import Path

# Change directory to the script directory
os.chdir(Path(__file__).parent)

# Detect arguments
parser = argparse.ArgumentParser(description="Lint all VHDL files in the project")
parser.add_argument("--debug", action="store_true", help="Lint files one by one and stop on any errors")
parser.add_argument("--syntastic", action="store_true", help="Output in syntastic format")

args: argparse.Namespace = parser.parse_args()

# Define the directory to search
DIR = "../.."

# Not linted files
NOT_LINTED = []
NOT_LINTED_DIR: list[str] = [
    "../../cores",
    "../../.venv",
    "../../vunit_out",
    "../../bench/models/spi",
]  # 3rd party libraries


def files_to_string(string, file_paths):
    """Join file paths into a single string with a custom separator.

    Parameters
    ----------
    string : str
        The separator string to use between file paths.
    file_paths : list[Path]
        List of file paths to join.

    Returns
    -------
    str
        A string containing all file paths joined by the separator.
    """
    return string.join(str(path) for path in file_paths)


def find_vhd_files(directory):
    """Recursively find all VHDL files in the specified directory.

    Excludes files and directories specified in NOT_LINTED and NOT_LINTED_DIR.

    Parameters
    ----------
    directory : Path
        The root directory to search for VHDL files.

    Returns
    -------
    list[Path]
        A list of resolved Path objects for all found VHDL files.
    """
    vhd_files = []

    for file in directory.rglob("*.vhd"):
        # Skip directories that are not relevant (including subdirectories)
        if any(file.resolve().is_relative_to(Path(not_linted).resolve()) for not_linted in NOT_LINTED_DIR):
            continue

        # Skip not linted files
        if file.name in NOT_LINTED:
            continue

        # Append file
        vhd_files.append(file.resolve())
    return vhd_files


# Configure output format
output_format = "-of vsg"
if args.syntastic:
    output_format = "-of syntastic"

# Get the list of .vhd files
vhd_files_list = find_vhd_files(Path(DIR))

# Print the list of files found
print("VHDL Files")
print(files_to_string("\n", vhd_files_list))
print()
print("Start Linting")

error_occurred = False

# Execute linting for VHD files
if args.debug:
    for file in vhd_files_list:
        print(f"Linting {file}")
        result = os.system(f"vsg -c ../config/.vsg.yaml -f {file} {output_format}")
        if result != 0:
            raise Exception(f"Error: Linting of {file} failed - check report")
else:
    all_files = files_to_string(" ", vhd_files_list)
    result = os.system(
        f"vsg -c ../config/.vsg.yaml -f {all_files} --junit ../report/vsg_vhdl.xml --all_phases {output_format}"
    )
    if result != 0:
        error_occurred = True

if error_occurred:
    raise Exception("Error: Linting of VHDL files failed - check report")

# Print success message
print("All VHDL files linted successfully")
