# Modules

The design is organized into functional RTL blocks and one top-level integration module.

| Module                                                        | Purpose                                                                       |
| ------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| [Top FPGA](top_fpga/top_fpga.md)                              | Integrates clocks, resets, peripherals, register access, and board-level I/O. |
| [Clock and Reset Manager](clk_rst_manager/clk_rst_manager.md) | Generates the system and VGA clocks and their domain-specific resets.         |
| [Internal Registers](regblock/regblock.md)                    | Defines the AXI4-Lite register map and hardware-facing register fields.       |
| [UART AXI4-Lite Bridge](uart/uart_axi_lite_bridge.md)         | Converts ASCII UART commands into AXI4-Lite register transactions.            |
| [UART RX](uart/uart_rx.md)                                    | Synchronizes, filters, samples, and decodes incoming UART frames.             |
| [UART TX](uart/uart_tx.md)                                    | Serializes bytes into UART frames.                                            |
| [SPI Master](spi/spi_master.md)                               | Performs configurable full-duplex SPI transactions.                           |
| [VGA Controller](vga/vga_controller.md)                       | Generates VGA timing and color outputs.                                       |

For integrated behavior, start with [Top FPGA](top_fpga/top_fpga.md). For simulation commands and test coverage.
