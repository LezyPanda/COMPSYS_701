library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.recop_types.all;
use work.various_constants.all;
use work.opcodes.all;

entity tb_datapath is
end entity;

architecture testbench of tb_datapath is
    -- DUT signals
    signal clk               : bit_1 := '0';
    signal reset             : bit_1 := '1';

    signal dm_sel_addr       : bit_2 := "00";
    signal dm_sel_in         : bit_2 := "00";
    signal dm_write          : bit_1 := '0';
    signal ir_fetch_start    : bit_1 := '0';
    signal rf_sel_in         : bit_3 := "000";
    signal rf_write_flag     : bit_1 := '0';
    signal pc_write_flag     : bit_1 := '0';
    signal pc_mode           : bit_2 := "00";
    signal alu_clr_z_flag    : bit_1 := '0';
    signal alu_operation     : bit_3 := "000";
    signal alu_sel_op1       : bit_2 := "00";
    signal alu_sel_op2       : bit_1 := '0';
    signal dpcr_write_flag   : bit_1 := '0';
    signal dpcr_sel          : bit_1 := '0';
    signal sop_write         : bit_1 := '0';

    signal alu_z_flag        : bit_1;
    signal alu_result        : bit_16;
    signal ir_opcode         : bit_8;
    signal inst_fetched      : bit_1;
    signal rz_empty          : bit_1;

    constant clk_period : time := 10 ns;

begin
    -- Instantiate the DUT
    uut: entity work.datapath
        port map (
            clk               => clk,
            reset             => reset,
            dm_sel_addr       => dm_sel_addr,
            dm_sel_in         => dm_sel_in,
            dm_write          => dm_write,
            ir_fetch_start    => ir_fetch_start,
            rf_sel_in         => rf_sel_in,
            rf_write_flag     => rf_write_flag,
            pc_write_flag     => pc_write_flag,
            pc_mode           => pc_mode,
            alu_clr_z_flag    => alu_clr_z_flag,
            alu_operation     => alu_operation,
            alu_sel_op1       => alu_sel_op1,
            alu_sel_op2       => alu_sel_op2,
            dpcr_write_flag   => dpcr_write_flag,
            dpcr_sel          => dpcr_sel,
            sop_write         => sop_write,
            alu_z_flag        => alu_z_flag,
            alu_result        => alu_result,
            ir_opcode         => ir_opcode,
            inst_fetched      => inst_fetched,
            rz_empty          => rz_empty
        );

    -- Clock generation
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Reset sequence
        wait for 20 ns;
        reset <= '0';

        -- Start instruction fetch
        wait for clk_period;
        ir_fetch_start <= '1';
        wait for clk_period;
        ir_fetch_start <= '0';

        -- Example ALU operation (just for illustration)
        alu_operation     <= "001";  -- Let's say it's ADD
        alu_sel_op1       <= "01";   -- Select operand 1
        alu_sel_op2       <= '1';    -- Select operand 2
        alu_clr_z_flag    <= '1';

        -- Program counter update
        pc_write_flag     <= '1';
        pc_mode           <= pc_mode_value; -- from constants

        -- Write to register file
        rf_sel_in         <= "001";
        rf_write_flag     <= '1';

        wait for 10 * clk_period;

        -- Stop simulation
        wait;
    end process;

end architecture;
