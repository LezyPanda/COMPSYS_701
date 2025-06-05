library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.signal_rom_pkg.all;

library work;
use work.TdmaMinTypes.all;

entity TopLevel is
	generic (
		ports : positive := 7
	);
	port (
		clock_50      : in    std_logic;
		key           : in    std_logic_vector(3 downto 0);
		sw            : in    std_logic_vector(9 downto 0);
		ledr          : out   std_logic_vector(9 downto 0);
		hex0          : out   std_logic_vector(6 downto 0);
		hex1          : out   std_logic_vector(6 downto 0);
		hex2          : out   std_logic_vector(6 downto 0);
		hex3          : out   std_logic_vector(6 downto 0);
		hex4          : out   std_logic_vector(6 downto 0);
		hex5          : out   std_logic_vector(6 downto 0);
		DRAM_DQ       : inout std_logic_vector(15 downto 0);
		DRAM_ADDR     : out   std_logic_vector(12 downto 0);
		DRAM_BA       : out   std_logic_vector(1 downto 0);
		DRAM_CAS_N, DRAM_RAS_N, DRAM_CLK : out std_logic;
		DRAM_CKE, DRAM_CS_N, DRAM_WE_N    : out std_logic;
		DRAM_UDQM, DRAM_LDQM              : out std_logic
	);
end entity;

architecture rtl of TopLevel is
	signal clock : std_logic;
	signal send_port : tdma_min_ports(0 to ports - 1);
	signal recv_port : tdma_min_ports(0 to ports - 1);
	signal recop_ledr : std_logic_vector(9 downto 0) := (others => '0');
	signal signal_gen_addr : integer range 0 to ROM_DEPTH - 1 := 0;

	signal adc_data : std_logic_vector(7 downto 0) := (others => '0');
begin

	clock <= clock_50;

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
        key    => key,
        sw     => sw,
        ledr   => recop_ledr,
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

	-- Nios System 2A instantiation
	Nios_Sys_2A_inst : entity work.Nios_Sys_2A
	port map (
	    CLOCK_50 => clock,
	    KEY      => key(1 downto 0),
	    HEX5     => hex5,
	    HEX4     => hex4,
	    HEX1     => hex1,
	    HEX0     => hex0,
	    DRAM_DQ  => DRAM_DQ,
	    DRAM_ADDR=> DRAM_ADDR,
	    DRAM_BA  => DRAM_BA,
	    DRAM_CAS_N=> DRAM_CAS_N,
	    DRAM_RAS_N=> DRAM_RAS_N,
	    DRAM_CLK => DRAM_CLK,
	    DRAM_CKE => DRAM_CKE,
	    DRAM_CS_N=> DRAM_CS_N,
	    DRAM_WE_N=> DRAM_WE_N,
	    DRAM_UDQM=> DRAM_UDQM,
	    DRAM_LDQM=> DRAM_LDQM
	);

	process(clock)
        variable counter : integer := 0;
	begin
		if (rising_edge(clock)) then
            if (send_port(1).data(8) = '1') then -- ADC has sent the data
                counter := counter + 1;
                signal_gen_addr <= counter mod ROM_DEPTH;
            end if;
		end if;
	end process;
	-- drive LEDR only from TDMA ports, avoid conflict with recops
	LEDR(7 downto 0) <= recv_port(1).addr;
	LEDR(8) <= recv_port(1).data(0);
	LEDR(9) <= send_port(1).data(0);
end architecture;
