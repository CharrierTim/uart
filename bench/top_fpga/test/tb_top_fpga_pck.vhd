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
    constant C_REG_1_BIT      : t_reg := (addr => 8x"EF", data => 16x"0001", name => "C_REG_1_BIT");
    constant C_REG_16_BITS    : t_reg := (addr => 8x"FF", data => 16x"0000", name => "C_REG_16_BITS");
    constant C_REG_DEAD       : t_reg := (addr => 8x"CC", data => 16x"DEAD", name => "C_REG_DEAD");
    -- vsg_on

end package TB_TOP_FPGA_PKG;
