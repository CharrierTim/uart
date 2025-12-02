-- Author    : https://github.com/n8tlarsen
-- Taken from: https://github.com/VUnit/vunit/pull/1041

library ieee;
    use ieee.std_logic_1164.all;

library vunit_lib;
    use vunit_lib.com_pkg.net;
    use vunit_lib.com_pkg.receive;
    use vunit_lib.com_pkg.reply;
    use vunit_lib.com_types_pkg.all;
    use vunit_lib.stream_slave_pkg.all;
    use vunit_lib.queue_pkg.all;
    use vunit_lib.print_pkg.all;
    use vunit_lib.log_levels_pkg.all;
    use vunit_lib.logger_pkg.all;
    use vunit_lib.log_handler_pkg.all;

library lib_bench;
    use lib_bench.spi_pkg.all;

entity SPI_SLAVE_MODEL is
    generic (
        SPI : spi_slave_t
    );
    port (
        SCLK : in    std_logic := spi.p_cpol_mode;
        SS_N : in    std_logic := '0';
        MOSI : in    std_logic;
        MISO : out   std_logic
    );
end entity SPI_SLAVE_MODEL;

architecture A of SPI_SLAVE_MODEL is

    constant DIN_QUEUE   : queue_t := new_queue;

    signal   local_event : std_logic := '0';

begin

    main : process is

        variable reply_msg, query_msg : msg_t;
        variable msg_type             : msg_type_t;

    begin

        receive(net, spi.p_actor, query_msg);
        msg_type := message_type(query_msg);

        if (msg_type = stream_pop_msg) then
            reply_msg := new_msg;
            if (not (length(DIN_QUEUE) > 0)) then
                wait on local_event until length(DIN_QUEUE) > 0;
            end if;
            push_std_ulogic_vector(reply_msg, pop_std_ulogic_vector(din_queue));
            push_boolean(reply_msg, false);
            reply(net, query_msg, reply_msg);
        else
            unexpected_msg_type(msg_type);
        end if;

    end process main;

    recv : process is

        procedure spi_transaction (
            variable data : out std_logic_vector;
            signal sclk   : in  std_logic;
            signal mosi   : in  std_logic
        ) is
            variable din_vector : std_logic_vector(7 downto 0);
            variable bit_count  : natural := 7;
        begin

            while (ss_n = '0') loop

                if ((spi.p_cpha_mode = '0') and (spi.p_cpol_mode = '0')) then
                    wait until rising_edge(sclk) or ss_n = '1'; wait for 1 ps;
                elsif ((spi.p_cpha_mode = '0') and (spi.p_cpol_mode = '1')) then
                    wait until falling_edge(sclk) or ss_n = '1'; wait for 1 ps;
                elsif ((spi.p_cpha_mode = '1') and (spi.p_cpol_mode = '0')) then
                    wait until falling_edge(sclk) or ss_n = '1'; wait for 1 ps;
                elsif ((spi.p_cpha_mode = '1') and (spi.p_cpol_mode = '1')) then
                    wait until rising_edge(sclk) or ss_n = '1'; wait for 1 ps;
                end if;

                if (ss_n = '0') then
                    din_vector(bit_count) := mosi;
                    if (bit_count = 0) then
                        bit_count := 7;
                        debug("Received " & to_string(din_vector));
                        push_std_ulogic_vector(din_queue, din_vector);
                    else
                        bit_count := bit_count - 1;
                    end if;
                end if;

            end loop;

        end procedure spi_transaction;

        variable data : std_logic_vector(7 downto 0);

    begin

        wait until SS_N = '0';
        spi_transaction(data, SCLK, MOSI);
        local_event <= '1';
        wait for 1 fs;
        local_event <= '0';
        wait for 1 fs;

    end process recv;

    -- Data loopback
    MISO <= MOSI;

end architecture A;
