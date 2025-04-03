library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.micore_types.all;

entity test_micore is
end test_micore;

architecture tb of test_micore is
	component micore
	port(
		-- system signals
		clk: in bit_1;
		rst_l: in bit_1;
		-- external data bus signals
		din: in bit_16;
		dout: out bit_16;
		-- external data address bus signals
		addr: out bit_16;
		-- memory control signals
		wr: out bit_1;
		-- exteral program memory signals
		pdin: in bit_32;
		paddr: out bit_16;
		pm_sel: in bit_1;
		-- signal input & output
		sir: in bit_16;
		sor: out bit_16
		);
	end component;
	
	signal clk, rst_l: bit_1;
	signal wr: bit_1;
	signal din, dout: bit_16;
	signal addr: bit_16;
	signal pdin: bit_32;
	signal paddr: bit_16;
	signal pm_sel: bit_1;
	signal sir, sor: bit_16;

begin
	F1: micore port map (clk, rst_l, din, dout, 
				addr, wr, pdin, paddr, pm_sel,
				sir, sor);
	
	pm_sel <= '0';
	
	clkgen: process
	begin
		clk <= '0';
		wait for 15 ns;
		clk <= '1';
		wait for 15 ns;
	end process;
	
	rstgen: process
	begin
		rst_l <= '0';
		wait for 120 ns;
		rst_l <= '1';
		wait;
	end process;

	process
	begin
		sir <= "0000000000000000";
		wait for 100 ns;
		sir <= "0111111111111111";
		wait;
	end process;

end tb;
    