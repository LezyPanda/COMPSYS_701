-- Testbench for LdrASP_WithRAM: integrates LdrASP and AverageDataRAM
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.TdmaMinTypes.all;
use work.signal_rom_pkg.all;

entity LAFAsp_WithRAM_tb2 is
end entity;

architecture sim of LAFAsp_WithRAM_tb2 is
    constant CLK_PERIOD : time := 10 ns;
    constant ROM_DEPTH  : integer := SIGNAL_ROM'length;

    -- Component Declaration
    component LAFAsp_RAM
        generic (
            WINDOW_SIZE : natural := 64
        );
        port (
            clock         : in  std_logic;
            recv          : in  tdma_min_port;
            send          : out tdma_min_port;
            ram_waddr     : in  std_logic_vector(9 downto 0);
            avg_ready_out : out std_logic
        );
    end component;

    -- Signals
    signal clock         : std_logic := '0';
    signal recv          : tdma_min_port := (addr => (others => '0'), data => (others => '0'));
    signal ram_waddr     : std_logic_vector(9 downto 0) := (others => '0');
    signal send          : tdma_min_port;
    signal avg_ready_out : std_logic;
begin

    -- Instantiate DUT
    UUT: LAFAsp_RAM
        generic map (WINDOW_SIZE => 64)
        port map (
            clock         => clock,
            recv          => recv,
            send          => send,
            ram_waddr     => ram_waddr,
            avg_ready_out => avg_ready_out
        );


    clk_gen: process
    begin
        clock <= '0';
        wait for CLK_PERIOD / 2;
        clock <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    stim: process
    begin
        wait for 20 ns; 
        -- fill entire RAM depth
        for idx in 0 to 2**10-1 loop  
            -- prepare recv
            recv.data <= (others => '0');
            recv.data(11 downto 9) <= "100"; -- window_size lalallalaladklfjasdklfjkasldfjlskadfjksdlfjsadklfjslk;fjsdklfjsadlkfjsal;fjl; joe biden
            recv.data(8)           <= '1';     -- adc_data_rdy
            -- sample index by wrapping ROM_DEPTH
            recv.data(7 downto 0)  <= SIGNAL_ROM(((idx mod ROM_DEPTH) + 1));
            recv.addr              <= std_logic_vector(to_unsigned(idx, recv.addr'length));
            -- write address
            ram_waddr <= std_logic_vector(to_unsigned(idx, ram_waddr'length));
            wait for CLK_PERIOD;
        end loop;
        recv.data(8) <= '0';
        wait for CLK_PERIOD;

        -- Read back RAM contents via send port
        for idx in 0 to 2**10-1 loop
            -- use recv.data to set read address
            recv.data <= (others => '0');
            recv.data(9 downto 0) <= std_logic_vector(to_unsigned(idx, 10));
            wait for CLK_PERIOD;
            report "RAM(" & integer'image(idx) & ") = " & integer'image(to_integer(unsigned(send.data(15 downto 0))));
        end loop;
        wait; -- stop
    end process;

end architecture sim;
