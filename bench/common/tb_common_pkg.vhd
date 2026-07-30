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
-- @file    tb_common_pkg.vhd
-- @version 1.0
-- @brief   Common testbench utilities with reusable procedures and functions
-- @author  Timothee Charrier
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      30/07/2026  Timothee Charrier   Initial version, create a package for common testbench utilities
-- =====================================================================================================================

library ieee;
    use ieee.math_real.all;

library vunit_lib;
    context vunit_lib.vunit_context;

package TB_COMMON_PKG is

    procedure proc_check_time_in_range (
        time_to_check : time;
        expected_time : time;
        accuracy      : time;
        message       : string := ""
    );

end package TB_COMMON_PKG;

package body TB_COMMON_PKG is

    function func_format_time (
        time_to_format : time
    ) return string is
        variable v_time_value : real;
        variable v_rounded    : real;
    begin

        if (time_to_format >= 1 sec) then
            v_time_value := real(time_to_format / 1 fs) / 1.0e15;
            v_rounded    := round(v_time_value * 100.0) / 100.0;
            return real'image(v_rounded) & " sec";
        elsif (time_to_format >= 1 ms) then
            v_time_value := real(time_to_format / 1 fs) / 1.0e12;
            v_rounded    := round(v_time_value * 100.0) / 100.0;
            return real'image(v_rounded) & " ms";
        elsif (time_to_format >= 1 us) then
            v_time_value := real(time_to_format / 1 fs) / 1.0e9;
            v_rounded    := round(v_time_value * 100.0) / 100.0;
            return real'image(v_rounded) & " us";
        elsif (time_to_format >= 1 ns) then
            v_time_value := real(time_to_format / 1 fs) / 1.0e6;
            v_rounded    := round(v_time_value * 100.0) / 100.0;
            return real'image(v_rounded) & " ns";
        elsif (time_to_format >= 1 ps) then
            v_time_value := real(time_to_format / 1 fs) / 1.0e3;
            v_rounded    := round(v_time_value * 100.0) / 100.0;
            return real'image(v_rounded) & " ps";
        else
            return time'image(time_to_format);
        end if;

    end function func_format_time;

    function func_pad_left (
        str   : string;
        width : integer
    ) return string is
        variable v_result : string(1 to width) := (others => ' ');
    begin

        if (str'length >= width) then
            return str;
        end if;

        v_result(width - str'length + 1 to width) := str;
        return v_result;

    end function func_pad_left;

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
