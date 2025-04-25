library ieee;
use ieee.std_logic_1164.all;

use work.recop_types.all;
use work.opcodes.all;
use work.various_constants.all;

entity recop_top is
end entity;

architecture sim of recop_top is
    signal clk   : bit_1 := '0';
    signal reset : bit_1 := '1';

    signal key   : bit_4 := (others => '0');
    signal sw    : bit_10 := (others => '0');
    signal led   : bit_10;
    signal hex0, hex1, hex2, hex3, hex4, hex5 : bit_7;

begin

    uut: entity work.recop
        port map (
            clk   => clk,
            reset => reset,
            key   => key,
            sw    => sw,
            led   => led,
            hex0  => hex0,
            hex1  => hex1,
            hex2  => hex2,
            hex3  => hex3,
            hex4  => hex4,
            hex5  => hex5
        );

    -- Clock generation
    clk_gen : process
    begin
        while true loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
    end process;

    -- Reset pulse
    reset_gen : process
    begin
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait;
    end process;

end architecture;
