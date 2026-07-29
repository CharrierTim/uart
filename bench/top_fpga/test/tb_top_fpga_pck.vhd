-- =====================================================================================================================
--  MIT License
--
--  Copyright (c) 2026 Timothee Charrier
--
--  Permission is hereby granted, free of charge, to any person obtaining a copy
--  of this software and associated documentation files (the "Software"), to deal
--  in the Software without restriction, including without limitation the rights
--  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--  copies of the Software, and to permit persons to whom the Software is
--  furnished to do so, subject to the following conditions:
--
--  The above copyright notice and this permission notice shall be included in all
--  copies or substantial portions of the Software.
--
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--  SOFTWARE.
-- =====================================================================================================================
-- @project uart
-- @file    tb_top_fpga_pck.vhd
-- @version 2.3
-- @brief   Package for the Top-Level testbench
-- @author  Timothee Charrier
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      01/12/2025  Timothee Charrier   Initial release
-- 2.0      12/01/2026  Timothee Charrier   Add VGA horizontal and vertical timings constants
-- 2.1      17/04/2026  Timothee Charrier   Add VGA test vectors and procedure to check VGA outputs
-- 2.2      23/05/2026  Timothee Charrier   Update register related definitions to 32 bits
-- 2.3      29/07/2026  Timothee Charrier   Add common package for register map
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.math_real.all;

library lib_rtl;
    use lib_rtl.regblock_pkg.all;

library lib_bench;
    use lib_bench.spi_pkg.all;
    use lib_bench.tb_reg_map_pkg.all;

library vunit_lib;
    context vunit_lib.vunit_context;
    context vunit_lib.com_context;
    use vunit_lib.stream_slave_pkg.all;

-- =====================================================================================================================
-- PACKAGE
-- =====================================================================================================================

