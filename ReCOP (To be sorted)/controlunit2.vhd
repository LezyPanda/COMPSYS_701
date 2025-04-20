-- filepath: ReCOP (To be sorted)/controlunit.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.recop_types.all;
use work.opcodes.all;

entity controlunit is
    Port (
        clk             : in  STD_LOGIC;
        reset           : in  STD_LOGIC;
        -- Status signals from datapath
        z_flag          : in  STD_LOGIC;
        er_flag         : in  STD_LOGIC;
        eot_flag        : in  STD_LOGIC;
        instr_opcode    : in  STD_LOGIC_VECTOR(5 downto 0);
        instr_mode      : in  STD_LOGIC_VECTOR(1 downto 0);
        instr_rx        : in  STD_LOGIC_VECTOR(3 downto 0);
        instr_rz        : in  STD_LOGIC_VECTOR(3 downto 0);
        
        -- Control signals to datapath
        pc_load         : out STD_LOGIC;
        pc_inc          : out STD_LOGIC;
        pc_inc_by_2     : out STD_LOGIC;
        ir_load         : out STD_LOGIC;
        op_load         : out STD_LOGIC;
        reg_write       : out STD_LOGIC;
        rx_sel          : out STD_LOGIC_VECTOR(3 downto 0);
        rz_sel          : out STD_LOGIC_VECTOR(3 downto 0);
        alu_op          : out STD_LOGIC_VECTOR(3 downto 0);
        data_mem_write  : out STD_LOGIC;
        data_mem_read   : out STD_LOGIC;
        alu_src_a_sel   : out STD_LOGIC;
        alu_src_b_sel   : out STD_LOGIC;
        reg_write_sel   : out STD_LOGIC_VECTOR(1 downto 0);
        mem_addr_sel    : out STD_LOGIC;
        -- Special registers control
        dpcr_load       : out STD_LOGIC;
        dprr_load       : out STD_LOGIC;
        er_load         : out STD_LOGIC;
        eot_load        : out STD_LOGIC;
        eot_value       : out STD_LOGIC;
        sip_load        : out STD_LOGIC;
        sop_load        : out STD_LOGIC;
        svop_load       : out STD_LOGIC;
        z_load          : out STD_LOGIC;
        z_clear         : out STD_LOGIC
    );
end controlunit;

architecture Behavioral of controlunit is
    -- Pipeline stage counter
    type state_type is (T1, T2, T3);
    signal state, next_state : state_type;
    
    -- Previous instruction mode for T1 conditional logic
    signal prev_instr_mode : STD_LOGIC_VECTOR(1 downto 0);
    
    -- Current instruction
    signal current_opcode : STD_LOGIC_VECTOR(5 downto 0);
    signal current_mode : STD_LOGIC_VECTOR(1 downto 0);
    signal current_rx : STD_LOGIC_VECTOR(3 downto 0);
    signal current_rz : STD_LOGIC_VECTOR(3 downto 0);
    
