-- Zoran Salcic

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.recop_types.all;
use work.opcodes.all;
use work.various_constants.all;

entity recop_tb2 is
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
    signal debug_prog_mem_in    : bit_15;
    signal debug_prog_mem_out   : bit_16;
    signal debug_data_mem_in_addr : bit_12;
    signal debug_data_mem_in_data : bit_16;
    signal debug_data_mem_out   : bit_16;
    signal debug_rx_addr        : bit_4;
    signal debug_rz_addr        : bit_4;
    signal debug_rx_value       : bit_16;
    signal debug_rz_value       : bit_16;
    signal debug_ir_operand     : bit_16;
    signal debug_rf_reg_listen  : integer range 0 to 15;
    signal debug_rf_reg_result  : bit_16;
    signal debug_flag           : bit_8;
    signal debug_inst_raw_1     : bit_16;
    signal debug_inst_raw_2     : bit_16;
    signal debug_all_regs       : reg_array;
    -- Debug Signals CU
    signal debug_state          : bit_2;
    signal debug_next_state     : bit_2;


    signal temp                 : bit_4 := "0011";

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
            debug_instruction   : out bit_32;
            debug_prog_mem_in   : out bit_15;
            debug_prog_mem_out  : out bit_16;
            debug_data_mem_in_addr    : out bit_12;
            debug_data_mem_in_data    : out bit_16;
            debug_data_mem_out  : out bit_16;
            debug_rx_addr       : out bit_4;
            debug_rz_addr       : out bit_4;
            debug_rx_value      : out bit_16;
            debug_rz_value      : out bit_16;
            debug_ir_operand    : out bit_16;
            debug_rf_reg_listen : in integer range 0 to 15;
            debug_rf_reg_result : out bit_16;
            debug_flag          : out bit_8;
            debug_inst_raw_1    : out bit_16;
            debug_inst_raw_2    : out bit_16;
            debug_all_regs      : out reg_array
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
            debug_instruction => debug_instruction,
            debug_prog_mem_in => debug_prog_mem_in,
            debug_prog_mem_out => debug_prog_mem_out,
            debug_data_mem_in_addr => debug_data_mem_in_addr,
            debug_data_mem_in_data => debug_data_mem_in_data,
            debug_data_mem_out => debug_data_mem_out,
            debug_rx_addr   => debug_rx_addr,
            debug_rz_addr   => debug_rz_addr,
            debug_rx_value  => debug_rx_value,
            debug_rz_value  => debug_rz_value,
            debug_ir_operand => debug_ir_operand,
            debug_rf_reg_listen => debug_rf_reg_listen,
            debug_rf_reg_result => debug_rf_reg_result,
            debug_flag      => debug_flag,
            debug_inst_raw_1 => debug_inst_raw_1,
            debug_inst_raw_2 => debug_inst_raw_2,
            debug_all_regs  => debug_all_regs
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

    -- Test
    debug_rf_reg_listen <= to_integer(unsigned(temp));


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
