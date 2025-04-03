-- filepath: ReCOP (To be sorted)/datapath.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.recop_types.all;

entity datapath is
    Port (
        clk             : in  STD_LOGIC;
        reset           : in  STD_LOGIC;
        -- Control signals from control unit
        pc_load         : in  STD_LOGIC;
        pc_inc          : in  STD_LOGIC;
        pc_inc_by_2     : in  STD_LOGIC;
        ir_load         : in  STD_LOGIC;
        op_load         : in  STD_LOGIC;
        reg_write       : in  STD_LOGIC;
        rx_sel          : in  STD_LOGIC_VECTOR(3 downto 0);
        rz_sel          : in  STD_LOGIC_VECTOR(3 downto 0);
        alu_op          : in  STD_LOGIC_VECTOR(3 downto 0);
        data_mem_write  : in  STD_LOGIC;
        data_mem_read   : in  STD_LOGIC;
        alu_src_a_sel   : in  STD_LOGIC;
        alu_src_b_sel   : in  STD_LOGIC;
        reg_write_sel   : in  STD_LOGIC_VECTOR(1 downto 0);
        mem_addr_sel    : in  STD_LOGIC;
        -- Special registers control
        dpcr_load       : in  STD_LOGIC;
        dprr_load       : in  STD_LOGIC;
        er_load         : in  STD_LOGIC;
        eot_load        : in  STD_LOGIC;
        eot_value       : in  STD_LOGIC;
        sip_load        : in  STD_LOGIC;
        sop_load        : in  STD_LOGIC;
        svop_load       : in  STD_LOGIC;
        z_load          : in  STD_LOGIC;
        z_clear         : in  STD_LOGIC;
        
        -- Status signals to control unit
        z_flag          : out STD_LOGIC;
        er_flag         : out STD_LOGIC;
        eot_flag        : out STD_LOGIC;
        instr_opcode    : out STD_LOGIC_VECTOR(5 downto 0);
        instr_mode      : out STD_LOGIC_VECTOR(1 downto 0);
        instr_rx        : out STD_LOGIC_VECTOR(3 downto 0);
        instr_rz        : out STD_LOGIC_VECTOR(3 downto 0);
        
        -- Memory interface
        prog_mem_data   : in  STD_LOGIC_VECTOR(15 downto 0);
        prog_mem_addr   : out STD_LOGIC_VECTOR(15 downto 0);
        data_mem_in     : in  STD_LOGIC_VECTOR(15 downto 0);
        data_mem_out    : out STD_LOGIC_VECTOR(15 downto 0);
        data_mem_addr   : out STD_LOGIC_VECTOR(15 downto 0)
    );
end datapath;

architecture Behavioral of datapath is
    -- Registers
    signal pc_reg       : STD_LOGIC_VECTOR(15 downto 0);
    signal ir_reg       : STD_LOGIC_VECTOR(15 downto 0);
    signal op_reg       : STD_LOGIC_VECTOR(15 downto 0);
    
    -- ALU signals
    signal alu_result   : STD_LOGIC_VECTOR(15 downto 0);
    signal alu_src_a    : STD_LOGIC_VECTOR(15 downto 0);
    signal alu_src_b    : STD_LOGIC_VECTOR(15 downto 0);
    signal alu_zero     : STD_LOGIC;
    
    -- Register file signals
    signal reg_write_data : STD_LOGIC_VECTOR(15 downto 0);
    signal rx_data      : STD_LOGIC_VECTOR(15 downto 0);
    signal rz_data      : STD_LOGIC_VECTOR(15 downto 0);
    
    -- Special registers
    signal dpcr_reg     : STD_LOGIC_VECTOR(31 downto 0);
    signal dprr_reg     : STD_LOGIC_VECTOR(1 downto 0);
    signal er_reg       : STD_LOGIC;
    signal eot_reg      : STD_LOGIC;
    signal z_reg        : STD_LOGIC;
    signal sip_reg      : STD_LOGIC_VECTOR(15 downto 0);
    signal sop_reg      : STD_LOGIC_VECTOR(15 downto 0);
    signal svop_reg     : STD_LOGIC_VECTOR(15 downto 0);
    
    -- Internal connections
    signal pc_next      : STD_LOGIC_VECTOR(15 downto 0);
    signal mem_addr     : STD_LOGIC_VECTOR(15 downto 0);
    
