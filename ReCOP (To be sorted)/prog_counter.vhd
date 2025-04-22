library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity prog_counter is
    port (
        clk             : in  bit_1;
        reset           : in  bit_1;
        pc_write_flag   : in  bit_1;
        pc_mode         : in  bit_2;
        pc_in           : in  bit_16;
        pc_out          : out bit_16
    );
end prog_counter;

architecture behaviour of prog_counter is
    signal pc_out_signal : bit_16 := X"0000";
begin
    process(clk, reset)
    begin
        if reset = '1' then
            pc_out_signal <= X"0000";
        elsif rising_edge(clk) and pc_write_flag = '1' then
            case pc_mode is
                when "00" =>
                    pc_out_signal <= pc_in;
                when "01" =>
                    pc_out_signal <= pc_out_signal + 1;
                when "10" =>
                    pc_out_signal <= pc_out_signal + 2;
                when others =>
                    null;
            end case;
        end if;
    end process;
    pc_out <= pc_out_signal;
end behaviour;
