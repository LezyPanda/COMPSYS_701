library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.micore_types.all;

entity micore is
	port(
		-- system signals
		clk: in bit_1;
		rst_l: in bit_1;
		-- external data bus signals
		din: in bit_16;
		dout: out bit_16;
		-- external data address bus signals
		addr: out bit_16;
		-- memory control signals
		wr: out bit_1;
		-- exteral program memory signals
		pdin: in bit_32;
		paddr: out bit_16;
		pm_sel: in bit_1;
		-- signal input & output
		sir: in bit_16;
		sor: out bit_16
		);
end micore;

architecture beh of micore is

	component controlunit
	port (
		clk, rst_l: in bit_1;
		-- write signal
		we: out bit_1;
		-- signals from data path
		opcode: in bit_11;
		zout, cout, vout, nout: in bit_1;
		-- control of multiplexers and alu
		pc_in_sel: out bit_2;
		rf_in_sel: out bit_2;
		sp_in_sel: out bit_2;
		dm_in_sel: out bit_2;
		dm_adr_sel: out bit_2;
		alu_ain_sel: out bit_1;
		alu_bin_sel: out bit_1;
		-- ALU operation selection
		alu_sel: out bit_4;
		-- SP add/sub operation selection
		sp_op_sel: out bit_1; -- increment or decrement sp
		-- control of datapath
		init_up: out bit_1; -- uP initialisation
		ld_pc: out bit_1; -- load program counter
		ld_ar: out bit_1; -- load memory address register
		ld_ir: out bit_1; -- load instruction register
		ld_sp: out bit_1; -- load stack pointer register
		ld_rf: out bit_1; -- load register file
		-- control of condition bits
		clr_c, clr_z, clr_v, clr_n: out bit_1;
		ld_c, ld_z, ld_v, ld_n: out bit_1
		);
	end component;
	
	component datapath
	port (
		clk: in bit_1;
		-- data memory lines,
		din : in bit_16;
		dout: out bit_16; 
		addr: out bit_16;
		-- program memory lines
		pdin: in bit_32;
		paddr: out bit_16;
		pm_sel: in bit_1; -- select internal or external
		-- write control signal
		we: in bit_1;
		-- opcode to control unit
		opcode: out bit_11;
		-- outputs from condition code bits to control unit
		zout, cout, vout, nout: out bit_1;
		-- inputs from control unit
		-- multiplexers select lines
		pc_in_sel: in bit_2;
		rf_in_sel: in bit_2;
		sp_in_sel: in bit_2;
		dm_in_sel: in bit_2;
		dm_adr_sel: in bit_2;
		alu_ain_sel: in bit_1;
		alu_bin_sel: in bit_1;
		-- ALU operation selection
		alu_sel: in bit_4;
		-- SP add/sub operation selection
		sp_op_sel: in bit_1; -- increment or decrement sp
		-- inputs from control unit that control
		-- individual resources
		init_up: in bit_1; -- uP initialisation signal
		ld_pc: in bit_1; -- PC 
		ld_ar: in bit_1; -- memory address register
		ld_ir: in bit_1; -- instruction register
		ld_sp: in bit_1; -- stack pointer register
		ld_rf: in bit_1; -- load register file
		-- control inputs to condition code bits
		clr_c, clr_z, clr_v, clr_n: in bit_1;
		ld_c, ld_z, ld_v, ld_n: in bit_1;
		-- signal input & output
		sir: in bit_16; -- Addr $FFFF
		sor: out bit_16 -- Addr $FFFF
		);
	end component;
	
	-- data memory write
	signal we: bit_1;
	-- Upper 7 bits of IR are opcodes
	signal opcode: bit_11;
	-- condition code bits
	signal zout, cout, vout, nout: bit_1;
	-- control of multiplexers and alu
	signal pc_in_sel: bit_2;
	signal rf_in_sel: bit_2;
	signal sp_in_sel: bit_2;
	signal dm_in_sel: bit_2;
	signal dm_adr_sel: bit_2;
	signal alu_ain_sel: bit_1;
	signal alu_bin_sel: bit_1;
	signal alu_sel: bit_4;
	signal sp_op_sel: bit_1;
	-- microprocessor initialisation
	signal init_up: bit_1;
	-- program counter control
	signal ld_pc: bit_1;
	-- address register control
	signal ld_ar: bit_1;
	-- instruction register control
	signal ld_ir: bit_1;
	-- stack pointer control
	signal ld_sp: bit_1;
	-- register file selection
	signal ld_rf: bit_1;
	-- control of condition bits
	signal clr_c, clr_z, clr_v, clr_n: bit_1;
	signal ld_c, ld_z, ld_v, ld_n: bit_1;

begin

	CU1: controlunit port map(
		clk, rst_l, we, opcode, zout, cout, vout, nout,
		pc_in_sel, rf_in_sel, sp_in_sel, dm_in_sel,
		dm_adr_sel, alu_ain_sel, alu_bin_sel,
		alu_sel, sp_op_sel, init_up, ld_pc, ld_ar,
		ld_ir, ld_sp, ld_rf, clr_c, clr_z, clr_v,
		clr_n, ld_c, ld_z, ld_v, ld_n
		);

	DP1: datapath port map(
		clk, din, dout, addr, pdin, paddr, pm_sel,
		we, opcode, zout, cout, vout, nout,
		pc_in_sel, rf_in_sel, sp_in_sel, dm_in_sel,
		dm_adr_sel, alu_ain_sel, alu_bin_sel,
		alu_sel, sp_op_sel, init_up, ld_pc, ld_ar,
		ld_ir, ld_sp, ld_rf, clr_c, clr_z, clr_v,
		clr_n, ld_c, ld_z, ld_v, ld_n, sir, sor
		);

	wr <= we;

end beh;