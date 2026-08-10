# Clock and Reset Manager

## Description

The clock and reset manager generates the internal system and VGA clock domains from the external FPGA clock.
It also generates an active-high reset for each clock domain.

A reset is requested when either condition is true:

- `PAD_I_ARST_P` is asserted.
- The PLL lock output is de-asserted.

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
            <td>65 MHz</td>
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

---

## Generics

<div class="generics-table" markdown="1">

| Generic Name         | Type      | Default Value | Description                                                        |
| -------------------- | --------- | ------------- | ------------------------------------------------------------------ |
| `RstPulseCycles_g`   | positive  | 0d3           | Minimum duration of the reset pulse in clock cycles                |
| `RstInPolarity_g`    | std_logic | 0b1           | Polarity of 'RstIn'.                                               |
| `AsyncResetOutput_g` | boolean   | false         | False -> Reset signal is asserted synchronously.                   |
| `SyncStages_g`       | positive  | 0d3           | Number of synchronization stages for the multi-stage synchronizer. |

---

## Inputs and Outputs

<div class="ports-table" markdown="1">

| Port Name           | Type      | Direction | Default Value | Description                              |
| ------------------- | --------- | :-------: | ------------- | ---------------------------------------- |
| `PAD_I_CLK`         | std_logic |    in     | -             | External 100 MHz input clock             |
| `PAD_I_ARST_P`      | std_logic |    in     | -             | External asynchronous reset, active high |
| `O_INTERNAL_CLK`    | std_logic |    out    | 0             | 50 MHz internal system clock             |
| `O_INTERNAL_ARST_P` | std_logic |    out    |               | Internal system reset, active high       |
| `O_VGA_CLK`         | std_logic |    out    | 0             | 65 MHz VGA clock                         |
| `O_VGA_ARST_P`      | std_logic |    out    |               | VGA-domain reset, active high            |

</div>

---

## Architecture

### Sub-modules

The FPGA instantiates the [`clk_wiz_0`](https://docs.amd.com/r/en-US/pg065-clk-wiz/Clocking-Wizard-v6.0-LogiCORE-IP-Product-Guide)
wired to generate the internal system and VGA clocks from the external clock. The PLL is reset by asserting `PAD_I_ARST_P`.

</div>

The FPGA instantiates the [`olo_base_reset_gen`](https://github.com/open-logic/open-logic/blob/main/doc/base/olo_base_reset_gen.md)
module with the following generics for the system clock domain reset:

<div class="generics-table" markdown="1">

| Generic Name         | Type      | Default Value | Description                                                        |
| -------------------- | --------- | ------------- | ------------------------------------------------------------------ |
| `RstPulseCycles_g`   | positive  | 0d3           | Minimum duration of the reset pulse in clock cycles                |
| `RstInPolarity_g`    | std_logic | 0b1           | Polarity of 'RstIn'.                                               |
| `AsyncResetOutput_g` | boolean   | false         | False -> Reset signal is asserted synchronously.                   |
| `SyncStages_g`       | positive  | 0d3           | Number of synchronization stages for the multi-stage synchronizer. |

</div>

The FPGA instantiates the [`olo_base_reset_gen`](https://github.com/open-logic/open-logic/blob/main/doc/base/olo_base_reset_gen.md)
module with the following generics for the VGA clock domain reset:

<div class="generics-table" markdown="1">

| Generic Name         | Type      | Default Value | Description                                                        |
| -------------------- | --------- | ------------- | ------------------------------------------------------------------ |
| `G_RST_PULSE_CYCLES` | positive  | 0d3           | Minimum duration of each generated reset pulse in clock cycles     |
| `G_RST_POLARITY`     | std_logic | 0b1           | Input polarity used by the Open Logic reset generators             |
| `G_ASYNC_RST_OUTPUT` | boolean   | true          | Assert reset asynchronously when true; de-assertion is synchronous |
| `G_RESYNC_NB_STAGES` | positive  | 0d3           | Number of reset synchronization stages                             |

</div>

---
