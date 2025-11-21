"""Simulator classes for VUnit - Refactored Version."""
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
import sys
from abc import ABC, abstractmethod
from pathlib import Path
from subprocess import CalledProcessError, run

from vunit import VUnit
from vunit.ui.library import Library
from vunit.ui.results import Results


class SimulatorConfig:
    """Configuration constants for simulators."""

    NVC = "nvc"
    GHDL = "ghdl"

    NVC_UNISIM_PATH = "~/.nvc/lib/unisim.08"
    NVC_UNIFAST_PATH = "~/.nvc/lib/unifast.08"
    GHDL_UNISIM_PATH = "~/.ghdl/xilinx-vivado/unisim/v08"
    GHDL_UNIFAST_PATH = "~/.ghdl/xilinx-vivado/unifast/v08"


class Simulator(ABC):
    """Abstract base class for HDL simulators.

    This class provides a common interface for different HDL simulators
    used with the VUnit framework.

    Attributes
    ----------
    enable_coverage : bool
        Flag indicating if code coverage is enabled.
    result_dir : Path
        Directory where simulation results are stored.
    uses_unisim : bool
        Flag indicating if Xilinx Unisim library is being used.
    uses_unifast : bool
        Flag indicating if Xilinx Unifast library is being used.
    VU : Optional[VUnit]
        VUnit instance being configured.
    """

    def __init__(self) -> None:
        """Initialize the simulator."""
        self.enable_coverage: bool = False
        self.result_dir: Path = Path.cwd() / "bench" / "results"
        self.uses_unisim: bool = False
        self.uses_unifast: bool = False
        self.VU: VUnit | None = None

        self._simulator_in_path()
        self._set_os_environment()

    @abstractmethod
    def _simulator_in_path(self) -> None:
        """Check if the simulator executable exists in PATH.

        Raises
        ------
        SystemExit
            If the simulator executable is not found.
        """
        pass

    @abstractmethod
    def _set_os_environment(self) -> None:
        """Set the operating system environment variables for the simulator."""
        pass

    def add_library(self, VU: VUnit, library_name: str, library_path: str) -> None:
        """Add an external library to VUnit.

        Parameters
        ----------
        VU : VUnit
            The VUnit instance.
        library_name : str
            Name of the library.
        library_path : str
            Path to the library directory.
        """
        expanded_path: str = os.path.expanduser(library_path)
        VU.add_external_library(library_name=library_name, path=expanded_path)

    @abstractmethod
    def add_unisim_library(self, VU: VUnit, unisim_path: str | None = None) -> None:
        """Add the Xilinx Unisim library to VUnit.

        Parameters
        ----------
        VU : VUnit
            The VUnit instance.
        unisim_path : Optional[str]
            Custom path to the Unisim library. Uses default if None.
        """
        pass

    @abstractmethod
    def add_unifast_library(self, VU: VUnit, unifast_path: str | None = None) -> None:
        """Add the Xilinx Unifast library to VUnit.

        Parameters
        ----------
        VU : VUnit
            The VUnit instance.
        unifast_path : Optional[str]
            Custom path to the Unifast library. Uses default if None.
        """
        pass

    @abstractmethod
    def configure(self, VU: VUnit) -> None:
        """Configure the simulator with specific settings.

        Parameters
        ----------
        VU : VUnit
            The VUnit instance to configure.
        """
        pass

    @abstractmethod
    def setup_coverage(self, VU: VUnit, **kwargs) -> None:
        """Set up code coverage for the simulator.

        Parameters
        ----------
        VU : VUnit
            The VUnit instance to configure.
        **kwargs
            Simulator-specific coverage configuration options.
        """
        pass

    def copy_output_log(self) -> None:
        """Copy the simulator output log to the results directory."""
        if self.VU is None:
            return

        output_folder = Path(self.VU._output_path)
        output_files: list[Path] = list(output_folder.glob("**/output.txt"))

        if output_files:
            # Take the first match (should only be one)
            output_file: Path = output_files[0]
            self.result_dir.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src=output_file, dst=self.result_dir / "output.txt")

    @abstractmethod
    def post_run(self, results: Results) -> None:
        """Actions to perform after the simulation run.

        Parameters
        ----------
        results : Results
            The simulation results from VUnit.
        """
        pass


