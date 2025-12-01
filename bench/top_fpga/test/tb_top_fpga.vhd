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
-- @file    top_fpga.vhd
-- @version 1.0
-- @brief   Top-Level Testbench
-- @author  Timothee Charrier
-- @date    20/10/2025
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library lib_rtl;
library lib_bench;
    use lib_bench.spi_pkg.all;
    use lib_bench.tb_top_fpga_pkg.all;

library vunit_lib;
    context vunit_lib.vunit_context;
    context vunit_lib.com_context;
    use vunit_lib.stream_slave_pkg.all;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity TB_TOP_FPGA is
    generic (
        RUNNER_CFG : string
    );
end entity TB_TOP_FPGA;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================

architecture TB_TOP_FPGA_ARCH of TB_TOP_FPGA is

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- DUT signals
    signal tb_pad_i_clk            : std_logic;
    signal tb_pad_i_rst_h          : std_logic;
    signal tb_pad_i_uart_rx        : std_logic;
    signal tb_pad_o_uart_tx        : std_logic;
    signal tb_pad_o_sclk           : std_logic;
    signal tb_pad_o_mosi           : std_logic;
    signal tb_pad_i_miso           : std_logic;
    signal tb_pad_o_cs             : std_logic;
    signal tb_pad_i_switch_0       : std_logic;
    signal tb_pad_i_switch_1       : std_logic;
    signal tb_pad_i_switch_2       : std_logic;
    signal tb_pad_o_led_0          : std_logic;

    -- UART model
    signal tb_i_uart_rx_manual     : std_logic;
    signal tb_i_uart_rx            : std_logic;
    signal tb_i_uart_select        : std_logic;
    signal tb_i_read_address       : std_logic_vector( 8 - 1 downto 0);
    signal tb_i_read_address_valid : std_logic;
    signal tb_o_read_data          : std_logic_vector(16 - 1 downto 0);
    signal tb_o_read_data_valid    : std_logic;
    signal tb_i_write_address      : std_logic_vector( 8 - 1 downto 0);
    signal tb_i_write_data         : std_logic_vector(16 - 1 downto 0);
    signal tb_i_write_valid        : std_logic;

    -- UART timing verification
    signal tb_check_uart_timings   : std_logic;

