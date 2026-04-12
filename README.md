# UART

## Documentation

For full documentation and usage, visit:  **<https://charriertim.github.io/uart>**

## Summary

FPGA project built for the Zedboard device around an UART peripheral, designed to control various IPs and peripherals
(UART, SPI, VGA, etc.).

Most of the design is built from scratch, but some IPs are taken from the [Open Logic FPGA Standard Library](https://github.com/open-logic/open-logic).

![UART top-level FPGA architecture](docs/assets/uart-TOP-FPGA.svg)

The verification environment used is [Vunit framework](https://github.com/VUnit/vunit).

The FPGA can be simulated with the open-source simulator [nvc](https://github.com/nickg/nvc) with code coverage and
with [GHDL](https://github.com/ghdl/ghdl).

Synthesis and implementation are done with Vivado.
