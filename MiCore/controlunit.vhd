library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.micore_types.all;
use work.various_constants.all;
use work.opcodes.all;

entity controlunit is
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
end controlunit;

architecture combined of controlunit is
	type state_type is (T0, T1, T2);
	signal state, next_state: state_type;
	signal clr_pd, ena_pd: bit_1; -- control of pulse distributor
begin

	---------------------------------------
	-- reset circuitry
	---------------------------------------
	resetcircuit: process (clk, rst_l)
		variable mrs: bit_2 := "00"; -- bit of internal counter
		variable sr: bit_1; -- internal state flipflop
	begin
		if (clk'event and clk = '1') then
			if (rst_l = '0') then
				sr := '1';
				ena_pd <= '0';
				clr_pd <= '1';
			elsif rst_l = '1' and mrs = "11" then
				sr := '0';
				ena_pd <= '1';
				clr_pd <= '0';
			end if;
			
			if sr = '1' then
				mrs := mrs + 1;
				init_up <= '1';
			else
				mrs := mrs;
				init_up <= '0';
			end if;
		end if;
	end process resetcircuit;

	---------------------------------------
	-- pulse distributor
	---------------------------------------
	pulsedistributor: process (clk)
	begin
		-- internal 2-bit counter
		if (clk'event and clk = '1') then
			if clr_pd = '1' then
				state <= T0;
			elsif ena_pd = '1' then
				state <= next_state;
			end if;
		end if;
	end process pulsedistributor;

	---------------------------------------
	-- operation decoder circuit
	---------------------------------------
	opdec: process(state, opcode, cout, zout, vout, nout)
	begin

		ld_pc <= '0'; ld_ar <= '0'; 
		ld_ir <= '0'; ld_sp <= '0';
		ld_rf <= '0'; we <= '0';
		clr_c <= '0'; clr_z <= '0';
		clr_v <= '0'; clr_n <= '0';
		ld_c <= '0'; ld_z <= '0';
		ld_v <= '0'; ld_n <= '0';

		--be added to eliminate the glitches
		pc_in_sel<=selinc2pc;
		rf_in_sel<=selalu2rf;
		sp_in_sel<=seldm2sp;
		dm_adr_sel<=selir2adr;
		dm_in_sel<=selir2dm;
		alu_ain_sel<=selx2alua;
		alu_bin_sel<=sely2alub;
		alu_sel<=addd;
		sp_op_sel<=inc_sp;

		case state is
			-- T01: fetch instruction from program memory (pm)
			when T0 =>
				next_state <= T1;
				-- ir <- pm 
				ld_ir <= '1';
				-- pc <- pc + 1
				pc_in_sel <= selinc2pc;
				ld_pc <= '1';

			-- T1: decoding instruction
			when T1 =>
				next_state <= T2;
				-- detect addressing mode and prepare for execution
				case opcode(10 downto 9) is
					when stack => -- stack addressing
						if opcode(7) = '0' then
							-- push type operation
							dm_adr_sel <= selsp2adr;
							sp_in_sel <= selspop2sp;
							sp_op_sel <= dec_sp;
							ld_sp <= '1';
						else
							-- pull type operation
							dm_adr_sel <= selspop2adr;
							sp_in_sel <= selspop2sp;
							sp_op_sel <= inc_sp;
							ld_sp <= '1';
						end if;
						-- push: ar <- sp, pull: ar <- sp + 1
						ld_ar <= '1';
					when indirect => -- register indirect addressing
						-- ar <- Ry
						dm_adr_sel <= selry2adr;
						ld_ar <= '1';
					when direct => -- direct addressing
						-- ar <- ir[24..9]
						dm_adr_sel <= selir2adr;
						ld_ar <= '1';
					when others => -- inherent and immediate
						-- do nothing
				end case;
			-- T2: execution			
			when T2 =>
				next_state <= T0;
				if opcode(10 downto 9) = stack then
					case opcode(8 downto 4) is		
						when pul =>
							-- Rz <- dm
							rf_in_sel <= seldm2rf;
							ld_rf <= '1';
						when psh =>
							-- dm <- Rx
							dm_in_sel <= selrx2dm;
							we <= '1';
						when ret =>
							-- pc <- dm  
							pc_in_sel <= seldm2pc;
							ld_pc <= '1';
						when jsr =>
							-- dm <- pc
							dm_in_sel <= selpc2dm;
							we <= '1';
							-- pc <- ir[24..9]
							pc_in_sel <= selir2pc;
							ld_pc <= '1';
						when others =>
							-- should be invalid instruction code
					end case;

				elsif opcode(10 downto 9) = direct then
					case opcode(8 downto 4) is
						when ldr =>
							rf_in_sel <= seldm2rf;
							ld_rf <= '1';
						when str =>
							dm_in_sel <= selrx2dm;
							we <= '1';
						when ldsp =>
							sp_in_sel <= seldm2sp;
							ld_sp <= '1';
						when others =>
							-- should be invalid instruction code
					end case;
					
				elsif opcode(10 downto 9) = indirect then
					case opcode(8 downto 4) is
						when ldr =>
							rf_in_sel <= seldm2rf;
							ld_rf <= '1';
						when str =>
							dm_in_sel <= selrx2dm;
							we <= '1';
						when strv =>
							dm_in_sel <= selir2dm;
							we <= '1';
						when others =>
							-- should be invalid instruction code
					end case;

				elsif opcode(10 downto 9) = implicit then
					case opcode(8 downto 4) is
						-- immediate AM
						when ldr =>
							rf_in_sel <= selir2rf;
							ld_rf <= '1';
						when ldsp =>
							sp_in_sel <= selir2sp;
							ld_sp <= '1';
						when jmp =>
							pc_in_sel <= selir2pc;
							ld_pc <= '1';
						when jmpr =>
							pc_in_sel <= selry2pc;
							ld_pc <= '1';
						-- inherent AM
						when addr =>
							-- (1) choose ALU operation
							alu_sel <= addd;
							-- (2) choose ALU inputs
							alu_ain_sel <= selx2alua;
							alu_bin_sel <= sely2alub;
							-- (3) rf <- ALU
							rf_in_sel <= selalu2rf;
							ld_rf <= '1';
							-- (4) set flags
							ld_c <= '1';
							ld_z <= '1';
							ld_v <= '1';
							ld_n <= '1';
						when addx =>
							alu_sel <= addd;
							alu_ain_sel <= selx2alua;
							alu_bin_sel <= selir2alub;
							rf_in_sel <= selalu2rf;
							ld_rf <= '1';
							ld_c <= '1';
							ld_z <= '1';
							ld_v <= '1';
							ld_n <= '1';
						when subr =>
							alu_sel <= subb;
							alu_ain_sel <= selx2alua;
							alu_bin_sel <= sely2alub;
							rf_in_sel <= selalu2rf;
							ld_rf <= '1';
							ld_c <= '1';
							ld_z <= '1';
							ld_v <= '1';
							ld_n <= '1';
						when subx =>
							alu_sel <= subb;
							alu_ain_sel <= selx2alua;
							alu_bin_sel <= selir2alub;
							rf_in_sel <= selalu2rf;
							ld_rf <= '1';
							ld_c <= '1';
							ld_z <= '1';
							ld_v <= '1';
							ld_n <= '1';
						when andr =>
							alu_sel <= andd;
							alu_ain_sel <= selx2alua;
							alu_bin_sel <= sely2alub;
							rf_in_sel <= selalu2rf;
							ld_rf <= '1';
							ld_z <= '1';
						when andx =>
							alu_sel <= andd;
							alu_ain_sel <= selx2alua;
							alu_bin_sel <= selir2alub;
							rf_in_sel <= selalu2rf;
							ld_rf <= '1';
							ld_z <= '1';
						when orr =>
							alu_sel <= orrr;
							alu_ain_sel <= selx2alua;
							alu_bin_sel <= sely2alub;
							rf_in_sel <= selalu2rf;
							ld_rf <= '1';
							ld_z <= '1';
						when orx =>
							alu_sel <= orrr;
							alu_ain_sel <= selx2alua;
							alu_bin_sel <= selir2alub;
							rf_in_sel <= selalu2rf;
							ld_rf <= '1';
							ld_z <= '1';
						when xorr =>
							alu_sel <= xoro;
							alu_ain_sel <= selx2alua;
							alu_bin_sel <= sely2alub;
							rf_in_sel <= selalu2rf;
							ld_rf <= '1';
							ld_z <= '1';
						when xorx =>
							alu_sel <= xoro;
							alu_ain_sel <= selx2alua;
							alu_bin_sel <= selir2alub;
							rf_in_sel <= selalu2rf;
							ld_rf <= '1';
							ld_z <= '1';
						when cmp =>
							alu_sel <= cmpl;
							alu_ain_sel <= selx2alua;
							rf_in_sel <= selalu2rf;
							ld_rf <= '1';
						when lsh =>
							alu_sel <= lshf;
							alu_ain_sel <= selx2alua;
							rf_in_sel <= selalu2rf;
							ld_rf <= '1';
						when rsh =>
							alu_sel <= rshf;
							alu_ain_sel <= selx2alua;
							rf_in_sel <= selalu2rf;
							ld_rf <= '1';
						when lrt =>
							alu_sel <= lrtr;
							alu_ain_sel <= selx2alua;
							rf_in_sel <= selalu2rf;
							ld_rf <= '1';
						when rrt =>
							alu_sel <= rrtr;
							alu_ain_sel <= selx2alua;
							rf_in_sel <= selalu2rf;
							ld_rf <= '1';
						when absr =>
							alu_sel <= absv;
							alu_ain_sel <= selx2alua;
							rf_in_sel <= selalu2rf;
							ld_rf <= '1';
						when trf =>
							rf_in_sel <= selx2rf;
							ld_rf <= '1';
						when clrf =>
							-- clear carry
							if opcode(3) = '1' then
								clr_c <= '1';
							end if;
							-- clear zero
							if opcode(2) = '1' then
								clr_z <= '1';
							end if;
							-- clear overflow
							if opcode(1) = '1' then
								clr_v <= '1';
							end if;
							-- clear negative
							if opcode(0) = '1' then
								clr_n <= '1';
							end if;
						when skc =>
							if cout = '1' then
								ld_pc <= '1';
								pc_in_sel <= selir2pc;
							end if;
						when skz =>
							if zout = '1' then
								ld_pc <= '1';
								pc_in_sel <= selir2pc;
							end if;
						when skv =>
							if vout = '1' then
								ld_pc <= '1';
								pc_in_sel <= selir2pc;
							end if;
						when skn =>
							if nout = '1' then
								ld_pc <= '1';
								pc_in_sel <= selir2pc;
							end if;
						when noop =>
							-- do nothing
						when others =>
							-- should be invalid instruction code
					end case;
				end if;
		end case;
	end process opdec;	

end combined;	