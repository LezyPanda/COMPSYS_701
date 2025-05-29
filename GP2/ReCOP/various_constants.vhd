-- Zoran Salcic

library ieee;
use ieee.std_logic_1164.all;
use work.recop_types.all;

package various_constants is
	-- ALU operation selection alu_sel
	constant alu_add: bit_3 	:= "000";
	constant alu_sub: bit_3 	:= "001";
	constant alu_and: bit_3 	:= "010";
	constant alu_or: bit_3 		:= "011";
	constant alu_idle: bit_3 	:= "100";
	constant alu_max: bit_3 	:= "101";
	constant alu_hold: bit_3 	:= "110";

	constant alu_sel_op1_rx		: bit_2 := "00";
	constant alu_sel_op1_value	: bit_2 := "01";
	constant alu_sel_op1_direct	: bit_2 := "10";
	constant alu_sel_op1_other	: bit_2 := "11";

	constant alu_sel_op2_rx		: bit_1 := '0';
	constant alu_sel_op2_rz		: bit_1 := '1';

	-- program counter input selection pc_in_sel
	constant pc_mode_rx		: bit_2 := "00";
	constant pc_mode_incr_1 : bit_2 := "01";
	constant pc_mode_incr_2 : bit_2 := "10";
	constant pc_mode_value 	: bit_2 := "11";

	-- DataMem address select
	constant dm_sel_addr_value	: bit_2 := "00";
	constant dm_sel_addr_pc		: bit_2 := "01";
	constant dm_sel_addr_rx		: bit_2 := "10";
	constant dm_sel_addr_rz		: bit_2 := "11";

	-- DataMem input select
	constant dm_sel_in_value	: bit_2 := "00";
	constant dm_sel_in_pc		: bit_2 := "01";
	constant dm_sel_in_rx		: bit_2 := "10";

	-- register file input select
	constant rf_sel_in_value	: bit_3 := "000"; -- used
	constant rf_sel_in_dprr		: bit_3 := "001";
	constant rf_sel_in_alu		: bit_3 := "011"; -- used
	constant rf_sel_in_rz_max	: bit_3 := "100";
	constant rf_sel_in_sip		: bit_3 := "101"; --used
	constant rf_sel_in_er		: bit_3 := "110";
	constant rf_sel_in_dm		: bit_3 := "111"; -- used

	-- dpcr
	constant dpcr_r7 	: bit_1 := '0';
	constant dpcr_value	: bit_1 := '1';
	

	
end various_constants;	
