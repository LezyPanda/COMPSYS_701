library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;

use work.recop_types.all;
use work.opcodes.all;
use work.various_constants.all;

entity control_unit is
    port (
        -- Common
        clk:    in bit_1;
        reset:  in bit_1;

        -- Mux Control to Datapath
        dm_sel_addr     : out bit_2;
        dm_sel_in       : out bit_2;
        dm_write        : out bit_1;
        ir_in           : out bit_1;
        ir_fetch_start  : out bit_1; 
        pc_in           : out bit_2;
        rf_sel_in       : out bit_3;
        alu_operation   : out bit_3;
        alu_sel_op1     : out bit_2;
        alu_sel_op2     : out bit_1;
        pc_mode         : out bit_2; 
        dcpr_sel        : out bit_1;
        sop_write       : out bit_1; 
        alu_clr_z_flag  : out bit_1;
        reg_ld_r        : out bit_1; 
        pc_write_flag   : out bit_1;
        dcpr_write_flag : out bit_1;

        -- From Datapath
        alu_z_flag      : in bit_1;
        alu_result      : in bit_16;
        ir_opcode       : in bit_8    := (others => '0');
        inst_fetched    : in bit_16;
        
        rz_empty: in bit_1
    );
end control_unit;

architecture behaviour of control_unit is
    -- States
    type state_type is (T0, T1, T2, T3);
    signal state, next_state: state_type;
    -- States End

    -- Datapath Control
    signal pc_write_flag_signal : bit_1 := '0'; -- Write Program Counter
    signal pc_mode_signal       : bit_2 := "00"; -- 00 -> Direct Set (Jump?), 01 -> PC + 1, 10 -> PC + 2

    -- Internal control signals
    signal dm_sel_addr_signal       : bit_2 := (others=>'0');
    signal dm_sel_in_signal         : bit_2 := (others=>'0');
    signal dm_write_signal          : bit_1 := '0';
    signal ir_in_signal             : bit_1 := '0';
    signal ir_fetch_start_signal    : bit_1 := '0';
    signal pc_in_signal             : bit_2 := (others=>'0');
    signal rf_sel_in_signal         : bit_3 := (others=>'0');
    signal alu_operation_signal     : bit_3 := (others=>'0');
    signal alu_sel_op1_signal       : bit_2 := "00";
    signal alu_sel_op2_signal       : bit_1 := '0';
    signal dcpr_sel_signal          : bit_1 := '0';
    signal sop_write_signal         : bit_1 := '0';
    signal alu_clr_z_flag_signal    : bit_1 := '0';
    signal reg_write_signal         : bit_1 := '0';
    signal dcpr_write_flag_signal   : bit_1 := '0';

