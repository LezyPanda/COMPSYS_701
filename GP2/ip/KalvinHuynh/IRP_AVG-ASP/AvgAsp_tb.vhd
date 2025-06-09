-- Testbench for LdrASP using signal_rom_pkg as input source
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.TdmaMinTypes.all;
use work.signal_rom_pkg.all;

entity AvgAsp_tb is
end entity;

architecture sim of AvgAsp_tb is
    constant CLK_PERIOD : time := 10 ns;
    constant ROM_DEPTH  : integer := SIGNAL_ROM'length;
    -- Component Declaration
    component AvgAsp
        generic (
            WINDOW_SIZE : natural := 64
        );
        port (
            clock     : in  std_logic;
            recv      : in  tdma_min_port;
            avg_data  : out std_logic_vector(15 downto 0);
            avg_ready : out std_logic
        );
    end component;

    -- Testbench signals
    signal clock         : std_logic := '0';
    signal recv          : tdma_min_port := (addr => (others => '0'), data => (others => '0'));
    signal avg_data_sig  : std_logic_vector(15 downto 0);
    signal avg_ready_sig : std_logic := '0';
    signal rom_idx : integer range 1 to ROM_DEPTH := 1;
    -- Mirror of LdrASP internal variables
    constant N_tb : natural := 64;
    subtype sample_t_tb is unsigned(7 downto 0);
    type buffer_t_tb is array (0 to N_tb-1) of sample_t_tb;
    signal buffer_tb      : buffer_t_tb := (others => (others => '0'));
    signal ptr_tb         : integer range 0 to N_tb-1 := 0;
    signal oldest_tb      : sample_t_tb := (others => '0');
    signal new_s_tb       : sample_t_tb := (others => '0');
    signal sum_acc_tb     : unsigned(15 downto 0) := (others => '0');
begin

    -- Instantiate Device Under Test
    UUT: AvgAsp
        generic map (WINDOW_SIZE => 64)
        port map (
            clock     => clock,
            recv      => recv,
            avg_data  => avg_data_sig,
            avg_ready => avg_ready_sig
        );

    -- Clock generation: 100MHz
    clk_gen: process
    begin
        clock <= '0';
        wait for 5 ns;
        clock <= '1';
        wait for 5 ns;
    end process;

    -- Input driver: feed samples from SIGNAL_ROM each clock
    input_drive: process(clock)
    begin
        if rising_edge(clock) then
            -- update address and sample
            recv.addr <= std_logic_vector(to_unsigned(rom_idx-1, recv.addr'length));
            -- prepare recv.data: window code, data ready, and sample
            recv.data <= (others => '0');
            recv.data(11 downto 9) <= "001";  -- window size = 8
            recv.data(8)             <= '1';     -- adc_data_rdy
            recv.data(7 downto 0)    <= SIGNAL_ROM(rom_idx);
            -- wrap index
            if rom_idx < ROM_DEPTH then
                rom_idx <= rom_idx + 1;
            else
                rom_idx <= 1;
            end if;
            -- Mirror internal LdrASP behavior
            oldest_tb    <= buffer_tb(ptr_tb);
            new_s_tb     <= unsigned(SIGNAL_ROM(rom_idx));
            buffer_tb(ptr_tb) <= new_s_tb;
            sum_acc_tb   <= sum_acc_tb + resize(new_s_tb, sum_acc_tb'length) - resize(oldest_tb, sum_acc_tb'length);
            ptr_tb       <= (ptr_tb + 1) mod N_tb;
        end if;
    end process;

    -- Output monitor: report moving sum
    output_monitor: process(clock)
    begin
        if rising_edge(clock) then
            report "Time " & time'image(now) &
                   " DUT_Sum=" & integer'image(to_integer(unsigned(avg_data_sig))) &
                   " Ready="   & std_logic'image(avg_ready_sig) &
                   " TB_Sum="  & integer'image(to_integer(sum_acc_tb));
        end if;
    end process;
end architecture sim;
