library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity vgamod is
    port (
        -- clk       : in    std_logic;
        reset     : in    std_logic;
        pixel_clk : in    std_logic;

        lcd_de    : out   std_logic;
        lcd_hsync : out   std_logic;
        lcd_vsync : out   std_logic;
        lcd_b     : out   std_logic_vector(4 downto 0);
        lcd_g     : out   std_logic_vector(5 downto 0);
        lcd_r     : out   std_logic_vector(4 downto 0)
    );
end entity vgamod;

architecture rtl of vgamod is

    signal pixel_count : unsigned(15 downto 0);
    signal line_count  : unsigned(15 downto 0);

    constant H_PIXELS     : unsigned(15 downto 0) := 16d"804";
    constant H_FRONTPORCH : unsigned(15 downto 0) := 16d"40";
    constant H_SYNCTIME   : unsigned(15 downto 0) := 16d"128";
    constant H_BACKPORCH  : unsigned(15 downto 0) := 16d"88";
    constant H_SYNCSTART  : unsigned(15 downto 0) := 16d"900";
    constant H_SYNCEND    : unsigned(15 downto 0) := 16d"1028";
    constant H_PERIOD     : unsigned(15 downto 0) := 16d"1056";

    constant V_LINES      : unsigned(15 downto 0) := 16d"604";
    constant V_FRONTPORCH : unsigned(15 downto 0) := 16d"1";
    constant V_SYNCTIME   : unsigned(15 downto 0) := 16d"4";
    constant V_BACKPORCH  : unsigned(15 downto 0) := 16d"23";
    constant V_SYNCSTART  : unsigned(15 downto 0) := 16d"603";
    constant V_SYNCEND    : unsigned(15 downto 0) := 16d"607";
    constant V_PERIOD     : unsigned(15 downto 0) := 16d"628";

    constant BAR_COUNT : unsigned(15 downto 0) := 16d"16";
    constant WIDTH_BAR : unsigned(15 downto 0) := H_PIXELS / BAR_COUNT;

    constant PIXEL_FOR_HS : unsigned(15 downto 0) := H_PERIOD; -- H_PIXELS + H_BACKPORCH + H_FRONTPORCH;
    constant LINE_FOR_VS  : unsigned(15 downto 0) := V_PERIOD; -- V_LINES + V_BACKPORCH + V_FRONTPORCH;

    signal data_r : std_logic_vector(4 downto 0);
    signal data_g : std_logic_vector(5 downto 0);
    signal data_b : std_logic_vector(4 downto 0);

    signal hcnt,   vcnt     : unsigned(11 downto 0);
    signal enable, hsyncint : std_logic;

begin

    process (pixel_clk, reset) is
    begin

        if (reset = '1') then
            pixel_count <= (others => '0');
            line_count  <= (others => '0');

            data_r <= (others => '0');
            data_g <= (others => '0');
            data_b <= (others => '0');
        elsif rising_edge(pixel_clk) then
            if (pixel_count = PIXEL_FOR_HS) then
                pixel_count <= (others => '0');
                line_count  <= line_count + x"1";
            elsif (line_count = LINE_FOR_VS) then
                pixel_count <= (others => '0');
                line_count  <= (others => '0');
            else
                pixel_count <= pixel_count + x"1";
            end if;

            if ((pixel_count>0) and (pixel_count<100)) then
                data_g <= 6x"3F";                                 -- green
            elsif ((pixel_count>101) and (pixel_count<200)) then
                data_r <= 5x"1F";                                 -- red
            elsif ((pixel_count>201) and (pixel_count<300)) then
                data_b <= 5x"1F";                                 -- blue
            elsif ((pixel_count>301) and (pixel_count<400)) then
                data_g <= 6x"0F";                                 -- green
            elsif ((pixel_count>401) and (pixel_count<500)) then
                data_r <= 5x"0F";                                 -- red
            elsif ((pixel_count>501) and (pixel_count<600)) then
                data_b <= 5x"0F";                                 -- blue
            elsif ((pixel_count>601) and (pixel_count<700)) then
                data_g <= 6x"07";                                 -- green
            elsif ((pixel_count>701) and (pixel_count<800)) then
                data_r <= 5x"07";                                 -- red
            else
                data_b <= 5x"00";
                data_r <= 5x"00";
                data_g <= 6x"00";
            end if;
        end if;

    end process;

    lcd_b <= data_b;
    lcd_g <= data_g;
    lcd_r <= data_r;

    lcd_hsync <= '0' when ((pixel_count >= H_SYNCSTART) and (pixel_count <= H_SYNCEND)) else
                 '1';
    lcd_vsync <= '0' when (((line_count  >= V_SYNCSTART) and (line_count  <= V_SYNCEND))) else
                 '1';

    lcd_de <= '1' when ((pixel_count >= H_BACKPORCH) and
                           (pixel_count <= PIXEL_FOR_HS - H_FRONTPORCH) and
                           (line_count >= V_BACKPORCH) and
                           (line_count <= LINE_FOR_VS - V_FRONTPORCH - 1)) else
              '0';

end architecture rtl;
