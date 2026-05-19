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
-- @file    tb_regblock.vhd
-- @version 1.0
-- @brief   Regblock testbench
-- @author  Timothee Charrier
-- =====================================================================================================================
-- REVISION HISTORY
--
-- Version  Date        Author              Description
-- -------  ----------  ------------------  ----------------------------------------------------------------------------
-- 1.0      16/05/2026  Timothee Charrier   Initial release
-- =====================================================================================================================

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library lib_rtl;
    use lib_rtl.axi4lite_intf_pkg.all;
    use lib_rtl.regblock_pkg.all;

library vunit_lib;
    use vunit_lib.signal_checker_pkg.all;
    context vunit_lib.vunit_context;
    context vunit_lib.com_context;
    context vunit_lib.vc_context;

library osvvm;
    use osvvm.randompkg.randomptype;

library lib_bench;
    use lib_bench.tb_regblock_pkg.all;

-- =====================================================================================================================
-- ENTITY
-- =====================================================================================================================

entity TB_REGBLOCK is
    generic (
        RUNNER_CFG : string
    );
end entity TB_REGBLOCK;

-- =====================================================================================================================
-- ARCHITECTURE
-- =====================================================================================================================

architecture TB_REGBLOCK_ARCH of TB_REGBLOCK is

    -- =================================================================================================================
    -- SIGNALS
    -- =================================================================================================================

    -- DUT signals
    signal tb_clk         : std_logic;
    signal tb_arst_h      : std_logic;
    signal tb_s_axil_i    : axi4lite_slave_in_intf(
                                                   AWADDR(REGBLOCK_MIN_ADDR_WIDTH - 1 downto 0),
                                                   WDATA(REGBLOCK_DATA_WIDTH - 1 downto 0),
                                                   WSTRB(REGBLOCK_DATA_WIDTH / 8 - 1 downto 0),
                                                   ARADDR(REGBLOCK_MIN_ADDR_WIDTH - 1 downto 0));
    signal tb_s_axil_o    : axi4lite_slave_out_intf(RDATA(REGBLOCK_DATA_WIDTH - 1 downto 0));
    signal tb_hwif_in     : regblock_in_t;
    signal tb_hwif_out    : regblock_out_t;

    -- AXI-Lite master <-> slave signals
    signal arready        : std_logic;
    signal arvalid        : std_logic;
    signal araddr         : std_logic_vector(REGBLOCK_MIN_ADDR_WIDTH - 1 downto 0);

    signal rready         : std_logic;
    signal rvalid         : std_logic;
    signal rdata          : std_logic_vector(REGBLOCK_DATA_WIDTH - 1 downto 0);
    signal rresp          : std_logic_vector(1 downto 0);

    signal awready        : std_logic;
    signal awvalid        : std_logic;
    signal awaddr         : std_logic_vector(REGBLOCK_MIN_ADDR_WIDTH - 1 downto 0);

    signal wready         : std_logic;
    signal wvalid         : std_logic;
    signal wdata          : std_logic_vector(REGBLOCK_DATA_WIDTH - 1 downto 0);
    signal wstrb          : std_logic_vector(REGBLOCK_DATA_WIDTH / 8 - 1 downto 0);

    signal bvalid         : std_logic;
    signal bready         : std_logic;
    signal bresp          : std_logic_vector(1 downto 0);

    -- =================================================================================================================
    -- CONSTANTS for verification components
    -- =================================================================================================================

    constant C_BUS_HANDLE : bus_master_t := new_bus(
            data_length    => wdata'length,
            address_length => awaddr'length);

begin

    -- =================================================================================================================
    -- DUT
    -- =================================================================================================================

    dut : entity lib_rtl.regblock
        port map (
            clk      => tb_clk,
            arst     => tb_arst_h,
            s_axil_i => tb_s_axil_i,
            s_axil_o => tb_s_axil_o,
            hwif_in  => tb_hwif_in,
            hwif_out => tb_hwif_out
        );

    -- =================================================================================================================
    -- AXI-LITE VERIFICATION COMPONENT
    -- =================================================================================================================

    inst_axi_lite_master : entity vunit_lib.axi_lite_master
        generic map (
            BUS_HANDLE => C_BUS_HANDLE
        )
        port map (
            aclk    => tb_clk,
            arready => arready,
            arvalid => arvalid,
            araddr  => araddr,
            rready  => rready,
            rvalid  => rvalid,
            rdata   => rdata,
            rresp   => rresp,
            awready => awready,
            awvalid => awvalid,
            awaddr  => awaddr,
            wready  => wready,
            wvalid  => wvalid,
            wdata   => wdata,
            wstrb   => wstrb,
            bvalid  => bvalid,
            bready  => bready,
            bresp   => bresp
        );

    tb_s_axil_i.AWVALID <= awvalid;
    tb_s_axil_i.AWADDR  <= awaddr;
    tb_s_axil_i.AWPROT  <= "000";

    tb_s_axil_i.WVALID  <= wvalid;
    tb_s_axil_i.WDATA   <= wdata;
    tb_s_axil_i.WSTRB   <= wstrb;

    tb_s_axil_i.BREADY  <= bready;
    tb_s_axil_i.ARVALID <= arvalid;
    tb_s_axil_i.ARADDR  <= araddr;
    tb_s_axil_i.ARPROT  <= "000";
    tb_s_axil_i.RREADY  <= rready;

    arready             <= tb_s_axil_o.ARREADY;
    rvalid              <= tb_s_axil_o.RVALID;
    rdata               <= tb_s_axil_o.RDATA;
    rresp               <= tb_s_axil_o.RRESP;
    awready             <= tb_s_axil_o.AWREADY;
    wready              <= tb_s_axil_o.WREADY;
    bvalid              <= tb_s_axil_o.BVALID;
    bresp               <= tb_s_axil_o.BRESP;

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

        variable v_tmp_data      : std_logic_vector(rdata'range);
        variable v_expected_data : std_logic_vector(rdata'range);
        variable v_rnd           : randomptype;
        variable v_rnd_reg       : t_reg
                (
                name(1 to C_REG_TEST_REGISTER_1.name'length)
               );

        -- =============================================================================================================
        -- proc_reset_dut
        -- Description: This procedure resets the DUT to a known state.
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
            tb_arst_h                                <= '1';

            tb_hwif_in.GIT_HASH.hash.next_q          <= std_logic_vector(C_REG_GIT_HASH.data);
            tb_hwif_in.GIT_STATUS.status.next_q      <= std_logic(C_REG_GIT_STATUS.data(0));
            tb_hwif_in.FPGA_ID.id.next_q             <= std_logic_vector(C_REG_FPGA_ID.data);
            tb_hwif_in.SPI_RX_DATA.rx_data.next_q    <= std_logic_vector(C_REG_SPI_RX_DATA.data(15 downto 8));
            tb_hwif_in.SWITCH_STATUS.switch_0.next_q <= std_logic(C_REG_Switch_STATUS.data(0));
            tb_hwif_in.SWITCH_STATUS.switch_1.next_q <= std_logic(C_REG_Switch_STATUS.data(1));
            tb_hwif_in.SWITCH_STATUS.switch_2.next_q <= std_logic(C_REG_Switch_STATUS.data(2));

            wait for c_clock_cycles * C_CLK_PERIOD;

            -- Reassert reset
            tb_arst_h                                <= '0';

            -- Wait for the DUT to step over
            wait for 5 ns;

            -- Log the reset action
            info("");
            info("DUT has been reset.");

        end procedure proc_reset_dut;

        -- =============================================================================================================
        -- proc_axi_lite_check
        --
        -- Description: This procedure checks if the value read from a specified AXI-Lite register matches the expected
        --              value and response.
        --
        -- Parameters:
        --   reg            : t_reg            - The register to check.
        --   expected_data  : std_logic_vector - The expected data value to be returned when reading the register.
        --   expected_rresp : axi_resp_t       - The expected response when reading the register.
        --   msg            : string           - A message to display if the check fails.
        --
        -- Example:
        --   proc_axi_lite_check(C_REG_16_BITS, x"ABCD_1234");
        -- or
        --   proc_axi_lite_check(C_REG_16_BITS, x"ABCD_1234", axi_resp_slverr, "Invalid read from register");
        -- =============================================================================================================

        procedure proc_axi_lite_check (
            constant reg            : t_reg;
            constant expected_data  : std_logic_vector;
            constant expected_rresp : axi_resp_t := axi_resp_okay;
            constant msg            : string     := ""
        ) is
            variable v_returned_data : std_logic_vector(rdata'range);
        begin

            info(
                "Reading value from register " & reg.name &
                " at address 0x"               & to_hstring(reg.addr) &
                " and expecting 0x"            & to_hstring(expected_data));

            -- Check the default value of the register after reset
            read_axi_lite(
                net,
                C_BUS_HANDLE,
                reg.addr,
                expected_rresp,
                v_returned_data);

            if (msg'length = 0) then
                check_equal(
                    v_returned_data,
                    expected_data,
                    "Value mismatch for register " & reg.name);
            else
                check_equal(
                    v_returned_data,
                    expected_data,
                    msg);
            end if;

        end procedure proc_axi_lite_check;

        -- =============================================================================================================
        -- proc_axi_lite_write
        --
        -- Description: This procedure writes a value to a specified AXI-Lite register.
        --
        -- Parameters:
        --   reg            : t_reg            - The register to write to.
        --   data           : std_logic_vector - The data value to write to the register.
        --   expected_bresp : axi_resp_t       - The expected response when writing to the register.
        --                                       (optional, default is OKAY)
        --   byte_enable    : std_logic_vector - The byte enable value to use for the write transaction
        --                                       (optional, default is all bytes enabled).
        -- Example:
        --   proc_axi_lite_write(C_REG_16_BITS, x"ABCD_1234");
        -- =============================================================================================================

        procedure proc_axi_lite_write (
            constant reg            : t_reg;
            constant data           : std_logic_vector;
            constant expected_bresp : axi_resp_t                    := axi_resp_okay;
            constant byte_enable    : std_logic_vector(wstrb'range) := (others => '1')
        ) is
        begin

            info(
                "Writing value 0x" & to_hstring(data)     & " to register "           & reg.name               &
                " at address 0x"   & to_hstring(reg.addr) & " with byte enable 0b"    & to_string(byte_enable) &
                " and expecting AXI response `"           & to_string(expected_bresp) & "`");

            -- Check the default value of the register after reset
            write_axi_lite(
                net,
                C_BUS_HANDLE,
                reg.addr,
                data,
                expected_bresp,
                byte_enable);

        end procedure proc_axi_lite_write;

        -- =============================================================================================================
        -- proc_axi_lite_check_default_value
        --
        -- Description: This procedure checks if the default value of a specified AXI-Lite register matches the expected
        --              reset value.
        --
        -- Parameters:
        --   reg : t_reg - The register to check.
        --
        -- Example:
        --   proc_axi_lite_check_default_value(C_REG_16_BITS);
        -- =============================================================================================================

        procedure proc_axi_lite_check_default_value (
            constant reg : t_reg
        ) is
        begin

            info("");
            info("Checking register " & reg.name & " value after reset");

            -- Check the default value of the register after reset
            proc_axi_lite_check(
                reg,
                reg.data,
                axi_resp_okay);

        end procedure proc_axi_lite_check_default_value;

        -- =============================================================================================================
        -- proc_axi_lite_read
        --
        -- Description: This procedure reads a value from a specified AXI-Lite register.
        --              An error is raised if a read-only register is accessed for a write operation -> axi_resp_slverr
        --
        -- Parameters:
        --   reg : t_reg - The register to read from.
        --
        -- Example:
        --   proc_axi_lite_read(C_REG_16_BITS);
        -- =============================================================================================================

        procedure proc_axi_lite_check_read_only (
            constant reg : t_reg
        ) is
        begin

            info("");
            info("Checking register " & reg.name & " is in read-only mode");

            info(
                "Attempting to write value 0x" & to_hstring(not reg.data) & " to register " & reg.name &
                " at address 0x"               & to_hstring(reg.addr));

            -- Attempt to write the opposite reset value to the register
            proc_axi_lite_write(
                reg,
                not reg.data,
                axi_resp_slverr); -- Expecting SLVERR response for write attempts to read-only registers

            -- Check if the register value remains unchanged
            proc_axi_lite_check(
                reg,
                reg.data,
                axi_resp_okay,
                "Read-only register " & reg.name & " value changed after write attempt");

        end procedure proc_axi_lite_check_read_only;

        -- =============================================================================================================
        -- proc_axi_lite_check_read_write
        --
        -- Description: This procedure checks if a specified UART register is read-write by writing a value to it and
        --              verifying that the value is correctly updated.
        --
        -- Parameters:
        --   reg            : t_reg            - The register to check.
        --   expected_value : std_logic_vector - The expected value to compare against after writing.
        --
        -- Example:
        --   proc_axi_lite_check_read_write(C_REG_16_BITS, x"0001");
        -- =============================================================================================================

        procedure proc_axi_lite_check_read_write (
            constant reg : t_reg
        ) is
        begin

            info("");
            info("Checking register " & reg.name & " is in read-write mode");

            wait until rising_edge(tb_clk);

            -- Write the opposite of the reset value to ensure a change is made to the register
            proc_axi_lite_write(reg, (not reg.data) and reg.used_bits_mask);

            -- Check if the register value is updated correctly
            proc_axi_lite_check(
                reg,
                (not reg.data) and reg.used_bits_mask,
                axi_resp_okay,
                "Read-write register " & reg.name & " value mismatch after write");

        end procedure proc_axi_lite_check_read_write;

        -- =============================================================================================================
        -- proc_axi_lite_read_bad_addr
        --
        -- Description: This procedure checks if reading from an invalid AXI-Lite address returns the expected error
        --              response.
        --
        -- Parameters:
        --   addr           : unsigned         - The invalid address to read from.
        --   expected_data  : unsigned         - The expected data value to be returned (0x0 for invalid addresses)
        --   id             : std_logic_vector - The ID to use for the read transaction (optional, default is "X").
        --   ar_valid_delay : time             - The delay before asserting ARVALID     (optional, default is 0 ns).
        --   r_ready_delay  : time             - The delay before asserting RREADY      (optional, default is 0 ns).
        --
        -- Examples:
        --   proc_axi_lite_read_bad_addr(x"1E");
        --   proc_axi_lite_read_bad_addr(x"1F", x"DEAD_BEEF", "X", 0 ns, 0 ns);
        -- =============================================================================================================

        procedure proc_axi_lite_read_bad_addr (
            addr           : std_logic_vector(REGBLOCK_MIN_ADDR_WIDTH - 1 downto 0);
            expected_data  : std_logic_vector(REGBLOCK_DATA_WIDTH - 1 downto 0) := 32x"0000_0000";
            id             : std_logic_vector                                   := "X";
            ar_valid_delay : time                                               := 0 ns;
            r_ready_delay  : time                                               := 0 ns
        ) is
            variable v_returned_data : std_logic_vector(rdata'range);
        begin

            info("");
            info("Checking read from invalid AXI-Lite address 0x" & to_hstring(addr));

            wait until rising_edge(tb_clk);

            read_axi_lite(
                net            => net,
                bus_handle     => C_BUS_HANDLE,
                address        => addr,
                expected_rresp => axi_resp_slverr,
                data           => v_returned_data);

            check_equal(
                v_returned_data,
                std_logic_vector(expected_data),
                "Data mismatch when reading from invalid address 0x" & to_hstring(addr));

        end procedure proc_axi_lite_read_bad_addr;

        -- =============================================================================================================
        -- proc_axi_lite_write_bad_addr
        --
        -- Description: This procedure checks if writing to an invalid AXI-Lite address returns the expected error
        --              response.
        --
        -- Parameters:
        --   addr            : unsigned         - The invalid address to write to.
        --   data            : unsigned         - The data value to write (optional, default is 0xABCD_1234).
        --
        -- Examples:
        --   proc_axi_lite_write_bad_addr(x"1F");
        --   proc_axi_lite_write_bad_addr(x"1F", x"DEAD_BEEF", "1111", "X", 0 ns, 0 ns, 0 ns);
        -- =================================================================================================

        procedure proc_axi_lite_write_bad_addr (
            addr : std_logic_vector(REGBLOCK_MIN_ADDR_WIDTH - 1 downto 0);
            data : std_logic_vector(REGBLOCK_DATA_WIDTH - 1 downto 0) := 32x"ABCD_1234"
        ) is
        begin

            info("");
            info("Checking write to invalid AXI-Lite address 0x" & to_hstring(addr));

            wait until rising_edge(tb_clk);

            write_axi_lite(
                net            => net,
                bus_handle     => C_BUS_HANDLE,
                address        => addr,
                data           => data,
                expected_bresp => axi_resp_slverr);

            check_equal(
                bresp,
                axi_resp_slverr,
                "Response mismatch when writing to invalid address 0x" & to_hstring(addr) &
                " - Got AXI response `" & to_string(bresp) & "` expected SLVERR(0b10)");

        end procedure proc_axi_lite_write_bad_addr;

    begin

        -- Set up the test runner
        test_runner_setup(runner, RUNNER_CFG);

        -- Show PASS log messages for checks
        show(get_logger(default_checker), display_handler, pass);

        -- Set time unit for display handler
        set_format(display_handler, log_time_unit => us);

        -- Disable stop on errors from my_logger and its children
        disable_stop(get_logger(default_checker), error);

        while test_suite loop

            if run("test_regblock_axil_lite_if") then

                -- Reset DUT
                proc_reset_dut;
                wait for 10 us;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Checking AXI-Lite read values after reset");
                info("-----------------------------------------------------------------------------");

                proc_axi_lite_check_default_value(C_REG_GIT_HASH);
                proc_axi_lite_check_default_value(C_REG_GIT_STATUS);
                proc_axi_lite_check_default_value(C_REG_FPGA_ID);
                proc_axi_lite_check_default_value(C_REG_SPI_TX_DATA);
                proc_axi_lite_check_default_value(C_REG_SPI_RX_DATA);
                proc_axi_lite_check_default_value(C_REG_VGA_COLOR);
                proc_axi_lite_check_default_value(C_REG_SWITCH_STATUS);
                proc_axi_lite_check_default_value(C_REG_TEST_REGISTER_1);
                proc_axi_lite_check_default_value(C_REG_TEST_REGISTER_2);

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Checking AXI-Lite read-only registers");
                info("-----------------------------------------------------------------------------");

                proc_axi_lite_check_read_only(C_REG_GIT_HASH);
                proc_axi_lite_check_read_only(C_REG_GIT_STATUS);
                proc_axi_lite_check_read_only(C_REG_FPGA_ID);
                proc_axi_lite_check_read_only(C_REG_SPI_RX_DATA);
                proc_axi_lite_check_read_only(C_REG_SWITCH_STATUS);

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Checking AXI-Lite read-write registers");
                info("-----------------------------------------------------------------------------");

                proc_reset_dut;
                wait for 10 us;

                proc_axi_lite_check_read_write(C_REG_SPI_TX_DATA);
                proc_axi_lite_check_read_write(C_REG_VGA_COLOR);
                proc_axi_lite_check_read_write(C_REG_TEST_REGISTER_1);
                proc_axi_lite_check_read_write(C_REG_TEST_REGISTER_2);

            elsif run("test_regblock_hw_if") then

                -- Reset DUT
                proc_reset_dut;
                wait for 10 us;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Checking HW interface default values after reset");
                info("-----------------------------------------------------------------------------");

                check_equal(
                    tb_hwif_out.spi_rx_data.rx_data.value,
                    C_REG_SPI_RX_DATA.data(15 downto 8),
                    "SPI_RX_DATA[15:8] default value mismatch after reset");

                check_equal(
                    tb_hwif_out.spi_tx_data.tx_data.value,
                    C_REG_SPI_TX_DATA.data(7 downto 0),
                    "SPI_TX_DATA[7:0]  default value mismatch after reset");

                check_equal(
                    tb_hwif_out.vga_color.red.value,
                    C_REG_VGA_COLOR.data(3 downto 0),
                    "VGA_COLOR[3:0]    default value mismatch after reset");

                check_equal(
                    tb_hwif_out.vga_color.green.value,
                    C_REG_VGA_COLOR.data(7 downto 4),
                    "VGA_COLOR[7:4]    default value mismatch after reset");

                check_equal(
                    tb_hwif_out.vga_color.blue.value,
                    C_REG_VGA_COLOR.data(11 downto 8),
                    "VGA_COLOR[11:8]   default value mismatch after reset");

            elsif run("test_regblock_bad_addr") then

                -- Reset DUT
                proc_reset_dut;
                wait for 10 us;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Reading from invalid AXI-Lite address");
                info("-----------------------------------------------------------------------------");

                proc_axi_lite_read_bad_addr(std_logic_vector(to_unsigned(C_REG_MAX_ADDR + 4, araddr'length)));
                proc_axi_lite_read_bad_addr(std_logic_vector(to_unsigned(C_REG_MAX_ADDR + 8, araddr'length)));

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Writing to invalid AXI-Lite address");
                info("-----------------------------------------------------------------------------");

                proc_axi_lite_write_bad_addr(std_logic_vector(to_unsigned(C_REG_MAX_ADDR + 4, awaddr'length)));
                proc_axi_lite_write_bad_addr(std_logic_vector(to_unsigned(C_REG_MAX_ADDR + 8, awaddr'length)));

            elsif run("test_regblock_bad_rw") then

                -- Reset DUT
                proc_reset_dut;
                wait for 10 us;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Writing to a read-only register with write transaction");
                info("-----------------------------------------------------------------------------");

                info("");
                info("Writing to read-only register " & C_REG_GIT_HASH.name & " at address 0x"
                    & to_hstring(C_REG_GIT_HASH.addr) & " with value 0x"    & to_hstring(not C_REG_GIT_HASH.data) &
                    " and expecting SLVERR response");

                -- Doing it manually instead of using proc_axi_lite_write to be able to check the response of the
                -- write transaction without the procedure's checks interfering
                write_axi_lite(
                    net            => net,
                    bus_handle     => C_BUS_HANDLE,
                    address        => C_REG_GIT_HASH.addr,
                    data           => not C_REG_GIT_HASH.data,
                    expected_bresp => axi_resp_slverr);

                wait until rising_edge(tb_clk) and bvalid = '1';

                check_equal(
                    bresp,
                    axi_resp_slverr,
                    "Response mismatch when writing to read-only register " & C_REG_GIT_HASH.name &
                    " and expected SLVERR(10)");

            elsif run("test_regblock_random_rw") then

                -- Reset DUT
                proc_reset_dut;
                wait for 10 us;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Performing random read/write operations on AXI-Lite on TEST registers");
                info("-----------------------------------------------------------------------------");

                for i in 1 to 32 loop

                    v_expected_data := v_rnd.RandSlv(rdata'length);

                    if (v_rnd.RandInt(0, 1) = 0) then
                        v_rnd_reg := C_REG_TEST_REGISTER_1;
                    else
                        v_rnd_reg := C_REG_TEST_REGISTER_2;
                    end if;

                    info("");
                    info("[" & to_string(i) & "/32] Write 0x"  & to_hstring(v_expected_data) & " to register " &
                        v_rnd_reg.name      & " at address 0x" & to_hstring(v_rnd_reg.addr));

                    -- Writes a random value to one of the registers and
                    -- checks if the read value matches the written value
                    proc_axi_lite_write(v_rnd_reg, v_expected_data);
                    proc_axi_lite_check(v_rnd_reg, v_expected_data);

                end loop;

            elsif (run("test_regblock_write_byte_enable")) then

                -- Reset DUT
                proc_reset_dut;
                wait for 10 us;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Checking AXI-Lite write operations with LSB byte enable only");
                info("-----------------------------------------------------------------------------");
                info("");

                proc_axi_lite_write(
                    reg            => C_REG_TEST_REGISTER_1,
                    data           => not C_REG_TEST_REGISTER_1.data,
                    expected_bresp => axi_resp_okay,
                    byte_enable    => "0001"); -- Only the least significant byte should be written

                proc_axi_lite_check(
                    reg            => C_REG_TEST_REGISTER_1,
                    expected_data  => (
                                        (31 downto 8 => C_REG_TEST_REGISTER_1.data(31 downto 8)),
                                        ( 7 downto 0 => not C_REG_TEST_REGISTER_1.data(7 downto 0))
                                      ),
                    expected_rresp => axi_resp_okay,
                    msg            => "Only the least significant byte of TEST_REGISTER_1 should be updated");

                -- Reset DUT
                proc_reset_dut;
                wait for 10 us;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Checking AXI-Lite write operations with byte_enable set to `0b1010`");
                info("-----------------------------------------------------------------------------");
                info("");

                proc_axi_lite_write(
                    reg            => C_REG_TEST_REGISTER_1,
                    data           => not C_REG_TEST_REGISTER_1.data,
                    expected_bresp => axi_resp_okay,
                    byte_enable    => "1010"); -- MSB and 3rd byte should be written

                proc_axi_lite_check(
                    reg            => C_REG_TEST_REGISTER_1,
                    expected_data  => (
                                        (31 downto 24 => not C_REG_TEST_REGISTER_1.data(31 downto 24)),
                                        (23 downto 16 => C_REG_TEST_REGISTER_1.data(23 downto 16)),
                                        (15 downto 8  => not C_REG_TEST_REGISTER_1.data(15 downto 8)),
                                        ( 7 downto 0  => C_REG_TEST_REGISTER_1.data(7 downto 0))
                                      ),
                    expected_rresp => axi_resp_okay,
                    msg            => "Only the MSB and the third byte of TEST_REGISTER_1 should be updated");

            end if;

        end loop;

        -- End simulation
        test_runner_cleanup(runner);

    end process p_test_runner;

end architecture TB_REGBLOCK_ARCH;
