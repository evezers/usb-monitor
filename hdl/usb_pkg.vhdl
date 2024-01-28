library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
-- use ieee.math_real.all;

package usb_pkg is

    type t_usb_request is record
        bmRequestType : unsigned(63 downto 55);
        bRequest      : unsigned(54 downto 46);
        wValue        : unsigned(45 downto 29);
        wIndex        : unsigned(28 downto 16);
        wLength       : unsigned(15 downto 0);
    end record t_usb_request;

    type t_usb_token is record
        address  : unsigned(15 downto 9);
        endpoint : unsigned(8 downto 5);
        CRC5     : unsigned(4 downto 0);
    end record t_usb_token;

    constant USB_PID_OUT   : std_logic_vector(3 downto 0) := b"0001";
    constant USB_PID_IN    : std_logic_vector(3 downto 0) := b"1001";
    constant USB_PID_SETUP : std_logic_vector(3 downto 0) := b"1101";

    constant USB_PID_DATA0 : std_logic_vector(3 downto 0) := b"0011";
    constant USB_PID_DATA1 : std_logic_vector(3 downto 0) := b"1011";

    constant USB_PID_ACK : std_logic_vector(3 downto 0) := b"0010";
    constant USB_PID_NAK : std_logic_vector(3 downto 0) := b"1010";

    constant USB_REQUEST_SET_ADDRESS    : natural := 5;
    constant USB_REQUEST_GET_DESCRIPTOR : natural := 6;

    constant USB_CRC16_LENGTH    : natural := 2;
    constant USB_MAX_PACKET_SIZE : natural := 8;

    constant USB_DESCRIPTOR_SIZE          : natural := 18;
    constant USB_DESCRIPTOR_PACKETS_COUNT : natural := USB_DESCRIPTOR_SIZE / USB_MAX_PACKET_SIZE + 1;
-- constant USB_DESCRIPTOR_PACKETS_COUNT : natural := natural(ceil(real(USB_DESCRIPTOR_SIZE) /
--                                                                 real(USB_MAX_PACKET_SIZE)));

end package usb_pkg;
