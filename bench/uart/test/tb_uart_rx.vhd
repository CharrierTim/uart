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
-- @file    tb_uart_rx.vhd
-- @version 1.1
-- @brief   UART RX Testbench.
-- @author  Timothee Charrier
-- @date    10/12/2025
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      28/11/2025  Timothee Charrier   Initial release
-- 1.1      10/12/2025  Timothee Charrier   Naming conventions update and remove generic
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library lib_rtl;

library vunit_lib;
    context vunit_lib.vunit_context;
    context vunit_lib.vc_context;

library osvvm;
    use osvvm.randompkg.randomptype;

library lib_bench;
    use lib_bench.tb_uart_pkg.all;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity TB_UART_RX is
    generic (
        RUNNER_CFG : string
    );
end entity TB_UART_RX;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================

architecture TB_UART_RX_ARCH of TB_UART_RX is

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- UART Slave BFM instance
    constant C_UART_BFM_MASTER    : uart_master_t   := new_uart_master(
            initial_baud_rate => C_BAUD_RATE_BPS
        );
    constant C_UART_STREAM_MASTER : stream_master_t := as_stream(C_UART_BFM_MASTER);

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- DUT signals
    signal tb_clk                 : std_logic;
    signal tb_rst_n               : std_logic;
    signal tb_i_uart_rx           : std_logic;
    signal tb_o_byte              : std_logic_vector(C_NB_DATA_BITS - 1 downto 0);
    signal tb_o_byte_valid        : std_logic;
    signal tb_o_start_bit_error   : std_logic;
    signal tb_o_stop_bit_error    : std_logic;

    signal tb_i_uart_rx_manual    : std_logic;
    signal tb_model_uart_tx       : std_logic;
    signal tb_i_uart_select       : std_logic;
    signal tb_random_data         : std_logic_vector(tb_o_byte'range);

begin

    -- =================================================================================================================
    -- DUT
    -- =================================================================================================================

    dut : entity lib_rtl.uart_rx
        generic map (
            G_CLK_FREQ_HZ   => C_CLK_FREQ_HZ,
            G_BAUD_RATE_BPS => C_BAUD_RATE_BPS,
            G_SAMPLING_RATE => C_SAMPLING_RATE
        )
        port map (
            CLK               => tb_clk,
            RST_N             => tb_rst_n,
            I_UART_RX         => tb_i_uart_rx,
            O_BYTE            => tb_o_byte,
            O_BYTE_VALID      => tb_o_byte_valid,
            O_START_BIT_ERROR => tb_o_start_bit_error,
            O_STOP_BIT_ERROR  => tb_o_stop_bit_error
        );

    -- Select between manual RX input and model RX input
    tb_i_uart_rx <= tb_i_uart_rx_manual when tb_i_uart_select = '1' else
                    tb_model_uart_tx;

    -- =================================================================================================================
    -- UART master model
    -- =================================================================================================================

    inst_uart_master : entity vunit_lib.uart_master
        generic map (
            UART => C_UART_BFM_MASTER
        )
        port map (
            tx => tb_model_uart_tx
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

        variable v_random_data : randomptype;

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
            constant c_clock_cycles : positive := 50
        ) is
        begin

            -- Reset the DUT by setting the input state to all zeros
            tb_rst_n            <= '0';
            tb_i_uart_rx_manual <= '1';
            tb_i_uart_select    <= '0';
            tb_random_data      <= (others => '0');

            wait for c_clock_cycles * C_CLK_PERIOD;

            -- Reassert reset
            tb_rst_n            <= '1';

            -- Wait for the DUT to step over
            wait for 5 ns;

            -- Log the reset action
            info("");
            info("DUT has been reset.");

        end procedure proc_reset_dut;

        -- =============================================================================================================
        -- proc_uart_send_byte
        --
        -- Description: This procedure sends a byte ("manually") via the UART.
        --
        -- Parameters:
        --   byte : std_logic_vector - The byte to send.
        --
        -- Example:
        --   proc_uart_send_byte(uart_rx, x"30");
        -- =============================================================================================================

        procedure proc_uart_send_byte (
            signal   uart_rx      : out std_logic;
            constant byte_to_send : std_logic_vector(8 - 1 downto 0)
        ) is
        begin

            -- Select the manual UART
            if (tb_i_uart_select = '0') then
                tb_i_uart_select <= '1';
                wait for 200 ns;
            end if;

            -- Start bit
            uart_rx <= '0';
            wait for C_BIT_TIME;

            -- Data bits (LSB to MSB)
            for bit_idx in byte_to_send'low to byte_to_send'high loop
                uart_rx <= byte_to_send(bit_idx);
                wait for C_BIT_TIME;
            end loop;

            -- Stop bit
            uart_rx <= '1';
            wait until rising_edge(tb_o_byte_valid);

        end procedure proc_uart_send_byte;

        -- =============================================================================================================
        -- proc_uart_check
        -- Description: Writes a value to UART RX and verifies correct transmission and reception using the model.
        --
        -- Parameters:
        --   value - 8-bit data to transmit and verify
        --
        -- Example:
        --   proc_uart_check(x"CD");
        -- =============================================================================================================

        procedure proc_uart_send_and_check (
            constant value : std_logic_vector(8 - 1 downto 0)
        ) is
        begin

            info("");
            info("Sending value 0x" & to_hstring(value) & " with UART model.");

            push_stream(net, C_UART_STREAM_MASTER, value);
            wait for 1.5 * C_UART_TRANSACTION_TIME;

            -- Verify data are matching
            check_equal(
                tb_o_byte,
                value,
                "Checking received data");

        end procedure proc_uart_send_and_check;

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

            if run("test_uart_decode") then

                -- Reset values
                proc_reset_dut;
                wait for 10 us;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Testing incrementing data value from 0x00 to 0xFF for UART RX");
                info("-----------------------------------------------------------------------------");

                for value in 0 to 2 ** tb_o_byte'length - 1 loop
                    proc_uart_send_and_check(std_logic_vector(to_unsigned(value, tb_o_byte'length)));
                end loop;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Testing random data for UART RX");
                info("-----------------------------------------------------------------------------");

                for value in 0 to 2 ** tb_o_byte'length - 1 loop
                    tb_random_data <= v_random_data.RandSlv(tb_o_byte'length);
                    wait for C_BIT_TIME;
                    proc_uart_send_and_check(tb_random_data);
                end loop;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Manually sending byte");
                info("-----------------------------------------------------------------------------");

                for value in 0 to 2 ** tb_o_byte'length - 1 loop
                    tb_random_data <= v_random_data.RandSlv(tb_o_byte'length);
                    wait for C_BIT_TIME;
                    proc_uart_send_byte(tb_i_uart_rx_manual, tb_random_data);

                    -- Verify data are matching
                    check_equal(
                        tb_o_byte,
                        tb_random_data,
                        "Checking received data");
                end loop;

            elsif run("test_uart_robustness") then

                -- Reset values
                proc_reset_dut;
                wait for 10 us;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Testing incrementing data value from 0x00 to 0xFF for UART RX");
                info("-----------------------------------------------------------------------------");

                -- Reset DUT
                proc_reset_dut;
                wait for 100 us;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Sending bytes 0x00 with invalid start bit");
                info("-----------------------------------------------------------------------------");

                -- Select the manual UART
                tb_i_uart_select <= '1';

                -- Send a byte (0x00) with invalid start bit
                tb_i_uart_rx_manual <= '0';
                wait for 0.25 * C_BIT_TIME; -- Invalid start bit (too short)
                tb_i_uart_rx_manual <= '1'; -- Sudden change to high
                wait for 0.75 * C_BIT_TIME; -- Complete the rest of the start bit duration
                tb_i_uart_rx_manual <= '0'; -- Bit 0
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '0'; -- Bit 1
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '0'; -- Bit 2
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '0'; -- Bit 3
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '0'; -- Bit 4
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '0'; -- Bit 5
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '0'; -- Bit 6
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '0'; -- Bit 7
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '1'; -- Stop bit
                wait for 1.1 * C_BIT_TIME;

                -- Check data was not updated
                check_equal(
                    tb_o_byte_valid'stable(C_UART_TRANSACTION_TIME) and tb_o_byte'stable(C_UART_TRANSACTION_TIME),
                    True,
                    "Ensuring UART not updating output data with invalid start bit in char 'R'");

                info("Sending bytes 0x01 and 0x02 to ensure UART is still working");

                proc_uart_send_byte(tb_i_uart_rx_manual, x"01");
                check_equal(
                    tb_o_byte = x"01",
                    True,
                    "Checking received data is 0x02");

                proc_uart_send_byte(tb_i_uart_rx_manual, x"02");
                check_equal(
                    tb_o_byte = x"02",
                    True,
                    "Checking received data is 0x02");

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Sending bytes 0xE2 with invalid stop bit");
                info("-----------------------------------------------------------------------------");

                -- Reset DUT
                proc_reset_dut;
                wait for 10 us;

                -- Select the manual UART
                tb_i_uart_select <= '1';

                -- Send a byte (0xE2) with invalid stop bit
                tb_i_uart_rx_manual <= '0';
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '1'; -- Bit 0
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '1'; -- Bit 1
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '1'; -- Bit 2
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '0'; -- Bit 3
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '1'; -- Bit 4
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '0'; -- Bit 5
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '1'; -- Bit 6
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '0'; -- Bit 7
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '0'; -- Stop bit
                wait for 2 * C_BIT_TIME;
                tb_i_uart_rx_manual <= '1'; -- Bit 0

                -- Check data was not updated
                check_equal(
                    tb_o_byte_valid'stable(C_UART_TRANSACTION_TIME) and tb_o_byte'stable(C_UART_TRANSACTION_TIME),
                    True,
                    "Ensuring UART not updating output data with invalid start bit in char 'R'");

                -- Wait some time
                wait for C_UART_TRANSACTION_TIME;

                info("Sending bytes 0x01 and 0x02 to ensure UART is still working");

                proc_uart_send_byte(tb_i_uart_rx_manual, x"01");
                check_equal(
                    tb_o_byte = x"01",
                    True,
                    "Checking received data is 0x01");

                proc_uart_send_byte(tb_i_uart_rx_manual, x"02");
                check_equal(
                    tb_o_byte = x"02",
                    True,
                    "Checking received data 0x02");

            end if;

        end loop;

        -- End simulation
        test_runner_cleanup(runner);

    end process p_test_runner;

end architecture TB_UART_RX_ARCH;
