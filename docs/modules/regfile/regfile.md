# Registers

## Description

Internal FPGA registers with read/write registers accessible via the UART line.

## Generics

| Generic Name   | Type         | Default Value | Description                                                              |
| -------------- | ------------ | ------------- | ------------------------------------------------------------------------ |
| `G_GIT_ID_MSB` | vector[15:0] | 0x0000        | 16 MSB of the git ID containing the sources for the bitstream generation |
| `G_GIT_ID_LSB` | vector[15:0] | 0x0000        | 16 LSB of the git ID containing the sources for the bitstream generation |

## Inputs and Outputs

| Port Name             | Type         | Direction | Default Value  | Description                                               |
| --------------------- | ------------ | :-------: | :------------: | --------------------------------------------------------- |
| `CLK`                 | std_logic    |    in     |       -        | Input clock                                               |
| `RST_N`               | std_logic    |    in     |       -        | Input asynchronous reset, active low                      |
| `I_SWITCHES`          | vector[2:0]  |    in     |       -        | Input vector containing the resynchronized switches value |
| `I_SPI_RX_DATA`       | vector[7:0]  |    in     |       -        | Input vector containing the SPI data sent by the slave    |
| `I_SPI_RX_DATA_VALID` | std_logic    |    in     |       -        | Input vector containing the SPI data sent flag valid      |
| `I_READ_ADDR`         | vector[7:0]  |    in     |       -        | Read address from the UART                                |
| `I_READ_ADDR_VALID`   | std_logic    |    in     |       -        | Read address valid flag                                   |
| `O_READ_DATA`         | vector[15:0] |    out    | `G_GIT_ID_MSB` | Read data at the address `I_READ_ADDR`                    |
| `O_READ_DATA_VALID`   | std_logic    |    out    |      0x00      | Read data valid flag                                      |
| `I_WRITE_ADDR`        | vector[7:0]  |    in     |       -        | Write address from the UART                               |
| `I_WRITE_DATA`        | vector[15:0] |    in     |       -        | Write data to be written at `I_WRITE_DATA`                |
| `I_WRITE_VALID`       | std_logic    |    in     |       -        | Write address and data valid flag                         |
| `O_SPI_TX_DATA`       | vector[7:0]  |    out    |      0x00      | Input vector containing the SPI data to be send           |
| `O_SPI_TX_DATA_VALID` | std_logic    |    out    |      0b0       | Input vector containing the SPI data flag valid           |
| `O_LED_0`             | std_logic    |    out    |      0b1       | LED 0 value                                               |

## Architecture

### Read Operations

The regfile module performs a read operation when `I_READ_ADDR_VALID` is
asserted (set to '1'). The module responds by:

1. Reading the data stored at the address specified by `I_READ_ADDR`
2. Asserting `O_READ_DATA_VALID` on the next clock cycle
3. Outputting the retrieved value on `O_READ_DATA`

**Invalid Address Handling:**

If the specified address does not correspond to a defined register, the
module returns the sentinel value `0xDEAD` to indicate an invalid read
operation.

``` text
Valid address:   I_READ_ADDR_VALID = '1' → O_READ_DATA = register[I_READ_ADDR]
Invalid address: I_READ_ADDR_VALID = '1' → O_READ_DATA = 0xDEAD
```

### Write Operations

The regfile module performs a write operation when `I_WRITE_VALID` is
asserted (set to '1'). The module writes the data from `I_WRITE_DATA`
to the address specified by `I_WRITE_ADDR`.

**Write Protection:**

Not all registers are writable. If the specified address corresponds to:

- A **read-only register**: The write operation is silently ignored, and
  the register value remains unchanged
- A **writable register**: The data is written on the next clock cycle
- An **undefined address**: The write operation is ignored

## Overview

A simplified view of the regfile module:

![image](../../assets/uart.drawio){ page="REGFILE" }

## Summary

