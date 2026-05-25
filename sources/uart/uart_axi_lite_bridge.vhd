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
-- @file    uart_axi_lite_bridge.vhd
-- @version 2.3
-- @brief   AXI4-Lite UART bridge providing a command-based interface to read and write registers over UART.
-- @author  Timothee Charrier
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      21/10/2025  Timothee Charrier   Initial release
-- 1.1      10/12/2025  Timothee Charrier   Naming conventions update and remove generic
-- 2.0      12/01/2026  Timothee Charrier   Convert reset signal from active-low to active-high
-- 2.1      22/01/2026  Timothee Charrier   Improve FSM readability by adding a soft reset instead of using a condition
--                                          in clocked p_fsm_seq process.
-- 2.2      09/04/2026  Timothee Charrier   Refactor soft reset sequential process to be more clear and concise.
-- 2.3      24/05/2026  Timothee Charrier   Update UART interface to AXI4-Lite and update the protocol accordingly.
--          25/05/2026                      Rename `RST` to `ARST` to reflect asynchronous reset nature.
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library lib_rtl;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity UART_AXI_LITE_BRIDGE is
    generic (
        G_CLK_FREQ_HZ   : positive := 50_000_000; -- Clock frequency in Hz
        G_BAUD_RATE_BPS : positive := 115_200;    -- Baud rate
        G_SAMPLING_RATE : positive := 16          -- Sampling rate (number of clock cycles per bit)
    );
    port (
        -- Clock and reset
        CLK            : in    std_logic;
        ARST_P         : in    std_logic;
        -- UART interface
        I_UART_RX      : in    std_logic;
        O_UART_TX      : out   std_logic;
        -- AXI4-Lite interface for register access
        M_AXIL_AWREADY : in    std_logic;
        M_AXIL_AWVALID : out   std_logic;
        M_AXIL_AWADDR  : out   std_logic_vector( 8 - 1 downto 0);
        M_AXIL_AWPROT  : out   std_logic_vector( 2 downto 0);
        M_AXIL_WREADY  : in    std_logic;
        M_AXIL_WVALID  : out   std_logic;
        M_AXIL_WDATA   : out   std_logic_vector(32 - 1 downto 0);
        M_AXIL_WSTRB   : out   std_logic_vector( 4 - 1 downto 0);
        M_AXIL_BREADY  : out   std_logic;
        M_AXIL_BVALID  : in    std_logic;
        M_AXIL_BRESP   : in    std_logic_vector( 1 downto 0);
        M_AXIL_ARREADY : in    std_logic;
        M_AXIL_ARVALID : out   std_logic;
        M_AXIL_ARADDR  : out   std_logic_vector( 8 - 1 downto 0);
        M_AXIL_ARPROT  : out   std_logic_vector( 2 downto 0);
        M_AXIL_RREADY  : out   std_logic;
        M_AXIL_RVALID  : in    std_logic;
        M_AXIL_RDATA   : in    std_logic_vector(32 - 1 downto 0);
        M_AXIL_RRESP   : in    std_logic_vector( 1 downto 0)
    );
end entity UART_AXI_LITE_BRIDGE;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================

