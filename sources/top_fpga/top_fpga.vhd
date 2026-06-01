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
-- @file    top_fpga.vhd
-- @version 2.2
-- @brief   Top-Level of the FPGA
-- @author  Timothee Charrier
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      01/12/2025  Timothee Charrier   Initial release
-- 1.1      10/12/2025  Timothee Charrier   Remove generic from UART module, update resync_slv module generic names
-- 1.2      16/12/2025  Timothee Charrier   Use new PLL outputting a 50 MHz and 25 MHz clock
-- 1.3      17/12/2025  Timothee Charrier   Update regfile module to interface with new VGA module
-- 1.4      09/01/2026  Timothee Charrier   The FPGA now uses open-logic modules for clock domain crossing. Also
--                                          update the VGA timings to 1024*768@60Hz.
-- 2.0      14/01/2026  Timothee Charrier   Convert reset signal from active-low to active-high and now uses synchronous
--                                          async reset.
-- 2.1      11/04/2026  Timothee Charrier   Add GIT_ID flag as generic for the regfile module.
-- 2.2      23/05/2026  Timothee Charrier   Use SystemRDL-generated registers and update the UART interface to AXI4-Lite
--                                          LED now indicates AXI bad address transactions.
--                                          Add FPGA_ID generic and register.
--          25/05/2026                      Rename `RST` to `ARST` to reflect asynchronous reset nature.
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;

library olo;

