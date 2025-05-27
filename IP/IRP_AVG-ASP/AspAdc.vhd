library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.TdmaMinTypes.all;
use work.signal_rom_pkg.all;

entity AspAdc is
	generic (
		SEND_TO : std_logic_vector(3 downto 0) := "0001";		-- Avg(in)
		SAMPLING_DELAY : natural := 9			-- 10 MHz
	);
	port (
		clock : in  std_logic;
		recv  : in  tdma_min_port;
		send  : out tdma_min_port
	);
end entity;

architecture rtl of AspAdc is

	signal rom_index : integer range 1 to ROM_DEPTH := 1;
	signal counter   : natural range 0 to SAMPLING_DELAY := 0;
	signal adc_data  : std_logic_vector(7 downto 0);
	signal data_rdy  : std_logic := '0';
   
begin

	process(clock)
	begin
		if rising_edge(clock) then
			send.addr <= (others => '0');
			send.data <= (others => '0');
			
			if counter = 0 then 
				-- Request new sample 
				adc_data <= SIGNAL_ROM(rom_index);
				data_rdy <= '1';
				
				-- Format and send packet
				send.addr <= "0000" & SEND_TO;
				send.data <=
					"0000" &
					SEND_TO &
					(23 downto 9 => '0') &
					'1' &
					adc_data;
					
				-- Increment ROM index
				if rom_index = ROM_DEPTH then 
					rom_index <= 1;
				else 
					rom_index <= rom_index + 1;
				end if;
				
				counter <= SAMPLING_DELAY;
				
			else 
				data_rdy <= '0';
				counter <= counter - 1;
			end if;
		end if;
	end process;

end architecture;
