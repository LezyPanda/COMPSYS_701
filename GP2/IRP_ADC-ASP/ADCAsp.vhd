library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.TdmaMinTypes.all;

entity ADCAsp is
	port (
		clock : in  std_logic;
        adc   : in  std_logic_vector(7 downto 0);
		recv  : in  tdma_min_port;
		send  : out tdma_min_port
	);
end entity;

architecture aADCAsp of ADCAsp is
    signal period : std_logic_vector(7 downto 0) := "00000010";
    

    signal sendSignal : tdma_min_port;
begin 
    clock_process: process(clock)
        variable counter : integer range 0 to 255 := 0;
        variable adc_data : std_logic_vector(7 downto 0);
        variable adc_rdy : std_logic := '0';
    begin
        if rising_edge(clock) then
            if (recv.data(31 downto 28) = "1111") then
                period <= recv.data(7 downto 0);
            end if;
            if counter >= to_integer(unsigned(period)) then
                counter := 0;
                adc_data := adc;
                adc_rdy := '1';
            else
                adc_rdy := '0';
            end if;
            sendSignal.addr <= "00000001"; -- To LdrASP
            sendSignal.data <= (others => '0');
            sendSignal.data(31 downto 28) <= "0110";
            sendSignal.data(8) <= adc_rdy;
            sendSignal.data(7 downto 0) <= adc_data;
            counter := counter + 1;
        end if;
    end process clock_process;

    send <= sendSignal;
end architecture aADCAsp;