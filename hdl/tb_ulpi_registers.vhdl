library vunit_lib;
    context vunit_lib.vunit_context;

library osvvm;
    context osvvm.osvvmcontext;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity tb_ulpi_registers is
    generic (
        runner_cfg : string := runner_cfg_default
    );
end entity tb_ulpi_registers;

architecture tb of tb_ulpi_registers is

    signal clk_r   : std_logic := '0';
    signal reset_r : std_logic;
    signal data_r  : std_logic_vector(7 downto 0);
    signal dir_r   : std_logic;

    signal clk      : std_logic;
    signal reset    : std_logic;
    signal enable   : std_logic;
    signal new_cmd  : std_logic;
    signal i_data   : std_logic_vector(7 downto 0);
    signal reg_data : std_logic_vector(7 downto 0);

    signal dir           : std_logic;
    signal nxt           : std_logic;
    signal o_data        : std_logic_vector(7 downto 0);
    signal stp           : std_logic;
    signal o_read_data   : std_logic_vector(7 downto 0);
    signal add_test_data : std_logic;

    signal rst : std_logic;

    -- component ulpi_driver is
    --     port (
    --         clk66           : inout std_logic;
    --         rst           : out   std_logic;
    --         data          : inout std_logic_vector(7 downto 0);
    --         dir           : out   std_logic;
    --         nxt           : out   std_logic;
    --         stp           : in    std_logic;
    --         add_test_data : in    std_logic
    --     );
    -- end component;

begin

    

    -- fsm_ulpi_tester_inst : entity work.fsm_ulpi_tester
    --     port map (
    --         clk      => clk,
    --         reset    => reset,
    --         enable   => enable,
    --         new_cmd  => new_cmd,
    --         i_data   => i_data,
    --         reg_data => reg_data
    --     );

    -- fsm_ulpi_inst : entity work.fsm_ulpi
    --     port map (
    --         clk         => clk,
    --         reset       => reset,
    --         enable      => enable,
    --         new_cmd     => new_cmd,
    --         i_data      => i_data,
    --         reg_data    => reg_data,
    --         dir         => dir,
    --         nxt         => nxt,
    --         o_data      => o_data,
    --         stp         => stp,
    --         o_read_data => o_read_data
    --     );

    -- ulpi_driver_inst : component ulpi_driver
    --     port map (
    --         clk66           => clk,
    --         rst           => rst,
    --         data          => o_data,
    --         dir           => dir,
    --         nxt           => nxt,
    --         stp           => stp,
    --         add_test_data => add_test_data
    --     );

    -- ulpi_driver ULPI
    -- (
    --     .clk (ulpi_clk),
    --     .rst (ulpi_rst),
    --     .data (ulpi_data),
    --     .dir (ulpi_dir),
    --     .nxt (ulpi_nxt),
    --     .stp (ulpi_stp),
    --     .add_test_data(add_test_data)
    -- );

    -- ulpi_link_inst : entity work.ulpi_link
    --     port map (
    --         clk   => clk_r,
    --         reset => reset_r,
    --         data  => data_r,
    --         dir   => dir_r
    --     );

    -- tester_ulpi_inst : entity work.tester_ulpi
    --     port map (
    --         clk   => clk_r,
    --         reset => reset_r,
    --         data  => data_r,
    --         dir   => dir_r
    --     );

    CreateClock(
                Clk       => clk_r,
                Period    => 10 ns,
                DutyCycle => 0.5
            );

    CreateReset(
                Reset       => reset_r,
                ResetActive => '1',
                Clk         => clk_r,
                Period      => 5 * 10 ns,
                tpd         => 2 ns
            );

    main : process is
    begin

        test_runner_setup(runner, runner_cfg);

        while test_suite loop

            if run("test_pass") then
                WaitForClock(clk_r, 10);

                report "This will pass";
            -- elsif run("test_fail") then
            --     assert true
            --         report "It fails";
            end if;

        end loop;

        test_runner_cleanup(runner);

    end process;

end architecture tb;
