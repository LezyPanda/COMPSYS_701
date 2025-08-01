library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.TdmaMinTypes.all;

entity CorAsp is
	port (
		clock : in  std_logic;
		recv  : in  tdma_min_port;
		send  : out tdma_min_port
	);
end entity;

architecture rtl of CorAsp is
    type states is (S0, S1, S2, S3);
    signal state                    : states := S0;
    signal correlation_window_size  : integer range 0 to 15 := 4;
    signal counter                  : unsigned(15 downto 0) := (others => '0');

    signal calculate                    : std_logic := '0';
    signal newest_avg_data_addr_signal  : std_logic_vector(9 downto 0) := (others => '0');

    signal current_corr_origin          : std_logic_vector(9 downto 0) := (others => '0');
    signal correlation_pair_product     : std_logic_vector(31 downto 0) := (others => '0');
    signal multiplicand_temp            : std_logic_vector(15 downto 0) := (others => '0');
    signal avg_data_signal              : std_logic_vector(15 downto 0) := (others => '0');
    signal correlation_first_half       : std_logic := '0';
    signal correlation_second_half      : std_logic := '0';

    signal correlation                  : std_logic_vector(35 downto 0) := (others => '0');
    signal avg_data_mem_addr_signal     : std_logic_vector(9 downto 0) := (others => '0');

    signal sendSignal : tdma_min_port;

