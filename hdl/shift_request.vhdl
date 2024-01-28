--! Module description
--! *italic* **bold** ***test***
--! | Table | Table | table
--! | ----- | :-----: | -----:
--! | 1 | 2 | 3
--! | 1 | 2 | 3
--! | 1 | 2 | 3
--! | 1 | 2 | 3
--! | 1 | 2 | 3

--! { signal: [
--!  { name: "clk",  wave: "P......" },
--!  { name: "bus",  wave: "x.==.=x", data: ["head", "body", "tail", "data"] },
--!  { name: "wire", wave: "0.1..0." }
--! ]}


library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.usb_pkg.all;

entity shift_request is
    port (
        --# {{clocks|Clocking}}
        clk    : in    std_logic; --!Clock
        reset  : in    std_logic;
        enable : in    std_logic;

        --# {{control|Control signals}}
        i_request_byte : in    unsigned(7 downto 0);
        o_request      : out   t_usb_request

        --# {{data|Data port}}
        --# {{Additional port1}}
        --# {{}}
    );
end entity shift_request;

architecture rtl of shift_request is

    signal r_request_shift : unsigned(63 downto 0);

begin

    o_request <= (
        bmRequestType => r_request_shift(63 downto 55),
        bRequest      => r_request_shift(54 downto 46),
        wValue        => r_request_shift(45 downto 29),
        wIndex        => r_request_shift(28 downto 16),
        wLength       => r_request_shift(15 downto 0)
    );

    process (clk) is
    begin

        if (reset = '1') then
            r_request_shift <= (others => '0');
        elsif rising_edge(clk) then
            if (enable = '1') then
                r_request_shift             <= shift_left(r_request_shift, 8);
                r_request_shift(7 downto 0) <= i_request_byte;
            end if;
        end if;

    end process;

end architecture rtl;
