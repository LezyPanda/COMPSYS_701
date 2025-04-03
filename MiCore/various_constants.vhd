library ieee;
use ieee.std_logic_1164.all;
use work.micore_types.all;

package various_constants is

-- program counter input selection pc_in_sel
	constant selir2pc: bit_2 := "00";
	constant seldm2pc: bit_2 := "01";
	constant selinc2pc: bit_2 := "10";
	constant selry2pc: bit_2 := "11";
	
-- register file input selection rf_in_sel
	constant selir2rf: bit_2 := "00";
	constant seldm2rf: bit_2 := "01";
	constant selx2rf: bit_2 := "10";
	constant selalu2rf: bit_2 := "11";

-- stack pointer input selection sp_in_sel
	constant selir2sp: bit_2 := "00";
	constant seldm2sp: bit_2 := "01";
	constant selspop2sp: bit_2 := "10";
	
-- stack point add/sub selection sp_op_sel
	constant inc_sp: bit_1 := '1';
	constant dec_sp: bit_1 := '0';
	
-- data memory address input select dm_adr_sel
	constant selir2adr: bit_2 := "00";
	constant selsp2adr: bit_2 := "01";
	constant selspop2adr: bit_2 := "10";
	constant selry2adr: bit_2 := "11";

-- data memory input selection dm_in_sel
	constant selir2dm: bit_2 := "00";
	constant selpc2dm: bit_2 := "01";
	constant selrx2dm: bit_2 := "10";
	
-- ALU a input selection alu_ain_sel
	constant selx2alua: bit_1 := '0';
	constant sely2alua: bit_1 := '1';
	
-- ALU b input selection alu_bin_sel
	constant sely2alub: bit_1 := '0';
	constant selir2alub: bit_1 := '1';

-- internal or external program memory selection pm_sel
	constant int_pm: bit_1 := '0';
	constant ext_pm: bit_1 := '1';
	
-- select ry selction sely_sel
	constant sely_pipe: bit_1 := '0';
	constant sely: bit_1 := '1';
	
-- ALU operation selection alu_sel
	constant subb: bit_4 := "0000";
	constant addd: bit_4 := "0001";
	constant andd: bit_4 := "0010";
	constant orrr: bit_4 := "0011";
	constant cmpl: bit_4 := "0100";
	constant absv: bit_4 := "0101";
	constant lshf: bit_4 := "0110";
	constant rshf: bit_4 := "0111";
	constant lrtr: bit_4 := "1000";
	constant rrtr: bit_4 := "1001";
	constant xoro: bit_4 := "1010";
	
end various_constants;	
