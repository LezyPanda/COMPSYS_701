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
        -- To add segment displays...etc ??

        -- Mux Control
        dm_sel_addr     : in bit_2;
        dm_sel_in       : in bit_2;
        dm_write        : in bit_1;
        ir_in           : in bit_1; 
        pc_in           : in bit_2;
        rf_sel_in       : in bit_3;
        dcpr_sel        : in bit_1;
        sop_write       : in bit_1;
        reg_write       : in bit_1; 
        pc_write_flag   : in bit_1;
        pc_mode         : in bit_2;
        alu_clr_z_flag  : in bit_1;
        alu_operation   : in bit_3;
        alu_sel_op1     : in bit_1;
        alu_sel_op2     : in bit_1;
        
        -- Out
        alu_z_flag      : out bit_1;
        alu_result      : out bit_16
        ir_opcode       : out bit_8; -- AM(2) + OPCODE(6)
    );
end datapath;

architecture behaviour of datapath is
    -- Common Signals
    type fetchStatus is (IDLE, FETCH_1, FETCH_2, FETCH_3);
    signal fetch_state  : fetchStatus   := IDLE;
    signal fetch_inst_1 : bit_16        := X"0000";
    signal fetch_inst_2 : bit_16        := X"0000";
    signal rxAddr       : bit_4         := X"0";
    signal rzAddr       : bit_4;        := X"0";
    signal rxValue      : bit_16;       := X"0000";
    signal rzValue      : bit_16;       := X"0000";
    signal data_mem_out : bit_16;       := X"0000";
    signal ir_operand   : bit_16;       := X"0000";

    -- Components
    component alu is
        port (
            clk				: in bit_1;
            z_flag			: out bit_1;
            alu_operation	: in bit_3;
            alu_op1_sel		: in bit_2;
            alu_op2_sel		: in bit_1;
            alu_carry		: in bit_1;
            alu_result		: out bit_16;
            rx				: in bit_16;
            rz				: in bit_16;
            ir_operand		: in bit_16;
            clr_z_flag		: in bit_1;
            reset 			: in bit_1
        );
    end component;
    signal alu_result       : bit_16;

    component regfile is
        port (
            clk             : in bit_1;
            reset           : in bit_1;
            id_r            : in bit_1;
            sel_z           : in integer range 0 to 15;
            sel_x           : in integer range 0 to 15;
            rx              : out bit_16;
            rz              : out bit_16;
            rf_input_sel    : in bit_3;
            ir_operand      : in bit_16;
            dm_out          : in bit_16;
            aluout          : in bit_16;
            rz_max          : in bit_16;
            sip_hold        : in bit_16;
            er_temp         : in bit_1;
            r7              : out bit_16;
            dprr_res        : in bit_1;
            dprr_res_reg    : in bit_1;
            dprr_wren       : in bit_1
        );
    end component;
    signal rf_id_r      : bit_1;
    signal rf_sel_z     : integer range 0 to 15;
    signal rf_sel_x     : integer range 0 to 15;
    signal rf_input_sel : bit_3;
    signal rz_max       : bit_16;
    signal sip_hold     : bit_16;
    signal er_temp      : bit_1;
    signal r7           : bit_16;
    signal dprr_res     : bit_1;
    signal dprr_res_reg : bit_1;
    signal dprr_wren    : bit_1;

    component prog_counter is
        port (
            clk             : in  bit_1;
            reset           : in  bit_1;
            pc_write_flag   : in  bit_1;
            pc_mode         : in  bit_2;
            pc_in           : in  bit_16;
            pc_out          : out bit_15
        );
    end component;
    signal pc_in            : bit_15;
    signal pc_out           : bit_16;

    component inst_reg is
        port (
            clk         : in  bit_1;
            reset       : in  bit_1;
            instruction : in  bit_32;
            opcode      : out bit_8; -- AM(2) + OPCODE(6)
            rx          : out bit_16;
            rz          : out bit_16;
            operand     : out bit_16;
        );
    end component;

    component prog_mem is
        port
        (
            address : in bit_15;
            clock	: in bit_1 := '1';
            q		: out bit_16
        );
    end component;
    signal prog_mem_in  : bit_15;
    signal prog_mem_out : bit_16;

    component data_mem is
        port (
            address	: in bit_12;
            clock	: in bit_1;
            data	: in bit_16;
            wren	: in bit_1;
            q		: out bit_16
        );
    end component;
    signal data_mem_in_addr : bit_12;
    signal data_mem_in_data : bit_16;

    -- End Components
