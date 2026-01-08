# VGA Controller

## Description

The VGA Controller is a hardware module that generates timing signals for VGA video output.

Only works for the [TE 4-1734682-2](https://www.te.com/en/product-4-1734682-2.html?RQPN=4-1734682-2) used on the Zedboard.

## Generics

<div class="generics-table" markdown="1">

| Generic Name      | Type    | Default Value | Description                                |
| ----------------- | ------- | ------------- | ------------------------------------------ |
| `G_H_PIXELS`      | integer | 0d640         | Horizontal resolution in pixels            |
| `G_H_FRONT_PORCH` | integer | 0d16          | Horizontal front porch in pixels           |
| `G_H_SYNC_PULSE`  | integer | 0d96          | Horizontal synchronization pulse in pixels |
| `G_H_BACK_PORCH`  | integer | 0d48          | Horizontal back porch in pixels            |
| `G_V_PIXELS`      | integer | 0d480         | Vertical resolution in pixels              |
| `G_V_FRONT_PORCH` | integer | 0d10          | Vertical front porch in pixels             |
| `G_V_SYNC_PULSE`  | integer | 0d2           | Vertical synchronization pulse in pixels   |
| `G_V_BACK_PORCH`  | integer | 0d33          | Vertical back porch in pixels              |

</div>

## Inputs and Outputs

<div class="ports-table" markdown="1">

| Port Name        | Type         | Direction | Default Value | Description                                                  |
| ---------------- | ------------ | :-------: | ------------- | ------------------------------------------------------------ |
| `CLK`            | std_logic    |    in     | -             | Input clock                                                  |
| `RST_N`          | std_logic    |    in     | -             | Input asynchronous reset, active low                         |
| `O_HSYNC`        | std_logic    |    out    | 0b0           | Horizontal sync signal output                                |
| `O_VSYNC`        | std_logic    |    out    | 0b0           | Vertical sync signal output                                  |
| `I_MANUAL_RED`   | vector[3:0]  |    in     | -             | Red color channel input (4-bit)                              |
| `I_MANUAL_GREEN` | vector[3:0]  |    in     | -             | Green color channel input (4-bit)                            |
| `I_MANUAL_BLUE`  | vector[3:0]  |    in     | -             | Blue color channel input (4-bit)                             |
| `O_RED`          | vector[3:0]  |    out    | 0x00          | Red color channel output (blanked during inactive regions)   |
| `O_GREEN`        | vector[3:0]  |    out    | 0x00          | Green color channel output (blanked during inactive regions) |
| `O_BLUE`         | vector[3:0]  |    out    | 0x00          | Blue color channel output (blanked during inactive regions)  |
| `O_H_POSITION`   | vector[15:0] |    out    | 0x00          | Current horizontal pixel position within active region       |
| `O_V_POSITION`   | vector[15:0] |    out    | 0x00          | Current vertical pixel position within active region         |
| `O_ACTIVE`       | std_logic    |    out    | 0b0           | Active display region flag (high during visible area)        |

</div>

## Architecture

![VGA Controller Architecture](../../assets/uart.drawio){ page="VGA-CONTROLLER" }

---
