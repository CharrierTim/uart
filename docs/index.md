# UART PROJECT

Documentation of the UART Project.

## Tools Versions

| Tool       | Version                                                  |
| ---------- | -------------------------------------------------------- |
| **NVC**    | `nvc 1.18.2 (1.18.2. r0.g8893318a5) (Using LLVM 18.1.3)` |
| **Vunit**  | `commit 4e30fa124ea84609af0f957dbc55b82adaed1d76`        |
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
            <td><code>locked</code></td>
            <td>Status</td>
            <td>-</td>
            <td>PLL lock indicator (<code>pll_locked</code>)</td>
        </tr>
    </tbody>
</table>

## Inputs and Outputs

The FPGA defines the following inputs/outputs:

| Pin Name         | Pin Number | Direction | Resistor | Slew | IOSTANDARD |
| ---------------- | ---------- | --------- | -------- | ---- | ---------- |
| `PAD_I_CLK`      | Y9         | in        | -        | -    | LVCMOS33   |
| `PAD_RST_H`      | BTN6       | in        | -        | -    | LVCMOS18   |
| `PAD_I_UART_RX`  | Y11        | in        | PULL-UP  | -    | LVCMOS33   |
| `PAD_O_UART_TX`  | AA11       | out       | PULL-UP  | -    | LVCMOS33   |
| `PAD_O_SCLK`     | W12        | out       | -        | -    | LVCMOS33   |
| `PAD_O_MOSI`     | W11        | out       | -        | -    | LVCMOS33   |
| `PAD_I_MISO`     | W10        | in        | -        | -    | LVCMOS33   |
| `PAD_O_CS`       | W8         | out       | PULL-UP  | -    | LVCMOS33   |
| `PAD_I_SWITCH_0` | F22        | in        | -        | -    | LVCMOS18   |
| `PAD_I_SWITCH_1` | G22        | in        | -        | -    | LVCMOS18   |
| `PAD_I_SWITCH_2` | H22        | in        | -        | -    | LVCMOS18   |
| `PAD_O_LED_0`    | T22        | out       | -        | -    | LVCMOS33   |

## Design architecture

- [top_fpga](modules/top_fpga.md)

## Testbench

- [bench](modules/tb_top_fpga.md)