begin 

    process(clock)
        variable avg_data               : std_logic_vector(15 downto 0) := (others => '0');
        -- output signals
        variable avg_data_mem_addr      : std_logic_vector(9 downto 0) := (others => '0');
        variable newest_avg_data_addr   : std_logic_vector(9 downto 0) := (others => '0');
        variable correlation_rdy        : std_logic := '0';
        variable send_avg_data_rq       : std_logic := '0';
        variable has_send_avg_data_rq   : std_logic := '0';
        variable just_recv_avg_data     : std_logic := '0';
    begin
        if rising_edge(clock) then
            if (recv.data(31 downto 28) = "1010") then                                  -- Correlation Calculator Config
                case recv.data(2 downto 0) is                                               -- Correlation WIndow Size
                    when "000" => correlation_window_size <= 1;
                    when "001" => correlation_window_size <= 2;
                    when "010" => correlation_window_size <= 4;
                    when "011" => correlation_window_size <= 8;
                    when others => correlation_window_size <= 15;
                end case;          
            elsif (recv.data(31 downto 28) = "1000") then                               -- Data Packet
                if (recv.data(23 downto 20) = "0011") then                                  -- AVG Data Packet
                    if (recv.data(16) = '1') then
                        calculate <= recv.data(16);                                         -- Enough ADC Samples, Calculate Correlation
                    end if;
                    avg_data := recv.data(15 downto 0);                                     -- Average Data
                    just_recv_avg_data := '1';                                              -- Flag to indicate that we just received average data
                elsif (recv.data(23 downto 20) = "0100") then                           -- AVG New Data Address Packet
                    newest_avg_data_addr := recv.data(9 downto 0);                          -- Newest Average Data Address
                end if;
            end if;

            -- Our state machine advances every clock cycle, maybe we need to use flags instead
            case state is
                when S0 =>
                    if (just_recv_avg_data = '0') then                              -- If we have not just received average data requested
                        if (has_send_avg_data_rq = '0') then                           -- If we have not just sent average data request
                            avg_data_mem_addr := std_logic_vector(unsigned(newest_avg_data_addr) - to_unsigned(correlation_window_size / 2 - 1, avg_data_mem_addr'length));
                            send_avg_data_rq := '1';
                        end if;
                    else                                                            -- We received average data requested
                        just_recv_avg_data := '0';  
                        has_send_avg_data_rq := '0';
                        correlation_rdy := '0';
                        correlation_pair_product <= (others => '0');
                        counter <= (others => '0');
                        multiplicand_temp <= (others => '0');
                        if calculate = '1' then
                            calculate <= '0';
                            correlation <= (others => '0');
                            multiplicand_temp <= avg_data;
                            current_corr_origin <= avg_data_mem_addr;
                            state <= S1;
                        end if;
                    end if;
                when S1 =>
                    if (just_recv_avg_data = '0') then                              -- If we have not just received average data requested
                        if (has_send_avg_data_rq = '0') then                           -- If we have not just sent average data request
                            avg_data_mem_addr := std_logic_vector(unsigned(current_corr_origin) - to_unsigned(to_integer(counter), avg_data_mem_addr'length) - 1);
                            send_avg_data_rq := '1';
                        end if;
                    else                                                            -- We received average data requested
                        just_recv_avg_data := '0';
                        has_send_avg_data_rq := '0';
                        correlation_pair_product <= std_logic_vector(unsigned(multiplicand_temp) * unsigned(avg_data));
                        correlation_rdy := '0';
                        state <= S2;
                    end if;
                when S2 =>
                    counter <= counter + 1;
                    state <= S3;
                when S3 =>
                    if (just_recv_avg_data = '0') then                              -- If we have not just received average data requested
                        if (has_send_avg_data_rq = '0') then                           -- If we have not just sent average data request
                            avg_data_mem_addr := std_logic_vector(unsigned(current_corr_origin) + to_unsigned(to_integer(counter), avg_data_mem_addr'length));
                            send_avg_data_rq := '1';
                        end if;
                    else                           
                        just_recv_avg_data := '0';
                        has_send_avg_data_rq := '0';
                        correlation <= std_logic_vector(unsigned(correlation) + unsigned(correlation_pair_product));
                        correlation_pair_product <= (others => '0');
                        if to_integer(counter) >= correlation_window_size / 2 then
                            counter <= (others => '0');
                            correlation_rdy := '1';
                            state <= S0;
                            correlation_first_half <= '1';
                            correlation_second_half <= '1';
                        else
                            multiplicand_temp <= avg_data;
                            correlation_rdy := '0';
                            state <= S1;
                        end if;
                    end if;
            end case;

            
            if (correlation_first_half = '1') then                      -- Send First Half of Correlation
                sendSignal.addr <= "00000100";                              -- To PdAsp
                sendSignal.data <= (others => '0');                         -- Clear
                sendSignal.data(31 downto 28) <= "1000";                    -- Data Packet
                sendSignal.data(23 downto 20) <= "0101";                    -- MODE
                sendSignal.data(18) <= '0';                                 -- Indicates First Half of Correlation (Correlation Not Ready)
                sendSignal.data(17 downto 0) <= correlation(35 downto 18);  -- First Half of Correlation
                correlation_first_half <= '0';                              -- Reset First Half Flag
            elsif (correlation_second_half = '1') then                  -- Send Second Half of Correlation
                sendSignal.addr <= "00000100";                              -- To PdAsp
                sendSignal.data <= (others => '0');                         -- Clear
                sendSignal.data(31 downto 28) <= "1000";                    -- Data Packet
                sendSignal.data(23 downto 20) <= "0101";                    -- MODE
                sendSignal.data(18) <= '1';                                 -- Indicates Second Half of Correlation (Correlation Ready)
                sendSignal.data(17 downto 0) <= correlation(17 downto 0);   -- Second Half of Correlation
                correlation_second_half <= '0';                             -- Reset Second Half Flag
            elsif (send_avg_data_rq = '1' and has_send_avg_data_rq = '0') then -- Send Average Data Request
                sendSignal.addr <= "00000010";                              -- To AvgAsp
                sendSignal.data <= (others => '0');                         -- Clear
                sendSignal.data(31 downto 28) <= "1000";                    -- Data Packet
                sendSignal.data(23 downto 20) <= "0010";                    -- MODE
                sendSignal.data(9 downto 0) <= avg_data_mem_addr;           -- Average Data Memory Address
                send_avg_data_rq := '0';                                    -- Reset Flag
                has_send_avg_data_rq := '1';                                -- Sent Already
            else
                sendSignal.addr <= (others => '0');                         -- Clear
                sendSignal.data <= (others => '0');                         -- Clear
            end if;
        end if;
        avg_data_signal <= avg_data;
        avg_data_mem_addr_signal <= avg_data_mem_addr;
        newest_avg_data_addr_signal <= newest_avg_data_addr;
    end process;
    send <= sendSignal;
end architecture rtl;