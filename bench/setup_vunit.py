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
## @version 3.0
## @brief   This module provides simulator classes for VUnit.
## @author  Timothee Charrier
## =====================================================================================================================
## REVISION HISTORY
##
## Version  Date        Author              Description
## -------  ----------  ------------------  ----------------------------------------------------------------------------
## 1.0      01/11/2025  Timothee Charrier   Initial release
## 2.0      07/01/2026  Timothee Charrier   Major refactor: VUnit now supports NVC coverage, no need for a custom
##                                          interface.
## 2.1      11/04/2026  Timothee Charrier   Add Unisim and Unifast library path retrieval methods
## 2.2      17/04/2026  Timothee Charrier   Add `get_simulator_name` method to Simulator base class
## 2.3      07/05/2026  Timothee Charrier   Add coverage report generation methods for GHDL and initial Questa or
##                                          ModelSim support
## 2.4      10/05/2026  Timothee Charrier   Add custom vhdl_ls.toml generation method
## 2.5      14/05/2026  Timothee Charrier   Update results directory to be at the same level as the testbench directory.
##                                          Fix a runtime error with GHDL invalid option.
## 2.6      17/05/2026  Timothee Charrier   Now takes the run file directory as an argument to properly handle the
##                                          results directory and coverage specific options.
##          18/05/2026                      Only enable coverage for the libraries we want to cover instead of globally,
##                                          as coverage can significantly reduce performance.
##          22/05/2026                      Add unisim and unifast workarounds for Questa/ModelSim support, which is
##                                          currently very slow due to issues with pre-compilation of these libraries.
## 2.7      29/07/2026  Timothee Charrier   Improve output return from `get_..._path` methods.
##                                          Improve library path handling and error reporting
##                                          Create a `create_vunit_cli` and `create_vunit` functions to simplify VUnit
##                                          setup and CLI handling.
## 3.0      14/08/2026  Timothee Charrier   Major refactor: add `VivadoPathHelper` and `VUnitProject` classes to better
##                                          handle the simulation/non-simulation modes.
## =====================================================================================================================

import logging
import os
import re
import shutil
from abc import ABC, abstractmethod
from argparse import Namespace
from pathlib import Path
from typing import TYPE_CHECKING, Any, ClassVar, TypeAlias

import rtoml
from vunit import VUnit, VUnitCLI
from vunit.ostools import Process
from vunit.ui.results import Results

if TYPE_CHECKING:
    from vunit.ui.library import Library

LOGGER: logging.Logger = logging.getLogger(name=__name__)
VhdlLsToml: TypeAlias = dict[str, Any]


