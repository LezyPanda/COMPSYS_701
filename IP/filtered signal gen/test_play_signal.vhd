-- test_play_signal.vhd
-- Testbench for play_signal to display ROM data
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.filter_rom_pkg.all;

entity tb_play_signal is
end entity;

architecture test of tb_play_signal is
  signal clk     : std_logic := '0';
  signal addr    : integer range 1 to ROM_DEPTH := 1;
  signal data_o  : std_logic_vector(15 downto 0);
  constant CLK_PERIOD : time := 20 ns;
begin
  -- Instantiate the Unit Under Test
  UUT: entity work.play_signal
    port map(
      clk  => clk,
      addr => addr,
      data => data_o
    );

  -- Clock generation process
  clk_process: process
  begin
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
  end process;

  -- Stimulus process to cycle through addresses and report data
  stim_process: process
  begin
    -- wait for global reset
    wait for 100 ns;
    for i in 1 to ROM_DEPTH loop
      addr <= i;
      wait until rising_edge(clk);
      report "ADDR=" & integer'image(i) & " DATA=" & integer'image(to_integer(unsigned(data_o))) severity note;
    end loop;
    report "Test completed." severity note;
    wait;
  end process;
end architecture;