package TB_TOP_FPGA_PKG is

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- Clock period for the testbench
    constant C_FREQ_HZ                    : positive := 100_000_000;
    constant C_CLK_PERIOD                 : time     := 1 sec / C_FREQ_HZ;

    -- DUT generics
    constant C_GIT_ID                     : std_logic_vector(32 - 1 downto 0) := C_REG_GIT_HASH.data;
    constant C_GIT_STATUS                 : std_logic                         := C_REG_GIT_STATUS.data(0);
    constant C_FPGA_ID                    : std_logic_vector(32 - 1 downto 0) := C_REG_FPGA_ID.data;

    -- UART model constants
    constant C_UART_BAUD_RATE_BPS         : positive := 115_200;
    constant C_UART_BIT_TIME              : time     := 1 sec / C_UART_BAUD_RATE_BPS;
    constant C_UART_BIT_TIME_ACCURACY     : time     := 0.01 * C_UART_BIT_TIME;
    constant C_UART_WRITE_NB_BITS         : positive := 10 * 12; -- 10 bits , 12 chars in total
    constant C_UART_WRITE_CMD_TIME        : time     := C_UART_BIT_TIME * C_UART_WRITE_NB_BITS;
    constant C_UART_READ_NB_BITS          : positive := 10 * 13; -- 10 bits , 13 chars in total
    constant C_UART_READ_CMD_TIME         : time     := C_UART_BIT_TIME * C_UART_READ_NB_BITS;

    -- SPI
    constant C_SPI_FREQ_HZ                : positive  := 1_000_000;
    constant C_SPI_BIT_TIME               : time      := 1 sec / C_SPI_FREQ_HZ;
    constant C_SPI_BIT_TIME_ACCURACY      : time      := 0.01 * C_SPI_BIT_TIME;
    constant C_SPI_NB_DATA_BITS           : positive  := 8;
    constant C_SPI_TRANSACTION_TIME       : time      := (C_SPI_NB_DATA_BITS + 2) * C_SPI_BIT_TIME;
    constant C_SPI_CLK_POLARITY           : std_logic := '0';
    constant C_SPI_CLK_PHASE              : std_logic := '0';

    constant C_SLAVE_SPI                  : spi_slave_t    := new_spi_slave(
            cpol_mode => C_SPI_CLK_POLARITY,
            cpha_mode => C_SPI_CLK_PHASE
        );
    constant C_SLAVE_STREAM               : stream_slave_t := as_stream(C_SLAVE_SPI);

    --
    -- VGA
    --

    -- Horizontal characteristics
    constant C_H_VGA_PIXEL_FREQUENCY      : integer := 65_000_000;
    constant C_H_VGA_PIXEL_BIT_TIME       : time    := 1 sec / C_H_VGA_PIXEL_FREQUENCY;

    constant C_H_PIXELS                   : integer := 1024;
    constant C_H_FRONT_PORCH              : integer := 24;
    constant C_H_SYNC_PULSE               : integer := 136;
    constant C_H_BACK_PORCH               : integer := 160;
    constant C_H_HSYNC_HIGH               : integer := C_H_PIXELS + C_H_FRONT_PORCH + C_H_BACK_PORCH;
    constant C_H_WHOLE_LINE               : integer := C_H_SYNC_PULSE + C_H_HSYNC_HIGH;

    constant C_H_SYNC_PULSE_TIME          : time := C_H_SYNC_PULSE * C_H_VGA_PIXEL_BIT_TIME;
    constant C_H_SYNC_PULSE_TIME_ACCURACY : time := C_H_SYNC_PULSE * C_H_VGA_PIXEL_BIT_TIME * 0.01;
    constant C_H_HSYNC_HIGH_TIME          : time := C_H_HSYNC_HIGH * C_H_VGA_PIXEL_BIT_TIME;
    constant C_H_HSYNC_HIGH_TIME_ACCURACY : time := C_H_HSYNC_HIGH * C_H_VGA_PIXEL_BIT_TIME * 0.01;
    constant C_H_WHOLE_LINE_TIME          : time := C_H_SYNC_PULSE_TIME + C_H_HSYNC_HIGH_TIME;
    constant C_H_WHOLE_LINE_TIME_ACCURACY : time := C_H_SYNC_PULSE_TIME_ACCURACY + C_H_HSYNC_HIGH_TIME_ACCURACY;

    -- Vertical characteristics
    constant C_V_VGA_PIXEL_FREQUENCY      : integer := C_H_VGA_PIXEL_FREQUENCY / C_H_WHOLE_LINE;
    constant C_V_VGA_PIXEL_BIT_TIME       : time    := 1 sec / C_V_VGA_PIXEL_FREQUENCY;

    constant C_V_PIXELS                   : integer := 768;
    constant C_V_FRONT_PORCH              : integer := 3;
    constant C_V_SYNC_PULSE               : integer := 6;
    constant C_V_BACK_PORCH               : integer := 29;
    constant C_V_HSYNC_HIGH               : integer := C_V_PIXELS + C_V_FRONT_PORCH + C_V_BACK_PORCH;
    constant C_V_WHOLE_LINE               : integer := C_V_SYNC_PULSE + C_V_HSYNC_HIGH;

    constant C_V_SYNC_PULSE_TIME          : time := C_V_SYNC_PULSE * C_V_VGA_PIXEL_BIT_TIME;
    constant C_V_SYNC_PULSE_TIME_ACCURACY : time := C_V_SYNC_PULSE * C_V_VGA_PIXEL_BIT_TIME * 0.01;
    constant C_V_HSYNC_HIGH_TIME          : time := C_V_HSYNC_HIGH * C_V_VGA_PIXEL_BIT_TIME;
    constant C_V_HSYNC_HIGH_TIME_ACCURACY : time := C_V_HSYNC_HIGH * C_V_VGA_PIXEL_BIT_TIME * 0.01;
    constant C_V_WHOLE_LINE_TIME          : time := C_V_SYNC_PULSE_TIME + C_V_HSYNC_HIGH_TIME;
    constant C_V_WHOLE_LINE_TIME_ACCURACY : time := C_V_SYNC_PULSE_TIME_ACCURACY + C_V_HSYNC_HIGH_TIME_ACCURACY;

    constant C_VGA_VECTOR_TEST_1          : std_logic_vector(12 - 1 downto 0) := x"ABC";
    constant C_VGA_VECTOR_TEST_2          : std_logic_vector(12 - 1 downto 0) := x"123";
    constant C_VGA_VECTOR_TEST_3          : std_logic_vector(12 - 1 downto 0) := x"F0F";

end package TB_TOP_FPGA_PKG;