class VivadoPathHelper:
    """Resolve Vivado VHDL source paths.

    Unisim files:
        - unisim_VPKG.vhd: Usually located under        `vivado_path/data/vhdl/src/unisims/unisim_VPKG.vhd`
        - unisim_VCOMP.vhd: Usually located under       `vivado_path/data/vhdl/src/unisims/unisim_VCOMP.vhd`
        - Unisim primitive files: Usually located under `vivado_path/data/vhdl/src/unisims/primitive/*.vhd`

    Unifast files:
        - Unifast primitive files: Usually located under `vivado_path/data/vhdl/src/unifast/primitive/*.vhd`
    """

    def __init__(self) -> None:
        """Initialize an unresolved Vivado installation path."""
        self._vivado_path: Path | None = None
        self._is_resolved: bool = False

    def _resolve_vivado_path(self, *, warn: bool) -> Path | None:
        """Resolve and store the Vivado installation path."""
        if self._is_resolved:
            return self._vivado_path

        self._is_resolved = True
        executable_path: str | None = shutil.which(cmd="vivado")

        if not executable_path:
            if warn:
                LOGGER.warning("Vivado executable not found in PATH!")
            return None

        installation_path: Path = Path(executable_path).resolve().parent.parent

        if not (installation_path / "data" / "vhdl").is_dir():
            if warn:
                LOGGER.warning("Vivado VHDL data directory not found under %s", installation_path)
            return None

        self._vivado_path = installation_path
        return self._vivado_path

    def is_available(self) -> bool:
        """Return whether Vivado VHDL sources are available without logging a warning."""
        return self._resolve_vivado_path(warn=False) is not None

    def get_vivado_path(self) -> Path | None:
        """Return the Vivado installation path when its VHDL sources are available."""
        return self._resolve_vivado_path(warn=True)

    def _get_source_path(self, relative_path: Path, description: str, *, directory: bool = False) -> Path | None:
        """Return a Vivado source path when it exists."""
        vivado_path: Path | None = self.get_vivado_path()

        if vivado_path is None:
            return None

        source_path: Path = vivado_path / relative_path
        exists: bool = source_path.is_dir() if directory else source_path.is_file()

        if not exists:
            LOGGER.warning("%s not found at %s", description, source_path)
            return None

        return source_path

    def get_unisim_vcomp_path(self) -> Path | None:
        """Return the Unisim component declaration file."""
        return self._get_source_path(
            relative_path=Path("data/vhdl/src/unisims/unisim_VCOMP.vhd"),
            description="Unisim VCOMP file",
        )

    def get_unisim_vpkg_path(self) -> Path | None:
        """Return the Unisim package file."""
        return self._get_source_path(
            relative_path=Path("data/vhdl/src/unisims/unisim_VPKG.vhd"),
            description="Unisim VPKG file",
        )

    def get_unisim_primitive_path(self) -> Path | None:
        """Return the glob for Unisim primitive source files."""
        primitive_path: Path | None = self._get_source_path(
            relative_path=Path("data/vhdl/src/unisims/primitive"),
            description="Unisim primitive directory",
            directory=True,
        )
        return primitive_path / "*.vhd" if primitive_path is not None else None

    def get_unifast_primitive_path(self) -> Path | None:
        """Return the glob for Unifast primitive source files."""
        primitive_path: Path | None = self._get_source_path(
            relative_path=Path("data/vhdl/src/unifast/primitive"),
            description="Unifast primitive directory",
            directory=True,
        )
        return primitive_path / "*.vhd" if primitive_path is not None else None

    def get_vhdl_ls_external_libraries(self) -> list[tuple[Path, str]]:
        """Return available Vivado source paths tagged with their VHDL library names."""
        optional_libraries: list[tuple[Path | None, str]] = [
            (self.get_unifast_primitive_path(), "unifast"),
            (self.get_unisim_vcomp_path(), "unisim"),
            (self.get_unisim_vpkg_path(), "unisim"),
        ]
        return [(path, library_name) for path, library_name in optional_libraries if path is not None]


