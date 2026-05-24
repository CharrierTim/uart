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
        - [`C_REG_GIT_HASH`](../regblock/regblock.md#git_hash-register)
        - [`C_REG_GIT_STATUS`](../regblock/regblock.md#git_status-register)
        - [`C_REG_FPGA_ID`](../regblock/regblock.md#fpga_id-register)
        - [`C_REG_TEST_REGISTER_1`](../regblock/regblock.md#test_register_1-register)
        - [`C_REG_TEST_REGISTER_2`](../regblock/regblock.md#test_register_2-register)

      Call [`proc_uart_check_default_value`](tb_top_fpga.md#procedure-proc_uart_check_default_value) and verify value
      after reset.

3. **Verify Read-Only Registers**
    - For each read-only register (same as above except for `C_REG_TEST_REGISTER_1` and `C_REG_TEST_REGISTER_2`):
      - Call [`proc_uart_check_read_only`](tb_top_fpga.md#procedure-proc_uart_check_read_only).

4. **Verify Read-Write Registers**
    - Check [`C_REG_TEST_REGISTER_1`](../regblock/regblock.md#test_register_1-register):
        - Write `not C_REG_TEST_REGISTER_1.data` with [`proc_uart_write`](tb_top_fpga.md#procedure-proc_uart_write).
        - Read back and verify value with [`proc_uart_check`](tb_top_fpga.md#procedure-proc_uart_check).
    - Check [`C_REG_TEST_REGISTER_2`](../regblock/regblock.md#test_register_2-register):
        - Write `not C_REG_TEST_REGISTER_2.data` with [`proc_uart_write`](tb_top_fpga.md#procedure-proc_uart_write).
        - Read back and verify value with [`proc_uart_check`](tb_top_fpga.md#procedure-proc_uart_check).

5. **Write and Verify Custom Value**
    - Write `0x1234_ABCD` to [`C_REG_TEST_REGISTER_1`](../regblock/regblock.md#test_register_1-register).
    - Read back and check value is `0x1234_ABCD`.
    - Write `6789_EF01` to [`C_REG_TEST_REGISTER_2`](../regblock/regblock.md#test_register_2-register).
    - Read back and check value is `6789_EF01`.

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

4. **Check UART Timings With Value `0x5555_5555`**
    - Call [`proc_reset_dut`](tb_top_fpga.md#procedure-proc_reset_dut)
    - Wait for 100 µs
    - Set `tb_check_uart_timings` to `1`
    - Write `0x5555_5555` to [`C_REG_TEST_REGISTER_1`](../regblock/regblock.md#test_register_1-register) with [`proc_uart_write`](tb_top_fpga.md#procedure-proc_uart_write)
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
    - Check default value for [`C_REG_TEST_REGISTER_1`](../regblock/regblock.md#test_register_1-register)
    - Send bytes: `0x57`, `0x46`, `0x46`, `0x31`, `0x32`, `0x33`, `0x34`, `0x39`, `0x40`, `0x41`, `0x42`, `0x0A` using [`proc_uart_send_byte`](tb_top_fpga.md#procedure-proc_uart_send_byte)
    - Wait `C_UART_READ_CMD_TIME`
    - Check value in [`C_REG_TEST_REGISTER_1`](../regblock/regblock.md#test_register_1-register) was not written;
    contents unchanged with [`proc_uart_check`](tb_top_fpga.md#procedure-proc_uart_check)

---

## Testcase 03: `test_led_and_switches_toggling`

### Description

Validates the bad address counter and `SWITCH_STATUS` read-only register. Checks bad address handling via `LED_0` and
reading all switch combinations.

### Steps

1. **Check Register `BAD_ADDRESS_COUNTER` Characteristics**
        - Call [`proc_reset_dut`](tb_top_fpga.md#procedure-proc_reset_dut)
        - Wait for 100 µs
        - Check default value using [`proc_uart_check_default_value`](tb_top_fpga.md#procedure-proc_uart_check_default_value)
            for [`C_REG_BAD_ADDRESS_COUNTER`](../regblock/regblock.md#bad_address_counter-register)
        - Check register [`C_REG_BAD_ADDRESS_COUNTER`](../regblock/regblock.md#bad_address_counter-register) is in
        read-only mode using [`proc_uart_check_read_only`](tb_top_fpga.md#procedure-proc_uart_check_read_only)

2. **Read and Write a Bad Address and Verify `led_0` Output**
        - Read from bad address `C_REG_BAD_ADDR`
            - Wait for `C_UART_READ_CMD_TIME`
            - Check `tb_pad_o_led_0` is stable at `'1'` for `C_UART_READ_CMD_TIME` using `check_equal`
        - Reset the DUT, then write to bad address `C_REG_BAD_ADDR`
            - Wait for `C_UART_WRITE_CMD_TIME`
            - Check `tb_pad_o_led_0` is stable at `'1'` for `C_UART_WRITE_CMD_TIME` using `check_equal`

3. **Check Register `SWITCH_STATUS` Characteristics**
        - Call [`proc_reset_dut`](tb_top_fpga.md#procedure-proc_reset_dut)
        - Wait for 100 µs
        - Check default value using [`proc_uart_check_default_value`](tb_top_fpga.md#procedure-proc_uart_check_default_value)
            for [`C_REG_SWITCH_STATUS`](../regblock/regblock.md#switch_status-register)
        - Check register [`C_REG_SWITCH_STATUS`](../regblock/regblock.md#switch_status-register) is in read-only mode
        using [`proc_uart_check_read_only`](tb_top_fpga.md#procedure-proc_uart_check_read_only)

4. **Toggle Input Switches and Verify Combinations**
        - For all combinations of `tb_pad_i_switch_0`, `tb_pad_i_switch_1`, `tb_pad_i_switch_2` (from `0` to `7`):
            - Set switches with binary pattern from `i`
            - Wait for 1 ns (signal propagation)
            - Check register [`C_REG_SWITCH_STATUS`](../regblock/regblock.md#switch_status-register) value matches
            the bit pattern using [`proc_uart_check`](tb_top_fpga.md#procedure-proc_uart_check)

---

## Testcase 04: `test_spi`

### Description

Tests SPI master TX and RX registers, including SPI transfer correctness and MOSI/MISO data verification.

### Steps

1. **Reset DUT and Check Register Default Values**
    - Call [`proc_reset_dut`](tb_top_fpga.md#procedure-proc_reset_dut)
    - Wait for 100 µs
    - Check default value of [`C_REG_SPI_TX_CONTROL`](../regblock/regblock.md#spi_tx_control-register) using [`proc_uart_check_default_value`](tb_top_fpga.md#procedure-proc_uart_check_default_value)
    - Check default value of [`C_REG_SPI_RX_DATA`](../regblock/regblock.md#spi_rx_data-register) using [`proc_uart_check_default_value`](tb_top_fpga.md#procedure-proc_uart_check_default_value)
    - Check register [`C_REG_SPI_RX_DATA`](../regblock/regblock.md#spi_rx_data-register) is in read-only mode using [`proc_uart_check_read_only`](tb_top_fpga.md#procedure-proc_uart_check_read_only)
    - Check register [`C_REG_SPI_TX_CONTROL`](../regblock/regblock.md#spi_tx_control-register) is in read-write mode by
    writing `not C_REG_SPI_TX_CONTROL.data` and that written value equals to `0x01FF` using [`proc_uart_check_read_write`](tb_top_fpga.md#procedure-proc_uart_check_read_write)
    - Pop data from SPI model and check it is equals to `not C_REG_SPI_TX_CONTROL.data[7:0]` with `check_equal`

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
