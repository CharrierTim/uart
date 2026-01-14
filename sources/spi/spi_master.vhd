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
-- @file    spi_master.vhd
-- @version 2.0
-- @brief   SPI master module supporting all four SPI modes (0-3).
--
--          SPI Mode Configuration (adapted from Texas Instruments KeyStone Architecture Serial Peripheral Interface
--          (SPI) User Guide, SPRUGP2A, March 2012):
--
--          +------+----------+-------+-----------------------------------------------------------------------+
--          | MODE | POLARITY | PHASE | Description                                                           |
--          +------+----------+-------+-----------------------------------------------------------------------+
--          | 0    | 0        | 0     | Data is output on the rising edge of SCLK.                            |
--          |      |          |       | Input data is latched on the falling edge.                            |
--          +------+----------+-------+-----------------------------------------------------------------------+
--          | 1    | 0        | 1     | Data is output one half-cycle before the first rising edge of SCLK    |
--          |      |          |       | and on subsequent falling edges.                                      |
--          |      |          |       | Input data is latched on the rising edge of SCLK.                     |
--          +------+----------+-------+-----------------------------------------------------------------------+
--          | 2    | 1        | 0     | Data is output on the falling edge of SCLK.                           |
--          |      |          |       | Input data is latched on the rising edge.                             |
--          +------+----------+-------+-----------------------------------------------------------------------+
--          | 3    | 1        | 1     | Data is output one half-cycle before the first falling edge of SCLK   |
--          |      |          |       | and on subsequent rising edges.                                       |
--          |      |          |       | Input data is latched on the falling edge of SCLK.                    |
--          +------+----------+-------+-----------------------------------------------------------------------+
--
-- @author  Timothee Charrier
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      24/11/2025  Timothee Charrier   Initial release
-- 1.1      10/12/2025  Timothee Charrier   Naming conventions update
-- 2.0      12/01/2026  Timothee Charrier   Convert reset signal from active-low to active-high
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
        G_CLK_PHASE    : std_logic := '0'         -- SPI clock phase
    );
    port (
        -- Clock and reset
        CLK             : in    std_logic;
        RST_P           : in    std_logic;
        -- SPI interface
        O_SCLK          : out   std_logic; -- Serial Clock
        O_MOSI          : out   std_logic; -- Master Out Slave In
        I_MISO          : in    std_logic; -- Master In Slave Out
        O_CS_N          : out   std_logic; -- Chip select (active low)
        -- Data interface
        I_TX_DATA       : in    std_logic_vector(G_NB_DATA_BITS - 1 downto 0);
        I_TX_DATA_VALID : in    std_logic;
        O_RX_DATA       : out   std_logic_vector(G_NB_DATA_BITS - 1 downto 0);
        O_RX_DATA_VALID : out   std_logic
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
        STATE_IDLE,
        STATE_DEAD_TIME_BEFORE,
        STATE_WAIT_LEADING_EDGE,
        STATE_SEND_BITS,
        STATE_DEAD_TIME_AFTER,
        STATE_DONE
    );

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- SPI clock generation
    constant C_HALF_PERIOD_CYCLES  : positive := G_CLK_FREQ_HZ / G_SPI_FREQ_HZ / 2;
    constant C_COUNTER_WIDTH       : positive := positive(ceil(log2(real(C_HALF_PERIOD_CYCLES))));

    -- Resynchronization
    constant C_RESYNC_STAGES       : positive := 2;

    -- Bit counter
    constant C_BIT_COUNTER_WIDTH   : positive := positive(ceil(log2(real(G_NB_DATA_BITS))));

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
    signal next_o_mosi             : std_logic;
    signal next_o_cs_n             : std_logic;
    signal next_o_valid            : std_logic;

    -- Bit count
    signal bit_counter             : unsigned(C_BIT_COUNTER_WIDTH - 1 downto 0);

    -- Internal registers
    signal reg_i_tx_data_valid_d1  : std_logic;
    signal reg_resync_i_miso       : std_logic_vector(C_RESYNC_STAGES - 1 downto 0);
    signal reg_i_tx_data           : std_logic_vector(G_NB_DATA_BITS - 1 downto 0);
    signal reg_o_rx_data_sr        : std_logic_vector(G_NB_DATA_BITS - 1 downto 0);

