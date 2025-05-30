library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.TdmaMinTypes.all;

entity LAFAsp is
    generic (
        MAX_WIN : natural := 64  
    );
    port (
        clock      : in  std_logic;
        recv       : in  tdma_min_port;   
        avg_data   : out std_logic_vector(15 downto 0);
        avg_ready  : out std_logic
    );
end entity; -- tdma future 3 bits needed to use io to change from 4 8 16 32 64

architecture rtl of LAFAsp is
    constant MAX_N : natural := MAX_WIN;  
    signal window_size_inst : natural range 4 to MAX_N := MAX_N;
    subtype sample_t is unsigned(7 downto 0);
    type buffer_t is array (0 to MAX_N-1) of sample_t;

    signal buffer_reg : buffer_t := (others => (others => '0'));
    signal sum_acc    : unsigned(15 downto 0) := (others => '0');
    signal ptr        : integer range 0 to MAX_N-1 := 0;
begin
    process(clock)
        variable oldest        : sample_t;
        variable new_s         : sample_t;
        variable code_i        : integer;
        variable desired_size  : natural;
    begin
        if rising_edge(clock) then
            if recv.data(8) = '1' then
                -- determine desired window size from code bits
                code_i := to_integer(unsigned(recv.data(11 downto 9)));
                case code_i is
                    when 0 => desired_size := 4;
                    when 1 => desired_size := 8;
                    when 2 => desired_size := 16;
                    when 3 => desired_size := 32;
                    when 4 => desired_size := 64;
                    when others => desired_size := MAX_N;
                end case;
                if desired_size > MAX_N then
                    window_size_inst <= MAX_N;
                else
                    window_size_inst <= desired_size;
                end if;
                -- moving average calculation
                new_s  := unsigned(recv.data(7 downto 0));
                oldest := buffer_reg(ptr);
                buffer_reg(ptr) <= new_s;
                sum_acc <= sum_acc + resize(new_s, sum_acc'length) - resize(oldest, sum_acc'length);
                -- advance pointer within dynamic window
                ptr <= (ptr + 1) mod window_size_inst;
                -- prepare output
                avg_data  <= std_logic_vector(sum_acc);
                avg_ready <= '1';
            else
                -- no new data
                avg_data  <= (others => '0');
                avg_ready <= '0';
            end if;
        end if;
    end process;
end architecture;