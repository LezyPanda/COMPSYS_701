library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.signal_rom_pkg.all;
use work.TdmaMinTypes.all;

-- get data from signal rom pkg
entity play_signal is
  Port (
    clk   : in  std_logic;
    addr  : in  integer range 0 to ROM_DEPTH-1;
    recv  : in  tdma_min_port;
	send  : out tdma_min_port
  );
end entity;

architecture rtl of play_signal is
    signal sendSignal : tdma_min_port := (
		addr => (others => '0'),
		data => (others => '0')
	);
begin
  process(clk)
  begin
    if rising_edge(clk) then
		sendSignal.data(7 downto 0) <= SIGNAL_ROM(addr);
    end if;
  end process;
end architecture;