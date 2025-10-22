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
-- @file    tb_uart_tx.vhd
-- @version 1.0
-- @brief   Testbench for UART TX module
-- @author  Timothee Charrier
-- @date    18/10/2025
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library lib_rtl;

library vunit_lib;
    context vunit_lib.vunit_context;
    context vunit_lib.vc_context;

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
    -- TYPES
    -- =================================================================================================================

    type t_tx_byte is record
        string_byte : string;                           -- Byte in hex (1 characters)
        slv_byte    : std_logic_vector(8 - 1 downto 0); -- Data as std_logic_vector
    end record t_tx_byte;

    type t_tx_byte_array is array (natural range <>) of t_tx_byte;

    -- Byte to send

    -- vsg_off
    constant C_CHAR_CR          : t_tx_byte := (string_byte => "'CR'", slv_byte => x"0D"); -- Carriage Return
    constant C_CHAR_0           : t_tx_byte := (string_byte => " '0'", slv_byte => x"30"); -- Character '0'
    constant C_CHAR_1           : t_tx_byte := (string_byte => " '1'", slv_byte => x"31"); -- Character '1'
    constant C_CHAR_2           : t_tx_byte := (string_byte => " '2'", slv_byte => x"32"); -- Character '2'
    constant C_CHAR_3           : t_tx_byte := (string_byte => " '3'", slv_byte => x"33"); -- Character '3'
    constant C_CHAR_4           : t_tx_byte := (string_byte => " '4'", slv_byte => x"34"); -- Character '4'
    constant C_CHAR_5           : t_tx_byte := (string_byte => " '5'", slv_byte => x"35"); -- Character '5'
    constant C_CHAR_6           : t_tx_byte := (string_byte => " '6'", slv_byte => x"36"); -- Character '6'
    constant C_CHAR_7           : t_tx_byte := (string_byte => " '7'", slv_byte => x"37"); -- Character '7'
    constant C_CHAR_8           : t_tx_byte := (string_byte => " '8'", slv_byte => x"38"); -- Character '8'
    constant C_CHAR_9           : t_tx_byte := (string_byte => " '9'", slv_byte => x"39"); -- Character '9'
    constant C_CHAR_A           : t_tx_byte := (string_byte => " 'A'", slv_byte => x"41"); -- Character 'A'
    constant C_CHAR_B           : t_tx_byte := (string_byte => " 'B'", slv_byte => x"42"); -- Character 'B'
    constant C_CHAR_C           : t_tx_byte := (string_byte => " 'C'", slv_byte => x"43"); -- Character 'C'
    constant C_CHAR_D           : t_tx_byte := (string_byte => " 'D'", slv_byte => x"44"); -- Character 'D'
    constant C_CHAR_E           : t_tx_byte := (string_byte => " 'E'", slv_byte => x"45"); -- Character 'E'
    constant C_CHAR_F           : t_tx_byte := (string_byte => " 'F'", slv_byte => x"46"); -- Character 'F'
    constant C_CHAR_R           : t_tx_byte := (string_byte => " 'R'", slv_byte => x"52"); -- Character 'R'
    constant C_CHAR_W           : t_tx_byte := (string_byte => " 'W'", slv_byte => x"57"); -- Character 'W'
    -- vsg_on

    constant C_CHAR_LIST      : t_tx_byte_array :=
    (
        C_CHAR_CR,
        C_CHAR_0,
        C_CHAR_1,
        C_CHAR_2,
        C_CHAR_3,
        C_CHAR_4,
        C_CHAR_5,
        C_CHAR_6,
        C_CHAR_7,
        C_CHAR_8,
        C_CHAR_9,
        C_CHAR_A,
        C_CHAR_B,
        C_CHAR_C,
        C_CHAR_D,
        C_CHAR_E,
        C_CHAR_F,
        C_CHAR_R,
        C_CHAR_W
    );

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- Clock period for the testbench
    constant C_FREQ_HZ        : positive := 50_000_000;
    constant C_CLK_PERIOD     : time     := 1 sec / C_FREQ_HZ;

    -- DUT generics
    constant C_CLK_FREQ_HZ    : positive := 50_000_000;
    constant C_BAUD_RATE_BPS  : positive := 115_200;
    constant C_DATA_LENGTH    : positive := 8;

    -- UART Slave BFM instance
    constant C_UART_BFM_SLAVE : uart_slave_t   := new_uart_slave(
            initial_baud_rate => C_BAUD_RATE_BPS,
            data_length       => C_DATA_LENGTH
        );
    constant C_UART_STREAM    : stream_slave_t := as_stream(C_UART_BFM_SLAVE);

    -- Byte to send

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- DUT signals
    signal tb_clk             : std_logic;
    signal tb_rst_n           : std_logic;
    signal tb_i_byte          : std_logic_vector(8 - 1 downto 0);
    signal tb_i_byte_valid    : std_logic;
    signal tb_o_uart_tx       : std_logic;
    signal tb_o_done          : std_logic;

begin

    -- =================================================================================================================
    -- DUT
    -- =================================================================================================================

    inst_uart_tx : entity lib_rtl.uart_tx
        generic map (
            G_CLK_FREQ_HZ   => C_CLK_FREQ_HZ,
            G_BAUD_RATE_BPS => C_BAUD_RATE_BPS
        )
        port map (
            CLK          => tb_clk,
            RST_N        => tb_rst_n,
            I_BYTE       => tb_i_byte,
            I_BYTE_VALID => tb_i_byte_valid,
            O_UART_TX    => tb_o_uart_tx,
            O_DONE       => tb_o_done
        );

    -- =================================================================================================================
    -- UART SLAVE
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
            constant c_clock_cycles : positive := 50
        ) is
        begin

            -- Reset the DUT by setting the input state to all zeros
            tb_rst_n        <= '0';
            tb_i_byte       <= (others => '0');
            tb_i_byte_valid <= '0';

            wait for c_clock_cycles * C_CLK_PERIOD;

            -- Reassert reset
            tb_rst_n        <= '1';

            -- Wait for the DUT to step over a simulation step
            wait for 5 ns;

            -- Log the reset action
            info("DUT has been reset.");
            info("");

        end procedure proc_reset_dut;

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

            if run("test_uart_tx_serialization") then

                info("-----------------------------------------------------------------------------");
                info("TESTING UART TX SERIALIZATION");
                info("-----------------------------------------------------------------------------");

                -- Reset values
                proc_reset_dut;
                wait for 100 us;

                -- Send all characters in C_CHAR_LIST
                for i in C_CHAR_LIST'range loop

                    info(
                        "Sending character: "                         &
                        C_CHAR_LIST(i).string_byte                    &
                        " (0x"                                        &
                        to_hstring(unsigned(C_CHAR_LIST(i).slv_byte)) &
                        ")");

                    -- Apply input byte and assert valid signal
                    tb_i_byte       <= C_CHAR_LIST(i).slv_byte;
                    tb_i_byte_valid <= '1';
                    wait for 2 * C_CLK_PERIOD;
                    tb_i_byte_valid <= '0';

                    -- Check received byte
                    check_stream(net, C_UART_STREAM, C_CHAR_LIST(i).slv_byte);
                    wait for 100 us;

                end loop;

            end if;

        end loop;

        -- End simulation
        test_runner_cleanup(runner);

    end process p_test_runner;

end architecture TB_UART_TX_ARCH;
