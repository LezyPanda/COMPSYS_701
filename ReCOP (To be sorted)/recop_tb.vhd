-- filepath: vsls:/ReCOP%20%28To%20be%20sorted%29/recop_tb.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.recop_types.all;
use work.opcodes.all;
use work.various_constants.all;

entity recop_tb is
end entity;

architecture sim of recop_tb is
    -- signals for DUT
    signal clk    : bit_1    := '0';
    signal reset  : bit_1    := '1';
    signal key    : bit_4    := (others => '0');
    signal sw     : bit_10   := (others => '0');
    signal led    : bit_10;
    signal hex0   : bit_7;
    signal hex1   : bit_7;
    signal hex2   : bit_7;
    signal hex3   : bit_7;
    signal hex4   : bit_7;
    signal hex5   : bit_7;

    constant clk_period : time := 10 ns;
begin
    -- Instantiate UUT
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
    clk_gen: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus
    stim: process
    begin
        -- apply reset
        report "Applying reset" severity note;
        reset <= '1';
        wait for 2*clk_period;
        reset <= '0';
        wait for clk_period;

        -- Test vector 1
        report "Test 1: sw=0000000001, key=0001" severity note;
        sw  <= "0000000001";
        key <= "0001";
        wait for 20*clk_period;
        report "  -> led = " & to_string(led) severity note;

        -- Test vector 2
        report "Test 2: sw=0000000010, key=0010" severity note;
        sw  <= "0000000010";
        key <= "0010";
        wait for 20*clk_period;
        report "  -> led = " & to_string(led) severity note;

        -- Test vector 3
        report "Test 3: sw=0000001010, key=1111" severity note;
        sw  <= "0000001010";
        key <= "1111";
        wait for 50*clk_period;
        report "  -> led = " & to_string(led) severity note;

        -- wait to observe final state
        wait for 100*clk_period;
        report "End of simulation" severity note;
        wait;  -- stop
    end process;

    -- helper function to print bit_10 as string
    function to_string(v : bit_10) return string is
        variable s : string(1 to 10);
    begin
        for i in 0 to 9 loop
            s(i+1) := character'VALUE(bit'image(v(i)));
        end loop;
        return s;
    end function;
end architecture;