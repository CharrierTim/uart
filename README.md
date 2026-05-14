# UART

## Documentation

For full documentation and usage, visit:  **<https://charriertim.github.io/uart>**

## Summary

FPGA project built for the Zedboard device around an UART peripheral, designed to control various IPs and peripherals
(SPI, VGA, etc.).

Most of the design is built from scratch, but some IPs are taken from the [Open Logic FPGA Standard Library](https://github.com/open-logic/open-logic).

![UART top-level FPGA architecture](docs/assets/uart-TOP-FPGA.svg)

The verification environment used is [VUnit framework](https://github.com/VUnit/vunit).

The FPGA can be simulated with code coverage using the open-source simulators [nvc](https://github.com/nickg/nvc) or
[GHDL](https://github.com/ghdl/ghdl) or with closed-source ModelSim/QuestaSim.

Synthesis and implementation are done with Vivado.
