# Testbench description

## Overview

The following figure depicts the Testbench:

![Testbench Diagram](../../assets/uart.drawio){ page="TB-TOP-FPGA" }

## Types

### t_reg

A record type used to define register configurations for the testbench.

| Property      | Description                                                                                                                                                                             |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Type Name** | `t_reg`                                                                                                                                                                                 |
| **Purpose**   | Register fields with address and default value                                                                                                                                          |
| **Fields**    | - `name` : `string` - Register name identifier<br>- `addr` : `std_logic_vector(7 downto 0)` - 8-bit register address<br>- `data` : `std_logic_vector(15 downto 0)` - 16-bit reset value |

## Constants

### General constants

The following constants are defined:

| Name                       | Type         | Value            re                          | Description                             |
| -------------------------- | ------------ | -------------------------------------------- | --------------------------------------- |
| `C_FREQ_HZ`                | positive     | 0d100_000_000                                | Clock frequency                         |
| `C_CLK_PERIOD`             | time         | 1 sec / `C_FREQ_HZ`                          | Clock period                            |
| `C_GIT_ID`                 | vector[31:0] | 0x12345678                                   | Git identifier for DUT version tracking |
| `C_UART_BAUD_RATE_BPS`     | positive     | 0d115_200                                    | UART baud rate in bits per second       |
| `C_UART_BIT_TIME`          | time         | 1 sec / `C_UART_BAUD_RATE_BPS`               | Time duration for one UART bit          |
| `C_UART_BIT_TIME_ACCURACY` | time         | 0.01 * `C_UART_BIT_TIME`                     | UART bit timing tolerance (1%)          |
| `C_UART_WRITE_NB_BITS`     | positive     | 10 * 8                                       | Total bits for UART write command       |
| `C_UART_WRITE_CMD_TIME`    | time         | `C_UART_BIT_TIME` * `C_UART_WRITE_NB_BITS`   | Total time for UART write command       |
| `C_READ_NB_BITS`           | positive     | 10 * 9                                       | Total bits for UART read command        |
| `C_UART_READ_CMD_TIME`     | time         | `C_UART_BIT_TIME` * `C_UART_READ_NB_BITS`    | Total time for UART read command        |
| `C_SPI_FREQ_HZ`            | positive     | 0d1_000_000                                  | SPI SLCK frequency                      |
| `C_SPI_BIT_TIME`           | time         | 1 sec / `C_SPI_FREQ_HZ`                      | SPI baud rate in bits per second        |
| `C_SPI_BIT_TIME_ACCURACY`  | time         | 0.01 * `C_SPI_BIT_TIME`                      | SPI bit timing tolerance (1%)           |
| `C_SPI_NB_DATA_BIS`        | positive     | 8                                            | Total bits in SPI transaction           |
| `C_SPI_TRANSACTION_TIME`   | time         | (`C_SPI_NB_DATA_BIS` + 2) * `C_SPI_BIT_TIME` | SPI transaction time                    |
| `C_SPI_CLK_POLARITY`       | std_logic    | 0b0                                          | SPI SLCK polarity                       |
| `C_SPI_CLK_PHASE`          | std_logic    | 0b0                                          | SPI SLCK phase                          |

### Registers