begin
    -- Reset
    reset_process : process(clk, reset)
    begin
        if (clk'event and clk = '1' and reset = '1') then
            alu_result      <= X"0000";
            alu_op2_sel     <= '0';
            alu_carry       <= '0';
            alu_operation   <= "000";
            rx              <= X"0000";
            rz              <= X"0000";
            ir_operand      <= X"0000";
            clr_z_flag      <= '0';
        end if;
    end process reset_process;

    -- FSM State Update
    fsm_process : process(clk, reset)
    begin
        if reset = '1' then
            state <= T1;
        elsif rising_edge(clk) then
            if (state /= T1 or inst_fetched = '1') then
                state <= next_state;
            end if;
        end if;
    end process fsm_process;

    -- Tick
    opcode_process : process(state)
        variable am             : bit_2 := "00";
        variable useImmediate   : bit_1 := '0';
        variable opcode         : bit_6 := (others => '0');
    begin
        am      := ir_opcode(7 downto 6);
        opcode  := ir_opcode(5 downto 0);

        -- Default Values
        pc_mode_signal <= pc_mode_incr_1
        ir_fetch_start_signal <= '0';
        case state is
            when T1 =>
                next_state <= T2;
                if (am = am_inherent) then
                    pc_mode_signal <= pc_mode_incr_1;
                elsif (am = am_immediate) then
                    pc_mode_signal <= pc_mode_incr_2;
                elsif (am = am_direct) then
                    pc_mode_signal <= pc_mode_incr_2;
                elsif (am = am_register) then
                    pc_mode_signal <= pc_mode_dm_out;
                else
                    pc_mode_signal <= pc_mode_incr_1;
                end if;
                pc_write_flag_signal <= '1'; 
                ir_fetch_start_signal <= '1';
            when T2 =>
                next_state <= T3;
                alu_sel_op1_signal <= am;
                \ andr, orr, addr \
                if (opcode = andr or opcode = orr or opcode = addr) then
                    alu_operation_signal <= alu_and when opcode = andr else
                                             alu_or when opcode = orr else
                                            alu_add when opcode = addr else
                                           alu_idle;
                    rf_sel_in_signal <= rf_sel_in_alu;
                    if (am = am_immediate) then
                        alu_sel_op1_signal <= alu_sel_op1_value;
                        alu_sel_op2_signal <= alu_sel_op2_rx;
                    else
                        alu_sel_op1_signal <= alu_sel_op1_rx;
                        alu_sel_op2_signal <= alu_sel_op2_rz;
                    end if;
                \ subvr, subr \
                elsif (opcode = subvr or opcode = subr) then
                    alu_operation_signal <= alu_sub;
                    rf_sel_in_signal <= rf_sel_in_alu;
                    alu_sel_op1_signal <= alu_sel_op1_value;
                    alu_sel_op2_signal <= alu_sel_op2_rx when opcode = subvr else
                                          alu_sel_op2_rz when opcode = subr else
                                          alu_sel_op2_rz;
                \ ldr -- This part needs to be double checkd -- \
                elsif (opcode = ldr) then
                    alu_operation_signal <= alu_idle;
                    if (am = am_immediate or am = am_register) then
                        rf_sel_in_signal <= rf_sel_in_value;
                    elsif (am = am_direct) then
                        rf_sel_in_signal <= rf_sel_in_value; 
                        dm_sel_addr_signal <= dm_sel_addr_value;
                    end if;
                \ ----------------------------------------- \
                \ str \
                elsif (opcode = str) then
                    case am is 
                        when am_immediate =>
                            -- set operand as input 
                            dm_sel_in_signal <= dm_sel_in_value;
                            -- set rz as address to write operand to
                            dm_sel_addr_signal <= dm_sel_addr_rz; 
                        when am_register =>
                            dm_sel_in_signal <= dm_sel_in_rx;
                            dm_sel_addr_signal <= dm_sel_addr_rz; 
                        when am_direct =>
                            dm_sel_in_signal <= dm_sel_in_rx;
                            dm_sel_addr_signal <= dm_sel_addr_value; 
                        when others =>
                            null;
                    end case;
                \ jmp \
                elsif (opcode = jmp) then
                    if am = am_immediate then 
                    --  set operand  as pc mode
                        pc_mode_signal <= pc_sel_value;
                    elsif am = am_register then
                        pc_mode_signal <= pc_sel_rx;
                    end if;
                \ present \
                elsif (opcode = present) then
                    pc_mode_signal <= pc_sel_value;
                \ datacall -- This part needs to be double checkd -- \
                elsif (opcode = datacall) then
                    if am = am_immediate then 
                        -- set operand as input for dpcr operation
                        dcpr_sel_signal <= dpcr_value;
                    elsif am = am_register then
                        -- set rz as operand 
                        dcpr_sel_signal <= dpcr_r7;
                    end if;
                \ sz \
                elsif (opcode = sz) then
                    -- set pc mode to operand
                    pc_mode_signal <= pc_sel_value;
                \ strpc \
                elsif (opcode = strpc) then
                    -- store pc operation into data memoryu
                    dm_sel_in_signal <= dm_sel_in_pc;
                    dm_sel_addr_signal <= dm_sel_addr_value;
                \ ssop \
                elsif (opcode = ssop) then
                    sop_write_signal <= '1';
                    -- put rx in op1 and then put op1 to sop
                \ ----------------------------------------- \
                end if;
            when T3 =>
                next_state <= T1;
                -- mostly setting flags for datapath to excecute actions
                case opcode is
                    when andr or orr or addr or subvr or subr =>
                        reg_write_signal <= '1'; 
                    when ldr =>
                        reg_write_signal <= '1';
                    when str =>
                        dm_write_signal <= '1'; 
                    when jmp =>
                        pc_write_flag_signal <= '1'; 
                    when present =>
                        if rz_empty = '1' then
                            pc_write_flag_signal <= '1'; 
                        else
                            pc_write_flag_signal <= '0';   
                        end if;
                    when datacall => 
                        dcpr_write_flag_signal <= '1';
                    when sz =>
                        -- if z flag is one then pc is operand mode
                        if alu_z_flag = '1' then
                            pc_write_flag_signal <= '1'; 
                        else
                            pc_write_flag_signal <= '0'; 
                        end if;
                    when strpc =>
                        dm_write_signal <= '1';
                    when clfz =>
                        -- set a flag to clear z_flag
                        alu_clr_z_flag_signal <= '1'; 
                    when lsip =>
                        -- set sip hold to input
                        rf_sel_in_signal <= rf_sel_in_sip;
                        reg_write_signal <= '1';
                    when ssop =>
                        sop_write_signal <= '1';
                    when others =>
                        null; -- NOOOOOOP?
                    end case;
            end case;
        end case;
    end process opcode_process;
    
    -- Output port assignments
    dm_sel_addr       <= dm_sel_addr_signal;
    dm_sel_in         <= dm_sel_in_signal;
    dm_write          <= dm_write_signal;
    ir_in             <= ir_in_signal;
    pc_in             <= pc_in_signal;
    rf_sel_in         <= rf_sel_in_signal;
    alu_operation     <= alu_operation_signal;
    alu_sel_op1       <= alu_sel_op1_signal;
    alu_sel_op2       <= alu_sel_op2_signal;
    pc_mode           <= pc_mode_signal;
    pc_write_flag     <= pc_write_flag_signal;
    dcpr_sel          <= dcpr_sel_signal;
    sop_write         <= sop_write_signal;
    alu_clr_z_flag    <= alu_clr_z_flag_signal;
    reg_ld_r         <= reg_write_signal;
    dcpr_write_flag   <= dcpr_write_flag_signal;

end behaviour;

