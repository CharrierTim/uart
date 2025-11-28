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
-- @file    regfile_pkg.vhd
-- @version 1.0
-- @brief   Package containing the registers addresses and value at reset
-- @author  Timothee Charrier
-- @date    20/10/2025
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;

-- =====================================================================================================================
-- PACKAGE
-- =====================================================================================================================

package REGFILE_PKG is

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- Registers addresses
    constant C_REG_GIT_ID_MSB_ADDR : std_logic_vector( 8 - 1 downto 0) := 8x"00"; -- 0x00
    constant C_REG_GIT_ID_LSB_ADDR : std_logic_vector( 8 - 1 downto 0) := 8x"01"; -- 0x01
    constant C_REG_12_ADDR         : std_logic_vector( 8 - 1 downto 0) := 8x"02"; -- 0x02
    constant C_REG_34_ADDR         : std_logic_vector( 8 - 1 downto 0) := 8x"03"; -- 0x03
    constant C_REG_56_ADDR         : std_logic_vector( 8 - 1 downto 0) := 8x"04"; -- 0x04
    constant C_REG_78_ADDR         : std_logic_vector( 8 - 1 downto 0) := 8x"05"; -- 0x05
    constant C_REG_SPI_ADDR        : std_logic_vector( 8 - 1 downto 0) := 8x"06"; -- 0x06
    constant C_REG_9A_ADDR         : std_logic_vector( 8 - 1 downto 0) := 8x"AB"; -- 0xAB
    constant C_REG_CD_ADDR         : std_logic_vector( 8 - 1 downto 0) := 8x"AC"; -- 0xAC
    constant C_REG_SWITCHES_ADDR   : std_logic_vector( 8 - 1 downto 0) := 8x"B1"; -- 0xB1
    constant C_REG_EF_ADDR         : std_logic_vector( 8 - 1 downto 0) := 8x"DC"; -- 0xDC
    constant C_REG_LED_ADDR        : std_logic_vector( 8 - 1 downto 0) := 8x"EF"; -- 0xEF
    constant C_REG_16_BITS_ADDR    : std_logic_vector( 8 - 1 downto 0) := 8x"FF"; -- 0xFF

    -- Read-only registers
    constant C_REG_12_DATA         : std_logic_vector(16 - 1 downto 0) := 16x"1212";
    constant C_REG_34_DATA         : std_logic_vector(16 - 1 downto 0) := 16x"3434";
    constant C_REG_56_DATA         : std_logic_vector(16 - 1 downto 0) := 16x"5656";
    constant C_REG_78_DATA         : std_logic_vector(16 - 1 downto 0) := 16x"7878";
    constant C_REG_9A_DATA         : std_logic_vector(16 - 1 downto 0) := 16x"9A9A";
    constant C_REG_CD_DATA         : std_logic_vector(16 - 1 downto 0) := 16x"CDCD";
    constant C_REG_EF_DATA         : std_logic_vector(16 - 1 downto 0) := 16x"EFEF";

    -- Read-Write registers value at reset
    constant C_REG_SPI_RST         : std_logic_vector( 9 - 1 downto 0) := 9x"0";
    constant C_REG_LED_RST         : std_logic                         := '1';
    constant C_REG_16_BITS_RST     : std_logic_vector(16 - 1 downto 0) := x"0000";

    -- Specific values for undefined registers
    constant C_REG_DEAD            : std_logic_vector(16 - 1 downto 0) := x"DEAD";

end package REGFILE_PKG;
