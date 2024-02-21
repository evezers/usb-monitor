library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.usb_pkg.all;
    use work.ulpi_pkg.all;

entity top is
    port (
        clk   : in    std_logic;
        rst_n : in    std_logic;

        lcd_clk   : out   std_logic;
        lcd_de    : out   std_logic;
        lcd_hsync : out   std_logic;
        lcd_vsync : out   std_logic;
        lcd_b     : out   std_logic_vector(4 downto 0);
        lcd_g     : out   std_logic_vector(5 downto 0);
        lcd_r     : out   std_logic_vector(4 downto 0);

        -- vsg_off port_010
        O_psram_ck      : out   std_logic_vector(1 downto 0);
        O_psram_ck_n    : out   std_logic_vector(1 downto 0);
        IO_psram_rwds   : inout std_logic_vector(1 downto 0);
        O_psram_reset_n : out   std_logic_vector(1 downto 0);
        IO_psram_dq     : inout std_logic_vector(15 downto 0);
        O_psram_cs_n    : out   std_logic_vector(1 downto 0);
        -- vsg_on

        ulpi_data : inout std_logic_vector(7 downto 0);
        ulpi_stp  : out   std_logic;
        ulpi_nxt  : in    std_logic;
        ulpi_dir  : in    std_logic;
        ulpi_clk  : in    std_logic;
        ulpi_rst  : out   std_logic
    );
end entity top;

architecture rtl of top is

    signal clkout  : std_logic; -- //output clkout      //200M
    signal clkoutd : std_logic; -- //output clkoutd   //50M
    signal clkin   : std_logic;
    signal lock    : std_logic;

    signal memory_clk     : std_logic;
    signal pll_lock       : std_logic;
    signal init_calib0    : std_logic;
    signal init_calib1    : std_logic;
    signal clk_out        : std_logic;
    signal cmd0           : std_logic;
    signal cmd1           : std_logic;
    signal cmd_en0        : std_logic;
    signal cmd_en1        : std_logic;
    signal addr0          : std_logic_vector(20 downto 0);
    signal addr1          : std_logic_vector(20 downto 0);
    signal wr_data0       : std_logic_vector(31 downto 0);
    signal wr_data1       : std_logic_vector(31 downto 0);
    signal rd_data0       : std_logic_vector(31 downto 0);
    signal rd_data1       : std_logic_vector(31 downto 0);
    signal rd_data_valid0 : std_logic;
    signal rd_data_valid1 : std_logic;
    signal data_mask0     : std_logic_vector(3 downto 0);
    signal data_mask1     : std_logic_vector(3 downto 0);

    signal pixel_clk : std_logic;
    signal reset     : std_logic;
    signal enable    : std_logic;

    -- vsg_off component_008 component_012 port_010
    component Gowin_rPLL is
        port (
            clkout  : out   std_logic;
            clkoutd : out   std_logic;
            lock    : out   std_logic;
            clkin   : in    std_logic
        );
    end component;

    component PSRAM_Memory_Interface_HS_2CH_Top is
        port (
            clk             : in    std_logic;
            rst_n           : in    std_logic;
            memory_clk      : in    std_logic;
            pll_lock        : in    std_logic;
            O_psram_ck      : out   std_logic_vector(1 downto 0);
            O_psram_ck_n    : out   std_logic_vector(1 downto 0);
            IO_psram_rwds   : inout std_logic_vector(1 downto 0);
            O_psram_reset_n : out   std_logic_vector(1 downto 0);
            IO_psram_dq     : inout std_logic_vector(15 downto 0);
            O_psram_cs_n    : out   std_logic_vector(1 downto 0);
            init_calib0     : out   std_logic;
            init_calib1     : out   std_logic;
            clk_out         : out   std_logic;
            cmd0            : in    std_logic;
            cmd1            : in    std_logic;
            cmd_en0         : in    std_logic;
            cmd_en1         : in    std_logic;
            addr0           : in    std_logic_vector(20 downto 0);
            addr1           : in    std_logic_vector(20 downto 0);
            wr_data0        : in    std_logic_vector(31 downto 0);
            wr_data1        : in    std_logic_vector(31 downto 0);
            rd_data0        : out   std_logic_vector(31 downto 0);
            rd_data1        : out   std_logic_vector(31 downto 0);
            rd_data_valid0  : out   std_logic;
            rd_data_valid1  : out   std_logic;
            data_mask0      : in    std_logic_vector(3 downto 0);
            data_mask1      : in    std_logic_vector(3 downto 0)
        );
    end component;
-- vsg_on

begin

    clkin      <= clk;
    memory_clk <= clkoutd;
    pixel_clk  <= clkoutd;
    lcd_clk    <= clkoutd;
    pll_lock   <= lock;

    reset  <= not rst_n;
    enable <= '1';

    -- vsg_off instantiation_008 instantiation_009 instantiation_028 port_map_002
    Gowin_rPLL_inst : component Gowin_rPLL
        port map (
            clkout  => clkout,
            clkoutd => clkoutd,
            lock    => lock,
            clkin   => clkin
        );

    PSRAM_Memory_Interface_HS_2CH_Top_inst : component PSRAM_Memory_Interface_HS_2CH_Top
        port map (
            clk             => clk,
            rst_n           => rst_n,
            memory_clk      => memory_clk,
            pll_lock        => pll_lock,
            O_psram_ck      => O_psram_ck,
            O_psram_ck_n    => O_psram_ck_n,
            IO_psram_rwds   => IO_psram_rwds,
            O_psram_reset_n => O_psram_reset_n,
            IO_psram_dq     => IO_psram_dq,
            O_psram_cs_n    => O_psram_cs_n,
            init_calib0     => init_calib0,
            init_calib1     => init_calib1,
            clk_out         => clk_out,
            cmd0            => cmd0,
            cmd1            => cmd1,
            cmd_en0         => cmd_en0,
            cmd_en1         => cmd_en1,
            addr0           => addr0,
            addr1           => addr1,
            wr_data0        => wr_data0,
            wr_data1        => wr_data1,
            rd_data0        => rd_data0,
            rd_data1        => rd_data1,
            rd_data_valid0  => rd_data_valid0,
            rd_data_valid1  => rd_data_valid1,
            data_mask0      => data_mask0,
            data_mask1      => data_mask1
        );
    -- vsg_on

    vgamod_inst : entity work.vgamod
        port map (
            reset     => reset,
            pixel_clk => pixel_clk,
            lcd_de    => lcd_de,
            lcd_hsync => lcd_hsync,
            lcd_vsync => lcd_vsync,
            lcd_b     => lcd_b,
            lcd_g     => lcd_g,
            lcd_r     => lcd_r
        );

    usb_device_inst : entity work.usb_device
        port map (
            reset     => reset,
            enable    => enable,
            ulpi_data => ulpi_data,
            ulpi_stp  => ulpi_stp,
            ulpi_nxt  => ulpi_nxt,
            ulpi_dir  => ulpi_dir,
            ulpi_clk  => ulpi_clk,
            ulpi_rst  => ulpi_rst
        );

end architecture rtl;