architecture UART_AXI_LITE_BRIDGE_ARCH of UART_AXI_LITE_BRIDGE is

    -- =================================================================================================================
    -- TYPES
    -- =================================================================================================================

    type t_ascii_to_hex is record
        ascii : std_logic_vector(8 - 1 downto 0);
        hex   : std_logic_vector(4 - 1 downto 0);
    end record t_ascii_to_hex;

    type t_state is (

        -- Waiting for 'R' or 'W' command
        STATE_IDLE,

        -- Write mode states
        STATE_WRITE_MODE,           -- Receiving address and data bytes
        STATE_WRITE_MODE_END,       -- Validating write command
        STATE_WRITE_MODE_WAIT_RESP, -- Waiting for write response

        -- Read mode states
        STATE_READ_MODE,           -- Receiving address bytes
        STATE_READ_MODE_WAIT_DATA, -- Waiting for register data
        STATE_READ_MODE_SEND_DATA, -- Transmitting data as hex ASCII
        STATE_READ_MODE_END        -- Completing read operation
    );

    -- =================================================================================================================
    -- CONSTANTS
    -- =================================================================================================================

    -- Number of byte to count
    constant C_READ_MODE_BYTE_COUNT  : positive := 3;  -- ADDR        + CR
    constant C_WRITE_MODE_BYTE_COUNT : positive := 11; -- ADDR + DATA + CR

    -- Number of bytes to transmit
    constant C_TX_DATA_BYTES         : positive := 8; -- Number of hex chars to transmit + CR (starting from 0)

    -- ASCII to hexadecimal conversion table

    -- vsg_off
    constant C_CHAR_0                : t_ascii_to_hex := (ascii => x"30", hex => "0000");
    constant C_CHAR_1                : t_ascii_to_hex := (ascii => x"31", hex => "0001");
    constant C_CHAR_2                : t_ascii_to_hex := (ascii => x"32", hex => "0010");
    constant C_CHAR_3                : t_ascii_to_hex := (ascii => x"33", hex => "0011");
    constant C_CHAR_4                : t_ascii_to_hex := (ascii => x"34", hex => "0100");
    constant C_CHAR_5                : t_ascii_to_hex := (ascii => x"35", hex => "0101");
    constant C_CHAR_6                : t_ascii_to_hex := (ascii => x"36", hex => "0110");
    constant C_CHAR_7                : t_ascii_to_hex := (ascii => x"37", hex => "0111");
    constant C_CHAR_8                : t_ascii_to_hex := (ascii => x"38", hex => "1000");
    constant C_CHAR_9                : t_ascii_to_hex := (ascii => x"39", hex => "1001");
    constant C_CHAR_A                : t_ascii_to_hex := (ascii => x"41", hex => "1010");
    constant C_CHAR_B                : t_ascii_to_hex := (ascii => x"42", hex => "1011");
    constant C_CHAR_C                : t_ascii_to_hex := (ascii => x"43", hex => "1100");
    constant C_CHAR_D                : t_ascii_to_hex := (ascii => x"44", hex => "1101");
    constant C_CHAR_E                : t_ascii_to_hex := (ascii => x"45", hex => "1110");
    constant C_CHAR_F                : t_ascii_to_hex := (ascii => x"46", hex => "1111");
    -- vsg_on

    -- Other useful ASCII characters
    constant C_CHAR_CR               : std_logic_vector(8 - 1 downto 0) := x"0D"; -- Carriage return character
    constant C_CHAR_R                : std_logic_vector(8 - 1 downto 0) := x"52"; -- 'R' character
    constant C_CHAR_W                : std_logic_vector(8 - 1 downto 0) := x"57"; -- 'W' character

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- Soft reset (when receiving 'R' or 'W' char)
    signal rst_soft_p                : std_logic;

    -- FSM signals
    signal current_state             : t_state;
    signal next_state                : t_state;
    signal next_read_valid           : std_logic;
    signal next_write_valid          : std_logic;

    -- RX module signals
    signal rx_byte_count             : unsigned(4 - 1 downto 0);
    signal rx_byte                   : std_logic_vector( 8 - 1 downto 0);
    signal rx_byte_decoded           : std_logic_vector( 4 - 1 downto 0);
    signal rx_byte_valid             : std_logic;

    -- TX module signals
    signal tx_byte_count             : unsigned(4 - 1 downto 0);
    signal tx_byte_to_send           : std_logic_vector( 4 - 1 downto 0);
    signal tx_byte_to_send_encoded   : std_logic_vector( 8 - 1 downto 0);
    signal tx_byte_to_send_valid     : std_logic;
    signal tx_byte_send              : std_logic;

    -- Stored data to send via UART after a read transaction
    signal data_to_send              : std_logic_vector(32 - 1 downto 0);

    -- AXI4-Lite handshake
    signal read_addr_hs              : std_logic;
    signal read_data_hs              : std_logic;
    signal write_addr_hs             : std_logic;
    signal write_data_hs             : std_logic;
    signal write_resp_hs             : std_logic;