begin
    alu : alu
        port map (
            clk             => clk,
            z_flag          => alu_z_flag,
            alu_operation   => alu_operation,
            alu_op1_sel     => alu_op1_sel,
            alu_op2_sel     => alu_op2_sel,
            alu_carry       => '0', -- Don't care...
            alu_result      => alu_result,
            rx              => rxValue,
            rz              => rzValue,
            ir_operand      => ir_operand,
            clr_z_flag      => alu_clr_z_flag,
            reset           => reset
        );
    rf : regfile
        port map (
            clk             => clk,
            reset           => reset,
            id_r            => rf_id_r,
            sel_z           => rf_sel_z,
            sel_x           => rf_sel_x,
            rx              => rxValue,
            rz              => rzValue,
            rf_input_sel    => rf_sel_in,
            ir_operand      => ir_operand,
            dm_out          => data_mem_out,
            aluout          => alu_result,
            rz_max          => rz_max,
            sip_hold        => sip_hold,
            er_temp         => er_temp,
            r7              => r7,
            dprr_res        => dprr_res,
            dprr_res_reg    => dprr_res_reg,
            dprr_wren       => dprr_wren
        );
    pc : prog_counter
        port map (
            clk             => clk,
            reset           => reset,
            pc_write_flag   => pc_write_flag,
            pc_mode         => pc_mode,
            pc_in           => pc_in,
            pc_out          => pc_out
        );
    ir : inst_reg
        port map (
            clk         => clk,
            reset       => reset,
            instruction => instruction,
            opcode      => ir_opcode,
            rx          => rxAddr,
            rz          => rzAddr,
            operand     => ir_operand
        );
    pm : prog_mem
        port map (
            address => prog_mem_in,
            clock   => clk,
            q       => prog_mem_out
        );
    dm : data_mem
        port map (
            address => data_mem_in_addr,
            clock   => clk,
            data    => data_mem_in_data,
            wren    => dm_write,
            q       => data_mem_out
        );
    
    -- Program Counter
    pc_in <=     rx when pc_mode = pc_mode_rx else
             dm_out when pc_mode = pc_mode_dm else
             X"0000";

    -- Program Memory
    prog_mem_in <= pc_out;

    -- Instruction Register
    fetch_listener : process(pc_out)
    begin
        if fetch_state = IDLE then
            fetch_state <= FETCH_1;
        end if;
    end process fetch_listener;
    ir_process : process(clk, reset)
    begin
        if reset = '1' then
            fetch_state <= IDLE;
        elsif rising_edge(clk) then
            case fetch_state is
                when IDLE =>
                    fetch_inst_1 := X"0000";
                    fetch_inst_2 := X"0000";
                when FETCH_1 =>
                    prog_mem_in <= pc_out;
                    fetch_state <= FETCH_2;
                when FETCH_2 =>
                    fetch_inst_1 <= prog_mem_out;
                    -- This instruction, is fat...
                    if (fetch_inst_1(15 downto 14) = am_immediate or fetch_inst_1(15 downto 14) = am_direct) then
                        prog_mem_in <= pc_out + 1;
                        fetch_state <= FETCH_3;
                    else
                        fetch_state <= IDLE;
                    end if;
                when FETCH_3 =>
                    fetch_inst_2 <= prog_mem_out;
                    fetch_state <= IDLE;
                when others =>
                    null;
            end case;
        end if;
    end process ir_process;
    instruction <= fetch_inst_1 & fetch_inst_2;

    -- Reg File
    rf_sel_x <= to_integer(unsigned(rxAddr));
    rf_sel_z <= to_integer(unsigned(rzAddr));

    -- ALU

    -- Address Register
    -- What to write to the data memory? Just the
    -- opcode ? but that does not fit the length
    -- The first statement needs to be double checked, it named value is it for the opcode?
    data_mem_in_addr <=     (X"0" & ir_opcode) when dm_sel_addr = dm_sel_addr_value else
                           pc_out(11 downto 0) when dm_sel_addr = dm_sel_addr_pc else
                          rxValue(11 downto 0) when dm_sel_addr = dm_sel_addr_rx else
                          rzValue(11 downto 0) when dm_sel_addr = dm_sel_addr_rz else
                          X"0000";

    -- Data Memory
    -- What to write to the data memory? Just the
    -- opcode ? but that does not fit the length
    -- The first statement needs to be double checked, it named value is it for the opcode?
    data_mem_in_data <=     (X"00" & ir_opcode) when dm_sel_in = dm_sel_in_value else
                                 ("0" & pc_out) when dm_sel_in = dm_sel_in_pc else
                                        rxValue when dm_sel_in = dm_sel_in_rx else
                                        rzValue when dm_sel_in = dm_sel_in_rz else
                                        X"0000";
end behaviour;

