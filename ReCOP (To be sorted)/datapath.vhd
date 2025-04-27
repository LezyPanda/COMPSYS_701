library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


use work.recop_types.all;
use work.various_constants.all;
use work.opcodes.all;


entity datapath is
    port (
        -- Common
        clk     : in bit_1;
        reset   : in bit_1;

        -- Mux Control
        dm_sel_addr     : in bit_2;
        dm_sel_in       : in bit_2;
        dm_write        : in bit_1;
        ir_fetch_start  : in bit_1;
        rf_sel_in       : in bit_3;
        rf_write_flag   : in bit_1; 
        pc_write_flag   : in bit_1;
        pc_mode         : in bit_2;
        alu_clr_z_flag  : in bit_1;
        alu_operation   : in bit_3;
        alu_sel_op1     : in bit_2;
        alu_sel_op2     : in bit_1;
        dpcr_write_flag : in bit_1;
        dpcr_sel        : in bit_1;
        sop_write       : in bit_1;

        -- Out
        alu_z_flag      : out bit_1;
        alu_result      : out bit_16;
        ir_opcode       : out bit_8; -- AM(2) + OPCODE(6)
        inst_fetched    : out bit_1;
        rz_empty        : out bit_1;

        -- Debug Signals
        debug_pc_out        : out bit_15;
        debug_fetch_state   : out bit_2;
        debug_instruction   : out bit_32;
        debug_prog_mem_in   : out bit_15;
        debug_prog_mem_out  : out bit_16;
        debug_data_mem_in_addr : out bit_12;
        debug_data_mem_in_data : out bit_16;
        debug_data_mem_out  : out bit_16;
        debug_rx_addr       : out bit_4;
        debug_rz_addr       : out bit_4;
        debug_rx_value      : out bit_16;
        debug_rz_value      : out bit_16;
        debug_ir_operand    : out bit_16;
        debug_rf_reg_listen : in integer range 0 to 15;
        debug_rf_reg_result : out bit_16;
        debug_flag          : out bit_8;
        debug_inst_raw_1    : out bit_16;
        debug_inst_raw_2    : out bit_16;
        debug_all_regs     : out reg_array
    );
end datapath;

