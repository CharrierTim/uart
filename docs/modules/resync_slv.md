# Resync slv

## Description

Re-synchronize asynchronous inputs to a destination clock domain using 3 DFF stages for each bit of the input vector.

## Generics

| Generic Name | Type | Default Value | Description |
|--------------|------|---------------|-------------|
| `G_WIDTH` | positive | 0d8 | Width of the input/output vector |
| `G_DEFAULT_VALUE` | vector [G_WIDTH - 1:0] | 0x00 | Default value of the output vector |

## Inputs and Outputs

| Port Name | Type | Direction | Default Value | Description |
|-----------|------|-----------|---------------|-------------|
| `CLK` | std_logic | in | - | Input clock |
| `RST_N` | std_logic | in | - | Input asynchronous reset, active low |
| `I_DATA_ASYNC` | vector[G_WIDTH - 1:0] | in | - | Input vector containing asynchronous signals |
| `O_DATA_SYNC` | vector[G_WIDTH - 1:0] | out | `G_DEFAULT_VALUE` | Input vector resynchronized in `CLK` domain |

## Overview

![Resync SLV Diagram](../_static/svg/UART-RESYNC_SLV.svg)

## Architecture
