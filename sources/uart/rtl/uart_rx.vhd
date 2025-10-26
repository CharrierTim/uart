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
-- @version 1.0
-- @brief   Reception module for UART communication
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

    type t_rx_state is (
        STATE_IDLE,
        STATE_START_BIT,
        STATE_DATA_BITS,
        STATE_STOP_BIT,
        STATE_CLEANUP,
        STATE_START_BIT_ERROR,
        STATE_STOP_BIT_ERROR
    );

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- UART RX clock (default is 16 times the baud rate)
    constant C_RX_CLK_DIV_RATIO         : integer := G_CLK_FREQ_HZ / (G_BAUD_RATE_BPS * G_SAMPLING_RATE);
    constant C_SAMPLE_COUNTER_WIDTH     : integer := integer(ceil(log2(real(C_RX_CLK_DIV_RATIO))));

    -- Sampling constants
    constant C_OVERSAMPLE_COUNTER_WIDTH : integer := integer(ceil(log2(real(G_SAMPLING_RATE))));
    constant C_OVERSAMPLE_MAX           : integer := G_SAMPLING_RATE - 1;
    constant C_MID_BIT_SAMPLE_POINT     : integer := C_OVERSAMPLE_MAX / 2;

    -- =================================================================================================================
    -- SIGNAL
    -- =================================================================================================================

    -- Baud rate generators
    signal rx_baud_counter              : unsigned(C_SAMPLE_COUNTER_WIDTH  - 1 downto 0);
    signal rx_baud_tick                 : std_logic;

    -- Clock Domain Crossing and Filtering (5-stage shift register: 2 for metastability + 3 for filtering)
    signal i_uart_rx_sr                 : std_logic_vector(5 - 1 downto 0);
    signal i_uart_rx_filtered           : std_logic;
    signal i_uart_rx_filtered_d1        : std_logic;

    -- Bit tick
    signal uart_rx_mid_bit_samples      : std_logic_vector(3 - 1 downto 0);
    signal uart_rx_sampled_bit          : std_logic;

    -- FSM
    signal current_state                : t_rx_state;
    signal next_state                   : t_rx_state;
    signal next_count_enable            : std_logic;
    signal next_o_byte_update           : std_logic;
    signal next_start_bit_error         : std_logic;
    signal next_stop_bit_error          : std_logic;
    signal next_o_data_valid            : std_logic;

    -- Counter of current oversampling ticks within a bit period
    signal oversampling_count           : unsigned(C_OVERSAMPLE_COUNTER_WIDTH  - 1 downto 0);

    -- Counter of current data bits received
    signal data_bit_count               : unsigned(3 - 1 downto 0);

    -- Current byte
    signal received_byte                : std_logic_vector(O_BYTE'range);

begin

    -- =================================================================================================================
    -- Generate the RX baud rate tick, which is 16 times the baud rate.
    -- =================================================================================================================

    p_rx_clock_divider : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            rx_baud_counter <= (others => '0');
            rx_baud_tick    <= '0';

        elsif rising_edge(CLK) then

            -- =========================================================================================================
            -- Baud rate counter
            -- =========================================================================================================
            -- The baud rate counter increments on each clock cycle when enabled. When a falling edge is detected on the
            -- UART RX line (indicating the start of a new frame), the counter is reset to zero to synchronize with the
            -- incoming data.
            -- =========================================================================================================

            if (next_count_enable = '1') then

                -- Counter handling
                if (rx_baud_counter >= C_RX_CLK_DIV_RATIO - 1) then
                    rx_baud_counter <= (others => '0');
                    rx_baud_tick    <= '1';
                else
                    rx_baud_counter <= rx_baud_counter + 1;
                    rx_baud_tick    <= '0';
                end if;
            else
                rx_baud_counter <= (others => '0');
                rx_baud_tick    <= '0';

            end if;

        end if;

    end process p_rx_clock_divider;

    -- =================================================================================================================
    -- Resynchronize UART RX input into 16x baud clock domain and apply digital filtering
    -- =================================================================================================================

    p_input_sync_filter : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            i_uart_rx_sr          <= (others => '1');
            i_uart_rx_filtered    <= '1';
            i_uart_rx_filtered_d1 <= '1';

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

            if (i_uart_rx_sr(4 downto 2) = "000") then
                i_uart_rx_filtered <= '0';
            elsif (i_uart_rx_sr(4 downto 2) = "111") then
                i_uart_rx_filtered <= '1';
            end if;

            -- Update last value to detect falling edge for start bit detection and rising edge for stop bit validation
            i_uart_rx_filtered_d1 <= i_uart_rx_filtered;

        end if;

    end process p_input_sync_filter;

    -- =================================================================================================================
    -- Sampling control process: manages oversampling and majority voting
    -- =================================================================================================================

    p_sampling_control : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            oversampling_count      <= (others => '0');
            data_bit_count          <= (others => '0');
            uart_rx_mid_bit_samples <= (others => '0');
            uart_rx_sampled_bit     <= '1';

        elsif rising_edge(CLK) then

            -- =========================================================================================================
            -- Baud tick counter and decoded bit counter
            -- ========================================================================================================
            -- Each bit period is 16 baud ticks. After 16 ticks, we have received one full bit, then the data bit count
            -- is Incremented by one.
            -- =========================================================================================================

            if (rx_baud_tick = '1' and next_count_enable = '1') then
                if (oversampling_count = C_OVERSAMPLE_MAX) then

                    -- One full bit period has passed (16 ticks at 16x oversampling)
                    oversampling_count <= (others => '0');

                    -- Increment the decoded bit count
                    if (current_state = STATE_DATA_BITS) then
                        data_bit_count <= data_bit_count    + 1;
                    end if;

                else
                    oversampling_count <= oversampling_count + 1;
                end if;
            end if;

            -- =========================================================================================================
            -- UART RX Sampling: Majority Voting at Mid-Bit
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
            --   Samples:                                   ^  ^  ^
            --                                          Sample Points (Ticks 7, 8, 9)
            --
            -- Sampling Logic:
            --   - Tick 7: First sample  -> uart_rx_mid_bit_samples(0)
            --   - Tick 8: Second sample -> uart_rx_mid_bit_samples(1)
            --   - Tick 9: Third sample  -> uart_rx_mid_bit_samples(2)
            --
            -- =========================================================================================================

            -- Sampling at ticks 7, 8, and 9 (all - 1 because counting from 0)
            if (oversampling_count = C_MID_BIT_SAMPLE_POINT  - 1 and rx_baud_tick = '1') then
                uart_rx_mid_bit_samples(0) <= i_uart_rx_filtered;
            elsif (oversampling_count = C_MID_BIT_SAMPLE_POINT  and rx_baud_tick = '1') then
                uart_rx_mid_bit_samples(1) <= i_uart_rx_filtered;
            elsif (oversampling_count = C_MID_BIT_SAMPLE_POINT  + 1 and rx_baud_tick = '1') then
                uart_rx_mid_bit_samples(2) <= i_uart_rx_filtered;
            end if;

            -- =========================================================================================================
            -- Majority Voting Logic
            -- =========================================================================================================
            -- Majority Voting Decision:
            --   - If 2 or 3 samples are '0' -> bit value = '0'
            --   - If 2 or 3 samples are '1' -> bit value = '1'
            --   - This provides immunity against single-tick noise spikes
            --
            -- Example scenarios:
            --   uart_rx_mid_bit_samples = "000" -> Clean '0', output = '0' -> OK
            --   uart_rx_mid_bit_samples = "111" -> Clean '1', output = '1' -> OK
            --   uart_rx_mid_bit_samples = "001" -> Noisy '0', output = '0' -> OK
            --   uart_rx_mid_bit_samples = "110" -> Noisy '1', output = '1' -> OK
            --   uart_rx_mid_bit_samples = "010" -> Ambiguous, keeps previous value
            -- =========================================================================================================

            case uart_rx_mid_bit_samples is

                -- Majority is '0' (2 or 3 zeros)
                when "000" | "001" | "010" | "100" =>

                    uart_rx_sampled_bit <= '0';

                -- Majority is '1' (2 or 3 ones)
                when "111" | "110" | "101" | "011" =>

                    uart_rx_sampled_bit <= '1';

                -- Ambiguous cases (1 zero, 1 one, 1 unknown), keep previous value
                when others =>

            end case;

        end if;

    end process p_sampling_control;

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
        next_state <= current_state;

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
            --     - If the start bit is invalid (line goes high), the module transitions to the START BIT ERROR state.
            -- =========================================================================================================

            when STATE_START_BIT =>

                if (rx_baud_tick = '1' and oversampling_count = C_OVERSAMPLE_MAX) then
                    if (uart_rx_sampled_bit = '0') then
                        next_state <= STATE_DATA_BITS;
                    else
                        next_state <= STATE_START_BIT_ERROR;
                    end if;
                else
                    next_state <= STATE_START_BIT;
                end if;

            -- =========================================================================================================
            -- STATE: START BIT ERROR
            -- =========================================================================================================
            -- In start bit error state, the module flags a start bit error and transitions back to the IDLE state.
            -- =========================================================================================================

            when STATE_START_BIT_ERROR =>

                next_state <= STATE_IDLE;

            -- =========================================================================================================
            -- STATE: DATA BITS
            -- =========================================================================================================
            -- In data bits state, the module samples the incoming data bits at the middle of each bit period.
            -- After receiving 8 data bits, the module transitions to the STOP BIT state.
            -- =========================================================================================================

            when STATE_DATA_BITS =>

                if (data_bit_count = 7 and oversampling_count = C_OVERSAMPLE_MAX and rx_baud_tick = '1') then
                    next_state <= STATE_STOP_BIT;
                else
                    next_state <= STATE_DATA_BITS;
                end if;

            -- =========================================================================================================
            -- STATE: STOP BIT
            -- =========================================================================================================
            -- In stop bit state, the module verifies that the stop bit is valid by checking that the UART RX line
            -- remains high at the middle of the bit period.
            --    - If the stop bit is valid, the module transitions to the CLEANUP state.
            --    - If the stop bit is invalid (line goes low), the module transitions to the STOP BIT ERROR state.
            -- =========================================================================================================

            when STATE_STOP_BIT =>

                if (rx_baud_tick = '1' and oversampling_count = C_OVERSAMPLE_MAX) then
                    if (uart_rx_sampled_bit = '1') then
                        next_state <= STATE_CLEANUP;
                    else
                        next_state <= STATE_STOP_BIT_ERROR;
                    end if;
                else
                    next_state <= STATE_STOP_BIT;
                end if;

            -- =========================================================================================================
            -- STATE: STOP BIT ERROR
            -- =========================================================================================================
            -- In stop bit error state, the module flags a stop bit error and transitions back to the IDLE state.
            -- =========================================================================================================

            when STATE_STOP_BIT_ERROR =>

                next_state <= STATE_IDLE;

            -- =========================================================================================================
            -- STATE: CLEANUP
            -- =========================================================================================================
            -- In cleanup state, the module asserts the data valid signal for one clock cycle and then
            -- transitions back to the IDLE state.
            -- =========================================================================================================

            when STATE_CLEANUP =>

                next_state <= STATE_IDLE;

            -- =========================================================================================================
            -- DEFAULT CASE: should not occur
            -- =========================================================================================================

            when others =>

                next_state <= STATE_IDLE;

        end case;

    end process p_next_state_comb;

    -- =================================================================================================================
    -- Output logic
    -- =================================================================================================================

    p_fsm_output_comb : process (all) is
    begin

        -- Default assignment
        next_count_enable    <= '1';
        next_o_byte_update   <= '0';
        next_start_bit_error <= '0';
        next_stop_bit_error  <= '0';
        next_o_data_valid    <= '0';

        case current_state is

            -- =========================================================================================================
            -- STATE: IDLE
            -- =========================================================================================================

            when STATE_IDLE =>

                next_count_enable <= '0';

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

                if (rx_baud_tick = '1' and oversampling_count = C_OVERSAMPLE_MAX) then
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
            -- STATE: CLEANUP
            -- =========================================================================================================

            when STATE_CLEANUP =>

                next_o_data_valid <= '1';

            -- =========================================================================================================
            -- DEFAULT CASE: should not occur
            -- =========================================================================================================

            when others =>

                next_count_enable    <= '1';
                next_o_byte_update   <= '0';
                next_start_bit_error <= '0';
                next_stop_bit_error  <= '0';
                next_o_data_valid    <= '0';

        end case;

    end process p_fsm_output_comb;

    -- =================================================================================================================
    -- Output registers
    -- =================================================================================================================

    p_output_reg : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            O_BYTE            <= (others => '0');
            O_BYTE_VALID      <= '0';
            O_START_BIT_ERROR <= '0';
            O_STOP_BIT_ERROR  <= '0';

            received_byte     <= (others => '0');

        elsif (rising_edge(CLK)) then

            -- Update output byte (receive from LSB to MSB)
            if (next_o_byte_update = '1') then
                received_byte <= uart_rx_sampled_bit & received_byte(received_byte'high downto received_byte'low + 1);
            end if;

            -- If data is valid, latch the byte to output
            if (next_o_data_valid = '1') then
                O_BYTE <= received_byte;
            end if;

            -- Update output signals
            O_BYTE_VALID      <= next_o_data_valid;
            O_START_BIT_ERROR <= next_start_bit_error;
            O_STOP_BIT_ERROR  <= next_stop_bit_error;

        end if;

    end process p_output_reg;

end architecture UART_RX_ARCH;
