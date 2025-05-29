library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.TdmaMinTypes.all;

entity ADCAspTest is
end entity;

architecture aADCAspTest of ADCAspTest is
    signal clock : std_logic;
    signal adc_gen   : std_logic_vector(7 downto 0) := (others => '0');

    signal adc_rdy : std_logic := '0';
    signal adc_data : std_logic_vector(7 downto 0) := (others => '0');

	signal recv  : tdma_min_port;
	signal send  : tdma_min_port;
begin 
	adcAsp : entity work.ADCAsp
		port map (
			clock => clock,
            adc   => adc_gen,
			recv  => recv,
			send  => send
		);

    clockGen : process
	begin
		clock <= '0';
		wait for 10 ns;
		clock <= '1';
		wait for 10 ns;
    end process;

	recv_process : process(send)
		variable id : std_logic_vector(3 downto 0);
	begin
		id := send.data(31 downto 28);
        if (id = "0110") then
            adc_rdy <= send.data(8);
            adc_data <= send.data(7 downto 0);
        end if;
	end process;


	clk_process : process(clock)
        variable counter : integer := 0;
	begin
		if (rising_edge(clock)) then
            counter := counter + 1;
            adc_gen <= std_logic_vector(to_unsigned(counter, 8));
            recv.data <= (others => '0');
            recv.data(31 downto 28) <= "1111";
            recv.data(7 downto 0) <= "00001111";
		end if;
	end process;



end architecture aADCAspTest;