begin

    -- =================================================================================================================
    -- CLOCK GENERATION
    -- =================================================================================================================
    -- Generates the SPI clock by dividing the system clock by (G_CLK_FREQ_HZ / G_SPI_FREQ_HZ).
    -- Creates complementary clock signals (core_clk and core_clk_n) with associated enable pulses.
    -- The enable pulses are used to synchronize sampling and shifting operations across the FSM.
    -- =================================================================================================================

    p_core_clock_gen : process (CLK, RST_P) is
    begin

        if (RST_P = '1') then

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
    -- Sampling and shifting on according leading/trailing edges based on clock phase configuration
    -- =================================================================================================================

    gen_clk_phase : if G_CLK_PHASE = '0' generate
        spi_enable_sampling <= core_clk_en;
        spi_enable_shifting <= core_clk_n_en;
    else generate
        spi_enable_sampling <= core_clk_n_en;
        spi_enable_shifting <= core_clk_en;
    end generate gen_clk_phase;

    -- =================================================================================================================
    -- SPI output clock when active
    -- =================================================================================================================

    p_sclk : process (CLK, RST_P) is
    begin

        if (RST_P = '1') then

            reg_o_sclk <= G_CLK_POLARITY;
            O_SCLK     <= G_CLK_POLARITY;

        elsif rising_edge(CLK) then

            if (current_state = STATE_SEND_BITS and next_state = STATE_SEND_BITS) then
                reg_o_sclk <= spi_clk;
            else
                reg_o_sclk <= G_CLK_POLARITY;
            end if;

            O_SCLK <= reg_o_sclk;

        end if;

    end process p_sclk;

    -- =================================================================================================================
    -- Bit counter, increments on leading edge
    -- =================================================================================================================

    p_bit_count : process (CLK, RST_P) is
    begin

        if (RST_P = '1') then

            bit_counter <= (others => '0');

        elsif rising_edge(CLK) then

            if (current_state = STATE_SEND_BITS) then

                if (spi_enable_shifting = '1') then
                    bit_counter <= bit_counter + 1;
                end if;

            else
                bit_counter <= (others => '0');
            end if;

        end if;

    end process p_bit_count;

    -- =================================================================================================================
    -- Register the input data when valid and I_MISO resynchronization to input clock domain
    -- =================================================================================================================

    p_internal_reg : process (CLK, RST_P) is
    begin

        if (RST_P = '1') then

            reg_i_tx_data_valid_d1 <= '0';
            reg_i_tx_data          <= (others => '0');
            reg_resync_i_miso      <= (others => '0');

        elsif rising_edge(CLK) then

            reg_i_tx_data_valid_d1 <= I_TX_DATA_VALID;

            if (reg_i_tx_data_valid_d1 = '0' and I_TX_DATA_VALID = '1') then
                reg_i_tx_data <= I_TX_DATA;
            end if;

            -- 2 DFF stage resynchronizing async MISO to system clock domain
            reg_resync_i_miso <= reg_resync_i_miso(reg_resync_i_miso'high - 1 downto reg_resync_i_miso'low) & I_MISO;

        end if;

    end process p_internal_reg;

    -- =================================================================================================================
    -- FSM sequential process for state transitions
    -- =================================================================================================================

    p_fsm_seq : process (CLK, RST_P) is
    begin

        if (RST_P = '1') then

            current_state <= STATE_IDLE;

        elsif rising_edge(CLK) then

            current_state <= next_state;

        end if;

    end process p_fsm_seq;

    -- =================================================================================================================
    -- FSM combinatorial process for next state logic
    -- =================================================================================================================

    p_next_state_comb : process (all) is
    begin

        -- Default assignment
        next_state <= STATE_IDLE;

        case current_state is

            -- =========================================================================================================
            -- STATE: IDLE
            -- =========================================================================================================
            -- In idle state, the module awaits a valid data signal to initiate transmission.
            -- =========================================================================================================

            when STATE_IDLE =>

                if (reg_i_tx_data_valid_d1 = '0' and I_TX_DATA_VALID = '1') then
                    next_state <= STATE_DEAD_TIME_BEFORE;
                else
                    next_state <= STATE_IDLE;
                end if;

            -- =========================================================================================================
            -- STATE: DEAD TIME BEFORE
            -- =========================================================================================================
            -- In dead time before, the module awaits for a trailing edge
            -- =========================================================================================================

            when STATE_DEAD_TIME_BEFORE =>

                if (spi_enable_sampling = '1') then
                    next_state <= STATE_WAIT_LEADING_EDGE;
                else
                    next_state <= STATE_DEAD_TIME_BEFORE;
                end if;

            -- =========================================================================================================
            -- STATE: WAIT LEADING EDGE
            -- =========================================================================================================
            -- In wait leading edge, the module awaits for half a SPI clock period before sending the data bits and
            -- drives chip select low
            -- =========================================================================================================

            when STATE_WAIT_LEADING_EDGE =>

                if (spi_enable_shifting = '1') then
                    next_state <= STATE_SEND_BITS;
                else
                    next_state <= STATE_WAIT_LEADING_EDGE;
                end if;

            -- =========================================================================================================
            -- STATE: SEND BITS
            -- =========================================================================================================
            -- In send bits state, the module serializes the data to mosi and de-serializes miso and drives chip select
            -- low
            -- =========================================================================================================

            when STATE_SEND_BITS =>

                if (bit_counter >= G_NB_DATA_BITS - 1 and spi_enable_shifting = '1') then
                    next_state <= STATE_DEAD_TIME_AFTER;
                else
                    next_state <= STATE_SEND_BITS;
                end if;

            -- =========================================================================================================
            -- STATE: DEAD TIME AFTER
            -- =========================================================================================================
            -- In dead time after, the module awaits for a leading edge and drives chip select low
            -- =========================================================================================================

            when STATE_DEAD_TIME_AFTER =>

                if (spi_enable_sampling = '1') then
                    next_state <= STATE_DONE;
                else
                    next_state <= STATE_DEAD_TIME_AFTER;
                end if;

            -- =========================================================================================================
            -- STATE: DONE
            -- =========================================================================================================
            -- In done state, the module asserts the o_rx_data_valid flag for a system clock period
            -- =========================================================================================================

            when STATE_DONE =>

                next_state <= STATE_IDLE;

        end case;

    end process p_next_state_comb;

    -- =================================================================================================================
    -- FSM combinatorial process for next outputs
    -- =================================================================================================================

    p_next_outputs_comb : process (all) is
    begin

        -- Default assignment
        next_o_mosi  <= '0';
        next_o_cs_n  <= '1';
        next_o_valid <= '0';

        case current_state is

            -- =========================================================================================================
            -- STATE: IDLE
            -- =========================================================================================================

            when STATE_IDLE =>

            -- =========================================================================================================
            -- STATE: DEAD TIME BEFORE
            -- =========================================================================================================

            when STATE_DEAD_TIME_BEFORE =>

            -- =========================================================================================================
            -- STATE: WAIT LEADING EDGE
            -- =========================================================================================================

            when STATE_WAIT_LEADING_EDGE =>

                next_o_cs_n <= '0';

            -- =========================================================================================================
            -- STATE: SEND BITS
            -- =========================================================================================================

            when STATE_SEND_BITS =>

                -- Shift TX data
                next_o_mosi <= reg_i_tx_data(to_integer(reg_i_tx_data'length - 1 - bit_counter));

                next_o_cs_n <= '0';

            -- =========================================================================================================
            -- STATE: DEAD TIME AFTER
            -- =========================================================================================================

            when STATE_DEAD_TIME_AFTER =>

                next_o_cs_n <= '0';

            -- =========================================================================================================
            -- STATE: DONE
            -- =========================================================================================================

            when STATE_DONE =>

                next_o_valid <= '1';

        end case;

    end process p_next_outputs_comb;

    -- =================================================================================================================
    -- Registered outputs
    -- =================================================================================================================

    p_outputs_seq : process (CLK, RST_P) is
    begin

        if (RST_P = '1') then

            O_MOSI           <= '0';
            O_CS_N           <= '1';
            O_RX_DATA        <= (others => '0');
            O_RX_DATA_VALID  <= '0';

            reg_o_rx_data_sr <= (others => '0');

        elsif rising_edge(CLK) then

            if (current_state = STATE_SEND_BITS and spi_enable_sampling = '1') then
                reg_o_rx_data_sr <= reg_o_rx_data_sr(reg_o_rx_data_sr'high - 1 downto reg_o_rx_data_sr'low) &
                                    reg_resync_i_miso(reg_resync_i_miso'high);
            end if;

            O_MOSI          <= next_o_mosi;
            O_CS_N          <= next_o_cs_n;
            O_RX_DATA       <= reg_o_rx_data_sr;
            O_RX_DATA_VALID <= next_o_valid;

        end if;

    end process p_outputs_seq;

end architecture SPI_MASTER_ARCH;
