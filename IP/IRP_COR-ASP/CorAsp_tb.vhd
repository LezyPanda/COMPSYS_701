library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.TdmaMinTypes.all;

entity CorAsp_tb is
end entity;

architecture tb of CorAsp_tb is
    signal t_clock : std_logic;
	signal t_recv  : tdma_min_port;
	signal t_send  : tdma_min_port;

	signal addr_origin 		: integer := 0;
	signal addr 		: integer := 0;

	-- Output from CorAsp
	signal correlation_rdy 	: std_logic := '0';
	signal correlation 	: std_logic_vector(39 downto 0) := (others => '0');

	signal avg_data_origin 		: std_logic_vector(15 downto 0) := (others => '0');
	signal avg_data 		: std_logic_vector(15 downto 0) := (others => '0');
	signal adc_addr 		: std_logic_vector(9 downto 0) := (others => '0');
	signal adc_addr_new 	: std_logic_vector(9 downto 0) := (others => '0');
begin 
	corAsp : entity work.CorAsp
		port map (
			clock => t_clock,
			recv  => t_recv,
			send  => t_send
		);
	
	sig_gen_origin : entity work.play_signal
		port map (
			clk   => t_clock,
			addr  => addr_origin,
			data  => avg_data_origin
		);

	sig_gen : entity work.play_signal
		port map (
			clk   => t_clock,
			addr  => addr,
			data  => avg_data
		);

	-- sig_gen_origin : entity work.test_signal
	-- 	port map (
	-- 		clk   => t_clock,
	-- 		addr  => addr_origin,
	-- 		data  => avg_data_origin
	-- 	);

	-- sig_gen : entity work.test_signal
	-- 	port map (
	-- 		clk   => t_clock,
	-- 		addr  => addr,
	-- 		data  => avg_data
	-- 	);

    clk_gen : process
	begin
		t_clock <= '0';
		wait for 10 ns;
		t_clock <= '1';
		wait for 10 ns;
    end process;

	recv_process : process(t_send)
		variable id : std_logic_vector(3 downto 0);
	begin
		id := t_send.data(31 downto 28);
		-- To RAM
		if (id = "0111") then
			adc_addr <= t_send.data(9 downto 0);
		-- To Peak Detector, first half
		elsif (id = "1000") then
			correlation_rdy <= t_send.data(18);
			correlation(39 downto 20) <= t_send.data(19 downto 0);
		-- To Peak Detector, second half
		elsif (id = "1001") then
			correlation_rdy <= t_send.data(18);
			correlation(19 downto 0) <= t_send.data(19 downto 0);
		end if;
	end process;

	
	clk_process : process(t_clock)
	begin
		if (rising_edge(t_clock)) then
			adc_addr_new <= std_logic_vector(unsigned(adc_addr_new) + 1);
		end if;
		addr_origin <= to_integer(unsigned(adc_addr_new));
	end process;
	
	t_recv.data <= "0110" & "0" & adc_addr_new & '1' & avg_data;
	addr <= to_integer(unsigned(adc_addr_new));

end architecture;