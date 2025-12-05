# Tescases description

## Testcase 01: `test_top_fpga_registers`

### Description

This testcase check the test registers.

### Steps

Reset the DUT
Wait for 100 us

#### Check default values

Check register [C_REG_GIT_ID_MSB](../regfile/regfile.md#reg_git_id_msb) default value after reset with procedure [proc_uart_check_default_value](tb_top_fpga.md#procedure-proc_uart_check_default_value)

Check register [C_REG_GIT_ID_LSB](../regfile/regfile.md#reg_git_id_lsb) default value after reset with procedure [proc_uart_check_default_value](tb_top_fpga.md#procedure-proc_uart_check_default_value)

Check register [C_REG_12](../regfile/regfile.md#reg_12) default value after reset with procedure [proc_uart_check_default_value](tb_top_fpga.md#procedure-proc_uart_check_default_value)

Check register [C_REG_34](../regfile/regfile.md#reg_34) default value after reset with procedure [proc_uart_check_default_value](tb_top_fpga.md#procedure-proc_uart_check_default_value)

Check register [C_REG_56](../regfile/regfile.md#reg_56) default value after reset with procedure [proc_uart_check_default_value](tb_top_fpga.md#procedure-proc_uart_check_default_value)

Check register [C_REG_78](../regfile/regfile.md#reg_78) default value after reset with procedure [proc_uart_check_default_value](tb_top_fpga.md#procedure-proc_uart_check_default_value)

Check register [C_REG_9A](../regfile/regfile.md#reg_9a) default value after reset with procedure [proc_uart_check_default_value](tb_top_fpga.md#procedure-proc_uart_check_default_value)

Check register [C_REG_CD](../regfile/regfile.md#reg_cd) default value after reset with procedure [proc_uart_check_default_value](tb_top_fpga.md#procedure-proc_uart_check_default_value)

Check register [C_REG_EF](../regfile/regfile.md#reg_ef) default value after reset with procedure [proc_uart_check_default_value](tb_top_fpga.md#procedure-proc_uart_check_default_value)

Check register [C_REG_16_BITS](../regfile/regfile.md#reg_16_bits) default value after reset with procedure [proc_uart_check_default_value](tb_top_fpga.md#procedure-proc_uart_check_default_value)

Check register C_REG_DEAD default value after reset with procedure [proc_uart_check_default_value](tb_top_fpga.md#procedure-proc_uart_check_default_value)

#### Check read-only registers behaviour

Check register [C_REG_GIT_ID_MSB](../regfile/regfile.md#reg_git_id_msb) is in read-only mode with [proc_uart_check_read_only](tb_top_fpga.md#procedure-proc_uart_check_read_only)

Check register [C_REG_GIT_ID_LSB](../regfile/regfile.md#reg_git_id_lsb) is in read-only mode with [proc_uart_check_read_only](tb_top_fpga.md#procedure-proc_uart_check_read_only)

Check register [C_REG_12](../regfile/regfile.md#reg_12) is in read-only mode with [proc_uart_check_read_only](tb_top_fpga.md#procedure-proc_uart_check_read_only)

Check register [C_REG_34](../regfile/regfile.md#reg_34) is in read-only mode with [proc_uart_check_read_only](tb_top_fpga.md#procedure-proc_uart_check_read_only)

Check register [C_REG_56](../regfile/regfile.md#reg_56) is in read-only mode with [proc_uart_check_read_only](tb_top_fpga.md#procedure-proc_uart_check_read_only)

Check register [C_REG_78](../regfile/regfile.md#reg_78) is in read-only mode with [proc_uart_check_read_only](tb_top_fpga.md#procedure-proc_uart_check_read_only)

Check register [C_REG_9A](../regfile/regfile.md#reg_9a) is in read-only mode with [proc_uart_check_read_only](tb_top_fpga.md#procedure-proc_uart_check_read_only)

Check register [C_REG_CD](../regfile/regfile.md#reg_cd) is in read-only mode with [proc_uart_check_read_only](tb_top_fpga.md#procedure-proc_uart_check_read_only)

Check register [C_REG_EF](../regfile/regfile.md#reg_ef) is in read-only mode with [proc_uart_check_read_only](tb_top_fpga.md#procedure-proc_uart_check_read_only)

Check register C_REG_DEAD is in read-only mode with [proc_uart_check_read_only](tb_top_fpga.md#procedure-proc_uart_check_read_only)

#### Check read-write registers behaviour

Check [C_REG_16_BITS](../regfile/regfile.md#reg_16_bits) is in read-write mode by writing
`not C_REG_16_BITS.data` and checking returned value
is equal to `not C_REG_16_BITS.data` with procedure [proc_uart_check_read_only](tb_top_fpga.md#procedure-proc_uart_check_read_only)

(Write some data to C_REG_16_BITS)

Write register [C_REG_16_BITS](../regfile/regfile.md#reg_16_bits) with data 0xABCD with procedure [proc_uart_write](tb_top_fpga.md#procedure-proc_uart_write)

Read register [C_REG_16_BITS](../regfile/regfile.md#reg_16_bits) and check that returned value is data 0xABCD with
procedure [proc_uart_read](tb_top_fpga.md#procedure-proc_uart_read)
