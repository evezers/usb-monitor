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

entity tb_usb_config is
    generic (
        runner_cfg : string := runner_cfg_default
    );
end entity tb_usb_config;

architecture tb of tb_usb_config is

    signal clk_r   : std_logic := '0';
    signal reset_r : std_logic;

    signal clk    : std_logic;
    signal reset  : std_logic;
    signal enable : std_logic;

    signal o_shift_request_enable : std_logic;
    signal o_request_byte         : unsigned(7 downto 0);
    signal i_request              : t_usb_request;
    signal i_receive_data         : std_logic_vector(7 downto 0);
    signal i_receive_busy         : std_logic;
    signal i_receive_hold         : std_logic;
    signal o_transmit_end         : std_logic;
    signal o_transmit_request     : std_logic;
    signal o_transmit_pid         : std_logic_vector(3 downto 0);
    signal o_transmit_data        : std_logic_vector(7 downto 0);
    signal i_transmit_busy        : std_logic;
    signal i_transmit_hold        : std_logic;
    signal o_lut_address          : std_logic_vector(7 downto 0);
    signal i_lut_data             : std_logic_vector(7 downto 0);

    signal i_ulpi : t_from_ulpi;
    signal o_ulpi : t_to_ulpi;

    signal ulpi_clock : std_logic;

    -- signal ulpi_data : std_logic_vector(15 downto 0);

begin

    ulpi_clock <= clk_r;
    clk        <= clk_r;
    reset      <= reset_r;
    enable     <= '1';

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
                i_ulpi.data <= (others => '0');

                -- Reset
                WaitForClock(clk_r, 10);

                -- USB Connect
                sess_vld_interrupt(ulpi_clock, i_ulpi, o_ulpi);

                WaitForClock(clk_r, 10);

                host_send(ulpi_clock, i_ulpi, o_ulpi, USB_PID_SETUP, x"FABE");
                WaitForClock(clk_r, RX_CMD_DELAY);
                host_send(ulpi_clock, i_ulpi, o_ulpi, USB_PID_SETUP, x"DEAD");
                WaitForClock(clk_r, RX_CMD_DELAY);

                host_send(ulpi_clock, i_ulpi, o_ulpi, USB_PID_DATA0, x"8006000100001200F4E0", 3);
                WaitForClock(clk_r, LINK_DECISION_TIME);

                host_receive(ulpi_clock, i_ulpi, o_ulpi);

                host_send(ulpi_clock, i_ulpi, o_ulpi, USB_PID_IN, x"0000");
                host_receive(ulpi_clock, i_ulpi, o_ulpi);

                host_send(ulpi_clock, i_ulpi, o_ulpi, USB_PID_IN, x"0000");
                host_receive(ulpi_clock, i_ulpi, o_ulpi);

                host_send(ulpi_clock, i_ulpi, o_ulpi, USB_PID_IN, x"0000");
                host_receive(ulpi_clock, i_ulpi, o_ulpi);

                host_send(ulpi_clock, i_ulpi, o_ulpi, USB_PID_SETUP, x"0000");
                WaitForClock(clk_r, RX_CMD_DELAY);
                
                host_send(ulpi_clock, i_ulpi, o_ulpi, USB_PID_DATA0, 
                x"0005_7F00_0000_0000_0000", 3);

                host_receive(ulpi_clock, i_ulpi, o_ulpi);

                WaitForClock(clk_r, 10);
            end if;

        end loop;

        test_runner_cleanup(runner);

    end process;

    test_runner_watchdog(runner, 5 us);

    fsm_usb_config_inst : entity work.fsm_usb_config
        port map (
            clk    => clk,
            reset  => reset,
            enable => enable,

            o_shift_request_enable => o_shift_request_enable,
            o_request_byte         => o_request_byte,
            i_request              => i_request,

            i_receive_data => i_receive_data,
            i_receive_busy => i_receive_busy,
            i_receive_hold => i_receive_hold,

            o_transmit_end     => o_transmit_end,
            o_transmit_request => o_transmit_request,
            o_transmit_pid     => o_transmit_pid,
            o_transmit_data    => o_transmit_data,
            i_transmit_busy    => i_transmit_busy,
            i_transmit_hold    => i_transmit_hold,

            o_lut_address => o_lut_address,
            i_lut_data    => i_lut_data
        );

    shift_request_inst : entity work.shift_request
        port map (
            clk    => clk,
            reset  => reset,
            enable => o_shift_request_enable,

            i_request_byte => o_request_byte,
            o_request      => i_request
        );

    fsm_ulpi_receive_inst : entity work.fsm_ulpi_receive
        port map (
            clk    => clk,
            reset  => reset,
            enable => enable,

            o_receive_data => i_receive_data,
            o_receive_busy => i_receive_busy,
            o_receive_hold => i_receive_hold,

            i_ulpi => i_ulpi
            -- o_ulpi => o_ulpi
        );

    fsm_ulpi_transmit_inst : entity work.fsm_ulpi_transmit
        port map (
            clk    => clk,
            reset  => reset,
            enable => enable,

            i_transmit_end     => o_transmit_end,
            i_transmit_request => o_transmit_request,
            i_transmit_pid     => o_transmit_pid,
            i_transmit_data    => o_transmit_data,
            o_transmit_busy    => i_transmit_busy,
            o_transmit_hold    => i_transmit_hold,

            i_ulpi => i_ulpi,
            o_ulpi => o_ulpi
        );

    lut_ulpi_config_inst : entity work.lut_ulpi_config
        port map (
            address => o_lut_address,
            clock   => clk,
            nrst    => "not"(reset),
            -- ulpi_register_address => (others => '0'),
            ulpi_data => i_lut_data
        );

    -- i_lut_data <= ulpi_data(15 downto 8);

end architecture tb;
