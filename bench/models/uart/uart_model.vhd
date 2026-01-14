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
-- @file    uart_model.vhd
-- @version 1.1
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
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      21/10/2025  Timothee Charrier   Initial release
-- 1.1      12/10/2025  Timothee Charrier   Naming conventions update
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;

library vunit_lib;
    context vunit_lib.vunit_context;
    context vunit_lib.vc_context;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity UART_MODEL is
    generic (
        G_BAUD_RATE_BPS : positive := 115_200 -- Baud rate
    );
    port (
        -- UART interface
        I_UART_RX         : in    std_logic;
        O_UART_TX         : out   std_logic;
        -- Read interface
        I_READ_ADDR       : in    std_logic_vector( 8 - 1 downto 0);
        I_READ_ADDR_VALID : in    std_logic;
        -- vsg_disable_next_line port_012 : In a model, default value is fine
        O_READ_DATA       : out   std_logic_vector(16 - 1 downto 0) := (others => '0');
        O_READ_DATA_VALID : out   std_logic;
        -- Write interface
        I_WRITE_ADDRESS   : in    std_logic_vector( 8 - 1 downto 0);
        I_WRITE_DATA      : in    std_logic_vector(16 - 1 downto 0);
        I_WRITE_VALID     : in    std_logic
    );
end entity UART_MODEL;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================

architecture UART_MODEL_ARCH of UART_MODEL is

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- Characters
    constant C_CHAR_CR            : std_logic_vector(8 - 1 downto 0) := x"0D"; -- Carriage return character
    constant C_CHAR_R             : std_logic_vector(8 - 1 downto 0) := x"52"; -- 'R' character
    constant C_CHAR_W             : std_logic_vector(8 - 1 downto 0) := x"57"; -- 'W' character

    -- UART Slave BFM instance
    constant C_UART_BFM_SLAVE     : uart_slave_t   := new_uart_slave(
            initial_baud_rate => G_BAUD_RATE_BPS,
            data_length       => 8
        );
    constant C_UART_STREAM_SLAVE  : stream_slave_t := as_stream(C_UART_BFM_SLAVE);

    -- UART Master BFM instance
    constant C_UART_BFM_MASTER    : uart_master_t   := new_uart_master(
            initial_baud_rate => G_BAUD_RATE_BPS
        );
    constant C_UART_STREAM_MASTER : stream_master_t := as_stream(C_UART_BFM_MASTER);

    function func_hex_to_ascii_representation (
        hex_char : std_logic_vector
    ) return std_logic_vector is
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

    function func_ascii_to_nibble (
        ascii_byte : std_logic_vector
    ) return std_logic_vector is
    begin

        -- vsg_off
        case ascii_byte is
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
            when x"41" => return x"A";
            when x"42" => return x"B";
            when x"43" => return x"C";
            when x"44" => return x"D";
            when x"45" => return x"E";
            when x"46" => return x"F";
            when x"61" => return x"A";
            when x"62" => return x"B";
            when x"63" => return x"C";
            when x"64" => return x"D";
            when x"65" => return x"E";
            when x"66" => return x"F";
            when others => return x"0"; -- Default to 0 on unexpected input
        end case;
        -- vsg_on
    end function;

begin

    -- =================================================================================================================
    -- UART MASTER
    -- =================================================================================================================

    inst_uart_master : entity vunit_lib.uart_master
        generic map (
            UART => C_UART_BFM_MASTER
        )
        port map (
            tx => O_UART_TX
        );

    -- =================================================================================================================
    -- UART SLAVE
    -- =================================================================================================================

    inst_uart_slave : entity vunit_lib.uart_slave
        generic map (
            UART => C_UART_BFM_SLAVE
        )
        port map (
            rx => I_UART_RX
        );

    -- =================================================================================================================
    -- Write process: send "W" AA DDDD "\r", no response expected
    -- =================================================================================================================

    p_write : process is
    begin

        wait until rising_edge(I_WRITE_VALID);

        -- Send 'W'
        push_stream(net, C_UART_STREAM_MASTER, C_CHAR_W);

        -- Send address (2 ASCII hex characters MSB-first)
        push_stream(net, C_UART_STREAM_MASTER, func_hex_to_ascii_representation(I_WRITE_ADDRESS(7 downto 4)));
        push_stream(net, C_UART_STREAM_MASTER, func_hex_to_ascii_representation(I_WRITE_ADDRESS(3 downto 0)));

        -- Send data (4 ASCII hex characters MSB-first)
        push_stream(net, C_UART_STREAM_MASTER, func_hex_to_ascii_representation(I_WRITE_DATA(15 downto 12)));
        push_stream(net, C_UART_STREAM_MASTER, func_hex_to_ascii_representation(I_WRITE_DATA(11 downto  8)));
        push_stream(net, C_UART_STREAM_MASTER, func_hex_to_ascii_representation(I_WRITE_DATA( 7 downto  4)));
        push_stream(net, C_UART_STREAM_MASTER, func_hex_to_ascii_representation(I_WRITE_DATA( 3 downto  0)));

        -- Send carriage return
        push_stream(net, C_UART_STREAM_MASTER, C_CHAR_CR);

    end process p_write;

    -- =================================================================================================================
    -- Read process: send "R" AA "\r", then parse 4 ASCII hex chars (DDDD) then CR
    -- =================================================================================================================

    p_read : process is

        variable v_byte : std_logic_vector( 7 downto 0);
        variable v_last : boolean;
        variable v_data : std_logic_vector(15 downto 0);

    begin

        O_READ_DATA_VALID <= '0';

        -- Wait for rising edge of the valid signal
        wait until rising_edge(I_READ_ADDR_VALID);

        -- Send 'R'
        push_stream(net, C_UART_STREAM_MASTER, C_CHAR_R);

        -- Send address (MSB nibble then LSB nibble)
        push_stream(net, C_UART_STREAM_MASTER, func_hex_to_ascii_representation(I_READ_ADDR(7 downto 4)));
        push_stream(net, C_UART_STREAM_MASTER, func_hex_to_ascii_representation(I_READ_ADDR(3 downto 0)));

        -- Send carriage return
        push_stream(net, C_UART_STREAM_MASTER, C_CHAR_CR);

        -- Get the 4 ASCII characters for the 16-bit data value
        for char in 0 to 3 loop

            pop_stream(net, C_UART_STREAM_SLAVE, v_byte, v_last);
            v_data(15 - 4 * char downto 12 - 4 * char) := func_ascii_to_nibble(v_byte);

        end loop;

        -- Check last value if CR
        pop_stream(net, C_UART_STREAM_SLAVE, v_byte, v_last);

        if (v_byte = C_CHAR_CR) then
            O_READ_DATA       <= v_data;
            O_READ_DATA_VALID <= '1';
        end if;

        wait for 100 ns;

    end process p_read;

end architecture UART_MODEL_ARCH;
