library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity inst_reg is
    port (
        clk         : in  bit_1;
        reset       : in  bit_1;
        instruction : in  bit_32;
        opcode      : out bit_8; -- AM(2) + OPCODE(6)
        rxValue     : out bit_16;
        rzValue     : out bit_16;
        operand     : out bit_16;
    );
end inst_reg;

architecture behaviour of inst_reg is
    signal opcode_signal : bit_8 := X"00";
    signal rxValue_signal : bit_16 := X"0000";
    signal rzValue_signal : bit_16 := X"0000";
    signal operand_signal : bit_16 := X"0000";
begin
    process(clk, reset, instruction)
    begin
        if reset = '1' then
            opcode_signal <= X"00";
            rxValue_signal <= X"0000";
            rzValue_signal <= X"0000";
            operand_signal <= X"0000";
        elsif rising_edge(clk) then
            opcode_signal <= instruction(31 downto 24);
            rxValue_signal <= instruction(23 downto 20);
            rzValue_signal <= instruction(19 downto 16);
            operand_signal <= instruction(15 downto 0);
        end if;
    end process;
    opcode <= opcode_signal;
    rxValue <= rxValue_signal;
    rzValue <= rzValue_signal;
    operand <= operand_signal;
end behaviour;
