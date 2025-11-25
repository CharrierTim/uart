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
-- @file    spi_master.vhd
-- @version 1.0
-- @brief   SPI master module.
--
--              +----------+-------+-----------------------------------------------------------------------+
--              | POLARITY | PHASE | Action                                                                |
--              +----------+-------+-----------------------------------------------------------------------+
--              | 0        | 0     | Data is output on the rising edge of SPICLK.                          |
--              |          |       | Input data is latched on the falling edge.                            |
--              +----------+-------+-----------------------------------------------------------------------+
--              | 0        | 1     | Data is output one half-cycle before the first rising edge of SPICLK  |
--              |          |       | and on subsequent falling edges.                                      |
--              |          |       | Input data is latched on the rising edge of SPICLK.                   |
--              +----------+-------+-----------------------------------------------------------------------+
--              | 1        | 0     | Data is output on the falling edge of SPICLK.                         |
--              |          |       | Input data is latched on the rising edge.                             |
--              +----------+-------+-----------------------------------------------------------------------+
--              | 1        | 1     | Data is output one half-cycle before the first falling edge of SPICLK |
--              |          |       | and on subsequent rising edges.                                       |
--              |          |       | Input data is latched on the falling edge of SPICLK.                  |
--              +----------+-------+-----------------------------------------------------------------------+
--
-- @author  Timothee Charrier
-- @date    24/11/2025
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity SPI_MASTER is
    generic (
        G_CLK_FREQ_HZ  : positive := 50_000_000; -- Clock frequency in Hz
        G_SPI_FREQ_HZ  : positive := 281_000;    -- SPI clock frequency in Hz
        G_NB_DATA_BITS : positive := 8           -- Number of data bits
    );
    port (
        -- Clock and reset
        CLK             : in    std_logic;
        RST_N           : in    std_logic;
        -- Control interface
        I_CLK_POLARITY  : in    std_logic; -- SPI clock polarity
        I_CLK_PHASE     : in    std_logic; -- SPI clock phase
        I_CONFIG_VALID  : in    std_logic; -- Polarity and phase valid
        -- SPI interface
        O_SCLK          : out   std_logic; -- Serial Clock
        O_MOSI          : out   std_logic; -- Master Out Slave In
        I_MISO          : in    std_logic; -- Master In Slave Out
        O_CS            : out   std_logic; -- Chip select
        -- Data interface
        I_TX_BYTE       : in    std_logic_vector(G_NB_DATA_BITS - 1 downto 0);
        I_TX_BYTE_VALID : in    std_logic;
        O_RX_BYTE       : out   std_logic_vector(G_NB_DATA_BITS - 1 downto 0);
        O_RX_BYTE_VALID : out   std_logic
    );
end entity SPI_MASTER;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================
architecture SPI_MASTER_ARCH of SPI_MASTER is

    -- =================================================================================================================
    -- TYPES
    -- =================================================================================================================

    type t_state is (
        STATE_IDLE,
        STATE_INIT,
        STATE_SEND_BITS,
        STATE_DEAD_TIME,
        STATE_DONE
    );

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    constant C_NB_BYTE_WIDTH         : integer := integer(ceil(log2(real(G_NB_DATA_BITS)))) + 1;

    constant C_CLK_DIV_RATIO         : integer := G_CLK_FREQ_HZ / G_SPI_FREQ_HZ / 2;
    constant C_CLK_DIV_RATIO_WIDTH   : integer := integer(ceil(log2(real(C_CLK_DIV_RATIO))));
    constant C_DEAD_TIME_COUNT       : integer := C_CLK_DIV_RATIO / 2;
    constant C_DEAD_TIME_COUNT_WIDTH : integer := integer(ceil(log2(real(C_DEAD_TIME_COUNT))));

    -- =================================================================================================================
    -- SIGNAL
    -- =================================================================================================================

    -- FSM signals
    signal current_state             : t_state;
    signal next_state                : t_state;
    signal next_o_cs                 : std_logic;
    signal next_o_rx_byte_valid      : std_logic;

    -- Internal registers
    signal reg_sclk                  : std_logic;
    signal next_o_sclk               : std_logic;
    signal reg_mosi                  : std_logic;
    signal reg_clk_polarity          : std_logic;
    signal reg_clk_phase             : std_logic;
    signal reg_tx_byte               : std_logic_vector(G_NB_DATA_BITS - 1 downto 0);
    signal reg_tx_byte_shifted       : std_logic_vector(G_NB_DATA_BITS - 1 downto 0);
    signal reg_rx_byte               : std_logic_vector(G_NB_DATA_BITS - 1 downto 0);
    signal reg_edge_detect           : std_logic;
    signal reg_edge_detect_d1        : std_logic;

    -- Counters
    signal reg_clk_div_counter       : unsigned(C_CLK_DIV_RATIO_WIDTH - 1 downto 0);
    signal reg_bit_counter           : unsigned(C_NB_BYTE_WIDTH - 1 downto 0);
    signal reg_dead_time_counter     : unsigned(C_DEAD_TIME_COUNT_WIDTH - 1 downto 0);

