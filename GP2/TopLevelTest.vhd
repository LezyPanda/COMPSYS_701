library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.signal_rom_pkg.all;

library work;
use work.TdmaMinTypes.all;

entity TopLevelTest is
	generic (
		ports : positive := 7
	);
end entity;

architecture rtl of TopLevelTest is
	signal clock : std_logic;

	signal KEY           : std_logic_vector(3 downto 0) := (others => '0');
	signal SW            : std_logic_vector(9 downto 0) := (others => '0');
	signal LEDR          : std_logic_vector(9 downto 0) := (others => '0');
	signal HEX0          : std_logic_vector(6 downto 0) := (others => '0');
	signal HEX1          : std_logic_vector(6 downto 0) := (others => '0');
	signal HEX2          : std_logic_vector(6 downto 0) := (others => '0');
	signal HEX3          : std_logic_vector(6 downto 0) := (others => '0');
	signal HEX4          : std_logic_vector(6 downto 0) := (others => '0');
	signal HEX5          : std_logic_vector(6 downto 0) := (others => '0');

	signal send_port : tdma_min_ports(0 to ports - 1);
	signal recv_port : tdma_min_ports(0 to ports - 1);
	signal recop_ledr : std_logic_vector(9 downto 0) := (others => '0');
	signal signal_gen_addr : integer range 0 to ROM_DEPTH - 1 := 0;

	signal adc_data : std_logic_vector(7 downto 0) := (others => '0');
begin
	tdma_min : entity work.TdmaMin
	generic map (
		ports => ports
	)
	port map (
		clock => clock,
		sends => send_port,
		recvs => recv_port
	);
	
	asp_adc : entity work.ADCAsp
	port map (
		clock => clock,
		adc   => adc_data,
		send  => send_port(1),
		recv  => recv_port(1)
	);
	
	asp_laf : entity work.LAFAsp_RAM
	port map (
		clock => clock,
		send  => send_port(2),
		recv  => recv_port(2)
	);
	
	asp_cor : entity work.CorAsp
	port map (
		clock => clock,
		send  => send_port(3),
		recv  => recv_port(3)
	);

	asp_pd : entity work.PdAsp
	port map (
		clock => clock,
		send  => send_port(4),
		recv  => recv_port(4)
	);

	recop : entity work.recop
	port map (
		clock  => clock,
        key    => KEY,
        sw     => SW,
        ledr   => recop_ledr,
        hex0   => HEX0,
        hex1   => HEX1,
        hex2   => HEX2,
        hex3   => HEX3,
        hex4   => HEX4,
        hex5   => HEX5,
		send  => send_port(5),
		recv  => recv_port(5)
	);

	signal_gen : entity work.play_signal
	port map (
		clk   => clock,
		addr  => signal_gen_addr,
		send  => send_port(6),
		recv  => recv_port(6),
		data  => adc_data
	);
    
    clock_gen : process
	begin
		clock <= '0';
		wait for 10 ns;
		clock <= '1';
		wait for 10 ns;
    end process;

	process(clock)
        variable counter : integer := 0;
	begin
		if (rising_edge(clock)) then
            counter := counter + 1;
			signal_gen_addr <= counter mod ROM_DEPTH;
		end if;
	end process;

end architecture;
