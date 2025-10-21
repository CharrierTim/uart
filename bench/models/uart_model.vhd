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
-- @file    uart_model.vhd
-- @version 1.0
-- @brief   Model for the UART implementing the custom protocol
--
--          Protocol (ASCII-hex)
--            - Read register:
--                Send:  "R" AA "\r"
--                  * 'R'        : ASCII 'R' (0x52)
--                  * AA         : two ASCII hex characters representing an 8-bit register address (MSB first)
--                  * '\r'       : carriage return (0x0D)
--                Response: DDDD "\r"
--                  * DDDD       : four ASCII hex characters for the 16-bit register value (MSB first)
--                  * '\r'       : carriage return
--
--            - Write register:
--                Send:  "W" AA DDDD "\r"
--                  * 'W'        : ASCII 'W' (0x57)
--                  * AA         : 2 ASCII hex chars (8-bit address)
--                  * DDDD       : 4 ASCII hex chars (16-bit data)
--                  * '\r'       : carriage return
--                No response
--
-- @author  Timothee Charrier
-- @date    21/10/2025
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity UART_MODEL is
    generic (
        G_BAUD_RATE_BPS : positive := 115_200 -- Baud rate
    );
    port (
        -- UART interface
        I_UART_RX            : in    std_logic;
        O_UART_TX            : out   std_logic;
        -- Read interface
        I_READ_ADDRESS       : in    std_logic_vector( 8 - 1 downto 0);
        I_READ_ADDRESS_VALID : in    std_logic;
        O_READ_DATA          : out   std_logic_vector(16 - 1 downto 0);
        -- Write interface
        I_WRITE_ADDRESS      : in    std_logic_vector( 8 - 1 downto 0);
        I_WRITE_DATA         : in    std_logic_vector(16 - 1 downto 0);
        I_WRITE_VALID        : in    std_logic
    );
end entity UART_MODEL;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================

architecture UART_MODEL_ARCH of UART_MODEL is

    -- =================================================================================================================
    -- TYPE
    -- =================================================================================================================

    type t_state is (
        STATE_IDLE,
        STATE_READ,
        STATE_WRITE
    );

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    constant C_BIT_TIME  : time := 1 sec / G_BAUD_RATE_BPS;

    -- Characters
    constant C_CHAR_CR   : std_logic_vector(8 - 1 downto 0) := x"0D"; -- Carriage return character
    constant C_CHAR_R    : std_logic_vector(8 - 1 downto 0) := x"52"; -- 'R' character
    constant C_CHAR_W    : std_logic_vector(8 - 1 downto 0) := x"57"; -- 'W' character

    -- =================================================================================================================
    -- SIGNAL
    -- =================================================================================================================

    signal current_state : t_state;

    -- =================================================================================================================
    -- func_hex_to_ascii_representation
    -- Description: This function converts a 4-bit hex value to its ASCII std_logic_vector representation.
    -- =================================================================================================================
    function func_hex_to_ascii_representation (hex_char : std_logic_vector(4 - 1 downto 0)) return std_logic_vector is
    begin

        -- vsg_off
        case hex_char is
        -- '0'..'9'
        when x"0"   => return x"30";
        when x"1"   => return x"31";
        when x"2"   => return x"32";
        when x"3"   => return x"33";
        when x"4"   => return x"34";
        when x"5"   => return x"35";
        when x"6"   => return x"36";
        when x"7"   => return x"37";
        when x"8"   => return x"38";
        when x"9"   => return x"39";
        -- 'A'..'F'
        when x"A"   => return x"41";
        when x"B"   => return x"42";
        when x"C"   => return x"43";
        when x"D"   => return x"44";
        when x"E"   => return x"45";
        when x"F"   => return x"46";
        when others => return x"30"; -- Default to '0'
        end case;
        -- vsg_on
    end function;

    -- =================================================================================================================
    -- func_ascii_to_nibble
    -- Description: Convert an ASCII hex character (0-9, A-F, a-f) to a 4-bit nibble.
    -- =================================================================================================================
    function func_ascii_to_nibble (ascii_byte : std_logic_vector(8 - 1 downto 0)) return std_logic_vector is
    begin

        -- vsg_off
        case ascii_byte is
            -- '0'..'9'
            when x"30" => return x"0";
            when x"31" => return x"1";
            when x"32" => return x"2";
            when x"33" => return x"3";
            when x"34" => return x"4";
            when x"35" => return x"5";
            when x"36" => return x"6";
            when x"37" => return x"7";
            when x"38" => return x"8";
            when x"39" => return x"9";
            -- 'A'..'F'
            when x"41" => return x"A";
            when x"42" => return x"B";
            when x"43" => return x"C";
            when x"44" => return x"D";
            when x"45" => return x"E";
            when x"46" => return x"F";
            when others => return x"0"; -- Default to 0 on unexpected input
        end case;
        -- vsg_on
    end function;

    -- =================================================================================================================
    -- proc_send_byte
    -- Description: This procedure sends a single byte over the UART interface.
    --              Uses LSB-first data bit order (typical UART).
    -- =================================================================================================================
    procedure proc_send_byte (
        signal uart_line      : out std_logic;
        constant byte_to_send : std_logic_vector(8 - 1 downto 0)) is
    begin
        -- Start bit (low)
        uart_line <= '0';
        wait for C_BIT_TIME;

        -- Data bits (LSB first)
        for bit_idx in 0 to 7 loop
            uart_line <= byte_to_send(bit_idx);
            wait for C_BIT_TIME;
        end loop;

        -- Stop bit (high)
        uart_line <= '1';
        wait for C_BIT_TIME;
    end procedure;

begin

    p_read_write : process (all) is
    begin

        case current_state is

            when STATE_IDLE =>

            when STATE_READ =>

            when STATE_WRITE =>

        end case;

    end process p_read_write;

end architecture UART_MODEL_ARCH;
