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
-- @file    tb_spi_master.vhd
-- @version 1.0
-- @brief   SPI master testbench
-- @author  Timothee Charrier
-- @date    01/12/2025
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library lib_rtl;

library vunit_lib;
    context vunit_lib.vunit_context;
    context vunit_lib.com_context;
    use vunit_lib.stream_slave_pkg.all;

library osvvm;
    use osvvm.randompkg.randomptype;

library lib_bench;
    use lib_bench.spi_pkg.all;
    use lib_bench.tb_spi_master_pkg.all;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity TB_SPI_MASTER is
    generic (
        RUNNER_CFG     : string;
        G_CLK_POLARITY : std_logic;
        G_CLK_PHASE    : std_logic
    );
end entity TB_SPI_MASTER;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================

architecture TB_SPI_MASTER_ARCH of TB_SPI_MASTER is

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    constant C_SLAVE_SPI        : spi_slave_t    := new_spi_slave(
            cpol_mode => G_CLK_POLARITY,
            cpha_mode => G_CLK_PHASE
        );
    constant C_SLAVE_STREAM     : stream_slave_t := as_stream(C_SLAVE_SPI);

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- DUT signals
    signal tb_clk               : std_logic;
    signal tb_rst_n             : std_logic;
    signal tb_o_sclk            : std_logic;
    signal tb_o_mosi            : std_logic;
    signal tb_i_miso            : std_logic;
    signal tb_o_cs_n            : std_logic;
    signal tb_i_tx_data         : std_logic_vector(C_NB_DATA_BITS - 1 downto 0);
    signal tb_i_tx_data_valid   : std_logic;
    signal tb_o_rx_data         : std_logic_vector(C_NB_DATA_BITS - 1 downto 0);
    signal tb_o_rx_data_valid   : std_logic;

    signal tb_random_data       : std_logic_vector(C_NB_DATA_BITS - 1 downto 0);

    signal tb_check_spi_timings : std_logic;

