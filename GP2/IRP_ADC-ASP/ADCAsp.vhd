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
    signal adc_sample_delay : unsigned(7 downto 0) := "00000010";
    signal sendSignal       : tdma_min_port;
begin 
    clock_process: process(clock)
        variable adc_sample_delay_counter   : integer range 0 to 255 := 0;
        variable adc_rdy                    : std_logic := '0';
    begin
        if rising_edge(clock) then
            if (recv.data(31 downto 28) = "1001" and recv.data(23) = '0') then      -- ADC Config
                adc_sample_delay <= unsigned(recv.data(7 downto 0));                    -- ADC Sampling Delay/Period
            end if;

            if adc_sample_delay_counter >= to_integer(adc_sample_delay) then -- Delay has Expired, Read ADC
                adc_sample_delay_counter := 0;
                sendSignal.addr <= "00000010";              -- To LAFAsp
                sendSignal.data <= (others => '0');         -- Clear
                sendSignal.data(31 downto 28) <= "1000";    -- Data Packet
                sendSignal.data(23 downto 20) <= "0001";    -- MODE
                sendSignal.data(8) <= '1';                  -- ADC Ready
                sendSignal.data(7 downto 0) <= adc;         -- ADC Data
            else
                sendSignal.data <= (others => '0');         -- Clear
            end if;
            -- Maybe we need a flag on this so we don't assume that the ADC is readable every clock cycle
            adc_sample_delay_counter := adc_sample_delay_counter + 1;
        end if;
    end process clock_process;

    send <= sendSignal;
end architecture aADCAsp;