begin

    -- =================================================================================================================
    -- UART TX MODULE
    -- =================================================================================================================

    inst_uart_tx : entity lib_rtl.uart_tx
        generic map (
            G_CLK_FREQ_HZ   => G_CLK_FREQ_HZ,
            G_BAUD_RATE_BPS => G_BAUD_RATE_BPS
        )
        port map (
            CLK             => CLK,
            ARST_P          => ARST_P,
            I_TX_DATA       => tx_byte_to_send_encoded,
            I_TX_DATA_VALID => tx_byte_to_send_valid,
            O_UART_TX       => O_UART_TX,
            O_DONE          => tx_byte_send
        );

    -- =================================================================================================================
    -- TX DATA DECODING
    -- =================================================================================================================

    -- Converting the hexadecimal values to their ASCII representation
    tx_byte_to_send_encoded <= C_CHAR_CR      when tx_byte_count = C_TX_DATA_BYTES else
                               C_CHAR_0.ascii when tx_byte_to_send = C_CHAR_0.hex  else
                               C_CHAR_1.ascii when tx_byte_to_send = C_CHAR_1.hex  else
                               C_CHAR_2.ascii when tx_byte_to_send = C_CHAR_2.hex  else
                               C_CHAR_3.ascii when tx_byte_to_send = C_CHAR_3.hex  else
                               C_CHAR_4.ascii when tx_byte_to_send = C_CHAR_4.hex  else
                               C_CHAR_5.ascii when tx_byte_to_send = C_CHAR_5.hex  else
                               C_CHAR_6.ascii when tx_byte_to_send = C_CHAR_6.hex  else
                               C_CHAR_7.ascii when tx_byte_to_send = C_CHAR_7.hex  else
                               C_CHAR_8.ascii when tx_byte_to_send = C_CHAR_8.hex  else
                               C_CHAR_9.ascii when tx_byte_to_send = C_CHAR_9.hex  else
                               C_CHAR_A.ascii when tx_byte_to_send = C_CHAR_A.hex  else
                               C_CHAR_B.ascii when tx_byte_to_send = C_CHAR_B.hex  else
                               C_CHAR_C.ascii when tx_byte_to_send = C_CHAR_C.hex  else
                               C_CHAR_D.ascii when tx_byte_to_send = C_CHAR_D.hex  else
                               C_CHAR_E.ascii when tx_byte_to_send = C_CHAR_E.hex  else
                               C_CHAR_F.ascii when tx_byte_to_send = C_CHAR_F.hex  else
                               8x"00";

    -- =================================================================================================================
    -- UART RX MODULE
    -- =================================================================================================================

    inst_uart_rx : entity lib_rtl.uart_rx
        generic map (
            G_CLK_FREQ_HZ   => G_CLK_FREQ_HZ,
            G_BAUD_RATE_BPS => G_BAUD_RATE_BPS,
            G_SAMPLING_RATE => G_SAMPLING_RATE
        )
        port map (
            CLK               => CLK,
            ARST_P            => ARST_P,
            I_UART_RX         => I_UART_RX,
            O_BYTE            => rx_byte,
            O_BYTE_VALID      => rx_byte_valid,
            O_START_BIT_ERROR => open,
            O_STOP_BIT_ERROR  => open
        );

    -- =================================================================================================================
    -- RX DATA DECODING
    -- =================================================================================================================

    -- Converting the received ASCII-encoded hexadecimal data to binary
    rx_byte_decoded <= C_CHAR_0.hex when rx_byte = C_CHAR_0.ascii else
                       C_CHAR_1.hex when rx_byte = C_CHAR_1.ascii else
                       C_CHAR_2.hex when rx_byte = C_CHAR_2.ascii else
                       C_CHAR_3.hex when rx_byte = C_CHAR_3.ascii else
                       C_CHAR_4.hex when rx_byte = C_CHAR_4.ascii else
                       C_CHAR_5.hex when rx_byte = C_CHAR_5.ascii else
                       C_CHAR_6.hex when rx_byte = C_CHAR_6.ascii else
                       C_CHAR_7.hex when rx_byte = C_CHAR_7.ascii else
                       C_CHAR_8.hex when rx_byte = C_CHAR_8.ascii else
                       C_CHAR_9.hex when rx_byte = C_CHAR_9.ascii else
                       C_CHAR_A.hex when rx_byte = C_CHAR_A.ascii else
                       C_CHAR_B.hex when rx_byte = C_CHAR_B.ascii else
                       C_CHAR_C.hex when rx_byte = C_CHAR_C.ascii else
                       C_CHAR_D.hex when rx_byte = C_CHAR_D.ascii else
                       C_CHAR_E.hex when rx_byte = C_CHAR_E.ascii else
                       C_CHAR_F.hex when rx_byte = C_CHAR_F.ascii else
                       4x"0";

    -- AXI4-Lite handshake detection
    read_addr_hs  <= '1' when (M_AXIL_ARVALID = '1' and M_AXIL_ARREADY = '1') else
                     '0';
    read_data_hs  <= '1' when (M_AXIL_RVALID = '1' and M_AXIL_RREADY = '1') else
                     '0';
    write_addr_hs <= '1' when (M_AXIL_AWVALID = '1' and M_AXIL_AWREADY = '1') else
                     '0';
    write_data_hs <= '1' when (M_AXIL_WVALID = '1' and M_AXIL_WREADY = '1') else
                     '0';
    write_resp_hs <= '1' when (M_AXIL_BVALID = '1' and M_AXIL_BREADY = '1') else
                     '0';

    -- =================================================================================================================
    -- FSM sequential process for state transitions and byte count
    -- =================================================================================================================

    -- Generate a soft reset when receiving any valid 'R' or 'W' character
    rst_soft_p <= '1' when (rx_byte_valid = '1' and rx_byte = C_CHAR_R) else -- 'R'
                  '1' when (rx_byte_valid = '1' and rx_byte = C_CHAR_W) else -- 'W'
                  '0';

    p_fsm_seq : process (CLK, ARST_P) is
    begin

        if (ARST_P = '1') then

            current_state         <= STATE_IDLE;
            rx_byte_count         <= (others => '0');
            tx_byte_count         <= (others => '0');
            tx_byte_to_send_valid <= '0';

        elsif rising_edge(CLK) then

            -- Synchronous soft reset
            if (rst_soft_p = '1') then
                current_state         <= STATE_IDLE;
                rx_byte_count         <= (others => '0');
                tx_byte_count         <= (others => '0');
                tx_byte_to_send_valid <= '0';

            else

                -- Transition to the next state.
                current_state <= next_state;

                -- RX byte count
                if (current_state = STATE_IDLE) then
                    rx_byte_count <= (others => '0');
                elsif (rx_byte_valid = '1') then
                    rx_byte_count <= rx_byte_count + 1;
                end if;

                -- TX byte count
                if (current_state = STATE_IDLE) then
                    tx_byte_count         <= (others => '0');
                    tx_byte_to_send_valid <= '0';
                elsif (read_data_hs = '1') then
                    tx_byte_count         <= (others => '0');
                    tx_byte_to_send_valid <= '1';
                elsif (tx_byte_send = '1') then
                    tx_byte_count         <= tx_byte_count + 1;
                    tx_byte_to_send_valid <= '1';
                else
                    tx_byte_to_send_valid <= '0';
                end if;

            end if;

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
            -- In idle state, wait for a 'R' or 'W' character to start a new command
            -- =========================================================================================================

            when STATE_IDLE =>

                if (rx_byte = C_CHAR_R) then
                    next_state <= STATE_READ_MODE;
                elsif (rx_byte = C_CHAR_W) then
                    next_state <= STATE_WRITE_MODE;
                end if;

            -- =========================================================================================================
            -- STATE: READ_MODE
            -- =========================================================================================================
            -- In this mode, we decode the incoming read address
            -- Protocol is: R01\r
            --       Where:     - 0  is the address MSB
            --                  - 1  is the address LSB
            --                  - \r is the carriage return
            -- =========================================================================================================

            when STATE_READ_MODE =>

                if (rx_byte_count >= C_READ_MODE_BYTE_COUNT) then

                    -- Check if the last received character is a \r
                    if (rx_byte = C_CHAR_CR) then
                        next_state <= STATE_READ_MODE_END;
                    else
                        next_state <= STATE_IDLE;
                    end if;

                else
                    next_state <= STATE_READ_MODE;
                end if;

            -- =========================================================================================================
            -- STATE: READ_MODE_END
            -- =========================================================================================================
            -- After receiving the line feed character, go back to idle state and raise the data valid signal
            -- =========================================================================================================

            when STATE_READ_MODE_END =>

                next_state <= STATE_READ_MODE_WAIT_DATA;

            -- =========================================================================================================
            -- STATE: READ_MODE_WAIT_DATA
            -- =========================================================================================================
            -- Wait for the data from the regblock
            -- =========================================================================================================

            when STATE_READ_MODE_WAIT_DATA =>

                if (read_data_hs = '1') then
                    next_state <= STATE_READ_MODE_SEND_DATA;
                else
                    next_state <= STATE_READ_MODE_WAIT_DATA;
                end if;

            -- =========================================================================================================
            -- STATE: READ_MODE_SEND_DATA
            -- =========================================================================================================
            -- Send the data via uart
            -- =========================================================================================================

            when STATE_READ_MODE_SEND_DATA =>

                if (tx_byte_count >= C_TX_DATA_BYTES) then
                    next_state <= STATE_IDLE;
                else
                    next_state <= STATE_READ_MODE_SEND_DATA;
                end if;

            -- =========================================================================================================
            -- STATE: WRITE_MODE
            -- =========================================================================================================
            -- In this mode, we decode the incoming write address and data
            -- Protocol is: RAB12345678\r
            --       Where:     - A        is the address MSB
            --                  - B        is the address LSB
            --                  - 12345678 is the data
            --                  - \r       is the carriage return
            -- =========================================================================================================

            when STATE_WRITE_MODE =>

                if (rx_byte_count = C_WRITE_MODE_BYTE_COUNT) then

                    -- Check if the last received character is a \r
                    if (rx_byte = C_CHAR_CR) then
                        next_state <= STATE_WRITE_MODE_END;
                    else
                        next_state <= STATE_IDLE;
                    end if;

                else
                    next_state <= STATE_WRITE_MODE;
                end if;

            -- =========================================================================================================
            -- STATE: WRITE_MODE_END
            -- =========================================================================================================
            -- After receiving the line feed character, go back to idle state and raise the data valid signal
            -- =========================================================================================================

            when STATE_WRITE_MODE_END =>

                next_state <= STATE_WRITE_MODE_WAIT_RESP;

            -- =========================================================================================================
            -- STATE: WRITE_MODE_WAIT_RESP
            -- =========================================================================================================

            when STATE_WRITE_MODE_WAIT_RESP =>

                if (write_resp_hs = '1') then
                    next_state <= STATE_IDLE;
                else
                    next_state <= STATE_WRITE_MODE_WAIT_RESP;
                end if;

        end case;

    end process p_next_state_comb;

    -- =================================================================================================================
    -- Output logic
    -- =================================================================================================================

    p_next_outputs_comb : process (all) is
    begin

        -- Default assignment
        next_read_valid  <= '0';
        next_write_valid <= '0';
        tx_byte_to_send  <= (others => '0');

        case current_state is

            -- =========================================================================================================
            -- STATE: IDLE
            -- =========================================================================================================

            when STATE_IDLE =>

            -- =========================================================================================================
            -- STATE: READ_MODE
            -- =========================================================================================================
            -- In this mode, we decode the incoming read address.
            -- The rx_byte_count start after receiving a 'W' or 'R'.
            -- Protocol is: R01\r
            --       Where:     - 0  is the address MSB
            --                  - 1  is the address LSB
            --                  - \r is the carriage return
            -- =========================================================================================================

            when STATE_READ_MODE =>

            -- =========================================================================================================
            -- STATE: READ_MODE_END
            -- =========================================================================================================

            when STATE_READ_MODE_END =>

                next_read_valid <= '1';

            -- =========================================================================================================
            -- STATE: READ_MODE_WAIT_DATA
            -- =========================================================================================================

            when STATE_READ_MODE_WAIT_DATA =>

            -- =========================================================================================================
            -- STATE: READ_MODE_WAIT_DATA
            -- =========================================================================================================

            when STATE_READ_MODE_SEND_DATA =>

                -- Select the data

                case tx_byte_count is

                    -- vsg_off
                    when "0000"  => tx_byte_to_send <= data_to_send(31 downto 28); -- Data (bits 31 - 28)
                    when "0001"  => tx_byte_to_send <= data_to_send(27 downto 24); -- Data (bits 27 - 24)
                    when "0010"  => tx_byte_to_send <= data_to_send(23 downto 20); -- Data (bits 23 - 20)
                    when "0011"  => tx_byte_to_send <= data_to_send(19 downto 16); -- Data (bits 19 - 16)
                    when "0100"  => tx_byte_to_send <= data_to_send(15 downto 12); -- Data (bits 15 - 12)
                    when "0101"  => tx_byte_to_send <= data_to_send(11 downto  8); -- Data (bits 11 -  8)
                    when "0110"  => tx_byte_to_send <= data_to_send( 7 downto  4); -- Data (bits  7 -  4)
                    when "0111"  => tx_byte_to_send <= data_to_send( 3 downto  0); -- Data (bits  3 -  0)
                    when others => null;
                    -- vsg_on

                end case;

            -- =========================================================================================================
            -- STATE: WRITE_MODE
            -- =========================================================================================================
            -- In this mode, we decode the incoming write address and data.
            -- The rx_byte_count start after receiving a 'W' or 'R'.
            -- Protocol is: RAB12345678\r
            --       Where:     - A        is the address MSB
            --                  - B        is the address LSB
            --                  - 12345678 is the data
            --                  - \r       is the carriage return
            -- =========================================================================================================

            when STATE_WRITE_MODE =>

            -- =========================================================================================================
            -- STATE: WRITE_MODE_END
            -- =========================================================================================================

            when STATE_WRITE_MODE_END =>

                next_write_valid <= '1';

            when STATE_WRITE_MODE_WAIT_RESP =>

        end case;

    end process p_next_outputs_comb;

    -- =================================================================================================================
    -- AXI4-Lite signal assignments
    -- =================================================================================================================

    p_axil_signals_seq : process (CLK, ARST_P) is
    begin

        if (ARST_P = '1') then

            data_to_send   <= (others => '0');

            M_AXIL_AWVALID <= '0';
            M_AXIL_AWADDR  <= (others => '0');
            M_AXIL_AWPROT  <= (others => '0');
            M_AXIL_WVALID  <= '0';
            M_AXIL_WDATA   <= (others => '0');
            M_AXIL_WSTRB   <= (others => '0');
            M_AXIL_BREADY  <= '0';
            M_AXIL_ARVALID <= '0';
            M_AXIL_ARADDR  <= (others => '0');
            M_AXIL_ARPROT  <= (others => '0');
            M_AXIL_RREADY  <= '0';

        elsif rising_edge(CLK) then

            -- Tied off signals
            M_AXIL_AWPROT <= (others => '0');
            M_AXIL_ARPROT <= (others => '0');

            -- Synchronous soft reset
            if (rst_soft_p = '1') then

                data_to_send   <= (others => '0');

                M_AXIL_AWVALID <= '0';
                M_AXIL_WVALID  <= '0';
                M_AXIL_BREADY  <= '0';
                M_AXIL_ARVALID <= '0';
                M_AXIL_RREADY  <= '0';
                M_AXIL_WSTRB   <= (others => '0');

            else

                -- Read address channel
                if (next_read_valid = '1') then
                    M_AXIL_ARVALID <= '1';
                elsif (read_addr_hs = '1') then
                    M_AXIL_ARVALID <= '0';
                end if;

                -- Read data channel
                if (read_addr_hs = '1') then
                    M_AXIL_RREADY <= '1';
                elsif (read_data_hs = '1') then
                    M_AXIL_RREADY <= '0';
                end if;

                if (read_data_hs = '1') then
                    data_to_send <= M_AXIL_RDATA;
                end if;

                -- Write address channel
                if (next_write_valid = '1') then
                    M_AXIL_AWVALID <= '1';
                elsif (write_addr_hs = '1') then
                    M_AXIL_AWVALID <= '0';
                end if;

                -- Write data channel
                if (next_write_valid = '1') then
                    M_AXIL_WVALID <= '1';
                    M_AXIL_WSTRB  <= (others => '1');
                elsif (write_data_hs = '1') then
                    M_AXIL_WVALID <= '0';
                end if;

                -- Write response channel
                if (next_write_valid = '1') then
                    M_AXIL_BREADY <= '1';
                elsif (write_resp_hs = '1') then
                    M_AXIL_BREADY <= '0';
                end if;

                -- Update the read address and valid signal
                if (rx_byte_valid = '1') then

                    case rx_byte_count is

                        -- vsg_off
                        when "0000" => M_AXIL_ARADDR(7 downto 4) <= rx_byte_decoded; -- Addr MSB
                        when "0001" => M_AXIL_ARADDR(3 downto 0) <= rx_byte_decoded; -- Addr LSB
                        when others => null;
                        -- vsg_on

                    end case;

                end if;

                -- Update the write address, data and valid signal
                if (rx_byte_valid = '1') then

                    case rx_byte_count is

                        -- vsg_off
                        when "0000" => M_AXIL_AWADDR(7 downto  4) <= rx_byte_decoded; -- Addr MSB
                        when "0001" => M_AXIL_AWADDR(3 downto  0) <= rx_byte_decoded; -- Addr LSB
                        when "0010" => M_AXIL_WDATA(31 downto 28) <= rx_byte_decoded; -- Data (bits 31 - 28)
                        when "0011" => M_AXIL_WDATA(27 downto 24) <= rx_byte_decoded; -- Data (bits 27 - 24)
                        when "0100" => M_AXIL_WDATA(23 downto 20) <= rx_byte_decoded; -- Data (bits 23 - 20)
                        when "0101" => M_AXIL_WDATA(19 downto 16) <= rx_byte_decoded; -- Data (bits 19 - 16)
                        when "0110" => M_AXIL_WDATA(15 downto 12) <= rx_byte_decoded; -- Data (bits 15 - 12)
                        when "0111" => M_AXIL_WDATA(11 downto  8) <= rx_byte_decoded; -- Data (bits 11 -  8)
                        when "1000" => M_AXIL_WDATA( 7 downto  4) <= rx_byte_decoded; -- Data (bits  7 -  4)
                        when "1001" => M_AXIL_WDATA( 3 downto  0) <= rx_byte_decoded; -- Data (bits  3 -  0)
                        when others => null;
                        -- vsg_on

                    end case;

                end if;

            end if;

        end if;

    end process p_axil_signals_seq;

end architecture UART_AXI_LITE_BRIDGE_ARCH;
