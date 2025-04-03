library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library lpm;
use lpm.lpm_components.all;

use work.micore_types.all;
use work.various_constants.all;
use work.ram_constants.all;

entity datapath is
	port (
		clk: in bit_1;
		-- data memory lines,
		din: in bit_16;
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
end datapath;

architecture combined of datapath is

	-- internal buses and signals
	signal pc_hold, ar_hold: bit_16;
	signal sp_hold, sor_hold: bit_16;
	signal ir_hold: bit_32;
	signal pc_add_out: bit_16;
	signal sp_op_out: bit_16;
	signal absout: bit_16;
	signal result: bit_16;
	signal alu_ain, alu_bin: bit_16;
	signal aluout: bit_16;
	signal rx, ry: bit_16;
	signal z1, c1, v1, n1: bit_1;
	signal ipm_out, pm_out: bit_32;
	signal idm_out, dm_out: bit_16;
	signal dm_in, dm_adr: bit_16;
	signal pc_in, rf_in, sp_in: bit_16;
	signal sor_en: bit_1;
	signal mem_clk: bit_1;

	-- register file component
	component regfile is
		generic (wid: integer range 1 to 3 := 2);
		port (
			clk: in std_logic;
			ld_r: in std_logic;
			sel_z: integer range 0 to 2**(wid+1)-1;
			sel_x: integer range 0 to 2**(wid+1)-1;
			sel_y: integer range 0 to 2**(wid+1)-1;
			x, y: out std_logic_vector(15 downto 0);
			z: in std_logic_vector(15 downto 0)
			);
	end component;
	
begin

	---------------------------------------
	-- ALU declarations
	---------------------------------------

	-- instance of program counter adder
	pc_adder: lpm_add_sub
	generic map (
		lpm_width => ram_data_width,
		lpm_representation => "UNSIGNED"
	)
	PORT MAP (
		dataa => pc_hold,
		datab => X"0001",
		result => pc_add_out
	);
	
	-- instance of stack pointer add & sub
	sp_add_sub: lpm_add_sub
	generic map (
		lpm_width => ram_data_width,
		lpm_representation => "UNSIGNED"
	)
	port map (
		dataa => sp_hold,
		add_sub => sp_op_sel,
		datab => X"0001",
		result => sp_op_out
	);

	-- instance of adder/subtractor - alu_sel(0) select
	add_sub: lpm_add_sub
	generic map (
		lpm_width => ram_data_width,
		lpm_representation => "SIGNED"
	)
	port map (
		dataa => alu_ain,
		datab => alu_bin,
		add_sub => alu_sel(0),
		result => result,
		overflow => c1
	);

	-- instance of abs			
	abs_m: lpm_abs
	generic map (
		lpm_width => ram_data_width
	)
	port map (
		data => alu_ain,
		result => absout
	);
	
	-- internal ALU
	alu: process (alu_sel, alu_ain, alu_bin, result, absout)
	begin
		case alu_sel is
			when addd =>
				aluout <= result;
			when subb =>
				aluout <= result;
			when andd =>
				aluout <= alu_ain and alu_bin;
			when orrr =>
				aluout <= alu_ain or alu_bin;
			when xoro =>
				aluout <= alu_ain xor alu_bin;				
			when cmpl => -- complement
				aluout <= not(alu_ain);
			when absv => -- absolute
				aluout <= absout;
			when lshf =>
				aluout(15 downto 1) <= alu_ain(14 downto 0);
				aluout(0) <= '0';
			when rshf =>
				aluout(14 downto 0) <= alu_ain(15 downto 1);
				aluout(15) <= '0';
			when lrtr =>
				aluout(15 downto 1) <= alu_ain(14 downto 0);
				aluout(0) <= alu_ain(15);
			when rrtr =>
				aluout(14 downto 0) <= alu_ain(15 downto 1);
				aluout(15) <= alu_ain(0);
			when others =>
				aluout <= X"0000";
		end case;
	end process alu;
	
	-- ALU zero flag
	z1gen: process (aluout)
	begin
		-- generate of z condition bit
		if aluout(15 downto 8) = X"00" and 
			aluout(7 downto 0) = X"00" then
			z1 <= '1';
		else
			z1 <= '0';
		end if;
	end process z1gen;
	
	-- ALU negative flag
	n1gen: process (aluout)
	begin
		-- generate of negative condition bit
		if aluout(15) = '1' then
			n1 <= '1';
		else
			n1 <= '0';
		end if;
	end process n1gen;

	---------------------------------------
	-- memory declarations 
	---------------------------------------	

	-- instance of internal RAM
	int_ram: lpm_ram_dq
		generic map (
			lpm_widthad => ram_addr_width,
			lpm_width => ram_data_width,
			lpm_indata => "REGISTERED",
			lpm_outdata => "UNREGISTERED",
			lpm_address_control => "REGISTERED",
			lpm_file => "int_ram.hex"
			)
		port map (
			data => dm_in, 
			inclock => mem_clk,
			address => ar_hold(9 downto 0),
			we => we,
			q => idm_out
			);

	-- instance of internal ROM			  
	int_rom: lpm_rom
		generic map (
			lpm_widthad => rom_addr_width,
			lpm_width => rom_data_width,
			lpm_outdata => "UNREGISTERED",
			lpm_address_control => "UNREGISTERED",
			lpm_file => "int_rom.hex"
			)
		port map (
			address => pc_hold(9 downto 0),
			q => ipm_out
			);

	---------------------------------------
	-- register declarations
	---------------------------------------	

	-- instance of register file
	reg_file: regfile
	generic map (wid => 2)
	port map (
		clk => clk,
		ld_r => ld_rf,
		sel_z => CONV_INTEGER(ir_hold(8 downto 6)),
		sel_x => CONV_INTEGER(ir_hold(2 downto 0)),
		sel_y => CONV_INTEGER(ir_hold(5 downto 3)),
		x => rx,
		y => ry,
		z => rf_in
	);
	
	-- program counter
	pc: process (clk)
	begin
		if (clk'event and clk = '1') then
			if init_up = '1' then
				pc_hold <= X"0000";
			elsif ld_pc = '1' then
				pc_hold <= pc_in;
			end if;
		end if;
	end process pc;

	-- memory address register
	areg: process (clk)
	begin
		if (clk'event and clk = '1') then
			if ld_ar = '1' then
				ar_hold <= dm_adr;
			end if;
		end if;
	end process areg;

	-- instruction register
	ireg: process (clk)
	begin
		if (clk'event and clk = '1') then
			if ld_ir = '1' then
				ir_hold <= pm_out;
			end if;
		end if;
	end process ireg;
	
	-- stack pointer register
	spreg: process (clk)
	begin
		if (clk'event and clk = '1') then
			if init_up = '1' then
				-- start position of stack pointer
				sp_hold <= X"01FF"; 
			elsif ld_sp = '1' then
				sp_hold <= sp_in;
			end if;
		end if;
	end process spreg;

	-- signal output register
	soreg: process (clk)
	begin
		if (clk'event and clk = '1') then
			if init_up = '1' then
				sor_hold <= X"0000"; 
			elsif sor_en = '1' then
				sor_hold <= dm_in;
			end if;
		end if;
	end process soreg;

	-- conditional code bits stored in individual flip-flops
	ccr: process (clk)
	begin
		if (clk'event and clk='1') then
			if clr_z = '1' then
				zout <= '0';
			elsif ld_z = '1' then
				zout <= z1;
			end if;
			
			if clr_c = '1' then
				cout <= '0';
			elsif ld_c = '1' then
				cout <= c1; -- from the LPM module
			end if;
			
			if clr_v = '1' then
				vout <= '0';
			elsif ld_v = '1' then
				vout <= v1;
			end if;
			
			if clr_n = '1' then
				nout <= '0';
			elsif ld_n = '1' then
				nout <= n1;
			end if;
		end if;
	end process ccr;

	---------------------------------------
	-- interconnection declarations
	---------------------------------------	

	-- shared bus
	dout <= dm_in;
	addr <= ar_hold;
	paddr <= pc_hold;
	v1 <= c1; -- overflow is same as carry
	opcode <= ir_hold(31 downto 21);
	sor <= sor_hold;
	sor_en <= '1' when ar_hold = X"FFFF" and we = '1' else '0';
	mem_clk <= not clk;

	-- program counter (pc) input multiplexer
	pc_in <= ir_hold(24 downto 9) when pc_in_sel = selir2pc else
			 dm_out when pc_in_sel = seldm2pc else
			 pc_add_out when pc_in_sel = selinc2pc else
			 ry when pc_in_sel = selry2pc else
			 pc_add_out;

	-- register file (rf) input multiplexer
	rf_in <= ir_hold(24 downto 9) when rf_in_sel = selir2rf else
			 dm_out when rf_in_sel = seldm2rf else
			 rx when rf_in_sel = selx2rf else
			 aluout when rf_in_sel = selalu2rf else
			 aluout;

	-- stack pointer (sp) input multiplexer
	sp_in <= ir_hold(24 downto 9) when sp_in_sel = selir2sp else
			 sp_op_out when sp_in_sel = selspop2sp else
			 dm_out when sp_in_sel = seldm2sp else
			 sp_op_out;

	-- address register (ar) input multiplexer
	dm_adr <= ir_hold(24 downto 9) when dm_adr_sel = selir2adr else
			  sp_hold when dm_adr_sel = selsp2adr else
			  sp_op_out when dm_adr_sel = selspop2adr else
			  ry when dm_adr_sel = selry2adr else
			  ir_hold(24 downto 9);

	-- data memory (dm) input multiplexer
	dm_in <= ir_hold(24 downto 9) when dm_in_sel = selir2dm else
			 pc_hold when dm_in_sel = selpc2dm else
			 rx when dm_in_sel = selrx2dm else
			 ir_hold(24 downto 9);

	-- ALU a input multiplexer
	alu_ain <= rx when alu_ain_sel = selx2alua else
			   ry when alu_ain_sel = sely2alua else
			   rx;

	-- ALU b input multiplexer
	alu_bin <= ir_hold(24 downto 9) when alu_bin_sel = selir2alub else
			   ry when alu_bin_sel = sely2alub else
			   ry;

	-- internal & external data memory (dm) output multiplexer
	dm_out <= idm_out when ar_hold(15 downto 10) = "000000" else
			  sir when ar_hold = X"FFFF" else
			  din;

	-- internal & external program memory (pm) output multiplexer
	pm_out <= ipm_out when pm_sel = int_pm else
			  pdin when pm_sel = ext_pm else
			  ipm_out;

end combined;