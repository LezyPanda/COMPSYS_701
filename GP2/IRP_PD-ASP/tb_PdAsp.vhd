library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sine_filter_rom_pkg.all;
use work.TdmaMinTypes.all;

entity tb_PdAsp is
end entity;

architecture sim of tb_PdAsp is
	constant CLK_PERIOD : time := 10 ns;
	constant ROM_DEPTH  : integer := SINE_FILTER_ROM'length;

	signal wave          : std_logic_vector(39 downto 0);

	signal peak_detected : std_logic;
    signal corr_count : std_logic_vector(19 downto 0) := (others => '0');
    signal corr_min : std_logic_vector(39 downto 0) := (others => '0');
    signal corr_max : std_logic_vector(39 downto 0) := (others => '0');


	signal clk               : std_logic := '0';
	signal reset             : std_logic := '1';
	signal recv              : tdma_min_port := (
		addr => (others => '0'),
		data => (others => '0')
	);
	signal send              : tdma_min_port;
	signal rom_idx           : integer range 0 to ROM_DEPTH := 0;

	signal peak_type : std_logic_vector(1 downto 0) := "00"; -- 0 None, 1 Min, 2 Max
    signal last_peak_type : std_logic_vector(1 downto 0) := "01";
begin
	-- Instantiate PdAsp
	DUT: entity work.PdAsp
		port map(
			clock => clk,
			recv  => recv,
			send  => send
		);

	-- Clock generation
	clk_gen: process  
	begin
		clk <= '0';
		wait for CLK_PERIOD / 2;
		clk <= '1';
		wait for CLK_PERIOD / 2;

	end process;

	process (clk, send)
	begin
        if (rising_edge(clk)) then
            if (send.data(31 downto 28) = "1100") then
                peak_detected <= send.data(20);
                corr_count <= send.data(19 downto 0);
				
                if (send.data(20) = '1' and peak_type = "00") then
                    if (last_peak_type = "01") then
                        peak_type <= "10";
                        last_peak_type <= "10";
                    elsif (last_peak_type = "10") then
                        peak_type <= "01";
                        last_peak_type <= "01";
                    end if;
                end if;
            elsif (send.data(31 downto 28) = "1101") then
                peak_type <= "00";
                if (send.data(20) = '0') then
                    corr_min(39 downto 20) <= send.data(19 downto 0);
                else
                    corr_max(39 downto 20) <= send.data(19 downto 0);
                end if;
            elsif (send.data(31 downto 28) = "1110") then
                peak_type <= "00";
                if (send.data(20) = '0') then
                    corr_min(19 downto 0) <= send.data(19 downto 0);
                else
                    corr_max(19 downto 0) <= send.data(19 downto 0);
                end if;
            end if;
        end if;
	end process;
	
	-- Stimulus process
	stim: process
		variable temp : std_logic_vector(39 downto 0) := (others => '0');
	begin
		-- Release reset
		wait for 2 * CLK_PERIOD;
		reset <= '0';

		-- Feed data from SINE_FILTER_ROM
		for i in 0 to ROM_DEPTH - 1 loop
			recv.data <= (others => '0');
			recv.data(23 downto 22) <= peak_type;
			recv.data(21) <= peak_detected;
			recv.data(20) <= '1';
			temp := std_logic_vector(to_unsigned(to_integer(unsigned(SINE_FILTER_ROM(i))), 40));
			wave <= temp;
			recv.data(31 downto 28) <= "1010";
			recv.data(19 downto 0) <= temp(39 downto 20);
			wait for CLK_PERIOD;
			recv.data(31 downto 28) <= "1011";
			recv.data(19 downto 0) <= temp(19 downto 0);
			wait for CLK_PERIOD;
		end loop;

		-- End simulation
		wait;
	end process;
end architecture sim;