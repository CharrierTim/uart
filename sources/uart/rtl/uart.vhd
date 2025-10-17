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
-- @file    uart.vhd
-- @version 1.0
-- @brief   Top-level UART module, implementing both TX and RX functionalities with a custom protocol
-- @author  Timothee Charrier
-- @date    14/10/2025
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;

library lib_rtl;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity UART is
    generic (
        G_CLK_FREQ_HZ   : positive := 50_000_000; -- Clock frequency in Hz
        G_BAUD_RATE_BPS : positive := 115_200     -- Baud rate
    );
    port (
        -- Clock and reset
        CLK               : in    std_logic;
        RST_N             : in    std_logic;
        -- UART interface
        I_UART_RX         : in    std_logic;
        O_UART_TX         : out   std_logic;
        -- Read data interface
        O_READ_ADDR       : out   std_logic_vector( 8 - 1 downto 0);
        O_READ_ADDR_VALID : out   std_logic;
        I_READ_DATA       : in    std_logic_vector( 8 - 1 downto 0);
        I_READ_DATA_VALID : in    std_logic;
        -- Write data interface
        O_WRITE_ADDR      : out   std_logic_vector( 8 - 1 downto 0);
        O_WRITE_DATA      : out   std_logic_vector(16 - 1 downto 0);
        O_WRITE_VALID     : out   std_logic
    );
end entity UART;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================

architecture UART_ARCH of UART is

    -- =================================================================================================================
    -- TYPES
    -- =================================================================================================================

    type t_ascii_to_hex is record
        ascii : std_logic_vector(8 - 1 downto 0);
        hex   : std_logic_vector(4 - 1 downto 0);
    end record t_ascii_to_hex;

    type t_state is (
        STATE_IDLE,

        -- Start character state ('R' or 'W')
        STATE_CHAR_START,
        STATE_WAIT_READ_ADDR,
        STATE_WAIT_WRITE_ADDR,

        -- Write command states
        STATE_WRITE_ADDR_MSB,   -- MSB (bits 15-12)
        STATE_WRITE_ADDR_LSB,   -- LSB (bits  7- 4)
        STATE_WRITE_DATA_BYTE3, -- MSB (bits 15-12)
        STATE_WRITE_DATA_BYTE2, --     (bits 11- 8)
        STATE_WRITE_DATA_BYTE1, --     (bits  7- 4)
        STATE_WRITE_DATA_BYTE0, -- LSB (bits  3- 0)
        STATE_WRITE_CR,
        STATE_WRITE_END,

        -- Read command states
        STATE_READ_ADDR_MSB, -- MSB (bits 15-12)
        STATE_READ_ADDR_LSB, -- LSB (bits  7- 4)
        STATE_READ_CR,
        STATE_READ_END
    );

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- ASCII to hexadecimal conversion table

    -- vsg_off
    constant C_CHAR_0            : t_ascii_to_hex := (ascii => x"30", hex => "0000");
    constant C_CHAR_1            : t_ascii_to_hex := (ascii => x"31", hex => "0001");
    constant C_CHAR_2            : t_ascii_to_hex := (ascii => x"32", hex => "0010");
    constant C_CHAR_3            : t_ascii_to_hex := (ascii => x"33", hex => "0011");
    constant C_CHAR_4            : t_ascii_to_hex := (ascii => x"34", hex => "0100");
    constant C_CHAR_5            : t_ascii_to_hex := (ascii => x"35", hex => "0101");
    constant C_CHAR_6            : t_ascii_to_hex := (ascii => x"36", hex => "0110");
    constant C_CHAR_7            : t_ascii_to_hex := (ascii => x"37", hex => "0111");
    constant C_CHAR_8            : t_ascii_to_hex := (ascii => x"38", hex => "1000");
    constant C_CHAR_9            : t_ascii_to_hex := (ascii => x"39", hex => "1001");
    constant C_CHAR_A            : t_ascii_to_hex := (ascii => x"41", hex => "1010");
    constant C_CHAR_B            : t_ascii_to_hex := (ascii => x"42", hex => "1011");
    constant C_CHAR_C            : t_ascii_to_hex := (ascii => x"43", hex => "1100");
    constant C_CHAR_D            : t_ascii_to_hex := (ascii => x"44", hex => "1101");
    constant C_CHAR_E            : t_ascii_to_hex := (ascii => x"45", hex => "1110");
    constant C_CHAR_F            : t_ascii_to_hex := (ascii => x"46", hex => "1111");
    -- vsg_on

    -- Other useful ASCII characters
    constant C_CHAR_CR           : std_logic_vector(8 - 1 downto 0) := x"0D"; -- Carriage return character
    constant C_CHAR_R            : std_logic_vector(8 - 1 downto 0) := x"52"; -- 'R' character
    constant C_CHAR_W            : std_logic_vector(8 - 1 downto 0) := x"57"; -- 'W' character

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- FSM signals
    signal current_state         : t_state;
    signal next_state            : t_state;
    signal next_read_addr        : std_logic_vector( 8 - 1 downto 0);
    signal next_read_addr_valid  : std_logic;
    signal next_write_addr       : std_logic_vector( 8 - 1 downto 0);
    signal next_write_data       : std_logic_vector(16 - 1 downto 0);
    signal next_write_valid      : std_logic;

    -- RX module signals
    signal rx_data               : std_logic_vector( 8 - 1 downto 0);
    signal rx_data_valid         : std_logic;
    signal rx_start_bit_error    : std_logic;
    signal rx_stop_bit_error     : std_logic;

    -- Decoded RX data
    signal decoded_rx_data       : std_logic_vector( 4 - 1 downto 0);
    signal reg_decoded_rx_data   : std_logic_vector( 4 - 1 downto 0);
    signal decoded_rx_data_valid : std_logic;

