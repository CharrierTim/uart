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
-- @file    pll_fast_sim.vhd
-- @version 1.0
-- @brief   A simple PLL model for fast simulation. Indented only for tesbenches without the slow unisim PLL model and
--          for quick debug.
-- @author  Timothee Charrier
-- @date    24/05/2026
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;

-- vsg_off
entity clk_wiz_0 is
    port (
        CLK_OUT1 : out   std_logic := '0';
        CLK_OUT2 : out   std_logic := '0';
        RESET    : in    std_logic;
        LOCKED   : out   std_logic := '0';
        CLK_IN1  : in    std_logic
    );
end entity clk_wiz_0;

architecture rtl of clk_wiz_0 is

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    constant C_CLK_OUT1_PERIOD : time := 20 ns;        -- 50 MHz
    constant C_CLK_OUT2_PERIOD : time := 1 sec / 65e6; -- 65 MHz

begin

    -- =================================================================================================================
    -- CLOCK OUTPUTS
    -- =================================================================================================================

    CLK_OUT1 <= not CLK_OUT1 after C_CLK_OUT1_PERIOD / 2 when RESET = '0' else
                '0';
    CLK_OUT2 <= not CLK_OUT2 after C_CLK_OUT2_PERIOD / 2 when RESET = '0' else
                '0';

    -- =================================================================================================================
    -- LOCKED SIGNAL
    -- =================================================================================================================

    LOCKED <= '1' after 100 ns when RESET = '0' else
              '0';

end architecture RTL;
-- vsg_on
