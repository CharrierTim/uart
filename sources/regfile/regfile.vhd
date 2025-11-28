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
-- @file    registers.vhd
-- @version 1.0
-- @brief   Registers for the FPGA
-- @author  Timothee Charrier
-- @date    20/10/2025
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
        CLK               : in    std_logic;
        RST_N             : in    std_logic;

        -- Inputs switches
        I_SWITCHES        : in    std_logic_vector(3 - 1 downto 0);

        -- Read data interface
        I_READ_ADDR       : in    std_logic_vector( 8 - 1 downto 0);
        I_READ_ADDR_VALID : in    std_logic;
        O_READ_DATA       : out   std_logic_vector(16 - 1 downto 0);
        O_READ_DATA_VALID : out   std_logic;

        -- Write data interface
        I_WRITE_ADDR      : in    std_logic_vector( 8 - 1 downto 0);
        I_WRITE_DATA      : in    std_logic_vector(16 - 1 downto 0);
        I_WRITE_VALID     : in    std_logic;

        -- Output
        O_LED_0           : out   std_logic;
        O_SPI_DATA        : out   std_logic_vector(8 - 1 downto 0);
        O_SPI_DATA_VALID  : out   std_logic
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
    signal reg_spi     : std_logic_vector(C_REG_SPI_RST'range);
    signal reg_led     : std_logic;
    signal reg_16_bits : std_logic_vector(16 - 1 downto 0);

    -- Read interface
    signal reg_read    : std_logic_vector(16 - 1 downto 0);

begin

    -- =================================================================================================================
    -- READ/WRITE PROCESS
    -- =================================================================================================================

    p_reg : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            -- Read data valid flag
            O_READ_DATA_VALID <= '0';

            -- RW registers
            reg_spi     <= C_REG_SPI_RST;
            reg_led     <= C_REG_LED_RST;
            reg_16_bits <= C_REG_16_BITS_RST;

            -- Read interface
            reg_read <= G_GIT_ID_MSB;

        elsif rising_edge(CLK) then

            -- =========================================================================================================
            -- Valid flags (read/write only take one clock cycle)
            -- =========================================================================================================

            O_READ_DATA_VALID <= I_READ_ADDR_VALID;

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

                    when C_REG_SPI_ADDR =>

                        reg_read <= 7b"0" & reg_spi;

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

                    when C_REG_SPI_ADDR =>

                        reg_spi <= I_WRITE_DATA(reg_spi'range);

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

    O_READ_DATA      <= reg_read;
    O_LED_0          <= reg_led;
    O_SPI_DATA       <= reg_spi(reg_spi'high - 1 downto reg_spi'low);
    O_SPI_DATA_VALID <= reg_spi(reg_spi'high);

end architecture REGFILE_ARCH;
