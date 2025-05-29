library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.TdmaMinTypes.all;

entity PdAsp is
	generic (
		DIFFERENCE : integer := 5000
	);
	port (
		clock : in  std_logic;
		recv  : in  tdma_min_port;
		send  : out tdma_min_port
	);
end entity;

architecture aPdASP of PdAsp is
    -- Prev State
	signal last_correlation_value 	: std_logic_vector(39 downto 0);
    signal last_slope_pos 			: std_logic := '0';

	-- Flags and Counters
    signal peak_detected 	: std_logic := '0';
    signal counter 			: unsigned(19 downto 0) := (others => '0');
	signal counter_prev 	: unsigned(19 downto 0) := (others => '0');

	signal correlation_min : std_logic_vector(39 downto 0) := (others => '0');
	signal correlation_max : std_logic_vector(39 downto 0) := (others => '0');
	signal previous_maximum : std_logic_vector(39 downto 0) := (others => '0');

	signal peak_type : std_logic_vector(1 downto 0) := "00"; -- 0 None, 1 Min, 2 Max
	signal peak_half : std_logic := '0'; -- Used to track if we are sending the first or second half of a peak

    -- output signals
    signal sendSignal : tdma_min_port := (
		addr => (others => '0'),
		data => (others => '0')
	);
    
begin
    process(clock)
		variable current_correlation_value 	: std_logic_vector(39 downto 0);
		variable curr_slope_pos 			: std_logic := '0';
		
		-- input from corAsp
		variable correlation_rdy 			: std_logic := '0';
		-- input from nios 
    	variable correlation_count_read 	: std_logic := '0';
    begin
        if rising_edge(clock) then
			curr_slope_pos := last_slope_pos;

			if (recv.data(31 downto 28) = "1010") then
				if (peak_type = "00") then
					peak_half <= '0';
					peak_type <= recv.data(23 downto 22);
				end if;
				correlation_rdy 			:= recv.data(20);
				correlation_count_read 		:= recv.data(21);
				if (correlation_rdy = '1') then
					current_correlation_value(39 downto 20) := recv.data(19 downto 0);
				end if;
			elsif (recv.data(31 downto 28) = "1011") then
				if (peak_type = "00") then
					peak_half <= '0';
					peak_type <= recv.data(23 downto 22);
				end if;
				correlation_rdy 			:= recv.data(20);
				correlation_count_read 		:= recv.data(21);
				if (correlation_rdy = '1') then
					current_correlation_value(19 downto 0) := recv.data(19 downto 0);
				end if;
			else
				correlation_rdy 			:= '0';
				correlation_count_read 		:= '0';
			end if;			-- Positive Slope
			if (last_slope_pos = '1') then
				if (signed(current_correlation_value) >= signed(last_correlation_value)) then
					counter <= counter + 1;
				elsif (signed(current_correlation_value) < signed(last_correlation_value)) and 
					  ((unsigned(previous_maximum) = 0) or 
					   (abs(signed(last_correlation_value) - signed(previous_maximum)) <= DIFFERENCE)) then
					correlation_max <= last_correlation_value;
					previous_maximum <= last_correlation_value;  
					curr_slope_pos := '0';
					peak_detected <= '1';
					counter_prev <= counter;
					counter <= (others => '0');
				else
					curr_slope_pos := '0';
					counter <= counter + 1;
				end if;
			-- Negative Slope
			else
				counter <= counter + 1;
				if (signed(current_correlation_value) > signed(last_correlation_value)) and
				   (signed(correlation_min) - signed(last_correlation_value)) >= DIFFERENCE then
					correlation_min <= last_correlation_value;
					curr_slope_pos := '1';
				elsif (signed(current_correlation_value) > signed(last_correlation_value)) then
					curr_slope_pos := '1';
				end if;
			end if;

            last_correlation_value <= current_correlation_value;
            last_slope_pos <= curr_slope_pos;


			if (correlation_count_read = '1') then
				peak_detected <= '0';
				counter_prev <= (others => '0');
			end if;

			sendSignal.data <= (others => '0');
			if (peak_type = "00") then
				sendSignal.data(31 downto 28) <= "1100";
				sendSignal.data(20) <= peak_detected;
				sendSignal.data(19 downto 0) <= std_logic_vector(counter_prev);
			elsif (peak_type = "01") then
				sendSignal.data(20) <= '0';
				if (peak_half = '0') then
					sendSignal.data(31 downto 28) <= "1101";
					sendSignal.data(19 downto 0) <= correlation_min(39 downto 20);
					peak_half <= '1';
				else
					sendSignal.data(31 downto 28) <= "1110";
					sendSignal.data(19 downto 0) <= correlation_min(19 downto 0);
					peak_half <= '0';
					peak_type <= "00";
				end if;
			elsif (peak_type = "10") then
				sendSignal.data(20) <= '1';
				if (peak_half = '0') then
					sendSignal.data(31 downto 28) <= "1101";
					sendSignal.data(19 downto 0) <= correlation_max(39 downto 20);
					peak_half <= '1';
				else
					sendSignal.data(31 downto 28) <= "1110";
					sendSignal.data(19 downto 0) <= correlation_max(19 downto 0);
					peak_half <= '0';
					peak_type <= "00";
				end if;
			end if;
        end if;



    end process;

    send <= sendSignal;
end architecture;

-- :(
-- :O