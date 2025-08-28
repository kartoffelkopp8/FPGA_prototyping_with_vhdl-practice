library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity heartbeat is
    port(
        clk    : in  std_logic;
        reset  : in  std_logic;
        O_SSEG : out std_logic_vector(7 downto 0);
        O_AN   : out std_logic_vector(3 downto 0)
    );
end entity heartbeat;

architecture behave of heartbeat is
    component led_mux is
        generic(N : integer := 18);
        port(
            clk, reset         : in  std_logic;
            in0, in1, in2, in3 : in  std_logic_vector(7 downto 0);
            o_an               : out std_logic_vector(3 downto 0);
            o_sseg             : out std_logic_vector(7 downto 0)
        );
    end component led_mux;

    signal   in0, in1, in2, in3     : std_logic_vector(7 downto 0);
    signal   r_counter, counter_nxt : unsigned(23 downto 0);
    constant COUNT                  : integer                      := 13_888_888;
    signal   tick                   : std_logic;
    constant ONE                    : std_logic_vector(7 downto 0) := "10011111"; -- line on the rigth 
    constant TWO                    : std_logic_vector(7 downto 0) := "11110011"; -- line on the left
    constant OFF                    : std_logic_vector(7 downto 0) := "11111111"; -- turn off

    type   state is (INNER, MIDDLE, OUTER);
    signal st    : state;
begin
    Hz72 : process(clk, reset) is
    begin
        if reset = '1' then
            r_counter <= (others => '0');
            tick      <= '0';
        elsif rising_edge(clk) then
            if to_integer(r_counter) = COUNT then
                r_counter <= (others => '0');
                tick      <= '1';
            else
                r_counter <= counter_nxt;
                tick      <= '0';
            end if;
        end if;
    end process;

    counter_nxt <= r_counter +1;

    states : process(clk, reset, tick) is
    begin
        if reset = '1' then
            st <= INNER;
        elsif rising_edge(clk) and tick = '1' then
            case st is
                when INNER =>
                    st <= MIDDLE;
                when MIDDLE =>
                    st <= OUTER;
                when others =>
                    st <= INNER;
            end case;
        end if;
    end process states;

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

    logic : process(st) is
    begin
        in0 <= OFF;
        in1 <= OFF;
        in2 <= OFF;
        in3 <= OFF;
        case st is
            when INNER =>
                in1 <= TWO;
                in2 <= ONE;
            when MIDDLE =>
                in1 <= ONE;
                in2 <= TWO;
            when others =>
                in0 <= ONE;
                in3 <= TWO;
        end case;
    end process logic;

end architecture behave;
