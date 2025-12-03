# UART Documentation

This directory contains the documentation for the UART project, built using [MkDocs](https://www.mkdocs.org/) with the [Material theme](https://squidfunk.github.io/mkdocs-material/).

## Prerequisites

Install the required dependencies:

```bash
pip install -e ".[docs]"
```

## Building the Documentation

### Using MkDocs directly

From the repository root:

```bash
# Build the documentation
mkdocs build

# Serve the documentation locally (with live reload)
mkdocs serve
```

### Using the Makefile

From the `docs/` directory:

```bash
# Build the documentation
make build

# Serve the documentation locally (with live reload)
make serve

# Clean the built documentation
make clean
```

## Viewing the Documentation

After building, the documentation will be available in the `site/` directory. You can open `site/index.html` in a web browser.

When using `mkdocs serve`, the documentation will be available at `http://127.0.0.1:8000`.

## Documentation Structure

- `index.md` - Main landing page with project overview
- `bench.md` - Testbench description
- `modules/` - Individual module documentation
  - `top_fpga.md` - Top-level FPGA module
  - `resync_slv.md` - Synchronizer module
  - `regfile.md` - Register file module
  - `uart.md` - UART module (main)
  - `uart_tx.md` - UART transmitter
  - `uart_rx.md` - UART receiver
  - `spi_master.md` - SPI master module

## Migration from Sphinx

This documentation was previously built using Sphinx. It has been migrated to MkDocs for improved:
- Markdown-native documentation
- Modern, responsive Material theme
- Simpler configuration
- Better navigation and search

The old Sphinx configuration files are preserved in `docs/source/` for reference but are no longer used.
