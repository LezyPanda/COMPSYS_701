library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.filter_rom_pkg.all;
-- get data from signal rom pkg
entity play_signal is
  Port (
    clk   : in  std_logic;
    addr  : in  integer range 0 to ROM_DEPTH-1;
    data  : out std_logic_vector(15 downto 0)
  );
end entity;

architecture rtl of play_signal is
begin
  process(clk)
  begin
    if rising_edge(clk) then
      data <= FILTER_ROM(addr);
    end if;
  end process;
end architecture;