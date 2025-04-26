library IEEE;
use IEEE.std_logic_1164.all;   

entity Bcd2seg7 is
	port (
		conv_in 	: in std_logic_vector(3 downto 0);
		conv_out 	: out std_logic_vector(6 downto 0)
	);
end entity;

architecture aBcd2seg7 of Bcd2seg7 is
begin
    conv_out <= 
		"1111001" when Conv_in = "0001" else -- 1
		"0100100" when Conv_in = "0010" else -- 2
		"0110000" when Conv_in = "0011" else -- 3
		"0011001" when Conv_in = "0100" else -- 4
		"0010010" when Conv_in = "0101" else -- 5
		"0000010" when Conv_in = "0110" else -- 6
		"1111000" when Conv_in = "0111" else -- 7
		"0000000" when Conv_in = "1000" else -- 8
		"0010000" when Conv_in = "1001" else -- 9
		"1000000" when Conv_in = "0000" else -- 0
		"1111111";
end architecture aBcd2seg7; 
