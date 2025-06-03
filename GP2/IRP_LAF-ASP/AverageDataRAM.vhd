library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- AverageDataRAM: stores 16-bit average results into RAM
entity AverageDataRAM is
    generic (
        ADDR_WIDTH : natural := 20;  
        DATA_WIDTH : natural := 16   
    );
    port (
        clk          : in  std_logic;
        data_in      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        write_enable : in  std_logic;
        write_addr   : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        read_addr    : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        q            : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of AverageDataRAM is
    type ram_t is array (0 to 2**ADDR_WIDTH - 1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal ram : ram_t := (others => (others => '0'));
    signal q_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if write_enable = '1' then
                ram(to_integer(unsigned(write_addr))) <= data_in;
            end if;
            -- synchronous read
            q_reg <= ram(to_integer(unsigned(read_addr)));
        end if;
    end process;

    q <= q_reg;
end architecture;
