library ieee;
    use ieee.std_logic_1164.all;
    use work.ulpi_pkg.all;

entity fsm_ulpi_transmit is
    port (
        clk    : in    std_logic;
        reset  : in    std_logic;
        enable : in    std_logic;

        i_transmit_end     : in    std_logic;
        i_transmit_request : in    std_logic;
        i_transmit_pid     : in    std_logic_vector(3 downto 0);
        i_transmit_data    : in    std_logic_vector(7 downto 0);
        o_transmit_busy    : out   std_logic;
        o_transmit_hold    : out   std_logic;

        i_ulpi : in    t_from_ulpi;
        o_ulpi : out   t_to_ulpi
    );
end entity fsm_ulpi_transmit;

architecture rtl of fsm_ulpi_transmit is

    -- Build an enumerated type for the state machine

    type fsm_ulpi_state_type is (
        idle_state,
        wait_dir_state,
        cmd_write_state,
        write_reg_state,
        stp_state
    );

    -- Register to hold the current state
    signal state : fsm_ulpi_state_type;

    signal address_head_r : std_logic_vector(7 downto 6);
    signal data_r         : std_logic_vector(7 downto 0);
    signal o_data_r       : std_logic_vector(7 downto 0);
    signal stp_r          : std_logic;
    signal busy_r         : std_logic;

    signal o_register_data_r : std_logic_vector(7 downto 0);

begin

    o_transmit_hold <= i_ulpi.nxt;
    o_ulpi.stp      <= stp_r;
    o_transmit_busy <= busy_r;
    o_ulpi.data     <= o_data_r when (enable = '0' and i_ulpi.dir = '1') else
                       (others => 'Z');

    process (enable, clk, reset) is
    begin

        if (reset = '1') then
            state <= idle_state;

            address_head_r <= (others => '0');
            data_r         <= (others => '0');
            o_data_r       <= (others => '0');
            stp_r          <= '0';
            busy_r         <= '0';
        elsif (rising_edge(clk)) then

            case state is

                when idle_state =>

                    if (i_transmit_request = '1') then
                        state <= wait_dir_state;
                    else
                        state <= state;
                    end if;

                when wait_dir_state =>

                    if (i_ulpi.dir = '0') then
                        state <= cmd_write_state;
                    else
                        state <= state;
                    end if;

                when cmd_write_state =>

                    if (i_ulpi.nxt = '1') then
                        state <= write_reg_state;
                    else
                        state <= state;
                    end if;

                when write_reg_state =>

                    if (i_ulpi.nxt = '1' and i_transmit_end = '1') then
                        state <= stp_state;
                    else
                        state <= state;
                    end if;

                when stp_state =>

                    state <= idle_state;

            end case;

        end if;

    end process;

    process (state) is
    begin

        case state is

            when idle_state =>

                o_data_r <= ULPI_CMD_IDLE;
                stp_r    <= '0';
                busy_r   <= '0';

            when wait_dir_state =>

                busy_r <= '1';

            when cmd_write_state =>

                o_data_r <= ULPI_CMD_HEAD_TRANSMIT & b"00" & i_transmit_pid;

            when write_reg_state =>

                o_data_r <= i_transmit_data;

            when stp_state =>

                stp_r <= '1';

        end case;

    end process;

end architecture rtl;
