# Registers

## Description

Internal FPGA registers with read/write registers accessible via the UART.
An UART-AXI4 Lite bridge is used to access these registers.

Documentation partially generated from the RDL file using the
[`generate_regblock.py`](https://github.com/CharrierTim/uart/blob/main/tools/peakrdl/script/generate_regblock.py) script.

## Summary

- Absolute Address: `0x0`
- Base Offset: `0x0`
- Size: `0x100`

<p>Registers accessible on the AXI4 Lite bus providing control and status functionality.</p>

| Name                                                 | Offset | Mode |
| ---------------------------------------------------- | ------ | ---- |
| [git_hash](#git_hash-register)                       | 0x00   | R    |
| [git_status](#git_status-register)                   | 0x04   | R    |
| [fpga_id](#fpga_id-register)                         | 0x08   | R    |
| [spi_tx_control](#spi_tx_control-register)           | 0x0C   | RW   |
| [spi_rx_data](#spi_rx_data-register)                 | 0x10   | R    |
| [vga_color_control](#vga_color_control-register)     | 0x14   | RW   |
| [switch_status](#switch_status-register)             | 0x18   | R    |
| [bad_address_counter](#bad_address_counter-register) | 0x1C   | R    |
| [test_register_1](#test_register_1-register)         | 0xF8   | RW   |
| [test_register_2](#test_register_2-register)         | 0xFC   | RW   |

Where:

| Mode   | Description                                                                  |
| ------ | ---------------------------------------------------------------------------- |
| **R**  | Read-only: Register value can be read but not modified via write operations  |
| **W**  | Write-only: Register value can be modified via write operations but not read |
| **RW** | Read-Write: Register value can be both read and written                      |

---

## Detailed register descriptions

---

### git_hash register

- Absolute Address: `0x0`
- Base Offset: `0x0`
- Size: `0x4`

<p>Register indicating the git hash of the repository at the time of bitstream generation.</p>

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "git_hash",
            "bits": 32,
            "attr": [
                "r"
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
}</script>

| Bits | Identifier | Access | Reset | Name |
| ---- | ---------- | ------ | ----- | ---- |
| 31:0 | hash       | r      | —     | —    |

#### hash field

<p>Hash value</p>

---

### git_status register

- Absolute Address: `0x4`
- Base Offset: `0x4`
- Size: `0x4`

<p>Register indicating the git status of the repository at the time of bitstream generation.
If the value is 1, there were uncommitted changes in the repository (dirty), while if the value is 0,
there were no uncommitted changes (clean).</p>

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "status",
            "bits": 1,
            "attr": [
                "r"
            ],
            "rotate": -90,
            "type": 3
        },
        {
            "name": "Reserved",
            "bits": 30,
            "attr": [
                "r"
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
}</script>

| Bits | Identifier | Access | Reset | Name |
| ---- | ---------- | ------ | ----- | ---- |
| 0    | status     | r      | —     | —    |

#### status field

<p>Status value</p>

---

### fpga_id register

- Absolute Address: `0x8`
- Base Offset: `0x8`
- Size: `0x4`

<p>Register indicating the FPGA identification information.</p>

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "id",
            "bits": 32,
            "attr": [
                "r"
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
}</script>

| Bits | Identifier | Access | Reset | Name |
| ---- | ---------- | ------ | ----- | ---- |
| 31:0 | id         | r      | —     | —    |

#### id field

<p>ID value</p>

---

### spi_tx_control register

- Absolute Address: `0xC`
- Base Offset: `0xC`
- Size: `0x4`

<p>Register used to send data over SPI. Writing to this register starts the SPI transaction.</p>

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "tx_data",
            "bits": 8,
            "attr": [
                "rw"
            ],
            "rotate": 0,
            "type": 3
        },
        {
            "name": "tx_data_valid",
            "bits": 1,
            "attr": [
                "rw"
            ],
            "rotate": -90,
            "type": 3
        },
        {
            "name": "Reserved",
            "bits": 23,
            "attr": [
                "r"
            ],
            "rotate": 0,
            "type": 2
        }
    ],
    "config": {
        "lanes": 1,
        "fontsize": 10,
        "vspace": 120
    }
}</script>

| Bits | Identifier    | Access | Reset | Name |
| ---- | ------------- | ------ | ----- | ---- |
| 7:0  | tx_data       | rw     | 0x0   | —    |
| 8    | tx_data_valid | rw     | 0x0   | —    |

#### tx_data field

<p>TX data to be sent</p>

#### tx_data_valid field

<p>SPI transaction valid signal. Asserts for one cycle when written 1
and then clears back to 0 on the next cycle</p>

---

### spi_rx_data register

- Absolute Address: `0x10`
- Base Offset: `0x10`
- Size: `0x4`

<p>Register used to receive data over SPI.</p>

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "rx_data",
            "bits": 8,
            "attr": [
                "r"
            ],
            "rotate": 0,
            "type": 3
        },
        {
            "name": "Reserved",
            "bits": 24,
            "attr": [
                "r"
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
}</script>

| Bits | Identifier | Access | Reset | Name |
| ---- | ---------- | ------ | ----- | ---- |
| 7:0  | rx_data    | r      | 0x0   | —    |

#### rx_data field

<p>RX data received over SPI</p>

---

### vga_color_control register

- Absolute Address: `0x14`
- Base Offset: `0x14`
- Size: `0x4`

<p>Register used to set the VGA output color.
The color is specified in RGB format, with 4 bits for each channel (red, green, blue).</p>

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "blue",
            "bits": 4,
            "attr": [
                "rw"
            ],
            "rotate": 0,
            "type": 3
        },
        {
            "name": "green",
            "bits": 4,
            "attr": [
                "rw"
            ],
            "rotate": 0,
            "type": 3
        },
        {
            "name": "red",
            "bits": 4,
            "attr": [
                "rw"
            ],
            "rotate": 0,
            "type": 3
        },
        {
            "name": "Reserved",
            "bits": 20,
            "attr": [
                "r"
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
}</script>

| Bits | Identifier | Access | Reset | Name |
| ---- | ---------- | ------ | ----- | ---- |
| 3:0  | blue       | rw     | 0x0   | —    |
| 7:4  | green      | rw     | 0xF   | —    |
| 11:8 | red        | rw     | 0x0   | —    |

#### blue field

<p>Blue channel intensity (0-15)</p>

#### green field

<p>Green channel intensity (0-15)</p>

#### red field

<p>Red channel intensity (0-15)</p>

---

### switch_status register

- Absolute Address: `0x18`
- Base Offset: `0x18`
- Size: `0x4`

<p>Register used to read the status of the input switches.
Each bit corresponds to a different switch, with bit 0 corresponding to switch_0,
bit 1 to switch_1, and bit 2 to switch_2.</p>

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "switch_2",
            "bits": 1,
            "attr": [
                "r"
            ],
            "rotate": -90,
            "type": 3
        },
        {
            "name": "switch_1",
            "bits": 1,
            "attr": [
                "r"
            ],
            "rotate": -90,
            "type": 3
        },
        {
            "name": "switch_0",
            "bits": 1,
            "attr": [
                "r"
            ],
            "rotate": -90,
            "type": 3
        },
        {
            "name": "Reserved",
            "bits": 29,
            "attr": [
                "r"
            ],
            "rotate": 0,
            "type": 2
        }
    ],
    "config": {
        "lanes": 1,
        "fontsize": 10,
        "vspace": 100
    }
}</script>

| Bits | Identifier | Access | Reset | Name |
| ---- | ---------- | ------ | ----- | ---- |
| 0    | switch_0   | r      | 0x0   | —    |
| 1    | switch_1   | r      | 0x0   | —    |
| 2    | switch_2   | r      | 0x0   | —    |

#### switch_0 field

<p>Status of switch 0</p>

#### switch_1 field

<p>Status of switch 1</p>

#### switch_2 field

<p>Status of switch 2</p>

---

### bad_address_counter register

- Absolute Address: `0x1C`
- Base Offset: `0x1C`
- Size: `0x4`

<p>Register used to count the number of bad address accesses.</p>

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "count",
            "bits": 32,
            "attr": [
                "r"
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
}</script>

| Bits | Identifier | Access | Reset | Name |
| ---- | ---------- | ------ | ----- | ---- |
| 31:0 | count      | r      | 0x0   | —    |

#### count field

<p>Counter value, incremented on each bad address access</p>

---

### test_register_1 register

- Absolute Address: `0xF8`
- Base Offset: `0xF8`
- Size: `0x4`

<p>Register used to test a 32-bit read/write register with all bits used for data.</p>

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "test_bits",
            "bits": 32,
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
}</script>

| Bits | Identifier | Access | Reset | Name |
| ---- | ---------- | ------ | ----- | ---- |
| 31:0 | test_bits  | rw     | 0x0   | —    |

#### test_bits field

<p>Test bits</p>

---

### test_register_2 register

- Absolute Address: `0xFC`
- Base Offset: `0xFC`
- Size: `0x4`

<p>Register used to test a 32-bit read/write register with all bits used for data.</p>

<script type="WaveDrom">
{
    "reg": [
        {
            "name": "test_bits",
            "bits": 32,
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
}</script>

| Bits | Identifier | Access | Reset | Name |
| ---- | ---------- | ------ | ----- | ---- |
| 31:0 | test_bits  | rw     | 0x0   | —    |

#### test_bits field

<p>Test bits</p>

---
