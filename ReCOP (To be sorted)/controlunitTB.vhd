-- filepath: c:\Users\DH\Documents\GitHub\COMPSYS_701\ReCOP\controlunit_tb.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.recop_types.ALL;
use work.opcodes.ALL;
use work.various_constants.ALL;

entity controlunit_tb is
end entity controlunit_tb;

architecture tb of controlunit_tb is
    -- Clock & reset
    signal clk            : bit_1   := '0';
    signal reset          : bit_1   := '1';

    -- Inputs to CUT
    signal dm_sel_addr    : bit_2   := (others => '0');
    signal dm_sel_in      : bit_2   := (others => '0');
    signal rz_empty       : bit_1   := '0';
    signal alu_z_flag     : bit_1   := '0';
    signal opcode         : bit_6   := (others => '0');
    signal address_mode   : bit_2   := (others => '0');

    -- Outputs from CUT
    signal ir_in             : bit_1;
    signal pc_in             : bit_2;
    signal rf_sel_in         : bit_3;
    signal alu_operation     : bit_3;
    signal alu_sel_op1       : bit_1;
    signal alu_sel_op2       : bit_1;
    signal pc_mode           : bit_2;
    signal dcpr_sel          : bit_1;
    signal sop_write         : bit_1;
    signal alu_clr_z_flag    : bit_1;
    signal reg_write         : bit_1;
    signal data_mem_write    : bit_1;
    signal pc_write_flag     : bit_1;
    signal dcpr_write_flag   : bit_1;
begin
    -- Instantiate Device Under Test
    CUT: entity work.control_unit
        port map (
            clk               => clk,
            reset             => reset,
            dm_sel_addr       => dm_sel_addr,
            dm_sel_in         => dm_sel_in,
            ir_in             => ir_in,
            pc_in             => pc_in,
            rf_sel_in         => rf_sel_in,
            alu_operation     => alu_operation,
            alu_sel_op1       => alu_sel_op1,
            alu_sel_op2       => alu_sel_op2,
            pc_mode           => pc_mode,
            dcpr_sel          => dcpr_sel,
            sop_write         => sop_write,
            alu_clr_z_flag    => alu_clr_z_flag,
            reg_write         => reg_write,
            data_mem_write    => data_mem_write,
            pc_write_flag     => pc_write_flag,
            dcpr_write_flag   => dcpr_write_flag,
            rz_empty          => rz_empty,
            alu_z_flag        => alu_z_flag,
            opcode            => opcode,
            address_mode      => address_mode
        );

    -- Clock generation: 10 ns period
    clk_proc: process
    begin
        while true loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
    end process clk_proc;

    -- Stimulus process
    stim_proc: process
    begin
        -- apply reset
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait for 20 ns;

        -- Test 1: ANDR immediate
        opcode       <= andr;
        address_mode <= am_immediate;
        rz_empty     <= '0';
        alu_z_flag   <= '0';
        wait for 30 ns;

        -- Test 2: LDR direct
        opcode       <= ldr;
        address_mode <= am_direct;
        wait for 30 ns;

        -- Test 3: STR register
        opcode       <= str;
        address_mode <= am_register;
        wait for 30 ns;

        -- Test 4: JMP immediate
        opcode       <= jmp;
        address_mode <= am_immediate;
        wait for 30 ns;

        -- End simulation
        report "Testbench completed" severity note;
        wait;
    end process stim_proc;

end architecture tb;