-- =====================================================================================================================
--  MIT License
--
--  Copyright (c) 2025 Timothée Charrier
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
-- @file    tb_uart.vhd
-- @version 1.0
-- @brief   Testbench for UART module
-- @author  Timothee Charrier
-- @date    10/10/2025
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library lib_rtl;

library vunit_lib;
    context vunit_lib.vunit_context;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity TB_UART is
    generic (
        RUNNER_CFG : string
    );
end entity TB_UART;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================

architecture TB_UART_ARCH of TB_UART is

    -- =================================================================================================================
    -- TYPES
    -- =================================================================================================================

    type t_rx_message is record
        string_addr : string(1 to 2);                    -- Address in hex (2 characters)
        string_data : string(1 to 4);                    -- Data in hex (4 characters
        slv_addr    : std_logic_vector(8  - 1 downto 0); -- Address as std_logic_vector
        slv_data    : std_logic_vector(16 - 1 downto 0); -- Data as std_logic_vector
    end record t_rx_message;

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- Clock period for the testbench
    constant C_FREQ_HZ              : positive := 50_000_000;
    constant C_CLK_PERIOD           : time     := 1 sec / C_FREQ_HZ;

    -- DUT generics
    constant C_CLK_FREQ_HZ          : positive := 50_000_000;
    constant C_BAUD_RATE_BPS        : positive := 115_200;
    constant C_PARITY               : string   := "NONE";

    -- RX message
    constant C_RX_MESSAGE_1         : t_rx_message :=
    (
        string_addr => "05",
        string_data => "ABCD",
        slv_addr    => x"05",
        slv_data    => x"ABCD"
    );

    constant C_RX_MESSAGE_2         : t_rx_message :=
    (
        string_addr => "FF",
        string_data => "1234",
        slv_addr    => x"FF",
        slv_data    => x"1234"
    );

    constant C_RX_MESSAGE_3         : t_rx_message :=
    (
        string_addr => "1A",
        string_data => "5678",
        slv_addr    => x"1A",
        slv_data    => x"5678"
    );

    constant C_RX_MESSAGE_ALL_ZEROS : t_rx_message :=
    (
        string_addr => "00",
        string_data => "0000",
        slv_addr    => x"00",
        slv_data    => x"0000"
    );

    constant C_RX_MESSAGE_ALL_ONES  : t_rx_message :=
    (
        string_addr => "FF",
        string_data => "FFFF",
        slv_addr    => x"FF",
        slv_data    => x"FFFF"
    );

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- dut signals
    signal tb_clk                   : std_logic;
    signal tb_rst_n                 : std_logic;
    signal tb_i_uart_rx             : std_logic;
    signal tb_o_uart_tx             : std_logic;
    signal tb_o_read_addr           : std_logic_vector(8 - 1 downto 0);
    signal tb_i_read_data           : std_logic_vector(8 - 1 downto 0);
    signal tb_i_read_data_valid     : std_logic;
    signal tb_o_addr                : std_logic_vector(8 - 1 downto 0);
    signal tb_o_write_data          : std_logic_vector(16 - 1 downto 0);
    signal tb_o_write_valid         : std_logic;

    -- =================================================================================================================
    -- FUNCTIONS
    -- =================================================================================================================

    -- Convert a hex character ('0'-'9', 'A'-'F', 'a'-'f') to its ASCII std_logic_vector representation
    function hex_char_to_ascii (hex_char : character) return std_logic_vector is
    begin

                -- vsg_off
                case hex_char is
                    when '0'       => return x"30";
                    when '1'       => return x"31";
                    when '2'       => return x"32";
                    when '3'       => return x"33";
                    when '4'       => return x"34";
                    when '5'       => return x"35";
                    when '6'       => return x"36";
                    when '7'       => return x"37";
                    when '8'       => return x"38";
                    when '9'       => return x"39";
                    when 'A' | 'a' => return x"41";
                    when 'B' | 'b' => return x"42";
                    when 'C' | 'c' => return x"43";
                    when 'D' | 'd' => return x"44";
                    when 'E' | 'e' => return x"45";
                    when 'F' | 'f' => return x"46";
                    when others    => return x"30"; -- Default to '0'
                end case;
                -- vsg_on
    end function;

begin

    -- =================================================================================================================
    -- DUT
    -- =================================================================================================================

    dut : entity lib_rtl.uart
        generic map (
            G_CLK_FREQ_HZ   => C_CLK_FREQ_HZ,
            G_BAUD_RATE_BPS => C_BAUD_RATE_BPS,
            G_PARITY        => C_PARITY
        )
        port map (
            CLK               => tb_clk,
            RST_N             => tb_rst_n,
            I_UART_RX         => tb_i_uart_rx,
            O_UART_TX         => tb_o_uart_tx,
            O_READ_ADDR       => tb_o_read_addr,
            I_READ_DATA       => tb_i_read_data,
            I_READ_DATA_VALID => tb_i_read_data_valid,
            O_WRITE_ADDR      => tb_o_addr,
            O_WRITE_DATA      => tb_o_write_data,
            O_WRITE_VALID     => tb_o_write_valid
        );

    -- =================================================================================================================
    -- CLK GENERATION
    -- =================================================================================================================

    p_clock_gen : process is
    begin
        tb_clk <= '0';

        l_clock_gen : loop
            wait for C_CLK_PERIOD / 2;
            tb_clk <= '1';
            wait for C_CLK_PERIOD / 2;
            tb_clk <= '0';
        end loop l_clock_gen;

    end process p_clock_gen;

    -- =================================================================================================================
    -- TESTBENCH PROCESS
    -- =================================================================================================================

    p_test_runner : process is

        -- =============================================================================================================
        -- proc_reset_dut
        -- Description: This procedure resets the DUT to a know state.
        --
        -- Parameters:
        --   None
        --
        -- Example:
        --   proc_reset_dut;
        --
        -- Notes:
        --  - This procedure is called at the beginning of each test to ensure the DUT starts from a known state.
        -- =============================================================================================================
        procedure proc_reset_dut (
            constant c_clock_cycles : positive := 50) is
        begin

            -- Reset the DUT by setting the input state to all zeros
            tb_rst_n             <= '0';
            tb_i_uart_rx         <= '1';
            tb_i_READ_data       <= (others => '0');
            tb_i_READ_data_valid <= '0';

            wait for c_clock_cycles * C_CLK_PERIOD;

            -- Reassert reset
            tb_rst_n             <= '1';

            -- Wait for the DUT to step over a simulation step
            wait for 5 ns;

            -- Log the reset action
            info("DUT has been reset.");
            info("");

        end procedure;

        -- =============================================================================================================
        -- proc_send_byte
        -- Description: This procedure sends a single byte over the UART interface.
        --
        -- Parameters:
        --   uart_rx      : out std_logic                    - The UART RX line to drive.
        --   byte_to_send : std_logic_vector(8 - 1 downto 0) - The byte to send.
        --
        -- Example:
        --   proc_send_byte(tb_i_uart_rx, x"41"); -- Send ASCII 'A'
        --
        -- =============================================================================================================
        procedure proc_send_byte (
            signal uart_rx        : out std_logic;
            constant byte_to_send : std_logic_vector(8 - 1 downto 0)) is
        begin

            -- Start bit
            uart_rx <= '0';
            wait for 1 sec / C_BAUD_RATE_BPS;

            -- Data bits (MSB to LSB)
            for bit_idx in byte_to_send'range loop
                uart_rx <= byte_to_send(bit_idx);
                wait for 1 sec / C_BAUD_RATE_BPS;
            end loop;

            -- Stop bit
            uart_rx <= '1';
            wait for 1 sec / C_BAUD_RATE_BPS;
        end procedure;

        -- =============================================================================================================
        -- proc_uart_write
        -- Description: This procedure sends a write command over the UART interface.
        --
        -- Parameters:
        --   uart_rx      : out std_logic - The UART RX line to drive.
        --   addr         : string        - The address to write to as hex string (e.g., "01", "FF").
        --   data         : string        - The data to write as hex string (e.g., "ABCD", "1234").
        --
        -- Example:
        --   proc_uart_write(tb_i_uart_rx, "05", "ABCD"); -- Write data 0xABCD to address 0x05
        --
        -- =============================================================================================================
        procedure proc_uart_write (
            signal uart_rx : out std_logic;
            constant addr  : string(1 to 2);
            constant data  : string(1 to 4)) is
        begin

            info("");
            info("Sending UART write command: Address = 0x" & addr & ", Data = 0x" & data);

            -- Send 'W'
            proc_send_byte(uart_rx, x"57");

            -- Send address (convert each hex character to ASCII)
            for i in addr'range loop
                proc_send_byte(uart_rx, hex_char_to_ascii(addr(i)));
            end loop;

            -- Send data (convert each hex character to ASCII)
            for i in data'range loop
                proc_send_byte(uart_rx, hex_char_to_ascii(data(i)));
            end loop;

            -- Send carriage return and line feed
            proc_send_byte(uart_rx, x"0D");
            proc_send_byte(uart_rx, x"0A");

        end procedure;

        -- =============================================================================================================
        -- proc_uart_read
        -- Description: This procedure sends a read command over the UART interface.
        --
        -- Parameters:
        --   uart_rx      : out std_logic - The UART RX line to drive.
        --   addr         : string        - The address to read from as hex string (e.g., "01", "FF").
        --
        -- Example:
        --   proc_uart_read(tb_i_uart_rx, "05"); -- Read data from address 0x05
        --
        -- =============================================================================================================
        procedure proc_uart_read (
            signal uart_rx : out std_logic;
            constant addr  : string(1 to 2)) is
        begin

            info("");
            info("Sending UART read command: Address = 0x" & addr);

            -- Send 'R'
            proc_send_byte(uart_rx, x"52");

            -- Send address (convert each hex character to ASCII)
            for i in addr'range loop
                proc_send_byte(uart_rx, hex_char_to_ascii(addr(i)));
            end loop;

            -- Send carriage return and line feed
            proc_send_byte(uart_rx, x"0D");
            proc_send_byte(uart_rx, x"0A");

        end procedure;

    begin

        -- Set up the test runner
        test_runner_setup(runner, RUNNER_CFG);

        -- Show PASS log messages for checks
        show(get_logger(default_checker), display_handler, pass);

        -- Set time unit to ns for display handler
        set_format(display_handler, log_time_unit => ms);

        -- Disable stop on errors from my_logger and its children
        disable_stop(get_logger(default_checker), error);

        while test_suite loop

            if run("test_uart_decoder") then

                info("-----------------------------------------------------------------------------");
                info("TESTING UART DECODER");
                info("-----------------------------------------------------------------------------");

                -- Reset values
                proc_reset_dut;

                wait for 100 us;

                -- =====================================================================================================
                -- MESSAGE 1
                -- =====================================================================================================
                proc_uart_write(tb_i_uart_rx, C_RX_MESSAGE_1.string_addr, C_RX_MESSAGE_1.string_data);

                -- Check received address and data
                check_equal(
                    tb_o_addr,
                    C_RX_MESSAGE_1.slv_addr,
                    "Check write address");

                check_equal(
                    tb_o_write_data,
                    C_RX_MESSAGE_1.slv_data,
                    "Check write data   ");

                wait for 1 ms;
                -- =====================================================================================================
                -- MESSAGE 2
                -- =====================================================================================================
                proc_uart_write(tb_i_uart_rx, C_RX_MESSAGE_2.string_addr, C_RX_MESSAGE_2.string_data);

                -- Check received address and data
                check_equal(
                    tb_o_addr,
                    C_RX_MESSAGE_2.slv_addr,
                    "Check write address");

                check_equal(
                    tb_o_write_data,
                    C_RX_MESSAGE_2.slv_data,
                    "Check write data   ");

                wait for 1 ms;
                -- =====================================================================================================
                -- MESSAGE 3
                -- =====================================================================================================
                proc_uart_write(tb_i_uart_rx, C_RX_MESSAGE_3.string_addr, C_RX_MESSAGE_3.string_data);

                -- Check received address and data
                check_equal(
                    tb_o_addr,
                    C_RX_MESSAGE_3.slv_addr,
                    "Check write address");

                check_equal(
                    tb_o_write_data,
                    C_RX_MESSAGE_3.slv_data,
                    "Check write data   ");

                wait for 1 ms;
                -- =====================================================================================================
                -- MESSAGE ALL ZEROS
                -- =====================================================================================================
                proc_uart_write(tb_i_uart_rx, C_RX_MESSAGE_ALL_ZEROS.string_addr, C_RX_MESSAGE_ALL_ZEROS.string_data);

                -- Check received address and data
                check_equal(
                    tb_o_addr,
                    C_RX_MESSAGE_ALL_ZEROS.slv_addr,
                    "Check write address");

                check_equal(
                    tb_o_write_data,
                    C_RX_MESSAGE_ALL_ZEROS.slv_data,
                    "Check write data   ");

                wait for 1 ms;

                -- =====================================================================================================
                -- MESSAGE ALL ONES
                -- =====================================================================================================
                proc_uart_write(tb_i_uart_rx, C_RX_MESSAGE_ALL_ONES.string_addr, C_RX_MESSAGE_ALL_ONES.string_data);

                -- Check received address and data
                check_equal(
                    tb_o_addr,
                    C_RX_MESSAGE_ALL_ONES.slv_addr,
                    "Check write address");

                check_equal(
                    tb_o_write_data,
                    C_RX_MESSAGE_ALL_ONES.slv_data,
                    "Check write data   ");

                -- =====================================================================================================
                -- SEND READ COMMAND
                -- =====================================================================================================
                proc_uart_read(tb_i_uart_rx, C_RX_MESSAGE_1.string_addr);

            elsif run("testing invalid start and stop bits") then

                -- Reset values
                proc_reset_dut;
                wait for 100 us;

                info("-----------------------------------------------------------------------------");
                info("TESTING INVALID START BIT");
                info("-----------------------------------------------------------------------------");

                -- Send a byte (0xAB) with invalid start bit
                tb_i_uart_rx <= '0';
                wait for 0.25 sec / C_BAUD_RATE_BPS; -- Invalid start bit (too short)
                tb_i_uart_rx <= '1';                 -- Sudden change to high
                wait for 0.75 sec / C_BAUD_RATE_BPS; -- Complete the rest of the start bit duration
                tb_i_uart_rx <= '1';                 -- Bit 0
                wait for 1 sec / C_BAUD_RATE_BPS;
                tb_i_uart_rx <= '0';                 -- Bit 1
                wait for 1 sec / C_BAUD_RATE_BPS;
                tb_i_uart_rx <= '1';                 -- Bit 2
                wait for 1 sec / C_BAUD_RATE_BPS;
                tb_i_uart_rx <= '0';                 -- Bit 3
                wait for 1 sec / C_BAUD_RATE_BPS;
                tb_i_uart_rx <= '1';                 -- Bit 4
                wait for 1 sec / C_BAUD_RATE_BPS;
                tb_i_uart_rx <= '0';                 -- Bit 5
                wait for 1 sec / C_BAUD_RATE_BPS;
                tb_i_uart_rx <= '1';                 -- Bit 6
                wait for 1 sec / C_BAUD_RATE_BPS;
                tb_i_uart_rx <= '1';                 -- Bit 7
                wait for 1 sec / C_BAUD_RATE_BPS;
                tb_i_uart_rx <= '1';                 -- Stop bit
                wait for 1 sec / C_BAUD_RATE_BPS;

                -- Check no data is received due to start bit error
                wait for 10 us;
                check(
                    tb_o_write_valid = '0' and tb_o_write_valid'stable(9 * 1 sec / C_BAUD_RATE_BPS),
                    "Check no data received due to start bit error");

                -- Reset values
                proc_reset_dut;
                wait for 1 ms;

                info("-----------------------------------------------------------------------------");
                info("TESTING INVALID STOP BIT");
                info("-----------------------------------------------------------------------------");

                -- Send a byte (0x7C) with invalid stop bit
                tb_i_uart_rx <= '0'; -- Start bit
                wait for 1 sec / C_BAUD_RATE_BPS;
                tb_i_uart_rx <= '0'; -- Bit 0
                wait for 1 sec / C_BAUD_RATE_BPS;
                tb_i_uart_rx <= '1'; -- Bit 1
                wait for 1 sec / C_BAUD_RATE_BPS;
                tb_i_uart_rx <= '1'; -- Bit 2
                wait for 1 sec / C_BAUD_RATE_BPS;
                tb_i_uart_rx <= '1'; -- Bit 3
                wait for 1 sec / C_BAUD_RATE_BPS;
                tb_i_uart_rx <= '1'; -- Bit 4
                wait for 1 sec / C_BAUD_RATE_BPS;
                tb_i_uart_rx <= '1'; -- Bit 5
                wait for 1 sec / C_BAUD_RATE_BPS;
                tb_i_uart_rx <= '0'; -- Bit 6
                wait for 1 sec / C_BAUD_RATE_BPS;
                tb_i_uart_rx <= '0'; -- Bit 7
                wait for 1 sec / C_BAUD_RATE_BPS;
                tb_i_uart_rx <= '0'; -- Invalid stop bit (should be '1')
                wait for 1 sec / C_BAUD_RATE_BPS;

                -- Line goes back to idle
                wait for 5 us;
                tb_i_uart_rx <= '1';
                wait for 5 us;

                -- Check no data is received due to stop bit error
                check(
                    tb_o_write_valid = '0' and tb_o_write_valid'stable(9 * 1 sec / C_BAUD_RATE_BPS),
                    "Check no data received due to stop bit error");

            end if;

        end loop;

        -- End simulation
        test_runner_cleanup(runner);

    end process p_test_runner;

end architecture TB_UART_ARCH;
