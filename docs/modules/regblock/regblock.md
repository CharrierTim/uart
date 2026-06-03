# Registers

## Description

Internal FPGA registers with read/write registers accessible via the UART.
An UART-AXI4 Lite bridge is used to access these registers.

Documentation partially generated from the RDL file using the
[`generate_regblock.py`](https://github.com/CharrierTim/uart/blob/main/tools/peakrdl/script/generate_regblock.py) script.

## Summary

| Name                                                          | Offset | Length | Description                                                                               |
| :------------------------------------------------------------ | :----: | :----: | :---------------------------------------------------------------------------------------- |
| regblock.[git_hash](#git_hash-register)                       | `0x00` |   4    | Register indicating the git hash of the repository at the time of bitstream generation.   |
| regblock.[git_status](#git_status-register)                   | `0x04` |   4    | Register indicating the git status of the repository at the time of bitstream generation. |
| regblock.[fpga_id](#fpga_id-register)                         | `0x08` |   4    | Register indicating the FPGA identification information.                                  |
| regblock.[spi_tx_control](#spi_tx_control-register)           | `0x0C` |   4    | Register used to send data over SPI. Writing to this register starts the SPI transaction. |
| regblock.[spi_rx_data](#spi_rx_data-register)                 | `0x10` |   4    | Register used to receive data over SPI.                                                   |
| regblock.[vga_color_control](#vga_color_control-register)     | `0x14` |   4    | Register used to set the VGA output color.                                                |
| regblock.[switch_status](#switch_status-register)             | `0x18` |   4    | Register used to read the status of the input switches.                                   |
| regblock.[bad_address_counter](#bad_address_counter-register) | `0x1C` |   4    | Register used to count the number of bad address accesses.                                |
| regblock.[test_register_1](#test_register_1-register)         | `0xF8` |   4    | Register used to test a 32-bit read/write register with all bits used for data.           |
| regblock.[test_register_2](#test_register_2-register)         | `0xFC` |   4    | Register used to test a 32-bit read/write register with all bits used for data.           |

## git_hash register

Register indicating the git hash of the repository at the time of bitstream generation.

- Offset: `0x0`
- Reset default: `0x0`
- Reset mask: `0xffffffff`

### Fields

<!-- markdownlint-disable -->
<script type="WaveDrom">
{"reg": [{"name": "hash", "bits": 32, "attr": ["ro"], "rotate": 0}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}
</script>

<div class="register-bits-table" markdown="1">

| Bits  | Type  | Reset | Name | Description |
| :---: | :---: | :---: | :--- | :---------- |
| 31:0  |  ro   |  0x0  | hash | Hash value  |

</div>
<!-- markdownlint-enable -->

## git_status register

Register indicating the git status of the repository at the time of bitstream generation.
If the value is 1, there were uncommitted changes in the repository (dirty), while if the
value is 0, there were no uncommitted changes (clean).

- Offset: `0x4`
- Reset default: `0x0`
- Reset mask: `0x1`

### Fields

<!-- markdownlint-disable -->
<script type="WaveDrom">
{"reg": [{"name": "status", "bits": 1, "attr": ["ro"], "rotate": -90}, {"bits": 31}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}
</script>

<div class="register-bits-table" markdown="1">

| Bits  | Type  | Reset | Name   | Description  |
| :---: | :---: | :---: | :----- | :----------- |
| 31:1  |       |       |        | Reserved     |
|   0   |  ro   |  0x0  | status | Status value |

</div>
<!-- markdownlint-enable -->

## fpga_id register

Register indicating the FPGA identification information.

- Offset: `0x8`
- Reset default: `0x0`
- Reset mask: `0xffffffff`

### Fields

<!-- markdownlint-disable -->
<script type="WaveDrom">
{"reg": [{"name": "id", "bits": 32, "attr": ["ro"], "rotate": 0}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}
</script>

<div class="register-bits-table" markdown="1">

| Bits  | Type  | Reset | Name | Description |
| :---: | :---: | :---: | :--- | :---------- |
| 31:0  |  ro   |  0x0  | id   | ID value    |

</div>
<!-- markdownlint-enable -->

## spi_tx_control register

Register used to send data over SPI. Writing to this register starts the SPI transaction.

- Offset: `0xc`
- Reset default: `0x0`
- Reset mask: `0x1ff`

### Fields

<!-- markdownlint-disable -->
<script type="WaveDrom">
{"reg": [{"name": "tx_data", "bits": 8, "attr": ["rw"], "rotate": 0}, {"name": "tx_data_valid", "bits": 1, "attr": ["rw"], "rotate": -90}, {"bits": 23}], "config": {"lanes": 1, "fontsize": 10, "vspace": 150}}
</script>

<div class="register-bits-table" markdown="1">

| Bits  | Type  | Reset | Name          | Description                                                                                                     |
| :---: | :---: | :---: | :------------ | :-------------------------------------------------------------------------------------------------------------- |
| 31:9  |       |       |               | Reserved                                                                                                        |
|   8   |  rw   |  0x0  | tx_data_valid | SPI transaction valid signal. Asserts for one cycle when written 1 and then clears back to 0 on the next cycle. |
|  7:0  |  rw   |  0x0  | tx_data       | TX data to be sent                                                                                              |

</div>
<!-- markdownlint-enable -->

## spi_rx_data register

Register used to receive data over SPI.

- Offset: `0x10`
- Reset default: `0x0`
- Reset mask: `0xff`

### Fields

<!-- markdownlint-disable -->
<script type="WaveDrom">
{"reg": [{"name": "rx_data", "bits": 8, "attr": ["ro"], "rotate": 0}, {"bits": 24}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}
</script>

<div class="register-bits-table" markdown="1">

| Bits  | Type  | Reset | Name    | Description               |
| :---: | :---: | :---: | :------ | :------------------------ |
| 31:8  |       |       |         | Reserved                  |
|  7:0  |  ro   |  0x0  | rx_data | RX data received over SPI |

</div>
<!-- markdownlint-enable -->

## vga_color_control register

Register used to set the VGA output color.
The color is specified in RGB format, with 4 bits for each channel (red, green, blue).

- Offset: `0x14`
- Reset default: `0xf0`
- Reset mask: `0xfff`

### Fields

<!-- markdownlint-disable -->
<script type="WaveDrom">
{"reg": [{"name": "blue", "bits": 4, "attr": ["rw"], "rotate": 0}, {"name": "green", "bits": 4, "attr": ["rw"], "rotate": 0}, {"name": "red", "bits": 4, "attr": ["rw"], "rotate": 0}, {"bits": 20}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}
</script>

<div class="register-bits-table" markdown="1">

| Bits  | Type  | Reset | Name  | Description                    |
| :---: | :---: | :---: | :---- | :----------------------------- |
| 31:12 |       |       |       | Reserved                       |
| 11:8  |  rw   |  0x0  | red   | Red channel intensity (0-15)   |
|  7:4  |  rw   |  0xf  | green | Green channel intensity (0-15) |
|  3:0  |  rw   |  0x0  | blue  | Blue channel intensity (0-15)  |

</div>
<!-- markdownlint-enable -->

## switch_status register

Register used to read the status of the input switches.
Each bit corresponds to a different switch, with bit 0 corresponding to switch_0,
bit 1 to switch_1, and bit 2 to switch_2.

- Offset: `0x18`
- Reset default: `0x0`
- Reset mask: `0x7`

### Fields

<!-- markdownlint-disable -->
<script type="WaveDrom">
{"reg": [{"name": "switch_0", "bits": 1, "attr": ["ro"], "rotate": -90}, {"name": "switch_1", "bits": 1, "attr": ["ro"], "rotate": -90}, {"name": "switch_2", "bits": 1, "attr": ["ro"], "rotate": -90}, {"bits": 29}], "config": {"lanes": 1, "fontsize": 10, "vspace": 100}}
</script>

<div class="register-bits-table" markdown="1">

| Bits  | Type  | Reset | Name     | Description        |
| :---: | :---: | :---: | :------- | :----------------- |
| 31:3  |       |       |          | Reserved           |
|   2   |  ro   |  0x0  | switch_2 | Status of switch 2 |
|   1   |  ro   |  0x0  | switch_1 | Status of switch 1 |
|   0   |  ro   |  0x0  | switch_0 | Status of switch 0 |

</div>
<!-- markdownlint-enable -->

## bad_address_counter register

Register used to count the number of bad address accesses.

- Offset: `0x1c`
- Reset default: `0x0`
- Reset mask: `0xffffffff`

### Fields

<!-- markdownlint-disable -->
<script type="WaveDrom">
{"reg": [{"name": "count", "bits": 32, "attr": ["ro"], "rotate": 0}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}
</script>

<div class="register-bits-table" markdown="1">

| Bits  | Type  | Reset | Name  | Description                                           |
| :---: | :---: | :---: | :---- | :---------------------------------------------------- |
| 31:0  |  ro   |  0x0  | count | Counter value, incremented on each bad address access |

</div>
<!-- markdownlint-enable -->

## test_register_1 register

Register used to test a 32-bit read/write register with all bits used for data.

- Offset: `0xf8`
- Reset default: `0x0`
- Reset mask: `0xffffffff`

### Fields

<!-- markdownlint-disable -->
<script type="WaveDrom">
{"reg": [{"name": "test_bits", "bits": 32, "attr": ["rw"], "rotate": 0}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}
</script>

<div class="register-bits-table" markdown="1">

| Bits  | Type  | Reset | Name      | Description |
| :---: | :---: | :---: | :-------- | :---------- |
| 31:0  |  rw   |  0x0  | test_bits | Test bits   |

</div>
<!-- markdownlint-enable -->

## test_register_2 register

Register used to test a 32-bit read/write register with all bits used for data.

- Offset: `0xfc`
- Reset default: `0x0`
- Reset mask: `0xffffffff`

### Fields

<!-- markdownlint-disable -->
<script type="WaveDrom">
{"reg": [{"name": "test_bits", "bits": 32, "attr": ["rw"], "rotate": 0}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}
</script>

<div class="register-bits-table" markdown="1">

| Bits  | Type  | Reset | Name      | Description |
| :---: | :---: | :---: | :-------- | :---------- |
| 31:0  |  rw   |  0x0  | test_bits | Test bits   |

</div>
<!-- markdownlint-enable -->
