library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.TdmaMinTypes.all;

library altera_mf;
use altera_mf.all;

-- get data from signal rom pkg
entity play_signal is
	port (
		clk   : in  std_logic;
		addr  : in  integer range 0 to 4095;
		recv  : in  tdma_min_port;
		send  : out tdma_min_port;
		data  : out std_logic_vector(9 downto 0) := (others => '0')
	);
end entity;

architecture rtl of play_signal is
    signal sendSignal : tdma_min_port := (others => (others => '0'));

    -- ROM parameters
    constant ROM_DEPTH_C  : integer := 4096;
    constant ADDR_WIDTH   : integer := 12;
    signal addr_vec       : std_logic_vector(ADDR_WIDTH-1 downto 0);

    -- Altera ROM component
    component altsyncram
        generic (
            operation_mode : string;
            width_a        : integer;
            widthad_a      : integer;
            init_file      : string;
            numwords_a     : integer;
            lpm_hint       : string;
            lpm_type       : string
        );
        port (
            address_a : in std_logic_vector(widthad_a-1 downto 0);
            clock0    : in std_logic;
            q_a       : out std_logic_vector(width_a-1 downto 0);
            data_a    : in std_logic_vector(width_a-1 downto 0);
            wren_a    : in std_logic
        );
    end component;

begin
    -- address conversion
    addr_conv: process(addr)
    begin
        addr_vec <= std_logic_vector(to_unsigned(addr, ADDR_WIDTH));
    end process;

    -- instantiate ROM
    rom_inst: altsyncram
        generic map (
            operation_mode => "ROM",
            width_a        => 10,
            widthad_a      => ADDR_WIDTH,
            init_file      => "signal_rom.mif",
            numwords_a     => ROM_DEPTH_C,
            lpm_hint       => "ENABLE_RUNTIME_MOD=NO",
            lpm_type       => "altsyncram"
        )
        port map (
            address_a => addr_vec,
            clock0    => clk,
            q_a       => data,
            data_a    => (others => '0'),
            wren_a    => '0'
        );
end architecture;