| Name                              | Address | Mode | Description                                                              |
| --------------------------------- | ------- | ---- | ------------------------------------------------------------------------ |
| [REG_GIT_ID_MSB](#reg_git_id_msb) | 0x00    | R    | 16 MSB of the git ID containing the sources for the bitstream generation |
| [REG_GIT_ID_LSB](#reg_git_id_lsb) | 0x01    | R    | 16 LSB of the git ID containing the sources for the bitstream generation |
| [REG_12](#reg_12)                 | 0x02    | R    | Internal register 1                                                      |
| [REG_34](#reg_34)                 | 0x03    | R    | Internal register 2                                                      |
| [REG_56](#reg_56)                 | 0x04    | R    | Internal register 3                                                      |
| [REG_78](#reg_78)                 | 0x05    | R    | Internal register 4                                                      |
| [REG_SPI_TX](#reg_spi_tx)         | 0x06    | RW   | Register controlling the SPI data to send                                |
| [REG_SPI_RX](#reg_spi_rx)         | 0x07    | R    | Register containing the SPI slave data                                   |
| [REG_9A](#reg_9a)                 | 0xAB    | R    | Internal register 5                                                      |
| [REG_CD](#reg_cd)                 | 0xAC    | R    | Internal register 6                                                      |
| [REG_EF](#reg_ef)                 | 0xDC    | R    | Internal register 7                                                      |
| [REG_SWITCHES](#reg_switches)     | 0xB1    | R    | Status from the input switches                                           |
| [REG_LED](#reg_led)               | 0xEF    | RW   | Register with LSB bit writable controlling an LED                        |
| [REG_16_BITS](#reg_16_bits)       | 0xFF    | RW   | Register with all bits writable                                          |

Where:

| Mode   | Description                                                                 |
| ------ | --------------------------------------------------------------------------- |
| **R**  | Read-only: Register value can be read but not modified via write operations |
| **RW** | Read-Write: Register value can be both read and written                     |

## Detailed register descriptions

### REG_GIT_ID_MSB

16 MSB of the git ID containing the sources for the bitstream generation

- Address: `0x00`

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "GIT_ID_MSB",
            "bits": 16,
            "attr": [
                "ro"
            ],
            "rotate": 0,
            "type": 3
        }
    ],
    "config": {
        "lanes": 1,
        "fontsize": 10,
        "vspace": 80
    }
}
</script>

| Bits | Reset | Name       | Description                                   |
| ---- | ----- | ---------- | --------------------------------------------- |
| 15:0 | 0x0   | GIT_ID_MSB | Most significant 16 bits of the Git commit ID |

### REG_GIT_ID_LSB

16 LSB of the git ID containing the sources for the bitstream generation

- Address: `0x01`

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "GIT_ID_LSB",
            "bits": 16,
            "attr": [
                "ro"
            ],
            "rotate": 0,
            "type": 3
        }
    ],
    "config": {
        "lanes": 1,
        "fontsize": 10,
        "vspace": 80
    }
}
</script>

| Bits | Reset | Name       | Description                                    |
| ---- | ----- | ---------- | ---------------------------------------------- |
| 15:0 | 0x0   | GIT_ID_LSB | Least significant 16 bits of the Git commit ID |

### REG_12

Internal register 1

- Address: `0x02`

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "0x1212",
            "bits": 16,
            "attr": [
                "ro"
            ],
            "rotate": 0,
            "type": 3
        }
    ],
    "config": {
        "lanes": 1,
        "fontsize": 10,
        "vspace": 80,
        "bits": 16
    }
}
</script>

| Bits | Reset  | Name | Description |
| ---- | ------ | ---- | ----------- |
| 15:0 | 0x1212 |      | Constant    |

### REG_34

Internal register 2

- Address: `0x03`
- Reset default: `0x3434`

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "0x3434",
            "bits": 16,
            "attr": [
                "ro"
            ],
            "rotate": 0,
            "type": 3
        }
    ],
    "config": {
        "lanes": 1,
        "fontsize": 10,
        "vspace": 80,
        "bits": 16
    }
}
</script>

| Bits | Reset  | Name | Description |
| ---- | ------ | ---- | ----------- |
| 15:0 | 0x3434 |      | Constant    |

### REG_56

Internal register 3

- Address: `0x04`
- Reset default: `0x5656`

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "0x5656",
            "bits": 16,
            "attr": [
                "ro"
            ],
            "rotate": 0,
            "type": 3
        }
    ],
    "config": {
        "lanes": 1,
        "fontsize": 10,
        "vspace": 80,
        "bits": 16
    }
}
</script>

| Bits | Reset  | Name | Description |
| ---- | ------ | ---- | ----------- |
| 15:0 | 0x5656 |      | Constant    |

### REG_SPI_TX

SPI TX data register

- Address: `0x06`
- Reset default: `0x0000`

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "TX_DATA",
            "bits": 8,
            "attr": [
                "rw"
            ],
            "rotate": 0,
            "type": 3
        },
        {
            "name": "TX_DATA_VALID",
            "bits": 1,
            "attr": [
                "rw"
            ],
            "rotate": -90,
            "type": 3
        },
        {
            "name": "Reserved",
            "bits": 7,
            "attr": [
                "ro"
            ],
            "rotate": 0,
            "type": 2
        }
    ],
    "config": {
        "lanes": 1,
        "fontsize": 10,
        "vspace": 80,
        "bits": 16
    }
}
</script>

| Bits | Reset | Name          | Description                      |
| ---- | ----- | ------------- | -------------------------------- |
| 15:9 | 0x0   |               | Reserved                         |
| 8    | 0x0   | TX_DATA_VALID | 0 -> 1 start the SPI transaction |
| 7:0  | 0x0   | TX_DATA       | TX data to be sent               |

### REG_SPI_RX

SPI RX data register

- Address: `0x07`
- Reset default: `0x0000`

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "RX_DATA",
            "bits": 8,
            "attr": [
                "ro"
            ],
            "rotate": 0,
            "type": 3
        },
        {
            "name": "Reserved",
            "bits": 8,
            "attr": [
                "ro"
            ],
            "rotate": 0,
            "type": 2
        }
    ],
    "config": {
        "lanes": 1,
        "fontsize": 10,
        "vspace": 80,
        "bits": 16
    }
}
</script>

