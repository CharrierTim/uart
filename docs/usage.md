# Usage

## Prerequisites

- **Python**:  Version 3.14 or higher
- [**NVC**](https://github.com/nickg/nvc/releases/tag/r1.21.0): `Version r1.21.0`
- **Vivado**: `Version 2025.2`

Also be tested with:

- [**GHDL**](https://github.com/ghdl/ghdl/releases/tag/v6.0.0-rc2): `GHDL 6.0.0-rc2 (6.0.0.rc2.r0.gb981f25f3) [Dunoon edition]`
- **QuestaSim**: `Questa Altera Starter FPGA Edition-64 vsim 2025.2 Simulator 2025.05 May 31 2025`

## Installation

### 1. Clone the Repository

Clone the repo and initialize the submodules:

```bash
git clone --recursive https://github.com/CharrierTim/uart.git
cd uart
```

If you already cloned the repository without `--recursive`, initialize the submodules:

```bash
git submodule update --init --recursive
```

### 2. Set Up Python Environment

!!! bug
    `uv` requires version >= 0.11.15

    Without a higher or equal version, you may encounter an error with `VUnit`.
    See [this issue](https://github.com/astral-sh/uv/issues/9822) for more details.

Create a Python virtual environment and install the required dependencies:

=== "Linux/macOS"

    === "`uv`"

        ```bash
        uv venv
        ```

    === "`pip`"

        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        pip install .
        ```

=== "Windows"

    === "`uv`"

        ```bash
        uv venv
        ```

    === "`pip`"

        ```bash
        python -m venv .venv
        .venv\Scripts\activate
        pip install .
        ```

## Running Tests

!!! important
    Make sure to compile Unisim/Unifast libraries (e.g., `nvc --install vivado`).
    If Unisim/Unifast libraries are not found when running the tests, you can update the script `bench/top_fpga/run.py`
    and update the line `simulator.add_library(library_name="unisim", library_path="your_path_to_unisim")`.

### Basic Test Execution

To run the top-level FPGA testbench:

=== "Linux/macOS"

    === "`uv`"

        ```bash
        uv run bench/top_fpga/run.py
        ```

    === "`pip`"

        ```bash
        source .venv/bin/activate
        python3 bench/top_fpga/run.py
        ```

=== "Windows"

    === "`uv`"

        ```bash
        uv run bench/top_fpga/run.py
        ```

    === "`pip`"

        ```bash
        .venv\Scripts\activate
        python bench/top_fpga/run.py
        ```

### Parallel Execution

Run testcases in parallel using multiple threads for faster execution:

=== "Linux/macOS"

    === "`uv`"

        ```bash
        uv run bench/top_fpga/run.py -- -p0
        ```

    === "`pip`"

        ```bash
        source .venv/bin/activate
        python3 bench/top_fpga/run.py -p0
        ```

=== "Windows"

    === "`uv`"

        ```bash
        uv run bench/top_fpga/run.py -- -p0
        ```

    === "`pip`"

        ```bash
        .venv\Scripts\activate
        python bench/top_fpga/run.py -p0
        ```

Where:

- `-p0`: Runs each testcase in a separate thread (auto-detects number of CPU cores)
- `-p<N>`: Runs with N parallel threads (e.g., `-p4` for 4 threads)

### Coverage Analysis

Enable code coverage collection and generate an HTML coverage report:

=== "Linux/macOS"

    === "`uv`"

        ```bash
        uv run bench/top_fpga/run.py --coverage
        ```

    === "`pip`"

        ```bash
        source .venv/bin/activate
        python3 bench/top_fpga/run.py --coverage
        ```

=== "Windows"

    === "`uv`"

        ```bash
        uv run bench/top_fpga/run.py --coverage
        ```

    === "`pip`"

        ```bash
        .venv\Scripts\activate
        python bench/top_fpga/run.py --coverage
        ```

The coverage report will be generated in the `vunit_out/coverage_report` folder.
Open `vunit_out/coverage_report/index.html` in your browser to view the results.

## Generating the bitstream

Run the following command in the `synthesis` folder:

```bash
vivado -mode batch -nojournal -script run_synthesis.tcl
```

## Additional Options

- `--vhdl_ls`: Generate a `vhdl_ls` configuration file for [vhdl_ls](https://github.com/VHDL-LS/rust_hdl_vscode)
  language server integration. The file will be generated in the project root as `vhdl_ls.toml`. Known issue
  with `unifast` library, where manually adding `is_third_party = true` fixes the warnings.

The script auto-detects the simulator (1. `nvc` or 2. `GHDL` or 3. `QuestaSim`/`ModelSim`) but you can also explicitly specify
the simulator to use:

- `--nvc`: Use `nvc` as the simulator.
- `--ghdl`: Use `GHDL` as the simulator.
- `--questa` or `--modelsim`: Use `QuestaSim`/`ModelSim` as the simulator.

Run the following command to get more help with `VUnit` options:

=== "Linux/macOS"

    ```bash
    python3 bench/top_fpga/run.py --help
    ```

=== "Windows"

    ```bash
    python bench/top_fpga/run.py --help
    ```
