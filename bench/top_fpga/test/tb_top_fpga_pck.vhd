-- =====================================================================================================================
--  MIT License
--
--  Copyright (c) 2025 Timothee Charrier
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
-- @version 1.0
-- @brief   Package for the Top-Level testbench
-- @author  Timothee Charrier
-- @date    01/12/2025
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      01/12/2025  Timothee Charrier   Initial release
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.math_real.all;

library lib_bench;
    use lib_bench.spi_pkg.all;

library vunit_lib;
    context vunit_lib.vunit_context;
    context vunit_lib.com_context;
    use vunit_lib.stream_slave_pkg.all;

-- =====================================================================================================================
-- PACKAGE
-- =====================================================================================================================

package TB_TOP_FPGA_PKG is

    -- =================================================================================================================
    -- TYPES
    -- =================================================================================================================

    type t_reg is record
        name : string;                            -- Name
        addr : std_logic_vector( 8 - 1 downto 0); -- Address
        data : std_logic_vector(16 - 1 downto 0); -- Value at reset
    end record t_reg;

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- Clock period for the testbench
    constant C_FREQ_HZ                : positive := 100_000_000;
    constant C_CLK_PERIOD             : time     := 1 sec / C_FREQ_HZ;

    -- DUT generics
    constant C_GIT_ID                 : std_logic_vector(32 - 1 downto 0) := x"12345678";

    -- UART model constants
    constant C_UART_BAUD_RATE_BPS     : positive := 115_200;
    constant C_UART_BIT_TIME          : time     := 1 sec / C_UART_BAUD_RATE_BPS;
    constant C_UART_BIT_TIME_ACCURACY : time     := 0.01 * C_UART_BIT_TIME;
    constant C_UART_WRITE_NB_BITS     : positive := 10 * 8; -- 10 bits , 8 chars in total
    constant C_UART_WRITE_CMD_TIME    : time     := C_UART_BIT_TIME * C_UART_WRITE_NB_BITS;
    constant C_UART_READ_NB_BITS      : positive := 10 * 9; -- 10 bits , 9 chars in total
    constant C_UART_READ_CMD_TIME     : time     := C_UART_BIT_TIME * C_UART_READ_NB_BITS;

    -- vsg_off
    constant C_REG_GIT_ID_MSB : t_reg := (addr => 8x"00", data => 16x"1234", name => "C_REG_GIT_ID_MSB");
    constant C_REG_GIT_ID_LSB : t_reg := (addr => 8x"01", data => 16x"5678", name => "C_REG_GIT_ID_LSB");
    constant C_REG_12         : t_reg := (addr => 8x"02", data => 16x"1212", name => "C_REG_12");
    constant C_REG_34         : t_reg := (addr => 8x"03", data => 16x"3434", name => "C_REG_34");
    constant C_REG_56         : t_reg := (addr => 8x"04", data => 16x"5656", name => "C_REG_56");
    constant C_REG_78         : t_reg := (addr => 8x"05", data => 16x"7878", name => "C_REG_78");
    constant C_REG_SPI_TX     : t_reg := (addr => 8x"06", data => 16x"0000", name => "C_REG_SPI_TX");
    constant C_REG_SPI_RX     : t_reg := (addr => 8x"07", data => 16x"0000", name => "C_REG_SPI_RX");
    constant C_REG_VGA_CTRL   : t_reg := (addr => 8x"08", data => 16x"0000", name => "C_REG_VGA_CTRL");
    constant C_REG_9A         : t_reg := (addr => 8x"AB", data => 16x"9A9A", name => "C_REG_9A");
    constant C_REG_CD         : t_reg := (addr => 8x"AC", data => 16x"CDCD", name => "C_REG_CD");
    constant C_REG_EF         : t_reg := (addr => 8x"DC", data => 16x"EFEF", name => "C_REG_EF");
    constant C_REG_SWITCHES   : t_reg := (addr => 8x"B1", data => 16x"0000", name => "C_REG_SWITCHES");
    constant C_REG_LED        : t_reg := (addr => 8x"EF", data => 16x"0001", name => "C_REG_LED");
    constant C_REG_16_BITS    : t_reg := (addr => 8x"FF", data => 16x"0000", name => "C_REG_16_BITS");
    constant C_REG_DEAD       : t_reg := (addr => 8x"CC", data => 16x"DEAD", name => "C_REG_DEAD");
    -- vsg_on

    -- SPI
    constant C_SPI_FREQ_HZ            : positive  := 1_000_000;
    constant C_SPI_BIT_TIME           : time      := 1 sec / C_SPI_FREQ_HZ;
    constant C_SPI_BIT_TIME_ACCURACY  : time      := 0.01 * C_SPI_BIT_TIME;
    constant C_SPI_NB_DATA_BITS       : positive  := 8;
    constant C_SPI_TRANSACTION_TIME   : time      := (C_SPI_NB_DATA_BITS + 2) * C_SPI_BIT_TIME;
    constant C_SPI_CLK_POLARITY       : std_logic := '0';
    constant C_SPI_CLK_PHASE          : std_logic := '0';

    constant C_SLAVE_SPI              : spi_slave_t    := new_spi_slave(
            cpol_mode => C_SPI_CLK_POLARITY,
            cpha_mode => C_SPI_CLK_PHASE
        );
    constant C_SLAVE_STREAM           : stream_slave_t := as_stream(C_SLAVE_SPI);

    -- =================================================================================================================
    -- PROCEDURES
    -- =================================================================================================================

    procedure proc_check_time_in_range (
        time_to_check : time;
        expected_time : time;
        accuracy      : time;
        message       : string := ""
    );

