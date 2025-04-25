-- Zoran Salcic

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.recop_types.all;
use work.opcodes.all;
use work.various_constants.all;

entity recop_tb2 is
    --port (
        --key     : in bit_4;
        --sw      : in bit_10;
        --led     : out bit_10;
        --hex0    : out bit_7;
        --hex1    : out bit_7;
        --hex2    : out bit_7;
        --hex3    : out bit_7;
        --hex4    : out bit_7;
        --hex5    : out bit_7
    --);
end recop_tb2;

architecture combined of recop_tb2 is
    -- Internal simulated clock/reset
    signal clk   : bit_1 := '0';
    signal reset : bit_1 := '1';

    -- Control Signals
    signal dm_sel_addr     : bit_2;
    signal dm_sel_in       : bit_2;
    signal dm_write        : bit_1;
    signal ir_fetch_start  : bit_1;
    signal rf_sel_in       : bit_3;
    signal rf_write_flag   : bit_1;
    signal pc_write_flag   : bit_1;
    signal pc_mode         : bit_2;
    signal alu_clr_z_flag  : bit_1;
    signal alu_operation   : bit_3;
    signal alu_sel_op1     : bit_2;
    signal alu_sel_op2     : bit_1;
    signal dpcr_write_flag : bit_1;
    signal dpcr_sel        : bit_1;
    signal sop_write       : bit_1;
    signal alu_z_flag      : bit_1;
    signal alu_result      : bit_16;
    signal ir_opcode       : bit_8;
    signal inst_fetched    : bit_1;
    signal rz_empty        : bit_1;

    -- Debug Signals DP
    signal debug_pc_out         : bit_15;
    signal debug_fetch_state    : bit_2;
    signal debug_instruction    : bit_32;
    -- Debug Signals CU
    signal debug_state          : bit_2;
    signal debug_next_state     : bit_2;

    component datapath is
        port (
            clk             : in bit_1;
            reset           : in bit_1;
            dm_sel_addr     : in bit_2;
            dm_sel_in       : in bit_2;
            dm_write        : in bit_1;
            ir_fetch_start  : in bit_1;
            rf_sel_in       : in bit_3;
            rf_write_flag   : in bit_1;
            pc_write_flag   : in bit_1;
            pc_mode         : in bit_2;
            alu_clr_z_flag  : in bit_1;
            alu_operation   : in bit_3;
            alu_sel_op1     : in bit_2;
            alu_sel_op2     : in bit_1;
            dpcr_write_flag : in bit_1;
            dpcr_sel        : in bit_1;
            sop_write       : in bit_1;
            alu_z_flag      : out bit_1;
            alu_result      : out bit_16;
            ir_opcode       : out bit_8;
            inst_fetched    : out bit_1;
            rz_empty        : out bit_1;
            -- Debug Signals
            debug_pc_out        : out bit_15;
            debug_fetch_state   : out bit_2;
            debug_instruction   : out bit_32
        );
    end component;

    component control_unit is
        port (
            clk             : in bit_1;
            reset           : in bit_1;
            dm_sel_addr     : out bit_2;
            dm_sel_in       : out bit_2;
            dm_write        : out bit_1;
            ir_fetch_start  : out bit_1;
            rf_sel_in       : out bit_3;
            rf_write_flag   : out bit_1;
            pc_write_flag   : out bit_1;
            pc_mode         : out bit_2;
            alu_clr_z_flag  : out bit_1;
            alu_operation   : out bit_3;
            alu_sel_op1     : out bit_2;
            alu_sel_op2     : out bit_1;
            dpcr_write_flag : out bit_1;
            dpcr_sel        : out bit_1;
            sop_write       : out bit_1;
            alu_z_flag      : in bit_1;
            alu_result      : in bit_16;
            ir_opcode       : in bit_8 := (others => '0');
            inst_fetched    : in bit_1;
            rz_empty        : in bit_1;
            -- Debug Signals
            debug_state         : out bit_2;
            debug_next_state    : out bit_2
        );
    end component;

begin
    -- Datapath Instance
    impl_datapath: datapath
        port map (
            clk             => clk,
            reset           => reset,
            dm_sel_addr     => dm_sel_addr,
            dm_sel_in       => dm_sel_in,
            dm_write        => dm_write,
            ir_fetch_start  => ir_fetch_start,
            rf_sel_in       => rf_sel_in,
            rf_write_flag   => rf_write_flag,
            pc_write_flag   => pc_write_flag,
            pc_mode         => pc_mode,
            alu_clr_z_flag  => alu_clr_z_flag,
            alu_operation   => alu_operation,
            alu_sel_op1     => alu_sel_op1,
            alu_sel_op2     => alu_sel_op2,
            dpcr_write_flag => dpcr_write_flag,
            dpcr_sel        => dpcr_sel,
            sop_write       => sop_write,
            alu_z_flag      => alu_z_flag,
            alu_result      => alu_result,
            ir_opcode       => ir_opcode,
            inst_fetched    => inst_fetched,
            rz_empty        => rz_empty,
            -- Debug Signals
            debug_pc_out    => debug_pc_out,
            debug_fetch_state => debug_fetch_state,
            debug_instruction => debug_instruction
        );

    -- Control Unit Instance
    impl_control_unit: control_unit
        port map (
            clk             => clk,
            reset           => reset,
            dm_sel_addr     => dm_sel_addr,
            dm_sel_in       => dm_sel_in,
            dm_write        => dm_write,
            ir_fetch_start  => ir_fetch_start,
            rf_sel_in       => rf_sel_in,
            rf_write_flag   => rf_write_flag,
            pc_write_flag   => pc_write_flag,
            pc_mode         => pc_mode,
            alu_clr_z_flag  => alu_clr_z_flag,
            alu_operation   => alu_operation,
            alu_sel_op1     => alu_sel_op1,
            alu_sel_op2     => alu_sel_op2,
            dpcr_write_flag => dpcr_write_flag,
            dpcr_sel        => dpcr_sel,
            sop_write       => sop_write,
            alu_z_flag      => alu_z_flag,
            alu_result      => alu_result,
            ir_opcode       => ir_opcode,
            inst_fetched    => inst_fetched,
            rz_empty        => rz_empty,
            -- Debug Signals
            debug_state     => debug_state,
            debug_next_state => debug_next_state
        );
    -- Simulated Clock Process
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
    end process;

    -- Simulated Reset Process
    reset_process : process
    begin
        reset <= '1';
        wait for 10 ns;
        reset <= '0';
        wait;
    end process;
end combined;
