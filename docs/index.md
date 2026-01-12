# UART PROJECT

Documentation of the UART Project.

## List of Abbreviations

| Abbreviation | Definition                                          |
| ------------ | --------------------------------------------------- |
| ASCII        | American Standard Code for Information Interchange  |
| CR           | Carriage Return                                     |
| CS           | Chip Select                                         |
| FIFO         | First In, First Out                                 |
| FPGA         | Field-Programmable Gate Array                       |
| FSM          | Finite State Machine                                |
| I/O          | Input/Output                                        |
| LF           | Line Feed                                           |
| LSB          | Least Significant Bit                               |
| LVCMOS       | Low Voltage Complementary Metal-Oxide-Semiconductor |
| MISO         | Master In Slave Out                                 |
| MOSI         | Master Out Slave In                                 |
| MSB          | Most Significant Bit                                |
| PLL          | Phase-Locked Loop                                   |
| RTL          | Register Transfer Level                             |
| RX           | Receive                                             |
| SCLK         | Serial Clock                                        |
| SPI          | Serial Peripheral Interface                         |
| TX           | Transmit                                            |
| UART         | Universal Asynchronous Receiver-Transmitter         |
| VHDL         | VHSIC Hardware Description Language                 |
| VHSIC        | Very High Speed Integrated Circuit                  |

## Tools Versions

| Tool       | Version                                                  |
| ---------- | -------------------------------------------------------- |
| **NVC**    | `nvc 1.18.2 (1.18.2. r0.g8893318a5) (Using LLVM 18.1.3)` |
| **Vunit**  | `commit 1d9f0bdbf917dd486ae7f0902d54598a0b206719`        |
| **VSG**    | `VHDL Style Guide (VSG) version: 3.35.0`                 |
| **Vivado** | `2025.1`                                                 |

## Clocking Configuration

The FPGA uses a PLL (`clk_wiz_0`) to generate internal clocks from the input clock.

<table>
    <thead>
        <tr>
            <th>Signal Name</th>
            <th>Type</th>
            <th>Frequency</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr class="section-header">
            <td colspan="4"><strong>PLL Input</strong></td>
        </tr>
        <tr>
            <td><code>clk_in1</code></td>
            <td>Clock</td>
            <td>100 MHz</td>
            <td>Input clock from <code>PAD_I_CLK</code> (Y9)</td>
        </tr>
        <tr class="section-header">
            <td colspan="4"><strong>PLL Outputs</strong></td>
        </tr>
        <tr>
            <td><code>clk_out1</code></td>
            <td>Clock</td>
            <td>50 MHz</td>
            <td>Internal system clock (<code>internal_clk</code>)</td>
        </tr>
        <tr>
            <td><code>clk_out2</code></td>
            <td>Clock</td>
            <td>25 MHz</td>
            <td>VGA clock (<code>vga_clk</code>)</td>
        </tr>
        <tr>
            <td><code>locked</code></td>
            <td>Status</td>
            <td>-</td>
            <td>PLL lock indicator (<code>pll_locked</code>)</td>
        </tr>
    </tbody>
</table>

## Inputs and Outputs

The FPGA defines the following inputs/outputs:

| Pin Name             | Pin Number | Direction | Resistor | Slew | IOSTANDARD |
| -------------------- | ---------- | --------- | -------- | ---- | ---------- |
| `PAD_I_CLK`          | Y9         | in        | -        | -    | LVCMOS33   |
| `PAD_RST_H`          | BTN6       | in        | -        | -    | LVCMOS18   |
| `PAD_I_UART_RX`      | Y11        | in        | PULL-UP  | -    | LVCMOS33   |
| `PAD_O_UART_TX`      | AA11       | out       | PULL-UP  | -    | LVCMOS33   |
| `PAD_O_SCLK`         | W12        | out       | -        | -    | LVCMOS33   |
| `PAD_O_MOSI`         | W11        | out       | -        | -    | LVCMOS33   |
| `PAD_I_MISO`         | W10        | in        | -        | -    | LVCMOS33   |
| `PAD_O_CS_N`         | W8         | out       | PULL-UP  | -    | LVCMOS33   |
| `PAD_I_SWITCH_0`     | F22        | in        | -        | -    | LVCMOS18   |
| `PAD_I_SWITCH_1`     | G22        | in        | -        | -    | LVCMOS18   |
| `PAD_I_SWITCH_2`     | H22        | in        | -        | -    | LVCMOS18   |
| `PAD_O_LED_0`        | T22        | out       | -        | -    | LVCMOS33   |
| `PAD_O_VGA_BLUE[0]`  | Y21        | out       | -        | -    | LVCMOS33   |
| `PAD_O_VGA_BLUE[1]`  | Y20        | out       | -        | -    | LVCMOS33   |
| `PAD_O_VGA_BLUE[2]`  | AB20       | out       | -        | -    | LVCMOS33   |
| `PAD_O_VGA_BLUE[3]`  | AB19       | out       | -        | -    | LVCMOS33   |
| `PAD_O_VGA_GREEN[0]` | AB22       | out       | -        | -    | LVCMOS33   |
| `PAD_O_VGA_GREEN[1]` | AA22       | out       | -        | -    | LVCMOS33   |
| `PAD_O_VGA_GREEN[2]` | AB21       | out       | -        | -    | LVCMOS33   |
| `PAD_O_VGA_GREEN[3]` | AA21       | out       | -        | -    | LVCMOS33   |
| `PAD_O_VGA_RED[0]`   | V20        | out       | -        | -    | LVCMOS33   |
| `PAD_O_VGA_RED[1]`   | U20        | out       | -        | -    | LVCMOS33   |
| `PAD_O_VGA_RED[2]`   | V19        | out       | -        | -    | LVCMOS33   |
| `PAD_O_VGA_RED[3]`   | V18        | out       | -        | -    | LVCMOS33   |
| `PAD_O_VGA_HSYNC`    | AA19       | out       | -        | -    | LVCMOS33   |
| `PAD_O_VGA_VSYNC`    | Y19        | out       | -        | -    | LVCMOS33   |

## Design architecture

- [FPGA modules](modules/top_fpga.md)

## Testbench

- [Testbench description](modules/testbench/tb_top_fpga.md)
- [Testcases description](modules/testbench/testcases.md)
