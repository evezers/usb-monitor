library ieee;
    use ieee.std_logic_1164.all;
    use work.ulpi_pkg.all;

entity fsm_ulpi_receive is
    port (
        clk    : in    std_logic;
        reset  : in    std_logic;
        enable : in    std_logic;

        o_receive_data : out   std_logic_vector(7 downto 0);
        o_receive_busy : out   std_logic;
        o_receive_hold : out   std_logic;

        i_ulpi : in    t_from_ulpi
        -- o_ulpi : out   t_to_ulpi
    );
end entity fsm_ulpi_receive;

architecture rtl of fsm_ulpi_receive is

    -- Build an enumerated type for the state machine

    type fsm_ulpi_state_type is (
        idle_state,
        wait_dir_state,
        -- cmd_read_state,
        read_reg_state
    );

    -- Register to hold the current state
    signal fsm_ulpi_receive_state : fsm_ulpi_state_type;

    signal r_busy   : std_logic;
    -- signal r_active : std_logic;

-- signal r_register_data : std_logic_vector(7 downto 0);

begin

    -- r_active <= (i_ulpi.dir and i_ulpi.nxt) or ('1' and );

    o_receive_data <= i_ulpi.data;
    o_receive_busy <= r_busy;
    o_receive_hold <= i_ulpi.nxt;

    -- o_ulpi.data <= (others => 'Z');
    -- o_ulpi.stp <= 'Z';

    process (enable, clk, reset) is
    begin

        if (reset = '1') then
            fsm_ulpi_receive_state <= idle_state;
        elsif (rising_edge(clk)) then

            case fsm_ulpi_receive_state is

                when idle_state =>
                -- report "cmd_read_state: nxt: " & to_string(i_ulpi.nxt) & " dir: " & to_string(i_ulpi.dir);


                    fsm_ulpi_receive_state <= wait_dir_state;

                when wait_dir_state =>

                    if (i_ulpi.dir = '1') then
                        -- fsm_ulpi_receive_state <= cmd_read_state;
                        if (i_ulpi.nxt = '1') then
                            fsm_ulpi_receive_state <= read_reg_state;
                        elsif (i_ulpi.data(5 downto 4) = "01") then
                            fsm_ulpi_receive_state <= read_reg_state;
                        else
                            fsm_ulpi_receive_state <= idle_state;
                        end if;
                    else
                        fsm_ulpi_receive_state <= wait_dir_state;
                    end if;

                -- when cmd_read_state =>
                -- -- report "cmd_read_state: nxt: " & to_string(i_ulpi.nxt) & " dir: " & to_string(i_ulpi.dir);

                --     if (i_ulpi.nxt = '1') then
                --         fsm_ulpi_receive_state <= read_reg_state;
                --     elsif (i_ulpi.data(5 downto 4) = "01") then
                --         fsm_ulpi_receive_state <= read_reg_state;
                --     else
                --         fsm_ulpi_receive_state <= idle_state;
                --     end if;

                when read_reg_state =>

                    if (i_ulpi.dir = '1') then
                        fsm_ulpi_receive_state <= read_reg_state;
                    else
                        fsm_ulpi_receive_state <= idle_state;
                    end if;

            end case;

        end if;

    end process;

    process (fsm_ulpi_receive_state) is
    begin

        case fsm_ulpi_receive_state is

            when idle_state =>

                -- r_register_data <= i_ulpi.data;
                r_busy <= '0';

            when wait_dir_state =>

                r_busy <= '0';

            -- when cmd_read_state =>

            --     r_busy <= '0';

            when read_reg_state =>

                r_busy <= '1';

        -- r_register_data <= i_ulpi.data;

        end case;

    end process;

end architecture rtl;
