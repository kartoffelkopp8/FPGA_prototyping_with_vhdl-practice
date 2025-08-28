library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_mux is
    generic(N : integer := 18);
    port(
        clk, reset         : in  std_logic;
        in0, in1, in2, in3 : in  std_logic_vector(7 downto 0);
        o_an               : out std_logic_vector(3 downto 0);
        o_sseg             : out std_logic_vector(7 downto 0)
    );
end entity led_mux;

architecture led_mux_arch of led_mux is
    signal r_counter, counter_next : unsigned(N - 1 downto 0);
    signal sel                     : std_logic_vector(1 downto 0);
begin
    count : process(clk, reset) is
    begin
        if reset = '1' then
            r_counter <= (others => '0');
        elsif rising_edge(clk) then
            r_counter <= counter_next;
        end if;
    end process count;

    counter_next <= r_counter + 1;

    sel <= std_logic_vector(r_counter(N - 1 downto N - 2));

    with sel select o_an <=
        "1110" when "00",
        "1101" when "01",
        "1011" when "10",
        "0111" when others;

    sseg : process(clk, sel, in0, in1, in2, in3) is
    begin
        case sel is
            when "00" =>
                o_sseg <= in0;
            when "01" =>
                o_sseg <= in1;
            when "10" =>
                o_sseg <= in2;
            when others =>
                o_sseg <= in3;
        end case;
    end process sseg;
    
end architecture led_mux_arch;
