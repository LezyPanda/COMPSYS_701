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
    signal state        : states := S0;
    signal window_size  : unsigned(15 downto 0) := "0000000000000011";
    signal counter      : unsigned(15 downto 0) := (others => '0');

    signal calculate             : std_logic := '0';
    signal newest_avg_data_addr_signal  : std_logic_vector(9 downto 0) := (others => '0');

    signal current_corr_origin        : std_logic_vector(9 downto 0) := (others => '0');
    signal correlation_pair_product   : std_logic_vector(31 downto 0) := (others => '0');
    signal multiplicand_temp         : std_logic_vector(15 downto 0) := (others => '0');
    signal avg_data_signal : std_logic_vector(15 downto 0) := (others => '0');
    signal correlation_first_half : std_logic := '0';
    signal correlation_second_half : std_logic := '0';

    signal correlation : std_logic_vector(39 downto 0) := (others => '0');
    signal avg_data_mem_addr_signal : std_logic_vector(9 downto 0) := (others => '0');

    signal sendSignal : tdma_min_port;

begin 

    process(clock, recv)
        variable id : std_logic_vector(3 downto 0);
        variable avg_data : std_logic_vector(15 downto 0) := (others => '0');
        -- output signals
        variable avg_data_mem_addr : std_logic_vector(9 downto 0) := (others => '0');
        variable newest_avg_data_addr : std_logic_vector(9 downto 0) := (others => '0');
        variable correlation_rdy    : std_logic := '0';
        
    begin
        if rising_edge(clock) then
            id := recv.data(31 downto 28);
            if (id = "0110") then
                if (recv.data(27) = '1') then
                    window_size <= "0000000000000110"; -- 6
                else
                    window_size <= "0000000000000011"; -- 3
                end if;
                calculate <= recv.data(16);
                avg_data := recv.data(15 downto 0);
                newest_avg_data_addr := recv.data(26 downto 17);
            end if;

            case state is
                when S0 =>
                    avg_data_mem_addr := std_logic_vector(unsigned(newest_avg_data_addr) - to_unsigned((to_integer(window_size) / 2) - 1, avg_data_mem_addr'length));
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
                when S1 =>
                    avg_data_mem_addr := std_logic_vector(unsigned(current_corr_origin) - to_unsigned(to_integer(counter), avg_data_mem_addr'length) - 1);
                    correlation_pair_product <= std_logic_vector(unsigned(multiplicand_temp) * unsigned(avg_data));
                    correlation_rdy := '0';
                    state <= S2;
                when S2 =>
                    counter <= counter + 1;
                    state <= S3;
                when S3 =>
                    avg_data_mem_addr := std_logic_vector(unsigned(current_corr_origin) + to_unsigned(to_integer(counter), avg_data_mem_addr'length));
                    correlation <= std_logic_vector(unsigned(correlation) + unsigned(correlation_pair_product));
                    correlation_pair_product <= (others => '0');
                    if to_integer(counter) >= to_integer(window_size) / 2 then
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
                end case;
        end if;
        if (correlation_first_half = '1') then
            sendSignal.data <= (others => '0');
            sendSignal.data(31 downto 28) <= "1000";
            sendSignal.data(20) <= '0';
            sendSignal.data(19 downto 0) <= correlation(39 downto 20);
            correlation_first_half <= '0';
        elsif (correlation_second_half = '1') then
            sendSignal.data <= (others => '0');
            sendSignal.data(31 downto 28) <= "1001";
            sendSignal.data(20) <= '1';
            sendSignal.data(19 downto 0) <= correlation(19 downto 0);
            correlation_second_half <= '0';
        else
            sendSignal.data <= (others => '0');
            sendSignal.data(31 downto 28) <= "0111";
            sendSignal.data(9 downto 0) <= avg_data_mem_addr;
        end if;
        avg_data_signal <= avg_data;
        avg_data_mem_addr_signal <= avg_data_mem_addr;
        newest_avg_data_addr_signal <= newest_avg_data_addr;
    end process;
    send <= sendSignal;
end architecture rtl;