end package TB_TOP_FPGA_PKG;

package body TB_TOP_FPGA_PKG is

    -- =================================================================================================================
    -- FUNCTIONS
    -- =================================================================================================================

    function func_format_time (
        time_to_format : time
    ) return string is
        variable v_time_value : real;
        variable v_rounded    : real;
    begin

        -- Choose unit based on magnitude (show sec/ms/us/ns/ps/fs)

        -- Seconds
        if (time_to_format >= 1 sec) then
            v_time_value := real(time_to_format / 1 fs) / 1.0e15;
            v_rounded    := round(v_time_value * 100.0) / 100.0;  -- Round to 2 decimal places
            return real'image(v_rounded) & " sec";

        -- Milliseconds
        elsif (time_to_format >= 1 ms) then
            v_time_value := real(time_to_format / 1 fs) / 1.0e12;
            v_rounded    := round(v_time_value * 100.0) / 100.0;  -- Round to 2 decimal places
            return real'image(v_rounded) & " ms";

        -- Microseconds
        elsif (time_to_format >= 1 us) then
            v_time_value := real(time_to_format / 1 fs) / 1.0e9;
            v_rounded    := round(v_time_value * 100.0) / 100.0;  -- Round to 2 decimal places
            return real'image(v_rounded) & " us";

        -- Nanoseconds
        elsif (time_to_format >= 1 ns) then
            v_time_value := real(time_to_format / 1 fs) / 1.0e6;
            v_rounded    := round(v_time_value * 100.0) / 100.0;  -- Round to 2 decimal places
            return real'image(v_rounded) & " ns";

        -- Picoseconds
        elsif (time_to_format >= 1 ps) then
            v_time_value := real(time_to_format / 1 fs) / 1.0e3;
            v_rounded    := round(v_time_value * 100.0) / 100.0;  -- Round to 2 decimal places
            return real'image(v_rounded) & " ps";

        -- Femtoseconds
        else
            return time'image(time_to_format);
        end if;

    end function func_format_time;

    -- Simple padding function

    function func_pad_left (
        str   : string;
        width : integer
    ) return string is
        variable v_result     : string(1 to width) := (others => ' ');
        variable v_actual_len : integer            := str'length;
        variable v_padding    : integer;
    begin

        if (v_actual_len >= width) then
            return str;
        else
            v_padding                        := width - v_actual_len;
            v_result(v_padding + 1 to width) := str;
            return v_result;
        end if;

    end function func_pad_left;

    -- =================================================================================================================
    -- PROCEDURE
    -- =================================================================================================================

    procedure proc_check_time_in_range (
        time_to_check : time;
        expected_time : time;
        accuracy      : time;
        message       : string := ""
    ) is
    begin

        check(
            abs(time_to_check - expected_time) <= accuracy,
            message &
            "Time: "       & func_pad_left(func_format_time(time_to_check), 12) &
            "  |  Range: " & func_pad_left(func_format_time(expected_time), 12) &
            " +/- "        & func_pad_left(func_format_time(accuracy), 10));

    end procedure proc_check_time_in_range;

end package body;
