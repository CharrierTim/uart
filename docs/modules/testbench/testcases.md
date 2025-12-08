# Testcase Descriptions

---

## Testcase 01: `test_top_fpga_registers`

### Description

Checks default values and access rights (RO/RW) for the test registers of the FPGA.

### Steps

1. **Reset the DUT**
    - Call [`proc_reset_dut`](tb_top_fpga.md#procedure-proc_reset_dut)
    - Wait for 100 µs

2. **Check Default Register Values**
    - For each register:
        - [`C_REG_GIT_ID_MSB`](../regfile/regfile.md#reg_git_id_msb)
        - [`C_REG_GIT_ID_LSB`](../regfile/regfile.md#reg_git_id_lsb)
        - [`C_REG_12`](../regfile/regfile.md#reg_12)
        - [`C_REG_34`](../regfile/regfile.md#reg_34)
        - [`C_REG_56`](../regfile/regfile.md#reg_56)
        - [`C_REG_78`](../regfile/regfile.md#reg_78)
        - [`C_REG_9A`](../regfile/regfile.md#reg_9a)
        - [`C_REG_CD`](../regfile/regfile.md#reg_cd)
        - [`C_REG_EF`](../regfile/regfile.md#reg_ef)
        - [`C_REG_16_BITS`](../regfile/regfile.md#reg_16_bits)
        - `C_REG_DEAD`

      Call [`proc_uart_check_default_value`](tb_top_fpga.md#procedure-proc_uart_check_default_value) and verify value
      after reset.

3. **Verify Read-Only Registers**
    - For each read-only register (same as above except for `C_REG_16_BITS`):
      - Call [`proc_uart_check_read_only`](tb_top_fpga.md#procedure-proc_uart_check_read_only).

4. **Verify Read-Write Registers**
    - Check [`C_REG_16_BITS`](../regfile/regfile.md#reg_16_bits):
        - Write `not C_REG_16_BITS.data` with [`proc_uart_write`](tb_top_fpga.md#procedure-proc_uart_write).
        - Read back and verify value with [`proc_uart_check`](tb_top_fpga.md#procedure-proc_uart_check).

5. **Write and Verify Custom Value**
    - Write `0xABCD` to [`C_REG_16_BITS`](../regfile/regfile.md#reg_16_bits).
    - Read back and check value is `0xABCD`.

---

## Testcase 02: `test_uart_robustness`

### Description

Tests robustness of UART implementation including invalid start/stop bits and command framing.

### Steps

1. **Reset the DUT**
    - Call [`proc_reset_dut`](tb_top_fpga.md#procedure-proc_reset_dut)
    - Wait for 100 µs

2. **Send Read Command With Invalid Start Bit in 'R'**
    - Set manual UART: `tb_i_uart_select` to `1`
    - Manipulate `tb_i_uart_rx_manual` as follows:
        1. Set to `0`, wait 0.25 × `C_UART_BIT_TIME` (invalid start bit)
        2. Set to `1`, wait 0.75 × `C_UART_BIT_TIME`
        3. Set to `0`, wait `C_UART_BIT_TIME` (bit 0)
        4. Set to `1`, wait `C_UART_BIT_TIME` (bit 1)
        5. Set to `0`, wait `C_UART_BIT_TIME` (bit 2)
        6. Set to `0`, wait `C_UART_BIT_TIME` (bit 3)
        7. Set to `1`, wait `C_UART_BIT_TIME` (bit 4)
        8. Set to `0`, wait `C_UART_BIT_TIME` (bit 5)
        9. Set to `1`, wait `C_UART_BIT_TIME` (bit 6)
        10. Set to `0`, wait `C_UART_BIT_TIME` (bit 7)
        11. Send stop bit (`1`), 1.1 × wait `C_UART_BIT_TIME`
    - Send bytes `0x30`, `0x30`, `0x0D` using [`proc_uart_send_byte`](tb_top_fpga.md#procedure-proc_uart_send_byte)
    - Wait 1.1 × `C_UART_READ_CMD_TIME`
    - Check UART TX is stable high: `tb_pad_o_uart_tx` remains `1` for `C_UART_READ_CMD_TIME` with `check_equal`

3. **Send Read Command With Invalid Stop Bit in 'R'**
    - Call [`proc_reset_dut`](tb_top_fpga.md#procedure-proc_reset_dut)
    - Wait for 100 µs
    - Set `tb_i_uart_select` to `1`
    - Manipulate `tb_i_uart_rx_manual` as follows:
        1. Send start bit (`0`), wait `C_UART_BIT_TIME`
        2. Set to `0`, wait `C_UART_BIT_TIME` (bit 0)
        3. Set to `1`, wait `C_UART_BIT_TIME` (bit 1)
        4. Set to `0`, wait `C_UART_BIT_TIME` (bit 2)
        5. Set to `0`, wait `C_UART_BIT_TIME` (bit 3)
        6. Set to `1`, wait `C_UART_BIT_TIME` (bit 4)
        7. Set to `0`, wait `C_UART_BIT_TIME` (bit 5)
        8. Set to `1`, wait `C_UART_BIT_TIME` (bit 6)
        9. Set to `0`, wait `C_UART_BIT_TIME` (bit 7)
        10. Send invalid stop bit (`0`), 1.1 × wait `C_UART_BIT_TIME`
    - Send bytes `0x30`, `0x30`, `0x0D` using [`proc_uart_send_byte`](tb_top_fpga.md#procedure-proc_uart_send_byte)
    - Wait 1.1 × `C_UART_READ_CMD_TIME`
    - Check UART TX is stable high: `tb_pad_o_uart_tx` remains `1` for `C_UART_READ_CMD_TIME` with `check_equal`

4. **Check UART Timings With Value `0x5555`**
    - Call [`proc_reset_dut`](tb_top_fpga.md#procedure-proc_reset_dut)
    - Wait for 100 µs
    - Set `tb_check_uart_timings` to `1`
    - Write `0x5555` to [`C_REG_16_BITS`](../regfile/regfile.md#reg_16_bits) with [`proc_uart_write`](tb_top_fpga.md#procedure-proc_uart_write)
    - Read back using [`proc_uart_read`](tb_top_fpga.md#procedure-proc_uart_read) to start the timing check
    - Wait for `C_UART_READ_CMD_TIME`

5. **Send Read Commands With Invalid CR**
    - Call [`proc_reset_dut`](tb_top_fpga.md#procedure-proc_reset_dut)
    - Wait for 100 µs
    - Send bytes: `0x52`, `0x30`, `0x31`, `0x0A` (missing CR)
    - Wait `C_UART_READ_CMD_TIME`
    - Check TX remains `1` for duration

6. **Send Write Command With Invalid CR**
    - Call [`proc_reset_dut`](tb_top_fpga.md#procedure-proc_reset_dut)
    - Wait for 100 µs
    - Check default value for [`C_REG_16_BITS`](../regfile/regfile.md#reg_16_bits)
    - Send bytes: `0x57`, `0x46`, `0x46`, `0x39`, `0x40`, `0x41`, `0x42`, `0x0A` using [`proc_uart_send_byte`](tb_top_fpga.md#procedure-proc_uart_send_byte)
    - Wait `C_UART_READ_CMD_TIME`
    - Check value in [`C_REG_16_BITS`](../regfile/regfile.md#reg_16_bits) was not written; contents unchanged with [`proc_uart_check`](tb_top_fpga.md#procedure-proc_uart_check)

---

## Testcase 03: `test_led_and_switches_toggling`

### Description

Validates `REG_LED` (read-write) and `REG_SWITCHES` (read-only). Checks toggling the LED output and reading all switch combinations.

### Steps

1. **Check Register `REG_LED` Characteristics**
    - Call [`proc_reset_dut`](tb_top_fpga.md#procedure-proc_reset_dut)
    - Wait for 100 µs
    - Check default value using [`proc_uart_check_default_value`](tb_top_fpga.md#procedure-proc_uart_check_default_value)
    for [`C_REG_LED`](../regfile/regfile.md#reg_led)
    - Check register [`C_REG_LED`](../regfile/regfile.md#reg_led) is in read-write mode by writing
    `not C_REG_LED.data` and that written value equals to `15b"0" & not C_REG_LED.data(0)` using [`proc_uart_check_read_write`](tb_top_fpga.md#procedure-proc_uart_check_read_write)

2. **Toggle `led_0` Register and Verify Output**
    - Write `0x0001` to [`C_REG_LED`](../regfile/regfile.md#reg_led)
      Wait for 1 ms
      Check `tb_pad_o_led_0` is stable at `'1'` for `0.7 ms` using `check_equal`
    - Write `0x0000` to [`C_REG_LED`](../regfile/regfile.md#reg_led)
      Wait for 2.5 ms
      Check `tb_pad_o_led_0` is stable at `'0'` for `2.3 ms`
    - Write `0x0001` to [`C_REG_LED`](../regfile/regfile.md#reg_led)
      Wait for 2 ms
      Check `tb_pad_o_led_0` is stable at `'1'` for `1.8 ms`

3. **Check Register `REG_SWITCHES` Characteristics**
    - Call [`proc_reset_dut`](tb_top_fpga.md#procedure-proc_reset_dut)
    - Wait for 100 µs
    - Check default value using [`proc_uart_check_default_value`](tb_top_fpga.md#procedure-proc_uart_check_default_value)
     for [`C_REG_SWITCHES`](../regfile/regfile.md#reg_switches)
    - Check register [`C_REG_SWITCHES`](../regfile/regfile.md#reg_switches) is in read-only mode using [`proc_uart_check_read_only`](tb_top_fpga.md#procedure-proc_uart_check_read_only)

4. **Toggle Input Switches and Verify Combinations**
    - For all combinations of `tb_pad_i_switch_0`, `tb_pad_i_switch_1`, `tb_pad_i_switch_2` (from `0` to `7`):
        - Set switches with binary pattern from `i`
        - Wait for 1 ns (signal propagation)
        - Check register [`C_REG_SWITCHES`](../regfile/regfile.md#reg_switches) value matches the bit pattern using [`proc_uart_check`](tb_top_fpga.md#procedure-proc_uart_check)

---

## Testcase 04: `test_spi`

### Description

Tests SPI master TX and RX registers, including SPI transfer correctness and MOSI/MISO data verification.

### Steps

1. **Reset DUT and Check Register Default Values**
    - Call [`proc_reset_dut`](tb_top_fpga.md#procedure-proc_reset_dut)
    - Wait for 100 µs
    - Check default value of [`C_REG_SPI_TX`](../regfile/regfile.md#reg_spi_tx) using [`proc_uart_check_default_value`](tb_top_fpga.md#procedure-proc_uart_check_default_value)
    - Check default value of [`C_REG_SPI_RX`](../regfile/regfile.md#reg_spi_rx) using [`proc_uart_check_default_value`](tb_top_fpga.md#procedure-proc_uart_check_default_value)
    - Check register [`C_REG_SPI_RX`](../regfile/regfile.md#reg_spi_rx) is in read-only mode using [`proc_uart_check_read_only`](tb_top_fpga.md#procedure-proc_uart_check_read_only)
    - Check register [`C_REG_SPI_TX`](../regfile/regfile.md#reg_spi_tx) is in read-write mode by writing
    `not C_REG_SPI_TX.data` and that written value equals to `0x01FF` using [`proc_uart_check_read_write`](tb_top_fpga.md#procedure-proc_uart_check_read_write)
    - Pop data from SPI model and check it is equals to `not C_REG_SPI_TX.data[7:0]` with `check_equal`

2. **Testing SPI output**
    - Call [`proc_reset_dut`](tb_top_fpga.md#procedure-proc_reset_dut)
    - Wait for 100 µs
    - Send an SPI transaction with data set to `0x55` using [`proc_spi_check`](tb_top_fpga.md#procedure-proc_spi_check)
    - Send an SPI transaction with data set to `0xAB` using [`proc_spi_check`](tb_top_fpga.md#procedure-proc_spi_check)
    - Send an SPI transaction with data set to `0x1E` using [`proc_spi_check`](tb_top_fpga.md#procedure-proc_spi_check)

3. **Testing SPI timings**
    - Call [`proc_reset_dut`](tb_top_fpga.md#procedure-proc_reset_dut)
    - Wait for 100 µs
    - Set `tb_check_spi_timings` to 1
    - Wait for 2 × `C_CLK_PERIOD`
    - Set `tb_check_spi_timings` to 0
    - Send an SPI transaction with data set to `0x55` using [`proc_spi_write`](tb_top_fpga.md#procedure-proc_spi_write)
    - Wait for 2 × `C_SPI_TRANSACTION_TIME` (time longer than the response)
    - Set `tb_check_spi_timings` to 1
    - Wait for 2 × `C_CLK_PERIOD`
    - Set `tb_check_spi_timings` to 0
    - Send an SPI transaction with data set to `0xAB` using [`proc_spi_write`](tb_top_fpga.md#procedure-proc_spi_write)
    - Wait for 2 × `C_SPI_TRANSACTION_TIME` (time longer than the response)

---
