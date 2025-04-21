library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;

use work.recop_types.all;
use work.various_constants.all;
use work.opcodes.all;

entity datapath is
    port (
        -- Common
        clk     : in bit_1;
        reset   : in bit_1;

        -- DE1SoC Peripherals
        button  : in bit_4;
        sw      : in bit_10;

        -- Operation
        opcode          : out bit_8; -- AM(2) + OPCODE(6)
        rx              : out bit_16;
        rz              : out bit_16;
        alu_result      : in  bit_16;
        next_inst_addr  : out bit_16;

        -- Program Counter
        pc_mode : in  bit_2;
        pc_in   : in  bit_16;

        --      IDK WHAT THE FUCK THESE ARE
        -- Register Access
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

architecture behaviour of datapath is
    -- Components
    component prog_counter is
        port (
            clk     : in  bit_1;
            reset   : in  bit_1;
            pc_mode : in  bit_2;
            pc_in   : in  bit_16;
            pc_out  : out bit_16
        );
    end component;
    component memory is
        port (
            clk         : in  bit_1   := '0';
            --pm_rd: in bit_1 := '0';
            pm_address  : in  bit_16  := X"0000";
            pm_outdata  : out bit_16  := X"0000";
            
            --dm_rd: in bit_1 := '0';
            dm_address  : in  bit_16  := X"0000";
            dm_outdata  : out bit_16  := X"0000";
            
            dm_wr       : in  bit_1   := '0';
            dm_indata   : in  bit_16  := X"0000"
        );
    end component;
    component regfile is
        port (
            clk     : in bit_1;
            init    : in bit_1;
            -- control signal to allow data to write into Rz
            ld_r    : in bit_1;
            -- Rz and Rx select signals
            sel_z   : in integer range 0 to 15;
            sel_x   : in integer range 0 to 15;
            -- register data outputs
            rx      : out bit_16;
            rz      : out bit_16;
            -- select signal for input data to be written into Rz
            rf_input_sel: in bit_3;
            -- input data
            ir_operand  : in bit_16;
            dm_out      : in bit_16;
            aluout      : in bit_16;
            rz_max      : in bit_16;
            sip_hold    : in bit_16;
            er_temp     : in bit_1;
            -- R7 for writing to lower byte of dpcr
            r7              : out bit_16;
            dprr_res        : in  bit_1;
            dprr_res_reg    : in  bit_1;
            dprr_wren       : in  bit_1
        );
    end component;
    -- End Components

    -- Program Counter Signals
    signal pc_out   : bit_16    := X"0000";
    -- End Program Counter Signals

    -- Memory Model Signals
    signal pm_address:  bit_16 := X"0000";
    signal pm_outdata:  bit_16 := X"0000";
    signal dm_address:  bit_16 := X"0000";
    signal dm_outdata:  bit_16 := X"0000";
    signal dm_indata:   bit_16 := X"0000";
    signal dm_wr:       bit_1  := '0';
    -- End Memory Model Signals

    -- Register File Signals
    signal ld_r          : bit_1     := '0';
    signal sel_z         : integer range 0 to 15 := 0;
    signal sel_x         : integer range 0 to 15 := 0;
    signal rf_input_sel  : bit_3     := "000";
    signal ir_operand    : bit_16    := X"0000";
    signal dm_out        : bit_16    := X"0000";
    signal rz_max        : bit_16    := X"0000";
    signal sip_hold      : bit_16    := X"0000";
    signal er_temp       : bit_1     := '0';
    signal r7            : bit_16;
    signal dprr_res      : bit_1     := '0';
    signal dprr_res_reg  : bit_1     := '0';
    signal dprr_wren     : bit_1     := '0';
    -- End Register File Signals

    signal instruction : bit_32;
begin
    prog_counter_inst : prog_counter
        port map (
            clk     => clk,
            reset   => reset,
            pc_mode => pc_mode,
            pc_in   => pc_in,
            pc_out  => pc_out
        );
    memory_inst : memory
        port map (
            clk         => clk,
            pm_address  => pm_address,
            pm_outdata  => pm_outdata,
            dm_address  => dm_address,
            dm_outdata  => dm_outdata,
            dm_wr       => dm_wr,
            dm_indata   => dm_indata
        );
    regfile_inst : regfile
        port map (
            clk            => clk,
            init           => reset,
            ld_r           => ld_r,
            sel_z          => sel_z,
            sel_x          => sel_x,
            rx             => rx,
            rz             => rz,
            rf_input_sel   => rf_input_sel,
            ir_operand     => ir_operand,
            dm_out         => dm_out,
            aluout         => alu_result,
            rz_max         => rz_max,
            sip_hold       => sip_hold,
            er_temp        => er_temp,
            r7             => r7,
            dprr_res       => dprr_res,
            dprr_res_reg   => dprr_res_reg,
            dprr_wren      => dprr_wren
        );
    
    
    -- Decode Instruction
    opcode <= instruction(31 downto 24)

    next_inst_addr <= pc_out;

end behaviour;

