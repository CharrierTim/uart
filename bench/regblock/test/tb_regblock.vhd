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
                                                   AWADDR(4 downto 0),
                                                   WDATA(31 downto 0),
                                                   WSTRB(3 downto 0),
                                                   ARADDR(4 downto 0));
    signal tb_s_axil_o    : axi4lite_slave_out_intf(RDATA(31 downto 0));
    signal tb_hwif_in     : regblock_in_t;
    signal tb_hwif_out    : regblock_out_t;

    -- AXI-Lite master <-> slave signals
    signal arready        : std_logic;
    signal arvalid        : std_logic;
    signal araddr         : std_logic_vector(4 downto 0);

    signal rready         : std_logic;
    signal rvalid         : std_logic;
    signal rdata          : std_logic_vector(31 downto 0);
    signal rresp          : std_logic_vector(1 downto 0);

    signal awready        : std_logic;
    signal awvalid        : std_logic;
    signal awaddr         : std_logic_vector(4 downto 0);

    signal wready         : std_logic;
    signal wvalid         : std_logic;
    signal wdata          : std_logic_vector(31 downto 0);
    signal wstrb          : std_logic_vector(3 downto 0);

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
            variable v_returned_data : std_logic_vector(rdata'range);
        begin

            info("");
            info("Checking register " & reg.name & " value after reset");

            info(
                "Reading value from register "          & reg.name &
                " at address 0x"                        & to_hstring(reg.addr) &
                " and expecting 0x"                     & to_hstring(reg.data));

            -- Check the default value of the register after reset
            read_axi_lite(
                net,
                C_BUS_HANDLE,
                reg.addr,
                axi_resp_okay,
                v_returned_data);

            check_equal(
                v_returned_data,
                reg.data,
                "Default value mismatch for register " & reg.name);

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
            variable v_returned_data : std_logic_vector(rdata'range);
        begin

            info("");
            info("Checking register " & reg.name & " is in read-only mode");

            info(
                "Attempting to write value 0x" & to_hstring(not reg.data) & " to register " & reg.name &
                " at address 0x"               & to_hstring(reg.addr));

            -- Attempt to write the opposite reset value to the register
            write_axi_lite(
                net,
                C_BUS_HANDLE,
                reg.addr,
                not reg.data, -- Write the opposite of the reset value
                axi_resp_slverr);

            wait until rising_edge(tb_clk) and bvalid = '1';

            -- Check if the register value remains unchanged
            info(
                "Reading back value from register "         & reg.name             &
                " at address 0x"                            & to_hstring(reg.addr) &
                " and expecting 0x"                         & to_hstring(reg.data));

            read_axi_lite(
                net,
                C_BUS_HANDLE,
                reg.addr,
                axi_resp_okay,
                v_returned_data);

            check_equal(
                v_returned_data,
                reg.data,
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
            variable v_returned_data : std_logic_vector(rdata'range);
        begin

            info("");
            info("Checking register " & reg.name & " is in read-write mode");

            info(
                "Writing value 0x" & to_hstring(not reg.data) & " to register " & reg.name &
                " at address 0x" & to_hstring(reg.addr));

            wait until rising_edge(tb_clk);

            -- Write the expected value to the register
            write_axi_lite(
                net,
                C_BUS_HANDLE,
                reg.addr,
                (not reg.data) and reg.used_bits_mask, -- Only writable bits should be updated
                axi_resp_okay);

            wait until rising_edge(tb_clk) and bvalid = '1';

            -- Check if the register value is updated correctly
            info(
                "Reading back value from register "         & reg.name &
                " at address 0x"                            & to_hstring(reg.addr) &
                " and expecting 0x"                         & to_hstring(not reg.data and reg.used_bits_mask));

            read_axi_lite(
                net,
                C_BUS_HANDLE,
                reg.addr,
                axi_resp_okay,
                v_returned_data);

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
            addr           : std_logic_vector( 4 downto 0);
            expected_data  : std_logic_vector(31 downto 0) := 32x"0000_0000";
            id             : std_logic_vector              := "X";
            ar_valid_delay : time                          := 0 ns;
            r_ready_delay  : time                          := 0 ns
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
        --   strb            : std_logic_vector - The byte strobe value to use for the write transaction
        --                                        (optional, default is "X").
        --   id              : std_logic_vector - The ID to use for the write transaction (optional, default is "X").
        --   aw_valid_delay  : time             - The delay before asserting AWVALID     (optional, default is 0 ns).
        --   w_valid_delay   : time             - The delay before asserting WVALID      (optional, default is 0 ns).
        --   b_ready_delay   : time             - The delay before asserting BREADY      (optional, default is 0 ns).
        --
        -- Examples:
        --   proc_axi_lite_write_bad_addr(x"1F");
        --   proc_axi_lite_write_bad_addr(x"1F", x"DEAD_BEEF", "1111", "X", 0 ns, 0 ns, 0 ns);
        -- =================================================================================================

        procedure proc_axi_lite_write_bad_addr (
            addr           : std_logic_vector( 4 downto 0);
            data           : std_logic_vector(31 downto 0) := 32x"ABCD_1234";
            strb           : std_logic_vector              := "X";
            id             : std_logic_vector              := "X";
            aw_valid_delay : time                          := 0 ns;
            w_valid_delay  : time                          := 0 ns;
            b_ready_delay  : time                          := 0 ns
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

            wait until rising_edge(tb_clk) and bvalid = '1';

            check_equal(
                bresp,
                axi_resp_slverr,
                "Response mismatch when writing to invalid address 0x" & to_hstring(addr) &
                " - Got AXI response `" & to_string(bresp) & "` expected SLVERR(10)");

        end procedure proc_axi_lite_write_bad_addr;

    begin

        -- Set up the test runner
        test_runner_setup(runner, RUNNER_CFG);

        -- Show PASS log messages for checks
        show(get_logger(default_checker), display_handler, pass);

        -- Set time unit to ns for display handler
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
                    "SPI_RX_DATA[7:0] default value mismatch after reset");

                check_equal(
                    tb_hwif_out.spi_tx_data.tx_data.value,
                    C_REG_SPI_TX_DATA.data(7 downto 0),
                    "SPI_TX_DATA[7:0] default value mismatch after reset");

                check_equal(
                    tb_hwif_out.vga_color.red.value,
                    C_REG_VGA_COLOR.data(3 downto 0),
                    "VGA_COLOR[3:0]   default value mismatch after reset");

                check_equal(
                    tb_hwif_out.vga_color.green.value,
                    C_REG_VGA_COLOR.data(7 downto 4),
                    "VGA_COLOR[7:4]   default value mismatch after reset");

                check_equal(
                    tb_hwif_out.vga_color.blue.value,
                    C_REG_VGA_COLOR.data(11 downto 8),
                    "VGA_COLOR[11:8]  default value mismatch after reset");

            elsif run("test_regblock_bad_addr") then

                -- Reset DUT
                proc_reset_dut;
                wait for 10 us;

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Reading from invalid AXI-Lite address");
                info("-----------------------------------------------------------------------------");

                proc_axi_lite_read_bad_addr(std_logic_vector(to_unsigned(30, araddr'length)));
                proc_axi_lite_read_bad_addr(std_logic_vector(to_unsigned(31, araddr'length)));

                info("");
                info("-----------------------------------------------------------------------------");
                info(" Writing to invalid AXI-Lite address");
                info("-----------------------------------------------------------------------------");

                proc_axi_lite_write_bad_addr(std_logic_vector(to_unsigned(30, awaddr'length)));
                proc_axi_lite_write_bad_addr(std_logic_vector(to_unsigned(31, awaddr'length)));

                proc_axi_lite_write_bad_addr(x"1E");
                proc_axi_lite_write_bad_addr(x"1F");

            end if;

        end loop;

        -- End simulation
        test_runner_cleanup(runner);

    end process p_test_runner;

end architecture TB_REGBLOCK_ARCH;
