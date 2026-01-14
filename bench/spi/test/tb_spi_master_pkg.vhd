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
-- @file    tb_spi_master_pkg.vhd
-- @version 1.0
-- @brief   Package for the SPI master testbench
-- @author  Timothee Charrier
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      27/11/2025  Timothee Charrier   Initial release
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.math_real.all;

library vunit_lib;
    context vunit_lib.vunit_context;

-- =====================================================================================================================
-- PACKAGE
-- =====================================================================================================================

package TB_SPI_MASTER_PKG is

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- Clock configuration
    constant C_CLK_FREQ_HZ          : positive := 50_000_000;
    constant C_CLK_PERIOD           : time     := 1 sec / C_CLK_FREQ_HZ;

    -- DUT generics
    constant C_SPI_FREQ_HZ          : positive := 1_000_000;
    constant C_NB_DATA_BITS         : positive := 8;

    -- SPI constants
    constant C_BIT_TIME             : time := 1 sec / C_SPI_FREQ_HZ;
    constant C_BIT_TIME_ACCURACY    : time := 0.01 * C_BIT_TIME;
    constant C_SPI_TRANSACTION_TIME : time := (C_NB_DATA_BITS + 2) * C_BIT_TIME;

    -- =================================================================================================================
    -- PROCEDURES
    -- =================================================================================================================

    procedure proc_check_time_in_range (
        time_to_check : time;
        expected_time : time;
        accuracy      : time;
        message       : string := ""
    );

end package TB_SPI_MASTER_PKG;

package body TB_SPI_MASTER_PKG is

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
