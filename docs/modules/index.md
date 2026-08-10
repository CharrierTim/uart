# Modules

The following modules are included in the FPGA:

| Module                                                        | Purpose                                                                 |
| ------------------------------------------------------------- | ----------------------------------------------------------------------- |
| [Top FPGA](top_fpga/top_fpga.md)                              | Top-level integration module.                                           |
| [Clock and Reset Manager](clk_rst_manager/clk_rst_manager.md) | Generates the clocks and resets for the FPGA.                           |
| [Internal Registers](regblock/regblock.md)                    | Defines the AXI4-Lite register map and hardware-facing register fields. |
| [UART AXI4-Lite Bridge](uart/uart_axi_lite_bridge.md)         | Converts ASCII UART commands into AXI4-Lite register transactions.      |
| [UART RX](uart/uart_rx.md)                                    | Synchronizes, filters, samples, and decodes incoming UART frames.       |
| [UART TX](uart/uart_tx.md)                                    | Serializes bytes into UART frames.                                      |
| [SPI Master](spi/spi_master.md)                               | Performs configurable full-duplex SPI transactions.                     |
| [VGA Controller](vga/vga_controller.md)                       | Generates VGA timing and one color output (1024x768@60Hz).              |

See the [Top FPGA](top_fpga/top_fpga.md) module for a block diagram showing how these modules are connected.
