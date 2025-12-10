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
-- @file    uart_rx.vhd
-- @version 1.1
-- @brief   Reception module for UART communication
-- @author  Timothee Charrier
-- @date    10/12/2025
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      17/10/2025  Timothee Charrier   Initial release
-- 1.1      10/12/2025  Timothee Charrier   Naming conventions update and remove generic
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity UART_RX is
    generic (
        G_CLK_FREQ_HZ   : positive := 50_000_000; -- Clock frequency in Hz
        G_BAUD_RATE_BPS : positive := 115_200;    -- Baud rate
        G_SAMPLING_RATE : positive := 16          -- Sampling rate (number of clock cycles per bit)
    );
    port (
        -- Clock and reset
        CLK               : in    std_logic;
        RST_N             : in    std_logic;
        -- UART interface
        I_UART_RX         : in    std_logic;
        -- Output data interface
        O_BYTE            : out   std_logic_vector(8 - 1 downto 0);
        O_BYTE_VALID      : out   std_logic;
        -- Error flags
        O_START_BIT_ERROR : out   std_logic;
        O_STOP_BIT_ERROR  : out   std_logic
    );
end entity UART_RX;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================

architecture UART_RX_ARCH of UART_RX is

    -- =================================================================================================================
    -- TYPES
    -- =================================================================================================================

    type t_state is (
        STATE_IDLE,
        STATE_START_BIT,
        STATE_DATA_BITS,
        STATE_STOP_BIT,
        STATE_VALID,
        STATE_START_BIT_ERROR,
        STATE_STOP_BIT_ERROR,
        STATE_ERROR_RECOVERY
    );

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- UART RX clock
    constant C_RX_CLK_DIV_RATIO         : integer := G_CLK_FREQ_HZ / (G_BAUD_RATE_BPS * G_SAMPLING_RATE);
    constant C_SAMPLE_COUNTER_WIDTH     : integer := integer(ceil(log2(real(C_RX_CLK_DIV_RATIO))));

    -- Sampling constants
    constant C_OVERSAMPLE_COUNTER_WIDTH : integer := integer(ceil(log2(real(G_SAMPLING_RATE))));
    constant C_MID_SAMPLE_POINT         : integer := G_SAMPLING_RATE / 2;
    constant C_THREE_QUARTER_POINT      : integer := (G_SAMPLING_RATE * 3) / 4;

    -- Counter bit width
    constant C_BIT_COUNTER_WIDTH        : integer := integer(ceil(log2(real(O_BYTE'length))));

    -- Recovery constants
    constant C_NB_RECOVERY_BITS         : integer := O_BYTE'length + 1; -- Data bits + stop bit
    constant C_RECOVERY_PERIOD          : integer := G_SAMPLING_RATE * C_NB_RECOVERY_BITS;
    constant C_RECOVERY_COUNTER_WIDTH   : integer := integer(ceil(log2(real(C_RECOVERY_PERIOD))));

    -- =================================================================================================================
    -- SIGNAL
    -- =================================================================================================================

    -- Baud rate generators
    signal rx_baud_counter              : unsigned(C_SAMPLE_COUNTER_WIDTH - 1 downto 0);
    signal rx_baud_tick                 : std_logic;

    -- Sample count
    signal oversample_counter           : unsigned(C_OVERSAMPLE_COUNTER_WIDTH - 1 downto 0);

    -- Bit count
    signal bit_counter                  : unsigned(C_BIT_COUNTER_WIDTH  - 1 downto 0);

    -- Recovery locked counter
    signal recovery_counter             : unsigned(C_RECOVERY_COUNTER_WIDTH - 1 downto 0);
    signal recovery_elapsed             : std_logic;

    -- Clock Domain Crossing and Filtering (4-stage shift register: 2 for metastability + 2 for filtering)
    signal i_uart_rx_sr                 : std_logic_vector(4 - 1 downto 0);
    signal i_uart_rx_filtered           : std_logic;
    signal i_uart_rx_filtered_d1        : std_logic;

    -- Bit tick
    signal uart_rx_sampled_bit          : std_logic;

    -- FSM
    signal current_state                : t_state;
    signal next_state                   : t_state;
    signal next_start_bit_error         : std_logic;
    signal next_stop_bit_error          : std_logic;
    signal next_o_byte_valid            : std_logic;
    signal next_o_byte_update           : std_logic;
    signal next_o_byte                  : std_logic_vector(8 - 1 downto 0);

begin

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
            -- In idle state, the module awaits for a falling edge on the UART RX line to detect the start bit.
            -- =========================================================================================================

            when STATE_IDLE =>

                if (i_uart_rx_filtered_d1 = '1' and i_uart_rx_filtered = '0') then
                    next_state <= STATE_START_BIT;
                else
                    next_state <= STATE_IDLE;
                end if;

            -- =========================================================================================================
            -- STATE: START BIT
            -- =========================================================================================================
            -- In start bit state, the module verifies that the start bit is valid by checking that the UART RX line
            -- remains low at the middle of the bit period.
            --     - If the start bit is valid, the module transitions to the DATA BITS state.
            --     - If the start bit is invalid, the module transitions to the START BIT ERROR state.
            -- =========================================================================================================

            when STATE_START_BIT =>

                if (oversample_counter = G_SAMPLING_RATE - 1 and rx_baud_tick = '1') then

                    if (uart_rx_sampled_bit = '0') then
                        next_state <= STATE_DATA_BITS;
                    else
                        next_state <= STATE_START_BIT_ERROR;
                    end if;

                else
                    next_state <= STATE_START_BIT;
                end if;

            -- =========================================================================================================
            -- STATE: DATA BITS
            -- =========================================================================================================
            -- In data bits state, the module samples the incoming data bits at the middle of each bit period.
            -- After receiving 8 data bits, and when at the expected edge of the stop bit, the module transitions to
            -- the STOP BIT state.
            -- =========================================================================================================

            when STATE_DATA_BITS =>

                if ((bit_counter = O_BYTE'length - 1) and
                    (oversample_counter = G_SAMPLING_RATE - 1 and rx_baud_tick = '1')) then
                    next_state <= STATE_STOP_BIT;
                else
                    next_state <= STATE_DATA_BITS;
                end if;

            -- =========================================================================================================
            -- STATE: STOP BIT
            -- =========================================================================================================
            -- In stop bit state, the module verifies that the stop bit is valid by checking that the UART RX line
            -- remains high at the middle of the bit period. To ensure detecting a burst, leave the state before the
            -- expected end of the STOP bit (3/4 of it).
            --    - If the stop bit is   valid ('1'), the module transitions to the VALID state.
            --    - If the stop bit is invalid ('0'), the module transitions to the STOP BIT ERROR state.
            -- =========================================================================================================

            when STATE_STOP_BIT =>

                if (oversample_counter = C_THREE_QUARTER_POINT - 1) then

                    if (uart_rx_sampled_bit = '1') then
                        next_state <= STATE_VALID;
                    else
                        next_state <= STATE_STOP_BIT_ERROR;
                    end if;

                else
                    next_state <= STATE_STOP_BIT;
                end if;

            -- =========================================================================================================
            -- STATE: START BIT ERROR
            -- =========================================================================================================
            -- In start bit error state, the module flags a start bit error and transitions back to the IDLE state.
            -- =========================================================================================================

            when STATE_START_BIT_ERROR =>

                next_state <= STATE_ERROR_RECOVERY;

            -- =========================================================================================================
            -- STATE: STOP BIT ERROR
            -- =========================================================================================================
            -- In stop bit error state, the module flags a stop bit error and transitions back to the IDLE state.
            -- =========================================================================================================

            when STATE_STOP_BIT_ERROR =>

                next_state <= STATE_IDLE;

            when STATE_ERROR_RECOVERY =>

                if (recovery_elapsed = '1') then
                    next_state <= STATE_IDLE;
                else
                    next_state <= STATE_ERROR_RECOVERY;
                end if;

            -- =========================================================================================================
            -- STATE: VALID
            -- =========================================================================================================
            -- In this state, the module asserts the byte valid signal for one clock cycle and then
            -- transitions back to the IDLE state.
            -- =========================================================================================================

            when STATE_VALID =>

                next_state <= STATE_IDLE;

        end case;

    end process p_next_state_comb;

    -- =================================================================================================================
    -- Resynchronize UART RX input into input clock domain and apply digital filtering
    -- =================================================================================================================

    p_rx_filtering_and_sampling : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            i_uart_rx_sr          <= (others => '1');
            i_uart_rx_filtered    <= '1';
            i_uart_rx_filtered_d1 <= '1';
            uart_rx_sampled_bit   <= '1';

        elsif rising_edge(CLK) then

            -- =========================================================================================================
            -- Shift register to resynchronize the asynchronous UART RX input into the local clock domain
            -- =========================================================================================================

            i_uart_rx_sr <= i_uart_rx_sr(i_uart_rx_sr'high - 1 downto i_uart_rx_sr'low) & I_UART_RX;

            -- =========================================================================================================
            -- Simple digital filtering to mitigate noise on the UART RX line.
            -- Only change the filtered value if we have 3 consecutive samples of the same value.
            -- Only the last 3 bits of the shift register are used for filtering, the first 2 bits are potentially
            -- metastable and must not be used.
            -- =========================================================================================================

            if (i_uart_rx_sr(3 downto 1) = "000") then
                i_uart_rx_filtered <= '0';
            elsif (i_uart_rx_sr(3 downto 1) = "111") then
                i_uart_rx_filtered <= '1';
            end if;

            -- Update last value to detect falling edge for start bit detection and rising edge for stop bit validation
            i_uart_rx_filtered_d1 <= i_uart_rx_filtered;

            -- =========================================================================================================
            -- UART RX Sampling: Sampled at mid bit
            -- =========================================================================================================
            --
            -- Visual representation of a data bit transition with 16x oversampling:
            --
            --   Idle/Previous Bit                           Current Data Bit                           Next Bit
            --        (High)                                     (Low)                                   (High)
            --   ________________                                                                 __________________
            --                   \                                                               /
            --                    \                                                             /
            --                     \                                                           /
            --                      \_________________________________________________________/
            --
            --   Tick:                 0  1  2  3  4  5  6  7  8  9  10  11  12  13  14  15
            --   Samples:                                      ^
            --                                            Sample Point
            --
            -- Sampling Logic:
            --   - Tick 8: sample data
            --
            -- =========================================================================================================

            if (oversample_counter = C_MID_SAMPLE_POINT - 1) then
                uart_rx_sampled_bit <= i_uart_rx_filtered;
            end if;

        end if;

    end process p_rx_filtering_and_sampling;

    -- =================================================================================================================
    -- Generate the RX baud rate tick, which is 16 times the baud rate.
    -- =================================================================================================================

    p_baud_generator : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            rx_baud_counter    <= (others => '0');
            rx_baud_tick       <= '0';

            oversample_counter <= (others => '0');
            bit_counter        <= (others => '0');

            recovery_counter   <= (others => '0');
            recovery_elapsed   <= '0';

        elsif rising_edge(CLK) then

            -- =========================================================================================================
            -- Baud rate counter
            -- =========================================================================================================
            -- Generates an internal clock at G_SAMPLING_RATE times the baud rate (default 16x)
            -- =========================================================================================================

            if (current_state /= STATE_IDLE) then

                -- Counter handling
                if (rx_baud_counter >= C_RX_CLK_DIV_RATIO - 1) then
                    rx_baud_counter <= (others => '0');
                    rx_baud_tick    <= '1';
                else
                    rx_baud_counter <= rx_baud_counter + 1;
                    rx_baud_tick    <= '0';
                end if;

            else
                rx_baud_counter    <= (others => '0');
                rx_baud_tick       <= '0';
                oversample_counter <= (others => '0');
                bit_counter        <= (others => '0');
            end if;

            -- =========================================================================================================
            -- Oversample and bit counters
            -- =========================================================================================================
            -- Every 16x baud tick, increment the bit counter
            -- =========================================================================================================

            if (rx_baud_tick = '1') then

                -- Counter handling
                if (oversample_counter >= G_SAMPLING_RATE - 1) then

                    oversample_counter <= (others => '0');

                    -- Count the current bit index
                    if (bit_counter >= O_BYTE'length - 1) then
                        bit_counter <= (others => '0');
                    elsif (current_state = STATE_DATA_BITS) then
                        bit_counter <= bit_counter + 1;
                    end if;

                else
                    oversample_counter <= oversample_counter + 1;
                end if;
            end if;

            -- =========================================================================================================
            -- Recovery counter
            -- =========================================================================================================
            -- "Lock" the FSM if an invalid start bit is detected for C_NB_TOTAL_BITS at the specified baudrate
            -- =========================================================================================================

            -- Recovery counter management
            if (current_state = STATE_ERROR_RECOVERY) then
                if (rx_baud_tick = '1') then

                    if (recovery_counter >= C_RECOVERY_PERIOD - 1) then
                        recovery_counter <= (others => '0');
                        recovery_elapsed <= '1';
                    else
                        recovery_counter <= recovery_counter + 1;
                        recovery_elapsed <= '0';
                    end if;

                end if;
            end if;
        end if;

    end process p_baud_generator;

    -- =================================================================================================================
    -- Output logic
    -- =================================================================================================================

    p_next_outputs_comb : process (all) is
    begin

        next_start_bit_error <= '0';
        next_stop_bit_error  <= '0';
        next_o_byte_valid    <= '0';
        next_o_byte_update   <= '0';

        case current_state is

            -- =========================================================================================================
            -- STATE: IDLE
            -- =========================================================================================================

            when STATE_IDLE =>

            -- =========================================================================================================
            -- STATE: START BIT
            -- =========================================================================================================

            when STATE_START_BIT =>

            -- =========================================================================================================
            -- STATE: START BIT ERROR
            -- =========================================================================================================

            when STATE_START_BIT_ERROR =>

                next_start_bit_error <= '1';

            -- =========================================================================================================
            -- STATE: DATA BITS
            -- =========================================================================================================

            when STATE_DATA_BITS =>

                if (rx_baud_tick = '1' and oversample_counter = G_SAMPLING_RATE - 1) then
                    next_o_byte_update <= '1';
                else
                    next_o_byte_update <= '0';
                end if;

            -- =========================================================================================================
            -- STATE: STOP BIT
            -- =========================================================================================================

            when STATE_STOP_BIT =>

            -- =========================================================================================================
            -- STATE: STOP BIT ERROR
            -- =========================================================================================================

            when STATE_STOP_BIT_ERROR =>

                next_stop_bit_error <= '1';

            -- =========================================================================================================
            -- STATE: ERROR RECOVERY
            -- =========================================================================================================

            when STATE_ERROR_RECOVERY =>

            -- =========================================================================================================
            -- STATE: VALID
            -- =========================================================================================================

            when STATE_VALID =>

                next_o_byte_valid <= '1';

        end case;

    end process p_next_outputs_comb;

    -- =================================================================================================================
    -- Output process
    -- =================================================================================================================

    p_outputs_seq : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            next_o_byte       <= (others => '0');
            O_BYTE            <= (others => '0');
            O_BYTE_VALID      <= '0';
            O_START_BIT_ERROR <= '0';
            O_STOP_BIT_ERROR  <= '0';

        elsif rising_edge(CLK) then

            -- Current byte
            if (next_o_byte_update = '1') then
                next_o_byte <= uart_rx_sampled_bit & next_o_byte(next_o_byte'high downto next_o_byte'low + 1);
            end if;

            -- Output byte only if valid flag is asserted
            if (next_o_byte_valid = '1') then
                O_BYTE <= next_o_byte;
            end if;

            O_START_BIT_ERROR <= next_start_bit_error;
            O_STOP_BIT_ERROR  <= next_stop_bit_error;
            O_BYTE_VALID      <= next_o_byte_valid;

        end if;

    end process p_outputs_seq;

end architecture UART_RX_ARCH;
