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
    signal last_slope_pos 			: std_logic := '0';

	-- Flags and Counters
    signal peak_detected 	: std_logic := '0';
    signal counter 			: unsigned(17 downto 0) := (others => '0');
	signal counter_prev 	: unsigned(17 downto 0) := (others => '0');

	signal correlation_min 	: std_logic_vector(35 downto 0) := (others => '0');
	signal correlation_max 	: std_logic_vector(35 downto 0) := (others => '0');
	signal previous_maximum : std_logic_vector(35 downto 0) := (others => '0');

	signal peak_type 		: std_logic := '0';

    signal sendSignal : tdma_min_port := (others => (others => '0'));
begin
    process(clock)
		variable last_correlation_value 		: std_logic_vector(35 downto 0) := (others => '0');
		variable current_correlation_value 		: std_logic_vector(35 downto 0) := (others => '0');
		variable incomplete_correlation_value 	: std_logic_vector(35 downto 0) := (others => '0');
		variable curr_slope_pos 				: std_logic := '0';
		
		variable correlation_rdy 				: std_logic := '0';
		variable correlation_peak_read 			: std_logic := '0';
    	variable correlation_count_read 		: std_logic := '0';

		variable send_half 						: std_logic := '0';
    begin
        if rising_edge(clock) then
			if (recv.data(31 downto 28) = "1011") then										-- Peak Detector COnfig
				peak_type <= recv.data(0); 														-- Peak Type
			elsif (recv.data(31 downto 28) = "1000") then 									-- Data Packet
				if (recv.data(23 downto 20) = "0101") then 										-- Correlation Value Packet
					if (recv.data(18) = '0') then													-- Is First Half / Is Correlation Not Ready
						incomplete_correlation_value(35 downto 18) := recv.data(17 downto 0);			-- First Half
					else																			-- Is Second Half / Is Correlation Ready
						incomplete_correlation_value(17 downto 0) := recv.data(17 downto 0);			-- Second Half, Correlation Ready
						correlation_rdy := '1';															-- Set Correlation Ready
						last_correlation_value := current_correlation_value;							-- Update Last Correlation Value
						current_correlation_value := incomplete_correlation_value;						-- Update Current Correlation Value
					end if;
				elsif (recv.data(23 downto 20) = "0110") then 									-- Correlation Count Read Packet
					correlation_peak_read  := recv.data(1);											-- Set Correlation Peak Read
					correlation_count_read := recv.data(0);											-- Set Correlation Count Read
				end if;
			end if;


			if (correlation_rdy = '1') then
				curr_slope_pos := last_slope_pos;
				correlation_rdy := '0';
				if (last_slope_pos = '1') then																-- Last Slope was Positive
					if (signed(current_correlation_value) >= signed(last_correlation_value)) then				-- Still Positive Slope
						counter <= counter + 1;																		-- Increment Counter
					elsif (signed(current_correlation_value) < signed(last_correlation_value)) and 				
						((unsigned(previous_maximum) = 0) or 
						(abs(signed(last_correlation_value) - signed(previous_maximum)) <= DIFFERENCE)) then	-- Slope Changed to Negative
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
				else																						-- Last Slope was Negative
					counter <= counter + 1;
					if (signed(current_correlation_value) > signed(last_correlation_value)) and
					(signed(correlation_min) - signed(last_correlation_value)) >= DIFFERENCE then			-- Slope Changed to Positive
						correlation_min <= last_correlation_value;
						curr_slope_pos := '1';
					elsif (signed(current_correlation_value) > signed(last_correlation_value)) then
						curr_slope_pos := '1';
					end if;
				end if;

				last_slope_pos <= curr_slope_pos;
        	end if;


			if (peak_detected = '1') then												-- Peak Detected
				sendSignal.addr <= "00000111"; 												-- To Nios
				sendSignal.data <= (others => '0'); 										-- Clear Data
				sendSignal.data(31 downto 28) <= "1000"; 									-- Data Packet
				sendSignal.data(23 downto 20) <= "0111"; 									-- MODE
				sendSignal.data(18) <= '1';													-- Peak Detected
				sendSignal.data(17 downto 0) <= std_logic_vector(counter_prev); 			-- Send Counter Value

				peak_detected <= '0';														-- Reset Peak Detected Flag
			elsif (correlation_peak_read = '1') then									-- Correlation Peak Read
				sendSignal.addr <= "00000111"; 												-- To Nios
				sendSignal.data <= (others => '0'); 										-- Clear Data
				sendSignal.data(31 downto 28) <= "1000"; 									-- Data Packet
				sendSignal.data(23 downto 20) <= "1000"; 									-- MODE

				if (send_half = '0') then													-- Send First Half of Correlation Value
					send_half := '1';															-- Set Send Half
					sendSignal.data(18) <= '0';													-- First Half
					sendSignal.data(17 downto 0) <= current_correlation_value(35 downto 18); 	-- Send First Half of Correlation Value
				else																		-- Send Second Half of Correlation Value
					send_half := '0';															-- Reset Send Half
					sendSignal.data(18) <= '1';													-- Second Half
					sendSignal.data(17 downto 0) <= current_correlation_value(17 downto 0); 	-- Send Second Half of Correlation Value
				end if;

				correlation_peak_read := '0';											-- Reset Correlation Peak Read Flag
			else
				sendSignal.addr <= (others => '0'); 										-- Clear
				sendSignal.data <= (others => '0'); 										-- Clear
			end if;
		end if;
    end process;

    send <= sendSignal;
end architecture;

-- :(
-- :O