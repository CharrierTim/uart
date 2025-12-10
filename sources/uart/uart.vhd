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
-- @version 1.1
-- @brief   Top-level UART module, implementing both TX and RX functionalities with a custom protocol
-- @author  Timothee Charrier
-- @date    10/12/2025
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      21/10/2025  Timothee Charrier   Initial release
-- 1.1      10/12/2025  Timothee Charrier   Naming conventions update and remove generic
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library lib_rtl;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity UART is
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
        O_UART_TX         : out   std_logic;
        -- Read data interface
        O_READ_ADDR       : out   std_logic_vector( 8 - 1 downto 0);
        O_READ_ADDR_VALID : out   std_logic;
        I_READ_DATA       : in    std_logic_vector(16 - 1 downto 0);
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

        -- Waiting for 'R' or 'W' command
        STATE_IDLE,

        -- Processing start character
        STATE_CHAR_START,

        -- Write mode states
        STATE_WRITE_MODE,     -- Receiving address and data bytes
        STATE_WRITE_MODE_END, -- Validating write command

        -- Read mode states
        STATE_READ_MODE,           -- Receiving address bytes
        STATE_READ_MODE_WAIT_DATA, -- Waiting for register data
        STATE_READ_MODE_SEND_DATA, -- Transmitting data as hex ASCII
        STATE_READ_MODE_END        -- Completing read operation
    );

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- Number of byte to count
    constant C_READ_MODE_BYTE_COUNT  : positive := 3; -- ADDR        + CR
    constant C_WRITE_MODE_BYTE_COUNT : positive := 7; -- ADDR + DATA + CR

    -- Number of bytes to transmit
    constant C_TX_DATA_BYTES         : positive := 5; -- Number of hex chars to transmit for data + CR

    -- ASCII to hexadecimal conversion table

    -- vsg_off
    constant C_CHAR_0                : t_ascii_to_hex := (ascii => x"30", hex => "0000");
    constant C_CHAR_1                : t_ascii_to_hex := (ascii => x"31", hex => "0001");
    constant C_CHAR_2                : t_ascii_to_hex := (ascii => x"32", hex => "0010");
    constant C_CHAR_3                : t_ascii_to_hex := (ascii => x"33", hex => "0011");
    constant C_CHAR_4                : t_ascii_to_hex := (ascii => x"34", hex => "0100");
    constant C_CHAR_5                : t_ascii_to_hex := (ascii => x"35", hex => "0101");
    constant C_CHAR_6                : t_ascii_to_hex := (ascii => x"36", hex => "0110");
    constant C_CHAR_7                : t_ascii_to_hex := (ascii => x"37", hex => "0111");
    constant C_CHAR_8                : t_ascii_to_hex := (ascii => x"38", hex => "1000");
    constant C_CHAR_9                : t_ascii_to_hex := (ascii => x"39", hex => "1001");
    constant C_CHAR_A                : t_ascii_to_hex := (ascii => x"41", hex => "1010");
    constant C_CHAR_B                : t_ascii_to_hex := (ascii => x"42", hex => "1011");
    constant C_CHAR_C                : t_ascii_to_hex := (ascii => x"43", hex => "1100");
    constant C_CHAR_D                : t_ascii_to_hex := (ascii => x"44", hex => "1101");
    constant C_CHAR_E                : t_ascii_to_hex := (ascii => x"45", hex => "1110");
    constant C_CHAR_F                : t_ascii_to_hex := (ascii => x"46", hex => "1111");
    -- vsg_on

    -- Other useful ASCII characters
    constant C_CHAR_CR               : std_logic_vector(8 - 1 downto 0) := x"0D"; -- Carriage return character
    constant C_CHAR_R                : std_logic_vector(8 - 1 downto 0) := x"52"; -- 'R' character
    constant C_CHAR_W                : std_logic_vector(8 - 1 downto 0) := x"57"; -- 'W' character

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- FSM signals
    signal current_state             : t_state;
    signal next_state                : t_state;
    signal next_read_valid           : std_logic;
    signal next_write_valid          : std_logic;

    -- RX module signals
    signal rx_byte_count             : unsigned(3 - 1 downto 0);
    signal rx_byte                   : std_logic_vector( 8 - 1 downto 0);
    signal rx_byte_decoded           : std_logic_vector( 4 - 1 downto 0);
    signal rx_byte_valid             : std_logic;

    -- TX module signals
    signal tx_byte_count             : unsigned(3 - 1 downto 0);
    signal tx_byte_to_send           : std_logic_vector( 4 - 1 downto 0);
    signal tx_byte_to_send_encoded   : std_logic_vector( 8 - 1 downto 0);
    signal tx_byte_to_send_valid     : std_logic;
    signal tx_byte_send              : std_logic;