class NVC(Simulator):
    """NVC simulator implementation."""

    DEFAULT_UNISIM_PATH = SimulatorConfig.NVC_UNISIM_PATH
    DEFAULT_UNIFAST_PATH = SimulatorConfig.NVC_UNIFAST_PATH

    def _simulator_in_path(self) -> None:
        """Check if NVC simulator is in PATH."""
        if shutil.which("nvc") is None:
            raise SystemExit("ERROR: nvc executable not found!")

    def _set_os_environment(self) -> None:
        """Set the operating system environment variables for NVC."""
        os.environ["VUNIT_SIMULATOR"] = SimulatorConfig.NVC

    def add_unisim_library(self, VU: VUnit, unisim_path: str | None = None) -> None:
        """Add the Xilinx Unisim library to VUnit."""
        path: str = unisim_path or self.DEFAULT_UNISIM_PATH
        self.add_library(VU=VU, library_name="unisim", library_path=path)
        self.uses_unisim = True

    def add_unifast_library(self, VU: VUnit, unifast_path: str | None = None) -> None:
        """Add the Xilinx Unifast library to VUnit."""
        path: str = unifast_path or self.DEFAULT_UNIFAST_PATH
        self.add_library(VU=VU, library_name="unifast", library_path=path)
        self.uses_unifast = True

    def configure(self, VU: VUnit) -> None:
        """Configure the NVC simulator with specific settings."""
        VU.set_sim_option(name="nvc.global_flags", value=["--ieee-warnings=off-at-0"])

        if not self.enable_coverage:
            VU.set_attribute(name="run_all_in_same_sim", value=False)

    def setup_coverage(self, VU: VUnit, specifications: list[str] | None = None, **kwargs) -> None:
        """Set up code coverage for NVC.

        Parameters
        ----------
        VU : VUnit
            The VUnit instance to configure.
        specifications : Optional[list[str]]
            Coverage specifications to include in the spec file.
        """
        self.enable_coverage = True
        self.VU: VUnit = VU

        # NVC requires all simulations in the same run for coverage
        VU.set_attribute(name="run_all_in_same_sim", value=True)

        output_path = Path(VU._output_path)
        output_path.mkdir(parents=True, exist_ok=True)

        # Define coverage flags
        coverage_flags: list[str] = [
            "--cover=statement,branch,expression,fsm-state,count-from-undefined,exclude-unreachable",
            f"--cover-file={output_path}/coverage.ncdb",
        ]

        # Create coverage specification file if provided
        if specifications:
            spec_file: Path = output_path / "coverage.spec"
            try:
                with open(file=spec_file, mode="w") as f:
                    f.write("\n".join(specifications) + "\n")
                coverage_flags.append(f"--cover-spec={spec_file}")
            except OSError as e:
                raise RuntimeError(f"Failed to create coverage spec file: {e}")

        VU.set_sim_option(name="nvc.elab_flags", value=coverage_flags)

    def post_run(self, results: Results) -> None:
        """Actions to perform after the simulation run."""
        self.copy_output_log()

        if not self.enable_coverage or self.VU is None:
            return

        self._generate_coverage_report()

    def _generate_coverage_report(self) -> None:
        """Generate NVC coverage report."""
        output_path: Path = Path(self.VU._output_path)
        ncdb_file: Path = output_path / "coverage.ncdb"
        coverage_dir: Path = output_path / "coverage_report"

        if not ncdb_file.exists():
            print(f"Warning: Coverage database not found at {ncdb_file}", file=sys.stderr)
            return

        coverage_dir.mkdir(parents=True, exist_ok=True)

        nvc_coverage_cmd: list[str] = [
            "nvc",
            "--cover-report",
            "-o",
            str(coverage_dir),
            str(ncdb_file),
        ]

        try:
            run(args=nvc_coverage_cmd, check=True)

            # Copy coverage database to results directory
            self.result_dir.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src=ncdb_file, dst=self.result_dir / "coverage.ncdb")

        except CalledProcessError as e:
            print(f"Coverage report generation failed: {e.stderr}", file=sys.stderr)
            raise


