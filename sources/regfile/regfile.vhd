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
-- @file    registers.vhd
-- @version 2.0
-- @brief   Registers for the FPGA
-- @author  Timothee Charrier
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      01/12/2025  Timothee Charrier   Initial release
-- 2.0      14/01/2026  Timothee Charrier   Convert reset signal from active-low to active-high
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;

library lib_rtl;
    use lib_rtl.regfile_pkg.all;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity REGFILE is
    generic (
        G_GIT_ID_MSB : std_logic_vector(16 - 1 downto 0);
        G_GIT_ID_LSB : std_logic_vector(16 - 1 downto 0)
    );
    port (
        -- Clock and reset
        CLK                 : in    std_logic;
        RST_P               : in    std_logic;

        -- Inputs switches
        I_SWITCHES          : in    std_logic_vector( 3 - 1 downto 0);

        -- Input SPI
        I_SPI_RX_DATA       : in    std_logic_vector( 8 - 1 downto 0);
        I_SPI_RX_DATA_VALID : in    std_logic;

        -- Read data interface
        I_READ_ADDR         : in    std_logic_vector( 8 - 1 downto 0);
        I_READ_ADDR_VALID   : in    std_logic;
        O_READ_DATA         : out   std_logic_vector(16 - 1 downto 0);
        O_READ_DATA_VALID   : out   std_logic;

        -- Write data interface
        I_WRITE_ADDR        : in    std_logic_vector( 8 - 1 downto 0);
        I_WRITE_DATA        : in    std_logic_vector(16 - 1 downto 0);
        I_WRITE_VALID       : in    std_logic;

        -- Output
        O_LED_0             : out   std_logic;
        O_SPI_TX_DATA       : out   std_logic_vector( 8 - 1 downto 0);
        O_SPI_TX_DATA_VALID : out   std_logic;
        O_VGA_COLORS        : out   std_logic_vector(12 - 1 downto 0)
    );
end entity REGFILE;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================

architecture REGFILE_ARCH of REGFILE is

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- RW registers
    signal reg_spi_tx   : std_logic_vector(C_REG_SPI_TX_RST'range);
    signal reg_spi_rx   : std_logic_vector(C_REG_SPI_RX_RST'range);
    signal reg_vga_ctrl : std_logic_vector(C_REG_VGA_CTRL_RST'range);
    signal reg_led      : std_logic;
    signal reg_16_bits  : std_logic_vector(16 - 1 downto 0);

    -- Read interface
    signal reg_read     : std_logic_vector(16 - 1 downto 0);

begin

    -- =================================================================================================================
    -- READ/WRITE PROCESS
    -- =================================================================================================================

    p_reg : process (CLK, RST_P) is
    begin

        if (RST_P = '1') then

            -- Read data valid flag
            O_READ_DATA_VALID <= '0';

            -- RW registers
            reg_spi_tx   <= C_REG_SPI_TX_RST;
            reg_spi_rx   <= C_REG_SPI_RX_RST;
            reg_vga_ctrl <= C_REG_VGA_CTRL_RST;
            reg_led      <= C_REG_LED_RST;
            reg_16_bits  <= C_REG_16_BITS_RST;

            -- Read interface
            reg_read <= G_GIT_ID_MSB;

        elsif rising_edge(CLK) then

            -- =========================================================================================================
            -- Valid flags (read/write only take one clock cycle)
            -- =========================================================================================================

            O_READ_DATA_VALID <= I_READ_ADDR_VALID;

            -- =========================================================================================================
            -- Update SPI RX data when valid
            -- =========================================================================================================

            if (I_SPI_RX_DATA_VALID = '1') then
                reg_spi_rx <= I_SPI_RX_DATA;
            end if;

            -- =========================================================================================================
            -- READ HANDLING
            -- =========================================================================================================

            if (I_READ_ADDR_VALID = '1') then

                case I_READ_ADDR is

                    when C_REG_GIT_ID_MSB_ADDR =>

                        reg_read <= G_GIT_ID_MSB;

                    when C_REG_GIT_ID_LSB_ADDR =>

                        reg_read <= G_GIT_ID_LSB;

                    when C_REG_12_ADDR =>

                        reg_read <= C_REG_12_DATA;

                    when C_REG_34_ADDR =>

                        reg_read <= C_REG_34_DATA;

                    when C_REG_56_ADDR =>

                        reg_read <= C_REG_56_DATA;

                    when C_REG_78_ADDR =>

                        reg_read <= C_REG_78_DATA;

                    when C_REG_SPI_TX_ADDR =>

                        reg_read <= 7b"0" & reg_spi_tx;

                    when C_REG_SPI_RX_ADDR =>

                        reg_read <= 8b"0" & reg_spi_rx;

                    when C_REG_VGA_CTRL_ADDR =>

                        reg_read <= 4b"0" & reg_vga_ctrl;

                    when C_REG_9A_ADDR =>

                        reg_read <= C_REG_9A_DATA;

                    when C_REG_CD_ADDR =>

                        reg_read <= C_REG_CD_DATA;

                    when C_REG_EF_ADDR =>

                        reg_read <= C_REG_EF_DATA;

                    when C_REG_SWITCHES_ADDR =>

                        reg_read <= 13b"0" & I_SWITCHES;

                    when C_REG_LED_ADDR =>

                        reg_read <= 15b"0" & reg_led;

                    when C_REG_16_BITS_ADDR =>

                        reg_read <= reg_16_bits;

                    when others =>

                        reg_read <= C_REG_DEAD;

                end case;

            end if;

            -- =========================================================================================================
            -- WRITE HANDLING
            -- =========================================================================================================

            if (I_WRITE_VALID = '1') then

                case I_WRITE_ADDR is

                    when C_REG_SPI_TX_ADDR =>

                        reg_spi_tx <= I_WRITE_DATA(reg_spi_tx'range);

                    when C_REG_VGA_CTRL_ADDR =>

                        reg_vga_ctrl <= I_WRITE_DATA(reg_vga_ctrl'range);

                    when C_REG_LED_ADDR =>

                        reg_led <= I_WRITE_DATA(0);

                    when C_REG_16_BITS_ADDR =>

                        reg_16_bits <= I_WRITE_DATA;

                    when others =>

                end case;

            end if;

        end if;

    end process p_reg;

    -- =================================================================================================================
    -- OUTPUTS
    -- =================================================================================================================

    O_READ_DATA         <= reg_read;
    O_LED_0             <= reg_led;
    O_SPI_TX_DATA       <= reg_spi_tx(reg_spi_tx'high - 1 downto reg_spi_tx'low);
    O_SPI_TX_DATA_VALID <= reg_spi_tx(reg_spi_tx'high);
    O_VGA_COLORS        <= reg_vga_ctrl(11 downto 0);

end architecture REGFILE_ARCH;