begin
    -- Register file instantiation
    regfile_inst: entity work.regfile
        port map (
            clk         => clk,
            reset       => reset,
            rx_sel      => rx_sel,
            rz_sel      => rz_sel,
            rx_data     => rx_data,
            rz_data     => rz_data,
            write_sel   => rz_sel,
            write_data  => reg_write_data,
            write_en    => reg_write
        );
    
    -- ALU instantiation
    alu_inst: entity work.ALU
        port map (
            alu_in_a    => alu_src_a,
            alu_in_b    => alu_src_b,
            alu_op      => alu_op,
            alu_out     => alu_result,
            alu_zero    => alu_zero
        );
    
    -- Program Counter logic
    process(clk, reset)
    begin
        if reset = '1' then
            pc_reg <= (others => '0');
        elsif rising_edge(clk) then
            if pc_load = '1' then
                pc_reg <= alu_result;
            elsif pc_inc = '1' then
                if pc_inc_by_2 = '1' then
                    pc_reg <= std_logic_vector(unsigned(pc_reg) + 2);
                else
                    pc_reg <= std_logic_vector(unsigned(pc_reg) + 1);
                end if;
            end if;
        end if;
    end process;
    
    -- Instruction Register logic
    process(clk, reset)
    begin
        if reset = '1' then
            ir_reg <= (others => '0');
        elsif rising_edge(clk) then
            if ir_load = '1' then
                ir_reg <= prog_mem_data;
            end if;
        end if;
    end process;
    
    -- Operand Register logic
    process(clk, reset)
    begin
        if reset = '1' then
            op_reg <= (others => '0');
        elsif rising_edge(clk) then
            if op_load = '1' then
                op_reg <= prog_mem_data;
            end if;
        end if;
    end process;
    
    -- Special registers logic
    process(clk, reset)
    begin
        if reset = '1' then
            dpcr_reg <= (others => '0');
            dprr_reg <= (others => '0');
            er_reg <= '0';
            eot_reg <= '0';
            z_reg <= '0';
            sip_reg <= (others => '0');
            sop_reg <= (others => '0');
            svop_reg <= (others => '0');
        elsif rising_edge(clk) then
            -- DPCR register
            if dpcr_load = '1' then
                dpcr_reg <= rx_data & op_reg;
            end if;
            
            -- DPRR register
            if dprr_load = '1' then
                dprr_reg(1) <= '0'; -- As per DATACALL instruction
            end if;
            
            -- ER register
            if er_load = '1' then
                er_reg <= '0'; -- As per CER instruction
            end if;
            
            -- EOT register
            if eot_load = '1' then
                eot_reg <= eot_value; -- Set or clear based on SEOT/CEOT
            end if;
            
            -- Z flag register
            if z_clear = '1' then
                z_reg <= '0';
            elsif z_load = '1' then
                z_reg <= alu_zero;
            end if;
            
            -- SIP register
            if sip_load = '1' then
                -- Operation for LSIP instruction
            end if;
            
            -- SOP register
            if sop_load = '1' then
                sop_reg <= rx_data; -- For SSOP instruction
            end if;
            
            -- SVOP register
            if svop_load = '1' then
                svop_reg <= rx_data; -- For SSVOP instruction
            end if;
        end if;
    end process;
    
    -- ALU source selection
    alu_src_a <= rx_data when alu_src_a_sel = '0' else
                 op_reg;
                 
    alu_src_b <= rz_data when alu_src_b_sel = '0' else
                 op_reg;
    
    -- Register write data selection
    reg_write_data <= alu_result when reg_write_sel = "00" else
                      op_reg when reg_write_sel = "01" else
                      data_mem_in when reg_write_sel = "10" else
                      pc_reg;
    
    -- Memory address selection
    mem_addr <= rz_data when mem_addr_sel = '0' else
                op_reg;
    
    -- Outputs
    prog_mem_addr <= pc_reg;
    data_mem_addr <= mem_addr;
    data_mem_out <= rx_data;
    
    -- Status outputs
    z_flag <= z_reg;
    er_flag <= er_reg;
    eot_flag <= eot_reg;
    
    -- Instruction decode outputs
    instr_opcode <= ir_reg(15 downto 10);
    instr_mode <= ir_reg(9 downto 8);
    instr_rz <= ir_reg(7 downto 4);
    instr_rx <= ir_reg(3 downto 0);
    
end Behavioral;