class GHDL(Simulator):
    """GHDL simulator implementation."""

    DEFAULT_UNISIM_PATH = SimulatorConfig.GHDL_UNISIM_PATH
    DEFAULT_UNIFAST_PATH = SimulatorConfig.GHDL_UNIFAST_PATH

    def _simulator_in_path(self) -> None:
        """Check if GHDL simulator is in PATH."""
        if shutil.which("ghdl") is None:
            raise SystemExit("ERROR: ghdl executable not found!")

    def _set_os_environment(self) -> None:
        """Set the operating system environment variables for GHDL."""
        os.environ["VUNIT_SIMULATOR"] = SimulatorConfig.GHDL

    def add_unisim_library(self, VU: VUnit, unisim_path: str | None = None) -> None:
        """Add the Xilinx Unisim library to VUnit."""
        path: str = unisim_path or self.DEFAULT_UNISIM_PATH
        self.add_library(VU=VU, library_name="unisim", library_path=path)
        self.uses_unisim = True

    def add_unifast_library(self, VU: VUnit, unifast_path: str | None = None) -> None:
        """Add the Xilinx Unifast library to VUnit."""
        path: str = unifast_path or self.DEFAULT_UNIFAST_PATH
        self.add_library(VU=VU, library_name="unifast", library_path=path)
        self.uses_unifast = True

    def configure(self, VU: VUnit) -> None:
        """Configure the GHDL simulator with specific settings."""
        self.VU = VU

        VU.set_compile_option(name="ghdl.a_flags", value=["--warn-no-hide"])
        VU.set_sim_option(name="ghdl.sim_flags", value=["--asserts=disable-at-0"])

        if self.uses_unisim or self.uses_unifast:
            VU.add_compile_option(name="ghdl.a_flags", value=["-fsynopsys", "-frelaxed"])
            VU.set_sim_option(name="ghdl.elab_flags", value=["-fsynopsys", "-frelaxed"])

    def setup_coverage(self, VU: VUnit, libraries: tuple[Library, Library] | None = None, **kwargs) -> None:
        """Set up code coverage for GHDL.

        Parameters
        ----------
        VU : VUnit
            The VUnit instance to configure.
        libraries : Optional[Tuple[Library, Library]]
            Tuple of (LIB_SRC, LIB_BENCH) libraries to enable coverage on.
        """
        if libraries is None:
            raise ValueError("GHDL coverage requires (LIB_SRC, LIB_BENCH) libraries tuple")

        self.enable_coverage = True
        self.VU = VU

        LIB_SRC, LIB_BENCH = libraries
        LIB_SRC.set_compile_option(name="enable_coverage", value=True)
        LIB_BENCH.set_compile_option(name="enable_coverage", value=True)
        LIB_BENCH.set_sim_option(name="enable_coverage", value=True)

    def post_run(self, results: Results) -> None:
        """Actions to perform after the simulation run."""
        self.copy_output_log()

        if not self.enable_coverage or self.VU is None:
            return

        self._generate_coverage_report(results=results)

    def _generate_coverage_report(self, results: Results) -> None:
        """Generate GHDL coverage report."""
        output_path: Path = Path(self.VU._output_path)
        coverage_dir: Path = output_path / "coverage_report"
        coverage_dir.mkdir(parents=True, exist_ok=True)

        try:
            results.merge_coverage(file_name=str(coverage_dir))

            if results._simulator_if._backend == "gcc":
                self._generate_gcc_coverage_report(coverage_dir=coverage_dir)

        except Exception as e:
            print(f"Coverage report generation failed: {e}", file=sys.stderr)
            raise

    def _generate_gcc_coverage_report(self, coverage_dir: Path) -> None:
        """Generate GCC-based coverage report using lcov/genhtml."""
        coverage_info: Path = coverage_dir / "code_coverage.info"
        html_dir: Path = coverage_dir / "html_report"

        lcov_cmd: list[str] = [
            "lcov",
            "--capture",
            "--directory",
            str(coverage_dir),
            "--output-file",
            str(coverage_info),
            "--rc",
            "branch_coverage=1",
            "--ignore-errors",
            "mismatch",
        ]

        # Run lcov
        run(
            args=lcov_cmd,
            check=True,
        )

        html_report_cmd: list[str] = [
            "genhtml",
            str(coverage_info),
            "--output-directory",
            str(html_dir),
            "--ignore-errors",
            "source",
            "--ignore-errors",
            "unmapped",
        ]

        # Run genhtml
        run(args=html_report_cmd, check=True, capture_output=True)


def select_simulator(simulator_name: str | None = None) -> Simulator:
    """Select and return the appropriate simulator instance.

    Parameters
    ----------
    simulator_name : Optional[str]
        The name of the simulator to select ('nvc' or 'ghdl').
        If None, automatically selects based on available executables.

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
            simulator_name = SimulatorConfig.NVC
        elif shutil.which("ghdl") is not None:
            simulator_name = SimulatorConfig.GHDL
        else:
            raise SystemExit("ERROR: No supported simulator found in PATH!")

    simulator_name_lower: str = simulator_name.lower()

    if simulator_name_lower == SimulatorConfig.NVC:
        return NVC()
    elif simulator_name_lower == SimulatorConfig.GHDL:
        return GHDL()
    else:
        raise ValueError(
            f"Unsupported simulator: {simulator_name}. "
            f"Supported simulators: {SimulatorConfig.NVC}, {SimulatorConfig.GHDL}"
        )
