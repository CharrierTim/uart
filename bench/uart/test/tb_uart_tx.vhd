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
-- @file    tb_uart_tx.vhd
-- @version 2.0
-- @brief   UART TX Testbench.
-- @author  Timothee Charrier
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      28/11/2025  Timothee Charrier   Initial release
-- 1.1      10/12/2025  Timothee Charrier   Naming conventions update
-- 2.0      12/01/2026  Timothee Charrier   Convert reset signal from active-low to active-high
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

entity TB_UART_TX is
    generic (
        RUNNER_CFG : string
    );
end entity TB_UART_TX;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================

architecture TB_UART_TX_ARCH of TB_UART_TX is

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- UART Slave BFM instance
    constant C_UART_BFM_SLAVE       : uart_slave_t   := new_uart_slave(
            initial_baud_rate => C_BAUD_RATE_BPS,
            data_length       => 8
        );
    constant C_UART_STREAM_SLAVE    : stream_slave_t := as_stream(C_UART_BFM_SLAVE);

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- DUT signals
    signal tb_clk                   : std_logic;
    signal tb_rst_h                 : std_logic;
    signal tb_i_tx_data             : std_logic_vector(8 - 1 downto 0);
    signal tb_i_tx_data_valid       : std_logic;
    signal tb_o_uart_tx             : std_logic;
    signal tb_o_done                : std_logic;

    signal tb_check_uart_tx_timings : std_logic;
    signal tb_random_data           : std_logic_vector(8 - 1 downto 0);

