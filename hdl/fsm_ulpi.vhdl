library ieee;
    use ieee.std_logic_1164.all;

entity fsm_ulpi is
    port (
        clk    : in    std_logic;
        reset  : in    std_logic;
        enable : in    std_logic;

        new_cmd  : in    std_logic;
        i_data   : in    std_logic_vector(7 downto 0);
        reg_data : in    std_logic_vector(7 downto 0);

        dir    : in    std_logic;
        nxt    : in    std_logic;
        o_data : inout std_logic_vector(7 downto 0);
        stp    : out   std_logic;

        o_read_data : out   std_logic_vector(7 downto 0)
    );
end entity fsm_ulpi;

architecture rtl of fsm_ulpi is

    constant ULPI_CMD_IDLE : std_logic_vector(7 downto 0) := (others => '0');

    constant ULPI_CMD_HEAD_TRANSMIT       : std_logic_vector(7 downto 6) := "01";
    constant ULPI_CMD_HEAD_REGISTER_WRITE : std_logic_vector(7 downto 6) := "10";
    constant ULPI_CMD_HEAD_REGISTER_READ  : std_logic_vector(7 downto 6) := "11";

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
    signal state : fsm_ulpi_state_type;

    signal data_head_r : std_logic_vector(7 downto 6);
    signal data_r      : std_logic_vector(7 downto 0);
    signal o_data_r    : std_logic_vector(7 downto 0);
    signal stp_r       : std_logic;

    signal o_read_data_r : std_logic_vector(7 downto 0);

begin

    -- data_r <= i_data;

    stp         <= stp_r;
    data_head_r <= i_data(7 downto 6);
    o_data      <= o_data_r when (enable = '0' and dir = '1') else
                   (others => 'Z');
    o_read_data <= o_read_data_r;

    process (enable, clk, reset) is
    begin

        if (enable = '0') then
            o_data <= (others => 'Z');
        elsif (reset = '1') then
            state <= idle_state;

            data_head_r <= (others => '0');
            data_r      <= (others => '0');
            o_data_r    <= (others => '0');
            stp_r       <= '0';
        elsif (rising_edge(clk)) then

            case state is

                when idle_state =>

                    if (new_cmd = '1') then
                        state <= wait_dir_state;
                    else
                        state <= state;
                    end if;

                when wait_dir_state =>                                               -- if IDLE will hang here

                    if (dir = '0') then
                        if (data_head_r = ULPI_CMD_HEAD_REGISTER_WRITE) then
                            state <= cmd_write_state;
                        elsif (data_head_r = ULPI_CMD_HEAD_REGISTER_READ) then
                            state <= cmd_read_state;
                        else
                            state <= state;
                        end if;
                    else
                        if (data_head_r = ULPI_CMD_HEAD_TRANSMIT) then
                            state <= state;                                          -- TRANSMIT
                        else
                            state <= state;
                        end if;
                    end if;

                when cmd_write_state =>

                    if (nxt = '1') then
                        state <= write_reg_state;
                    else
                        state <= state;
                    end if;

                when write_reg_state =>

                    state <= stp_state;

                when stp_state =>

                    state <= idle_state;

                when cmd_read_state =>

                    if (nxt = '1') then
                        state <= read_reg_state;
                    else
                        state <= state;
                    end if;

                when read_reg_state =>

                    state <= idle_state;

            -- when others =>
            --     state <= IDLE;

            end case;

        end if;

    end process;

    -- Determine the output based only on the current state
    -- and the input (do not wait for a clock edge).
    process (state) is
    begin

        case state is

            when idle_state =>

                o_data_r <= ULPI_CMD_IDLE;
                stp_r    <= '0';

            when wait_dir_state =>

            when cmd_write_state =>

                o_data_r <= i_data;

            when write_reg_state =>

                o_data_r <= reg_data;

            when stp_state =>

                stp_r <= '0';

            when cmd_read_state =>

                o_data_r <= i_data;

            when read_reg_state =>

                o_read_data_r <= o_data;

        end case;

    end process;

-- Move to the next state
-- process(clk)
-- begin
--     if (rising_edge(clock)) then
--         present_state <= next_state;
--     end if;
-- end process;

end architecture rtl;
