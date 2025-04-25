-- Zoran Salcic

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.recop_types.all;
use work.opcodes.all;
use work.various_constants.all;


entity recop is
	port (
		clk	    : in bit_1;
        reset   : in bit_1;
        key     : in bit_4;
        sw      : in bit_10;
        led     : out bit_10;
        hex0    : out bit_7;
        hex1    : out bit_7;
        hex2    : out bit_7;
        hex3    : out bit_7;
        hex4    : out bit_7;
        hex5    : out bit_7
	);
end recop;

architecture combined of recop is
    component datapath is
        port (
        -- Common
            clk     : in bit_1;
            reset   : in bit_1;

            -- Mux Control
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
            
            -- Out
            alu_z_flag      : out bit_1;
            alu_result      : out bit_16;
            ir_opcode       : out bit_8; -- AM(2) + OPCODE(6)
            inst_fetched    : out bit_1
        );
    end component datapath;
    signal dm_sel_addr     : bit_2;
    signal dm_sel_in       : bit_2;
    signal dm_write        : bit_1;
    signal ir_in           : bit_1;
    signal ir_fetch_start  : bit_1;
    signal rf_sel_in       : bit_3;
    signal rf_write_flag   : bit_1;
    signal dcpr_sel        : bit_1;
    signal sop_write       : bit_1;
    signal pc_write_flag   : bit_1;
    signal pc_mode         : bit_2;
    signal alu_clr_z_flag  : bit_1;
    signal alu_operation   : bit_3;
    signal alu_sel_op1     : bit_2;
    signal alu_sel_op2     : bit_1;
    signal alu_z_flag      : bit_1;
    signal alu_result      : bit_16;
    signal ir_opcode       : bit_8; -- AM(2) + OPCODE(6)
    signal inst_fetched    : bit_1;

    component
begin

end combined;