begin

    -- =================================================================================================================
    -- DUT
    -- =================================================================================================================

    dut : entity lib_rtl.spi_master
        generic map (
            G_CLK_FREQ_HZ  => C_CLK_FREQ_HZ,
            G_SPI_FREQ_HZ  => C_SPI_FREQ_HZ,
            G_NB_DATA_BITS => C_NB_DATA_BITS,
            G_CLK_POLARITY => G_CLK_POLARITY,
            G_CLK_PHASE    => G_CLK_PHASE
        )
        port map (
            CLK             => tb_clk,
            RST_N           => tb_rst_n,
            O_SCLK          => tb_o_sclk,
            O_MOSI          => tb_o_mosi,
            I_MISO          => tb_i_miso,
            O_CS_N          => tb_o_cs_n,
            I_TX_DATA       => tb_i_tx_data,
            I_TX_DATA_VALID => tb_i_tx_data_valid,
            O_RX_DATA       => tb_o_rx_data,
            O_RX_DATA_VALID => tb_o_rx_data_valid
        );

    -- =================================================================================================================
    -- SPI slave model
    -- =================================================================================================================

    inst_spi_slave_model : entity lib_bench.spi_slave_model
        generic map (
            SPI => C_SLAVE_SPI
        )
        port map (
            sclk => tb_o_sclk,
            ss_n => tb_o_cs_n,
            mosi => tb_o_mosi,
            miso => tb_i_miso
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
    -- SPI TIMINGS VERIFICATION
    -- =================================================================================================================

    p_check_spi_timings : process is

        variable v_start_time     : time;
        variable v_start_bit_time : time;

    begin
        wait until rising_edge(tb_check_spi_timings);

        info("");
        info("Checking SPI timings.");

        -- For each bit
        for bits in 1 to 8 loop

            if ((G_CLK_PHASE = '0') and (G_CLK_POLARITY = '0')) then
                wait until rising_edge(tb_o_sclk);
            elsif ((G_CLK_PHASE = '0') and (G_CLK_POLARITY = '1')) then
                wait until falling_edge(tb_o_sclk);
            elsif ((G_CLK_PHASE = '1') and (G_CLK_POLARITY = '0')) then
                wait until falling_edge(tb_o_sclk);
            elsif ((G_CLK_PHASE = '1') and (G_CLK_POLARITY = '1')) then
                wait until rising_edge(tb_o_sclk);
            end if;

            if (bits = 1) then
                v_start_time     := now;
                v_start_bit_time := now;
            else
                proc_check_time_in_range(now - v_start_bit_time, C_BIT_TIME, C_BIT_TIME_ACCURACY);
                v_start_bit_time := now;
            end if;

        end loop;

        -- We can only check 7 periods
        proc_check_time_in_range(now - v_start_time, 7 * C_BIT_TIME, 7 * C_BIT_TIME_ACCURACY);

    end process p_check_spi_timings;

    -- =================================================================================================================
    -- TESTBENCH PROCESS
    -- =================================================================================================================

    p_test_runner : process is

        variable v_spi_slave_data : std_logic_vector(tb_i_tx_data'range);
        variable v_random_data    : randomptype;

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
            tb_rst_n             <= '0';
            tb_i_tx_data         <= (others => '0');
            tb_i_tx_data_valid   <= '0';
            tb_random_data       <= (others => '0');
            tb_check_spi_timings <= '0';

            wait for c_clock_cycles * C_CLK_PERIOD;

            -- Reassert reset
            tb_rst_n             <= '1';

            -- Wait for the DUT to step over
            wait for 5 ns;

            -- Log the reset action
            info("");
            info("DUT has been reset.");

        end procedure proc_reset_dut;

        -- =============================================================================================================
        -- proc_spi_write
        -- Description: Writes a byte value to the SPI master module.
        --
        -- Parameters:
        --   value - 8-bit data to transmit via SPI
        --
        -- Example:
        --   proc_spi_write(x"AB");
        --
        -- Notes:
        --  - This procedure applies the data on I_TX_BYTE and pulses I_TX_BYTE_VALID.
        --  - Appropriate setup and hold times are observed.
        -- =============================================================================================================

        procedure proc_spi_write (
            constant value : std_logic_vector(8 - 1 downto 0)
        ) is
        begin

            info("Sending value 0x" & to_hstring(value) & " to SPI master");

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

        end procedure proc_spi_write;

        -- =============================================================================================================
        -- proc_spi_check
        -- Description: Writes a value to SPI master and verifies correct transmission and reception.
        --
        -- Parameters:
        --   value - 8-bit data to transmit and verify
        --
        -- Example:
        --   proc_spi_check(x"CD");
        --
        -- Notes:
        --  - This procedure verifies both MOSI (master output) and MISO (master input) paths.
        --  - Uses VUnit stream verification for MOSI path.
        --  - Directly checks O_RX_BYTE for MISO path.
        -- =============================================================================================================

        procedure proc_spi_check (
            constant value : std_logic_vector(8 - 1 downto 0)
        ) is
        begin

            info("");
            info("Checking SPI transaction is correct.");

            proc_spi_write(value);

            -- Retrieve data from SPI slave stream (MOSI path verification)
            pop_stream(net, C_SLAVE_STREAM, v_spi_slave_data);

            -- Verify MOSI path
            check_equal(v_spi_slave_data, value,
                "MOSI Verification: Slave received correct data from Master");

            -- Verify MISO path
            check_equal(tb_o_rx_data, value,
                "MISO Verification: Master received correct data from Slave");

        end procedure proc_spi_check;

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
                info(" Testing incrementing data value from 0x00 to 0xFF for SPI");
                info("-----------------------------------------------------------------------------");

                for value in 0 to 2 ** C_NB_DATA_BITS - 1 loop
                    proc_spi_check(std_logic_vector(to_unsigned(value, C_NB_DATA_BITS)));
                end loop;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Testing random data for SPI");
                info("-----------------------------------------------------------------------------");

                for nb_loop in 0 to 2 ** C_NB_DATA_BITS - 1 loop
                    tb_random_data <= v_random_data.RandSlv(tb_random_data'length);
                    proc_spi_check(tb_random_data);
                end loop;

            elsif (run("test_spi_timings")) then

                -- Reset values
                proc_reset_dut;
                wait for 10 us;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Testing SPI timings");
                info("-----------------------------------------------------------------------------");

                tb_check_spi_timings <= '1';
                wait for 2 * C_CLK_PERIOD;
                tb_check_spi_timings <= '0';
                proc_spi_write(x"55");

                wait for C_SPI_TRANSACTION_TIME;

                tb_check_spi_timings <= '1';
                wait for 2 * C_CLK_PERIOD;
                tb_check_spi_timings <= '0';
                proc_spi_write(x"AB");

                wait for C_SPI_TRANSACTION_TIME;

            elsif (run("test_spi_configuration")) then

                -- Reset values
                proc_reset_dut;
                wait for 10 us;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Testing SPI default clock polarity value");
                info("-----------------------------------------------------------------------------");

                check_equal(tb_o_sclk, G_CLK_POLARITY, "Checking clock polarity when idle.");

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Ensure data remains stable if rx_data_valid is not de-asserted");
                info("-----------------------------------------------------------------------------");

                -- Reset values
                proc_reset_dut;
                wait for 10 us;

                info("Sending value 0x6E to SPI master");

                -- Ensure valid is low
                tb_i_tx_data_valid <= '0';
                wait for 2 * C_CLK_PERIOD;

                -- Apply data
                tb_i_tx_data <= x"6E";
                wait for C_CLK_PERIOD;

                -- Pulse valid signal
                tb_i_tx_data_valid <= '1';
                wait for 2 * C_CLK_PERIOD;

                wait for 3 * C_SPI_TRANSACTION_TIME;

                -- Verify o_mosi, rx_data and rx_data_valid remain stable
                check_equal(tb_o_mosi'stable(2 * C_SPI_TRANSACTION_TIME),    True, "O_MISO must remain stable");
                check_equal(tb_o_rx_data'stable(2 * C_SPI_TRANSACTION_TIME), True, "O_RX_DATA must remain stable");
                check_equal(
                    tb_o_rx_data_valid'stable(2 * C_SPI_TRANSACTION_TIME),
                    True,
                    "O_RX_DATA_VALID must remain stable");

            end if;

        end loop;

        -- End simulation
        test_runner_cleanup(runner);

    end process p_test_runner;

end architecture TB_SPI_MASTER_ARCH;
