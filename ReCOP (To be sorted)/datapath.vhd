library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;

use work.recop_types.all;

entity datapath is
    port (
        -- Common
        clk:    in bit_1;
        reset:  in bit_1;

        -- DE1SoC Peripherals
        button: in bit_4;
        sw:     in bit_10;

        -- OPCode to CU
        opcode: out bit_8;
    );
end datapath;

component PC is 
    port (
        clk : in bit_1;
        reset : in bit_1;
        PC : in bit_16;
        IR : in bit_16;
        OP : in bit_16;
        instr_prev : bit_16;
    );
end component;

architecture behaviour of datapath is
    signal instruction : bit_32;

    -- Decode Instruction
    opcode <= instruction(31 downto 24)
    


    begin

end behaviour;

