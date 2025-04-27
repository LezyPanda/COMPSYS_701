library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.various_constants.all;
use work.recop_types.all;


entity prog_counter is
    port (
        clk             : in  bit_1;
        reset           : in  bit_1;
        pc_write_flag   : in  bit_1;
        pc_mode         : in  bit_2;
        pc_in           : in  bit_15;
        pc_out          : out bit_15
    );
end prog_counter;

architecture behaviour of prog_counter is
    signal pc_out_signal : bit_15 := "000000000000000";
    signal prev_write_flag : bit_1 := '0';
begin
    process(clk, reset)
    begin
        if reset = '1' then
            pc_out_signal <= "000000000000000";
        -- Only want to check for write flag change
        elsif rising_edge(clk) and pc_write_flag /= prev_write_flag then
            prev_write_flag <= pc_write_flag;
            if (pc_write_flag = '1') then
                case pc_mode is
                    when pc_mode_rx =>
                        pc_out_signal <= pc_in;
                    when pc_mode_value =>
                        pc_out_signal <= pc_in;
                    when pc_mode_incr_1 =>
                        pc_out_signal <= pc_out_signal + 1;
                    when pc_mode_incr_2 =>
                        pc_out_signal <= pc_out_signal + 2;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;
    pc_out <= pc_out_signal;
end behaviour;