class VUnitProject:
    """VUnit project that owns its VUnit instance."""

    THIRD_PARTY_LIBRARIES: ClassVar[set[str]] = {"vunit_lib", "osvvm", "unisim", "unifast", "xil_defaultlib"}

    def __init__(
        self,
        args: Namespace,
        run_file_dir: Path | None = None,
        add_random: bool = False,
        vivado_paths: VivadoPathHelper | None = None,
    ) -> None:
        """Initialize the VUnit project.

        Parameters
        ----------
        args : Namespace
            Parsed VUnit and simulator command-line arguments.
        run_file_dir : Path
            Directory containing the run file.
        add_random : bool
            Add the VUnit random package. Defaults to False.
        vivado_paths : VivadoPathHelper | None
            Vivado source path resolver. Defaults to a new helper.
        """
        # CLI arguments
        self.args: Namespace = args
        self.vivado_paths: VivadoPathHelper = vivado_paths or VivadoPathHelper()
        self._requires_unisim: bool = False

        # Paths
        self.run_file_dir: Path = run_file_dir or Path.cwd()
        self.results_dir: Path = self.run_file_dir / "results"

        # Prepare the environment before creating the VUnit instance
        self._prepare_environment()

        # Create the VUnit instance and add required built-ins and verification components
        self.vu: VUnit = VUnit.from_args(args=args)
        self.vu.add_vhdl_builtins()
        self.vu.add_verification_components()

        if add_random:
            self.vu.add_random()

    @property
    def enable_coverage(self) -> bool:
        """Return whether coverage collection is enabled."""
        return bool(self.args.coverage)

    @property
    def vhdl_ls(self) -> bool:
        """Return whether VHDL-LS configuration generation is requested."""
        return bool(self.args.vhdl_ls)

    @property
    def use_unisim(self) -> bool:
        """Return whether the Vivado Unisim PLL model is requested."""
        return self._requires_unisim and not bool(self.args.without_unisim)

    def require_unisim(self) -> None:
        """Declare that this project requires selecting a PLL simulation model."""
        self._requires_unisim = True

    @classmethod
    def create(
        cls,
        args: Namespace,
        run_file_dir: Path,
        add_random: bool = True,
    ) -> "VUnitProject":
        """Create a file-only project or simulator-backed project from parsed CLI arguments."""
        if args.vhdl_ls:
            return cls(
                args=args,
                run_file_dir=run_file_dir,
                add_random=add_random,
            )
        return _create_simulator(
            args=args,
            run_file_dir=run_file_dir,
            add_random=add_random,
        )

    def execute(
        self,
        output_path: Path | None = None,
        external_libraries: list[tuple[Path, str]] | None = None,
    ) -> None:
        """Generate VHDL-LS configuration or run the selected simulator."""
        # Check if Vivado Unisim sources are available when requested
        if self.use_unisim and not self.vivado_paths.is_available():
            raise SystemExit(
                "ERROR: Vivado Unisim sources are unavailable. "
                "Pass --without-unisim to use the behavioral PLL model explicitly."
            )

        # Generate VHDL-LS configuration if requested
        if self.vhdl_ls:
            libraries: list[tuple[Path, str]] = list(external_libraries or [])

            if self.use_unisim:
                vivado_libraries: list[tuple[Path, str]] = self.vivado_paths.get_vhdl_ls_external_libraries()
                libraries.extend(vivado_libraries)

                # To avoid warnings in the the vivado simulation netlist, define unisim to Vunit
                self.vu.add_external_library(library_name="unisim", path=str(self.vivado_paths.get_unisim_vpkg_path()))

            self.generate_vhdl_ls_toml(external_libraries=libraries, output_path=output_path)
            return

        self._execute_simulation(use_unisim=self.use_unisim)

    def _prepare_environment(self) -> None:
        """Prepare the environment before creating the VUnit instance."""

    def _execute_simulation(self, *, use_unisim: bool) -> None:
        """Reject simulation for projects without a simulator backend."""
        raise TypeError("Simulation mode requires a simulator-backed VUnit project")

    def _add_file_to_vhdl_ls_config(
        self,
        toml_data: VhdlLsToml,
        file_path: Path,
        library_name: str,
    ) -> None:
        """Add a file to the vhdl_ls configuration."""
        libraries: dict[str, dict[str, Any]] = toml_data.setdefault("libraries", {})
        library_entry: dict[str, Any] = libraries.setdefault(library_name, {"files": []})

        # Exclude known third-party libraries from user code analysis
        if library_name in self.THIRD_PARTY_LIBRARIES:
            library_entry["is_third_party"] = True

        library_entry["files"].append(str(file_path.resolve()))

    def generate_vhdl_ls_toml(
        self,
        external_libraries: list[tuple[Path, str]] | None = None,
        output_path: Path | None = None,
    ) -> None:
        """Generate `vhdl_ls.toml` file for the rust_hdl VHDL Language Server (https://github.com/VHDL-LS/rust_hdl).

        Adapted from `cores/open-logic/sim/create_vhdl_ls_config.py` to be used with the VUnit project.
        See https://github.com/open-logic/open-logic/blob/main/sim/create_vhdl_ls_config.py for the original version.

        Parameters
        ----------
        external_libraries : list[tuple[Path, str]] | None
            List of tuples containing library paths and names to include in the configuration. Defaults to None.
            Example: [(Path("/path/to/unisim_VPKG.vhd"), "unisim")]
        output_path : Path | None
            Directory to save the generated configuration file. Defaults to the project root.
        """
        if output_path is None:
            output_path = Path.cwd()

        toml_data: VhdlLsToml = {"libraries": {}}

        # Add files from the VUnit project
        for source_file in self.vu.get_compile_order():
            self._add_file_to_vhdl_ls_config(
                toml_data=toml_data,
                file_path=Path(source_file.name),
                library_name=source_file.library.name,
            )

        # Add external libraries if provided
        for file_path, library_name in external_libraries or []:
            self._add_file_to_vhdl_ls_config(
                toml_data=toml_data,
                file_path=file_path,
                library_name=library_name,
            )

        # Ignore unused work library statement
        toml_data.setdefault("lint", {})["unnecessary_work_library"] = False

        # Write the TOML data to a file
        config_file: Path = output_path / "vhdl_ls.toml"
        try:
            with open(file=config_file, mode="w", encoding="utf-8") as f:
                rtoml.dump(obj=toml_data, file=f, pretty=True)
            LOGGER.info("vhdl_ls configuration generated at: %s", config_file)
        except OSError as e:
            LOGGER.error("Failed to write vhdl_ls configuration: %s", e)
            raise


