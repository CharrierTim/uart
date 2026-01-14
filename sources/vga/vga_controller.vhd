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
-- @file    vga_controller.vhd
-- @version 2.0
-- @brief   VGA controller
-- @author  Timothee Charrier
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      16/12/2025  Timothee Charrier   Initial release
-- 1.1      05/01/2026  Timothee Charrier   Minor style updates
-- 1.2      09/01/2026  Timothee Charrier   The module now handle clock domain crossing of manual color inputs.
-- 2.0      13/01/2026  Timothee Charrier   Convert reset signal from active-low to active-high
-- =====================================================================================================================

library ieee;
    use ieee. std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library olo;

library lib_rtl;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity VGA_CONTROLLER is
    generic (
        -- Horizontal timings (default: 640x480@60Hz)
        G_H_PIXELS      : positive := 640;
        G_H_FRONT_PORCH : positive := 16;
        G_H_SYNC_PULSE  : positive := 96;
        G_H_BACK_PORCH  : positive := 48;

        -- Vertical timings (default: 640x480@60Hz)
        G_V_PIXELS      : positive := 480;
        G_V_FRONT_PORCH : positive := 10;
        G_V_SYNC_PULSE  : positive := 2;
        G_V_BACK_PORCH  : positive := 33
    );
    port (
        -- System clock domain
        CLK_SYS         : in    std_logic;
        RST_SYS_P       : in    std_logic;
        I_MANUAL_COLORS : in    std_logic_vector(12 - 1 downto 0);

        -- VGA clock domain
        CLK_VGA         : in    std_logic;
        RST_VGA_P       : in    std_logic;
        O_HSYNC         : out   std_logic;
        O_VSYNC         : out   std_logic;
        O_RED           : out   std_logic_vector( 4 - 1 downto 0);
        O_GREEN         : out   std_logic_vector( 4 - 1 downto 0);
        O_BLUE          : out   std_logic_vector( 4 - 1 downto 0);
        O_H_POSITION    : out   std_logic_vector(16 - 1 downto 0);
        O_V_POSITION    : out   std_logic_vector(16 - 1 downto 0);
        O_ACTIVE        : out   std_logic
    );
end entity VGA_CONTROLLER;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================

