library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.usb_pkg.all;
    use work.ulpi_pkg.all;

entity usb_device is
    port (
        -- clk   : in std_logic;
        reset  : in    std_logic;
        enable : in    std_logic;

        ulpi_data : inout std_logic_vector(7 downto 0);
        ulpi_stp  : out   std_logic;
        ulpi_nxt  : in    std_logic;
        ulpi_dir  : in    std_logic;
        ulpi_clk  : in    std_logic;
        ulpi_rst  : out   std_logic
    );
end entity usb_device;

architecture rtl of usb_device is

    -- signal enable : std_logic;

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

    signal i_ulpi   : t_from_ulpi;
    signal i_ulpi_r : t_from_ulpi;
    signal o_ulpi   : t_to_ulpi;

    signal r_address : unsigned(6 downto 0);

    -- signal clk : std_logic;
    -- signal reset : std_logic;
    -- signal enable : std_logic;
    signal o_fsm_ulpi_registers_enable : std_logic;
    signal o_register_request          : std_logic;
    signal o_register_address          : std_logic_vector(7 downto 0);
    signal o_register_data             : std_logic_vector(7 downto 0);
    signal i_register_busy             : std_logic;
    signal o_fsm_ulpi_transmit_enable  : std_logic;
    -- signal o_transmit_end : std_logic;
    -- signal o_transmit_request : std_logic;
    -- signal o_transmit_pid : std_logic_vector(3 downto 0);
    -- signal o_transmit_data : std_logic_vector(7 downto 0);
    -- signal i_transmit_busy : std_logic;
    -- signal i_transmit_hold : std_logic;
    -- signal ulpi_config_finished : std_logic;

begin

    fsm_usb_config_inst : entity work.fsm_usb_config
        port map (
            clk    => ulpi_clk,
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
            i_lut_data    => i_lut_data,

            o_address => r_address
        );

    shift_request_inst : entity work.shift_request
        port map (
            clk    => ulpi_clk,
            reset  => reset,
            enable => o_shift_request_enable,

            i_request_byte => o_request_byte,
            o_request      => i_request
        );

    fsm_ulpi_receive_inst : entity work.fsm_ulpi_receive
        port map (
            clk    => ulpi_clk,
            reset  => reset,
            enable => enable,

            o_receive_data => i_receive_data,
            o_receive_busy => i_receive_busy,
            o_receive_hold => i_receive_hold,

            i_ulpi => i_ulpi
        --            o_ulpi => o_ulpi
        );

    fsm_ulpi_transmit_inst : entity work.fsm_ulpi_transmit
        port map (
            clk    => ulpi_clk,
            reset  => reset,
            enable => o_fsm_ulpi_transmit_enable,

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
            clock   => ulpi_clk,
            nrst    => "not"(reset),
            -- ulpi_register_address => (others => '0'),
            ulpi_data => i_lut_data
        );

    fsm_control_inst : entity work.fsm_control
        port map (
            clk                         => ulpi_clk,
            reset                       => reset,
            enable                      => enable,
            o_fsm_ulpi_registers_enable => o_fsm_ulpi_registers_enable,
            o_register_request          => o_register_request,
            o_register_address          => o_register_address,
            o_register_data             => o_register_data,
            i_register_busy             => i_register_busy,
            o_fsm_ulpi_transmit_enable  => o_fsm_ulpi_transmit_enable
        --   o_transmit_end => o_transmit_end,
        --   o_transmit_request => o_transmit_request,
        --   o_transmit_pid => o_transmit_pid,
        --   o_transmit_data => o_transmit_data,
        --   i_transmit_busy => i_transmit_busy,
        --   i_transmit_hold => i_transmit_hold,
        --          ulpi_config_finished => ulpi_config_finished
        );

    fsm_ulpi_registers_inst : entity work.fsm_ulpi_registers
        port map (
            clk                => ulpi_clk,
            reset              => reset,
            enable             => o_fsm_ulpi_registers_enable,
            i_register_request => o_register_request,
            i_register_address => o_register_address,
            i_register_data    => o_register_data,
            -- o_register_data => i_register_data,
            o_register_busy => i_register_busy,
            i_ulpi          => i_ulpi,
            o_ulpi          => o_ulpi
        );

    ulpi_data   <= o_ulpi.data;-- when i_ulpi.dir = '0' else
                --    (others => 'Z');
    i_ulpi.data <= ulpi_data;

    ulpi_stp <= o_ulpi.stp;

    i_ulpi.nxt <= ulpi_nxt;
    i_ulpi.dir <= ulpi_dir;
    ulpi_rst <= '0';

end architecture rtl;