class Simulator(VUnitProject, ABC):
    """Abstract VUnit project backed by an HDL simulator."""

    SIMULATOR_NAME: str = ""
    EXECUTABLE: str = ""
    DEFAULT_LIBRARIES: ClassVar[dict[str, str]] = {}
    DEFAULT_LIBRARIES_TO_COVER: ClassVar[set[str]] = {"lib_bench"}

    def _prepare_environment(self) -> None:
        """Validate and select the simulator before creating VUnit."""
        self._check_results_dir()
        self._check_executable()
        self._set_environment()

    def _check_results_dir(self) -> None:
        """Check if the results directory exists and is writable."""
        if not self.results_dir.exists():
            try:
                self.results_dir.mkdir(parents=True, exist_ok=True)
            except OSError as e:
                raise SystemExit(f"ERROR: Could not create results directory at {self.results_dir} - {e}") from e
        elif not os.access(path=self.results_dir, mode=os.W_OK):
            raise SystemExit(f"ERROR: Results directory is not writable: {self.results_dir}")

    def _check_executable(self) -> None:
        """Check if the simulator executable is available."""
        if not shutil.which(cmd=self.EXECUTABLE):
            raise SystemExit(f"ERROR: {self.EXECUTABLE} executable not found in PATH!")

    def _set_environment(self) -> None:
        """Set environment variables for the simulator."""
        os.environ["VUNIT_SIMULATOR"] = self.SIMULATOR_NAME

    def _get_output_path(self) -> Path:
        """Return VUnit's configured output path."""
        return Path(self.vu._output_path)

    @staticmethod
    def _uses_gcc_backend(results: Results) -> bool:
        """Return whether GHDL uses its GCC backend."""
        return results._simulator_if._backend == "gcc"

    def add_library(self, library_name: str, library_path: str | None = None) -> "Simulator":
        """Add an external precompiled library to VUnit."""
        path: str | None = library_path or self.DEFAULT_LIBRARIES.get(library_name)
        if not path:
            raise SystemExit(f"ERROR: No path configured for library '{library_name}'")

        self.vu.add_external_library(library_name=library_name, path=str(Path(path).expanduser()))
        return self

    def get_libraries_to_cover(self) -> list["Library"]:
        """Return the VUnit libraries included in coverage collection."""
        libraries_by_name: dict[str, "Library"] = {  # noqa: UP037
            library.name: library for library in self.vu.get_libraries()
        }
        return [libraries_by_name[name] for name in self.DEFAULT_LIBRARIES_TO_COVER if name in libraries_by_name]

    def configure(self) -> "Simulator":
        """Apply simulator-specific options after project source registration."""
        self._apply_options()
        return self

    def _execute_simulation(self, *, use_unisim: bool) -> None:
        """Configure and run the simulator with optional Vivado libraries."""
        simulator: Simulator = self.configure()
        LOGGER.info("Using simulator %s with executable %s", simulator.SIMULATOR_NAME, simulator.EXECUTABLE)

        if use_unisim:
            simulator.add_library(library_name="unisim")
            simulator.add_library(library_name="unifast")

        simulator.vu.main(post_run=simulator.post_run)

    def _merge_output_files(self, results: Results) -> None:
        """Merge output files from tests in the current run into a single file."""
        output_file: Path = self.results_dir / "output.txt"
        test_results = results.get_report().tests

        if not test_results:
            LOGGER.warning("No test results found for output merge")
            return

        with open(file=output_file, mode="w", encoding="utf-8") as outfile:
            LOGGER.info("Merging output from %d tests...", len(test_results))

            for test_name, test_result in sorted(test_results.items()):
                txt_file: Path = test_result.path / "output.txt"
                # Write a header with the test name
                outfile.write(f"\n{'=' * 80}\n")
                outfile.write(f"Test: {test_name}\n")
                outfile.write(f"Path: {test_result.relpath}\n")
                outfile.write(f"{'=' * 80}\n\n")

                # Write the contents of the file
                try:
                    with open(file=txt_file, encoding="utf-8") as infile:
                        outfile.write(infile.read())
                except (OSError, UnicodeDecodeError) as e:
                    outfile.write(f"[ERROR: Could not read file - {e}]\n")
                    LOGGER.error("Failed to read %s: %s", txt_file, e)

        LOGGER.info("Successfully merged output files to: %s", output_file)

    @abstractmethod
    def _apply_options(self) -> None:
        """Apply simulator-specific VUnit options."""

    @abstractmethod
    def _generate_coverage(self, results: Results) -> None:
        """Generate the simulator-specific coverage report."""

    def post_run(self, results: Results) -> None:
        """Execute post-run actions.

        This method is used as VUnit's post_run callback.

        Parameters
        ----------
        results : Results
            The simulation results from VUnit.
        """
        self._merge_output_files(results=results)

        if self.enable_coverage:
            self._generate_coverage(results=results)


