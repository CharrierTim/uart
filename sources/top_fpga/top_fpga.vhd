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
-- @version 1.3
-- @brief   Top-Level of the FPGA
-- @author  Timothee Charrier
-- @date    16/12/2025
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      01/12/2025  Timothee Charrier   Initial release
-- 1.1      10/12/2025  Timothee Charrier   Remove generic from UART module, update resync_slv module generic names
-- 1.2      16/12/2025  Timothee Charrier   Use new PLL outputing a 50 MHz and 25 MHz clock
-- 1.3      17/12/2025  Timothee Charrier   Update regfile module to interface with new VGA module
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
        PAD_I_CLK       : in    std_logic;
        PAD_I_RST_H     : in    std_logic;

        -- UART
        PAD_I_UART_RX   : in    std_logic;
        PAD_O_UART_TX   : out   std_logic;

        -- SPI
        PAD_O_SCLK      : out   std_logic;
        PAD_O_MOSI      : out   std_logic;
        PAD_I_MISO      : in    std_logic;
        PAD_O_CS_N      : out   std_logic;

        -- VGA
        PAD_O_VGA_HSYNC : out   std_logic;
        PAD_O_VGA_VSYNC : out   std_logic;
        PAD_O_VGA_RED   : out   std_logic_vector(4 - 1 downto 0);
        PAD_O_VGA_GREEN : out   std_logic_vector(4 - 1 downto 0);
        PAD_O_VGA_BLUE  : out   std_logic_vector(4 - 1 downto 0);

        -- Switches and LED
        PAD_I_SWITCH_0  : in    std_logic;
        PAD_I_SWITCH_1  : in    std_logic;
        PAD_I_SWITCH_2  : in    std_logic;
        PAD_O_LED_0     : out   std_logic
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

    -- SPI
    constant C_SPI_FREQ_HZ          : positive  := 1_000_000;
    constant C_SPI_NB_DATA_BITS     : positive  := 8;
    constant C_CLK_POLARITY         : std_logic := '0';
    constant C_CLK_PHASE            : std_logic := '0';

    -- VGA
    constant C_H_PIXELS             : integer := 640;
    constant C_H_FRONT_PORCH        : integer := 16;
    constant C_H_SYNC_PULSE         : integer := 96;
    constant C_H_BACK_PORCH         : integer := 48;

    constant C_V_PIXELS             : integer := 480;
    constant C_V_FRONT_PORCH        : integer := 10;
    constant C_V_SYNC_PULSE         : integer := 2;
    constant C_V_BACK_PORCH         : integer := 33;

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- Internal reset and clock
    signal internal_clk             : std_logic;
    signal vga_clk                  : std_logic;
    signal internal_rst_n           : std_logic;
    signal pll_locked               : std_logic;

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

    -- SPI data
    signal spi_tx_data              : std_logic_vector( 8 - 1 downto 0);
    signal spi_tx_data_valid        : std_logic;
    signal spi_rx_data              : std_logic_vector( 8 - 1 downto 0);
    signal spi_rx_data_valid        : std_logic;

    -- VGA control
    signal reg_vga_mode             : std_logic;
    signal reg_red                  : std_logic_vector(4 - 1 downto 0);
    signal reg_green                : std_logic_vector(4 - 1 downto 0);
    signal reg_blue                 : std_logic_vector(4 - 1 downto 0);

    -- =================================================================================================================
    -- COMPONENTS
    -- =================================================================================================================

    -- vsg_off
    component clk_wiz_0 is
        port (
            CLK_OUT1          : out   std_logic;
            CLK_OUT2          : out   std_logic;
            RESET             : in    std_logic;
            LOCKED            : out   std_logic;
            CLK_IN1           : in    std_logic
        );
    end component;
    -- vsg_on