begin

    -- =================================================================================================================
    -- DUT
    -- =================================================================================================================

    dut : entity lib_rtl.top_fpga
        generic map (
            G_GIT_ID => C_GIT_ID
        )
        port map (
            PAD_I_CLK      => tb_pad_i_clk,
            PAD_I_RST_h    => tb_pad_i_rst_h,
            PAD_I_UART_RX  => tb_i_uart_rx,
            PAD_O_UART_TX  => tb_pad_o_uart_tx,
            PAD_O_SCLK     => tb_pad_o_sclk,
            PAD_O_MOSI     => tb_pad_o_mosi,
            PAD_I_MISO     => tb_pad_i_miso,
            PAD_O_CS       => tb_pad_o_cs,
            PAD_I_SWITCH_0 => tb_pad_i_switch_0,
            PAD_I_SWITCH_1 => tb_pad_i_switch_1,
            PAD_I_SWITCH_2 => tb_pad_i_switch_2,
            PAD_O_LED_0    => tb_pad_o_led_0
        );

    -- =================================================================================================================
    -- UART MODEL
    -- =================================================================================================================

    inst_uart_model : entity lib_bench.uart_model
        generic map (
            G_BAUD_RATE_BPS => C_BAUD_RATE_BPS
        )
        port map (
            I_UART_RX            => tb_pad_o_uart_tx,
            O_UART_TX            => tb_pad_i_uart_rx,
            I_READ_ADDRESS       => tb_i_read_address,
            I_READ_ADDRESS_VALID => tb_i_read_address_valid,
            O_READ_DATA          => tb_o_read_data,
            O_READ_DATA_VALID    => tb_o_read_data_valid,
            I_WRITE_ADDRESS      => tb_i_write_address,
            I_WRITE_DATA         => tb_i_write_data,
            I_WRITE_VALID        => tb_i_write_valid
        );

    -- Select between manual RX input and model RX input
    tb_i_uart_rx <= tb_i_uart_rx_manual when tb_i_uart_select = '1' else
                    tb_pad_i_uart_rx;

    -- =================================================================================================================
    -- SPI slave model
    -- =================================================================================================================

    inst_spi_slave_model : entity lib_bench.spi_slave_model
        generic map (
            SPI => C_SLAVE_SPI
        )
        port map (
            sclk => tb_pad_o_sclk,
            ss_n => tb_pad_o_cs,
            mosi => tb_pad_o_mosi,
            miso => tb_pad_i_miso
        );

    -- =================================================================================================================
    -- CLK GENERATION
    -- =================================================================================================================

    p_clock_gen : process is
    begin
        tb_pad_i_clk <= '0';

        l_clock_gen : loop
            wait for C_CLK_PERIOD / 2;
            tb_pad_i_clk <= '1';
            wait for C_CLK_PERIOD / 2;
            tb_pad_i_clk <= '0';
        end loop l_clock_gen;

    end process p_clock_gen;

    -- =================================================================================================================
    -- UART TIMINGS VERIFICATION
    -- =================================================================================================================

    p_check_uart_timings : process is

        variable v_start_time     : time;
        variable v_start_bit_time : time;

    begin

        wait until rising_edge(tb_check_uart_timings);

        info("Checking UART timings on TX with value 0x5555");

        -- For each byte
        for byte in 1 to 4 loop

            -- Wait for the start bit
            wait until falling_edge(tb_pad_o_uart_tx);
            v_start_bit_time := now;

            if (byte = 1) then
                v_start_time := now;
            end if;

            wait until rising_edge(tb_pad_o_uart_tx);
            proc_check_time_in_range(now - v_start_bit_time, C_BIT_TIME, C_BIT_TIME_ACCURACY);
            v_start_bit_time := now;

            wait until falling_edge(tb_pad_o_uart_tx);
            proc_check_time_in_range(now - v_start_bit_time, C_BIT_TIME, C_BIT_TIME_ACCURACY);
            v_start_bit_time := now;

            wait until rising_edge(tb_pad_o_uart_tx);
            proc_check_time_in_range(now - v_start_bit_time, C_BIT_TIME, C_BIT_TIME_ACCURACY);
            v_start_bit_time := now;

            wait until falling_edge(tb_pad_o_uart_tx);
            proc_check_time_in_range(now - v_start_bit_time, C_BIT_TIME, C_BIT_TIME_ACCURACY);
            v_start_bit_time := now;

            wait until rising_edge(tb_pad_o_uart_tx);
            proc_check_time_in_range(now - v_start_bit_time, C_BIT_TIME, C_BIT_TIME_ACCURACY);
            v_start_bit_time := now;

            wait until falling_edge(tb_pad_o_uart_tx);
            proc_check_time_in_range(now - v_start_bit_time, 2.0 * C_BIT_TIME, 2.0 * C_BIT_TIME_ACCURACY);
            v_start_bit_time := now;

            wait until rising_edge(tb_pad_o_uart_tx);
            proc_check_time_in_range(now - v_start_bit_time, 2.0 * C_BIT_TIME, 2.0 * C_BIT_TIME_ACCURACY);
            v_start_bit_time := now;

        end loop;

    end process p_check_uart_timings;

    -- =================================================================================================================
    -- TESTBENCH PROCESS
    -- =================================================================================================================

    p_test_runner : process is

        variable v_spi_slave_data : std_logic_vector(8 - 1 downto 0);

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
            tb_pad_i_rst_h          <= '1';

            tb_i_uart_select        <= '0';
            tb_i_uart_rx_manual     <= '0';
            tb_pad_i_switch_0       <= '0';
            tb_pad_i_switch_1       <= '0';
            tb_pad_i_switch_2       <= '0';

            tb_i_read_address       <= (others => '0');
            tb_i_read_address_valid <= '0';
            tb_i_write_address      <= (others => '0');
            tb_i_write_data         <= (others => '0');
            tb_i_write_valid        <= '0';

            tb_check_uart_timings   <= '0';

            wait for c_clock_cycles * C_CLK_PERIOD;

            -- Reassert reset
            tb_pad_i_rst_h          <= '0';

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
            wait for 1.1 * C_BIT_TIME;

        end procedure proc_uart_send_byte;

        -- =============================================================================================================
        -- proc_uart_write
        --
        -- Description: This procedure writes a value to a specified UART register.
        --
        -- Parameters:
        --   reg   : t_reg            - The register to write to.
        --   value : std_logic_vector - The value to write to the register.
        --
        -- Example:
        --   proc_uart_write(C_REG_16_BITS, x"ABCD");
        -- =============================================================================================================

        procedure proc_uart_write (
            constant reg   : t_reg;
            constant value : std_logic_vector(16 - 1 downto 0)
        ) is
        begin

            info(
                "Writing value 0x" & to_hstring(value) & " to register " & reg.name &
                " at address 0x"   & to_hstring(reg.addr));

            -- Select the model UART
            if (tb_i_uart_select = '1') then
                tb_i_uart_select <= '0';
                wait for 200 ns;
            end if;

            -- Set up the write operation
            tb_i_write_address <= reg.addr;
            tb_i_write_data    <= value;
            tb_i_write_valid   <= '1';

            -- Wait for a short duration
            wait for 200 ns;

            -- De-assert the write valid signal
            tb_i_write_valid   <= '0';

            -- Wait for the write operation to complete
            wait for 1.1 * C_UART_WRITE_CMD_TIME;

        end procedure proc_uart_write;

        -- =============================================================================================================
        -- proc_uart_read
        --
        -- Description: This procedure reads a value from a specified UART register.
        --
        -- Parameters:
        --   reg : t_reg - The register to read from.
        --
        -- Example:
        --   proc_uart_read(C_REG_16_BITS);
        -- =============================================================================================================

        procedure proc_uart_read (
            constant reg : t_reg
        ) is
        begin

            info("Reading value from register " & reg.name & " at address 0x" & to_hstring(reg.addr));

            -- Select the model UART
            if (tb_i_uart_select = '1') then
                tb_i_uart_select <= '0';
                wait for 200 ns;
            end if;

            -- Wait some time before starting the read to avoid simulation stuck
            wait for 500 ns;

            -- Set up the read operation
            tb_i_read_address       <= reg.addr;
            tb_i_read_address_valid <= '1';

            -- Wait for the read operation to complete
            wait until rising_edge(tb_o_read_data_valid);

            -- De-assert the read valid signal after completion
            tb_i_read_address_valid <= '0';

        end procedure proc_uart_read;

        -- =============================================================================================================
        -- proc_uart_check
        --
        -- Description: This procedure checks if the read value from a specified UART register matches the expected
        --              value.
        --
        -- Parameters:
        --   reg            : t_reg            - The register to check.
        --   expected_value : std_logic_vector - The expected value to compare against.
        --
        -- Example:
        --   proc_uart_check(C_REG_16_BITS, x"ABCD");
        -- =============================================================================================================

        procedure proc_uart_check (
            constant reg            : t_reg;
            constant expected_value : std_logic_vector(16 - 1 downto 0)
        ) is
        begin

            -- Read the register value
            proc_uart_read(reg);

            -- Check if the read value matches the expected value
            check_equal(
                tb_o_read_data,
                expected_value,
                "Check register " & reg.name & ": expected 0x" & to_hstring(expected_value) &
                ", got 0x"        & to_hstring(tb_o_read_data));

        end procedure proc_uart_check;

        -- =============================================================================================================
        -- proc_uart_check_default_value
        --
        -- Description: This procedure checks if the default value of a specified UART register matches the expected
        --              reset value.
        --
        -- Parameters:
        --   reg : t_reg - The register to check.
        --
        -- Example:
        --   proc_uart_check_default_value(C_REG_16_BITS);
        -- =============================================================================================================

        procedure proc_uart_check_default_value (
            constant reg : t_reg
        ) is
        begin

            info("");
            info("Checking register " & reg.name & " value after reset");

            -- Check the default value
            proc_uart_check(reg, reg.data);

        end procedure proc_uart_check_default_value;

        -- =============================================================================================================
        -- proc_uart_check_read_only
        --
        -- Description: This procedure checks if a specified UART register is read-only by attempting to write to it
        --              and verifying that the value remains unchanged.
        --
        -- Parameters:
        --   reg : t_reg - The register to check.
        --
        -- Example:
        --   proc_uart_check_read_only(C_REG_16_BITS);
        -- =============================================================================================================

        procedure proc_uart_check_read_only (
            constant reg : t_reg
        ) is
        begin

            info("");
            info("Checking register " & reg.name & " is in read-only");

            -- Attempt to write an incorrect value to the register
            proc_uart_write(reg, not reg.data);

            -- Check if the register value remains unchanged
            proc_uart_check(reg, reg.data);

        end procedure proc_uart_check_read_only;

        -- =============================================================================================================
        -- proc_uart_check_read_write
        --
        -- Description: This procedure checks if a specified UART register is read-write by writing a value to it and
        --              verifying that the value is correctly updated.
        --
        -- Parameters:
        --   reg            : t_reg            - The register to check.
        --   expected_value : std_logic_vector - The expected value to compare against after writing.
        --
        -- Example:
        --   proc_uart_check_read_write(C_REG_16_BITS, x"0001");
        -- =============================================================================================================

        procedure proc_uart_check_read_write (
            constant reg            : t_reg;
            constant expected_value : std_logic_vector(16 - 1 downto 0)
        ) is
        begin

            info("");
            info("Checking register " & reg.name & " is in read-write");

            -- Write the expected value to the register
            proc_uart_write(reg, not reg.data);

            -- Check if the register value is updated correctly
            proc_uart_check(reg, expected_value);

        end procedure proc_uart_check_read_write;

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

            -- Reset C_REG_SPI before for the rising edge detection
            proc_uart_write(C_REG_SPI, x"0000");

            -- Write the data
            proc_uart_write(C_REG_SPI, x"01" & value);

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

            if run("test_top_fpga_registers") then

                -- Reset values
                proc_reset_dut;
                wait for 100 us;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Checking default register values");
                info("-----------------------------------------------------------------------------");

                proc_uart_check_default_value(C_REG_GIT_ID_MSB);
                proc_uart_check_default_value(C_REG_GIT_ID_LSB);
                proc_uart_check_default_value(C_REG_12);
                proc_uart_check_default_value(C_REG_34);
                proc_uart_check_default_value(C_REG_56);
                proc_uart_check_default_value(C_REG_78);
                proc_uart_check_default_value(C_REG_9A);
                proc_uart_check_default_value(C_REG_CD);
                proc_uart_check_default_value(C_REG_EF);
                proc_uart_check_default_value(C_REG_16_BITS);
                proc_uart_check_default_value(C_REG_DEAD);

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Checking read-only registers");
                info("-----------------------------------------------------------------------------");

                proc_uart_check_read_only(C_REG_GIT_ID_MSB);
                proc_uart_check_read_only(C_REG_GIT_ID_LSB);
                proc_uart_check_read_only(C_REG_12);
                proc_uart_check_read_only(C_REG_34);
                proc_uart_check_read_only(C_REG_56);
                proc_uart_check_read_only(C_REG_78);
                proc_uart_check_read_only(C_REG_9A);
                proc_uart_check_read_only(C_REG_CD);
                proc_uart_check_read_only(C_REG_EF);
                proc_uart_check_read_only(C_REG_DEAD);

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Checking read-write registers");
                info("-----------------------------------------------------------------------------");

                proc_uart_check_read_write(C_REG_16_BITS, not C_REG_16_BITS.data);

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Writing some values to read-write registers");
                info("-----------------------------------------------------------------------------");

                proc_uart_write(C_REG_16_BITS, x"ABCD");
                proc_uart_check(C_REG_16_BITS, x"ABCD");

            elsif (run("test_uart_robustness")) then

                -- Reset DUT
                proc_reset_dut;
                wait for 100 us;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Sending read command with invalid start bit in char 'R'");
                info("-----------------------------------------------------------------------------");

                -- Select the manual UART
                tb_i_uart_select <= '1';

                info("Sending command R00\n -> Invalid start bit in 'R'");

                -- Send a byte (0x52) with invalid start bit
                tb_i_uart_rx_manual <= '0';
                wait for 0.25 * C_BIT_TIME; -- Invalid start bit (too short)
                tb_i_uart_rx_manual <= '1'; -- Sudden change to high
                wait for 0.75 * C_BIT_TIME; -- Complete the rest of the start bit duration
                tb_i_uart_rx_manual <= '0'; -- Bit 0
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '1'; -- Bit 1
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '0'; -- Bit 2
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
                tb_i_uart_rx_manual <= '1'; -- Stop bit
                wait for 1.1 * C_BIT_TIME;

                -- Send valid 2 bytes 0x30
                proc_uart_send_byte(tb_i_uart_rx_manual, 8x"30");
                proc_uart_send_byte(tb_i_uart_rx_manual, 8x"30");

                -- Send valid byte 0x0D
                proc_uart_send_byte(tb_i_uart_rx_manual, 8x"0D");

                -- Wait some time longer than the response
                wait for 1.1 * C_UART_READ_CMD_TIME;

                -- Ensure UART TX remains stable high and send no data to this invalid read command
                check_equal(
                    tb_pad_o_uart_tx = '1' and tb_pad_o_uart_tx'stable(C_UART_READ_CMD_TIME),
                    True,
                    "Ensuring UART not responding when sending read command with invalid start bit in char 'R'");

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Sending read command with invalid stop bit in char 'R'");
                info("-----------------------------------------------------------------------------");

                -- Reset DUT
                proc_reset_dut;
                wait for 100 us;

                info("Sending command R00\n -> Invalid stop bit in 'R'");

                -- Select the manual UART
                tb_i_uart_select <= '1';

                -- Send a byte (0x52) with invalid stop bit
                tb_i_uart_rx_manual <= '0';
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '0'; -- Bit 0
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '1'; -- Bit 1
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '0'; -- Bit 2
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

                -- Send valid 2 bytes 0x30
                proc_uart_send_byte(tb_i_uart_rx_manual, 8x"30");
                proc_uart_send_byte(tb_i_uart_rx_manual, 8x"30");

                -- Send valid byte 0x0D
                proc_uart_send_byte(tb_i_uart_rx_manual, 8x"0D");

                -- Wait some time longer than the response
                wait for 1.1 * C_UART_READ_CMD_TIME;

                -- Ensure UART TX remains stable high and send no data to this invalid read command
                check_equal(
                    tb_pad_o_uart_tx = '1' and tb_pad_o_uart_tx'stable(C_UART_READ_CMD_TIME),
                    True,
                    "Ensuring UART not responding when sending read command with invalid start bit in char 'R'");

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Checking UART timings with value 0x5555");
                info("-----------------------------------------------------------------------------");

                -- Reset DUT
                proc_reset_dut;
                wait for 100 us;

                -- Enable the timings check
                tb_check_uart_timings <= '1';

                proc_uart_write(C_REG_16_BITS, x"5555");
                proc_uart_read (C_REG_16_BITS);

                wait for C_UART_READ_CMD_TIME;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Sending read commands with invalid CR");
                info("-----------------------------------------------------------------------------");

                -- Reset DUT
                proc_reset_dut;
                wait for 100 us;

                info("");
                info("Sending read command R01\n -> Missing \r");

                proc_uart_send_byte(tb_i_uart_rx_manual, 8x"52");
                proc_uart_send_byte(tb_i_uart_rx_manual, 8x"30");
                proc_uart_send_byte(tb_i_uart_rx_manual, 8x"31");
                proc_uart_send_byte(tb_i_uart_rx_manual, 8x"0A"); -- Missing CR

                wait for C_UART_READ_CMD_TIME;

                -- Ensure UART TX remains stable high and send no data to this invalid read command
                check_equal(
                    tb_pad_o_uart_tx = '1' and tb_pad_o_uart_tx'stable(C_UART_READ_CMD_TIME),
                    True,
                    "Ensuring UART not responding when sending read command with invalid \r");

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Sending write commands with invalid CR");
                info("-----------------------------------------------------------------------------");

                -- Reset DUT
                proc_reset_dut;
                wait for 100 us;

                -- Read default value before write attempt
                proc_uart_check(C_REG_16_BITS, C_REG_16_BITS.data);

                info("");
                info("Sending write command WFFABCD\n -> Missing \r");

                proc_uart_send_byte(tb_i_uart_rx_manual, x"57");
                proc_uart_send_byte(tb_i_uart_rx_manual, x"46");
                proc_uart_send_byte(tb_i_uart_rx_manual, x"46");
                proc_uart_send_byte(tb_i_uart_rx_manual, x"39");
                proc_uart_send_byte(tb_i_uart_rx_manual, x"40");
                proc_uart_send_byte(tb_i_uart_rx_manual, x"41");
                proc_uart_send_byte(tb_i_uart_rx_manual, x"42");
                proc_uart_send_byte(tb_i_uart_rx_manual, x"0A"); -- Missing CR

                -- Read back the register to ensure the data was not written
                proc_uart_check(C_REG_16_BITS, C_REG_16_BITS.data);

            elsif (run("test_led_and_switches_toggling")) then

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Checking register REG_LED characteristics (read-write)");
                info("-----------------------------------------------------------------------------");

                -- Reset DUT
                proc_reset_dut;
                wait for 100 us;

                -- Check default value
                proc_uart_check_default_value(C_REG_LED);

                -- Check register is in read-only
                proc_uart_check_read_write(C_REG_LED, 15b"0" & not C_REG_LED.data(0));

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Toggling led_0 register");
                info("-----------------------------------------------------------------------------");

                info("");
                proc_uart_write(C_REG_LED, x"0001");
                wait for 1 ms;

                check_equal(
                    tb_pad_o_led_0 = '1' and tb_pad_o_led_0'stable(0.7 ms),
                    True,
                    "Ensuring tb_pad_o_led_0 stable at '1' during 0.7 ms");

                info("");
                proc_uart_write(C_REG_LED, x"0000");
                wait for 2.5 ms;

                check_equal(
                    tb_pad_o_led_0 = '0' and tb_pad_o_led_0'stable(2.3 ms),
                    True,
                    "Ensuring tb_pad_o_led_0 stable at '0' 2.3 ms");

                info("");
                proc_uart_write(C_REG_LED, x"0001");
                wait for 2 ms;

                check_equal(
                    tb_pad_o_led_0 = '1' and tb_pad_o_led_0'stable(1.8 ms),
                    True,
                    "Ensuring tb_pad_o_led_0 stable at '1' during 1.8 ms");

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Checking register REG_SWITCHES characteristics (read-only)");
                info("-----------------------------------------------------------------------------");

                -- Reset DUT
                proc_reset_dut;
                wait for 100 us;

                -- Check default value
                proc_uart_check_default_value(C_REG_SWITCHES);

                -- Check register is in read-only
                proc_uart_check_read_only(C_REG_SWITCHES);

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Toggling input switches - Testing combinations");
                info("-----------------------------------------------------------------------------");

                for i in 0 to 7 loop

                    -- Set switches according to bit pattern
                    tb_pad_i_switch_0 <= std_logic(to_unsigned(i, 3)(0));
                    tb_pad_i_switch_1 <= std_logic(to_unsigned(i, 3)(1));
                    tb_pad_i_switch_2 <= std_logic(to_unsigned(i, 3)(2));
                    wait for 1 ns; -- Signal propagation

                    info("");
                    info("Testing combination :"                     &
                        " SW2=" & std_logic'image(tb_pad_i_switch_2) &
                        " SW1=" & std_logic'image(tb_pad_i_switch_1) &
                        " SW0=" & std_logic'image(tb_pad_i_switch_0));

                    proc_uart_check(C_REG_SWITCHES, std_logic_vector(to_unsigned(i, 16)));
                end loop;

            elsif (run("test_spi")) then

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Testing SPI register");
                info("-----------------------------------------------------------------------------");

                -- Reset DUT
                proc_reset_dut;
                wait for 100 us;

                -- Check default value
                proc_uart_check_default_value(C_REG_SPI);

                -- Check register is in read-write
                proc_uart_check_read_write(C_REG_SPI, x"01FF");

                pop_stream(net, C_SLAVE_STREAM, v_spi_slave_data);

                -- Verify MOSI path
                check_equal(v_spi_slave_data, not(C_REG_SPI.data(8 - 1 downto 0)),
                    "MOSI Verification: Slave received correct data from Master");

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Testing SPI output");
                info("-----------------------------------------------------------------------------");

                -- Reset DUT
                proc_reset_dut;
                wait for 100 us;

                proc_spi_check(x"55");
                proc_spi_check(x"AB");
                proc_spi_check(x"1E");

                wait for C_UART_READ_CMD_TIME;

            end if;

        end loop;

        -- End simulation
        test_runner_cleanup(runner);

    end process p_test_runner;

end architecture TB_TOP_FPGA_ARCH;
