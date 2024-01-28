library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.usb_pkg.all;

entity shift_packet is
    port (
        clk    : in    std_logic;
        reset  : in    std_logic;
        enable : in    std_logic;

        i_packet_byte : in    unsigned(7 downto 0);
        o_packet      : out   t_usb_token
    );
end entity shift_packet;

architecture rtl of shift_packet is

    signal r_request_shift : unsigned(15 downto 0);

begin

    o_packet <=
    (
        address  => r_request_shift(15 downto 9),
        endpoint => r_request_shift(8 downto 5),
        CRC5     => r_request_shift(4 downto 0)
    );

    process (clk, reset) is
    begin

        if (reset = '1') then
            r_request_shift <= (others => '0');
        elsif rising_edge(clk) then
            if (enable = '1') then
                r_request_shift             <= shift_left(r_request_shift, 8);
                r_request_shift(7 downto 0) <= i_packet_byte;
            end if;
        end if;

    end process;

end architecture rtl;