class NVC(Simulator):
    """NVC simulator implementation."""

    SIMULATOR_NAME: str = "nvc"
    EXECUTABLE: str = "nvc"
    DEFAULT_LIBRARIES: ClassVar[dict[str, str]] = {
        "unisim": "~/.nvc/lib/unisim.08",
        "unifast": "~/.nvc/lib/unifast.08",
    }

    def _apply_options(self) -> None:
        """Apply NVC-specific options."""
        # Base flags always applied
        global_flags: list[str] = ["--ieee-warnings=off"]
        elab_flags: list[str] = []
        sim_flags: list[str] = []

        # Add coverage flags if enabled
        if self.enable_coverage:
            coverage_spec_path: Path = self.run_file_dir / "coverage.spec"
            if not coverage_spec_path.exists():
                LOGGER.warning(
                    "Coverage spec file not found at %s. Coverage will be enabled but may not work properly "
                    "without a valid spec file.",
                    coverage_spec_path,
                )

            elab_flags.append(f"--cover-spec={coverage_spec_path}")

            # Coverage reduces performance, so we only enable it for the libraries we want to cover instead of globally.
            # Coverage on `lib_bench` is enough for nvc. Add more libraries to
            # `DEFAULT_LIBRARIES_TO_COVER` when needed.
            libs_to_cover: list["Library"] = self.get_libraries_to_cover()  # noqa: UP037

            for lib in libs_to_cover:
                lib.set_sim_option(name="enable_coverage", value=True)
                lib.set_sim_option(
                    name="nvc.elab_flags",
                    value=["--cover=statement,branch,expression,fsm-state,count-from-undefined,exclude-unreachable"],
                    overwrite=False,
                )

        self.vu.set_sim_option(name="nvc.global_flags", value=global_flags, overwrite=False)
        self.vu.set_sim_option(name="nvc.elab_flags", value=elab_flags, overwrite=False)
        self.vu.set_sim_option(name="nvc.sim_flags", value=sim_flags, overwrite=False)

    def _generate_coverage(self, results: Results) -> None:
        """Generate NVC coverage report.

        Parameters
        ----------
        results : Results
            The simulation results from VUnit.
        """
        output_path: Path = self._get_output_path()
        coverage_file: Path = output_path / "coverage_data"
        coverage_dir: Path = output_path / "coverage_report_nvc"

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
        cmd: list[str] = ["nvc", "--cover-report", str(coverage_db), "-o", str(coverage_dir)]
        process: Process[list[str]] = Process(args=cmd)
        process.consume_output()
        LOGGER.info("Coverage report generated at %s", coverage_dir)

        # Copy to results directory
        self.results_dir.mkdir(parents=True, exist_ok=True)
        output_file: Path = self.results_dir / "coverage_data.ncdb"
        shutil.copy2(src=coverage_db, dst=output_file)
        LOGGER.info("Coverage database copied to %s", output_file)


