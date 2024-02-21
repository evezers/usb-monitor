library ieee;
    use ieee.std_logic_1164.all;

entity fsm_control is
    port (
        clk    : in    std_logic;
        reset  : in    std_logic;
        enable : in    std_logic;

        -- fsm_ulpi_registers
        o_fsm_ulpi_registers_enable : out   std_logic;
        o_register_request          : out   std_logic;
        o_register_address          : out   std_logic_vector(7 downto 0);
        o_register_data             : out   std_logic_vector(7 downto 0);
        i_register_busy             : in    std_logic;

        -- fsm_ulpi_transmit
        o_fsm_ulpi_transmit_enable : out   std_logic -- ;
    -- o_transmit_end             : out   std_logic;
    -- o_transmit_request         : out   std_logic;
    -- o_transmit_pid             : out   std_logic_vector(3 downto 0);
    -- o_transmit_data            : out   std_logic_vector(7 downto 0);
    -- i_transmit_busy            : in    std_logic;
    -- i_transmit_hold            : in    std_logic;

    -- ulpi_config_finished : in    std_logic
    );
end entity fsm_control;

architecture rtl of fsm_control is

    -- common
    signal r_register_request : std_logic;
    signal r_register_data    : std_logic_vector(7 downto 0);

    -- fsm_ulpi_registers
    signal r_fsm_ulpi_registers_enable : std_logic;
    signal r_register_address          : std_logic_vector(7 downto 0);

    -- fsm_ulpi_transmit
    signal r_fsm_ulpi_transmit_enable : std_logic;
    -- signal r_transmit_end             : std_logic;
    -- signal r_transmit_pid             : std_logic_vector(3 downto 0);

    type fsm_control_state_type is (
        idle_state0,
        idle_state,
        idle_state1,
        idle_state2,
        ulpi_config_state,
        usb_connect_state -- ,
    -- usb_config_state,
    -- usb_idle_state,
    -- usb_disconnect
    );

    signal fsm_control_state : fsm_control_state_type;

    signal delay_counter : natural range 0 to 1_000_000_000 := 0;

begin

    o_fsm_ulpi_transmit_enable  <= r_fsm_ulpi_transmit_enable;
    o_fsm_ulpi_registers_enable <= r_fsm_ulpi_registers_enable;
    o_register_request          <= r_register_request;
    o_register_address          <= r_register_address;
    o_register_data             <= r_register_data;
    -- o_transmit_pid              <= r_transmit_pid;
    -- o_transmit_end              <= r_transmit_end;

    process (enable, clk, reset) is
    begin

        if (enable = '0') then
        -- o_data <= (others => 'Z');
        elsif (reset = '1') then
            fsm_control_state <= idle_state0;

        -- r_register_data             <= (others => '0');
        -- r_register_address          <= (others => '0');
        -- r_transmit_pid              <= (others => '0');
        -- r_register_request          <= '0';
        -- r_fsm_ulpi_registers_enable <= '0';
        -- r_transmit_end              <= '0';
        elsif (rising_edge(clk)) then

            case fsm_control_state is

                when idle_state0 =>

                    if (delay_counter = 1_000_000_000) then
                        fsm_control_state <= idle_state;
                    else
                        fsm_control_state <= idle_state0;
                    end if;

                when idle_state =>

                    fsm_control_state <= idle_state1;

                when idle_state1 =>

                    if (i_register_busy = '0' and r_register_request = '0') then
                        fsm_control_state <= idle_state2;
                    else
                        fsm_control_state <= idle_state1;
                    end if;

                when idle_state2 =>

                    fsm_control_state <= ulpi_config_state;

                when ulpi_config_state =>

                    if (i_register_busy = '0' and r_register_request = '0') then
                        fsm_control_state <= usb_connect_state;
                    else
                        fsm_control_state <= ulpi_config_state;
                    end if;

                when usb_connect_state =>

            -- if (ulpi_config_finished = '1') then
            --     fsm_control_state <= usb_config_state;
            -- else
            --     fsm_control_state <= usb_connect_state;
            -- end if;

            -- when usb_config_state =>

            --     if (ulpi_config_finished = '1') then
            --         fsm_control_state <= usb_idle_state;
            --     else
            --         fsm_control_state <= usb_config_state;
            --     end if;

            -- when usb_idle_state =>

            --     if (ulpi_config_finished = '1') then
            --         fsm_control_state <= usb_disconnect;
            --     else
            --         fsm_control_state <= usb_idle_state;
            --     end if;

            -- when usb_disconnect =>

            --     if (ulpi_config_finished = '1') then
            --         fsm_control_state <= usb_connect_state;
            --     else
            --         fsm_control_state <= usb_disconnect;
            --     end if;

            end case;

        end if;

    end process;

    process (clk, reset) is
    begin
        if (reset = '1') then
            delay_counter <= 0;
        elsif rising_edge(clk) then
            if (delay_counter = 1_000_000_000) then
                delay_counter <= 0;
            else
                delay_counter <= delay_counter + 1;
            end if;
        end if;

    end process;

    process (clk, enable, reset) is
    begin

        if (enable = '0') then
        -- o_data <= (others => 'Z');
        elsif (reset = '1') then
            -- fsm_control_state <= ulpi_config_state;

            r_register_data    <= (others => '0');
            r_register_address <= (others => '0');
            -- r_transmit_pid              <= (others => '0');
            r_register_request          <= '0';
            r_fsm_ulpi_registers_enable <= '0';
            r_fsm_ulpi_transmit_enable  <= '0';
        -- r_transmit_end              <= '0';
        elsif (rising_edge(clk)) then

            case fsm_control_state is

                when idle_state0 =>

                -- r_fsm_ulpi_registers_enable <= '0';
                -- r_register_address          <= b"1000_1010";
                -- r_register_data             <= b"0000_0000";
                -- r_register_request          <= '0';
                when idle_state =>

                    r_fsm_ulpi_registers_enable <= '1';
                    r_register_address          <= b"1000_1010";
                    r_register_data             <= b"0000_0000";
                    r_register_request          <= '1';

                when idle_state1 =>

                    r_register_request <= '0';

                when idle_state2 =>

                    r_fsm_ulpi_registers_enable <= '1';
                    r_register_address          <= b"1000_0100";
                    r_register_data             <= b"0110_0101";
                    r_register_request          <= '1';

                when ulpi_config_state =>

                    r_register_request <= '0';

                when usb_connect_state =>

                    r_register_request          <= '0';
                    r_fsm_ulpi_registers_enable <= '0';

                    r_fsm_ulpi_transmit_enable <= '1';

            --     when usb_config_state =>

            --     -- if (ulpi_config_finished = '1') then
            --     --     state <= usb_idle_state;
            --     -- else
            --     --     state <= state;
            --     -- end if;

            --     when usb_idle_state =>

            --     -- if (ulpi_config_finished = '1') then
            --     --     state <= usb_disconnect;
            --     -- else
            --     --     state <= state;
            --     -- end if;

            --     when usb_disconnect =>

            -- -- if (ulpi_config_finished = '1') then
            -- --     state <= usb_connect_state;
            -- -- else
            -- --     state <= state;
            -- -- end if;

            end case;

        end if;

    end process;

end architecture rtl;