begin
    -- State register
    process(clk, reset)
    begin
        if reset = '1' then
            state <= T1;
            prev_instr_mode <= "00";
            current_opcode <= (others => '0');
            current_mode <= (others => '0');
            current_rx <= (others => '0');
            current_rz <= (others => '0');
        elsif rising_edge(clk) then
            state <= next_state;
            
            -- Store current instruction details when fetching
            if state = T1 then
                prev_instr_mode <= current_mode;
                current_opcode <= instr_opcode;
                current_mode <= instr_mode;
                current_rx <= instr_rx;
                current_rz <= instr_rz;
            end if;
        end if;
    end process;
    
    -- Next state logic
    process(state)
    begin
        case state is
            when T1 =>
                next_state <= T2;
            when T2 =>
                next_state <= T3;
            when T3 =>
                next_state <= T1;
        end case;
    end process;
    
    -- Control signals generation
    process(state, current_opcode, current_mode, current_rx, current_rz, 
            prev_instr_mode, z_flag, er_flag, eot_flag)
    begin
        -- Default values
        pc_load <= '0';
        pc_inc <= '0';
        pc_inc_by_2 <= '0';
        ir_load <= '0';
        op_load <= '0';
        reg_write <= '0';
        rx_sel <= current_rx;
        rz_sel <= current_rz;
        alu_op <= ALU_NOP;
        data_mem_write <= '0';
        data_mem_read <= '0';
        alu_src_a_sel <= '0';
        alu_src_b_sel <= '0';
        reg_write_sel <= "00";
        mem_addr_sel <= '0';
        dpcr_load <= '0';
        dprr_load <= '0';
        er_load <= '0';
        eot_load <= '0';
        eot_value <= '0';
        sip_load <= '0';
        sop_load <= '0';
        svop_load <= '0';
        z_load <= '0';
        z_clear <= '0';
        
        case state is
            when T1 =>
                -- T1: Fetch instruction and/or operand
                if prev_instr_mode = "01" or prev_instr_mode = "10" then
                    -- Two-word instruction
                    ir_load <= '1';
                    op_load <= '1';
                    pc_inc <= '1';
                    pc_inc_by_2 <= '1';
                else
                    -- One-word instruction
                    op_load <= '1';
                    pc_inc <= '1';
                    pc_inc_by_2 <= '0';
                end if;
                
            when T2 =>
                -- T2: Operand fetch based on instruction
                case current_opcode is
                    -- Logic instructions
                    when AND_OP =>
                        if current_mode = "01" then  -- Immediate
                            alu_src_a_sel <= '0';  -- Rx
                            alu_src_b_sel <= '1';  -- Operand
                        else  -- Register
                            alu_src_a_sel <= '0';  -- Rz
                            alu_src_b_sel <= '0';  -- Rx
                        end if;
                        
                    when OR_OP =>
                        if current_mode = "01" then  -- Immediate
                            alu_src_a_sel <= '0';  -- Rx
                            alu_src_b_sel <= '1';  -- Operand
                        else  -- Register
                            alu_src_a_sel <= '0';  -- Rx
                            alu_src_b_sel <= '0';  -- Rz
                        end if;
                        
                    -- Arithmetic instructions
                    when ADD_OP =>
                        if current_mode = "01" then  -- Immediate
                            alu_src_a_sel <= '0';  -- Rx
                            alu_src_b_sel <= '1';  -- Operand
                        else  -- Register
                            alu_src_a_sel <= '0';  -- Rx
                            alu_src_b_sel <= '0';  -- Rz
                        end if;
                        
                    when SUBV_OP =>
                        if current_mode = "01" then  -- Immediate
                            alu_src_a_sel <= '1';  -- Operand
                            alu_src_b_sel <= '0';  -- Rx
                        end if;
                        
                    when SUB_OP =>
                        if current_mode = "01" then  -- Immediate
                            alu_src_a_sel <= '1';  -- Operand
                            alu_src_b_sel <= '0';  -- Rz
                        end if;
                        
                    -- Memory operations
                    when LDR_OP =>
                        if current_mode = "01" then  -- Immediate
                            alu_src_a_sel <= '1';  -- Operand
                        elsif current_mode = "00" then  -- Register
                            alu_src_b_sel <= '0';  -- Rx (address)
                            data_mem_read <= '1';
                        elsif current_mode = "10" then  -- Direct
                            alu_src_b_sel <= '1';  -- Operand (address)
                            data_mem_read <= '1';
                        end if;
                        
                    when STR_OP =>
                        if current_mode = "01" then  -- Immediate
                            alu_src_a_sel <= '1';  -- Operand
                            alu_src_b_sel <= '0';  -- Rz
                        elsif current_mode = "00" then  -- Register
                            alu_src_a_sel <= '0';  -- Rx (data)
                            alu_src_b_sel <= '0';  -- Rz (address)
                        elsif current_mode = "10" then  -- Direct
                            alu_src_a_sel <= '0';  -- Rx (data)
                            alu_src_b_sel <= '1';  -- Operand (address)
                        end if;
                        
                    -- Control flow
                    when JMP_OP =>
                        if current_mode = "01" then  -- Immediate
                            alu_src_a_sel <= '1';  -- Operand
                        else  -- Register
                            alu_src_a_sel <= '0';  -- Rx
                        end if;
                        
                    when PRESENT_OP =>
                        if current_mode = "01" then  -- Immediate
                            alu_src_a_sel <= '1';  -- Operand
                            alu_src_b_sel <= '0';  -- Rz
                        end if;
                        
                    -- Special operations
                    when DATACALL_OP =>
                        if current_mode = "00" then  -- Register
                            alu_src_a_sel <= '0';  -- Rz
                            alu_src_b_sel <= '0';  -- Rx
                        elsif current_mode = "01" then  -- Immediate
                            alu_src_a_sel <= '0';  -- Rx
                            alu_src_b_sel <= '1';  -- Operand
                        end if;
                        
                    when SZ_OP =>
                        if current_mode = "01" then  -- Immediate
                            alu_src_a_sel <= '1';  -- Operand
                        end if;
                        
                    when MAX_OP =>
                        if current_mode = "01" then  -- Immediate
                            alu_src_a_sel <= '0';  -- Rz
                            alu_src_b_sel <= '1';  -- Operand
                        end if;
                        
                    when STRPC_OP =>
                        if current_mode = "10" then  -- Direct
                            alu_src_a_sel <= '0';  -- PC
                            alu_src_b_sel <= '1';  -- Operand
                        end if;
                        
                    when others =>
                        null;  -- No operands for inherent instructions
                end case;
                
            when T3 =>
                -- T3: Execute and Write-back
                case current_opcode is
                    -- Logic instructions
                    when AND_OP =>
                        alu_op <= ALU_AND;
                        reg_write <= '1';
                        reg_write_sel <= "00";  -- ALU result
                        z_load <= '1';
                        
                    when OR_OP =>
                        alu_op <= ALU_OR;
                        reg_write <= '1';
                        reg_write_sel <= "00";  -- ALU result
                        z_load <= '1';
                        
                    -- Arithmetic instructions
                    when ADD_OP =>
                        alu_op <= ALU_ADD;
                        reg_write <= '1';
                        reg_write_sel <= "00";  -- ALU result
                        z_load <= '1';
                        
                    when SUBV_OP | SUB_OP =>
                        alu_op <= ALU_SUB;
                        reg_write <= '1';
                        reg_write_sel <= "00";  -- ALU result
                        z_load <= '1';
                        
                    -- Memory operations
                    when LDR_OP =>
                        if current_mode = "01" then  -- Immediate
                            reg_write <= '1';
                            reg_write_sel <= "01";  -- Operand
                        else  -- Register or Direct
                            reg_write <= '1';
                            reg_write_sel <= "10";  -- Data memory
                        end if;
                        
                    when STR_OP =>
                        data_mem_write <= '1';
                        
                    -- Control flow
                    when JMP_OP =>
                        pc_load <= '1';
                        
                    when PRESENT_OP =>
                        if z_flag = '1' then
                            pc_load <= '1';
                        end if;
                        
                    -- Special operations
                    when DATACALL_OP =>
                        dpcr_load <= '1';
                        dprr_load <= '1';
                        
                    when SZ_OP =>
                        if z_flag = '1' then
                            pc_load <= '1';
                        end if;
                        
                    when MAX_OP =>
                        alu_op <= ALU_MAX;
                        reg_write <= '1';
                        reg_write_sel <= "00";  -- ALU result
                        
                    when STRPC_OP =>
                        data_mem_write <= '1';
                        reg_write_sel <= "11";  -- PC
                        
                    when CLFZ_OP =>
                        z_clear <= '1';
                        
                    when CER_OP =>
                        er_load <= '1';
                        
                    when CEOT_OP =>
                        eot_load <= '1';
                        eot_value <= '0';
                        
                    when SEOT_OP =>
                        eot_load <= '1';
                        eot_value <= '1';
                        
                    when LER_OP =>
                        -- Load ER to Rz
                        reg_write <= '1';
                        
                    when SSVOP_OP =>
                        svop_load <= '1';
                        
                    when LSIP_OP =>
                        sip_load <= '1';
                        reg_write <= '1';
                        
                    when SSOP_OP =>
                        sop_load <= '1';
                        
                    when others =>
                        null;  -- NOOP or unimplemented
                end case;
        end case;
    end process;
    
end Behavioral;