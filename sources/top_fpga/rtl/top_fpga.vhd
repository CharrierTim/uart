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
-- @brief   Top-Level of the FPGA
-- @author  Timothee Charrier
-- @date    20/10/2025
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;

library lib_rtl;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity TOP_FPGA is
    generic (
        G_GIT_ID : std_logic_vector(32 - 1 downto 0) := (others => '0')
    );
    port (
        -- Clock and reset
        PAD_I_CLK      : in    std_logic;
        PAD_I_RST_N    : in    std_logic;

        -- UART
        PAD_I_UART_RX  : in    std_logic;
        PAD_O_UART_TX  : out   std_logic;

        -- Switches and LED
        PAD_I_SWITCH_0 : in    std_logic;
        PAD_I_SWITCH_1 : in    std_logic;
        PAD_I_SWITCH_2 : in    std_logic;
        PAD_O_LED_0    : out   std_logic
    );
end entity TOP_FPGA;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================

architecture TOP_FPGA_ARCH of TOP_FPGA is

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- Resynchronization
    constant C_RESYNC_DEFAULT_VALUE : std_logic_vector(3 - 1 downto 0) := "000";

    -- UART
    constant C_CLK_FREQ_HZ          : positive := 50_000_000;
    constant C_BAUD_RATE_BPS        : positive := 115_200;
    constant C_SAMPLING_RATE        : positive := 16;

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- Resynchronization
    signal async_inputs_slv         : std_logic_vector(C_RESYNC_DEFAULT_VALUE'range);
    signal sync_inputs_slv          : std_logic_vector(C_RESYNC_DEFAULT_VALUE'range);

    -- Read interface
    signal read_addr                : std_logic_vector( 8 - 1 downto 0);
    signal read_addr_valid          : std_logic;
    signal read_data                : std_logic_vector(16 - 1 downto 0);
    signal read_data_valid          : std_logic;

    -- Write interface
    signal write_addr               : std_logic_vector( 8 - 1 downto 0);
    signal write_data               : std_logic_vector(16 - 1 downto 0);
    signal write_addr_valid         : std_logic;

begin

    -- =================================================================================================================
    -- RESYNCHRONIZATION
    -- =================================================================================================================

    async_inputs_slv <=
    (
        2 => PAD_I_SWITCH_2,
        1 => PAD_I_SWITCH_1,
        0 => PAD_I_SWITCH_0
    );

    inst_resync_slv : entity lib_rtl.resync_slv
        generic map (
            G_WIDTH         => C_RESYNC_DEFAULT_VALUE'length,
            G_DEFAULT_VALUE => C_RESYNC_DEFAULT_VALUE
        )
        port map (
            CLK          => PAD_I_CLK,
            RST_N        => PAD_I_RST_N,
            I_DATA_ASYNC => async_inputs_slv,
            O_DATA_SYNC  => sync_inputs_slv
        );

    -- =================================================================================================================
    -- UART MODULE
    -- =================================================================================================================

    inst_uart : entity lib_rtl.uart
        generic map (
            G_CLK_FREQ_HZ   => C_CLK_FREQ_HZ,
            G_BAUD_RATE_BPS => C_BAUD_RATE_BPS,
            G_SAMPLING_RATE => C_SAMPLING_RATE
        )
        port map (
            CLK               => PAD_I_CLK,
            RST_N             => PAD_I_RST_N,
            I_UART_RX         => PAD_I_UART_RX,
            O_UART_TX         => PAD_O_UART_TX,
            O_READ_ADDR       => read_addr,
            O_READ_ADDR_VALID => read_addr_valid,
            I_READ_DATA       => read_data,
            I_READ_DATA_VALID => read_data_valid,
            O_WRITE_ADDR      => write_addr,
            O_WRITE_DATA      => write_data,
            O_WRITE_VALID     => write_addr_valid
        );

    -- =================================================================================================================
    -- REGFILE MODULE
    -- =================================================================================================================

    inst_regfile : entity lib_rtl.regfile
        generic map (
            G_GIT_ID_MSB => G_GIT_ID(31 downto 16),
            G_GIT_ID_LSB => G_GIT_ID(15 downto  0)
        )
        port map (
            CLK               => PAD_I_CLK,
            RST_N             => PAD_I_RST_N,
            I_SWITCHES        => sync_inputs_slv,
            I_READ_ADDR       => read_addr,
            I_READ_ADDR_VALID => read_addr_valid,
            O_READ_DATA       => read_data,
            O_READ_DATA_VALID => read_data_valid,
            I_WRITE_ADDR      => write_addr,
            I_WRITE_DATA      => write_data,
            I_WRITE_VALID     => write_addr_valid,
            O_LED_0           => PAD_O_LED_0
        );

end architecture TOP_FPGA_ARCH;