begin

    -- =================================================================================================================
    -- UART TX MODULE
    -- =================================================================================================================

    inst_uart_tx : entity lib_rtl.uart_tx
        generic map (
            G_CLK_FREQ_HZ   => G_CLK_FREQ_HZ,
            G_BAUD_RATE_BPS => G_BAUD_RATE_BPS
        )
        port map (
            CLK             => CLK,
            RST_N           => RST_N,
            I_TX_DATA       => tx_byte_to_send_encoded,
            I_TX_DATA_VALID => tx_byte_to_send_valid,
            O_UART_TX       => O_UART_TX,
            O_DONE          => tx_byte_send
        );

    -- =================================================================================================================
    -- TX DATA DECODING
    -- =================================================================================================================

    -- Converting the hexadecimal values to their ASCII representation
    tx_byte_to_send_encoded <= C_CHAR_CR      when tx_byte_count = C_TX_DATA_BYTES else
                               C_CHAR_0.ascii when tx_byte_to_send = C_CHAR_0.hex  else
                               C_CHAR_1.ascii when tx_byte_to_send = C_CHAR_1.hex  else
                               C_CHAR_2.ascii when tx_byte_to_send = C_CHAR_2.hex  else
                               C_CHAR_3.ascii when tx_byte_to_send = C_CHAR_3.hex  else
                               C_CHAR_4.ascii when tx_byte_to_send = C_CHAR_4.hex  else
                               C_CHAR_5.ascii when tx_byte_to_send = C_CHAR_5.hex  else
                               C_CHAR_6.ascii when tx_byte_to_send = C_CHAR_6.hex  else
                               C_CHAR_7.ascii when tx_byte_to_send = C_CHAR_7.hex  else
                               C_CHAR_8.ascii when tx_byte_to_send = C_CHAR_8.hex  else
                               C_CHAR_9.ascii when tx_byte_to_send = C_CHAR_9.hex  else
                               C_CHAR_A.ascii when tx_byte_to_send = C_CHAR_A.hex  else
                               C_CHAR_B.ascii when tx_byte_to_send = C_CHAR_B.hex  else
                               C_CHAR_C.ascii when tx_byte_to_send = C_CHAR_C.hex  else
                               C_CHAR_D.ascii when tx_byte_to_send = C_CHAR_D.hex  else
                               C_CHAR_E.ascii when tx_byte_to_send = C_CHAR_E.hex  else
                               C_CHAR_F.ascii when tx_byte_to_send = C_CHAR_F.hex  else
                               8x"00";

    -- =================================================================================================================
    -- UART RX MODULE
    -- =================================================================================================================

    inst_uart_rx : entity lib_rtl.uart_rx
        generic map (
            G_CLK_FREQ_HZ   => G_CLK_FREQ_HZ,
            G_BAUD_RATE_BPS => G_BAUD_RATE_BPS,
            G_SAMPLING_RATE => G_SAMPLING_RATE
        )
        port map (
            CLK               => CLK,
            RST_N             => RST_N,
            I_UART_RX         => I_UART_RX,
            O_BYTE            => rx_byte,
            O_BYTE_VALID      => rx_byte_valid,
            O_START_BIT_ERROR => open,
            O_STOP_BIT_ERROR  => open
        );

    -- =================================================================================================================
    -- RX DATA DECODING
    -- =================================================================================================================

    -- Converting the received ASCII-encoded hexadecimal data to binary
    rx_byte_decoded <= C_CHAR_0.hex when rx_byte = C_CHAR_0.ascii else
                       C_CHAR_1.hex when rx_byte = C_CHAR_1.ascii else
                       C_CHAR_2.hex when rx_byte = C_CHAR_2.ascii else
                       C_CHAR_3.hex when rx_byte = C_CHAR_3.ascii else
                       C_CHAR_4.hex when rx_byte = C_CHAR_4.ascii else
                       C_CHAR_5.hex when rx_byte = C_CHAR_5.ascii else
                       C_CHAR_6.hex when rx_byte = C_CHAR_6.ascii else
                       C_CHAR_7.hex when rx_byte = C_CHAR_7.ascii else
                       C_CHAR_8.hex when rx_byte = C_CHAR_8.ascii else
                       C_CHAR_9.hex when rx_byte = C_CHAR_9.ascii else
                       C_CHAR_A.hex when rx_byte = C_CHAR_A.ascii else
                       C_CHAR_B.hex when rx_byte = C_CHAR_B.ascii else
                       C_CHAR_C.hex when rx_byte = C_CHAR_C.ascii else
                       C_CHAR_D.hex when rx_byte = C_CHAR_D.ascii else
                       C_CHAR_E.hex when rx_byte = C_CHAR_E.ascii else
                       C_CHAR_F.hex when rx_byte = C_CHAR_F.ascii else
                       4x"0";

    -- =================================================================================================================
    -- FSM sequential process for state transitions and byte count
    -- =================================================================================================================

    p_fsm_seq : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            current_state         <= STATE_IDLE;

            rx_byte_count         <= (others => '0');
            tx_byte_count         <= (others => '0');

            tx_byte_to_send_valid <= '0';

        elsif rising_edge(CLK) then

            -- Transition to the next state. Always go to STATE_CHAR_START when receiving a 'R' or 'W' character
            if (rx_byte_valid = '1' and (rx_byte = C_CHAR_R or rx_byte = C_CHAR_W)) then
                current_state <= STATE_CHAR_START;
            else
                current_state <= next_state;
            end if;

            -- RX byte count
            if (current_state = STATE_IDLE or current_state = STATE_CHAR_START) then
                rx_byte_count <= (others => '0');
            elsif (rx_byte_valid = '1') then
                rx_byte_count <= rx_byte_count + 1;
            end if;

            -- TX byte count
            if (current_state = STATE_IDLE or current_state = STATE_CHAR_START) then
                tx_byte_count         <= (others => '0');
                tx_byte_to_send_valid <= '0';
            elsif (
                   (I_READ_DATA_VALID = '1') -- First byte to send
                   or
                   (tx_byte_send = '1')      -- Other bytes to send
               ) then
                tx_byte_count         <= tx_byte_count + 1;
                tx_byte_to_send_valid <= '1';
            else
                tx_byte_to_send_valid <= '0';
            end if;

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

                if (rx_byte = C_CHAR_R) then
                    next_state <= STATE_READ_MODE;
                elsif (rx_byte = C_CHAR_W) then
                    next_state <= STATE_WRITE_MODE;
                end if;

            -- =========================================================================================================
            -- STATE: READ_MODE
            -- =========================================================================================================
            -- In this mode, we decode the incoming read address
            -- Protocol is: R01\r
            --       Where:     - 0  is the address MSB
            --                  - 1  is the address LSB
            --                  - \r is the carriage return
            -- =========================================================================================================

            when STATE_READ_MODE =>

                if (rx_byte_count >= C_READ_MODE_BYTE_COUNT) then

                    -- Check if the last received character is a \r
                    if (rx_byte = C_CHAR_CR) then
                        next_state <= STATE_READ_MODE_END;
                    else
                        next_state <= STATE_IDLE;
                    end if;

                else
                    next_state <= STATE_READ_MODE;
                end if;

            -- =========================================================================================================
            -- STATE: READ_MODE_END
            -- =========================================================================================================
            -- After receiving the line feed character, go back to idle state and raise the data valid signal
            -- =========================================================================================================

            when STATE_READ_MODE_END =>

                next_state <= STATE_READ_MODE_WAIT_DATA;

            -- =========================================================================================================
            -- STATE: READ_MODE_WAIT_DATA
            -- =========================================================================================================
            -- Wait for the data from the regfile
            -- =========================================================================================================

            when STATE_READ_MODE_WAIT_DATA =>

                if (I_READ_DATA_VALID = '1') then
                    next_state <= STATE_READ_MODE_SEND_DATA;
                else
                    next_state <= STATE_READ_MODE_WAIT_DATA;
                end if;

            -- =========================================================================================================
            -- STATE: READ_MODE_SEND_DATA
            -- =========================================================================================================
            -- Send the data via uart
            -- =========================================================================================================

            when STATE_READ_MODE_SEND_DATA =>

                if (tx_byte_count >= C_TX_DATA_BYTES) then
                    next_state <= STATE_IDLE;
                else
                    next_state <= STATE_READ_MODE_SEND_DATA;
                end if;

            -- =========================================================================================================
            -- STATE: WRITE_MODE
            -- =========================================================================================================
            -- In this mode, we decode the incoming write address and data
            -- Protocol is: RAB1235\r
            --       Where:     - A    is the address MSB
            --                  - B    is the address LSB
            --                  - 1234 is the data
            --                  - \r   is the carriage return
            -- =========================================================================================================

            when STATE_WRITE_MODE =>

                if (rx_byte_count = C_WRITE_MODE_BYTE_COUNT) then

                    -- Check if the last received character is a \r
                    if (rx_byte = C_CHAR_CR) then
                        next_state <= STATE_WRITE_MODE_END;
                    else
                        next_state <= STATE_IDLE;
                    end if;

                else
                    next_state <= STATE_WRITE_MODE;
                end if;

            -- =========================================================================================================
            -- STATE: WRITE_MODE_END
            -- =========================================================================================================
            -- After receiving the line feed character, go back to idle state and raise the data valid signal
            -- =========================================================================================================

            when STATE_WRITE_MODE_END =>

                next_state <= STATE_IDLE;

        end case;

    end process p_next_state_comb;

    -- =================================================================================================================
    -- Output logic
    -- =================================================================================================================

    p_fsm_output_comb : process (all) is
    begin

        -- Default assignment
        next_read_valid  <= '0';
        next_write_valid <= '0';
        tx_byte_to_send  <= (others => '0');

        case current_state is

            -- =========================================================================================================
            -- STATE: IDLE
            -- =========================================================================================================

            when STATE_IDLE =>

            -- =========================================================================================================
            -- STATE: CHAR_START
            -- =========================================================================================================

            when STATE_CHAR_START =>

            -- =========================================================================================================
            -- STATE: READ_MODE
            -- =========================================================================================================
            -- In this mode, we decode the incoming read address.
            -- The rx_byte_count start after receiving a 'W' or 'R'.
            -- Protocol is: R01\r
            --       Where:     - 0  is the address MSB
            --                  - 1  is the address LSB
            --                  - \r is the carriage return
            -- =========================================================================================================

            when STATE_READ_MODE =>

            -- =========================================================================================================
            -- STATE: READ_MODE_END
            -- =========================================================================================================

            when STATE_READ_MODE_END =>

                next_read_valid <= '1';

            -- =========================================================================================================
            -- STATE: READ_MODE_WAIT_DATA
            -- =========================================================================================================

            when STATE_READ_MODE_WAIT_DATA =>

            -- =========================================================================================================
            -- STATE: READ_MODE_WAIT_DATA
            -- =========================================================================================================

            when STATE_READ_MODE_SEND_DATA =>

                -- Select the data

                case tx_byte_count is

                    -- vsg_off
                    when "001"  => tx_byte_to_send <= I_READ_DATA(15 downto 12); -- Data (bits 15 - 12)
                    when "010"  => tx_byte_to_send <= I_READ_DATA(11 downto  8); -- Data (bits 11 -  8)
                    when "011"  => tx_byte_to_send <= I_READ_DATA( 7 downto  4); -- Data (bits  7 -  4)
                    when "100"  => tx_byte_to_send <= I_READ_DATA( 3 downto  0); -- Data (bits  3 -  0)
                    when others => null;
                    -- vsg_on

                end case;

            -- =========================================================================================================
            -- STATE: WRITE_MODE
            -- =========================================================================================================
            -- In this mode, we decode the incoming write address and data.
            -- The rx_byte_count start after receiving a 'W' or 'R'.
            -- Protocol is: RAB1235\r
            --       Where:     - A    is the address MSB
            --                  - B    is the address LSB
            --                  - 1234 is the data
            --                  - \r   is the carriage return
            -- =========================================================================================================

            when STATE_WRITE_MODE =>

            -- =========================================================================================================
            -- STATE: WRITE_MODE_END
            -- =========================================================================================================

            when STATE_WRITE_MODE_END =>

                next_write_valid <= '1';

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
            if (rx_byte_valid = '1') then

                case rx_byte_count is

                    -- vsg_off
                    when "000"  => O_READ_ADDR(7 downto 4) <= rx_byte_decoded; -- Addr MSB
                    when "001"  => O_READ_ADDR(3 downto 0) <= rx_byte_decoded; -- Addr LSB
                    when others => null;
                    -- vsg_on

                end case;

            end if;

            O_READ_ADDR_VALID <= next_read_valid;

            -- Update the write address, data and valid signal
            if (rx_byte_valid = '1') then

                case rx_byte_count is

                    -- vsg_off
                    when "000"  => O_WRITE_ADDR( 7 downto  4) <= rx_byte_decoded; -- Addr MSB
                    when "001"  => O_WRITE_ADDR( 3 downto  0) <= rx_byte_decoded; -- Addr LSB
                    when "010"  => O_WRITE_DATA(15 downto 12) <= rx_byte_decoded; -- Data (bits 15 - 12)
                    when "011"  => O_WRITE_DATA(11 downto  8) <= rx_byte_decoded; -- Data (bits 11 -  8)
                    when "100"  => O_WRITE_DATA( 7 downto  4) <= rx_byte_decoded; -- Data (bits  7 -  4)
                    when "101"  => O_WRITE_DATA( 3 downto  0) <= rx_byte_decoded; -- Data (bits  3 -  0)
                    when others => null;
                    -- vsg_on

                end case;

            end if;

            O_WRITE_VALID <= next_write_valid;

        end if;

    end process p_output_reg;

end architecture UART_ARCH;
