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
-- @file    uart_tx.vhd
-- @version 2.0
-- @brief   Transmission module for UART communication
-- @author  Timothee Charrier
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      17/10/2025  Timothee Charrier   Initial release
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

entity UART_TX is
    generic (
        G_CLK_FREQ_HZ   : positive := 50_000_000; -- Clock frequency in Hz
        G_BAUD_RATE_BPS : positive := 115_200     -- Baud rate
    );
    port (
        -- Clock and reset
        CLK             : in    std_logic;
        RST_P           : in    std_logic;
        -- Input data interface
        I_TX_DATA       : in    std_logic_vector(8 - 1 downto 0);
        I_TX_DATA_VALID : in    std_logic;
        -- Output interface
        O_UART_TX       : out   std_logic;
        O_DONE          : out   std_logic
    );
end entity UART_TX;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================
architecture UART_TX_ARCH of UART_TX is

    -- =================================================================================================================
    -- TYPES
    -- =================================================================================================================

    type t_state is (
        STATE_IDLE,
        STATE_SEND_TX_DATA,
        STATE_DONE
    );

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- UART TX clock
    constant C_TX_CLK_DIV_RATIO   : integer := G_CLK_FREQ_HZ / G_BAUD_RATE_BPS;
    constant C_BAUD_COUNTER_WIDTH : integer := integer(ceil(log2(real(C_TX_CLK_DIV_RATIO))));

    -- Data register (1 start bit, 8 dara bits and 1 stop bit)
    constant C_NB_TX_BITS         : integer := 10;
    constant C_BIT_COUNTER_WIDTH  : integer := integer(ceil(log2(real(C_NB_TX_BITS))));

    -- =================================================================================================================
    -- SIGNAL
    -- =================================================================================================================

    -- Baud rate generator
    signal tx_baud_counter        : unsigned(C_BAUD_COUNTER_WIDTH - 1 downto 0);

    -- FSM signals
    signal current_state          : t_state;
    signal next_state             : t_state;
    signal next_o_uart_tx         : std_logic;
    signal next_o_done            : std_logic;

    -- Bit count
    signal bit_counter            : unsigned(C_BIT_COUNTER_WIDTH - 1 downto 0);

    -- Data register
    signal reg_tx_data            : std_logic_vector(C_NB_TX_BITS - 1 downto 0);

begin

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

                if (I_TX_DATA_VALID = '1') then
                    next_state <= STATE_SEND_TX_DATA;
                else
                    next_state <= STATE_IDLE;
                end if;

            -- =========================================================================================================
            -- STATE: SEND BYTE
            -- =========================================================================================================
            -- In this state, send the start bit, the data and the stop bit
            -- =========================================================================================================

            when STATE_SEND_TX_DATA =>

                if (bit_counter >= C_NB_TX_BITS) then
                    next_state <= STATE_DONE;
                else
                    next_state <= STATE_SEND_TX_DATA;
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
    -- TX Baud Rate Generator and Serial Shift Register
    -- =================================================================================================================
    -- Generates the transmission baud rate clock from the system clock and manages the serial bit stream.
    --
    -- Transmission Order: Start bit first (0), then data LSB to MSB, then stop bit (1)
    -- =================================================================================================================

    p_tx_clock_gen : process (CLK, RST_P) is
    begin

        if (RST_P = '1') then

            tx_baud_counter <= (others => '0');
            reg_tx_data     <= (others => '1');
            bit_counter     <= (others => '0');

        elsif rising_edge(CLK) then

            if (current_state = STATE_SEND_TX_DATA) then

                -- =====================================================================================================
                -- Active Transmission State
                -- =====================================================================================================

                if (tx_baud_counter >= C_TX_CLK_DIV_RATIO - 1) then

                    tx_baud_counter <= (others => '0');

                    -- Shift right to transmit next bit (LSB is output to TX line)
                    reg_tx_data <= '1' & reg_tx_data(reg_tx_data'high downto reg_tx_data'low + 1);

                    -- Track current bit index
                    bit_counter <= bit_counter + 1;

                else
                    tx_baud_counter <= tx_baud_counter + 1;
                end if;

            else
                -- =====================================================================================================
                -- Prepare for next transmission
                -- =====================================================================================================

                tx_baud_counter <= (others => '0');
                bit_counter     <= (others => '0');

                -- Preload shift register
                reg_tx_data <= '1' & I_TX_DATA & '0';

            end if;

        end if;

    end process p_tx_clock_gen;

    -- =================================================================================================================
    -- Next output logic
    -- =================================================================================================================

    p_next_outputs_comb : process (all) is
    begin

        -- Default assignments
        next_o_uart_tx <= '1';
        next_o_done    <= '0';

        case current_state is

            -- =========================================================================================================
            -- STATE: IDLE
            -- =========================================================================================================

            when STATE_IDLE =>

            -- =========================================================================================================
            -- STATE: SEND BYTE
            -- =========================================================================================================

            when STATE_SEND_TX_DATA =>

                next_o_uart_tx <= reg_tx_data(reg_tx_data'low);

            -- =========================================================================================================
            -- STATE: DONE
            -- =========================================================================================================

            when STATE_DONE =>

                next_o_done <= '1';

        end case;

    end process p_next_outputs_comb;

    -- =================================================================================================================
    -- Output registers
    -- =================================================================================================================

    p_outputs_seq : process (CLK, RST_P) is
    begin

        if (RST_P = '1') then

            O_UART_TX <= '1';
            O_DONE    <= '0';

        elsif (rising_edge(CLK)) then

            O_UART_TX <= next_o_uart_tx;
            O_DONE    <= next_o_done;

        end if;

    end process p_outputs_seq;

end architecture UART_TX_ARCH;
