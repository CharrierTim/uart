"""Simulator classes for VUnit."""
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
## @file    setup_vunit.py
## @version 2.0
## @brief   This module provides simulator classes for VUnit.
## @author  Timothee Charrier
## @date    01/11/2025
## =====================================================================================================================
## REVISION HISTORY
##
## Version  Date        Author              Description
## -------  ----------  ------------------  ----------------------------------------------------------------------------
## 1.0      01/11/2025  Timothee Charrier   Initial release
## 2.0      07/01/2026  Timothee Charrier   Major refactor: Vunit now supports NVC coverage, no need for a custom
##                                          interface.
## =====================================================================================================================

import logging
import os
import shutil
from abc import ABC, abstractmethod
from pathlib import Path

from vunit import VUnit
from vunit.ostools import Process
from vunit.ui.results import Results

LOGGER: logging.Logger = logging.getLogger(name=__name__)


class Simulator(ABC):
    """Abstract base class for HDL simulators."""

    SIMULATOR_NAME: str = ""
    EXECUTABLE: str = ""
    DEFAULT_LIBRARIES: dict[str, str] = {}

    def __init__(self, result_dir: Path | None = None, enable_coverage: bool = False) -> None:
        """Initialize the simulator.

        Parameters
        ----------
        result_dir : Path | None
            Directory for simulation results. Defaults to ./bench/results
        enable_coverage : bool
            Enable coverage collection and reporting. Defaults to False.
        """
        self.result_dir: Path = result_dir or Path.cwd() / "bench" / "results"
        self.enable_coverage: bool = enable_coverage
        self.vu: VUnit | None = None

        self._check_executable()
        self._set_environment()

    def _check_executable(self) -> None:
        """Check if the simulator executable is available."""
        if not shutil.which(self.EXECUTABLE):
            raise SystemExit(f"ERROR: {self.EXECUTABLE} executable not found in PATH!")

    def _set_environment(self) -> None:
        """Set environment variables for the simulator."""
        os.environ["VUNIT_SIMULATOR"] = self.SIMULATOR_NAME

    def attach(self, vu: VUnit) -> "Simulator":
        """Attach a VUnit instance to this simulator.

        Parameters
        ----------
        vu : VUnit
            The VUnit instance to attach.

        Returns
        -------
        Simulator
            Self for method chaining.
        """
        self.vu = vu
        return self

    def add_library(self, library_name: str, library_path: str | None = None) -> "Simulator":
        """Add an external library to VUnit.

        Parameters
        ----------
        library_name : str
            Name of the library (e.g., 'unisim', 'unifast').
        library_path : str | None
            Path to the library. If None, uses the default path.

        Returns
        -------
        Simulator
            Self for method chaining.
        """
        if not self.vu:
            LOGGER.error("Must call attach() before adding libraries!")

        path: str | None = library_path or self.DEFAULT_LIBRARIES.get(library_name)
        if not path:
            LOGGER.error("No default path for library '%s'", library_name)

        expanded_path: str = os.path.expanduser(path)
        self.vu.add_external_library(library_name, expanded_path)
        return self

    def configure(self) -> "Simulator":
        """Apply simulator-specific configuration.

        Returns
        -------
        Simulator
            Self for method chaining.
        """
        if not self.vu:
            LOGGER.error("Must call attach() before configure!")

        self._apply_options()
        return self

    @abstractmethod
    def _apply_options(self) -> None:
        """Apply simulator-specific VUnit options."""

    def post_run(self, results: Results) -> None:
        """Execute post-run actions.

        This method is used as VUnit's post_run callback.

        Parameters
        ----------
        results : Results
            The simulation results from VUnit.
        """
        self._merge_output_files()

        if self.enable_coverage:
            self._generate_coverage(results)
        else:
            LOGGER.info("Coverage generation skipped (not enabled)")

    def _merge_output_files(self) -> None:
        """Merge all output.txt files from subdirectories into a single file."""
        vunit_dir = Path(self.vu._output_path)
        output_file = self.result_dir / "output.txt"

        # Check if test_output directory exists
        if not vunit_dir.exists():
            LOGGER.warning("Test output directory not found: %s", vunit_dir)
            return

        # Find all output.txt files
        output_files = list(vunit_dir.rglob("output.txt"))

        if not output_files:
            LOGGER.warning("No output.txt files found in %s", vunit_dir)
            return

        with open(output_file, "w", encoding="utf-8") as outfile:
            LOGGER.info("Merging %d output.txt files...", len(output_files))

            for txt_file in sorted(output_files):
                # Write a header with the test name
                outfile.write(f"\n{'=' * 80}\n")
                outfile.write(f"Test: {txt_file.parent.name}\n")
                outfile.write(f"Path: {txt_file.relative_to(vunit_dir)}\n")
                outfile.write(f"{'=' * 80}\n\n")

                # Write the contents of the file
                try:
                    with open(txt_file, encoding="utf-8") as infile:
                        outfile.write(infile.read())
                except Exception as e:
                    LOGGER.error("Failed to read %s: %s", txt_file, e)
                    outfile.write(f"[ERROR: Could not read file - {e}]\n")

        LOGGER.info("Successfully merged output files to: %s", output_file)

    @abstractmethod
    def _generate_coverage(self, results: Results) -> None:
        """Generate coverage report.

        Parameters
        ----------
        results : Results
            The simulation results from VUnit.
        """


