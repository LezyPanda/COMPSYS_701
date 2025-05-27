library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.TdmaMinTypes.all;
use work.signal_rom_pkg.all;

entity tb_chain is
end entity;

architecture sim of tb_chain is
    signal clock : std_logic := '0';
	 
	 signal dummy_recv : tdma_min_port := (
	 addr => (others => '0'),  
	 data => (others => '0')
	 );

    signal adc2avg : tdma_min_port;
    signal avg2dummy : tdma_min_port; 

begin
    -- Clock generation
    clock <= not clock after 5 ns; -- 100 MHz

    process
    begin
        wait for 20 ns;
    end process;

    -- Instantiate AspAdc
    u_adc: entity work.AspAdc
        port map (
            clock => clock,
            recv  => dummy_recv, -- Not used
            send  => adc2avg
        );

    -- Instantiate AspAvg
    u_avg: entity work.AspAvg
        port map (
            clock => clock,
            recv  => adc2avg,
            send  => avg2dummy
        );

end architecture;