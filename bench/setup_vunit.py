"""Simulator classes for VUnit."""

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
## @file    setup_vunit.py
## @version 1.0
## @brief   This module provides simulator classes for VUnit.
## @author  Timothee Charrier
## @date    01/11/2025
## =====================================================================================================================

import os
import shutil
import subprocess
from abc import ABC, abstractmethod
from pathlib import Path

from vunit import VUnit


class Simulator(ABC):
    """Abstract base class for simulators."""

    enable_coverage: bool = False
    result_dir: Path = Path.cwd() / "results"

    def __init__(self) -> None:
        self._simulator_in_path()
        self._set_os_environment()

    @abstractmethod
    def _simulator_in_path(self) -> None:
        """Raise exception if the simulator executable does not exist in :envvar:`PATH`."""
        pass

    @abstractmethod
    def _set_os_environment(self) -> None:
        """Set the operating system environment variables for the simulator."""
        pass

    def add_library(self, VU: VUnit, library_name: str, library_path: str) -> None:
        """Ädd a library to Vunit."""
        VU.add_external_library(library_name=library_name, path=os.path.expanduser(path=library_path))

    @abstractmethod
    def configure(self, VU: VUnit) -> None:
        """Configure the simulator with specific settings."""
        pass

    @abstractmethod
    def setup_coverage(self) -> None:
        """Set up code coverage for the simulator."""
        pass

    def copy_output_log(self) -> None:
        """Copy the simulator output log to the results directory."""
        if self.VU is None:
            return

        output_folder: Path = Path(self.VU._output_path)
        output_files: list[Path] = list(output_folder.glob("**/output.txt"))

        if output_files:
            # Take the first match (should only be one)
            output_file: Path = output_files[0]
            shutil.copy2(src=output_file, dst=self.result_dir / "output.txt")

    @abstractmethod
    def post_run(self) -> None:
        """Actions to perform after the simulation run."""
        pass


class NVC(Simulator):
    """Class representing the NVC simulator."""

    VU = None

    def _simulator_in_path(self) -> None:
        """Check if NVC simulator is in PATH."""
        if shutil.which("nvc") is None:
            raise SystemExit("ERROR: nvc executable not found!")

    def _set_os_environment(self) -> None:
        """Set the operating system environment variables for the NVC simulator."""
        os.environ["VUNIT_SIMULATOR"] = "nvc"

    def configure(self, VU: VUnit) -> None:
        """Configure the NVC simulator with specific settings."""
        VU.set_sim_option(name="nvc.global_flags", value=["--ieee-warnings=off-at-0"])

        if not self.enable_coverage:
            VU.set_attribute(name="run_all_in_same_sim", value=False)

    def setup_coverage(self, VU: VUnit, specifications: list[str] | None = None) -> None:
        """Set up code coverage for the simulator.

        Parameters
        ----------
        VU : VUnit
            The VUnit instance to configure.
        specifications : list[str] | None
            Optional list of coverage specifications to include.

        Returns
        -------
        None
        """
        self.enable_coverage = True
        self.VU: VUnit = VU

        # NVC is not "officially" supported for coverage, we need to run all sims in the same simulation
        VU.set_attribute(name="run_all_in_same_sim", value=True)

        # Define coverage flags
        coverage_flags: list[str] = []
        coverage_flags.append("--cover=statement,branch,expression,fsm-state,count-from-undefined,exclude-unreachable")
        coverage_flags.append(f"--cover-file={self.VU._output_path}/coverage.ncdb")

        # If specifications are provided, create the file and write them
        if specifications is not None:
            with open(file=f"{self.VU._output_path}/coverage.spec", mode="w") as f:
                f.writelines(f"{spec}\n" for spec in specifications)

            coverage_flags.append(f"--cover-spec={self.VU._output_path}/coverage.spec")

        # Set the elaboration flags for NVC
        VU.set_sim_option(name="nvc.elab_flags", value=coverage_flags)

    def post_run(
        self,
        results,
    ) -> None:
        """Actions to perform after the simulation run.

        Creates a coverage report if coverage is enabled.

        Parameters
        ----------
        results : TestResults
            The results of the simulation run. Used internally by VUnit.
        """
        # Generate coverage report if enabled
        if not self.enable_coverage:
            return

        # Coverage database and output folder paths
        ncdb_file: Path = Path(f"{self.VU._output_path}/coverage.ncdb")
        output_folder: Path = Path(f"{self.VU._output_path}/coverage_report")

        # Create the output folder if it does not exist
        output_folder.mkdir(parents=True, exist_ok=True)

        # Define the command to generate the coverage report
        nvc_coverage_cmd: list[str] = [
            "nvc",
            "--cover-report",
            "-o",
            str(object=output_folder),
            str(object=ncdb_file),
        ]

        subprocess.run(
            args=nvc_coverage_cmd,
            check=True,
        )


class GHDL(Simulator):
    """Class representing the GHDL simulator."""

    def _simulator_in_path(self) -> None:
        """Check if GHDL simulator is in PATH."""
        if shutil.which("ghdl") is None:
            raise SystemExit("ERROR: ghdl executable not found!")

    def _set_os_environment(self) -> None:
        """Set the operating system environment variables for the GHDL simulator."""
        os.environ["VUNIT_SIMULATOR"] = "ghdl"

    def configure(self, VU: VUnit) -> None:
        """Configure the GHDL simulator with specific settings."""
        VU.set_compile_option(name="ghdl.a_flags", value=["--warn-no-hide"])
        VU.set_sim_option(name="ghdl.sim_flags", value=["--asserts=disable-at-0"])

    def setup_coverage(self) -> None:
        """Set up code coverage for the simulator."""
        # GHDL only supports coverage with GCC backend, TODO: implement later
        pass

    def post_run(self, results) -> None:
        """Actions to perform after the simulation run."""
        # GHDL only supports coverage with GCC backend, TODO: implement later
        pass


def select_simulator(simulator_name: str | None = None) -> Simulator:
    """Select and return the appropriate simulator instance based on the provided name.

    Parameters
    ----------
    simulator_name : str | None
        The name of the simulator to select. Supported values are "nvc" and "ghdl".
        If not provided, defaults to:
            1. nvc
            2. ghdl

    Returns
    -------
    Simulator
        An instance of the selected simulator class.

    Raises
    ------
    SystemExit
        If no supported simulator is found in PATH.
    ValueError
        If an unsupported simulator name is provided.
    """
    if simulator_name is None:
        if shutil.which("nvc") is not None:
            simulator_name = "nvc"
        elif shutil.which("ghdl") is not None:
            simulator_name = "ghdl"
        else:
            raise SystemExit("ERROR: No supported simulator found in PATH!")

    if simulator_name.lower() == "nvc":
        return NVC()
    elif simulator_name.lower() == "ghdl":
        return GHDL()
    else:
        raise ValueError(f"Unsupported simulator: {simulator_name}")
