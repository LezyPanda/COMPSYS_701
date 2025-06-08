library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


use work.recop_types.all;
use work.opcodes.all;
use work.various_constants.all;
use work.TdmaMinTypes.all;


entity recop is
    port (
        clock       : in bit_1;
        key         : in bit_4;
        sw          : in bit_10;
        ledr        : out bit_10;
        -- hex0        : out bit_7;
        -- hex1        : out bit_7;
        -- hex2        : out bit_7;
        -- hex3        : out bit_7;
        -- hex4        : out bit_7;
        -- hex5        : out bit_7;

        recv  : in  tdma_min_port;
		send  : out tdma_min_port
    );
end recop;

architecture combined of recop is
    -- Internal simulated clock/reset
    signal clk   : bit_1 := '0';
    signal reset : bit_1 := '1';

    -- Control Signals
    signal dm_sel_addr     : bit_2;
    signal dm_sel_in       : bit_2;
    signal dm_write        : bit_1;
    signal ir_fetch_start  : bit_1;
    signal rf_sel_in       : bit_3;
    signal rf_write_flag   : bit_1;
    signal pc_write_flag   : bit_1;
    signal pc_mode         : bit_2;
    signal alu_clr_z_flag  : bit_1;
    signal alu_operation   : bit_3;
    signal alu_sel_op1     : bit_2;
    signal alu_sel_op2     : bit_1;
    signal dpcr_write_flag : bit_1;
    signal dpcr_sel        : bit_1;
    signal irq_clr         : bit_1;
    signal sop_write       : bit_1;
    signal alu_z_flag      : bit_1;
    signal alu_result      : bit_16;
    signal ir_opcode       : bit_8;
    signal inst_fetched    : bit_1;
    signal rz_empty        : bit_1;
    signal dpcr            : bit_32 := (others => '0');

    -- Debug Signals DP
    signal debug_pc_out         : bit_15;
    signal debug_fetch_state    : bit_2;
    signal debug_instruction    : bit_32;
    signal debug_prog_mem_in    : bit_15;
    signal debug_prog_mem_out   : bit_16;
    signal debug_rx_addr        : bit_4;
    signal debug_rz_addr        : bit_4;
    signal debug_rx_value       : bit_16;
    signal debug_rz_value       : bit_16;
    signal debug_ir_operand     : bit_16;
    signal debug_rf_reg_listen  : integer range 0 to 15;
    signal debug_rf_reg_result  : bit_16;
    -- Debug Signals CU
    signal debug_state          : bit_2;
    signal debug_next_state     : bit_2;
    signal debug_flag           : bit_8;

    -- Signals
    signal ledr_signal : bit_10 := "0000000000";
    signal hex0_in_signal : bit_4 := "0000";
    signal hex1_in_signal : bit_4 := "0000";
    signal hex2_in_signal : bit_4 := "0000";
    signal hex3_in_signal : bit_4 := "0000";
    signal hex4_in_signal : bit_4 := "0000";
    signal hex5_in_signal : bit_4 := "0000";
    signal hex0_signal : bit_7 := "0000000";
    signal hex1_signal : bit_7 := "0000000";
    signal hex2_signal : bit_7 := "0000000";
    signal hex3_signal : bit_7 := "0000000";
    signal hex4_signal : bit_7 := "0000000";
    signal hex5_signal : bit_7 := "0000000";

    component Bcd2seg7 is
        port (
            conv_in  : in bit_4;
            conv_out : out bit_7
        );
    end component;
    
    component datapath is
        port (
            clk             : in bit_1;
            reset           : in bit_1;
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
            irq_clr         : in bit_1;
            sop_write       : in bit_1;
            alu_z_flag      : out bit_1;
            alu_result      : out bit_16;
            ir_opcode       : out bit_8;
            inst_fetched    : out bit_1;
            rz_empty        : out bit_1;
            dpcr            : out bit_32;
            -- Debug Signals
            debug_pc_out        : out bit_15;
            debug_fetch_state   : out bit_2;
            debug_instruction   : out bit_32;
            debug_prog_mem_in   : out bit_15;
            debug_prog_mem_out  : out bit_16;
            debug_rx_addr       : out bit_4;
            debug_rz_addr       : out bit_4;
            debug_rx_value      : out bit_16;
            debug_rz_value      : out bit_16;
            debug_ir_operand    : out bit_16;
            -- Debug Signals
            debug_rf_reg_listen : in integer range 0 to 15;
            debug_rf_reg_result : out bit_16;
            debug_flag          : out bit_8
        );
    end component;

    component control_unit is
        port (
            clk             : in bit_1;
            reset           : in bit_1;
            dm_sel_addr     : out bit_2;
            dm_sel_in       : out bit_2;
            dm_write        : out bit_1;
            ir_fetch_start  : out bit_1;
            rf_sel_in       : out bit_3;
            rf_write_flag   : out bit_1;
            pc_write_flag   : out bit_1;
            pc_mode         : out bit_2;
            alu_clr_z_flag  : out bit_1;
            alu_operation   : out bit_3;
            alu_sel_op1     : out bit_2;
            alu_sel_op2     : out bit_1;
            dpcr_write_flag : out bit_1;
            dpcr_sel        : out bit_1;
            irq_clr         : out bit_1;
            sop_write       : out bit_1;
            alu_z_flag      : in bit_1;
            alu_result      : in bit_16;
            ir_opcode       : in bit_8 := (others => '0');
            inst_fetched    : in bit_1;
            rz_empty        : in bit_1;
            -- Debug Signals
            debug_state         : out bit_2;
            debug_next_state    : out bit_2
        );
    end component;

    signal sendSignal   : tdma_min_port := (others => (others => '0'));
