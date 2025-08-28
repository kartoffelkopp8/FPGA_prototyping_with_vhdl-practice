library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rotate_sq is
    port(
        clk, reset : in  std_logic;
        cw, en     : in  std_logic;     -- cw is direction bit (1 is forwards, 0 backwards), and en pause bit
        O_SSEG     : out std_logic_vector(7 downto 0); -- output to fpga pins
        O_AN       : out std_logic_vector(3 downto 0) -- regulates which digit to use
    );
end entity rotate_sq;

architecture RTL of rotate_sq is
    signal   r_mod8_ctr, mod8_nxt   : unsigned(2 downto 0); -- square state counter 
    constant COUNTER                : integer := 99_999_999;
    signal   r_counter, counter_nxt : unsigned(26 downto 0); -- clock divider for one second ticks
    signal   tick                   : std_logic;
    signal   in0, in1, in2, in3     : std_logic_vector(7 downto 0);
    constant UPPER                  : std_logic_vector(7 downto 0) := "00111001";
    constant LOWER                  : std_logic_vector(7 downto 0) := "11000101";
    constant OFF                  	: std_logic_vector(7 downto 0) := "11111111";	 

    component led_mux is
        generic(N : integer := 18);
        port(
            clk, reset         : in  std_logic;
            in0, in1, in2, in3 : in  std_logic_vector(7 downto 0);
            o_an               : out std_logic_vector(3 downto 0);
            o_sseg             : out std_logic_vector(7 downto 0)
        );
    end component led_mux;

begin

    -- component instanciation
    led : led_mux port map(
            clk    => clk,
            reset  => reset,
            in0    => in0,
            in1    => in1,
            in2    => in2,
            in3    => in3,
            o_an   => O_AN,
            o_sseg => O_SSEG
    );
    
    -- calculaters the frequency iof the state change
    mod8 : process(clk, reset, tick) is
    begin
        if reset = '1' then
            r_mod8_ctr <= (others => '0');
        elsif rising_edge(clk) and tick = '1' then -- wenbn trick und clk 
            r_mod8_ctr <= mod8_nxt;
        end if;
    end process mod8;

    -- describes the divided clock
    freq : process(clk, reset) is
    begin
        if reset = '1' then
            r_counter <= (others => '0');
            tick      <= '0';
        elsif rising_edge(clk) then
            if to_integer(r_counter) = COUNTER then
                r_counter <= (others => '0');
                tick      <= '1';
            else
                r_counter <= counter_nxt;
                tick      <= '0';
            end if;
        end if;
    end process freq;

    counter_nxt <= r_counter + 1;

    -- describes the calculation of the next state
    logic : process(r_mod8_ctr, en, cw) is
    begin
        mod8_nxt <= r_mod8_ctr;
        if en = '0' then 
            if cw = '0' then
                if to_integer(r_mod8_ctr) = 7 then
                    mod8_nxt <= (others => '0');
                else
                    mod8_nxt <= r_mod8_ctr + 1;
                end if;
            else
                if to_integer(r_mod8_ctr) = 0 then
                    mod8_nxt <= (others => '1');
                else
                    mod8_nxt <= r_mod8_ctr - 1;
                end if;
            end if;
        end if;
    end process logic;

    -- describes which sqaure to display where
    process(r_mod8_ctr) is 
    begin 
			in0 <= OFF;
			in1 <= OFF;
			in2 <= OFF;
			in3 <= OFF;
        case to_integer(r_mod8_ctr) is 
            when 0 => 
                in3 <= UPPER;
            when 1 =>
                in2 <= UPPER;
            when 2 =>
                in1 <= UPPER;
            when 3 =>
                in0 <= UPPER;
            when 4 => 
                in0 <= LOWER;
            when 5 =>
                in1 <= LOWER;
            when 6 =>
                in2 <= LOWER;
            when others =>
                in3 <= LOWER;
            end case;
    end process;
end architecture RTL;

