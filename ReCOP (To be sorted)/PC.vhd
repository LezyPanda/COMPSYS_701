Library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.recop_types.all;



-- Program counter shit, I have no idea wtf im doing half the time

entity PC is 
    PORT(
        clk : in bit_1;
        reset : in bit_1;
        PC : in bit_16;
        IR : in bit_16;
        OP : in bit_16;
        instr_prev : bit_16;
    );
end entity PC;

architecture beh of PC is 
    begin 
        if reset = '1' then
            PC <= (others => '0');
            IR <= (others => '0');
            OP <= (others => '0');
        elsif rising_edge(clk) then
            if instr_prev(31 downto 30) = "01" or instr_prev(31 downto 30) = "10" then
                IR <= PM(to_integer(unsigned(PC)));
                OP <= PM(to_integer(unsigned(PC)) + 1);
                PC <= std_logic_vector(unsigned(PC) + 2);
            else
                IR <= operand_prev;
                OP <= PM(to_integer(unsigned(PC)));
                PC <= std_logic_vector(unsigned(PC) + 1);
            end if;
        end if;        
end beh