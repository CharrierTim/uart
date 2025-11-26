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
-- @file    spi_master.vhd
-- @version 1.0
-- @brief   SPI master module.
--
--              +----------+-------+-----------------------------------------------------------------------+
--              | POLARITY | PHASE | Action                                                                |
--              +----------+-------+-----------------------------------------------------------------------+
--              | 0        | 0     | Data is output on the rising edge of SPICLK.                          |
--              |          |       | Input data is latched on the falling edge.                            |
--              +----------+-------+-----------------------------------------------------------------------+
--              | 0        | 1     | Data is output one half-cycle before the first rising edge of SPICLK  |
--              |          |       | and on subsequent falling edges.                                      |
--              |          |       | Input data is latched on the rising edge of SPICLK.                   |
--              +----------+-------+-----------------------------------------------------------------------+
--              | 1        | 0     | Data is output on the falling edge of SPICLK.                         |
--              |          |       | Input data is latched on the rising edge.                             |
--              +----------+-------+-----------------------------------------------------------------------+
--              | 1        | 1     | Data is output one half-cycle before the first falling edge of SPICLK |
--              |          |       | and on subsequent rising edges.                                       |
--              |          |       | Input data is latched on the falling edge of SPICLK.                  |
--              +----------+-------+-----------------------------------------------------------------------+
--
-- @author  Timothee Charrier
-- @date    24/11/2025
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity SPI_MASTER is
    generic (
        G_CLK_FREQ_HZ  : positive  := 50_000_000; -- Clock frequency in Hz
        G_SPI_FREQ_HZ  : positive  := 500_000;    -- SPI clock frequency in Hz
        G_NB_DATA_BITS : positive  := 8;          -- Number of data bits
        G_CLK_POLARITY : std_logic := '0';        -- SPI clock polarity
        G_CLK_PHASE    : std_logic := '1'         -- SPI clock phase
    );
    port (
        -- Clock and reset
        CLK             : in    std_logic;
        RST_N           : in    std_logic;
        -- SPI interface
        O_SCLK          : out   std_logic; -- Serial Clock
        O_MOSI          : out   std_logic; -- Master Out Slave In
        I_MISO          : in    std_logic; -- Master In Slave Out
        O_CS            : out   std_logic; -- Chip select
        -- Data interface
        I_TX_BYTE       : in    std_logic_vector(G_NB_DATA_BITS - 1 downto 0);
        I_TX_BYTE_VALID : in    std_logic;
        O_RX_BYTE       : out   std_logic_vector(G_NB_DATA_BITS - 1 downto 0);
        O_RX_BYTE_VALID : out   std_logic
    );
end entity SPI_MASTER;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================

architecture SPI_MASTER_ARCH of SPI_MASTER is

    -- =================================================================================================================
    -- TYPES
    -- =================================================================================================================

    type t_state is (
        STATE_IDLE
    );

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    constant C_HALF_PERIOD_CYCLES  : positive := G_CLK_FREQ_HZ / G_SPI_FREQ_HZ / 2;
    constant C_COUNTER_WIDTH       : positive := positive(ceil(log2(real(C_HALF_PERIOD_CYCLES))));

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- SPI clock generation
    signal spi_half_period_counter : unsigned(C_COUNTER_WIDTH - 1 downto 0);
    signal half_period_tick        : std_logic;
    signal core_clk                : std_logic;
    signal core_clk_en             : std_logic;
    signal core_clk_n              : std_logic;
    signal core_clk_n_en           : std_logic;
    signal spi_clk                 : std_logic;
    signal spi_enable_sampling     : std_logic;
    signal spi_enable_shifting     : std_logic;
    signal reg_o_sclk              : std_logic;

    -- FSM signals
    signal current_state           : t_state;
    signal next_state              : t_state;

begin

    -- =================================================================================================================
    -- CLOCK GENERATION
    -- =================================================================================================================
    -- This section implements the same clock generation scheme as the reference design:
    --      1. Generate 2x SPI base clock
    --      2. Generate the positive and negative core clock and clock enable
    --      3. Select appropriate clock based on G_CLK_POLARITY indicating clock polarity
    -- =================================================================================================================

    p_core_clock_gen : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            spi_half_period_counter <= (others => '0');
            half_period_tick        <= '0';
            core_clk                <= '0';
            core_clk_en             <= '0';
            core_clk_n              <= '1';
            core_clk_n_en           <= '0';

        elsif rising_edge(CLK) then

            -- Generate tick every half period of desired SPI clock
            if (spi_half_period_counter >= C_HALF_PERIOD_CYCLES - 1) then
                spi_half_period_counter <= (others => '0');
                half_period_tick        <= '1';
            else
                spi_half_period_counter <= spi_half_period_counter + 1;
                half_period_tick        <= '0';
            end if;

            -- Generate complementary clock signals and their enables
            if (half_period_tick = '1') then

                -- Swap the clock states
                core_clk   <= core_clk_n;
                core_clk_n <= not core_clk_n;

                -- Enable signals pulse when respective clock goes high
                core_clk_en   <= core_clk_n;
                core_clk_n_en <= not core_clk_n;
            else
                core_clk_en   <= '0';
                core_clk_n_en <= '0';
            end if;

        end if;

    end process p_core_clock_gen;

    -- =================================================================================================================
    -- SPI clock polarity
    -- =================================================================================================================

    gen_clk_polarity : if G_CLK_POLARITY = '0' generate
        spi_clk <= core_clk;
    else generate
        spi_clk <= core_clk_n;
    end generate gen_clk_polarity;

    -- =================================================================================================================
    -- Sampling and shifting on according leading/trailing edges
    -- =================================================================================================================

    gen_clk_phase : if G_CLK_PHASE = '0' generate
        spi_enable_sampling <= core_clk_n_en; -- Sample RX data on a falling edge
        spi_enable_shifting <= core_clk_en;   -- Shift  TX data on a rising edge
    else generate
        spi_enable_sampling <= core_clk_en;   -- Sample RX data on a rising edge
        spi_enable_shifting <= core_clk_n_en; -- Shift  TX data on a rising edge
    end generate gen_clk_phase;

    -- =================================================================================================================
    -- SPI output clock when active
    -- =================================================================================================================

    p_sclk : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            reg_o_sclk <= G_CLK_POLARITY;
            O_SCLK     <= G_CLK_POLARITY;

        elsif rising_edge(CLK) then

            if (current_state = STATE_IDLE) then -- TO-DO
                reg_o_sclk <= spi_clk;
            else
                reg_o_sclk <= G_CLK_POLARITY;
            end if;

            O_SCLK <= reg_o_sclk;

        end if;

    end process p_sclk;

end architecture SPI_MASTER_ARCH;
