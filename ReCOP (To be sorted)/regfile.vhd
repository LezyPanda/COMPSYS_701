-- Zoran Salcic

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.recop_types.all;
use work.various_constants.all;

entity regfile is
	port (
		clk: in bit_1;
		init: in bit_1;
		-- control signal to allow data to write into Rz
		ld_r: in bit_1;
		-- Rz and Rx select signals
		sel_z: in integer range 0 to 15;
		sel_x: in integer range 0 to 15;
		-- register data outputs
		rx : out bit_16;
		rz: out bit_16;
		-- select signal for input data to be written into Rz
		rf_input_sel: in bit_3;
		-- input data
		ir_operand: in bit_16;
		dm_out: in bit_16;
		aluout: in bit_16;
		rz_max: in bit_16;
		sip_hold: in bit_16;
		er_temp: in bit_1;
		-- R7 for writing to lower byte of dpcr
		r7 : out bit_16;
		dprr_res : in bit_1;
		dprr_res_reg : in bit_1;
		dprr_wren : in bit_1;
		
		
		-- Debug Signals, maybe replace with dprr, idk
		debug_all_regs : out reg_array;
		debug_rf_reg_listen: in integer range 0 to 15;
		debug_rf_reg_result: out bit_16
	);
end regfile;

architecture beh of regfile is
	signal regs: reg_array;
	signal data_input_z: bit_16;
begin
	r7 <=regs(7);

	-- mux selecting input data to be written to Rz
	input_select: process (rf_input_sel, ir_operand, dm_out, aluout, rz_max, sip_hold, er_temp, dprr_res_reg)
    begin
        case rf_input_sel is
            when rf_sel_in_value =>
                data_input_z <= ir_operand;
			when rf_sel_in_dprr =>
				data_input_z <= X"000"&"000"&dprr_res_reg;
            when rf_sel_in_alu =>
                data_input_z <= aluout;
            when rf_sel_in_rz_max =>
                data_input_z <= rz_max;
            when rf_sel_in_sip =>
                data_input_z <= sip_hold;
            when rf_sel_in_er =>
                data_input_z <= X"000"&"000"&er_temp;
            when rf_sel_in_dm =>
                data_input_z <= dm_out;
            when others =>
                data_input_z <= X"0000";
        end case;
    end process input_select;
	
	process (clk, init)
	begin
		if init = '1' then
			regs<=((others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'));
		elsif rising_edge(clk) then
			-- write data into Rz if ld signal is asserted
			if ld_r = '1' then
				regs(sel_z) <= data_input_z;
			elsif dprr_wren = '1' then
				regs(0) <= X"000"&"000"&dprr_res;
			end if;
		end if;
	end process;
	debug_all_regs <= regs;
	debug_rf_reg_result <= regs(debug_rf_reg_listen);

	rx <= regs(sel_x);
	rz <= regs(sel_z);

end beh;
