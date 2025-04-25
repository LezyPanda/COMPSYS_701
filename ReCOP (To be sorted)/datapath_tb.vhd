library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.recop_types.all;
use work.various_constants.all;
use work.opcodes.all;

entity datapath_tb is
end entity;

architecture testbench of datapath_tb is
    signal clk               : bit_1 := '0';
    signal reset             : bit_1 := '1';

    signal button            : bit_4 := (others => '0');
    signal sw                : bit_10 := (others => '0');

    signal dm_sel_addr       : bit_2 := "00";
    signal dm_sel_in         : bit_2 := "00";
    signal dm_write          : bit_1 := '0';
    signal ir_in             : bit_1 := '0';
    signal ir_fetch_start    : bit_1 := '0';
    signal rf_sel_in         : bit_3 := "000";
    signal rf_write_flag     : bit_1 := '0';
    signal dcpr_sel          : bit_1 := '0';
    signal sop_write         : bit_1 := '0';
    signal pc_write_flag     : bit_1 := '0';
    signal pc_mode           : bit_2 := "00";
    signal alu_clr_z_flag    : bit_1 := '0';
    signal alu_operation     : bit_3 := "000";
    signal alu_sel_op1       : bit_2 := "00";
    signal alu_sel_op2       : bit_1 := '0';

    signal alu_z_flag        : bit_1;
    signal alu_result        : bit_16;
    signal ir_opcode         : bit_8;
    signal inst_fetched      : bit_1;

    component datapath is
        port (
            clk     : in bit_1;
            reset   : in bit_1;
            button  : in bit_4;
            sw      : in bit_10;
            dm_sel_addr     : in bit_2;
            dm_sel_in       : in bit_2;
            dm_write        : in bit_1;
            ir_in           : in bit_1;
            ir_fetch_start  : in bit_1;
            rf_sel_in       : in bit_3;
            rf_write_flag   : in bit_1;
            dcpr_sel        : in bit_1;
            sop_write       : in bit_1;
            pc_write_flag   : in bit_1;
            pc_mode         : in bit_2;
            alu_clr_z_flag  : in bit_1;
            alu_operation   : in bit_3;
            alu_sel_op1     : in bit_2;
            alu_sel_op2     : in bit_1;
            alu_z_flag      : out bit_1;
            alu_result      : out bit_16;
            ir_opcode       : out bit_8;
            inst_fetched    : out bit_1
        );
    end component;

begin
    -- Instantiate the DUT (Device Under Test)
    uut: datapath
        port map (
            clk             => clk,
            reset           => reset,
            button          => button,
            sw              => sw,
            dm_sel_addr     => dm_sel_addr,
            dm_sel_in       => dm_sel_in,
            dm_write        => dm_write,
            ir_in           => ir_in,
            ir_fetch_start  => ir_fetch_start,
            rf_sel_in       => rf_sel_in,
            rf_write_flag   => rf_write_flag,
            dcpr_sel        => dcpr_sel,
            sop_write       => sop_write,
            pc_write_flag   => pc_write_flag,
            pc_mode         => pc_mode,
            alu_clr_z_flag  => alu_clr_z_flag,
            alu_operation   => alu_operation,
            alu_sel_op1     => alu_sel_op1,
            alu_sel_op2     => alu_sel_op2,
            alu_z_flag      => alu_z_flag,
            alu_result      => alu_result,
            ir_opcode       => ir_opcode,
            inst_fetched    => inst_fetched
        );

    -- Clock generation (50 MHz = 20ns period)
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for 10 ns;
            clk <= '1';
            wait for 10 ns;
        end loop;
    end process;

    -- Stimulus process
    stimulus: process
    begin
        -- Initial reset
        wait for 30 ns;
        reset <= '0';
        
        wait for 20 ns;

        -- Start fetching an instruction
        ir_fetch_start <= '1';
        wait for 20 ns;
        ir_fetch_start <= '0';

        -- Wait and observe
        wait for 100 ns;

        -- Simulate a PC write operation
        pc_mode        <= pc_mode_value;
        pc_write_flag  <= '1';
        wait for 20 ns;
        pc_write_flag  <= '0';

        -- Finish
        wait for 200 ns;
        assert false report "Simulation Finished" severity failure;
    end process;

end architecture;
