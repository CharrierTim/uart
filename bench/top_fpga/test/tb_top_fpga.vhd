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
    use lib_bench.tb_top_fpga_pkg.all;

library vunit_lib;
    context vunit_lib.vunit_context;
    context vunit_lib.vc_context;

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
    -- CONSTANTS
    -- =================================================================================================================

    -- Clock period for the testbench
    constant C_FREQ_HZ             : positive := 50_000_000;
    constant C_CLK_PERIOD          : time     := 1 sec / C_FREQ_HZ;

    -- DUT generics
    constant C_BAUD_RATE_BPS       : positive                          := 115_200;
    constant C_BIT_TIME            : time                              := 1 sec / C_BAUD_RATE_BPS;
    constant C_WRITE_NB_BITS       : positive                          := 10 * 8; -- 10 bits , 8 chars in total
    constant C_WRITE_TIME_NS       : time                              := C_BIT_TIME * C_WRITE_NB_BITS;
    constant C_READ_NB_BITS        : positive                          := 10 * 9; -- 10 bits , 9 chars in total
    constant C_READ_TIME_NS        : time                              := C_BIT_TIME * C_READ_NB_BITS;
    constant C_GIT_ID              : std_logic_vector(32 - 1 downto 0) := x"12345678";

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- DUT signals
    signal tb_clk                  : std_logic;
    signal tb_rst_n                : std_logic;
    signal tb_pad_i_uart_rx        : std_logic;
    signal tb_pad_o_uart_tx        : std_logic;

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