class GHDL(Simulator):
    """GHDL simulator implementation."""

    SIMULATOR_NAME: str = "ghdl"
    EXECUTABLE: str = "ghdl"
    DEFAULT_LIBRARIES: ClassVar[dict[str, str]] = {
        "unisim": "~/.ghdl/xilinx-vivado/unisim/v08",
        "unifast": "~/.ghdl/xilinx-vivado/unifast/v08",
    }

    def _apply_options(self) -> None:
        """Apply GHDL-specific options."""
        # Base flags always applied
        analysis_flags: list[str] = ["-fsynopsys", "-frelaxed", "--warn-no-hide"]
        elab_flags: list[str] = ["-fsynopsys", "-frelaxed"]
        sim_flags: list[str] = ["--ieee-asserts=disable"]

        if self.enable_coverage:
            # Coverage reduces performance, so we only enable it for the libraries we want to cover instead of globally.
            # Coverage on `lib_bench` is enough for ghdl.
            libs_to_cover: list["Library"] = self.get_libraries_to_cover()  # noqa: UP037

            for lib in libs_to_cover:
                lib.set_sim_option(name="enable_coverage", value=True)

        self.vu.add_compile_option(name="ghdl.a_flags", value=analysis_flags)
        self.vu.set_sim_option(name="ghdl.elab_flags", value=elab_flags, overwrite=False)
        self.vu.set_sim_option(name="ghdl.sim_flags", value=sim_flags, overwrite=False)

    def _check_gcovr(self) -> bool:
        """Check if gcovr is available for coverage generation.

        Returns
        -------
        bool
            True if gcovr is available, False otherwise.
        """
        if not shutil.which(cmd="gcovr"):
            LOGGER.warning("gcovr executable not found in PATH! Coverage generation will be disabled.")
            return False
        return True

    def _generate_gcc_coverage(self, coverage_file: Path, html_report: Path) -> None:
        """Generate coverage report using gcovr with GCC backend.

        Parameters
        ----------
        coverage_file : Path
            The path to the coverage data file.
        html_report : Path
            The path to the HTML report file.
        """
        cmd: list[str] = [
            "gcovr",
            str(coverage_file),
            "--output",
            str(html_report),
            "--html",
            "--html-details",
        ]
        process: Process[list[str]] = Process(args=cmd)
        process.consume_output()

    @staticmethod
    def _fix_gcovr_json_version(json_file: Path) -> None:
        """Fix the version string in gcovr JSON coverage file to work around gcovr issues with GHDL coverage files.

        Parameters
        ----------
        json_file : Path
            The path to the JSON coverage file.
        """
        try:
            with open(file=json_file, encoding="utf-8") as f:
                content = f.read()

            # Normalize Windows backslashes to forward slashes in the JSON file
            content = content.replace("\\", "/")

            # Replace version string in JSON file
            content: str = re.sub(
                pattern=r'"gcovr/format_version":\s*"\d+\.\d+"', repl='"gcovr/format_version": "0.14"', string=content
            )

            with open(file=json_file, mode="w", encoding="utf-8") as f:
                f.write(content)

        except (OSError, UnicodeDecodeError) as e:
            LOGGER.error("Failed to modify gcovr.json: %s", e)

    def _generate_others_backend_coverage(self, json_file: Path, html_report: Path) -> None:
        """Generate coverage report using gcovr with JSON coverage file.

        Requires a workaround to fix the version string in the JSON file due to gcovr issues with GHDL coverage files.
        Without it, gcovr will fail with error `AssertionError: Wrong format version, got 0.6 expected 0.14.`

        Parameters
        ----------
        json_file : Path
            The path to the JSON coverage file.
        html_report : Path
            The path to the HTML report file.
        """
        self._fix_gcovr_json_version(json_file=json_file)

        cmd: list[str] = [
            "gcovr",
            "-a",
            str(json_file),
            "--output",
            str(html_report),
            "--html",
            "--html-details",
        ]
        process: Process[list[str]] = Process(args=cmd)
        process.consume_output()

    def _generate_coverage(self, results: Results) -> None:
        """Generate GHDL coverage report with gcovr JSON workaround.

        Parameters
        ----------
        results : Results
            The simulation results from VUnit.
        """
        if not self._check_gcovr():
            return

        output_path: Path = self._get_output_path()
        coverage_file: Path = output_path / "coverage_data"
        coverage_dir: Path = output_path / "coverage_report_ghdl"
        html_report: Path = coverage_dir / "index.html"
        coverage_dir.mkdir(parents=True, exist_ok=True)

        LOGGER.info("Merging coverage files into %s...", coverage_file)
        results.merge_coverage(file_name=str(coverage_file))
        LOGGER.info("Coverage files merged")

        if self._uses_gcc_backend(results=results):
            self._generate_gcc_coverage(coverage_file=coverage_file, html_report=html_report)
        else:
            json_file: Path = coverage_file / "gcovr.json"
            if not json_file.exists():
                LOGGER.warning("JSON coverage file not found: %s", json_file)
                return
            self._generate_others_backend_coverage(json_file=json_file, html_report=html_report)

        LOGGER.info("Coverage report generated at %s", html_report)


