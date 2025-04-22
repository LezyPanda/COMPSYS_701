library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;

use work.recop_types.all;
use work.opcodes.all;

entity control_unit is
    port (
        -- Common
        clk:    in bit_1;
        reset:  in bit_1;

        -- DE1SoC Peripherals
        button: in bit_4;
        sw:     in bit_10;
        -- ADD 7 seg display here
        -- ADD LED here


        --mux shit
        pm_sel: in bit_2; -- 00 -> pc, 01 -> ir, 10 -> dprr, 11 -> dm_out
        rf_sel: in bit_2; -- 00
        dm_in_sel: out bit_2;
		dm_adr_sel: out bit_2;



        -- Operation
        opcode: in bit_8;
        rx:     in bit_16;
        rz:     in bit_16;

        -- Program Counter
        mux         : in bit_2;
        control_sig : in bit_1;

        -- Register Files
        reg_ld_r            : in bit_1; 
        reg_rf_input_sel    : in bit_3;

        -- Program Counter
        pc_write_flag   : out bit_1; -- Write Program Counter
        pc_mode         : out bit_2; -- 00 -> Direct Set (Jump?), 01 -> PC + 1, 10 -> PC + 2
        pc_in           : out bit_16; -- Direct Set to the PC, for jump?
    );
end control_unit;

architecture behaviour of controlunit is
    -- Components
    component alu is
        port (
            clk           : in  bit_1;
            z_flag        : out bit_1;
            alu_operation : in  bit_3;
            alu_op1_sel   : in  bit_2;
            alu_op2_sel   : in  bit_1;
            alu_carry     : in  bit_1;
            alu_result    : out bit_16 := X"0000";
            rx            : in  bit_16;
            rz            : in  bit_16;
            ir_operand    : in  bit_16;
            clr_z_flag    : in  bit_1;
            reset         : in  bit_1
        );
    end component;
    -- Components End
    
    -- States
    type state_type is (T1, T2, T3);
    signal state, next_state: state_type;
    -- States End

    -- ALU
    signal z_flag           : bit_1     := '0';
    signal alu_result       : bit_16    := X"0000";
    signal alu_op1_sel      : bit_2     := "00";    -- 00 -> rx, 01 -> operand, else -> X"0000"
    signal alu_op2_sel      : bit_1     := '0';     -- 0 -> rx, 1 -> rz
    signal alu_carry        : bit_1     := '0';
    signal alu_operation    : bit_3     := "000";
    signal rx               : bit_16    := X"0000";
    signal rz               : bit_16    := X"0000";
    signal ir_operand       : bit_16    := X"0000";
    signal clr_z_flag       : bit_1     := '0';
    -- ALU End
    -- Register File
    reg_ld_r: bit_1 := '0';
    reg_rf_input_sel: bit_3 := "000"; -- 000 -> ir_operand, 001 -> dprr_res_reg, 011 -> aluout, 100 -> rz_max, 101 -> sip_hold, 110 -> er_temp, 111 -> dm_out

    -- Datapath Control
    signal pc_write_flag_signal : bit_1 := '0'; -- Write Program Counter
    signal pc_mode_signal       : bit_2 := "00"; -- 00 -> Direct Set (Jump?), 01 -> PC + 1, 10 -> PC + 2
