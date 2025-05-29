library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.TdmaMinTypes.all;

entity LdrASP is
    generic (
        WINDOW_SIZE : natural := 64   
    );
    port (
        clock : in  std_logic;
        recv  : in  tdma_min_port;   
        send  : out tdma_min_port    
    );
end entity; -- tdma future 3 bits needed to use io to change from 4 8 16 32 64

architecture rtl of LdrASP is
    constant MAX_N : natural := WINDOW_SIZE; 
    signal window_size_inst : natural range 4 to MAX_N := MAX_N;
    subtype sample_t is unsigned(7 downto 0);
    type buffer_t is array (0 to MAX_N-1) of sample_t;

    signal buffer_reg : buffer_t := (others => (others => '0'));
    signal sum_acc    : unsigned(15 downto 0) := (others => '0');
    signal ptr        : integer range 0 to MAX_N-1 := 0;
begin
    process(clock)
        variable oldest : sample_t;
        variable new_s  : sample_t;
    begin
        if rising_edge(clock) then
            -- decode window size and adc ready
            if recv.data(8) = '1' then
                case recv.data(11 downto 9) is -- not added to instr set yet but needed as user configurable
                    when "000" => window_size_inst <= 4;
                    when "001" => window_size_inst <= 8;
                    when "010" => window_size_inst <= 16;
                    when "011" => window_size_inst <= 32;
                    when "100" => window_size_inst <= 64;
                    when others => window_size_inst <= MAX_N;
                end case;
                -- moving average calculation
                new_s  := unsigned(recv.data(7 downto 0));
                oldest := buffer_reg(ptr);
                buffer_reg(ptr) <= new_s;
                sum_acc <= sum_acc + resize(new_s, sum_acc'length) - resize(oldest, sum_acc'length);
                -- advance pointer within dynamic window
                ptr <= (ptr + 1) mod window_size_inst;
                -- prepare output
                send.addr <= recv.addr;
                send.data <= (others => '0');
                send.data(15 downto 0) <= std_logic_vector(sum_acc);
                send.data(16) <= '1';  -- avg_result_rdy
            else
                -- no new data
                send.addr <= recv.addr;
                send.data <= (others => '0');
                send.data(16) <= '0';
            end if;
        end if;
    end process;
end architecture;