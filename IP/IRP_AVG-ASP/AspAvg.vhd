library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.TdmaMinTypes.all;

entity AspAvg is
  generic (
    WINDOW : integer := 4
  );
  port (
    clock : in  std_logic;
    recv  : in  tdma_min_port;
    send  : out tdma_min_port
  );
end entity;

architecture rtl of AspAvg is

  type sample_fifo_t is array(0 to WINDOW - 1) of signed(7 downto 0);

  signal out_addr    : unsigned(9 downto 0) := (others => '0');
  signal send_stage  : integer range 0 to 2 := 0;
  signal send_buffer : std_logic_vector(31 downto 0) := (others => '0');
  signal dest_mem   : std_logic_vector(3 downto 0) := "0110";	 -- mem_addr
  signal dest_data	: std_logic_vector(3 downto 0) := "0101";  -- Correlation(in)

begin

  process(clock)
    variable new_sample : signed(7 downto 0);
    variable buf    		: sample_fifo_t;
    variable index		: integer := 0;
	 variable avg 			: signed(15 downto 0);
	 variable sum			: signed(15 downto 0);
  begin
    if rising_edge(clock) then
      send.addr <= (others => '0');
      send.data <= (others => '0');

      if send_stage = 1 then
        -- Send address packet Avg(out) addr_gen
        send.addr <= "0100" & dest_mem;
		  -- Format packet
        send.data <=
          "0100" &                    			-- Bits 31–28: ID
          dest_mem &               				-- Bits 27–24: Destination
          (23 downto 10 => '0') &				-- Bits 23-10: Unused
          std_logic_vector(out_addr - 1); 	-- Bits 9–0: Address of avg_data
        send_stage <= 0;

      elsif send_stage = 2 then
        -- Send average data packet Avg(out)
        send.addr <= "0011" & dest_data;
        send.data <= send_buffer;
        send_stage <= 1;

      elsif recv.data(31 downto 28) = "0000" and recv.data(8) = '1' then  -- ADC(out)
        new_sample := signed(recv.data(7 downto 0));
		  buf(index) := new_sample;
		  index := (index + 1) mod WINDOW;
		  
		  if index = 0 then
		    sum := (others => '0');
			 for i in 0 to WINDOW - 1 loop
				sum := sum + resize(buf(i), 16);
			 end loop;
			 
			 avg := resize(sum(15 downto 2), 16);
          send_stage <= 2;

          -- Store averaged value in send_buffer
			 -- Packet format
          send_buffer <=
            "0011" &                    	-- Bits 31–28: ID 
            dest_data &                	-- Bits 27–24: Destination 
            "0000000" &                	-- Bits 23–17: Unused
            '1' &                      	-- Bit 16: avg_result_rdy
            std_logic_vector(avg); 			-- Bits 15–0
          out_addr <= out_addr + 1;
        end if;
      end if;
    end if;
  end process;

end architecture;