begin
    alu_inst : alu
        port map (
            clk           => clk,
            z_flag        => z_flag,
            alu_operation => alu_operation,
            alu_op1_sel   => alu_op1_sel,
            alu_op2_sel   => alu_op2_sel,
            alu_carry     => alu_carry,
            alu_result    => alu_result,
            rx            => rx,
            rz            => rz,
            ir_operand    => ir_operand,
            clr_z_flag    => clr_z_flag,
            reset         => reset
        );

    -- Reset
    reset_process : process(clk, reset)
    begin
        if (clk'event and clk = '1' and reset = '1') then
            z_flag          <= '0';
            alu_result      <= X"0000";
            alu_op1_sel     <= "00";
            alu_op2_sel     <= '0';
            alu_carry       <= '0';
            alu_operation   <= "000";
            rx              <= X"0000";
            rz              <= X"0000";
            ir_operand      <= X"0000";
            clr_z_flag      <= '0';
        end if;
    end process reset_process;

    --FSM state
    fsm_process : process(clk, reset)
    begin
        if reset = '1' then
            state <= T1;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process fsm_process;

    -- MOOOOve to next thing
    state_process : process(state)
    begin
        case state is
            when T1 => next_state <= T2;
            when T2 => next_state <= T3;
            when T3 => next_state <= T1;
            when others => next_state <= T1;
        end case;
    end process state_process;

    opcode_process : process(state, opcode)
        constant am             : bit_2 := "00";
        constant useRx          : bit_1 := '0';
        constant useRz          : bit_1 := '1';
        constant useImmediate   : bit_1 := '0';
        am := opcode(7 downto 6);
        -- alu_op1_sel: 00 -> rx, 01 -> operand, else -> X"0000"
        -- alu_op2_sel: 0 -> rx, 1 -> rz
        -- (op1 is the right most parameter)
        alu_op1_sel <= am;

        useImmediate <= am = am_immediate or am = am_direct;
        case state is
            when T1 =>
                pc_write_flag_signal <= '1'; 
                if useImmediate = '1' then
                    pc_mode_signal <= "10"; -- set pc + 2                    
                else 
                    pc_mode_signal <= "01"; -- set pc + 1
                end if;
            when T2 =>
                alu_op1_sel <= am;
                useImmediate <= am = am_immediate or am = am_direct;
                case opcode(5 downto 0) is
                    when andr =>
                        alu_operation <= alu_and;
                        alu_op2_sel   <= useRx when useImmediate = '1' else useRz;
                    when orr =>
                        alu_operation <= alu_or;
                        alu_op2_sel   <= useRx when useImmediate = '1' else useRz;
                    when addr =>
                        alu_operation <= alu_add;
                        alu_op2_sel   <= useRx when useImmediate = '1' else useRz;
                    when subvr =>
                        alu_operation <= alu_sub;
                        alu_op2_sel   <= useRx;
                    when subr =>
                        alu_operation <= alu_sub;
                        alu_op2_sel   <= useRz;
                    -- Mem operations
                    when ldr => 
                        -- need to grab rx and operand in dm somehow TO BE FIXED
                        if am = am_immediate then 
                            reg_rf_input_sel <= "000"; -- ir_operand
                        elsif am = am_register then
                            reg_rf_input_sel <= "111"; -- dm_out (datamemeory)
                        elsif am = am_direct then
                            reg_rf_input_sel <= "111"; 
                        end if;
                    when str =>
                        if am = am_immediate then 
                            --idk if this is correct probably not TO BE FIXED
                            reg_rf_input_sel <= "000"; -- ir_operand
                            alu_op2_sel <= useRz;
                        elsif am = am_register then
                            alu_op1_sel <= useRx;
                            alu_op2_sel <= useRz;
                        elsif am = am_direct then
                            alu_op1_sel <= useRx;
                        end if;
                    when jmp => 
                        if am = am_immediate then 
                            mux <= "00"; -- set to pc operand 
                        elsif am = am_register then
                            mux <= "01"; -- set to pc rx
                        end if;
                    when present =>
                        null;
                    when datacall =>
                        null;
                    when datacall2 =>
                        null;
                    when sz =>
                        null;
                    when strpc => 
                        null;
                    when ssop =>
                        null;
                end case;
            when T3 =>
                case opcode(5 downto 0) is
                    when andr | orr | addr | subvr | subr =>
                        reg_ld_r <= '1'; -- Write result to Rz
                        reg_rf_input_sel <= "011"; -- ALU result
                    when ldr =>
                        reg_ld_r <= '1';
                    when str =>
                        null;
                    when jmp =>
                        control_sig <= '1'; --?
                    when present =>
                        if op2 = '0' then
                            mux <= "00";  -- set pc to op1
                        end if;
                    when datacall | datacall2 => -- mostly placeholder
                        dcpr = op1 + op2; --register.vhd
                        dprr = '1'; -- regfile
                    when sz =>
                        if z_flag = '1' then
                            mux <= "00"; -- set pc to op1
                        end if;
                    when strpc =>
                        null;
                        -- DM[op2] = op1
                    when clfz =>
                        z_flag <= '0'; -- clear z_flag
                    when lsip =>
                        null;
                        --rz = sip
                    when ssop =>
                        null;
                        -- sop = op1
                    when others =>
                        null; --NOOOOOOP?                    
                end case;
            end case;
        end case;
    end process opcode_process;     

    pc_write_flag <= pc_write_flag_signal;
    pc_mode <= pc_mode_signal;

end behaviour;

