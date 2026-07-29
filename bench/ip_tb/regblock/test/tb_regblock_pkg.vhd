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
-- @version 1.1
-- @brief   Package for the regblock testbench
-- @author  Timothee Charrier
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      16/05/2026  Timothee Charrier   Initial release
-- 1.1      29/07/2026  Timothee Charrier   Move `proc_check_time_in_range` to a common package
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library lib_rtl;
    use lib_rtl.regblock_pkg.all;

library vunit_lib;
    context vunit_lib.vunit_context;

library lib_bench;
    use lib_bench.tb_reg_map_pkg.all;

-- =====================================================================================================================
-- PACKAGE
-- =====================================================================================================================

package TB_REGBLOCK_PKG is

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- Clock configuration
    constant C_CLK_FREQ_HZ    : positive := 50_000_000;
    constant C_CLK_PERIOD     : time     := 1 sec / C_CLK_FREQ_HZ;

    -- Min/Max out of range addresses for testing
    constant C_ADDR_BELOW_MIN : std_logic_vector(REGBLOCK_MIN_ADDR_WIDTH - 1 downto 0) := x"28";
    constant C_ADDR_ABOVE_MAX : std_logic_vector(REGBLOCK_MIN_ADDR_WIDTH - 1 downto 0) := x"F4";

end package TB_REGBLOCK_PKG;
