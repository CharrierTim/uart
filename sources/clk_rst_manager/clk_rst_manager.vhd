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
-- @file    clk_rst_manager.vhd
-- @version 1.1
-- @brief   Module that manages the clock and reset signals.
--          Uses a PLL to generate the clocks, and for each clock domain, generates a positive asynchronous reset signal
--          that guarantee synchronous de-assertion of the reset.
-- @author  Timothee Charrier
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      02/08/2026  Timothee Charrier   Initial release
-- 1.1      26/09/2026  Timothee Charrier   Add a bad address counter to trigger a reset request if the counter exceeds
--                                          a threshold and the reset request is enabled
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library olo;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity CLK_RST_MANAGER is
    generic (
        G_BAD_ADDRESS_COUNTER_WIDTH : positive  := 32;
        G_RST_PULSE_CYCLES          : positive  := 3;
        G_RST_POLARITY              : std_logic := '1';
        G_ASYNC_RST_OUTPUT          : boolean   := false;
        G_RESYNC_NB_STAGES          : positive  := 3
    );
    port (
        -- Input clock and reset from the pads
        PAD_I_CLK                : in    std_logic;
        PAD_I_ARST_P             : in    std_logic;

        -- For alarms generation
        I_BAD_ADDRESS_RST_REQ_EN : in    std_logic;
        I_BAD_ADDRESS_COUNTER    : in    std_logic_vector(G_BAD_ADDRESS_COUNTER_WIDTH - 1 downto 0);
        I_MAX_BAD_ADDRESS_COUNT  : in    std_logic_vector(8 - 1 downto 0);

        -- Output clocks and resets
        O_INTERNAL_CLK           : out   std_logic;
        O_INTERNAL_ARST_P        : out   std_logic;

        O_VGA_CLK                : out   std_logic;
        O_VGA_ARST_P             : out   std_logic
    );
end entity CLK_RST_MANAGER;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================

architecture CLK_RST_MANAGER_ARCH of CLK_RST_MANAGER is

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    signal internal_clk        : std_logic;
    signal vga_clk             : std_logic;
    signal pll_locked          : std_logic;
    signal intermediate_arst_p : std_logic;
    signal internal_sys_arst_p : std_logic;
    signal internal_vga_arst_p : std_logic;
    signal bad_address_rst_req : std_logic;

    -- =================================================================================================================
    -- COMPONENT DECLARATIONS
    -- =================================================================================================================

    -- vsg_off
    component clk_wiz_0 is
        port (
            CLK_OUT1 : out   std_logic;
            CLK_OUT2 : out   std_logic;
            RESET    : in    std_logic;
            LOCKED   : out   std_logic;
            CLK_IN1  : in    std_logic
        );
    end component;
    -- vsg_on

begin

    -- =================================================================================================================
    -- PLL
    -- =================================================================================================================

    inst_pll : component clk_wiz_0
        port map (
            clk_out1 => internal_clk,
            clk_out2 => vga_clk,
            reset    => PAD_I_ARST_P,
            locked   => pll_locked,
            clk_in1  => PAD_I_CLK
        );

    -- =================================================================================================================
    -- ALARMS GENERATION
    --
    --  - If more than G_MAX_BAD_ADDRESS_COUNT bad address transactions are detected, and if the reset request is
    --    enabled, then a reset request is generated.
    -- =================================================================================================================

    bad_address_rst_req <= '1' when (
                                        unsigned(I_BAD_ADDRESS_COUNTER) >= unsigned(I_MAX_BAD_ADDRESS_COUNT)
                                        and
                                        I_BAD_ADDRESS_RST_REQ_EN = '1'
                                    ) else
                           '0';

    -- =================================================================================================================
    -- RESET GENERATION AND SYNCHRONIZATION
    -- =================================================================================================================

    -- Toggle reset from BTN or when PLL is unlocked
    intermediate_arst_p <= PAD_I_ARST_P or (not pll_locked) or bad_address_rst_req;

    -- System clock domain positive reset generation
    inst_olo_base_sys_reset_gen : entity olo.olo_base_reset_gen
        generic map (
            RSTPULSECYCLES_G   => G_RST_PULSE_CYCLES, -- Minimum duration of the reset pulse in clock cycles
            RSTINPOLARITY_G    => G_RST_POLARITY,     -- Polarity of 'RstIn'
            ASYNCRESETOUTPUT_G => G_ASYNC_RST_OUTPUT, -- Asserted synchronously
            SYNCSTAGES_G       => G_RESYNC_NB_STAGES  -- Number of synchronization stages
        )
        port map (
            Clk    => internal_clk,
            RstOut => internal_sys_arst_p,
            RstIn  => intermediate_arst_p
        );

    -- VGA clock domain positive reset generation
    inst_olo_base_vga_reset_gen : entity olo.olo_base_reset_gen
        generic map (
            RSTPULSECYCLES_G   => G_RST_PULSE_CYCLES, -- Minimum duration of the reset pulse in clock cycles
            RSTINPOLARITY_G    => G_RST_POLARITY,     -- Polarity of 'RstIn'
            ASYNCRESETOUTPUT_G => G_ASYNC_RST_OUTPUT, -- Asserted synchronously
            SYNCSTAGES_G       => G_RESYNC_NB_STAGES  -- Number of synchronization stages
        )
        port map (
            Clk    => vga_clk,
            RstOut => internal_vga_arst_p,
            RstIn  => intermediate_arst_p
        );

    -- =================================================================================================================
    -- OUTPUT ASSIGNMENTS
    -- =================================================================================================================

    O_INTERNAL_CLK    <= internal_clk;
    O_INTERNAL_ARST_P <= internal_sys_arst_p;

    O_VGA_CLK         <= vga_clk;
    O_VGA_ARST_P      <= internal_vga_arst_p;

end architecture CLK_RST_MANAGER_ARCH;
