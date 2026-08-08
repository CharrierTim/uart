# Clock and Reset Manager

## Description

The clock and reset manager generates the internal system and VGA clock domains from the external FPGA clock.
It also generates an active-high reset for each clock domain. The resets assert asynchronously when the external reset
is asserted or the PLL loses lock, and de-assert synchronously with their respective output clocks.

---

## Generics

<div class="generics-table" markdown="1">

| Generic Name         | Type      | Default Value | Description                                                        |
| -------------------- | --------- | ------------- | ------------------------------------------------------------------ |
| `G_RST_PULSE_CYCLES` | positive  | 0d3           | Minimum duration of each generated reset pulse in clock cycles     |
| `G_RST_POLARITY`     | std_logic | 0b1           | Input polarity used by the Open Logic reset generators             |
| `G_ASYNC_RST_OUTPUT` | boolean   | true          | Assert reset asynchronously when true; de-assertion is synchronous |
| `G_RESYNC_NB_STAGES` | positive  | 0d3           | Number of reset synchronization stages                             |

</div>

`G_RST_POLARITY` controls the encoded polarity presented internally to the reset generators. It does not change the
external `PAD_I_ARST_P` interface or the generated reset outputs; those signals are always active high.

---

## Inputs and Outputs

<div class="ports-table" markdown="1">

| Port Name           | Type      | Direction | Default Value | Description                                           |
| ------------------- | --------- | :-------: | ------------- | ----------------------------------------------------- |
| `PAD_I_CLK`         | std_logic |    in     | -             | External 100 MHz input clock                          |
| `PAD_I_ARST_P`      | std_logic |    in     | -             | External asynchronous reset, active high              |
| `O_INTERNAL_CLK`    | std_logic |    out    | -             | 50 MHz internal system clock                          |
| `O_INTERNAL_ARST_P` | std_logic |    out    | -             | Internal system reset, active high                    |
| `O_VGA_CLK`         | std_logic |    out    | -             | 65 MHz VGA clock                                      |
| `O_VGA_ARST_P`      | std_logic |    out    | -             | VGA-domain reset, active high                         |

</div>

---

## Architecture

The module instantiates the `clk_wiz_0` PLL. The PLL derives the 50 MHz internal clock and the 65 MHz VGA clock from
`PAD_I_CLK`. Asserting `PAD_I_ARST_P` resets the PLL.

A reset is requested when either condition is true:

- `PAD_I_ARST_P` is asserted.
- The PLL lock output is de-asserted.

The active-high request is encoded according to `G_RST_POLARITY` and connected to two
[`olo_base_reset_gen`](https://github.com/open-logic/open-logic/blob/main/doc/base/olo_base_reset_gen.md) instances,
one for each output clock domain. Regardless of the selected input polarity, both generated reset outputs are active
high.

With the default `G_ASYNC_RST_OUTPUT = true`, the resets assert without requiring a generated clock edge. This is
required because resetting or losing lock in the PLL can stop its output clocks. Each reset de-asserts synchronously
with its own clock after the PLL locks and the configured synchronization stages have completed.

The `TOP_FPGA` integration uses the default reset settings: a three-cycle minimum pulse, active-high reset-generator
input encoding, asynchronous assertion, and three synchronization stages.