begin

    -- =================================================================================================================
    -- UART RX MODULE
    -- =================================================================================================================
    inst_uart_rx : entity lib_rtl.uart_rx
        generic map (
            G_CLK_FREQ_HZ   => G_CLK_FREQ_HZ,
            G_BAUD_RATE_BPS => G_BAUD_RATE_BPS
        )
        port map (
            CLK               => CLK,
            RST_N             => RST_N,
            I_UART_RX         => I_UART_RX,
            O_BYTE            => rx_data,
            O_BYTE_VALID      => rx_data_valid,
            O_START_BIT_ERROR => rx_start_bit_error,
            O_STOP_BIT_ERROR  => rx_stop_bit_error
        );

    -- =================================================================================================================
    -- RX DATA DECODING
    -- =================================================================================================================

    -- Converting the received ASCII-encoded hexadecimal data to binary
    decoded_rx_data <= C_CHAR_0.hex when rx_data = C_CHAR_0.ascii else
                       C_CHAR_1.hex when rx_data = C_CHAR_1.ascii else
                       C_CHAR_2.hex when rx_data = C_CHAR_2.ascii else
                       C_CHAR_3.hex when rx_data = C_CHAR_3.ascii else
                       C_CHAR_4.hex when rx_data = C_CHAR_4.ascii else
                       C_CHAR_5.hex when rx_data = C_CHAR_5.ascii else
                       C_CHAR_6.hex when rx_data = C_CHAR_6.ascii else
                       C_CHAR_7.hex when rx_data = C_CHAR_7.ascii else
                       C_CHAR_8.hex when rx_data = C_CHAR_8.ascii else
                       C_CHAR_9.hex when rx_data = C_CHAR_9.ascii else
                       C_CHAR_A.hex when rx_data = C_CHAR_A.ascii else
                       C_CHAR_B.hex when rx_data = C_CHAR_B.ascii else
                       C_CHAR_C.hex when rx_data = C_CHAR_C.ascii else
                       C_CHAR_D.hex when rx_data = C_CHAR_D.ascii else
                       C_CHAR_E.hex when rx_data = C_CHAR_E.ascii else
                       C_CHAR_F.hex when rx_data = C_CHAR_F.ascii else
                       x"0";

    -- =================================================================================================================
    -- Latch the decoded RX data
    -- =================================================================================================================

    p_rx_decoding : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            reg_decoded_rx_data   <= (others => '0');
            decoded_rx_data_valid <= '0';

        elsif rising_edge(CLK) then

            -- Decoding the data received from the RX module
            if (rx_data_valid = '1') then
                reg_decoded_rx_data <= decoded_rx_data;
            end if;

            -- Shift the decoded data valid signal
            decoded_rx_data_valid <= rx_data_valid;

        end if;

    end process p_rx_decoding;

    -- =================================================================================================================
    -- FSM sequential process for state transitions
    -- =================================================================================================================

    p_fsm_seq : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            current_state <= STATE_IDLE;

        elsif rising_edge(CLK) then

            -- Transition to the next state. Always go to STATE_CHAR_START when receiving a 'R' or 'W' character
            if (rx_data_valid = '1' and (rx_data = C_CHAR_R or rx_data = C_CHAR_W)) then
                current_state <= STATE_CHAR_START;
            else
                current_state <= next_state;
            end if;

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
            -- In idle state, wait for a 'R' or 'W' character to start a new command
            -- =========================================================================================================

            when STATE_IDLE =>

            -- Specific case, handled in the sequential process
            -- Any received 'R' or 'W' character will directly lead to STATE_CHAR_START

            -- =========================================================================================================
            -- STATE: CHAR_START
            -- =========================================================================================================
            -- After receiving a 'R' or 'W' character, go to the next state depending on the command type
            -- =========================================================================================================
            when STATE_CHAR_START =>

                -- Determine the next state based on the command type
                if (rx_data = C_CHAR_R) then
                    next_state <= STATE_WAIT_READ_ADDR;
                elsif (rx_data = C_CHAR_W) then
                    next_state <= STATE_WAIT_WRITE_ADDR;
                end if;

            -- =========================================================================================================
            -- STATE: WAIT_READ_ADDR
            -- =========================================================================================================
            -- Wait for the next byte containing the read address MSB
            -- =========================================================================================================
            when STATE_WAIT_READ_ADDR =>

                if (rx_data_valid = '1') then
                    next_state <= STATE_READ_ADDR_MSB;
                end if;

            -- =========================================================================================================
            -- STATE: WAIT_WRITE_ADDR
            -- =========================================================================================================
            -- Wait for the next byte containing the write address MSB
            -- =========================================================================================================
            when STATE_WAIT_WRITE_ADDR =>

                if (rx_data_valid = '1') then
                    next_state <= STATE_WRITE_ADDR_MSB;
                end if;

            -- =========================================================================================================
            -- STATE: READ_ADDR_MSB
            -- =========================================================================================================
            -- Get the read address MSB (bits 7-4)
            -- =========================================================================================================
            when STATE_READ_ADDR_MSB =>

                if (rx_data_valid = '1') then
                    next_state <= STATE_READ_ADDR_LSB;
                end if;

            -- =========================================================================================================
            -- STATE: READ_ADDR_LSB
            -- =========================================================================================================
            -- Get the read address LSB (bits 3-0)
            -- Then, go to the next state checking for a carriage return character
            -- =========================================================================================================
            when STATE_READ_ADDR_LSB =>

                if (rx_data_valid = '1') then
                    next_state <= STATE_READ_CR;
                end if;

            -- =========================================================================================================
            -- STATE: WRITE_ADDR_MSB
            -- =========================================================================================================
            -- Get the write address MSB (bits 7-4)
            -- =========================================================================================================
            when STATE_WRITE_ADDR_MSB =>

                if (rx_data_valid = '1') then
                    next_state <= STATE_WRITE_ADDR_LSB;
                end if;

            -- =========================================================================================================
            -- STATE: WRITE_ADDR_LSB
            -- =========================================================================================================
            -- Get the write address LSB (bits 3-0)
            -- =========================================================================================================
            when STATE_WRITE_ADDR_LSB =>

                if (rx_data_valid = '1') then
                    next_state <= STATE_WRITE_DATA_BYTE3;
                end if;

            -- =========================================================================================================
            -- STATE: WRITE_DATA_BYTE3
            -- =========================================================================================================
            -- Get the data bits 15-12 (MSB)
            -- =========================================================================================================
            when STATE_WRITE_DATA_BYTE3 =>

                if (rx_data_valid = '1') then
                    next_state <= STATE_WRITE_DATA_BYTE2;
                end if;

            -- =========================================================================================================
            -- STATE: WRITE_DATA_BYTE2
            -- =========================================================================================================
            -- After receiving the data bits 11- 8
            -- =========================================================================================================
            when STATE_WRITE_DATA_BYTE2 =>

                if (rx_data_valid = '1') then
                    next_state <= STATE_WRITE_DATA_BYTE1;
                end if;

            -- =========================================================================================================
            -- STATE: WRITE_DATA_BYTE1
            -- =========================================================================================================
            -- Get the data bits  7- 4
            -- =========================================================================================================
            when STATE_WRITE_DATA_BYTE1 =>

                if (rx_data_valid = '1') then
                    next_state <= STATE_WRITE_DATA_BYTE0;
                end if;

            -- =========================================================================================================
            -- STATE: WRITE_DATA_BYTE0
            -- =========================================================================================================
            -- Get the data bits  3- 0 (LSB)
            -- Then, go to the next state checking for a carriage return character
            -- =========================================================================================================
            when STATE_WRITE_DATA_BYTE0 =>

                if (rx_data_valid = '1') then
                    next_state <= STATE_WRITE_CR;
                end if;

            -- =========================================================================================================
            -- STATE: WRITE_CR
            -- =========================================================================================================
            -- After receiving a carriage return character, go to the end write state, otherwise go back to idle state
            -- =========================================================================================================

            when STATE_WRITE_CR =>

                if (rx_data = C_CHAR_CR) then
                    next_state <= STATE_WRITE_END;
                else
                    next_state <= STATE_IDLE;
                end if;

            -- =========================================================================================================
            -- STATE: STATE_READ_CR
            -- =========================================================================================================
            -- After receiving a carriage return character, go to the end read state, otherwise go back to idle state
            -- =========================================================================================================
            when STATE_READ_CR =>

                if (rx_data = C_CHAR_CR) then
                    next_state <= STATE_READ_END;
                else
                    next_state <= STATE_IDLE;
                end if;

            -- =========================================================================================================
            -- STATE: WRITE_END
            -- =========================================================================================================
            -- After receiving the line feed character, go back to idle state and raise the data valid signal
            -- =========================================================================================================
            when STATE_WRITE_END =>

                next_state <= STATE_IDLE;

            -- =========================================================================================================
            -- STATE: READ_END
            -- =========================================================================================================
            -- After receiving the line feed character, go back to idle state and raise the data valid signal
            -- =========================================================================================================
            when STATE_READ_END =>

                next_state <= STATE_IDLE;

            -- =========================================================================================================
            -- DEFAULT CASE
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

        next_read_addr_valid <= '0';
        next_write_valid     <= '0';

        case current_state is

            -- =========================================================================================================
            -- STATE: IDLE
            -- =========================================================================================================
            when STATE_IDLE =>

                next_read_addr  <= (others => '0');
                next_write_addr <= (others => '0');
                next_write_data <= (others => '0');

            -- =========================================================================================================
            -- STATE: CHAR_START
            -- =========================================================================================================
            when STATE_CHAR_START =>

                next_read_addr  <= (others => '0');
                next_write_addr <= (others => '0');
                next_write_data <= (others => '0');

            -- =========================================================================================================
            -- STATE: WAIT_READ_ADDR
            -- =========================================================================================================
            when STATE_WAIT_READ_ADDR =>

            -- =========================================================================================================
            -- STATE: WAIT_WRITE_ADDR
            -- =========================================================================================================
            when STATE_WAIT_WRITE_ADDR =>

            -- =========================================================================================================
            -- STATE: READ_ADDR_MSB
            -- =========================================================================================================
            when STATE_READ_ADDR_MSB =>

                next_read_addr(7 downto 4) <= reg_decoded_rx_data;

            -- =========================================================================================================
            -- STATE: READ_ADDR_LSB
            -- =========================================================================================================
            when STATE_READ_ADDR_LSB =>

                next_read_addr(3 downto 0) <= reg_decoded_rx_data;

            -- =========================================================================================================
            -- STATE: WRITE_ADDR_MSB
            -- =========================================================================================================
            when STATE_WRITE_ADDR_MSB =>

                next_write_addr(7 downto 4) <= reg_decoded_rx_data;

            -- =========================================================================================================
            -- STATE: WRITE_ADDR_LSB
            -- =========================================================================================================
            when STATE_WRITE_ADDR_LSB =>

                next_write_addr(3 downto 0) <= reg_decoded_rx_data;

            -- =========================================================================================================
            -- STATE: WRITE_DATA_BYTE3
            -- =========================================================================================================
            when STATE_WRITE_DATA_BYTE3 =>

                next_write_data(15 downto 12) <= reg_decoded_rx_data;

            -- =========================================================================================================
            -- STATE: WRITE_DATA_BYTE2
            -- =========================================================================================================
            when STATE_WRITE_DATA_BYTE2 =>

                next_write_data(11 downto 8) <= reg_decoded_rx_data;

            -- =========================================================================================================
            -- STATE: WRITE_DATA_BYTE1
            -- =========================================================================================================
            when STATE_WRITE_DATA_BYTE1 =>

                next_write_data(7 downto 4) <= reg_decoded_rx_data;

            -- =========================================================================================================
            -- STATE: WRITE_DATA_BYTE0
            -- =========================================================================================================
            when STATE_WRITE_DATA_BYTE0 =>

                next_write_data(3 downto 0) <= reg_decoded_rx_data;

            -- =========================================================================================================
            -- STATE: WRITE_CR
            -- =========================================================================================================
            when STATE_WRITE_CR =>

            -- =========================================================================================================
            -- STATE: READ_CR
            -- =========================================================================================================
            when STATE_READ_CR =>

            -- =========================================================================================================
            -- STATE: WRITE_END
            -- =========================================================================================================
            when STATE_WRITE_END =>

                next_write_valid <= '1';

            -- =========================================================================================================
            -- STATE: READ_END
            -- =========================================================================================================
            when STATE_READ_END =>

                next_read_addr_valid <= '1';

            -- =========================================================================================================
            -- DEFAULT CASE
            -- =========================================================================================================
            when others =>

                next_read_addr       <= (others => '0');
                next_read_addr_valid <= '0';
                next_write_addr      <= (others => '0');
                next_write_data      <= (others => '0');
                next_write_valid     <= '0';

        end case;

    end process p_fsm_output_comb;

    -- =================================================================================================================
    -- OUTPUT ASSIGNMENTS
    -- =================================================================================================================

    p_output_reg : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            O_READ_ADDR       <= (others => '0');
            O_READ_ADDR_VALID <= '0';
            O_WRITE_ADDR      <= (others => '0');
            O_WRITE_DATA      <= (others => '0');
            O_WRITE_VALID     <= '0';

        elsif rising_edge(CLK) then

            -- Update the read address and valid signal
            if (next_read_addr_valid = '1') then
                O_READ_ADDR <= next_read_addr;
            end if;

            O_READ_ADDR_VALID <= next_read_addr_valid;

            -- Update the write address, data and valid signal
            if (next_write_valid = '1') then
                O_WRITE_DATA <= next_write_data;
                O_WRITE_ADDR <= next_write_addr;
            end if;

            O_WRITE_VALID <= next_write_valid;

        end if;

    end process p_output_reg;

end architecture UART_ARCH;