begin

    -- Toggle reset from BTN and when PLL is lock
    internal_rst_n <= (not PAD_I_RST_H) and pll_locked;

    -- =================================================================================================================
    -- PLL
    -- =================================================================================================================

    inst_pll : component clk_wiz_0
        port map (
            clk_out1 => internal_clk,
            clk_out2 => vga_clk,
            reset    => PAD_I_RST_H,
            locked   => pll_locked,
            clk_in1  => PAD_I_CLK
        );

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
            G_DATA_WIDTH         => C_RESYNC_DEFAULT_VALUE'length,
            G_DATA_DEFAULT_VALUE => C_RESYNC_DEFAULT_VALUE
        )
        port map (
            CLK          => internal_clk,
            RST_N        => internal_rst_n,
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
            CLK               => internal_clk,
            RST_N             => internal_rst_n,
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
            CLK                 => internal_clk,
            RST_N               => internal_rst_n,
            I_SWITCHES          => sync_inputs_slv,
            I_SPI_RX_DATA       => spi_rx_data,
            I_SPI_RX_DATA_VALID => spi_rx_data_valid,
            I_READ_ADDR         => read_addr,
            I_READ_ADDR_VALID   => read_addr_valid,
            O_READ_DATA         => read_data,
            O_READ_DATA_VALID   => read_data_valid,
            I_WRITE_ADDR        => write_addr,
            I_WRITE_DATA        => write_data,
            I_WRITE_VALID       => write_addr_valid,
            O_LED_0             => PAD_O_LED_0,
            O_SPI_TX_DATA       => spi_tx_data,
            O_SPI_TX_DATA_VALID => spi_tx_data_valid,
            O_VGA_MODE          => reg_vga_mode,
            O_RED               => reg_red,
            O_GREEN             => reg_green,
            O_BLUE              => reg_blue
        );

    -- =================================================================================================================
    -- SPI MODULE
    -- =================================================================================================================

    inst_spi_master : entity lib_rtl.spi_master
        generic map (
            G_CLK_FREQ_HZ  => C_CLK_FREQ_HZ,
            G_SPI_FREQ_HZ  => C_SPI_FREQ_HZ,
            G_NB_DATA_BITS => C_SPI_NB_DATA_BITS,
            G_CLK_POLARITY => C_CLK_POLARITY,
            G_CLK_PHASE    => C_CLK_PHASE
        )
        port map (
            CLK             => internal_clk,
            RST_N           => internal_rst_n,
            O_SCLK          => PAD_O_SCLK,
            O_MOSI          => PAD_O_MOSI,
            I_MISO          => PAD_I_MISO,
            O_CS_N          => PAD_O_CS_N,
            I_TX_DATA       => spi_tx_data,
            I_TX_DATA_VALID => spi_tx_data_valid,
            O_RX_DATA       => spi_rx_data,
            O_RX_DATA_VALID => spi_rx_data_valid
        );

    -- =================================================================================================================
    -- VGA MODULE
    -- =================================================================================================================

    inst_vga : entity lib_rtl.vga_controller
        generic map (
            -- Horizontal timings (current: 640x480@60Hz)
            G_H_PIXELS      => C_H_PIXELS,
            G_H_FRONT_PORCH => C_H_FRONT_PORCH,
            G_H_SYNC_PULSE  => C_H_SYNC_PULSE,
            G_H_BACK_PORCH  => C_H_BACK_PORCH,

            -- Vertical timings (current: 640x480@60Hz)
            G_V_PIXELS      => C_V_PIXELS,
            G_V_FRONT_PORCH => C_V_FRONT_PORCH,
            G_V_SYNC_PULSE  => C_V_SYNC_PULSE,
            G_V_BACK_PORCH  => C_V_BACK_PORCH
        )
        port map (
            CLK            => vga_clk,
            RST_N          => internal_rst_n,
            O_HSYNC        => PAD_O_VGA_HSYNC,
            O_VSYNC        => PAD_O_VGA_VSYNC,
            I_MANUAL_RED   => reg_red,
            I_MANUAL_GREEN => reg_green,
            I_MANUAL_BLUE  => reg_blue,
            O_RED          => PAD_O_VGA_RED,
            O_GREEN        => PAD_O_VGA_GREEN,
            O_BLUE         => PAD_O_VGA_BLUE
        );

end architecture TOP_FPGA_ARCH;
