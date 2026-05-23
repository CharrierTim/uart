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
-- @file    tb_regblock_pkg.vhd
-- @version 1.0
-- @brief   Package for the regblock testbench
-- @author  Timothee Charrier
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      16/05/2026  Timothee Charrier   Initial release
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library lib_rtl;
    use lib_rtl.regblock_pkg.all;

library vunit_lib;
    context vunit_lib.vunit_context;

-- =====================================================================================================================
-- PACKAGE
-- =====================================================================================================================

package TB_REGBLOCK_PKG is

    -- =================================================================================================================
    -- RECORDS
    -- =================================================================================================================

    type t_reg is record
        name           : string;                                                 -- Name
        addr           : std_logic_vector(REGBLOCK_MIN_ADDR_WIDTH - 1 downto 0); -- Address
        data           : std_logic_vector(REGBLOCK_DATA_WIDTH - 1 downto 0);     -- Value at reset
        used_bits_mask : std_logic_vector(REGBLOCK_DATA_WIDTH - 1 downto 0);     -- Mask of bits that are unused
    end record t_reg;

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- Clock configuration
    constant C_CLK_FREQ_HZ             : positive := 50_000_000;
    constant C_CLK_PERIOD              : time     := 1 sec / C_CLK_FREQ_HZ;

    constant C_REG_GIT_HASH            : t_reg :=
    (
        name           => "GIT_HASH",
        addr           => 8x"00",
        data           => 32x"DEAD_BEEF",
        used_bits_mask => 32x"FFFF_FFFF"
    );

    constant C_REG_GIT_STATUS          : t_reg :=
    (
        name           => "GIT_STATUS",
        addr           => 8x"04",
        data           => 32x"0000_0001",
        used_bits_mask => 32x"0000_0001"
    );

    constant C_REG_FPGA_ID             : t_reg :=
    (
        name           => "FPGA_ID",
        addr           => 8x"08",
        data           => 32x"1234_5678",
        used_bits_mask => 32x"FFFF_FFFF"
    );

    constant C_REG_SPI_TX_CONTROL      : t_reg :=
    (
        name           => "SPI_TX_CONTROL",
        addr           => 8x"0C",
        data           => 32x"0000_0000",
        used_bits_mask => 32x"0000_00FF"
    );

    constant C_REG_SPI_RX_DATA         : t_reg :=
    (
        name           => "SPI_RX_DATA",
        addr           => 8x"10",
        data           => 32x"0000_0000",
        used_bits_mask => 32x"0000_00FF"
    );

    constant C_REG_VGA_COLOR           : t_reg :=
    (
        name           => "VGA_COLOR",
        addr           => 8x"14",
        data           => 32x"0000_00F0",
        used_bits_mask => 32x"0000_0FFF"
    );

    constant C_REG_SWITCH_STATUS       : t_reg :=
    (
        name           => "SWITCH_STATUS",
        addr           => 8x"18",
        data           => 32x"0000_0000",
        used_bits_mask => 32x"0000_0003"
    );

    constant C_REG_BAD_ADDRESS_COUNTER : t_reg :=
    (
        name           => "BAD_ADDRESS_COUNTER",
        addr           => 8x"1C",
        data           => 32x"0000_0000",
        used_bits_mask => 32x"FFFF_FFFF"
    );

    constant C_REG_TEST_REGISTER_1     : t_reg :=
    (
        name           => "TEST_REGISTER_1",
        addr           => 8x"F8",
        data           => 32x"0000_0000",
        used_bits_mask => 32x"FFFF_FFFF"
    );

    constant C_REG_TEST_REGISTER_2     : t_reg :=
    (
        name           => "TEST_REGISTER_2",
        addr           => 8x"FC",
        data           => 32x"0000_0000",
        used_bits_mask => 32x"FFFF_FFFF"
    );

    -- Min/Max out of range addresses for testing
    constant C_ADDR_BELOW_MIN          : std_logic_vector(REGBLOCK_MIN_ADDR_WIDTH - 1 downto 0) := x"20";
    constant C_ADDR_ABOVE_MAX          : std_logic_vector(REGBLOCK_MIN_ADDR_WIDTH - 1 downto 0) := x"F4";

    -- =================================================================================================================
    -- PROCEDURES
    -- =================================================================================================================

    procedure proc_check_time_in_range (
        time_to_check : time;
        expected_time : time;
        accuracy      : time;
        message       : string := ""
    );

end package TB_REGBLOCK_PKG;

package body TB_REGBLOCK_PKG is

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
