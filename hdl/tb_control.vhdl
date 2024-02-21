library vunit_lib;
    context vunit_lib.vunit_context;

library osvvm;
    context osvvm.osvvmcontext;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.usb_pkg.all;
    use work.ulpi_pkg.all;
    use work.tb_usb_pkg.all;

entity tb_control is
    generic (
        runner_cfg : string := runner_cfg_default
    );
end entity tb_control;

architecture tb of tb_control is

    signal clk_r   : std_logic := '0';
    signal reset_r : std_logic;

    signal clk    : std_logic;
    signal reset  : std_logic;
    signal enable : std_logic;

    signal i_ulpi : t_from_ulpi;
    signal o_ulpi : t_to_ulpi;

    signal ulpi_data  : std_logic_vector(7 downto 0);
    signal ulpi_stp   : std_logic;
    signal ulpi_nxt   : std_logic;
    signal ulpi_dir   : std_logic;
    signal ulpi_clk   : std_logic;
    signal ulpi_rst   : std_logic;

begin

    ulpi_clk <= clk_r;
    clk      <= clk_r;
    reset    <= reset_r;
    enable   <= '1';

    CreateClock(
                Clk       => clk_r,
                Period    => 10 ns,
                DutyCycle => 0.5
            );

    CreateReset(
                Reset       => reset_r,
                ResetActive => '1',
                Clk         => clk_r,
                Period      => 5 * 10 ns,
                tpd         => 2 ns
            );

    main : process is
    begin

        test_runner_setup(runner, runner_cfg);

        while test_suite loop

            if run("test_pass") then
                -- Initial
                i_ulpi.dir  <= '0';
                i_ulpi.nxt  <= '0';
                i_ulpi.data <= (others => 'Z');

                -- Reset
                WaitForClock(clk_r, 10);

                ulpi_reg_receive(ulpi_clk, i_ulpi, o_ulpi);
                WaitForClock(clk_r, 10);

                ulpi_reg_receive(ulpi_clk, i_ulpi, o_ulpi);
                WaitForClock(clk_r, 10);

                -- USB Connect
                sess_vld_interrupt(ulpi_clk, i_ulpi, o_ulpi);

                WaitForClock(ulpi_clk, 10);

                host_send(ulpi_clk, i_ulpi, o_ulpi, USB_PID_SETUP, x"FABE");
                WaitForClock(ulpi_clk, RX_CMD_DELAY);
                host_send(ulpi_clk, i_ulpi, o_ulpi, USB_PID_SETUP, x"DEAD");
                WaitForClock(ulpi_clk, RX_CMD_DELAY);

                host_send(ulpi_clk, i_ulpi, o_ulpi, USB_PID_DATA0, x"8006000100001200F4E0", 3);
                WaitForClock(clk_r, LINK_DECISION_TIME);

                host_receive(ulpi_clk, i_ulpi, o_ulpi);

                host_send(ulpi_clk, i_ulpi, o_ulpi, USB_PID_IN, x"0000");
                host_receive(ulpi_clk, i_ulpi, o_ulpi);

                host_send(ulpi_clk, i_ulpi, o_ulpi, USB_PID_IN, x"0000");
                host_receive(ulpi_clk, i_ulpi, o_ulpi);

                host_send(ulpi_clk, i_ulpi, o_ulpi, USB_PID_IN, x"0000");
                host_receive(ulpi_clk, i_ulpi, o_ulpi);

                host_send(ulpi_clk, i_ulpi, o_ulpi, USB_PID_SETUP, x"0000");
                WaitForClock(ulpi_clk, RX_CMD_DELAY);

                host_send(ulpi_clk, i_ulpi, o_ulpi, USB_PID_DATA0,
                          x"0005_7F00_0000_0000_0000", 3);

                host_receive(ulpi_clk, i_ulpi, o_ulpi);

                WaitForClock(ulpi_clk, 10);
            end if;

        end loop;

        test_runner_cleanup(runner);

    end process;

    test_runner_watchdog(runner, 5 us);

    enable <= '1';

    usb_device_inst : entity work.usb_device
        port map (
            reset     => reset,
            enable    => enable,
            ulpi_data => ulpi_data,
            ulpi_stp  => ulpi_stp,
            ulpi_nxt  => ulpi_nxt,
            ulpi_dir  => ulpi_dir,
            ulpi_clk  => ulpi_clk,
            ulpi_rst  => ulpi_rst
        );

    ulpi_data <= i_ulpi.data;

    o_ulpi.stp <= ulpi_stp;
    o_ulpi.data <= ulpi_data;

    ulpi_dir <= i_ulpi.dir;
    ulpi_nxt <= i_ulpi.nxt;

end architecture tb;
