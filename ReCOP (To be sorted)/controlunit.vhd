library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;

use work.recop_types.all;

entity control_unit is
    port (
        -- Common
        clk:    in bit_1;
        reset:  in bit_1;

        -- DE1SoC Peripherals
        button: in bit_4;
        sw:     in bit_10;

        -- OPCode from DP
        opcode: in bit_8;
    );
end control_unit;

architecture behaviour of datapath is
    begin

end behaviour;

