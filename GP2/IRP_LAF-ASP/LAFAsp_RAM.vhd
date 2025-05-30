library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.TdmaMinTypes.all;

entity LAFAsp_RAM is
    generic (
        WINDOW_SIZE : natural := 8  -- default window size
    );
    port (
        clock         : in  std_logic;
        recv          : in  tdma_min_port;
        send          : out tdma_min_port;  
        ram_waddr     : in  std_logic_vector(9 downto 0);
        avg_ready_out : out std_logic -- test
    );
end entity;

architecture rtl of LAFAsp_RAM is
    signal avg_data_sig  : std_logic_vector(15 downto 0);
    signal avg_ready_sig : std_logic;
    signal ram_raddr     :  std_logic_vector(9 downto 0);
    signal ram_q         :  std_logic_vector(15 downto 0);
    signal sendSignal : tdma_min_port := (
		addr => (others => '0'),
		data => (others => '0')
	);

begin
    -- Instantiate LdrASP
    LDR: entity work.LdrASP
        generic map (WINDOW_SIZE => WINDOW_SIZE)
        port map (
            clock     => clock,
            recv      => recv,
            avg_data  => avg_data_sig,
            avg_ready => avg_ready_sig
        );

    process(clock)
    begin
        if rising_edge(clock) then
            if recv.data(31 downto 28) = "0111" then
                ram_raddr <= recv.data(9 downto 0);
            end if;
        end if;
    end process;

    avg_ready_out <= avg_ready_sig;

    -- Instantiate AverageDataRAM directly with avg signals
    RAM: entity work.AverageDataRAM
        generic map (
            ADDR_WIDTH => 10,
            DATA_WIDTH => 16
        )
        port map (
            clk          => clock,
            data_in      => avg_data_sig,
            write_enable => avg_ready_sig,
            write_addr   => ram_waddr,
            read_addr    => ram_raddr,
            q            => ram_q
        );

    sendSignal.data(31 downto 28) <= "0101";
    sendSignal.data(26 downto 17) <= ram_raddr;
    sendSignal.data(16) <= '1'; 
    sendSignal.data(15 downto 0) <= ram_q;
end architecture;