begin

    -- =================================================================================================================
    -- FSM sequential process for state transitions
    -- =================================================================================================================

    p_fsm_seq : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            current_state <= STATE_IDLE;

        elsif rising_edge(CLK) then

            current_state <= next_state;

        end if;

    end process p_fsm_seq;

    -- =================================================================================================================
    -- FSM combinatorial process for next state logic
    -- =================================================================================================================

    p_next_state_comb : process (all) is
    begin

        -- Default assignment
        next_state <= STATE_IDLE;

        case current_state is

            -- =========================================================================================================
            -- STATE: IDLE
            -- =========================================================================================================
            -- In idle state, the module awaits a valid data signal to initiate transmission.
            -- =========================================================================================================

            when STATE_IDLE =>

                if (I_TX_BYTE_VALID = '1') then
                    next_state <= STATE_INIT;
                else
                    next_state <= STATE_IDLE;
                end if;

            -- =========================================================================================================
            -- STATE: INIT
            -- =========================================================================================================
            -- In init state...
            -- =========================================================================================================

            when STATE_INIT =>

                next_state <= STATE_SEND_BITS;

            -- =========================================================================================================
            -- STATE: SEND BITS
            -- =========================================================================================================
            -- In send bits state...
            -- =========================================================================================================

            when STATE_SEND_BITS =>

                if (reg_bit_counter > G_NB_DATA_BITS and reg_edge_detect = '1') then
                    next_state <= STATE_DEAD_TIME;
                else
                    next_state <= STATE_SEND_BITS;
                end if;

            -- =========================================================================================================
            -- STATE: DEAD TIME
            -- =========================================================================================================
            -- In dead time state...
            -- =========================================================================================================

            when STATE_DEAD_TIME =>

                if (reg_dead_time_counter >= C_DEAD_TIME_COUNT - 1) then
                    next_state <= STATE_DONE;
                else
                    next_state <= STATE_DEAD_TIME;
                end if;

            -- =========================================================================================================
            -- STATE: DONE
            -- =========================================================================================================
            -- In done state, assert byte valid for one clock cycle
            -- =========================================================================================================

            when STATE_DONE =>

                next_state <= STATE_IDLE;

        end case;

    end process p_next_state_comb;

    -- =================================================================================================================
    -- Register the inputs when byte valid is asserted and current state is IDLE to avoid changing data during the
    -- transmisison
    -- =================================================================================================================

    p_reg_inputs : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            reg_clk_polarity <= '0';
            reg_clk_phase    <= '0';
            reg_tx_byte      <= (others => '0');

        elsif rising_edge(CLK) then

            if (I_TX_BYTE_VALID = '1' and current_state = STATE_IDLE) then
                reg_tx_byte <= I_TX_BYTE;
            end if;

            if (I_CONFIG_VALID = '1') then
                reg_clk_polarity <= I_CLK_POLARITY;
                reg_clk_phase    <= I_CLK_PHASE;
            end if;

        end if;

    end process p_reg_inputs;

    -- =================================================================================================================
    -- Next output logic
    -- =================================================================================================================

    p_next_output_comb : process (all) is
    begin

        -- Default assignments
        next_o_cs            <= '1';
        next_o_rx_byte_valid <= '0';

        case current_state is

            -- =========================================================================================================
            -- STATE: IDLE
            -- =========================================================================================================

            when STATE_IDLE =>

            -- =========================================================================================================
            -- STATE: INIT
            -- =========================================================================================================

            when STATE_INIT =>

                next_o_cs <= '0';

            -- =========================================================================================================
            -- STATE: SEND BITS
            -- =========================================================================================================

            when STATE_SEND_BITS =>

                next_o_cs <= '0';

            -- =========================================================================================================
            -- STATE: DEAD TIME
            -- =========================================================================================================

            when STATE_DEAD_TIME =>

            -- =========================================================================================================
            -- STATE: DONE
            -- =========================================================================================================

            when STATE_DONE =>

                next_o_rx_byte_valid <= '1';

        end case;

    end process p_next_output_comb;

    -- =================================================================================================================
    -- Generate the SPI clock based on the FPGA system clock and detect edge transitions
    -- =================================================================================================================

    p_clk_gen : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            reg_clk_div_counter <= (others => '0');
            reg_sclk            <= '0';
            reg_edge_detect     <= '0';
            reg_edge_detect_d1  <= '0';

        elsif rising_edge(CLK) then

            -- =========================================================================================================
            -- Delayed edge detection for proper RX sampling timing
            -- =========================================================================================================

            reg_edge_detect_d1 <= reg_edge_detect;

            -- =========================================================================================================
            -- Generate internal SPI clock divider
            -- =========================================================================================================

            if (current_state = STATE_SEND_BITS) then

                if (reg_clk_div_counter >= C_CLK_DIV_RATIO - 1) then
                    reg_clk_div_counter <= (others => '0');
                    reg_sclk            <= not reg_sclk;
                    reg_edge_detect     <= '1';
                else
                    reg_clk_div_counter <= reg_clk_div_counter + 1;
                    reg_edge_detect     <= '0';
                end if;

            else
                -- Reset all clock generation signals when not actively transmitting
                reg_clk_div_counter <= (others => '0');
                reg_sclk            <= '0';
                reg_edge_detect     <= '0';
            end if;

        end if;

    end process p_clk_gen;

    -- =================================================================================================================
    -- Output SPI clock with polarity adjustment
    -- =================================================================================================================

    p_sclk_output : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            next_o_sclk <= '0';

        elsif rising_edge(CLK) then

            if (current_state = STATE_SEND_BITS or current_state = STATE_DEAD_TIME) then

                if (reg_clk_polarity = '1') then
                    next_o_sclk <= not reg_sclk;
                else
                    next_o_sclk <= reg_sclk;
                end if;
            else
                next_o_sclk <= reg_clk_polarity;
            end if;

        end if;

    end process p_sclk_output;

    -- =================================================================================================================
    -- Dead time counter waiting some time before finishing the communication
    -- =================================================================================================================

    p_dead_time_count : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            reg_dead_time_counter <= (others => '0');

        elsif rising_edge(CLK) then

            if (current_state = STATE_DEAD_TIME) then
                reg_dead_time_counter <= reg_dead_time_counter + 1;
            else
                reg_dead_time_counter <= (others => '0');
            end if;

        end if;

    end process p_dead_time_count;

    -- =================================================================================================================
    -- Serialize the TX byte to MOSI
    -- =================================================================================================================

    reg_tx_byte_shifted <= std_logic_vector(shift_left(unsigned(reg_tx_byte), to_integer(reg_bit_counter)));

    p_spi_tx : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then
            reg_mosi        <= '0';
            reg_bit_counter <= (others => '0');

        elsif rising_edge(CLK) then

            -- Pre-communication state: MSB bit output when clock phase = 0
            if (current_state = STATE_INIT and reg_clk_phase = '0') then

                reg_mosi        <= reg_tx_byte(reg_tx_byte'high);
                reg_bit_counter <= reg_bit_counter + 1;

            -- During communication
            elsif (current_state = STATE_SEND_BITS or current_state = STATE_DEAD_TIME) then

                -- clock phase = 0: Change data on falling edge of SCLK
                if (reg_clk_phase = '0') then

                    if (reg_sclk = '0' and reg_edge_detect = '1') then
                        reg_mosi        <= reg_tx_byte_shifted(reg_tx_byte_shifted'high);
                        reg_bit_counter <= reg_bit_counter + 1;
                    end if;

                -- clock phase = 1: Change data on rising edge of SCLK
                else

                    if (reg_sclk = '1' and reg_edge_detect = '1') then
                        reg_mosi        <= reg_tx_byte_shifted(reg_tx_byte_shifted'high);
                        reg_bit_counter <= reg_bit_counter + 1;
                    end if;

                end if;

            -- Reset counter when in idle state
            elsif (current_state = STATE_IDLE) then
                reg_bit_counter <= (others => '0');
            end if;

        end if;

    end process p_spi_tx;

    -- =================================================================================================================
    -- De-serialize the RX from MISO
    -- =================================================================================================================

    p_spi_rx : process (CLK, RST_N) is
    begin

        if (RST_N = '0') then

            reg_rx_byte     <= (others => '0');
            O_RX_BYTE       <= (others => '0');
            O_RX_BYTE_VALID <= '0';

        elsif rising_edge(CLK) then

            -- Mode 0 (CPOL=0, CPHA=0) or Mode 3 (CPOL=1, CPHA=1): Sample on rising edge of output clock
            if (((reg_clk_polarity = '0' and reg_clk_phase = '0')  or
                 (reg_clk_polarity = '1' and reg_clk_phase = '1')) and
                next_o_sclk = '1'                                  and
                reg_edge_detect_d1 = '1'
            ) then

                reg_rx_byte <= reg_rx_byte(reg_rx_byte'high - 1 downto reg_rx_byte'low) & I_MISO;

            -- Mode 1 (CPOL=0, CPHA=1) or Mode 2 (CPOL=1, CPHA=0): Sample on falling edge of output clock
            elsif (((reg_clk_polarity = '0' and reg_clk_phase = '1')  or
                    (reg_clk_polarity = '1' and reg_clk_phase = '0')) and
                   next_o_sclk = '0'                                  and
                   reg_edge_detect_d1 = '1'
               ) then

                reg_rx_byte <= reg_rx_byte(reg_rx_byte'high - 1 downto reg_rx_byte'low) & I_MISO;

            end if;

            -- Output received byte and valid signal
            O_RX_BYTE_VALID <= next_o_rx_byte_valid;

            if (next_o_rx_byte_valid = '1') then
                O_RX_BYTE <= reg_rx_byte;
            end if;

        end if;

    end process p_spi_rx;

    O_MOSI <= reg_mosi when next_o_cs = '0' else
              'Z';
    O_SCLK <= next_o_sclk;
    O_CS   <= next_o_cs;

end architecture SPI_MASTER_ARCH;