class NVC(Simulator):
    """NVC simulator implementation."""

    SIMULATOR_NAME = "nvc"
    EXECUTABLE = "nvc"
    DEFAULT_LIBRARIES = {
        "unisim": "~/.nvc/lib/unisim.08",
        "unifast": "~/.nvc/lib/unifast.08",
    }

    def _apply_options(self) -> None:
        """Apply NVC-specific options."""
        # Base flags always applied
        global_flags: list[str] = ["--ieee-warnings=off-at-0"]
        elab_flags: list[str] = []

        # Add coverage flags if enabled
        if self.enable_coverage:
            elab_flags.append("--cover=statement,branch,expression,fsm-state,count-from-undefined,exclude-unreachable")

        self.vu.set_sim_option(name="nvc.global_flags", value=global_flags, overwrite=False)
        self.vu.set_sim_option(name="nvc.elab_flags", value=elab_flags, overwrite=False)

    def _generate_coverage(self, results: Results) -> None:
        """Generate NVC coverage report."""
        if not self.vu:
            return

        output_path = Path(self.vu._output_path)
        coverage_file = output_path / "coverage_data"
        coverage_dir = output_path / "coverage_report"

        # Merge coverage databases
        LOGGER.info("Merging coverage files into %s.ncdb...", coverage_file)
        results.merge_coverage(file_name=str(coverage_file))
        LOGGER.info("Coverage files merged")

        coverage_db = Path(f"{coverage_file}.ncdb")
        if not coverage_db.exists():
            LOGGER.warning("Coverage database not found at %s", coverage_db)
            return

        # Generate coverage report
        LOGGER.info("Generating coverage report to %s...", coverage_dir)
        cmd = ["nvc", "--cover-report", str(coverage_db), "-o", str(coverage_dir)]
        process = Process(cmd)
        process.consume_output()
        LOGGER.info("Coverage report generated")

        # Copy to results directory
        self.result_dir.mkdir(parents=True, exist_ok=True)
        output_file = self.result_dir / "coverage_data.ncdb"
        shutil.copy2(coverage_db, output_file)
        LOGGER.info("Coverage database copied to %s", output_file)


class GHDL(Simulator):
    """GHDL simulator implementation."""

    SIMULATOR_NAME = "ghdl"
    EXECUTABLE = "ghdl"
    DEFAULT_LIBRARIES = {
        "unisim": "~/.ghdl/xilinx-vivado/unisim/v08",
        "unifast": "~/.ghdl/xilinx-vivado/unifast/v08",
    }

    def _apply_options(self) -> None:
        """Apply NVC-specific options."""
        # Base flags always applied
        analysis_flags: list[str] = ["-fsynopsys", "-frelaxed", "--warn-no-hide"]
        elab_flags: list[str] = ["-fsynopsys", "-frelaxed"]
        sim_flags: list[str] = ["--asserts=disable-at-0"]

        self.vu.add_compile_option(name="ghdl.a_flags", value=analysis_flags)
        self.vu.set_sim_option(name="ghdl.elab_flags", value=elab_flags)
        self.vu.set_sim_option(name="ghdl.sim_flags", value=sim_flags)

    def _generate_coverage(self, results: Results) -> None:
        """Generate GHDL coverage report."""
        if not self.vu:
            return

        # Merge coverage databases
        LOGGER.info("TODO")


def select_simulator(
    name: str | None = None, enable_coverage: bool = False, result_dir: Path | None = None
) -> Simulator:
    """Select and create a simulator.

    Parameters
    ----------
    name : str | None
        Simulator name ('nvc' or 'ghdl'). If None, auto-detects.
    enable_coverage : bool
        Enable coverage collection and reporting. Defaults to False.
    result_dir : Path | None
        Directory for simulation results. Defaults to ./vunit_out

    Returns
    -------
    Simulator
        Configured simulator instance.
    """
    simulators = {"nvc": NVC, "ghdl": GHDL}

    # Auto-detect if not specified
    if not name:
        name = os.environ.get("VUNIT_SIMULATOR")
        if not name:
            for sim_name in simulators:
                if shutil.which(sim_name):
                    name = sim_name
                    break

    # Create the appropriate simulator
    simulator_class = simulators.get(name)
    if not simulator_class:
        available = ", ".join(simulators.keys())
        LOGGER.error("Unknown simulator: %s. Available: %s", name, available)

    return simulator_class(result_dir=result_dir, enable_coverage=enable_coverage)
