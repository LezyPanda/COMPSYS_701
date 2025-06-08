library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.TdmaMinTypes.all;

entity ADCAsp is
	port (
		clock : in  std_logic;
        adc   : in  std_logic_vector(9 downto 0);
		recv  : in  tdma_min_port;
		send  : out tdma_min_port
	);
end entity;

architecture aADCAsp of ADCAsp is
    signal adc_sample_delay : integer range 0 to 255 := 16;
    signal sendSignal       : tdma_min_port;
begin 
    clock_process: process(clock)
        variable adc_sample_delay_counter : integer range 0 to 65535 := 0;
    begin
        if rising_edge(clock) then
            if (recv.data(31 downto 28) = "1001" and recv.data(23) = '0') then      -- ADC Config
                case recv.data(2 downto 0) is                                           -- ADC Sampling Delay/Period from packet
                    when "000" => adc_sample_delay <= 1;
                    when "001" => adc_sample_delay <= 2;
                    when "010" => adc_sample_delay <= 4;
                    when "011" => adc_sample_delay <= 8;
                    when "100" => adc_sample_delay <= 16;
                    when "101" => adc_sample_delay <= 32;
                    when "110" => adc_sample_delay <= 64;
                    when "111" => adc_sample_delay <= 128;
                    when others => adc_sample_delay <= 255;
                end case;
            end if;
            if adc_sample_delay_counter >= adc_sample_delay then -- Delay has Expired, Read ADC
                adc_sample_delay_counter := 0;

                sendSignal.addr <= "00000010";              -- To LAFAsp
                sendSignal.data <= (others => '0');         -- Clear
                sendSignal.data(31 downto 28) <= "1000";    -- Data Packet
                sendSignal.data(23 downto 20) <= "0001";    -- MODE
                sendSignal.data(10) <= '1';                  -- ADC Ready
                sendsignal.data(11) <= '0';                  -- 8 bit
                sendSignal.data(9 downto 0) <= adc;         -- ADC Data
                
            else
                sendSignal.addr <= (others => '0');         -- Clear
                sendSignal.data <= (others => '0');         -- Clear
            end if;

            adc_sample_delay_counter := adc_sample_delay_counter + 1;
        end if;
    end process clock_process;

    send <= sendSignal;
end architecture aADCAsp;