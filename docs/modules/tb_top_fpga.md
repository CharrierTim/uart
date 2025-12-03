# Testbench description

## Overview

The following figure depicts the Testbench:

![Testbench Diagram](../assets/uart.drawio){ page="TB-TOP-FPGA" }

## Types

### t_reg

A record type used to define register configurations for the testbench.

| Property      | Description                                                                                                                                                                             |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Type Name** | `t_reg`                                                                                                                                                                                 |
| **Purpose**   | Register fields with address and default value                                                                                                                                          |
| **Fields**    | - `name` : `string` - Register name identifier<br>- `addr` : `std_logic_vector(7 downto 0)` - 8-bit register address<br>- `data` : `std_logic_vector(15 downto 0)` - 16-bit reset value |

## Constants

The following constants are defined:

| Name                    | Type         | Value                            | Description                             |
| ----------------------- | ------------ | -------------------------------- | --------------------------------------- |
| `C_FREQ_HZ`             | positive     | 0d100_000_000                    | Clock frequency                         |
| `C_CLK_PERIOD`          | time         | 1 sec / `C_FREQ_HZ`              | Clock period                            |
| `C_GIT_ID`              | vector[31:0] | 0x12345678                       | Git identifier for DUT version tracking |
| `C_BAUD_RATE_BPS`       | positive     | 0d115_200                        | UART baud rate in bits per second       |
| `C_BIT_TIME`            | time         | 1 sec / `C_BAUD_RATE_BPS`        | Time duration for one UART bit          |
| `C_BIT_TIME_ACCURACY`   | time         | 0.01 * `C_BIT_TIME`              | UART bit timing tolerance (1%)          |
| `C_WRITE_NB_BITS`       | positive     | 10 * 8                           | Total bits for UART write command       |
| `C_UART_WRITE_CMD_TIME` | time         | `C_BIT_TIME` * `C_WRITE_NB_BITS` | Total time for UART write command       |
| `C_READ_NB_BITS`        | positive     | 10 * 9                           | Total bits for UART read command        |
| `C_UART_READ_CMD_TIME`  | time         | `C_BIT_TIME` * `C_READ_NB_BITS`  | Total time for UART read command        |

## Registers

The following registers are defined as `t_reg`:

| Name               | Address | Reset Value |
| ------------------ | ------- | ----------- |
| `C_REG_GIT_ID_MSB` | 0x00    | 0x1234      |
| `C_REG_GIT_ID_LSB` | 0x01    | 0x5678      |
| `C_REG_12`         | 0x02    | 0x1212      |
| `C_REG_34`         | 0x03    | 0x3434      |
| `C_REG_56`         | 0x04    | 0x5656      |
| `C_REG_78`         | 0x05    | 0x7878      |
| `C_REG_9A`         | 0xAB    | 0x9A9A      |
| `C_REG_CD`         | 0xAC    | 0xCDCD      |
| `C_REG_EF`         | 0xDC    | 0xEFEF      |
| `C_REG_SWITCHES`   | 0xB1    | 0x0000      |
| `C_REG_LED`        | 0xEF    | 0x0001      |
| `C_REG_16_BITS`    | 0xFF    | 0x0000      |
| `C_REG_DEAD`       | 0xCC    | 0xDEAD      |
