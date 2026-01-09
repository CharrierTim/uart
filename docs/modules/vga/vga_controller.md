# VGA Controller

## Description

The VGA Controller is a hardware module that generates timing signals for VGA video output.

Only works for the [TE 4-1734682-2](https://www.te.com/en/product-4-1734682-2.html?RQPN=4-1734682-2) used on the Zedboard.

---

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

---

## Inputs and Outputs

<div class="ports-table" markdown="1">

| Port Name         | Type         | Direction | Default Value | Description                                                                                            |
| ----------------- | ------------ | :-------: | ------------- | ------------------------------------------------------------------------------------------------------ |
| `CLK_SYS`         | std_logic    |    in     | -             | Input system clock                                                                                     |
| `CLK_VGA`         | std_logic    |    in     | -             | Input vga clock                                                                                        |
| `RST_H`           | std_logic    |    in     | -             | Input asynchronous reset, active high                                                                  |
| `O_HSYNC`         | std_logic    |    out    | 0b0           | Horizontal sync signal output                                                                          |
| `O_VSYNC`         | std_logic    |    out    | 0b0           | Vertical sync signal output                                                                            |
| `I_MANUAL_COLORS` | vector[11:0] |    in     | -             | Red color channel input (4-bit) & Green color channel input (4-bit) & Blue color channel input (4-bit) |
| `O_RED`           | vector[3:0]  |    out    | 0x00          | Red color channel output (blanked during inactive regions)                                             |
| `O_GREEN`         | vector[3:0]  |    out    | 0x00          | Green color channel output (blanked during inactive regions)                                           |
| `O_BLUE`          | vector[3:0]  |    out    | 0x00          | Blue color channel output (blanked during inactive regions)                                            |
| `O_H_POSITION`    | vector[15:0] |    out    | 0x00          | Current horizontal pixel position within active region                                                 |
| `O_V_POSITION`    | vector[15:0] |    out    | 0x00          | Current vertical pixel position within active region                                                   |
| `O_ACTIVE`        | std_logic    |    out    | 0b0           | Active display region flag (high during visible area)                                                  |

</div>

The input vector `I_MANUAL_COLORS` is coming from the `CLK_SYS` clock domain and must be resynchronized
to the `CLK_VGA` clock domain.

---

## Architecture

![VGA Controller Architecture](../../assets/uart.drawio){ page="VGA-CONTROLLER" }

---

## Sub-modules

The VGA controller module instantiates the [olo_base_cc_status](https://github.com/open-logic/open-logic/blob/main/doc/base/olo_base_cc_status.md)
module with the following generics:

<div class="generics-table" markdown="1">

| Generic Name   | Type     | Default Value | Description                             |
| -------------- | -------- | ------------- | --------------------------------------- |
| `Width_g`      | positive | 0d12          | Width of the data-signal to clock-cross |
| `SyncStages_g` | positive | 0d2           | Number of synchronization stages.       |

</div>

---
