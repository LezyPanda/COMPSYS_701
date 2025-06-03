library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.TdmaMinTypes.all;

entity LAFAsp is
    port (
        clock                   : in  std_logic;
        recv                    : in  tdma_min_port;   
        avg_data                : out std_logic_vector(15 downto 0);
        avg_ready               : out std_logic;
        corr_calculate          : out std_logic
    );
end entity; -- tdma future 3 bits needed to use io to change from 4 8 16 32 64

architecture rtl of LAFAsp is
    constant MAX_N          : natural := 64;  
    subtype sample_t is unsigned(7 downto 0);
    type buffer_t is array (0 to MAX_N - 1) of sample_t;

    signal correlation_sample_interval : unsigned(7 downto 0) := (others => '0');
    signal avg_window_size  : natural range 4 to MAX_N := MAX_N;

    signal buffer_reg       : buffer_t := (others => (others => '0'));
    signal sum_acc          : unsigned(15 downto 0) := (others => '0');
    signal ptr              : integer range 0 to MAX_N-1 := 0;
begin
    process(clock)
        variable oldest             : sample_t;
        variable new_s              : sample_t;
        variable desired_size       : integer range 4 to MAX_N := MAX_N;
        variable correlation_sample_interval_counter : integer range 0 to 255 := 0;
    begin
        if rising_edge(clock) then
            if (recv.data(31 downto 28) = "1001" and recv.data(23) = '1') then      -- LAFAsp Config
                correlation_sample_interval <= unsigned(recv.data(10 downto 3));        -- Correlation Sample Interval
                case recv.data(2 downto 0) is                                           -- Window Size Selection
                    when "000" => desired_size := 4;
                    when "001" => desired_size := 8;
                    when "010" => desired_size := 16;
                    when "011" => desired_size := 32;
                    when "100" => desired_size := 64;
                    when others => desired_size := MAX_N;
                end case;
                if desired_size > MAX_N then
                    avg_window_size <= MAX_N;
                else
                    avg_window_size <= desired_size;
                end if;
            elsif (recv.data(31 downto 28) = "1000" and recv.data(23 downto 20) = "0001" and recv.data(7 downto 0) /= "00000000") then -- LAFAsp ADC Data In Packet
                -- Moving Average Calculation
                new_s  := unsigned(recv.data(7 downto 0));
                oldest := buffer_reg(ptr);
                buffer_reg(ptr) <= new_s;
                sum_acc <= sum_acc + resize(new_s, sum_acc'length) - resize(oldest, sum_acc'length);
                -- Advance Pointer Within Dynamic Window
                ptr <= (ptr + 1) mod avg_window_size;
                -- Prepare Output
                avg_data  <= std_logic_vector(sum_acc);
                avg_ready <= '1';
                correlation_sample_interval_counter := correlation_sample_interval_counter + 1;
                if correlation_sample_interval_counter >= to_integer(unsigned(correlation_sample_interval)) then -- Trigger Correlation Calculation
                    corr_calculate <= '1';
                    correlation_sample_interval_counter := 0;
                else
                    corr_calculate <= '0';
                end if;
            else
                avg_data  <= (others => '0');
                avg_ready <= '0';
            end if;
        end if;
    end process;
end architecture;