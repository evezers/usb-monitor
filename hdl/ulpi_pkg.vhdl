library ieee;
    use ieee.std_logic_1164.all;

package ulpi_pkg is

    type t_from_ulpi is record
        dir  : std_logic;
        nxt  : std_logic;
        data : std_logic_vector(7 downto 0);
    end record t_from_ulpi;

    type t_to_ulpi is record
        data : std_logic_vector(7 downto 0);
        stp  : std_logic;
    end record t_to_ulpi;

    constant ULPI_CMD_IDLE : std_logic_vector(7 downto 0) := (others => '0');

    constant ULPI_CMD_HEAD_TRANSMIT       : std_logic_vector(7 downto 6) := "01";
    constant ULPI_CMD_HEAD_REGISTER_WRITE : std_logic_vector(7 downto 6) := "10";
    constant ULPI_CMD_HEAD_REGISTER_READ  : std_logic_vector(7 downto 6) := "11";

end package ulpi_pkg;
