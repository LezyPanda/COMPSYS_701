library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.signal_rom_pkg.all;
use work.TdmaMinTypes.all;

-- get data from signal rom pkg
entity DirectSignal is
	port (
		clk   : in  std_logic;
		addr  : in  integer range 0 to ROM_DEPTH - 1;
		adc   : out std_logic_vector(7 downto 0);
	);
end entity;

architecture rtl of DirectSignal is
    signal adcSignal : std_logic_vector(7 downto 0) := (others => '0');
begin
  	process(clk)
  	begin
    	if rising_edge(clk) then
			adcSignal.data(7 downto 0) <= SIGNAL_ROM(addr);
    	end if;
  	end process;
    adc <= adcSignal;
end architecture;