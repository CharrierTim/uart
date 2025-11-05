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
-- @file    uart_tx.vhd
-- @version 1.0
-- @brief   Transmission module for UART communication
-- @author  Timothee Charrier
-- @date    17/10/2025
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity UART_TX is
    generic (
        G_CLK_FREQ_HZ   : positive := 50_000_000; -- Clock frequency in Hz
        G_BAUD_RATE_BPS : positive := 115_200     -- Baud rate
    );port (
        -- Clock and reset
        CLK          : in    std_logic;
        RST_N        : in    std_logic;
        -- Input data interface
        I_BYTE       : in    std_logic_vector(8 - 1 downto 0);
        I_BYTE_VALID : in    std_logic;
        -- Output interface
        O_UART_TX    : out   std_logic;
        O_DONE       : out   std_logic
    );
end entity UART_TX;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================
architecture UART_TX_ARCH of UART_TX is

    -- =================================================================================================================
    -- TYPES
    -- =================================================================================================================

    type t_tx_state is (
        STATE_IDLE,
        STATE_SEND_BYTE,
        STATE_DONE
    );

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- UART TX clock
    constant C_TX_CLK_DIV_RATIO  : integer := G_CLK_FREQ_HZ / G_BAUD_RATE_BPS;
    constant C_BAUD_COUNTER_BITS : integer := integer(ceil(log2(real(C_TX_CLK_DIV_RATIO))));

    -- Data register
    constant C_TX_NB_BITS        : integer := 10;
    constant C_TX_COUNT_WIDTH    : integer := integer(ceil(log2(real(C_TX_NB_BITS))));

    -- =================================================================================================================
    -- SIGNAL
    -- =================================================================================================================

    -- Baud rate generators
    signal tx_baud_counter       : unsigned(C_BAUD_COUNTER_BITS - 1 downto 0);
    signal tx_baud_tick          : std_logic;
    signal tx_current_bit_index  : unsigned(C_TX_COUNT_WIDTH - 1 downto 0);

    -- FSM signals
    signal current_state         : t_tx_state;
    signal next_state            : t_tx_state;
    signal next_tx_data          : std_logic_vector(8 - 1 downto 0);
    signal next_o_uart_tx        : std_logic;
    signal next_o_done           : std_logic;

    -- Data register
    signal tx_data_reg           : std_logic_vector(C_TX_NB_BITS - 1 downto 0);

begin

    -- =================================================================================================================
    -- Generate the TX baud rate tick
    -- =================================================================================================================

    p_tx_clock_divider : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            tx_baud_counter <= (others => '0');
            tx_baud_tick    <= '0';

        elsif rising_edge(CLK) then

            -- =========================================================================================================
            -- Baud rate counter
            -- =========================================================================================================
            -- The baud rate counter increments on each clock cycle.
            -- =========================================================================================================

            -- Counter handling
            if (current_state = STATE_SEND_BYTE) then
                if (tx_baud_counter >= C_TX_CLK_DIV_RATIO - 1) then

                    tx_baud_counter <= (others => '0');
                    tx_baud_tick    <= '1';

                else
                    tx_baud_counter <= tx_baud_counter + 1;
                    tx_baud_tick    <= '0';
                end if;
            else
                tx_baud_counter <= (others => '0');
                tx_baud_tick    <= '0';
            end if;

        end if;

    end process p_tx_clock_divider;

    -- =================================================================================================================
    -- Bit counter for data bits transmission
    -- =================================================================================================================

    p_bit_counter : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            tx_data_reg          <= (others => '0');
            tx_current_bit_index <= (others => '0');

        elsif rising_edge(CLK) then

            -- =========================================================================================================
            -- Data register loading or shifting
            -- =========================================================================================================

            if (current_state /= STATE_SEND_BYTE) then

                -- Set the data
                tx_data_reg <= '1' & next_tx_data & '0'; -- 1 for stop bit, 0 for start bit

                -- Reset counter
                tx_current_bit_index <= (others => '0');

            elsif (tx_baud_tick = '1') then

                -- Shift the data
                tx_data_reg <= '1' & tx_data_reg(tx_data_reg'high downto tx_data_reg'low + 1);

                -- Increment counter
                tx_current_bit_index <= tx_current_bit_index + 1;

            end if;

        end if;

    end process p_bit_counter;

    -- =================================================================================================================
    -- FSM sequential process for state transitions
    -- =================================================================================================================

    p_fsm_seq : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

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

                if (I_BYTE_VALID = '1') then
                    next_state <= STATE_SEND_BYTE;
                else
                    next_state <= STATE_IDLE;
                end if;

            -- =========================================================================================================
            -- STATE: SEND BYTE
            -- =========================================================================================================
            -- In this state, send the start bit, the data and the stop bit
            -- =========================================================================================================

            when STATE_SEND_BYTE =>

                if (tx_current_bit_index >= C_TX_NB_BITS and tx_baud_tick = '1') then
                    next_state <= STATE_DONE;
                else
                    next_state <= STATE_SEND_BYTE;
                end if;

            -- =========================================================================================================
            -- STATE: DONE
            -- =========================================================================================================
            -- In done state, the module signals the completion of transmission.
            -- =========================================================================================================

            when STATE_DONE =>

                next_state <= STATE_IDLE;

        end case;

    end process p_next_state_comb;

    -- =================================================================================================================
    -- Next output logic
    -- =================================================================================================================

    p_next_output_comb : process (all) is
    begin

        -- Default assignments
        next_tx_data   <= (others => '0');
        next_o_uart_tx <= '1';
        next_o_done    <= '0';

        case current_state is

            -- =========================================================================================================
            -- STATE: IDLE
            -- =========================================================================================================

            when STATE_IDLE =>

                next_tx_data <= I_BYTE;

            -- =========================================================================================================
            -- STATE: SEND BYTE
            -- =========================================================================================================

            when STATE_SEND_BYTE =>

                next_o_uart_tx <= tx_data_reg(tx_data_reg'low);

            -- =========================================================================================================
            -- STATE: DONE
            -- =========================================================================================================

            when STATE_DONE =>

                next_o_done <= '1';

        end case;

    end process p_next_output_comb;

    -- =================================================================================================================
    -- Output registers
    -- =================================================================================================================

    p_output_reg : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            O_UART_TX <= '1';
            O_DONE    <= '0';

        elsif (rising_edge(CLK)) then

            O_UART_TX <= next_o_uart_tx;
            O_DONE    <= next_o_done;

        end if;

    end process p_output_reg;

end architecture UART_TX_ARCH;
