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
## @version 2.6
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
## =====================================================================================================================

import logging
import os
import re
import shutil
from abc import ABC, abstractmethod
from pathlib import Path
from typing import TYPE_CHECKING, Any, TypeAlias, override

import rtoml
from vunit import VUnit
from vunit.ostools import Process
from vunit.ui.results import Results

if TYPE_CHECKING:
    from vunit.ui.library import Library

LOGGER: logging.Logger = logging.getLogger(name=__name__)
VHDL_LS_TOML: TypeAlias = dict[str, Any]


class Simulator(ABC):
    """Abstract base class for HDL simulators."""

    SIMULATOR_NAME: str = ""
    EXECUTABLE: str = ""
    DEFAULT_LIBRARIES: dict[str, str] = {}
    THIRD_PARTY_LIBRARIES: set[str] = {"vunit_lib", "osvvm", "unisim", "unifast", "xil_defaultlib"}
    DEFAULT_LIBRARIES_TO_COVER: set[str] = {"lib_bench"}

    def __init__(self, enable_coverage: bool = False, run_file_dir: Path | None = None) -> None:
        """Initialize the simulator.

        Parameters
        ----------
        enable_coverage : bool
            Enable coverage collection and reporting. Defaults to False.
        run_file_dir : Path
            Directory containing the run file.
        """
        self.enable_coverage: bool = enable_coverage
        self.run_file_dir: Path | None = run_file_dir
        self.results_dir: Path | None = (self.run_file_dir / "results") if self.run_file_dir else None

        self.vu: VUnit | None = None

        self._check_results_dir()
        self._check_executable()
        self._set_environment()

    def _check_results_dir(self) -> None:
        """Check if the results directory exists and is writable."""
        if not self.results_dir.exists():
            try:
                self.results_dir.mkdir(parents=True, exist_ok=True)
                LOGGER.info("Created results directory: %s", self.results_dir)
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

    def get_vivado_path(self) -> Path:
        """Get the path to the Vivado installation.

        Which command returns the path to the Vivado executable.
        The executable is usually located under `vivado_path/202x.x/bin/vivado`.
        This method returns the parent directory of `bin`, which is the root of the Vivado installation.

        Returns
        -------
        Path
            The path to the Vivado installation.
        """
        vivado_path: str | None = shutil.which(cmd="vivado")
        if not vivado_path:
            LOGGER.warning("Vivado executable not found in PATH!")
            return Path()

        return Path(vivado_path).parent.parent.parent

    def get_unisim_vcomp_library_path(self) -> Path:
        """Get the path for the unisim VCOMP file compiled in unisim library.

        Usually located under `vivado_path/data/vhdl/src/unisims/unisim_VCOMP.vhd`.

        Returns
        -------
        Path
            The path to the library file.
        """
        vivado_path: Path = self.get_vivado_path()
        unisim_vcomp_path: Path = vivado_path / "data" / "vhdl" / "src" / "unisims" / "unisim_VCOMP.vhd"

        if not unisim_vcomp_path.exists():
            LOGGER.warning("Unisim VCOMP file not found at %s", unisim_vcomp_path)
            return Path()

        return unisim_vcomp_path

    def get_unisim_vpkg_library_path(self) -> Path:
        """Get the path for the unisim VPKG file compiled in unisim library.

        Usually located under `vivado_path/data/vhdl/src/unisims/unisim_VPKG.vhd`.

        Returns
        -------
        Path
            The path to the library file.
        """
        vivado_path: Path = self.get_vivado_path()
        unisim_vpkg_path: Path = vivado_path / "data" / "vhdl" / "src" / "unisims" / "unisim_VPKG.vhd"

        if not unisim_vpkg_path.exists():
            LOGGER.warning("Unisim VPKG file not found at %s", unisim_vpkg_path)
            return Path()

        return unisim_vpkg_path

    def get_unifast_library_path(self) -> Path:
        """Get the path for the unifast library files compiled in the unifast library.

        Usually located under `vivado_path/data/vhdl/src/unifast/primitive/*.vhd`.

        Returns
        -------
        Path
            The path to the library.
        """
        vivado_path: Path = self.get_vivado_path()
        unifast_path: Path = vivado_path / "data" / "vhdl" / "src" / "unifast" / "primitive"

        if not unifast_path.exists():
            LOGGER.warning("Unifast primitive directory not found at %s", unifast_path)
            return Path()

        return unifast_path / "*.vhd"

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
            return self

        path: str | None = library_path or self.DEFAULT_LIBRARIES.get(library_name)
        if not path:
            LOGGER.error("No default path for library '%s'", library_name)

        expanded_path: str = os.path.expanduser(path)
        self.vu.add_external_library(library_name=library_name, path=expanded_path)
        return self

    def get_libraries_to_cover(self) -> list["Library"]:
        """Get the library objects to include in coverage collection.

        Returns
        -------
        list[Library]
            The library objects to cover.
        """
        libs_by_name: dict["Library"] = {lib.name: lib for lib in self.vu.get_libraries()}  # noqa: UP037
        return [libs_by_name[name] for name in self.DEFAULT_LIBRARIES_TO_COVER if name in libs_by_name]

    def configure(self) -> "Simulator":
        """Apply simulator-specific configuration.

        Returns
        -------
        Simulator
            Self for method chaining.
        """
        if not self.vu:
            LOGGER.error("Must call attach() before configure!")
            return self

        self._apply_options()
        return self

    @abstractmethod
    def get_simulator_name(self) -> str:
        """Get the name of the simulator."""

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
            self._generate_coverage(results=results)
        else:
            LOGGER.info("Coverage generation skipped (not enabled)")

    def _merge_output_files(self) -> None:
        """Merge all output.txt files from subdirectories into a single file."""
        vunit_dir: Path = Path(self.vu._output_path)
        output_file: Path = self.results_dir / "output.txt"

        # Check if test_output directory exists
        if not vunit_dir.exists():
            LOGGER.warning("Test output directory not found: %s", vunit_dir)
            return

        # Find all output.txt files
        output_files: list[Path] = list(vunit_dir.rglob("output.txt"))

        if not output_files:
            LOGGER.warning("No output.txt files found in %s", vunit_dir)
            return

        with open(file=output_file, mode="w", encoding="utf-8") as outfile:
            LOGGER.info("Merging %d output.txt files...", len(output_files))

            for txt_file in sorted(output_files):
                # Write a header with the test name
                outfile.write(f"\n{'=' * 80}\n")
                outfile.write(f"Test: {txt_file.parent.name}\n")
                outfile.write(f"Path: {txt_file.relative_to(vunit_dir)}\n")
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
    def _generate_coverage(self, results: Results) -> None:
        """Generate coverage report.

        Parameters
        ----------
        results : Results
            The simulation results from VUnit.
        """

    def _add_file_to_vhdl_ls_config(
        self,
        toml_data: VHDL_LS_TOML,
        file_path: Path,
        library_name: str,
    ) -> None:
        """Add a file to the vhdl_ls configuration.

        Adapted from `cores/open-logic/sim/create_vhdl_ls_config.py` to be used with the VUnit project.
        See https://github.com/open-logic/open-logic/blob/main/sim/create_vhdl_ls_config.py for the original version.

        Parameters
        ----------
        toml_data : dict[str, dict[str, Any]]
            The TOML data structure to which the file will be added.
        file_path : Path
            The path to the VHDL file.
        library_name : str
            The name of the library to which the file belongs.
        """
        libraries: dict[str, dict[str, Any]] = toml_data.setdefault("libraries", {})
        library_entry: dict[str, Any] = libraries.setdefault(library_name, {"files": []})
        library_entry.setdefault("files", [])

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
        if not self.vu:
            LOGGER.error("Must call attach() before generating vhdl_ls configuration!")
            return

        if output_path is None:
            output_path = Path.cwd()

        toml_data: VHDL_LS_TOML = {"libraries": {}}

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