library lib_rtl;
    use lib_rtl.regblock_pkg.all;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity TOP_FPGA is
    generic (
        G_GIT_ID     : std_logic_vector(32 - 1 downto 0) := (others => '0');
        G_GIT_STATUS : std_logic                         := '0';
        G_FPGA_ID    : std_logic_vector(32 - 1 downto 0) := (others => '0')
    );
    port (
        -- Clock and reset
        PAD_I_CLK       : in    std_logic;
        PAD_I_RST_P     : in    std_logic;

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

    -- General
    constant C_CLK_FREQ_HZ          : positive  := 50_000_000;
    constant C_RST_POLARITY         : std_logic := '1';

    -- Resynchronization
    constant C_RESYNC_WIDTH         : positive  := 3;
    constant C_RESYNC_DEFAULT_VALUE : std_logic := '0';
    constant C_RESYNC_NB_STAGES     : positive  := 3;

    -- UART
    constant C_BAUD_RATE_BPS        : positive := 115_200;
    constant C_SAMPLING_RATE        : positive := 16;

    -- SPI
    constant C_SPI_FREQ_HZ          : positive  := 1_000_000;
    constant C_SPI_NB_DATA_BITS     : positive  := 8;
    constant C_CLK_POLARITY         : std_logic := '0';
    constant C_CLK_PHASE            : std_logic := '0';

    -- VGA (current: 1024x768@60Hz)
    constant C_H_PIXELS             : positive := 1024;
    constant C_H_FRONT_PORCH        : positive := 24;
    constant C_H_SYNC_PULSE         : positive := 136;
    constant C_H_BACK_PORCH         : positive := 160;

    constant C_V_PIXELS             : positive := 768;
    constant C_V_FRONT_PORCH        : positive := 3;
    constant C_V_SYNC_PULSE         : positive := 6;
    constant C_V_BACK_PORCH         : positive := 29;

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- Internal reset and clock
    signal internal_clk             : std_logic;
    signal vga_clk                  : std_logic;
    signal pll_locked               : std_logic;
    signal intermediate_rst_p       : std_logic;
    signal internal_sys_arst_p      : std_logic;
    signal internal_vga_arst_p      : std_logic;

    -- Resynchronization
    signal async_inputs_slv         : std_logic_vector(C_RESYNC_WIDTH - 1 downto 0);
    signal sync_inputs_slv          : std_logic_vector(C_RESYNC_WIDTH - 1 downto 0);

    -- Reglock signals
    signal axil_awready             : std_logic;
    signal axil_awvalid             : std_logic;
    signal axil_awaddr              : std_logic_vector(REGBLOCK_MIN_ADDR_WIDTH - 1 downto 0);
    signal axil_awprot              : std_logic_vector(2 downto 0);
    signal axil_wready              : std_logic;
    signal axil_wvalid              : std_logic;
    signal axil_wdata               : std_logic_vector(REGBLOCK_DATA_WIDTH - 1 downto 0);
    signal axil_wstrb               : std_logic_vector(REGBLOCK_DATA_WIDTH / 8 - 1 downto 0);
    signal axil_bready              : std_logic;
    signal axil_bvalid              : std_logic;
    signal axil_bresp               : std_logic_vector(1 downto 0);
    signal axil_arready             : std_logic;
    signal axil_arvalid             : std_logic;
    signal axil_araddr              : std_logic_vector(REGBLOCK_MIN_ADDR_WIDTH - 1 downto 0);
    signal axil_arprot              : std_logic_vector(2 downto 0);
    signal axil_rready              : std_logic;
    signal axil_rvalid              : std_logic;
    signal axil_rdata               : std_logic_vector(REGBLOCK_DATA_WIDTH - 1 downto 0);
    signal axil_rresp               : std_logic_vector(1 downto 0);
    signal hwif_in                  : regblock_in_t;
    signal hwif_out                 : regblock_out_t;

    -- VGA registers
    signal manual_colors            : std_logic_vector(11 downto 0);

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

    -- =================================================================================================================
    -- PLL and positive reset logic
    -- =================================================================================================================

    inst_pll : component clk_wiz_0
        port map (
            clk_out1 => internal_clk,
            clk_out2 => vga_clk,
            reset    => PAD_I_RST_P,
            locked   => pll_locked,
            clk_in1  => PAD_I_CLK
        );

    -- Toggle reset from BTN or when PLL is unlocked
    intermediate_rst_p <= PAD_I_RST_P or (not pll_locked);

    -- System clock domain positive reset generation
    inst_olo_base_sys_reset_gen : entity olo.olo_base_reset_gen
        generic map (
            RSTPULSECYCLES_G   => 3,                 -- Minimum duration of the reset pulse in clock cycles
            RSTINPOLARITY_G    => C_RST_POLARITY,    -- Polarity of 'RstIn'
            ASYNCRESETOUTPUT_G => false,             -- Asserted synchronously
            SYNCSTAGES_G       => C_RESYNC_NB_STAGES -- Number of synchronization stages
        )
        port map (
            Clk    => internal_clk,
            RstOut => internal_sys_arst_p,
            RstIn  => intermediate_rst_p
        );

    -- VGA clock domain positive reset generation
    inst_olo_base_vga_reset_gen : entity olo.olo_base_reset_gen
        generic map (
            RSTPULSECYCLES_G   => 3,
            RSTINPOLARITY_G    => C_RST_POLARITY,
            ASYNCRESETOUTPUT_G => false,
            SYNCSTAGES_G       => C_RESYNC_NB_STAGES
        )
        port map (
            Clk    => vga_clk,
            RstOut => internal_vga_arst_p,
            RstIn  => intermediate_rst_p
        );

    -- =================================================================================================================
    -- RESYNCHRONIZATION FOR EXTERNAL SIGNALS
    -- =================================================================================================================

    async_inputs_slv <=
    (
        2 => PAD_I_SWITCH_2,
        1 => PAD_I_SWITCH_1,
        0 => PAD_I_SWITCH_0
    );

    inst_olo_intf_sync : entity olo.olo_intf_sync
        generic map (
            WIDTH_G      => C_RESYNC_WIDTH,
            RSTLEVEL_G   => C_RESYNC_DEFAULT_VALUE,
            SYNCSTAGES_G => C_RESYNC_NB_STAGES
        )
        port map (
            Clk       => internal_clk,
            Rst       => internal_sys_arst_p,
            DataAsync => async_inputs_slv,
            DataSync  => sync_inputs_slv
        );

    -- =================================================================================================================
    -- UART to AXI4-LITE BRIDGE MODULE
    -- =================================================================================================================

    inst_uart_axi_lite_bridge : entity lib_rtl.uart_axi_lite_bridge
        generic map (
            G_CLK_FREQ_HZ   => C_CLK_FREQ_HZ,
            G_BAUD_RATE_BPS => C_BAUD_RATE_BPS,
            G_SAMPLING_RATE => C_SAMPLING_RATE
        )
        port map (
            CLK            => internal_clk,
            ARST_P         => internal_sys_arst_p,
            I_UART_RX      => PAD_I_UART_RX,
            O_UART_TX      => PAD_O_UART_TX,
            M_AXIL_AWREADY => axil_awready,
            M_AXIL_AWVALID => axil_awvalid,
            M_AXIL_AWADDR  => axil_awaddr,
            M_AXIL_AWPROT  => axil_awprot,
            M_AXIL_WREADY  => axil_wready,
            M_AXIL_WVALID  => axil_wvalid,
            M_AXIL_WDATA   => axil_wdata,
            M_AXIL_WSTRB   => axil_wstrb,
            M_AXIL_BREADY  => axil_bready,
            M_AXIL_BVALID  => axil_bvalid,
            M_AXIL_BRESP   => axil_bresp,
            M_AXIL_ARREADY => axil_arready,
            M_AXIL_ARVALID => axil_arvalid,
            M_AXIL_ARADDR  => axil_araddr,
            M_AXIL_ARPROT  => axil_arprot,
            M_AXIL_RREADY  => axil_rready,
            M_AXIL_RVALID  => axil_rvalid,
            M_AXIL_RDATA   => axil_rdata,
            M_AXIL_RRESP   => axil_rresp
        );

    -- =================================================================================================================
    -- REGBLOCK MODULE
    -- =================================================================================================================

    -- FPGA information registers
    hwif_in.git_hash.hash.next_q     <= G_GIT_ID;
    hwif_in.git_status.status.next_q <= G_GIT_STATUS;
    hwif_in.fpga_id.id.next_q        <= G_FPGA_ID;

    -- Switches registers
    hwif_in.switch_status.switch_2.next_q <= sync_inputs_slv(2);
    hwif_in.switch_status.switch_1.next_q <= sync_inputs_slv(1);
    hwif_in.switch_status.switch_0.next_q <= sync_inputs_slv(0);

    inst_reglock : entity lib_rtl.regblock
        port map (
            clk            => internal_clk,
            arst           => internal_sys_arst_p,
            s_axil_awready => axil_awready,
            s_axil_awvalid => axil_awvalid,
            s_axil_awaddr  => axil_awaddr,
            s_axil_awprot  => axil_awprot,
            s_axil_wready  => axil_wready,
            s_axil_wvalid  => axil_wvalid,
            s_axil_wdata   => axil_wdata,
            s_axil_wstrb   => axil_wstrb,
            s_axil_bready  => axil_bready,
            s_axil_bvalid  => axil_bvalid,
            s_axil_bresp   => axil_bresp,
            s_axil_arready => axil_arready,
            s_axil_arvalid => axil_arvalid,
            s_axil_araddr  => axil_araddr,
            s_axil_arprot  => axil_arprot,
            s_axil_rready  => axil_rready,
            s_axil_rvalid  => axil_rvalid,
            s_axil_rdata   => axil_rdata,
            s_axil_rresp   => axil_rresp,
            hwif_in        => hwif_in,
            hwif_out       => hwif_out
        );

    -- vsg_off: increment bad_address_counter on AXI error responses
    hwif_in.bad_address_counter.count.incr   <= '1' when ((axil_bvalid = '1' and axil_bready = '1' and axil_bresp = "10")
                                                        or
                                                          (axil_rvalid = '1' and axil_rready = '1' and axil_rresp = "10")) else
                                                '0';

    hwif_in.bad_address_counter.count.next_q <= hwif_out.bad_address_counter.count.value;
    -- vsg_on

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
            ARST_P          => internal_sys_arst_p,
            O_SCLK          => PAD_O_SCLK,
            O_MOSI          => PAD_O_MOSI,
            I_MISO          => PAD_I_MISO,
            O_CS_N          => PAD_O_CS_N,
            I_TX_DATA       => hwif_out.spi_tx_control.tx_data.value,
            I_TX_DATA_VALID => hwif_out.spi_tx_control.tx_data_valid.value,
            O_RX_DATA       => hwif_in.spi_rx_data.rx_data.next_q
        );

    -- =================================================================================================================
    -- VGA MODULE
    -- =================================================================================================================

    manual_colors <= hwif_out.vga_color_control.red.value   &
                     hwif_out.vga_color_control.green.value &
                     hwif_out.vga_color_control.blue.value;

    inst_vga : entity lib_rtl.vga_controller
        generic map (
            G_H_PIXELS      => C_H_PIXELS,
            G_H_FRONT_PORCH => C_H_FRONT_PORCH,
            G_H_SYNC_PULSE  => C_H_SYNC_PULSE,
            G_H_BACK_PORCH  => C_H_BACK_PORCH,
            G_V_PIXELS      => C_V_PIXELS,
            G_V_FRONT_PORCH => C_V_FRONT_PORCH,
            G_V_SYNC_PULSE  => C_V_SYNC_PULSE,
            G_V_BACK_PORCH  => C_V_BACK_PORCH
        )
        port map (
            -- System clock domain
            CLK_SYS         => internal_clk,
            ARST_SYS_P      => internal_sys_arst_p,
            I_MANUAL_COLORS => manual_colors,
            -- VGA clock domain
            CLK_VGA         => vga_clk,
            ARST_VGA_P      => internal_vga_arst_p,
            O_HSYNC         => PAD_O_VGA_HSYNC,
            O_VSYNC         => PAD_O_VGA_VSYNC,
            O_RED           => PAD_O_VGA_RED,
            O_GREEN         => PAD_O_VGA_GREEN,
            O_BLUE          => PAD_O_VGA_BLUE
        );

    -- =================================================================================================================
    -- LED CONTROL: LED_0 is ON when the value of the counter 'bad_address_counter' is greater than 0
    -- =================================================================================================================

    p_led : process (internal_clk, internal_sys_arst_p) is
    begin

        if (internal_sys_arst_p = '1') then

            PAD_O_LED_0 <= '0';

        elsif rising_edge(internal_clk) then

            if (hwif_out.bad_address_counter.count.value > x"00000000") then
                PAD_O_LED_0 <= '1';
            else
                PAD_O_LED_0 <= '0';
            end if;

        end if;

    end process p_led;

end architecture TOP_FPGA_ARCH;
