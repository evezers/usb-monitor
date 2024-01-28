library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.usb_pkg.all;

entity fsm_usb_config is
    port (
        clk    : in    std_logic;
        reset  : in    std_logic;
        enable : in    std_logic;

        o_shift_request_enable : out   std_logic;
        o_request_byte         : out   unsigned(7 downto 0);
        i_request              : in    t_usb_request;

        -- o_shift_packet_enable : out   std_logic;
        -- i_token               : in    t_usb_token;

        i_receive_data : in    std_logic_vector(7 downto 0);
        i_receive_busy : in    std_logic;
        i_receive_hold : in    std_logic;

        o_transmit_end     : out   std_logic;
        o_transmit_request : out   std_logic;
        o_transmit_pid     : out   std_logic_vector(3 downto 0);
        o_transmit_data    : out   std_logic_vector(7 downto 0);
        i_transmit_busy    : in    std_logic;
        i_transmit_hold    : in    std_logic;

        o_lut_address : out   std_logic_vector(5 downto 0);
        i_lut_data    : in    std_logic_vector(7 downto 0)
    );
end entity fsm_usb_config;

architecture rtl of fsm_usb_config is

    type fsm_usb_config_state_type is (
        idle_state,
        pid_state,

        receive_token_state,
        receive_token_state1,

        receive_request_state,
        parse_request_state,
        set_address_state,

        send_descriptor_state,
        send_ack_state,
        send_nak_state
    );

    type fsm_setup_transaction_state_type is (
        no_setup_state,
        setup_pid_state,
        request_received_state,
        descriptor_sent_state
    );

    signal fsm_usb_config_state : fsm_usb_config_state_type;
    signal fsm_setup            : fsm_setup_transaction_state_type;

    signal r_shift_request_enable : std_logic;
    signal r_request_byte         : unsigned(7 downto 0);

    signal r_transmit_end     : std_logic;
    signal r_transmit_request : std_logic;
    signal r_transmit_pid     : std_logic_vector(3 downto 0);
    signal r_transmit_data    : std_logic_vector(7 downto 0);
    signal r_lut_address      : std_logic_vector(5 downto 0);
    signal r_lut_base_address : unsigned(5 downto 0);
    signal r_address          : unsigned(6 downto 0);

    signal r_shift_packet_enable : std_logic;

    signal counter_transaction     : natural range 0 to 1023;
    signal counter_transaction_end : natural range 0 to 1023;
    signal counter_packet          : natural range 0 to 10;

    -- signal r_setup_flag     : std_logic;
    signal r_counter_active : std_logic;

    signal r_data1_flag : std_logic;

    constant LUT_DESCRIPTOR_BASE_ADDRESS : unsigned(5 downto 0) := b"111111";

    constant MAX_PACKET_LENGTH : natural := USB_MAX_PACKET_SIZE + USB_CRC16_LENGTH;

    signal r_token        : unsigned(15 downto 0);
    signal r_token_record : t_usb_token;

    signal r_receive_pid : std_logic_vector(3 downto 0);

