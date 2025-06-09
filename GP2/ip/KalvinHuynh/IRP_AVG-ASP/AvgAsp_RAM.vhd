library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.TdmaMinTypes.all;

entity AvgAsp_RAM is
    port (
        clock         : in  std_logic;
        recv          : in  tdma_min_port;
        send          : out tdma_min_port
    );
end entity;

architecture rtl of AvgAsp_RAM is
    signal avg_data_sig         : std_logic_vector(15 downto 0) := (others => '0');
    signal avg_ready_sig        : std_logic := '0';
    signal prev_corr_calculate  : std_logic := '0';
    signal corr_calculate       : std_logic := '0';

    signal ram_raddr        : std_logic_vector(9 downto 0) := (others => '0');
    signal ram_waddr        : std_logic_vector(9 downto 0) := (others => '0');
    signal ram_q            : std_logic_vector(15 downto 0) := (others => '0');
    signal sendSignal       : tdma_min_port := (others => (others => '0'));
    signal read_request     : std_logic := '0';
begin
    LDR: entity work.AvgAsp
        port map (
            clock           => clock,
            recv            => recv,
            avg_data        => avg_data_sig,
            avg_ready       => avg_ready_sig,
            corr_calculate  => corr_calculate
        );

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

    process(clock)
    begin
        if rising_edge(clock) then
            if (recv.data(31 downto 28) = "1000" and recv.data(23 downto 20) = "0010") then -- Request ADC Data Packet
                ram_raddr <= recv.data(9 downto 0);                                        -- Latch new read address
                read_request <= '1';                                                           -- Flag new read
            end if;

            if (corr_calculate = '1') then
                prev_corr_calculate <= '1';
            end if;

            if (avg_ready_sig = '1' ) then                              -- New Average Data Ready and Data is not 0
                ram_waddr <= std_logic_vector(unsigned(ram_waddr) + 1);     -- Increment Write Address
                sendSignal.addr <= "00000011";                              -- To CorAsp
                sendSignal.data <= (others => '0');                         -- Clear
                sendSignal.data(31 downto 28) <= "1000";                    -- New AVG Data Address Gen Packet
                sendSignal.data(23 downto 20) <= "0100";                    -- MODE
                sendSignal.data(9 downto 0) <= ram_waddr;                   -- Send New Average Data Address
            elsif (read_request = '1') then                             -- Has Request for AVG Data Packet
                sendSignal.addr <= "00000011";                              -- To CorAsp
                sendSignal.data <= (others => '0');                         -- Clear
                sendSignal.data(31 downto 28) <= "1000";                    -- AVG Data Packet
                sendSignal.data(23 downto 20) <= "0011";                    -- MODE
                sendSignal.data(16) <= prev_corr_calculate;                 -- Enough ADC Samples to Calculate Correlation
                sendSignal.data(15 downto 0) <= ram_q;                      -- Send Q From RAM
                read_request <= '0';                                         -- Clear read flag
                prev_corr_calculate <= '0';                                 -- Reset Previous Correlation Calculate Flag
            else
                sendSignal.addr <= (others => '0');                         -- Clear
                sendSignal.data <= (others => '0');                         -- Clear
            end if;
        end if;
    end process;
    send <= sendSignal;
end architecture;
