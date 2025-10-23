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
-- @date    22/10/2025
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.math_real.all;

library vunit_lib;
    context vunit_lib.vunit_context;

-- =====================================================================================================================
-- PACKAGE
-- =====================================================================================================================

package tb_top_fpga_pkg is

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

    -- vsg_off
    constant C_REG_GIT_ID_MSB : t_reg := (addr => 8x"00", data => 16x"1234", name => "C_REG_GIT_ID_MSB");
    constant C_REG_GIT_ID_LSB : t_reg := (addr => 8x"01", data => 16x"5678", name => "C_REG_GIT_ID_LSB");
    constant C_REG_12         : t_reg := (addr => 8x"02", data => 16x"1212", name => "C_REG_12");
    constant C_REG_34         : t_reg := (addr => 8x"03", data => 16x"3434", name => "C_REG_34");
    constant C_REG_56         : t_reg := (addr => 8x"04", data => 16x"5656", name => "C_REG_56");
    constant C_REG_78         : t_reg := (addr => 8x"05", data => 16x"7878", name => "C_REG_78");
    constant C_REG_9A         : t_reg := (addr => 8x"AB", data => 16x"9A9A", name => "C_REG_9A");
    constant C_REG_CD         : t_reg := (addr => 8x"AC", data => 16x"CDCD", name => "C_REG_CD");
    constant C_REG_EF         : t_reg := (addr => 8x"DC", data => 16x"EFEF", name => "C_REG_EF");
    constant C_REG_SWITCHES   : t_reg := (addr => 8x"B1", data => 16x"0000", name => "C_REG_SWITCHES");
    constant C_REG_1_BIT      : t_reg := (addr => 8x"EF", data => 16x"0001", name => "C_REG_1_BIT");
    constant C_REG_16_BITS    : t_reg := (addr => 8x"FF", data => 16x"0000", name => "C_REG_16_BITS");
    constant C_REG_DEAD       : t_reg := (addr => 8x"CC", data => 16x"DEAD", name => "C_REG_DEAD");
    -- vsg_on

    -- =================================================================================================================
    -- PROCEDURES
    -- =================================================================================================================

    procedure proc_check_time_in_range (
        time_to_check : time;
        expected_time : time;
        accuracy      : time;
        message       : string := ""
    );

end package tb_top_fpga_pkg;

package body tb_top_fpga_pkg is

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
