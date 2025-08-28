library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rotating_banner is
    generic(WBCD : integer := 40);      -- generic for the width of the banner itself
    port(
        clk, reset : in  std_logic;
        en, cw     : in  std_logic;     -- en = 1 is pause, cw = 1 rotate left, = 0 is rotate rigth
        O_SSEG     : out std_logic_vector(7 downto 0);
        O_AN       : out std_logic_vector(3 downto 0)
    );
end entity rotating_banner;

architecture behavioural of rotating_banner is

    function multi(input : std_logic_vector(3 downto 0))
    return std_logic_vector is
        variable ret : std_logic_vector(7 downto 0);

    begin
        case input is
            when "0000" =>
                ret := "00000011";
            when "0001" =>
                ret := "10011111";
            when "0010" =>
                ret := "00100101";
            when "0011" =>
                ret := "00001101";
            when "0100" =>
                ret := "10011001";
            when "0101" =>
                ret := "01001001";
            when "0110" =>
                ret := "00000101";
            when "0111" =>
                ret := "00011111";
            when "1000" =>
                ret := "00000001";
            when others =>
                ret := "00001001";
        end case;
        return ret;
    end function;

    component led_mux is
        generic(N : integer := 18);
        port(
            clk, reset         : in  std_logic;
            in0, in1, in2, in3 : in  std_logic_vector(7 downto 0);
            o_an               : out std_logic_vector(3 downto 0);
            o_sseg             : out std_logic_vector(7 downto 0)
        );
    end component;

    constant COUNT                  : integer                       := 99_999_999;
    signal   r_counter, counter_nxt : unsigned(26 downto 0); -- counter for clock divider
    signal   tick                   : std_logic;
    signal   banner, banner_nxt     : std_logic_vector(WBCD - 1 downto 0);
    constant START                  : std_logic_vector(39 downto 0) := "0000000100100011010001010110011110001001"; -- bcd banner for 0 to 9
    signal   in0, in1, in2, in3     : std_logic_vector(7 downto 0);
begin
    regs : process(clk, reset) is
    begin
        if reset = '1' then
            banner    <= START;
            r_counter <= (others => '0');
        -- tick <= '0';
        elsif rising_edge(clk) then
            -- banner <= banner_nxt;
            if to_integer(r_counter) = COUNT then
                r_counter <= (others => '0');
                banner <= banner_nxt;
            -- tick <= '1';
            else
                r_counter <= counter_nxt;
                banner <= banner;
                -- tick <= '0';
            end if;
        end if;
    end process regs;

    counter_nxt <= r_counter + 1;

    with std_logic_vector'(en & cw) select banner_nxt <=
        banner when "00" | "01",
        banner(3 downto 0) & banner(39 downto 4) when "10", -- rotate rigth
        banner(35 downto 0) & banner(39 downto 36) when others;

    in0 <= multi(banner(3 downto 0));
    in1 <= multi(banner(7 downto 4));
    in2 <= multi(banner(11 downto 8));
    in3 <= multi(banner(15 downto 12));

    led_mux_inst : component led_mux
        generic map(
            N => 18
        )
        port map(
            clk    => clk,
            reset  => reset,
            in0    => in0,
            in1    => in1,
            in2    => in2,
            in3    => in3,
            o_an   => O_AN,
            o_sseg => O_SSEG
        );

end architecture behavioural;
