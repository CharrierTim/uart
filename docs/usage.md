# Usage

## Prerequisites

- **Python**:  Version 3.10 or higher
- [**NVC**](https://github.com/nickg/nvc/releases/tag/r1.18.2): Version r1.18.2
- **Vivado**: Version 2025.1

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

Create a Python virtual environment and install the required dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install .
```

## Running Tests

### Basic Test Execution

To run the top-level FPGA testbench:

```bash
python3 bench/top_fpga/run.py
```

### Parallel Execution

Run testcases in parallel using multiple threads for faster execution:

```bash
python3 bench/top_fpga/run.py -p0
```

Where:

- `-p0`: Runs each testcase in a separate thread (auto-detects number of CPU cores)
- `-p<N>`: Runs with N parallel threads (e.g., `-p4` for 4 threads)

### Coverage Analysis

Enable code coverage collection and generate an HTML coverage report:

```bash
python3 bench/top_fpga/run.py --coverage
```

The coverage report will be generated in the `vunit_out/coverage_report` folder.
Open `vunit_out/coverage_report/index.html` in your browser to view the results.