class NVC(Simulator):
    """NVC simulator implementation."""

    SIMULATOR_NAME: str = "nvc"
    EXECUTABLE: str = "nvc"
    DEFAULT_LIBRARIES: dict[str, str] = {
        "unisim": "~/.nvc/lib/unisim.08",
        "unifast": "~/.nvc/lib/unifast.08",
    }

    def get_simulator_name(self) -> str:
        """Get the name of the simulator."""
        return self.SIMULATOR_NAME

    def _apply_options(self) -> None:
        """Apply NVC-specific options."""
        # Base flags always applied
        global_flags: list[str] = ["--ieee-warnings=off"]
        elab_flags: list[str] = []
        sim_flags: list[str] = []

        # Add coverage flags if enabled
        if self.enable_coverage:
            coverage_spec_path: Path = (
                self.run_file_dir / "coverage.spec" if self.run_file_dir else Path("coverage.spec")
            )
            if not coverage_spec_path.exists():
                LOGGER.warning(
                    "Coverage spec file not found at %s. Coverage will be enabled but may not work properly without a valid spec file.",
                    coverage_spec_path,
                )

            elab_flags.append(f"--cover-spec={coverage_spec_path}")

            # Coverage reduces performance, so we only enable it for the libraries we want to cover instead of globally.
            # Coverage on `lib_bench` is enough for nvc, but more libraries can be added to `DEFAULT_LIBRARIES_TO_COVER` if needed.
            libs_to_cover: list["Library"] = self.get_libraries_to_cover()  # noqa: UP037
            LOGGER.info("Enabling coverage for libraries: %s", ", ".join(lib.name for lib in libs_to_cover))

            for lib in libs_to_cover:
                lib.set_sim_option(name="enable_coverage", value=True)
                lib.set_sim_option(
                    name="nvc.elab_flags",
                    value=["--cover=statement,branch,expression,fsm-state,count-from-undefined,exclude-unreachable,"],
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
        if not self.vu:
            return

        output_path: Path = Path(self.vu._output_path)
        coverage_file: Path = output_path / "coverage_data"
        coverage_dir: Path = output_path / "coverage_report"

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
    DEFAULT_LIBRARIES: dict[str, str] = {
        "unisim": "~/.ghdl/xilinx-vivado/unisim/v08",
        "unifast": "~/.ghdl/xilinx-vivado/unifast/v08",
    }

    def get_simulator_name(self) -> str:
        """Get the name of the simulator."""
        return self.SIMULATOR_NAME

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
            LOGGER.info("Enabling coverage for libraries: %s", ", ".join(lib.name for lib in libs_to_cover))

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

    def _fix_gcovr_json_version(self, json_file: Path) -> None:
        """Fix the version string in gcovr JSON coverage file to work around gcovr issues with GHDL coverage files.

        Parameters
        ----------
        json_file : Path
            The path to the JSON coverage file.
        """
        try:
            with open(file=json_file, encoding="utf-8") as f:
                content = f.read()

            # Replace version string in JSON file
            content: str = re.sub(
                pattern=r'"gcovr/format_version":\s*"\d+\.\d+"', repl='"gcovr/format_version": "0.14"', string=content
            )

            with open(file=json_file, mode="w", encoding="utf-8") as f:
                f.write(content)
            LOGGER.info("Modified gcovr.json to fix version issue")
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
        if not self.vu:
            return

        if not self._check_gcovr():
            return

        output_path: Path = Path(self.vu._output_path)
        coverage_file: Path = output_path / "coverage_data"
        coverage_dir: Path = output_path / "coverage_report"
        html_report: Path = coverage_dir / "index.html"
        coverage_dir.mkdir(parents=True, exist_ok=True)

        LOGGER.info("Merging coverage files into %s...", coverage_file)
        results.merge_coverage(file_name=str(coverage_file))
        LOGGER.info("Coverage files merged")

        if results._simulator_if._backend == "gcc":
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
    DEFAULT_LIBRARIES_TO_COVER: set[str] = {"lib_bench", "lib_rtl"}

    def get_simulator_name(self) -> str:
        """Get the name of the simulator."""
        return self.SIMULATOR_NAME

    @override
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
        if not self.vu:
            LOGGER.error("Must call attach() before adding libraries!")
            return self

        LOGGER.warning(
            (
                "Manually adding library '%s' with source files instead of using pre-compiled libraries. Expect very slow simulation times."
            ),
            library_name,
        )

        if library_name == "unisim":
            UNISIM: Library = self.vu.add_library(library_name="unisim")
            unisim_dir: Path = self.get_vivado_path() / "data" / "vhdl" / "src" / "unisims"
            UNISIM.add_source_file(file_name=self.get_unisim_vpkg_library_path())
            UNISIM.add_source_file(file_name=self.get_unisim_vcomp_library_path())
            UNISIM.add_source_files(pattern=str(unisim_dir / "primitive" / "*.vhd"))

        elif library_name == "unifast":
            UNIFAST: Library = self.vu.add_library(library_name="unifast")
            UNIFAST.add_source_files(pattern=self.get_unifast_library_path())

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
            LOGGER.info("Enabling coverage for libraries: %s", ", ".join(lib.name for lib in libs_to_cover))

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
        if not self.vu:
            return

        if not self._check_vcover():
            return

        output_path: Path = Path(self.vu._output_path)
        coverage_file: Path = output_path / "coverage_data.ucdb"
        coverage_dir: Path = output_path / "coverage_report"

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
        process: Process[list[str]] = Process(cmd)
        process.consume_output()
        LOGGER.info("Coverage report generated at %s", coverage_dir)


def select_simulator(
    name: str | None = None, enable_coverage: bool = False, run_file_dir: Path | None = None
) -> Simulator:
    """Select and create a simulator.

    Parameters
    ----------
    name : str | None
        Simulator name ('nvc', 'ghdl' or 'questa/modelsim'). If None, auto-detects.
    enable_coverage : bool
        Enable coverage collection and reporting. Defaults to False.
    run_file_dir : Path | None
        Directory of the `run.py` file. Defaults to None.

    Returns
    -------
    Simulator
        Configured simulator instance.

    Raises
    ------
    SystemExit
        If the specified simulator is unknown or if no suitable simulator is found during auto-detection.
    """
    simulators: dict[str, type[Simulator]] = {"nvc": NVC, "ghdl": GHDL, "questa/modelsim": QuestaModelSim}

    # Auto-detect if not specified
    if not name:
        name = os.environ.get("VUNIT_SIMULATOR")
        if not name:
            for sim_name in simulators:
                if shutil.which(cmd=sim_name):
                    name = sim_name
                    break

    # Create the appropriate simulator
    simulator_class: type[Simulator] | None = simulators.get(name)
    if not simulator_class:
        available: str = ", ".join(simulators.keys())
        LOGGER.error("Unknown simulator: %s. Available: %s", name, available)
        raise SystemExit(1)

    return simulator_class(enable_coverage=enable_coverage, run_file_dir=run_file_dir)