begin

    -- =================================================================================================================
    -- DUT
    -- =================================================================================================================

    dut : entity lib_rtl.uart_tx
        generic map (
            G_CLK_FREQ_HZ   => C_CLK_FREQ_HZ,
            G_BAUD_RATE_BPS => C_BAUD_RATE_BPS
        )
        port map (
            CLK             => tb_clk,
            RST_P           => tb_rst_h,
            I_TX_DATA       => tb_i_tx_data,
            I_TX_DATA_VALID => tb_i_tx_data_valid,
            O_UART_TX       => tb_o_uart_tx,
            O_DONE          => tb_o_done
        );

    -- =================================================================================================================
    -- UART slave model
    -- =================================================================================================================

    inst_uart_slave : entity vunit_lib.uart_slave
        generic map (
            UART => C_UART_BFM_SLAVE
        )
        port map (
            rx => tb_o_uart_tx
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
    -- UART TX TIMINGS VERIFICATION
    -- =================================================================================================================

    p_check_uart_tx_timings : process is

        variable v_start_time     : time;
        variable v_start_bit_time : time;

    begin
        wait until rising_edge(tb_check_uart_tx_timings);

        info("");
        info("Checking UART TX timings with input data set to 0x55.");

        -- Wait for the start bit
        wait until falling_edge(tb_o_uart_tx);
        v_start_bit_time := now;
        v_start_time     := now;

        wait until rising_edge(tb_o_uart_tx);
        proc_check_time_in_range(now - v_start_bit_time, C_BIT_TIME, C_BIT_TIME_ACCURACY);
        v_start_bit_time := now;

        wait until falling_edge(tb_o_uart_tx);
        proc_check_time_in_range(now - v_start_bit_time, C_BIT_TIME, C_BIT_TIME_ACCURACY);
        v_start_bit_time := now;

        wait until rising_edge(tb_o_uart_tx);
        proc_check_time_in_range(now - v_start_bit_time, C_BIT_TIME, C_BIT_TIME_ACCURACY);
        v_start_bit_time := now;

        wait until falling_edge(tb_o_uart_tx);
        proc_check_time_in_range(now - v_start_bit_time, C_BIT_TIME, C_BIT_TIME_ACCURACY);
        v_start_bit_time := now;

        wait until rising_edge(tb_o_uart_tx);
        proc_check_time_in_range(now - v_start_bit_time, C_BIT_TIME, C_BIT_TIME_ACCURACY);
        v_start_bit_time := now;

        wait until falling_edge(tb_o_uart_tx);
        proc_check_time_in_range(now - v_start_bit_time, C_BIT_TIME, C_BIT_TIME_ACCURACY);
        v_start_bit_time := now;

        wait until rising_edge(tb_o_uart_tx);
        proc_check_time_in_range(now - v_start_bit_time, C_BIT_TIME, C_BIT_TIME_ACCURACY);
        v_start_bit_time := now;

        -- We can only check 7 periods
        proc_check_time_in_range(now - v_start_time, 7 * C_BIT_TIME, 7 * C_BIT_TIME_ACCURACY);

    end process p_check_uart_tx_timings;

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
            tb_rst_h                 <= '1';
            tb_i_tx_data             <= (others => '0');
            tb_i_tx_data_valid       <= '0';
            tb_check_uart_tx_timings <= '0';

            wait for c_clock_cycles * C_CLK_PERIOD;

            -- Reassert reset
            tb_rst_h                 <= '0';

            -- Wait for the DUT to step over
            wait for 5 ns;

            -- Log the reset action
            info("");
            info("DUT has been reset.");

        end procedure proc_reset_dut;

        -- =============================================================================================================
        -- proc_uart_write
        -- Description: Writes a byte value to the UART TX module.
        --
        -- Parameters:
        --   value - 8-bit data to transmit via UART
        --
        -- Example:
        --   proc_uart_write(x"AB");
        -- =============================================================================================================

        procedure proc_uart_write (
            constant value : std_logic_vector(8 - 1 downto 0)
        ) is
        begin

            info("Sending value 0x" & to_hstring(value) & " to UART TX");

            -- Ensure valid is low
            tb_i_tx_data_valid <= '0';
            wait for 2 * C_CLK_PERIOD;

            -- Apply data
            tb_i_tx_data       <= value;
            wait for C_CLK_PERIOD;

            -- Pulse valid signal
            tb_i_tx_data_valid <= '1';
            wait for 2 * C_CLK_PERIOD;
            tb_i_tx_data_valid <= '0';

        end procedure proc_uart_write;

        -- =============================================================================================================
        -- proc_uart_check
        -- Description: Writes a value to UART TX and verifies correct transmission and reception.
        --
        -- Parameters:
        --   value - 8-bit data to transmit and verify
        --
        -- Example:
        --   proc_uart_check(x"CD");
        -- =============================================================================================================

        procedure proc_uart_check (
            constant value : std_logic_vector(8 - 1 downto 0)
        ) is
            variable v_byte : std_logic_vector(tb_i_tx_data'range);
            variable v_last : boolean;
        begin

            info("");
            info("Checking UART TX transmission is correct.");

            proc_uart_write(value);
            wait until rising_edge(tb_o_done);

            -- Receive UART TX byte
            pop_stream(net, C_UART_STREAM_SLAVE, v_byte, v_last);

            -- Verify data are matching
            check_equal(
                v_byte,
                value,
                "Checking decoded data");

        end procedure proc_uart_check;

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

            if run("test_push_and_pop") then

                -- Reset values
                proc_reset_dut;
                wait for 10 us;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Testing incrementing data value from 0x00 to 0xFF for UART TX");
                info("-----------------------------------------------------------------------------");

                for value in 0 to 2 ** tb_i_tx_data'length - 1 loop
                    proc_uart_check(std_logic_vector(to_unsigned(value, tb_i_tx_data'length)));
                end loop;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Testing random data for UART TX");
                info("-----------------------------------------------------------------------------");

                for nb_loop in 0 to 2 ** tb_i_tx_data'length - 1 loop
                    tb_random_data <= v_random_data.RandSlv(tb_random_data'length);
                    proc_uart_check(tb_random_data);
                end loop;

            elsif (run("test_uart_tx_timings")) then

                -- Reset values
                proc_reset_dut;
                wait for 10 us;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Testing UART timings");
                info("-----------------------------------------------------------------------------");

                proc_uart_write(x"55");
                tb_check_uart_tx_timings <= '1';
                wait for 2 * C_CLK_PERIOD;
                tb_check_uart_tx_timings <= '0';

                wait for C_UART_TRANSACTION_TIME;

            end if;

        end loop;

        -- End simulation
        test_runner_cleanup(runner);

    end process p_test_runner;

end architecture TB_UART_TX_ARCH;