class QuestaModelSim(Simulator):
    """Questa/ModelSim simulator implementation."""

    SIMULATOR_NAME: str = "modelsim"
    EXECUTABLE: str = "vsim"
    DEFAULT_LIBRARIES_TO_COVER: ClassVar[set[str]] = {"lib_bench", "lib_rtl"}

    def add_library(self, library_name: str, library_path: str | None = None) -> "Simulator":
        """Add an external library to VUnit for Questa/ModelSim.

        Very slow workaround for unisim and unifast libraries,
        my current QuestaSim version fails to pre-compile with the `compxlib` command...

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
        if library_name not in {"unisim", "unifast"}:
            return super().add_library(library_name, library_path)

        LOGGER.warning(
            "Manually adding library '%s' with source files instead of using pre-compiled libraries. "
            "Expect very slow simulation times.",
            library_name,
        )

        if library_name == "unisim":
            unisim_vpkg_path: Path | None = self.vivado_paths.get_unisim_vpkg_path()
            unisim_vcomp_path: Path | None = self.vivado_paths.get_unisim_vcomp_path()
            unisim_primitive_path: Path | None = self.vivado_paths.get_unisim_primitive_path()
            if unisim_vpkg_path is None or unisim_vcomp_path is None or unisim_primitive_path is None:
                raise SystemExit("ERROR: Vivado Unisim source files are unavailable")

            unisim: Library = self.vu.add_library(library_name="unisim")
            unisim.add_source_file(file_name=unisim_vpkg_path)
            unisim.add_source_file(file_name=unisim_vcomp_path)
            unisim.add_source_files(pattern=unisim_primitive_path)

        elif library_name == "unifast":
            unifast_path: Path | None = self.vivado_paths.get_unifast_primitive_path()
            if unifast_path is None:
                raise SystemExit("ERROR: Vivado Unifast source files are unavailable")

            unifast: Library = self.vu.add_library(library_name="unifast")
            unifast.add_source_files(pattern=unifast_path)

        return self

    def _apply_options(self) -> None:
        """Apply Questa/ModelSim-specific options."""
        vcom_flags: list[str] = []
        vlog_flags: list[str] = []
        vsim_flags: list[str] = ["-t", "fs"]
        vopt_flags: list[str] = []
        three_step_flow: bool = True

        self.vu.set_compile_option(name="modelsim.vcom_flags", value=vcom_flags)
        self.vu.set_compile_option(name="modelsim.vlog_flags", value=vlog_flags)
        self.vu.set_sim_option(name="disable_ieee_warnings", value=True)
        self.vu.set_sim_option(name="modelsim.vsim_flags", value=vsim_flags, overwrite=False)
        self.vu.set_sim_option(name="modelsim.vopt_flags", value=vopt_flags, overwrite=False)
        self.vu.set_sim_option(name="modelsim.three_step_flow", value=three_step_flow)

        if self.enable_coverage:
            # Coverage reduces performance, so we only enable it for the libraries we want to cover instead of globally.
            # Coverage on `lib_bench` is not enough for Questa/ModelSim. Also need to add `lib_rtl`.
            libs_to_cover: list["Library"] = self.get_libraries_to_cover()  # noqa: UP037

            for lib in libs_to_cover:
                lib.set_compile_option(name="modelsim.vcom_flags", value=["+cover=bcefs"])
                lib.set_compile_option(name="modelsim.vlog_flags", value=["+cover=bcefs"])

                # Cannot enable simulation on a RTL-only library, only on the testbench library.
                if lib.name == "lib_bench":
                    lib.set_sim_option(name="enable_coverage", value=True)

    def _check_vcover(self) -> bool:
        """Check if vcover is available for coverage generation.

        Returns
        -------
        bool
            True if vcover is available, False otherwise.
        """
        if not shutil.which(cmd="vcover"):
            LOGGER.warning("vcover executable not found in PATH! Coverage generation will be disabled.")
            return False
        return True

    def _generate_coverage(self, results: Results) -> None:
        """Generate Questa/ModelSim coverage report.

        Parameters
        ----------
        results : Results
            The simulation results from VUnit.
        """
        if not self._check_vcover():
            return

        output_path: Path = self._get_output_path()
        coverage_file: Path = output_path / "coverage_data.ucdb"
        coverage_dir: Path = output_path / "coverage_report_questa"

        LOGGER.info("Merging coverage files into %s...", coverage_file)
        results.merge_coverage(file_name=str(coverage_file))
        LOGGER.info("Coverage files merged")

        # Generate coverage report
        LOGGER.info("Generating coverage report to %s...", coverage_dir)
        cmd: list[str] = [
            "vcover",
            "report",
            "-html",
            "-details",
            "-annotate",
            "-code",
            "bcefs",
            str(coverage_file),
            "-output",
            str(coverage_dir),
        ]
        process: Process[list[str]] = Process(args=cmd)
        process.consume_output()
        LOGGER.info("Coverage report generated at %s", coverage_dir)


def _create_simulator(
    args: Namespace,
    run_file_dir: Path,
    add_random: bool = False,
) -> Simulator:
    """Create the simulator selected by the command-line arguments or environment.

    If no simulator is specified, attempt to auto-detect one from the available executables.
    Prioritize:
        1. NVC
        2. GHDL
        3. Questa/ModelSim

    Parameters
    ----------
    args : Namespace
        Parsed VUnit and simulator command-line arguments.
    run_file_dir : Path
        Directory of the `run.py` file.
    add_random : bool
        Add the VUnit random package. Defaults to False.

    Returns
    -------
    Simulator
        Configured simulator instance.

    Raises
    ------
    SystemExit
        If the selected simulator is unknown or if no suitable simulator is found during auto-detection.
    """
    simulators: dict[str, type[Simulator]] = {
        "nvc": NVC,
        "ghdl": GHDL,
        "questa": QuestaModelSim,
        "modelsim": QuestaModelSim,
    }

    simulator_name: str | None = args.simulator or os.environ.get("VUNIT_SIMULATOR")
    if not simulator_name:
        for simulator_class in (NVC, GHDL, QuestaModelSim):
            if shutil.which(cmd=simulator_class.EXECUTABLE):
                simulator_name = simulator_class.SIMULATOR_NAME
                break

    simulator_class: type[Simulator] | None = simulators.get(simulator_name)
    if simulator_class is None:
        LOGGER.error(
            (
                "Could not determine simulator to use from args or VUNIT_SIMULATOR."
                "Please specify a simulator with --nvc, --ghdl, --modelsim, or --questa."
            ),
        )
        raise SystemExit(1)

    return simulator_class(
        args=args,
        run_file_dir=run_file_dir,
        add_random=add_random,
    )


def create_vunit_cli() -> VUnitCLI:
    """Create a VUnit CLI with the simulator options shared by all benches."""
    cli = VUnitCLI()

    #
    # Default options
    #

    cli.parser.set_defaults(
        log_level="INFO",
    )

    cli.parser.add_argument(
        "--without-unisim",
        "--without_unisim",
        dest="without_unisim",
        action="store_true",
        help="Use a custom behavioral PLL model (faster simulation without needing Vivado pre-compiled libraries)",
    )

    #
    # VHDL-LS Toml generation option
    #

    cli.parser.add_argument(
        "--vhdl-ls",
        "--vhdl_ls",
        dest="vhdl_ls",
        action="store_true",
        help="Generate the vhdl_ls configuration without running simulation",
    )

    #
    # Simulator selection
    #

    simulator_group = cli.parser.add_mutually_exclusive_group()
    simulator_group.add_argument(
        "--nvc",
        dest="simulator",
        action="store_const",
        const="nvc",
        help="Use nvc as the simulator",
    )
    simulator_group.add_argument(
        "--ghdl",
        dest="simulator",
        action="store_const",
        const="ghdl",
        help="Use GHDL as the simulator",
    )
    simulator_group.add_argument(
        "--modelsim",
        dest="simulator",
        action="store_const",
        const="modelsim",
        help="Use ModelSim as the simulator",
    )
    simulator_group.add_argument(
        "--questa",
        dest="simulator",
        action="store_const",
        const="questa",
        help="Use Questa as the simulator",
    )

    #
    # Simulation options
    #

    cli.parser.add_argument(
        "--coverage",
        action="store_true",
        help="Enable coverage collection and reporting",
    )

    return cli