begin
    -- BCD to 7-segment decoder instances
    -- hex0_inst: Bcd2seg7 port map (hex0_in_signal, hex0_signal);
    -- hex1_inst: Bcd2seg7 port map (hex1_in_signal, hex1_signal);
    -- hex2_inst: Bcd2seg7 port map (hex2_in_signal, hex2_signal);
    -- hex3_inst: Bcd2seg7 port map (hex3_in_signal, hex3_signal);
    -- hex4_inst: Bcd2seg7 port map (hex4_in_signal, hex4_signal);
    -- hex5_inst: Bcd2seg7 port map (hex5_in_signal, hex5_signal);

    -- Datapath Instance
    impl_datapath: datapath
        port map (
            clk             => clk,
            reset           => reset,
            dm_sel_addr     => dm_sel_addr,
            dm_sel_in       => dm_sel_in,
            dm_write        => dm_write,
            ir_fetch_start  => ir_fetch_start,
            rf_sel_in       => rf_sel_in,
            rf_write_flag   => rf_write_flag,
            pc_write_flag   => pc_write_flag,
            pc_mode         => pc_mode,
            alu_clr_z_flag  => alu_clr_z_flag,
            alu_operation   => alu_operation,
            alu_sel_op1     => alu_sel_op1,
            alu_sel_op2     => alu_sel_op2,
            dpcr_write_flag => dpcr_write_flag,
            dpcr_sel        => dpcr_sel,
            dpcr            => dpcr,
            irq_clr         => irq_clr,
            sop_write       => sop_write,
            alu_z_flag      => alu_z_flag,
            alu_result      => alu_result,
            ir_opcode       => ir_opcode,
            inst_fetched    => inst_fetched,
            rz_empty        => rz_empty,
            -- Debug Signals
            debug_pc_out    => debug_pc_out,
            debug_fetch_state => debug_fetch_state,
            debug_instruction => debug_instruction,
            debug_prog_mem_in => debug_prog_mem_in,
            debug_prog_mem_out => debug_prog_mem_out,
            debug_rx_addr   => debug_rx_addr,
            debug_rz_addr   => debug_rz_addr,
            debug_rx_value  => debug_rx_value,
            debug_rz_value  => debug_rz_value,
            debug_ir_operand => debug_ir_operand,
            debug_rf_reg_listen => debug_rf_reg_listen,
            debug_rf_reg_result => debug_rf_reg_result,
            debug_flag => debug_flag
        );

    -- Control Unit Instance
    impl_control_unit: control_unit
        port map (
            clk             => clk,
            reset           => reset,
            dm_sel_addr     => dm_sel_addr,
            dm_sel_in       => dm_sel_in,
            dm_write        => dm_write,
            ir_fetch_start  => ir_fetch_start,
            rf_sel_in       => rf_sel_in,
            rf_write_flag   => rf_write_flag,
            pc_write_flag   => pc_write_flag,
            pc_mode         => pc_mode,
            alu_clr_z_flag  => alu_clr_z_flag,
            alu_operation   => alu_operation,
            alu_sel_op1     => alu_sel_op1,
            alu_sel_op2     => alu_sel_op2,
            dpcr_write_flag => dpcr_write_flag,
            dpcr_sel        => dpcr_sel,
            irq_clr         => irq_clr,
            sop_write       => sop_write,
            alu_z_flag      => alu_z_flag,
            alu_result      => alu_result,
            ir_opcode       => ir_opcode,
            inst_fetched    => inst_fetched,
            rz_empty        => rz_empty,
            -- Debug Signals
            debug_state     => debug_state,
            debug_next_state => debug_next_state
        );

    clk <= clock;

    
    process(clock)
        variable reset_counter : integer := 0;
    begin
        if (rising_edge(clock)) then
            if (reset_counter < 100) then
                reset <= '1';
                reset_counter := reset_counter + 1;
            else
                if (key(0) = '0') then -- First Button Pressed: Reset
                    reset <= '1';
                else
                    reset <= '0';
                    if (dpcr(31 downto 28) = "0000") then           -- DPCR is empty
                        if (key(1) = '0') then                          -- 2nd Button Pressed
                            sendSignal.addr <= "00000001";                  -- To ADCAsp
                            sendSignal.data <= (others => '0');             -- Clear
                            sendSignal.data(31 downto 28) <= "1001";        -- Config Packet
                            sendSignal.data(23) <= '0';                     -- ADC Config Packet
                            sendSignal.data(3) <= sw(3);                    -- ADC Bit Size
                            sendSignal.data(2 downto 0) <= sw(2 downto 0);  -- ADC Sampling Delay/Period | 1 | 2 | 4 | 8 | 16 | 32 | 64 | 128 |
                        elsif (key(2) = '0') then                       -- 3rd Button Pressed
                            sendSignal.addr <= "00000010";                  -- To LAF
                            sendSignal.data <= (others => '0');             -- Clear
                            sendSignal.data(31 downto 28) <= "1001";        -- Config Packet
                            sendSignal.data(23) <= '1';                     -- LAF Config Packet
                            sendSignal.data(9 downto 3) <= sw(9 downto 3);  -- Correlation Sample Interval
                            sendSignal.data(2 downto 0) <= sw(2 downto 0);  -- AVG Window | 4 | 8 | 16 | 32 | 64 |
                        elsif (key(3) = '0') then                       -- 4th Button Pressed
                            sendSignal.addr <= "00000011";                  -- To CorAsp
                            sendSignal.data <= (others => '0');             -- Clear
                            sendSignal.data(31 downto 28) <= "1010";        -- Cor Config Packet
                            sendSignal.data(2 downto 0) <= sw(2 downto 0);  -- Correlation Window
                        else
                            sendSignal.addr <= (others => '0');  -- Clear
                            sendSignal.data <= (others => '0');  -- Clear
                        end if;
                    else                                            -- DPCR is not empty
                        sendSignal.addr <= (others => '0');                     -- Clear
                        sendSignal.addr(3 downto 0) <= dpcr(27 downto 24);      -- Target Address
                        sendSignal.data <= (others => '0');                     -- Clear
                        sendSignal.data(31 downto 28) <= dpcr(31 downto 28);    -- Packet Type
                        sendSignal.data(23 downto 0) <= dpcr(23 downto 0);      -- Data
                    end if;
                end if;
            end if;
        end if;
    end process;

    send <= sendSignal;
end combined;
