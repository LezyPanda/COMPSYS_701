library ieee;
use ieee.std_logic_1164.all;
use work.micore_types.all;

package opcodes is

-- instruction format
-- --------------------------------------------------
-- |AM(2)|OP(5)|ADDR/VAL/OTHERs(16)|Rz(3)|Ry(3)Rx(3)|
-- --------------------------------------------------


-- addressing modes (AM)
	constant implicit: bit_2 := "00"; --immediate & inherent
	constant stack: bit_2 := "01"; --stack & functional unit
	constant direct: bit_2 := "10";
	constant indirect: bit_2 := "11";

---------------
-- direct AM --
---------------
-- operations with immediate, direct and indirect AM
	-- immediate: LDR Rz #value
	-- direct: LDR Rz $address
	-- indirect: LDR Rz Ry
	constant ldr: bit_5 := "00000";
	
-- operations with direct and indirect AM
	-- direct: STR Rx $address
	-- indirect: STR Rx Ry
	constant str: bit_5 := "00001";
	
-- operations with immediate and direct AM
	-- immediate: LDSP #value
	-- direct: LDSP $address
	constant ldsp: bit_5 := "00010";
	
-----------------
-- indirect AM --
-----------------	
-- operations with immediate, direct and indirect AM
	-- immediate: LDR Rz #value
	-- direct: LDR Rz $address
	-- indirect: LDR Rz Ry
	--constant ldr: bit_5 := "00000";
	
-- operations with direct and indirect AM
	-- direct: STR Rx $address
	-- indirect: STR Rx Ry
	--constant str: bit_5 := "00001";		

-- operation with indirect AM
	-- STR Ry #value
	constant strv: bit_5 := "00010";

-------------------------------
-- immediate and inherent AM --
-------------------------------
-- operations with immediate, direct and indirect AM
	-- immediate: LDR Rz #value
	-- direct: LDR Rz $address
	-- indirect: LDR Rz Ry
	--constant ldr: bit_5 := "00000";

-- operations with immediate AM
	-- JMP #address 
	constant jmp: bit_5 := "00001";
	
-- operations with immediate and direct AM
	-- immediate: LDSP #value
	-- direct: LDSP $address
	--constant ldsp: bit_5 := "00010";	

-- operations with immediate AM
	-- JMP Ry 
	constant jmpr: bit_5 := "00011";

-- operations with inherent AM
-- don't use the opcodes that have been used by immediate AM
	constant addr: bit_5 := "00100"; -- ADD Rz Ry Rx
	constant addx: bit_5 := "00101"; -- ADD Rz Rx #value
	constant xorr: bit_5 := "00110"; -- XOR Rz Ry Rx
	constant xorx: bit_5 := "11001"; -- XOR Rz Rx #value
	constant subr: bit_5 := "00111"; -- SUB Rz Ry Rx
	constant subx: bit_5 := "01000"; -- SUB Rz Rx #value
	constant andr: bit_5 := "01001"; -- AND Rz Ry Rx
	constant andx: bit_5 := "01010"; -- AND Rz Rx #value
	constant orr:  bit_5 := "01011"; -- OR Rz Ry Rx
	constant orx:  bit_5 := "01100"; -- OR Rz Rx #value
	constant cmp:  bit_5 := "01101"; -- CMP Rz Rx (complement)
	constant lsh:  bit_5 := "01110"; -- lsh Rz Rx (left shift)
	constant rsh:  bit_5 := "01111"; -- rsh Rz Rx (right shift)
	constant lrt:  bit_5 := "10000"; -- lrt Rz Rx (left rotate)
	constant rrt:  bit_5 := "10001"; -- rrt Rz Rx (right rotate)
	constant absr: bit_5 := "10010"; -- abs Rz Rx (absolute)
	constant trf:  bit_5 := "10011"; -- trf Rz Rx (transfer)
	constant clrf: bit_5 := "10100"; -- clrf czvn
	constant skc:  bit_5 := "10101"; -- sc #address
	constant skz:  bit_5 := "10110"; -- sz #address
	constant skv:  bit_5 := "10111"; -- sv #address
	constant skn:  bit_5 := "11000"; -- sn #address
	constant noop: bit_5 := "11111"; -- noop

--------------------------------------------------------------	
-- operation with stack and functional unit addressing mode --
--------------------------------------------------------------
-- operation with stack and functional unit addressing mode
-- stack related opcodes start with 0
	-- PUL Rz
	constant pul:  bit_5 := "01000";
	-- PSH Rx
	constant psh:  bit_5 := "00001";
	-- RET
	constant ret:  bit_5 := "01010";
	-- JSR $address
	constant jsr:  bit_5 := "00011";
	
end opcodes;