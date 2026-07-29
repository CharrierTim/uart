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
-- @version 1.1
-- @brief   Package for the SPI master testbench
-- @author  Timothee Charrier
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      27/11/2025  Timothee Charrier   Initial release
-- 1.1      29/07/2026  Timothee Charrier   Move `proc_check_time_in_range` to a common package
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;

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

end package TB_SPI_MASTER_PKG;
