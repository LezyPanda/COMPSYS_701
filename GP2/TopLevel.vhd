library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.signal_rom_pkg.all;

library work;
use work.TdmaMinTypes.all;

entity TopLevel is
	generic (
		ports : positive := 6
	);
	port (
		CLOCK_50      : in    std_logic;
		CLOCK2_50     : in    std_logic;
		CLOCK3_50     : in    std_logic;

		KEY           : in    std_logic_vector(3 downto 0);
		SW            : in    std_logic_vector(9 downto 0);
		LEDR          : out   std_logic_vector(9 downto 0);
		HEX0          : out   std_logic_vector(6 downto 0);
		HEX1          : out   std_logic_vector(6 downto 0);
		HEX2          : out   std_logic_vector(6 downto 0);
		HEX3          : out   std_logic_vector(6 downto 0);
		HEX4          : out   std_logic_vector(6 downto 0);
		HEX5          : out   std_logic_vector(6 downto 0)
	);
end entity;

architecture rtl of TopLevel is
	signal clock : std_logic;
	signal send_port : tdma_min_ports(0 to ports-1);
	signal recv_port : tdma_min_ports(0 to ports-1);
	signal recop_ledr : std_logic_vector(9 downto 0);  -- isolate recops LEDR output
	signal adc_empty : std_logic := '1';
	signal adc_get : std_logic := '0';
	signal adc_data : std_logic_vector(31 downto 0) := (others => '0'); 
	signal signal_addr : integer range 0 to ROM_DEPTH-1;


begin

	clock <= CLOCK_50;

	tdma_min : entity work.TdmaMin
	generic map (
		ports => ports
	)
	port map (
		clock => clock,
		sends => send_port,
		recvs => recv_port

	--	adc_empty     => adc_empty,
	--	adc_get       => adc_get,
	--	adc_data      => adc_data,
	);

	asp_pd : entity work.PdAsp
	port map (
		clock => clock,
		send  => send_port(1),
		recv  => recv_port(1)
	);
	
	
	asp_cor : entity work.CorAsp
	port map (
		clock => clock,
		send  => send_port(2),
		recv  => recv_port(2)
	);
	
	recop : entity work.recop
	port map (

		clock  => clock,
        key    => KEY,
        sw     => SW,
        ledr   => recop_ledr,  -- use internal signal
        hex0   => HEX0,
        hex1   => HEX1,
        hex2   => HEX2,
        hex3   => HEX3,
        hex4   => HEX4,
        hex5   => HEX5,
			send  => send_port(4),
			recv  => recv_port(4)
		
	);

	SG : entity work.play_signal
	port map (
		clk   => clock,
		addr  => signal_addr,
		send  => send_port(5),
		recv  => recv_port(5)
	);
	
	
   -- drive LEDR only from TDMA ports, avoid conflict with recops
   LEDR(7 downto 0) <= recv_port(1).addr;
   LEDR(8) <= recv_port(1).data(0);
   LEDR(9) <= send_port(1).data(0);

end architecture;
