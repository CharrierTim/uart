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
    -- TYPES
    -- =================================================================================================================

    type t_reg is record
        name : string;                            -- Name
        addr : std_logic_vector( 8 - 1 downto 0); -- Address
        data : std_logic_vector(16 - 1 downto 0); -- Value at reset
    end record t_reg;

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- Clock period for the testbench
    constant C_FREQ_HZ             : positive := 50_000_000;
    constant C_CLK_PERIOD          : time     := 1 sec / C_FREQ_HZ;

    -- DUT generics
    constant C_BAUD_RATE_BPS       : positive                          := 115_200;
    constant C_DATA_LENGTH         : positive                          := 8;
    constant C_GIT_ID              : std_logic_vector(32 - 1 downto 0) := x"12345678";

    -- Registers

    -- vsg_off
    constant C_REG_GIT_ID_MSB : t_reg := (addr => 8x"00", data => 16x"1234", name => "C_REG_GIT_ID_MSB");
    constant C_REG_GIT_ID_LSB : t_reg := (addr => 8x"01", data => 16x"5678", name => "C_REG_GIT_ID_LSB");
    constant C_REG_12         : t_reg := (addr => 8x"02", data => 16x"1212", name => "C_REG_12");
    constant C_REG_34         : t_reg := (addr => 8x"03", data => 16x"3434", name => "C_REG_34");
    constant C_REG_56         : t_reg := (addr => 8x"04", data => 16x"5656", name => "C_REG_56");
    constant C_REG_78         : t_reg := (addr => 8x"05", data => 16x"7878", name => "C_REG_78");
    constant C_REG_9A         : t_reg := (addr => 8x"AB", data => 16x"9A9A", name => "C_REG_9A");
    constant C_REG_CD         : t_reg := (addr => 8x"AC", data => 16x"CDCD", name => "C_REG_CD");
    constant C_REG_EF         : t_reg := (addr => 8x"DC", data => 16x"EFEF", name => "C_REG_EF");
    constant C_REG_1_BIT      : t_reg := (addr => 8x"EF", data => 16x"0001", name => "C_REG_1_BIT");
    constant C_REG_16_BITS    : t_reg := (addr => 8x"FF", data => 16x"0000", name => "C_REG_16_BITS");
    -- vsg_on

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- DUT signals
    signal tb_clk                  : std_logic;
    signal tb_rst_n                : std_logic;
    signal tb_pad_i_uart_rx_model  : std_logic;
    signal tb_pad_o_uart_tx_model  : std_logic;

    -- UART model
    signal tb_i_uart_rx_manual     : std_logic;
    signal tb_i_uart_rx_model      : std_logic;
    signal tb_i_uart_select        : std_logic;
    signal tb_i_read_address       : std_logic_vector( 8 - 1 downto 0);
    signal tb_i_read_address_valid : std_logic;
    signal tb_o_read_data          : std_logic_vector(16 - 1 downto 0);
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
            PAD_I_UART_RX => tb_pad_i_uart_rx_model,
            PAD_O_UART_TX => tb_pad_o_uart_tx_model
        );

    -- =================================================================================================================
    -- UART MODEL
    -- =================================================================================================================

    inst_uart_model : entity lib_bench.uart_model
        generic map (
            G_BAUD_RATE_BPS => C_BAUD_RATE_BPS
        )
        port map (
            I_UART_RX            => tb_pad_o_uart_tx_model,
            O_UART_TX            => tb_pad_i_uart_rx_model,
            I_READ_ADDRESS       => tb_i_read_address,
            I_READ_ADDRESS_VALID => tb_i_read_address_valid,
            O_READ_DATA          => tb_o_read_data,
            I_WRITE_ADDRESS      => tb_i_write_address,
            I_WRITE_DATA         => tb_i_write_data,
            I_WRITE_VALID        => tb_i_write_valid
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
            tb_rst_n                <= '0';
            tb_i_uart_select        <= '0';
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

            if run("test_uart_read_command") then

                info("-----------------------------------------------------------------------------");
                info("TESTING UART COMMAND");
                info("-----------------------------------------------------------------------------");

                -- Reset values
                proc_reset_dut;
                wait for 100 us;

                tb_i_read_address       <= x"AB";
                tb_i_read_address_valid <= '1';
                wait for 200 ns;
                tb_i_read_address_valid <= '0';
                wait for 1 ms;

                tb_i_write_address      <= x"FF";
                tb_i_write_data         <= x"CDEF";
                tb_i_write_valid        <= '1';
                wait for 200 ns;
                tb_i_write_valid        <= '0';
                wait for 1 ms;

            end if;

        end loop;

        -- End simulation
        test_runner_cleanup(runner);

    end process p_test_runner;

end architecture TB_TOP_FPGA_ARCH;
