library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.TdmaMinTypes.all;

entity PdAsp is
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

	signal peak_type 				: std_logic := '1';
	signal send_half        		: std_logic := '0';
	signal peak_detect_sent 		: std_logic := '0';
	signal correlation_peak_read 	: std_logic := '0';

    signal sendSignal : tdma_min_port := (others => (others => '0'));
begin
    process(clock)
		variable last_correlation_value 		: std_logic_vector(35 downto 0) := (others => '0');
		variable current_correlation_value 		: std_logic_vector(35 downto 0) := (others => '0');
		variable incomplete_correlation_value 	: std_logic_vector(35 downto 0) := (others => '0');
		variable curr_slope_pos 				: std_logic := '0';
		
		variable correlation_rdy 				: std_logic := '0';
    	variable correlation_count_read 		: std_logic := '0';
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
					correlation_peak_read  <= recv.data(1);											-- Set Correlation Peak Read
					correlation_count_read := recv.data(0);											-- Set Correlation Count Read
				end if;
			end if;


			if (correlation_rdy = '1') then
				curr_slope_pos := last_slope_pos;
				correlation_rdy := '0';
				if (last_slope_pos = '1') then																-- Last Slope was Positive
					if (unsigned(current_correlation_value) > unsigned(last_correlation_value)) then				-- Still Positive Slope
						counter <= counter + 1;																		-- Increment Counter
					else
						if (unsigned(last_correlation_value) > unsigned(correlation_max)) then
							correlation_max <= last_correlation_value;
						end if;
						curr_slope_pos := '0';
						peak_detected <= '1';
						counter_prev <= counter;
						counter <= (others => '0');
					end if;
				else																						-- Last Slope was Negative
					if (unsigned(current_correlation_value) >= unsigned(last_correlation_value)) then				-- Slope Changed to Positive
						if (unsigned(last_correlation_value) < unsigned(correlation_min)) then
							correlation_min <= last_correlation_value;
						end if;
						curr_slope_pos := '1';
					else
						counter <= counter + 1;
					end if;
				end if;

				last_slope_pos <= curr_slope_pos;
        	end if;



			if (correlation_peak_read = '1' and peak_detect_sent = '1') then									-- Correlation Peak Read
				sendSignal.addr <= "00000111"; 												-- To Nios
				sendSignal.data <= (others => '0'); 										-- Clear Data
				sendSignal.data(31 downto 28) <= "1000"; 									-- Data Packet
				sendSignal.data(23 downto 20) <= "1000"; 									-- MODE

				if (send_half = '0') then													-- Send First Half of Correlation Value
					send_half <= '1';															-- Set Send Half
					sendSignal.data(18) <= '0';													-- First Half
					if (peak_type = '0') then
						sendSignal.data(17 downto 0) <= correlation_min(35 downto 18); 	-- Send First Half of Min Correlation Value
					else
						sendSignal.data(17 downto 0) <= correlation_max(35 downto 18); 	-- Send First Half of Nax Correlation Value
					end if;
				else																		-- Send Second Half of Correlation Value
					send_half <= '0';															-- Reset Send Half
					sendSignal.data(18) <= '1';													-- Second Half
					if (peak_type = '0') then
						sendSignal.data(17 downto 0) <= correlation_min(17 downto 0); 	-- Send Second Half of Min Correlation Value
					else
						sendSignal.data(17 downto 0) <= correlation_max(17 downto 0); 	-- Send Second Half of Nax Correlation Value
					end if;							
					peak_detect_sent <= '0';												-- Reset Peak Detect Sent Flag
					correlation_peak_read <= '0';									-- Reset Correlation Peak Read Flag
				end if;
			elsif (peak_detected = '1') then												-- Peak Detected
				sendSignal.addr <= "00000111"; 												-- To Nios
				sendSignal.data <= (others => '0'); 										-- Clear Data
				sendSignal.data(31 downto 28) <= "1000"; 									-- Data Packet
				sendSignal.data(23 downto 20) <= "0111"; 									-- MODE
				sendSignal.data(18) <= '1';													-- Peak Detected
				sendSignal.data(17 downto 0) <= std_logic_vector(counter_prev); 			-- Send Counter Value
				peak_detect_sent <= '1';														-- Set Peak Detect Sent Flag
				peak_detected <= '0';														-- Reset Peak Detected Flag
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