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
-- @file    tb_reg_map_pkg.vhd
-- @version 1.0
-- @brief   Register map for testbench
-- @author  Timothee Charrier
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      28/11/2025  Timothee Charrier   Initial version, create a package for register map for testbench
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;

library lib_rtl;
    use lib_rtl.regblock_pkg.all;

package TB_REG_MAP_PKG is

    type t_reg is record
        name               : string;
        addr               : std_logic_vector(REGBLOCK_MIN_ADDR_WIDTH - 1 downto 0);
        data               : std_logic_vector(REGBLOCK_DATA_WIDTH - 1 downto 0);
        writable_bits_mask : std_logic_vector(REGBLOCK_DATA_WIDTH - 1 downto 0);
    end record t_reg;

    constant C_REG_GIT_HASH                : t_reg :=
    (
        name               => "GIT_HASH",
        addr               => 8x"00",
        data               => 32x"DEAD_BEEF",
        writable_bits_mask => 32x"FFFF_FFFF"
    );

    constant C_REG_GIT_STATUS              : t_reg :=
    (
        name               => "GIT_STATUS",
        addr               => 8x"04",
        data               => 32x"0000_0001",
        writable_bits_mask => 32x"0000_0001"
    );

    constant C_REG_FPGA_ID                 : t_reg :=
    (
        name               => "FPGA_ID",
        addr               => 8x"08",
        data               => 32x"1234_5678",
        writable_bits_mask => 32x"FFFF_FFFF"
    );

    constant C_REG_SPI_TX_CONTROL          : t_reg :=
    (
        name               => "SPI_TX_CONTROL",
        addr               => 8x"0C",
        data               => 32x"0000_0000",
        writable_bits_mask => 32x"0000_00FF"
    );

    constant C_REG_SPI_RX_DATA             : t_reg :=
    (
        name               => "SPI_RX_DATA",
        addr               => 8x"10",
        data               => 32x"0000_0000",
        writable_bits_mask => 32x"0000_00FF"
    );

    constant C_REG_VGA_COLOR_CONTROL       : t_reg :=
    (
        name               => "VGA_COLOR",
        addr               => 8x"14",
        data               => 32x"0000_00F0",
        writable_bits_mask => 32x"0000_0FFF"
    );

    constant C_REG_SWITCH_STATUS           : t_reg :=
    (
        name               => "SWITCH_STATUS",
        addr               => 8x"18",
        data               => 32x"0000_0000",
        writable_bits_mask => 32x"0000_0007"
    );

    constant C_REG_BAD_ADDRESS_COUNTER     : t_reg :=
    (
        name               => "BAD_ADDRESS_COUNTER",
        addr               => 8x"1C",
        data               => 32x"0000_0000",
        writable_bits_mask => 32x"FFFF_FFFF"
    );

    constant C_REG_START_BIT_ERROR_COUNTER : t_reg :=
    (
        name               => "START_BIT_ERROR_COUNTER",
        addr               => 8x"20",
        data               => 32x"0000_0000",
        writable_bits_mask => 32x"FFFF_FFFF"
    );

    constant C_REG_STOP_BIT_ERROR_COUNTER  : t_reg :=
    (
        name               => "STOP_BIT_ERROR_COUNTER",
        addr               => 8x"24",
        data               => 32x"0000_0000",
        writable_bits_mask => 32x"FFFF_FFFF"
    );

    constant C_REG_TEST_REGISTER_1         : t_reg :=
    (
        name               => "TEST_REGISTER_1",
        addr               => 8x"F8",
        data               => 32x"0000_0000",
        writable_bits_mask => 32x"FFFF_FFFF"
    );

    constant C_REG_TEST_REGISTER_2         : t_reg :=
    (
        name               => "TEST_REGISTER_2",
        addr               => 8x"FC",
        data               => 32x"0000_0000",
        writable_bits_mask => 32x"FFFF_FFFF"
    );

    constant C_REG_BAD_ADDR                : t_reg :=
    (
        name               => "REG_BAD_ADDR",
        addr               => 8x"98",
        data               => 32x"0000_0000",
        writable_bits_mask => 32x"FFFF_FFFF"
    );

end package TB_REG_MAP_PKG;
