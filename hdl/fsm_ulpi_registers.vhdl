library ieee;
    use ieee.std_logic_1164.all;
    use work.ulpi_pkg.all;

entity fsm_ulpi_registers is
    port (
        clk    : in    std_logic;
        reset  : in    std_logic;
        enable : in    std_logic;

        i_register_request : in    std_logic;
        i_register_address : in    std_logic_vector(7 downto 0);
        i_register_data    : in    std_logic_vector(7 downto 0);
        o_register_data    : out   std_logic_vector(7 downto 0);
        o_register_busy    : out   std_logic;

        i_ulpi : in    t_from_ulpi;
        o_ulpi : out   t_to_ulpi
    );
end entity fsm_ulpi_registers;

architecture rtl of fsm_ulpi_registers is

    -- Build an enumerated type for the state machine

    type fsm_ulpi_state_type is (
        idle_state,
        wait_dir_state,
        cmd_write_state,
        write_reg_state,
        stp_state,
        cmd_read_state,
        read_reg_state
    );

    -- Register to hold the current state
    signal fsm_ulpi_registers_state : fsm_ulpi_state_type;

    signal address_head_r : std_logic_vector(7 downto 6);
    -- signal data_r         : std_logic_vector(7 downto 0);
    signal o_data_r : std_logic_vector(7 downto 0);
    signal stp_r    : std_logic;
    signal busy_r   : std_logic;

    signal o_register_data_r : std_logic_vector(7 downto 0);

begin

    address_head_r  <= i_register_address(7 downto 6);
    o_ulpi.stp      <= stp_r when (enable = '1' ) else 'Z';
    o_register_data <= o_register_data_r;
    o_register_busy <= busy_r;
    o_ulpi.data     <= o_data_r when (enable = '1' and i_ulpi.dir = '0') else
                       (others => 'Z');

    process (enable, clk, reset) is
    begin

        if (reset = '1') then
            fsm_ulpi_registers_state <= idle_state;

--            address_head_r <= (others => '0');
        -- data_r         <= (others => '0');
        -- o_data_r       <= (others => '0');
        -- stp_r          <= '0';
        -- busy_r         <= '0';
        elsif (rising_edge(clk)) then

            case fsm_ulpi_registers_state is

                when idle_state =>

                    if (i_register_request = '1') then
                        fsm_ulpi_registers_state <= wait_dir_state;
                    else
                        fsm_ulpi_registers_state <= idle_state;
                    end if;

                when wait_dir_state =>

                    if (i_ulpi.dir = '0') then
                        if (address_head_r = ULPI_CMD_HEAD_REGISTER_WRITE) then
                            fsm_ulpi_registers_state <= cmd_write_state;
                        elsif (address_head_r = ULPI_CMD_HEAD_REGISTER_READ) then
                            fsm_ulpi_registers_state <= cmd_read_state;
                        else
                            fsm_ulpi_registers_state <= wait_dir_state;
                        end if;
                    else
                        fsm_ulpi_registers_state <= wait_dir_state;
                    end if;

                when cmd_write_state =>

                    if (i_ulpi.nxt = '1') then
                        fsm_ulpi_registers_state <= write_reg_state;
                    else
                        fsm_ulpi_registers_state <= cmd_write_state;
                    end if;

                when write_reg_state =>

                    fsm_ulpi_registers_state <= stp_state;

                when stp_state =>

                    fsm_ulpi_registers_state <= idle_state;

                when cmd_read_state =>

                    if (i_ulpi.nxt = '1') then
                        fsm_ulpi_registers_state <= read_reg_state;
                    else
                        fsm_ulpi_registers_state <= cmd_read_state;
                    end if;

                when read_reg_state =>

                    fsm_ulpi_registers_state <= idle_state;

            end case;

        end if;

    end process;

    process (clk, reset) is
    begin
        if (reset = '1') then
            -- fsm_ulpi_registers_state <= idle_state;

--            address_head_r <= (others => '0');
        -- data_r         <= (others => '0');
        o_data_r       <= (others => '0');
        stp_r          <= '0';
        busy_r         <= '0';

        o_register_data_r <= (others => '0');
        elsif (rising_edge(clk)) then

        case fsm_ulpi_registers_state is

            when idle_state =>

                o_data_r <= ULPI_CMD_IDLE;
                stp_r    <= '0';

                if (i_register_request = '1') then
                    busy_r   <= '1';
                else
                    busy_r   <= '0';
                end if;

            when wait_dir_state =>

                o_data_r <= ULPI_CMD_IDLE;
                stp_r    <= '0';

                busy_r <= '1';

            when cmd_write_state =>

                stp_r <= '0';

                busy_r   <= '1';
                o_data_r <= i_register_address;

            when write_reg_state =>

                stp_r <= '0';

                busy_r   <= '1';
                o_data_r <= i_register_data;

            when stp_state =>

                o_data_r <= i_register_data;

                busy_r <= '1';
                stp_r  <= '1';

            when cmd_read_state =>

                busy_r   <= '1';
                stp_r    <= '1';
                o_data_r <= i_register_address;

            when read_reg_state =>

                busy_r            <= '1';
                stp_r             <= '1';
                o_register_data_r <= i_ulpi.data;

        end case;
    end if;
    end process;

end architecture rtl;
