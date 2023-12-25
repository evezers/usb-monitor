library ieee;
    use ieee.std_logic_1164.all;

library osvvm;
    context osvvm.osvvmcontext;

entity fsm_ulpi_tester is
    port (
        clk   : in std_logic;
        reset : out std_logic;
        enable : out    std_logic;

        new_cmd  : out    std_logic;
        i_data   : out    std_logic_vector(7 downto 0);
        reg_data : out    std_logic_vector(7 downto 0)
        
    );
end entity fsm_ulpi_tester;

architecture rtl of fsm_ulpi_tester is
    signal reset_r : std_logic;
    signal address_r : std_logic_vector(5 downto 0);
    signal cmd_r : std_logic_vector(7 downto 6);
begin
    i_data(7 downto 6) <= cmd_r;
    i_data(5 downto 0) <= address_r;


    CreateReset(
                Reset       => reset_r,
                ResetActive => '1',
                Clk         => clk,
                Period      => 5 * 10 ns,
                tpd         => 2 ns
            );

    enable <= '1';

    new_cmd <= '1';
    address_r <= b"010110";
    cmd_r <= b"10";
    reg_data <= b"1010_1010";

    WaitForClock(clk, 2);

    new_cmd <= '0';

    WaitForClock(clk, 20);

    

end architecture;