The following registers are defined as [`t_reg`](#t_reg):

| Name               | Address | Reset Value |
| ------------------ | ------- | ----------- |
| `C_REG_GIT_ID_MSB` | 0x00    | 0x1234      |
| `C_REG_GIT_ID_LSB` | 0x01    | 0x5678      |
| `C_REG_12`         | 0x02    | 0x1212      |
| `C_REG_34`         | 0x03    | 0x3434      |
| `C_REG_56`         | 0x04    | 0x5656      |
| `C_REG_78`         | 0x05    | 0x7878      |
| `C_REG_SPI_TX`     | 0x06    | 0x0000      |
| `C_REG_SPI_RX`     | 0x07    | 0x0000      |
| `C_REG_9A`         | 0xAB    | 0x9A9A      |
| `C_REG_CD`         | 0xAC    | 0xCDCD      |
| `C_REG_EF`         | 0xDC    | 0xEFEF      |
| `C_REG_SWITCHES`   | 0xB1    | 0x0000      |
| `C_REG_LED`        | 0xEF    | 0x0001      |
| `C_REG_16_BITS`    | 0xFF    | 0x0000      |
| `C_REG_DEAD`       | 0xCC    | 0xDEAD      |

## Procedures

### Procedure `proc_check_time_in_range`

#### Description

This procedure performs a range check to verify that `time_to_check` is within `expected_time ± accuracy`.

#### Parameters

| Parameter       | Type     | Default | Description                                                 |
| --------------- | -------- | ------- | ----------------------------------------------------------- |
| `time_to_check` | `time`   | -       | The actual time value to be validated                       |
| `expected_time` | `time`   | -       | The target/expected time value                              |
| `accuracy`      | `time`   | -       | The acceptable deviation (tolerance) from the expected time |
| `message`       | `string` | `""`    | Optional custom message prefix for the assertion output     |

#### Steps

```raw
# Perform range check
Check that abs(time_to_check - expected_time) <= accuracy with procedure check
```

---

### Procedure `proc_reset_dut`

#### Description

This procedure puts all the testbench signals into a known state.

#### Parameters

| Parameter        | Type       | Default | Description                    |
| ---------------- | ---------- | ------- | ------------------------------ |
| `c_clock_cycles` | `positive` | 50      | Number of clock cycles to wait |

#### Steps

```raw
# Reset the DUT by setting the input state to all zeros
Set tb_pad_i_rst_h to 1
Set tb_i_uart_select to 0
Set tb_i_uart_rx_manual to 0
Set tb_pad_i_switch_0 to 0
Set tb_pad_i_switch_1 to 0
Set tb_pad_i_switch_2 to 0
Set tb_i_read_address to 0x00
Set tb_i_read_address_valid to 0
Set tb_i_write_address to 0x00
Set tb_i_write_data to 0x0000
Set tb_i_write_valid to 0
Set tb_check_uart_timings to 0
Set tb_check_spi_timings to 0

# Wait for the specified number of clock cycles
Wait for c_clock_cycles * C_CLK_PERIOD

# De-assert reset
Set tb_pad_i_rst_h to 0

# Wait for the DUT to settle
Wait for 5 ns
```

---

### Procedure `proc_uart_send_byte`

#### Description

This procedure sends a byte via UART using the manually driven line.

#### Parameters

| Parameter      | Type          | Default | Description            |
| -------------- | ------------- | ------- | ---------------------- |
| `uart_rx`      | `std_logic`   | -       | The UART line to drive |
| `byte_to_send` | `vector[7:0]` | -       | The byte to send       |

#### Steps

```raw
# Ensure the manual UART is selected
if tb_i_uart_select = 0:
    Set tb_i_uart_select to 1
    Wait for 200 ns

# Send the start bit
Set uart_rx to 0
Wait for C_UART_BIT_TIME

# Send the data bits (LSB to MSB)
for bit_idx in byte_to_send'low to byte_to_send'high:
    Set uart_rx to byte_to_send(bit_idx)
    Wait for C_UART_BIT_TIME

# Send the stop bit
Set uart_rx to 1
Wait for 1. 1 * C_UART_BIT_TIME
```

---

### Procedure `proc_uart_write`

#### Description

This procedure writes a value to a specified UART register.

#### Parameters

| Parameter | Type              | Default | Description                        |
| --------- | ----------------- | ------- | ---------------------------------- |
| `reg`     | [`t_reg`](#t_reg) | -       | The register to write to           |
| `value`   | `vector[15:0]`    | -       | The value to write to the register |

#### Steps

```raw
# Ensure the model UART is selected
if tb_i_uart_select = 1:
    Set tb_i_uart_select to 0
    Wait for 200 ns

# Set up the write operation
Set tb_i_write_address to reg. addr
Set tb_i_write_data to value
Set tb_i_write_valid to 1

# Wait some time and de-assert the valid flag
Wait for 200 ns
Set tb_i_write_valid to 0

# Wait for the write operation to complete
Wait for 1.1 * C_UART_WRITE_CMD_TIME
```

---

### Procedure `proc_uart_read`

#### Description

This procedure reads a value from a specified UART register.

#### Parameters

| Parameter | Type              | Default | Description               |
| --------- | ----------------- | ------- | ------------------------- |
| `reg`     | [`t_reg`](#t_reg) | -       | The register to read from |

#### Steps

```raw
# Ensure the model UART is selected
if tb_i_uart_select = 1:
    Set tb_i_uart_select to 0
    Wait for 200 ns

# Wait some time before starting the read to avoid simulation stuck
Wait for 500 ns

# Set up the read operation
Set tb_i_read_address to reg.addr
Set tb_i_read_address_valid to 1

# Wait for the read operation to complete
Wait for a rising edge on signal tb_o_read_data_valid

# De-assert the read valid signal after completion
Set tb_i_read_address_valid to 0
```

---

### Procedure `proc_uart_check`

#### Description

This procedure checks if the read value from a specified UART register matches the expected value.

#### Parameters

| Parameter        | Type              | Default | Description                           |
| ---------------- | ----------------- | ------- | ------------------------------------- |
| `reg`            | [`t_reg`](#t_reg) | -       | The register to check                 |
| `expected_value` | `vector[15:0]`    | -       | The expected value to compare against |

#### Steps

```raw
# Read the register value
Read the register reg value with procedure proc_uart_read

Check that the returned value tb_o_read_data equals expected_value with the procedure check_equal
```

---

### Procedure `proc_uart_check_default_value`

#### Description

This procedure checks if the default value of a specified UART register matches the expected reset value.

#### Parameters

| Parameter | Type              | Default | Description           |
| --------- | ----------------- | ------- | --------------------- |
| `reg`     | [`t_reg`](#t_reg) | -       | The register to check |

#### Steps

```raw
# Check the default value against the register's reset value
Check that the value after reset is equal to the one specified in reg.data with the procedure proc_uart_check
```

---

### Procedure `proc_uart_check_read_only`

#### Description

This procedure checks if a specified UART register is read-only by attempting to write to it and verifying that the
value remains unchanged.

#### Parameters

| Parameter | Type              | Default | Description           |
| --------- | ----------------- | ------- | --------------------- |
| `reg`     | [`t_reg`](#t_reg) | -       | The register to check |

#### Steps

```raw
# Attempt to write an incorrect value to the register
Write the data not(reg.data) to the register adress reg.addr with procedure proc_uart_write

# Check if the register value remains unchanged
Read back the register and check if the register value remains unchanged with procedure proc_uart_check
```

---

### Procedure `proc_uart_check_read_write`

#### Description

This procedure checks if a specified UART register is read-write by writing a value to it and verifying that the
value is correctly updated.

#### Parameters

| Parameter        | Type              | Default | Description                                         |
| ---------------- | ----------------- | ------- | --------------------------------------------------- |
| `reg`            | [`t_reg`](#t_reg) | -       | The register to check                               |
| `expected_value` | `vector[15:0]`    | -       | The expected value to compare against after writing |

#### Steps

```raw
# Write the inverted default value to the register
Write the data not(reg.data) to the register adress reg.addr with procedure proc_uart_write

# Check if the register value is updated correctly
Read back the register and check if the register value is matching expected_value with procedure proc_uart_check
```

---

### Procedure `proc_spi_write`

#### Description

Writes a byte value to the SPI master module via UART register interface.

#### Parameters

| Parameter | Type          | Default | Description                    |
| --------- | ------------- | ------- | ------------------------------ |
| `value`   | `vector[7:0]` | -       | 8-bit data to transmit via SPI |

#### Steps

```raw
# Reset C_REG_SPI_TX before for the rising edge detection
Write 0x0000 to register C_REG_SPI_TX with procedure proc_uart_write

# Write the data and the valid flag set
Write (7b0 & 1b1 & value) to the register C_REG_SPI_TX with procedure proc_uart_write
```

---

### Procedure `proc_spi_check`

#### Description

Writes a value to SPI master and verifies correct transmission and reception.

#### Parameters

| Parameter | Type          | Default | Description                       |
| --------- | ------------- | ------- | --------------------------------- |
| `value`   | `vector[7:0]` | -       | 8-bit data to transmit and verify |

#### Steps

```raw
# Write data to SPI
Start an SPI transaction with procedure proc_spi_write

# Retrieve data from SPI slave stream (MOSI path verification)
Pop data from C_SLAVE_STREAM into v_spi_slave_data

# Verify MOSI path
Check that v_spi_slave_data equals `value` with procedure check_equal

# Read and verify MISO register data
Check that sampled SPI data from slave is matching the one decoded in the REG_SPI_RX register with procedure proc_uart_check
```
