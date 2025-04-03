library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.micore_types.all;

entity regfile is
	generic (wid: integer range 1 to 3 := 2);
	port (
		clk: in bit_1;
		ld_r: in bit_1;
		sel_z, sel_x, sel_y: integer range 0 to 2**(wid+1)-1;
		x, y: out bit_16;
		z: in bit_16
		);
end regfile;

architecture beh of regfile is
	type reg_array is array (2**(wid+1)-1 downto 0) of bit_16;
	signal regs: reg_array;
begin
	process (clk)
	begin
		if clk'event and clk = '1' then
			if ld_r = '1' then
				regs(sel_z) <= z;
			end if;
		end if;
	end process;
	
	x <= regs(sel_x);
	y <= regs(sel_y);
end beh;