begin

    r_token_record <=
    (
        address  => r_token(15 downto 9),
        endpoint => r_token(8 downto 5),
        CRC5     => r_token(4 downto 0)
    );

    r_receive_pid <= i_receive_data(7 downto 4);

    o_shift_request_enable <= r_shift_request_enable and i_receive_hold;
    o_request_byte         <= r_request_byte;

    o_transmit_end     <= r_transmit_end;
    o_transmit_request <= r_transmit_request;
    o_transmit_pid     <= r_transmit_pid;
    o_transmit_data    <= r_transmit_data;
    o_lut_address      <= r_lut_address;

    -- o_shift_packet_enable <= r_shift_packet_enable and i_receive_hold;

    state_machine_process : process (enable, clk, reset) is
    begin

        if (enable = '0') then
        -- o_data <= (others => 'Z');
        elsif (reset = '1') then
            fsm_usb_config_state <= idle_state;
            -- fsm_setup   <= no_setup_state;

            r_token                <= (others => '0');
            r_request_byte         <= (others => '0');
            r_transmit_pid         <= (others => '0');
            r_transmit_data        <= (others => '0');
            r_address              <= (others => '0');
            r_lut_address          <= (others => '0');
            r_lut_base_address     <= (others => '0');
            r_shift_request_enable <= '0';
            r_transmit_end         <= '0';
            r_transmit_request     <= '0';
            r_shift_packet_enable  <= '0';
            r_counter_active       <= '0';

            -- r_setup_flag <= '0';
            r_data1_flag <= '0';
        elsif (rising_edge(clk)) then

            case fsm_usb_config_state is

                when idle_state =>

                    if (i_receive_busy = '1') then
                        fsm_usb_config_state <= pid_state;
                    else
                        fsm_usb_config_state <= idle_state;
                    end if;

                when pid_state =>

                    if (r_receive_pid = USB_PID_OUT
                        or r_receive_pid = USB_PID_IN
                        or r_receive_pid = USB_PID_SETUP) then
                        fsm_usb_config_state <= receive_token_state;
                    elsif (r_receive_pid = USB_PID_DATA0
                           or r_receive_pid = USB_PID_DATA1) then
                        fsm_usb_config_state <= receive_request_state;
                    elsif (r_receive_pid = USB_PID_ACK
                           or r_receive_pid = USB_PID_NAK) then
                        fsm_usb_config_state <= idle_state;
                    else
                        fsm_usb_config_state <= send_nak_state;
                    end if;

                when receive_token_state =>

                    if (i_receive_hold = '0') then
                        fsm_usb_config_state <= receive_token_state1;
                    else
                        fsm_usb_config_state <= receive_token_state;
                    end if;

                when receive_token_state1 =>

                    if (i_receive_hold = '0') then
                        fsm_usb_config_state <= idle_state;
                    else
                        fsm_usb_config_state <= receive_token_state1;
                    end if;

                when receive_request_state =>

                    if (r_counter_active = '0') then
                        fsm_usb_config_state <= parse_request_state;
                    else
                        fsm_usb_config_state <= receive_request_state;
                    end if;

                when parse_request_state =>

                    if (i_request.bRequest = USB_REQUEST_SET_ADDRESS) then
                        fsm_usb_config_state <= set_address_state;
                    elsif (i_request.bRequest = USB_REQUEST_GET_DESCRIPTOR) then
                        fsm_usb_config_state <= send_descriptor_state;
                    else
                        fsm_usb_config_state <= parse_request_state;
                    end if;

                when set_address_state =>

                    fsm_usb_config_state <= idle_state;

                when send_descriptor_state =>

                    if (i_transmit_busy = '0') then
                        fsm_usb_config_state <= idle_state;
                    else
                        fsm_usb_config_state <= send_descriptor_state;
                    end if;

                when send_ack_state =>

                    if (i_transmit_busy = '0') then
                        fsm_usb_config_state <= idle_state;
                    else
                        fsm_usb_config_state <= send_ack_state;
                    end if;

                when send_nak_state =>

                    if (i_transmit_busy = '0') then
                        fsm_usb_config_state <= idle_state;
                    else
                        fsm_usb_config_state <= send_nak_state;
                    end if;

            end case;

        end if;

    end process;

    counter_process : process (clk, reset) is
    begin

        if (reset = '1') then
            counter_transaction <= 0;
            counter_packet      <= 0;
        elsif rising_edge(clk) then
            if (r_counter_active = '0') then
                counter_transaction <= 0;
                counter_packet      <= 0;
            else
                if (i_receive_hold = '0' and i_transmit_hold = '0') then -- and counter /= 0
                    counter_transaction <= counter_transaction + 1;
                    counter_packet      <= counter_packet;
                end if;

                if (counter_packet = MAX_PACKET_LENGTH or counter_transaction = counter_transaction_end) then
                    r_counter_active <= '0';
                end if;
            end if;
        end if;

    end process;

    state_actions_process : process (fsm_usb_config_state) is
    begin

        case fsm_usb_config_state is

            when idle_state =>

                r_transmit_request <= '0';
                r_transmit_end     <= '0';
            -- counter_transaction_end <= 0;

            when pid_state =>

                if (r_receive_pid = USB_PID_SETUP) then
                    fsm_setup <= setup_pid_state;
                end if;

                if (r_receive_pid = USB_PID_OUT
                    or r_receive_pid = USB_PID_IN
                    or r_receive_pid = USB_PID_SETUP) then
                -- state <= receive_token_state;
                -- if (r_counter_active = '0') then
                -- counter_end <= 2;
                -- end if;
                elsif (r_receive_pid = USB_PID_DATA0
                       or r_receive_pid = USB_PID_DATA1) then
                    r_shift_request_enable <= '1';

                -- if (r_counter_active = '0') then
                -- counter_end <= 8;
                -- end if;

                -- state <= receive_request_state;
                elsif (r_receive_pid = USB_PID_ACK
                       or r_receive_pid = USB_PID_NAK) then
                -- state <= idle_state;
                else
                -- state <= send_nak_state;
                end if;

            when receive_token_state =>

                r_token(15 downto 8) <= unsigned(i_receive_data);

            when receive_token_state1 =>

                r_token(7 downto 0) <= unsigned(i_receive_data);

            when receive_request_state =>

                if (r_counter_active = '0') then
                    r_shift_request_enable <= '0';
                    fsm_setup              <= request_received_state;

                    if (i_request.bRequest = USB_REQUEST_GET_DESCRIPTOR) then
                        r_lut_base_address <= LUT_DESCRIPTOR_BASE_ADDRESS;
                    elsif (i_request.bRequest = USB_REQUEST_SET_ADDRESS) then
                    --     state <= send_descriptor_state;
                    else
                    --     state <= state;
                    end if;
                end if;

            when parse_request_state =>

            when set_address_state =>

                r_address <= i_request.wValue(45 downto 39);

            when send_descriptor_state =>

                if (r_counter_active = '0') then
                    r_counter_active <= '1';

                    if (r_address = 0) then
                        counter_transaction_end <= MAX_PACKET_LENGTH;
                    else
                        counter_transaction_end <= USB_DESCRIPTOR_SIZE +
                                                   USB_CRC16_LENGTH * USB_DESCRIPTOR_PACKETS_COUNT;
                    end if;
                end if;

                r_data1_flag       <= not r_data1_flag;
                r_transmit_request <= '1';

                if (r_data1_flag = '1') then
                    r_transmit_pid <= USB_PID_DATA1;
                else
                    r_transmit_pid <= USB_PID_DATA0;
                end if;

                r_transmit_data <= i_lut_data;
                r_lut_address   <= std_logic_vector(r_lut_base_address + counter_transaction);

                if (counter_transaction = counter_transaction_end) then
                    fsm_setup <= descriptor_sent_state;
                end if;

            when send_ack_state =>

                r_transmit_pid     <= USB_PID_ACK;
                r_transmit_request <= '1';
                r_transmit_end     <= '1';

            when send_nak_state =>

                r_transmit_pid     <= USB_PID_NAK;
                r_transmit_request <= '1';
                r_transmit_end     <= '1';

        end case;

    end process;

end architecture rtl;
