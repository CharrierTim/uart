-- Author    : https://github.com/n8tlarsen
-- Taken from: https://github.com/VUnit/vunit/pull/1041

library ieee;
    use ieee.std_logic_1164.all;

library vunit_lib;
    use vunit_lib.com_pkg.net;
    use vunit_lib.com_pkg.receive;
    use vunit_lib.com_pkg.reply;
    use vunit_lib.com_types_pkg.all;
    use vunit_lib.stream_master_pkg.all;
    use vunit_lib.stream_slave_pkg.all;
    use vunit_lib.sync_pkg.all;
    use vunit_lib.queue_pkg.all;
    use vunit_lib.sync_pkg.all;
    use vunit_lib.print_pkg.all;
    use vunit_lib.log_levels_pkg.all;
    use vunit_lib.logger_pkg.all;
    use vunit_lib.log_handler_pkg.all;

library lib_bench;
    use lib_bench.spi_pkg.all;

entity SPI_MASTER_MODEL is
    generic (
        SPI : spi_master_t
    );
    port (
        SCLK : out   std_logic := spi.p_cpol_mode;
        MOSI : out   std_logic := spi.p_idle_state;
        MISO : in    std_logic
    );
end entity SPI_MASTER_MODEL;

architecture A of SPI_MASTER_MODEL is

    constant DIN_QUEUE : queue_t := new_queue;

begin

    main : process is

        procedure spi_transaction (
            dout        : std_logic_vector;
            frequency   : integer;
            signal sclk : out std_logic;
            signal mosi : out std_logic;
            signal miso : in  std_logic
        ) is
            constant HALF_BIT_TIME : time := (10 ** 9 / (frequency * 2)) * 1 ns;

            variable din : std_logic_vector(dout'length - 1 downto 0);
            variable clk : std_logic := spi.p_cpol_mode;
        begin

            debug("Transmitting " & to_string(dout));
            sclk <= clk;
            mosi <= dout(dout'length - 1);

            if (spi.p_cpha_mode = '0') then
                wait for HALF_BIT_TIME;
            end if;

            clk  := not clk;
            sclk <= clk;

            if (spi.p_cpha_mode = '0') then
                din(dout'length - 1) := miso;
            end if;

            for b in dout'length - 2 downto 0 loop
                wait for HALF_BIT_TIME;
                clk  := not clk;
                sclk <= clk;

                if (spi.p_cpha_mode = '0') then
                    mosi <= dout(b);
                else
                    din(b) := miso;
                end if;

                wait for HALF_BIT_TIME;
                clk  := not clk;
                sclk <= clk;

                if (spi.p_cpha_mode = '1') then
                    mosi <= dout(b);
                else
                    din(b) := miso;
                end if;

            end loop;

            wait for HALF_BIT_TIME;
            sclk <= spi.p_cpol_mode;
            push_std_ulogic_vector(din_queue, din);

        end procedure spi_transaction;

        variable query_msg : msg_t;
        variable reply_msg : msg_t;
        variable frequency : natural := spi.p_frequency;
        variable msg_type  : msg_type_t;

    begin

        receive(net, spi.p_actor, query_msg);
        msg_type := message_type(query_msg);

        handle_sync_message(net, msg_type, query_msg);

        if (msg_type = stream_push_msg) then
            spi_transaction(pop_std_ulogic_vector(query_msg), frequency, SCLK, MOSI, MISO);
        elsif (msg_type = stream_pop_msg) then
            if (length(DIN_QUEUE) > 0) then
                reply_msg := new_msg;
                push_std_ulogic_vector(reply_msg, pop_std_ulogic_vector(din_queue));
                push_boolean(reply_msg, false);
                reply(net, query_msg, reply_msg);
            else
                unexpected_msg_type(msg_type);
            end if;
        elsif (msg_type = spi_set_frequency_msg) then
            frequency := pop(query_msg);
        else
            unexpected_msg_type(msg_type);
        end if;

    end process main;

end architecture A;