architecture behaviour of datapath is
    -- Common Signals
    type fetchStatus is (IDLE, FETCH_1, FETCH_2, FETCH_3);
    signal fetch_state      : fetchStatus  := IDLE;
    signal next_fetch_state : fetchStatus  := IDLE;
    signal fetch_inst_1 : bit_16       := (others => '0');
    signal fetch_inst_2 : bit_16       := (others => '0');
    signal rxAddr       : bit_4        := (others => '0');
    signal rzAddr       : bit_4        := (others => '0');
    signal rxValue      : bit_16       := (others => '0');
    signal rzValue      : bit_16       := (others => '0');
    signal data_mem_out : bit_16       := (others => '0');
    signal ir_operand   : bit_16       := (others => '0');
    signal r7           : bit_16       := (others => '0');
    signal instruction  : bit_32       := (others => '0');

    signal alu_result_signal    : bit_16 := (others => '0');
    signal ir_opcode_signal     : bit_8  := (others => '0');
    signal inst_fetched_signal  : bit_1  := '0';

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

    component regfile is
        port (
            clk             : in bit_1;
            init            : in bit_1;
            ld_r            : in bit_1;
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
            dprr_wren       : in bit_1;
            -- Debug Signals
            debug_all_regs      : out reg_array;
            debug_rf_reg_listen : in integer range 0 to 15;
            debug_rf_reg_result : out bit_16
        );
    end component;
    signal rf_sel_z     : integer range 0 to 15;
    signal rf_sel_x     : integer range 0 to 15;
    signal rf_input_sel : bit_3;
    signal rz_max       : bit_16;
    signal sip_hold     : bit_16;
    signal er_temp      : bit_1;
    signal dprr_res     : bit_1;
    signal dprr_res_reg : bit_1;
    signal dprr_wren    : bit_1;

    component prog_counter is
        port (
            clk             : in  bit_1;
            reset           : in  bit_1;
            pc_write_flag   : in  bit_1;
            pc_mode         : in  bit_2;
            pc_in           : in  bit_15;
            pc_out          : out bit_15
        );
    end component;
    signal pc_in            : bit_15;
    signal pc_out           : bit_15;

    component inst_reg is
        port (
            clk         : in  bit_1;
            reset       : in  bit_1;
            instruction : in  bit_32;
            opcode      : out bit_8; -- AM(2) + OPCODE(6)
            rz          : out bit_4;
            rx          : out bit_4;
            operand     : out bit_16
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

    component registers is
        port (
            clk         : in bit_1;
            reset       : in bit_1;
            dpcr        : out bit_32;
            r7          : in bit_16;
            rx          : in bit_16;
            ir_operand  : in bit_16;
            dpcr_lsb_sel: in bit_1;
            dpcr_wr     : in bit_1;
            er          : out bit_1;
            er_wr       : in bit_1;
            er_clr      : in bit_1;
            eot         : out bit_1;
            eot_wr      : in bit_1;
            eot_clr     : in bit_1;
            svop        : out bit_16;
            svop_wr     : in bit_1;
            sip_r       : out bit_16;
            sip         : in bit_16;
            sop         : out bit_16;
            sop_wr      : in bit_1;
            dprr        : out bit_2;
            irq_wr      : in bit_1;
            irq_clr     : in bit_1;
            result_wen  : in bit_1;
            result      : in bit_1
        );
    end component;
    signal reg_dpcr         : bit_32;
    signal reg_dpcr_lsb_sel : bit_1;
    signal reg_dpcr_wr      : bit_1;
    signal reg_er           : bit_1;
    signal reg_er_wr        : bit_1;
    signal reg_er_clr       : bit_1;
    signal reg_eot          : bit_1;
    signal reg_eot_wr       : bit_1;
    signal reg_eot_clr      : bit_1;
    signal reg_svop         : bit_16;
    signal reg_svop_wr      : bit_1;
    signal reg_sip_r        : bit_16;
    signal reg_sip          : bit_16;
    signal reg_sop          : bit_16;
    signal reg_dprr         : bit_2;
    signal reg_irq_wr       : bit_1;
    signal reg_irq_clr      : bit_1;
    signal reg_result_wen   : bit_1;
    signal reg_result       : bit_1;

    -- component memory is
    --     port (
    --         clk: in bit_1 := '0';
    --         --pm_rd: in bit_1 := '0';
    --         pm_address: in bit_16 := X"0000";
    --         pm_outdata: out bit_16 := X"0000";
    --         --dm_rd: in bit_1 := '0';
    --         dm_address: in bit_16 := X"0000";
    --         dm_outdata: out bit_16 := X"0000";
    --         dm_wr: in bit_1 := '0';
    --         dm_indata: in bit_16 := X"0000"
    --     );
    -- end component;
    signal mem_model_pm_in_addr : bit_16 := (others => '0');
    signal mem_model_dm_in_addr : bit_16 := (others => '0');
    -- End Components
begin
    impl_alu : alu
        port map (
            clk             => clk,
            z_flag          => alu_z_flag,
            alu_operation   => alu_operation,
            alu_op1_sel     => alu_sel_op1,
            alu_op2_sel     => alu_sel_op2,
            alu_carry       => '0', -- Don't care...
            alu_result      => alu_result_signal,
            rx              => rxValue,
            rz              => rzValue,
            ir_operand      => ir_operand,
            clr_z_flag      => alu_clr_z_flag,
            reset           => reset
        );
    impl_rf : regfile
        port map (
            clk             => clk,
            init            => reset,
            ld_r            => rf_write_flag,
            sel_z           => rf_sel_z,
            sel_x           => rf_sel_x,
            rx              => rxValue,
            rz              => rzValue,
            rf_input_sel    => rf_sel_in,
            ir_operand      => ir_operand,
            dm_out          => data_mem_out,
            aluout          => alu_result_signal,
            rz_max          => rz_max,
            sip_hold        => sip_hold,
            er_temp         => er_temp,
            r7              => r7,
            dprr_res        => dprr_res,
            dprr_res_reg    => dprr_res_reg,
            dprr_wren       => dprr_wren,
            -- Debug Signals
            debug_all_regs      => debug_all_regs,
            debug_rf_reg_listen => debug_rf_reg_listen,
            debug_rf_reg_result => debug_rf_reg_result
        );
    impl_pc : prog_counter
        port map (
            clk             => clk,
            reset           => reset,
            pc_write_flag   => pc_write_flag,
            pc_mode         => pc_mode,
            pc_in           => pc_in,
            pc_out          => pc_out
        );
    impl_ir : inst_reg
        port map (
            clk         => clk,
            reset       => reset,
            instruction => instruction,
            opcode      => ir_opcode_signal,
            rz          => rzAddr,
            rx          => rxAddr,
            operand     => ir_operand
        );
    impl_pm : prog_mem
        port map (
            address => prog_mem_in,
            clock   => clk,
            q       => prog_mem_out
        );
    impl_dm : data_mem
        port map (
            address => data_mem_in_addr,
            clock   => clk,
            data    => data_mem_in_data,
            wren    => dm_write,
            q       => data_mem_out
        );
    impl_reg : registers
        port map (
            clk             =>   clk,
            reset           => reset,
            dpcr            => reg_dpcr,
            r7              => r7,
            rx              => rxValue,
            ir_operand      => ir_operand,
            dpcr_lsb_sel    => reg_dpcr_lsb_sel,
            dpcr_wr         => reg_dpcr_wr,
            er              => reg_er,
            er_wr           => reg_er_wr,
            er_clr          => reg_er_clr,
            eot             => reg_eot,
            eot_wr          => reg_eot_wr,
            eot_clr         => reg_eot_clr,
            svop            => reg_svop,
            svop_wr         => reg_svop_wr,
            sip_r           => reg_sip_r,
            sip             => reg_sip,
            sop             => reg_sop,
            sop_wr          => sop_write,
            dprr            => reg_dprr,
            irq_wr          => reg_irq_wr,
            irq_clr         => reg_irq_clr,
            result_wen      => reg_result_wen,
            result          => reg_result
        );
    -- impl_mem : memory
    --     port map (
    --         clk         => clk,
    --         --pm_rd      => '0',
    --         pm_address  => mem_model_pm_in_addr,
    --         pm_outdata => prog_mem_out,
    --         --dm_rd      => '0',
    --         dm_address  => mem_model_dm_in_addr,
    --         dm_outdata  => data_mem_out,
    --         dm_wr       => dm_write,
    --         dm_indata   => data_mem_in_data
    --     );
    -- Debug Signals
    debug_pc_out        <= pc_out(14 downto 0);
    debug_fetch_state   <= "00" when fetch_state = IDLE else
                          "01" when fetch_state = FETCH_1 else
                          "10" when fetch_state = FETCH_2 else
                          "11" when fetch_state = FETCH_3 else
                          "00";
    debug_instruction   <= instruction;
    debug_prog_mem_in   <= prog_mem_in;
    debug_prog_mem_out  <= prog_mem_out;
    debug_data_mem_in_addr    <= data_mem_in_addr;
    debug_data_mem_in_data    <= data_mem_in_data;
    debug_data_mem_out  <= data_mem_out;
    debug_rx_addr       <= rxAddr;
    debug_rz_addr       <= rzAddr;
    debug_rx_value      <= rxValue;
    debug_rz_value      <= rzValue;
    debug_ir_operand    <= ir_operand;
    debug_flag <= pc_out(7 downto 0);
    debug_inst_raw_1 <= fetch_inst_1;
    debug_inst_raw_2 <= fetch_inst_2;
    -- End Debug Signals
    
    alu_result <= alu_result_signal;
    ir_opcode <= ir_opcode_signal;
    rz_empty <= '1' when rzValue = bit_16'(others => '0') else '0';

    -- Program Counter
    pc_in <= rxValue(14 downto 0) when pc_mode = pc_mode_rx else
          ir_operand(14 downto 0) when pc_mode = pc_mode_value else
                "000000000000000";

    -- Program Memory
    -- prog_mem_in <= pc_out;



    -- Instruction Register
    fsm_process : process(clk, reset, next_fetch_state)
    begin
        if reset = '1' then
            fetch_state <= IDLE;
        elsif rising_edge(clk) then
            fetch_state <= next_fetch_state;
        end if;
    end process fsm_process;
    ir_process : process(clk, reset, ir_fetch_start, pc_out, prog_mem_out)
    begin
        if reset = '1' then
            next_fetch_state <= IDLE;
            fetch_inst_1 <= (others => '0');
            fetch_inst_2 <= (others => '0');
        elsif rising_edge(clk) then
            inst_fetched_signal <= '0';
            case fetch_state is
                when IDLE =>
                    if ir_fetch_start = '1' then
                        next_fetch_state <= FETCH_1;
                    end if;
                when FETCH_1 =>
                    prog_mem_in <= pc_out;
                    next_fetch_state <= FETCH_2;
                when FETCH_2 =>
                    fetch_inst_1 <= prog_mem_out;
                    -- This instruction, is fat...
                    if (prog_mem_out(15 downto 14) = am_immediate or prog_mem_out(15 downto 14) = am_direct) then
                        prog_mem_in <= std_logic_vector(unsigned(pc_out) + 1);
                        next_fetch_state <= FETCH_3;
                    else
                        fetch_inst_2 <= (others => '0');
                        inst_fetched_signal <= '1';
                        next_fetch_state <= IDLE;
                    end if;
                when FETCH_3 =>
                    inst_fetched_signal <= '1';
                    next_fetch_state <= IDLE;
                    fetch_inst_2 <= prog_mem_out;
                when others =>
                    null;
            end case;
        end if;
    end process ir_process;
    instruction <= fetch_inst_1 & fetch_inst_2;
    inst_fetched <= inst_fetched_signal;

    -- Reg File
    rf_sel_x <= to_integer(unsigned(rxAddr));
    rf_sel_z <= to_integer(unsigned(rzAddr));

    -- ALU

    -- Address Register
    data_mem_in_addr <= ("0000" & ir_opcode_signal) when dm_sel_addr = dm_sel_addr_value else
                                pc_out(11 downto 0) when dm_sel_addr = dm_sel_addr_pc else
                               rxValue(11 downto 0) when dm_sel_addr = dm_sel_addr_rx else
                               rzValue(11 downto 0) when dm_sel_addr = dm_sel_addr_rz else
                                     "000000000000";


    -- Data Memory
    data_mem_in_data <= ("00000000" & ir_opcode_signal) when dm_sel_in = dm_sel_in_value else
                                         ("0" & pc_out) when dm_sel_in = dm_sel_in_pc else
                                                rxValue when dm_sel_in = dm_sel_in_rx else
                                     "0000000000000000";

    -- Memory Model weird
    -- mem_model_pm_in_addr <= "0" & prog_mem_in;
    -- mem_model_dm_in_addr <= "0000" & data_mem_in_addr;

end behaviour;

