library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;

use work.recop_types.all;
use work.various_constants.all;
use work.opcodes.all;

entity datapath is
    port (
        -- Common
        clk     : in bit_1;
        reset   : in bit_1;

        -- DE1SoC Peripherals
        button  : in bit_4;
        sw      : in bit_10;

        -- Operation
        opcode          : out bit_8; -- AM(2) + OPCODE(6)
        -- rx              : out bit_16;
        -- rz              : out bit_16;
        alu_result      : in  bit_16;
        
        -- Program Counter
        pc_write_flag   : in  bit_1; -- Write Program Counter
        pc_mode         : in  bit_2; -- 00 -> Direct Set (Jump?), 01 -> PC + 1, 10 -> PC + 2
        pc_in           : in  bit_16;
        next_inst_addr  : out bit_16; -- pc_out

        -- Control Unit Mux Select
        -- inst_fetch_mem_sel : in  bit_1; -- 0 -> internal, 1 -> external
    );
end datapath;

architecture behaviour of datapath is
    -- Components
    component prog_counter is
        port (
            clk     : in  bit_1;
            reset   : in  bit_1;
            pc_mode : in  bit_2;
            pc_in   : in  bit_16;
            pc_out  : out bit_16
        );
    end component;
    component inst_reg is
        port (
            clk         : in  bit_1;
            reset       : in  bit_1;
            instruction : in  bit_32;
            opcode      : out bit_8; -- AM(2) + OPCODE(6)
            rxValue     : out bit_16;
            rzValue     : out bit_16;
            operand     : out bit_16;
        );
    end component;
    component prog_mem is
        port
        (
            address : in bit_15;
            clock	: in bit_1 := '1';
            q		: out bit_16
        );
    end component;
    component data_mem is
        port
        (
            address		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
            clock		: IN STD_LOGIC  := '1';
            data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
            wren		: IN STD_LOGIC ;
            q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
        );
    end component;
    -- End Components

    -- Program Counter Signals
    signal pc_out   : bit_16    := X"0000";
    -- End Program Counter Signals

    -- Instruction Register Signals
    signal instruction  : bit_32;
    signal opcode       : bit_8     := X"00";
    signal rxValue      : bit_16    := X"0000";
    signal rzValue      : bit_16    := X"0000";
    signal operand      : bit_16    := X"0000";
    -- End Instruction Register Signals    

    -- Program Memory Signals
    signal pm_address   : bit_15    := "000000000000000";
    signal instruction  : bit_16    := X"0000";
    -- End Program Memory Signals
begin
    prog_counter_inst : prog_counter
        port map (
            clk             => clk,
            reset           => reset,
            pc_write_flag   => pc_write_flag,
            pc_mode         => pc_mode,
            pc_in           => pc_in,
            pc_out          => pc_out
        );
    inst_reg_inst : inst_reg
        port map (
            clk         => clk,
            reset       => reset,
            instruction => instruction,
            opcode      => opcode,
            rxValue     => rxValue,
            rzValue     => rzValue,
            operand     => operand
        );
    prog_mem_inst : prog_mem
        port map (
            address => pm_address,
            clock   => clk,
            q       => instruction
        );
    
    inst_addr_update_process: process(clk, reset, pc_out)
    begin
        if reset = '1' then
            pm_address <= "000000000000000";
            instruction <= X"00000000";
        elsif rising_edge(clk) then
            pm_address <= pc_out;
        end if;
    end process inst_addr_update_process;
    
    -- Decode Instruction
    opcode <= instruction(31 downto 24)

    next_inst_addr <= pc_out;

end behaviour;

