library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity lut_ulpi_config is
    port (
        address : in    std_logic_vector(7 downto 0);
        clock   : in    std_logic;
        nrst    : in    std_logic;
        ulpi_data : out   std_logic_vector(7 downto 0)
    );
end entity lut_ulpi_config;

architecture a_lut_ulpi_config of lut_ulpi_config is

    type int_array is array (2 ** 8 downto 0) of std_logic_vector(7 downto 0);

    constant LUT_ULPI_REGISTER_DATA : int_array :=
    (
        0 => X"A1",
        1 => X"A2",
        2 => X"A3",
        3 => X"ED",
        4 => X"DA",
        5 => X"A6",
        6 => X"A7",
        7 => X"A8",
        8 => X"A9",
        9 => X"DA",
        10 => X"DB",
        11 => X"DC",
        12 => X"DD",
        13 => X"DE",
        14 => X"DF",
        15 => X"10",
        16 => X"20",
        17 => X"30",
        18 => X"40",
        19 => X"50",
        20 => X"60",
        21 => X"70",
        22 => X"80",
        23 => X"BE",

        --- DESCRIPTOR
        32 => X"12",
        33 => X"01",
        34 => X"00",
        35 => X"02",
        36 => X"00",
        37 => X"00",
        38 => X"00",
        39 => X"08",
        40 => X"E7",
        41 => X"57", --

        42 => X"6D",
        43 => X"04",
        44 => X"34",
        45 => X"C5",
        46 => X"01",
        47 => X"29",
        48 => X"01",
        49 => X"02",
        50 => X"85",
        51 => X"A5",

        52 => X"00",
        53 => X"01",
        54 => X"84",
        55 => X"3F",

        -- 64 => CONFIG
        64   => X"09",
        65   => X"02",
        66   => X"3B",
        67   => X"00",
        68   => X"02",
        69   => X"01",
        70   => X"04",
        71   => X"A0",
        72   => X"15",
        73   => X"0A",

        74   => X"31",
        75   => X"09",
        76   => X"04",
        77   => X"00",
        78   => X"00",
        79   => X"01",
        80   => X"03",
        81   => X"01",
        82   => X"58",
        83   => X"75",

        84   => X"01",
        85   => X"00",
        86   => X"09",
        87   => X"21",
        88   => X"11",
        89   => X"01",
        90   => X"00",
        91   => X"01",
        92   => X"9A",
        93   => X"57",

        94   => X"22",
        95   => X"3B",
        96   => X"00",
        97   => X"07",
        98   => X"05",
        99   => X"81",
        100  => X"03",
        101  => X"08",
        102  => X"E4",
        103  => X"52",

        104  => X"00",
        105  => X"08",
        106  => X"09",
        107  => X"04",
        108  => X"01",
        109  => X"00",
        110  => X"01",
        111  => X"03",
        112  => X"00",
        113  => X"87",

        114 => X"01",
        115 => X"02",
        116 => X"00",
        117 => X"09",
        118 => X"21",
        119 => X"11",
        120 => X"01",
        121 => X"00",
        122 => X"50",
        123 => X"DA",

        124   => X"01",
        125   => X"22",
        126   => X"B1",
        127   => X"00",
        128   => X"07",
        129   => X"05",
        130   => X"82",
        131   => X"03",
        132   => X"0F",
        133   => X"56",

        134  => X"14",
        135  => X"00",
        136  => X"02",
        137  => X"FA",
        138  => X"4F",

        others => X"FF"
    );

begin

    process (nrst, address) is
    begin

        if (nrst = '0') then
            ulpi_data <= (others => '0');
        else
            ulpi_data <= LUT_ULPI_REGISTER_DATA(to_integer(unsigned(address)));
        end if;

    end process;

end architecture a_lut_ulpi_config;