architecture VGA_CONTROLLER_ARCH of VGA_CONTROLLER is

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- Total horizontal pixels
    constant C_HORIZONTAL_TOTAL_PIXELS : positive :=
    (
        G_H_PIXELS      +
        G_H_FRONT_PORCH +
        G_H_SYNC_PULSE  +
        G_H_BACK_PORCH
    );

    -- Total vertical pixels
    constant C_VERTICAL_TOTAL_PIXELS   : positive :=
    (
        G_V_PIXELS      +
        G_V_FRONT_PORCH +
        G_V_SYNC_PULSE  +
        G_V_BACK_PORCH
    );

    --
    -- VGA horizontal and vertical active start and stop
    --

    constant C_HORIZONTAL_ACTIVE_START : positive :=
    (
        G_H_SYNC_PULSE +
        G_H_BACK_PORCH
    );

    constant C_HORIZONTAL_ACTIVE_STOP  : positive :=
    (
        C_HORIZONTAL_ACTIVE_START +
        G_H_PIXELS
    );

    constant C_VERTICAL_ACTIVE_START   : positive :=
    (
        G_V_SYNC_PULSE +
        G_V_BACK_PORCH
    );

    constant C_VERTICAL_ACTIVE_STOP    : positive :=
    (
        C_VERTICAL_ACTIVE_START +
        G_V_PIXELS
    );

    -- Counter width
    constant C_HORIZONTAL_COUNT_WIDTH  : positive := positive(ceil(log2(real(C_HORIZONTAL_TOTAL_PIXELS))));
    constant C_VERTICAL_COUNT_WIDTH    : positive := positive(ceil(log2(real(C_VERTICAL_TOTAL_PIXELS))));

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- Clock domain crossing for input colors
    signal manual_colors_resync        : std_logic_vector(I_MANUAL_COLORS'range);

    -- Counters
    signal horizontal_count            : unsigned(C_HORIZONTAL_COUNT_WIDTH - 1 downto 0);
    signal vertical_count              : unsigned(C_VERTICAL_COUNT_WIDTH - 1 downto 0);

    -- VGA signals
    signal active_region               : std_logic;

    -- Position signals
    signal h_position                  : unsigned(C_HORIZONTAL_COUNT_WIDTH - 1 downto 0);
    signal v_position                  : unsigned(C_VERTICAL_COUNT_WIDTH - 1 downto 0);

begin

    -- =================================================================================================================
    -- CLOCK DOMAIN CROSSING FOR INPUT COLORS
    -- =================================================================================================================

    inst_olo_base_cc_status : entity olo.olo_base_cc_status
        generic map (
            WIDTH_G      => manual_colors_resync'length,
            SYNCSTAGES_G => 2
        )
        port map (
            In_Clk     => CLK_SYS,
            In_RstIn   => RST_SYS_P,
            In_RstOut  => open,
            In_Data    => I_MANUAL_COLORS,
            Out_Clk    => CLK_VGA,
            Out_RstIn  => RST_VGA_P,
            Out_RstOut => open,
            Out_Data   => manual_colors_resync
        );

    -- =================================================================================================================
    -- HORIZONTAL AND VERTICAL COUNTERS
    -- =================================================================================================================

    p_counters : process (CLK_VGA, RST_VGA_P) is
    begin

        if (RST_VGA_P = '1') then

            horizontal_count <= (others => '0');
            vertical_count   <= (others => '0');

        elsif rising_edge(CLK_VGA) then

            -- Horizontal counter
            if (horizontal_count >= C_HORIZONTAL_TOTAL_PIXELS - 1) then

                horizontal_count <= (others => '0');

                -- Vertical counter
                if (vertical_count >= C_VERTICAL_TOTAL_PIXELS - 1) then
                    vertical_count <= (others => '0');
                else
                    vertical_count <= vertical_count + 1;
                end if;

            else
                horizontal_count <= horizontal_count + 1;
            end if;

        end if;

    end process p_counters;

    -- =================================================================================================================
    -- SYNC AND ACTIVE REGION GENERATION
    -- =================================================================================================================

    active_region <= '1' when (
                                  (horizontal_count >= C_HORIZONTAL_ACTIVE_START) and
                                  (horizontal_count < C_HORIZONTAL_ACTIVE_STOP)   and
                                  (vertical_count >= C_VERTICAL_ACTIVE_START)     and
                                  (vertical_count < C_VERTICAL_ACTIVE_STOP)
                              ) else
                     '0';

    -- Calculate position within active region
    h_position <= horizontal_count - C_HORIZONTAL_ACTIVE_START when active_region = '1' else
                  (others => '0');
    v_position <= vertical_count - C_VERTICAL_ACTIVE_START when active_region = '1' else
                  (others => '0');

    -- =================================================================================================================
    -- OUTPUTS
    -- =================================================================================================================

    p_outputs : process (CLK_VGA, RST_VGA_P) is
    begin

        if (RST_VGA_P = '1') then

            O_HSYNC      <= '0';
            O_VSYNC      <= '0';
            O_ACTIVE     <= '0';

            O_RED        <= (others => '0');
            O_GREEN      <= (others => '0');
            O_BLUE       <= (others => '0');

            O_H_POSITION <= (others => '0');
            O_V_POSITION <= (others => '0');

        elsif rising_edge(CLK_VGA) then

            -- Apply horizontal and vertical sync
            O_HSYNC <= '1' when horizontal_count >= G_H_SYNC_PULSE else '0';
            O_VSYNC <= '1' when vertical_count >= G_V_SYNC_PULSE   else '0';

            -- Active region flag
            O_ACTIVE <= active_region;

            -- Color outputs with blanking
            O_RED   <= manual_colors_resync(11 downto 8) when active_region = '1' else (others => '0');
            O_GREEN <= manual_colors_resync( 7 downto 4) when active_region = '1' else (others => '0');
            O_BLUE  <= manual_colors_resync( 3 downto 0) when active_region = '1' else (others => '0');

            -- Position outputs
            O_H_POSITION <= std_logic_vector(resize(h_position, 16));
            O_V_POSITION <= std_logic_vector(resize(v_position, 16));

        end if;

    end process p_outputs;

end architecture VGA_CONTROLLER_ARCH;
