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
## @version 2.0
## @brief   Script linting all HDL files specified.
#           Adapted from https://github.com/open-logic/open-logic/blob/main/lint/script/script.py
## @author  Timothee Charrier
## =====================================================================================================================
## REVISION HISTORY
##
## Version  Date        Author              Description
## -------  ----------  ------------------  ----------------------------------------------------------------------------
## 1.0      18/11/2025  Timothee Charrier   Initial release
## 2.0      17/05/2026  Timothee Charrier   Update script and add new excluded directory (`sources/regblock`)
## =====================================================================================================================

import argparse
import logging
import subprocess
from pathlib import Path
from typing import Literal

LOGGER: logging.Logger = logging.getLogger(name=__name__)

## =====================================================================================================================
# Define paths
## =====================================================================================================================

THIS_DIR: Path = Path(__file__).resolve().parent
PRJ_ROOT: Path = THIS_DIR.parent.parent.parent
VSG_CONFIG: Path = THIS_DIR.parent / "config" / ".vsg.yaml"
VSG_REPORT: Path = THIS_DIR.parent / "report" / "vsg_vhdl.xml"

NOT_LINTED: list[str] = []
NOT_LINTED_DIR: list[Path] = [
    PRJ_ROOT / "sources" / "regblock",
    PRJ_ROOT / "cores",
    PRJ_ROOT / ".venv",
    PRJ_ROOT / "vunit_out",
    PRJ_ROOT / "bench" / "models" / "spi",
]

## =====================================================================================================================
# Functions
## =====================================================================================================================


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Lint all VHDL files in the project")
    parser.add_argument("--debug", action="store_true", help="Lint files one by one and stop on any errors")
    parser.add_argument("--syntastic", action="store_true", help="Output in syntastic format")
    return parser.parse_args()


def _files_to_string(separator: str, file_paths: list[Path]) -> str:
    """Join file paths into a single string with a custom separator.

    Parameters
    ----------
    separator : str
        The separator string to use between file paths.
    file_paths : list[Path]
        List of file paths to join.

    Returns
    -------
    str
        A string containing all file paths joined by the separator.
    """
    return separator.join(str(path) for path in file_paths)


def _is_excluded(file_path: Path) -> bool:
    resolved_path: Path = file_path.resolve()
    return any(resolved_path.is_relative_to(excluded_dir.resolve()) for excluded_dir in NOT_LINTED_DIR)


def _find_vhd_files(directory: Path) -> list[Path]:
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
    vhd_files: list[Path] = []

    for file in directory.rglob(pattern="*.vhd"):
        if _is_excluded(file_path=file):
            continue
        if file.name in NOT_LINTED:
            continue
        vhd_files.append(file.resolve())
    return vhd_files


def _run_vsg(args: list[str]) -> None:
    result: subprocess.CompletedProcess[bytes] = subprocess.run(args, check=True)
    if result.returncode != 0:
        raise SystemExit("ERROR: Linting of VHDL files failed - check report")


## =====================================================================================================================
# Main script
## =====================================================================================================================


def main() -> None:
    """Entry point of the script."""
    args: argparse.Namespace = _parse_args()

    output_format: Literal["-of syntastic", "-of vsg"] = "-of syntastic" if args.syntastic else "-of vsg"
    vhd_files_list: list[Path] = _find_vhd_files(directory=PRJ_ROOT)

    print("VHDL Files")
    print(_files_to_string(separator="\n", file_paths=vhd_files_list))
    print()
    print("Start Linting")

    if args.debug:
        for file in vhd_files_list:
            print(f"Linting {file}")
            _run_vsg(args=["vsg", "-c", str(VSG_CONFIG), "-f", str(file), *output_format.split()])
    else:
        vsg_args = [
            "vsg",
            "-c",
            str(VSG_CONFIG),
            "-f",
            *[str(path) for path in vhd_files_list],
            "--junit",
            str(VSG_REPORT),
            "--all_phases",
            *output_format.split(),
        ]
        _run_vsg(args=vsg_args)

    print("All VHDL files linted successfully")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
    LOGGER.info("Linting VHDL files...")
    main()
    LOGGER.info("Done!")