begin

    -- =================================================================================================================
    -- DUT
    -- =================================================================================================================

    dut : entity lib_rtl.top_fpga
        generic map (
            G_GIT_ID => C_GIT_ID
        )
        port map (
            CLK           => tb_clk,
            RST_N         => tb_rst_n,
            PAD_I_UART_RX => tb_i_uart_rx,
            PAD_O_UART_TX => tb_pad_o_uart_tx
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
            tb_rst_n                <= '0';
            tb_i_uart_select        <= '0';
            tb_i_uart_rx_manual     <= '0';
            tb_i_read_address       <= (others => '0');
            tb_i_read_address_valid <= '0';
            tb_i_write_address      <= (others => '0');
            tb_i_write_data         <= (others => '0');
            tb_i_write_valid        <= '0';

            wait for c_clock_cycles * C_CLK_PERIOD;

            -- Reassert reset
            tb_rst_n                <= '1';

            -- Wait for the DUT to step over a simulation step
            wait for 5 ns;

            -- Log the reset action
            info("");
            info("DUT has been reset.");

        end procedure;

        -- =============================================================================================================
        -- proc_uart_write
        -- Description: This procedure writes a value to a specified UART register.
        -- Parameters:
        --   reg : t_reg - The register to write to.
        --   value : std_logic_vector - The value to write to the register.
        -- Example:
        --   proc_uart_write(C_REG_16_BITS, x"ABCD");
        -- =============================================================================================================
        procedure proc_uart_write (
            constant reg   : t_reg;
            constant value : std_logic_vector(16 - 1 downto 0)) is
        begin

            info(
                "Writing value 0x" & to_hstring(value) & " to register " & reg.name &
                " at address 0x"   & to_hstring(reg.addr));

            -- Set up the write operation
            tb_i_write_address <= reg.addr;
            tb_i_write_data    <= value;
            tb_i_write_valid   <= '1';

            -- Wait for a short duration
            wait for 200 ns;

            -- De-assert the write valid signal
            tb_i_write_valid   <= '0';

            -- Wait for the write operation to complete
            wait for 1.1 * C_WRITE_TIME_NS;

        end procedure;

        -- =============================================================================================================
        -- proc_uart_read
        -- Description: This procedure reads a value from a specified UART register.
        -- Parameters:
        --   reg : t_reg - The register to read from.
        -- Example:
        --   proc_uart_read(C_REG_16_BITS);
        -- =============================================================================================================
        procedure proc_uart_read (
            constant reg : t_reg) is
        begin

            info("Reading value from register " & reg.name & " at address 0x" & to_hstring(reg.addr));

            -- Set up the read operation
            tb_i_read_address       <= reg.addr;
            tb_i_read_address_valid <= '1';

            -- Wait for a short duration
            wait for 200 ns;

            -- De-assert the read valid signal
            tb_i_read_address_valid <= '0';

        end procedure;

        -- =============================================================================================================
        -- proc_uart_check
        -- Description: This procedure checks if the read value from a specified UART register matches the expected
        --              value.
        -- Parameters:
        --   reg : t_reg - The register to check.
        --   expected_value : std_logic_vector - The expected value to compare against.
        -- Example:
        --   proc_uart_check(C_REG_16_BITS, x"ABCD");
        -- =============================================================================================================
        procedure proc_uart_check (
            constant reg            : t_reg;
            constant expected_value : std_logic_vector(16 - 1 downto 0)) is
        begin

            -- Read the register value
            proc_uart_read(reg);
            wait for 1.1 * C_READ_TIME_NS;

            -- Check if the read value matches the expected value
            check_equal(
                tb_o_read_data,
                expected_value,
                "Check register " & reg.name & ": expected 0x" & to_hstring(expected_value) &
                ", got 0x"        & to_hstring(tb_o_read_data));

        end procedure;

        -- =============================================================================================================
        -- proc_uart_check_default_value
        -- Description: This procedure checks if the default value of a specified UART register matches the expected
        --              reset value.
        -- Parameters:
        --   reg : t_reg - The register to check.
        -- Example:
        --   proc_uart_check_default_value(C_REG_16_BITS);
        -- =============================================================================================================
        procedure proc_uart_check_default_value (
            constant reg : t_reg) is
        begin

            info("");
            info("Checking register " & reg.name & " value after reset");

            -- Check the default value
            proc_uart_check(reg, reg.data);

        end procedure;

        -- =============================================================================================================
        -- proc_uart_check_read_only
        -- Description: This procedure checks if a specified UART register is read-only by attempting to write to it
        --              and verifying that the value remains unchanged.
        -- Parameters:
        --   reg : t_reg - The register to check.
        -- Example:
        --   proc_uart_check_read_only(C_REG_16_BITS);
        -- =============================================================================================================
        procedure proc_uart_check_read_only (
            constant reg : t_reg) is
        begin

            info("");
            info("Checking register " & reg.name & " is in read-only");

            -- Attempt to write an incorrect value to the register
            proc_uart_write(reg, not reg.data);

            -- Check if the register value remains unchanged
            proc_uart_check(reg, reg.data);

        end procedure;

        -- =============================================================================================================
        -- proc_uart_check_read_write
        -- Description: This procedure checks if a specified UART register is read-write by writing a value to it and
        --              verifying that the value is correctly updated.
        -- Parameters:
        --   reg : t_reg - The register to check.
        --   expected_value : std_logic_vector - The expected value to compare against after writing.
        -- Example:
        --   proc_uart_check_read_write(C_REG_16_BITS, x"0001");
        -- =============================================================================================================
        procedure proc_uart_check_read_write (
            constant reg            : t_reg;
            constant expected_value : std_logic_vector(16 - 1 downto 0)) is
        begin

            info("");
            info("Checking register " & reg.name & " is in read-write");

            -- Write the expected value to the register
            proc_uart_write(reg, not reg.data);

            -- Check if the register value is updated correctly
            proc_uart_check(reg, expected_value);

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
                proc_uart_check_default_value(C_REG_1_BIT);
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

                proc_uart_check_read_write(C_REG_1_BIT, x"0000");
                proc_uart_check_read_write(C_REG_16_BITS, not C_REG_16_BITS.data);

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Writing some values to read-write registers");
                info("-----------------------------------------------------------------------------");

                proc_uart_write(C_REG_1_BIT, x"0001");
                proc_uart_check(C_REG_1_BIT, x"0001");

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

                -- Send valid byte 0x30
                for i in 1 to 2 loop
                    tb_i_uart_rx_manual <= '0'; -- Start bit
                    wait for C_BIT_TIME;
                    tb_i_uart_rx_manual <= '0'; -- Bit 0
                    wait for C_BIT_TIME;
                    tb_i_uart_rx_manual <= '0'; -- Bit 1
                    wait for C_BIT_TIME;
                    tb_i_uart_rx_manual <= '0'; -- Bit 2
                    wait for C_BIT_TIME;
                    tb_i_uart_rx_manual <= '0'; -- Bit 3
                    wait for C_BIT_TIME;
                    tb_i_uart_rx_manual <= '1'; -- Bit 4
                    wait for C_BIT_TIME;
                    tb_i_uart_rx_manual <= '1'; -- Bit 5
                    wait for C_BIT_TIME;
                    tb_i_uart_rx_manual <= '0'; -- Bit 6
                    wait for C_BIT_TIME;
                    tb_i_uart_rx_manual <= '0'; -- Bit 7
                    wait for C_BIT_TIME;
                    tb_i_uart_rx_manual <= '1'; -- Stop bit
                    wait for 1.1 * C_BIT_TIME;
                end loop;

                -- Send valid byte 0x0D
                tb_i_uart_rx_manual <= '0'; -- Start bit
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '1'; -- Bit 0
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '0'; -- Bit 1
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '1'; -- Bit 2
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '1'; -- Bit 3
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

                -- Wait some time longer than the response
                wait for 1.1 * C_READ_TIME_NS;

                -- Ensure UART TX remains stable high and send no data to this invalid read command
                check_equal(
                    tb_pad_o_uart_tx = '1' and tb_pad_o_uart_tx'stable(C_READ_TIME_NS),
                    True,
                    "Ensuring UART not responding when sending read command with invalid start bit in char 'R'");

                -- Reset DUT
                proc_reset_dut;
                wait for 100 us;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Sending read command with invalid stop bit in char 'R'");
                info("-----------------------------------------------------------------------------");

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
                tb_i_uart_rx_manual <= '1'; -- Stop bit
                wait for 0.25 * C_BIT_TIME;
                tb_i_uart_rx_manual <= '0'; -- Sudden change to low
                wait for 0.75 * C_BIT_TIME;
                tb_i_uart_rx_manual <= '1';
                wait for 1.1 * C_BIT_TIME;

                -- Send valid byte 0x30
                for i in 1 to 2 loop
                    tb_i_uart_rx_manual <= '0'; -- Start bit
                    wait for C_BIT_TIME;
                    tb_i_uart_rx_manual <= '0'; -- Bit 0
                    wait for C_BIT_TIME;
                    tb_i_uart_rx_manual <= '0'; -- Bit 1
                    wait for C_BIT_TIME;
                    tb_i_uart_rx_manual <= '0'; -- Bit 2
                    wait for C_BIT_TIME;
                    tb_i_uart_rx_manual <= '0'; -- Bit 3
                    wait for C_BIT_TIME;
                    tb_i_uart_rx_manual <= '1'; -- Bit 4
                    wait for C_BIT_TIME;
                    tb_i_uart_rx_manual <= '1'; -- Bit 5
                    wait for C_BIT_TIME;
                    tb_i_uart_rx_manual <= '0'; -- Bit 6
                    wait for C_BIT_TIME;
                    tb_i_uart_rx_manual <= '0'; -- Bit 7
                    wait for C_BIT_TIME;
                    tb_i_uart_rx_manual <= '1'; -- Stop bit
                    wait for 1.1 * C_BIT_TIME;
                end loop;

                -- Send valid byte 0x0D
                tb_i_uart_rx_manual <= '0'; -- Start bit
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '1'; -- Bit 0
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '0'; -- Bit 1
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '1'; -- Bit 2
                wait for C_BIT_TIME;
                tb_i_uart_rx_manual <= '1'; -- Bit 3
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

                -- Wait some time longer than the response
                wait for 1.1 * C_READ_TIME_NS;

                -- Ensure UART TX remains stable high and send no data to this invalid read command
                check_equal(
                    tb_pad_o_uart_tx = '1' and tb_pad_o_uart_tx'stable(C_READ_TIME_NS),
                    True,
                    "Ensuring UART not responding when sending read command with invalid start bit in char 'R'");

            end if;

        end loop;

        -- End simulation
        test_runner_cleanup(runner);

    end process p_test_runner;

end architecture TB_TOP_FPGA_ARCH;