| Bits | Reset | Name    | Description                  |
| ---- | ----- | ------- | ---------------------------- |
| 15:8 | 0x0   |         | Reserved                     |
| 7:0  | 0x0   | RX_DATA | Received data from SPI slave |

### REG_78

Internal register 4

- Address: `0x05`
- Reset default: `0x7878`

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "0x7878",
            "bits": 16,
            "attr": [
                "ro"
            ],
            "rotate": 0,
            "type": 3
        }
    ],
    "config": {
        "lanes": 1,
        "fontsize": 10,
        "vspace": 80,
        "bits": 16
    }
}
</script>

| Bits | Reset  | Name | Description |
| ---- | ------ | ---- | ----------- |
| 15:0 | 0x7878 |      | Constant    |

### REG_9A

Internal register 5

- Address: `0xAB`
- Reset default: `0x9A9A`

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "0x9A9A",
            "bits": 16,
            "attr": [
                "ro"
            ],
            "rotate": 0,
            "type": 3
        }
    ],
    "config": {
        "lanes": 1,
        "fontsize": 10,
        "vspace": 80,
        "bits": 16
    }
}
</script>

| Bits | Reset  | Name | Description |
| ---- | ------ | ---- | ----------- |
| 15:0 | 0x9A9A |      | Constant    |

### REG_CD

Internal register 6

- Address: `0xAC`
- Reset default: `0xCDCD`

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "0xCDCD",
            "bits": 16,
            "attr": [
                "ro"
            ],
            "rotate": 0,
            "type": 3
        }
    ],
    "config": {
        "lanes": 1,
        "fontsize": 10,
        "vspace": 80,
        "bits": 16
    }
}
</script>

| Bits | Reset  | Name | Description |
| ---- | ------ | ---- | ----------- |
| 15:0 | 0xCDCD |      | Constant    |

### REG_EF

Internal register 7

- Address: `0xDC`
- Reset default: `0xEFEF`

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "0xEFEF",
            "bits": 16,
            "attr": [
                "ro"
            ],
            "rotate": 0,
            "type": 3
        }
    ],
    "config": {
        "lanes": 1,
        "fontsize": 10,
        "vspace": 80,
        "bits": 16
    }
}
</script>

| Bits | Reset  | Name | Description |
| ---- | ------ | ---- | ----------- |
| 15:0 | 0xEFEF |      | Constant    |

### REG_SWITCHES

Register returning the status of the input switches

- Address: `0xB1`
- Reset default: `0x0000`

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "SWITCH_0",
            "bits": 1,
            "attr": [
                "ro"
            ],
            "rotate": -90,
            "type": 3
        },
        {
            "name": "SWITCH_1",
            "bits": 1,
            "attr": [
                "ro"
            ],
            "rotate": -90,
            "type": 3
        },
        {
            "name": "SWITCH_2",
            "bits": 1,
            "attr": [
                "ro"
            ],
            "rotate": -90,
            "type": 3
        },
        {
            "name": "Reserved",
            "bits": 13,
            "attr": [
                "ro"
            ],
            "rotate": 0,
            "type": 2
        }
    ],
    "config": {
        "lanes": 1,
        "fontsize": 10,
        "vspace": 80
    }
}
</script>

| Bits | Reset | Name     | Description                |
| ---- | ----- | -------- | -------------------------- |
| 15:3 | 0x0   |          | Reserved                   |
| 2    | 0x0   | SWITCH_2 | Signal from PAD_I_SWITCH_2 |
| 1    | 0x0   | SWITCH_1 | Signal from PAD_I_SWITCH_1 |
| 0    | 0x0   | SWITCH_0 | Signal from PAD_I_SWITCH_0 |

### REG_LED

Register with LSB bit writable controlling an LED

- Address: `0xEF`
- Reset default: `0x0001`

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "LED_0",
            "bits": 1,
            "attr": [
                "rw"
            ],
            "rotate": -90,
            "type": 3
        },
        {
            "name": "Reserved",
            "bits": 15,
            "attr": [
                "ro"
            ],
            "rotate": 0,
            "type": 2
        }
    ],
    "config": {
        "lanes": 1,
        "fontsize": 10,
        "vspace": 80
    }
}
</script>

| Bits | Reset | Name  | Description  |
| ---- | ----- | ----- | ------------ |
| 15:1 | 0x0   |       | Reserved     |
| 0    | 0x1   | LED_0 | Writable bit |

### REG_16_BITS

Register with all bits writable

- Address: `0xFF`
- Reset default: `0x0000`

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "DATA",
            "bits": 16,
            "attr": [
                "rw"
            ],
            "rotate": 0,
            "type": 3
        }
    ],
    "config": {
        "lanes": 1,
        "fontsize": 10,
        "vspace": 80
    }
}
</script>

| Bits | Reset | Name | Description                |
| ---- | ----- | ---- | -------------------------- |
| 15:0 | 0x0   | DATA | 16-bit writable data field |
