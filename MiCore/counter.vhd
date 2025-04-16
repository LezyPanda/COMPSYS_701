entity counter is
    port (
        Clk, Reset : in bit;
        Q : out integer
    );
end entity counter;

architecture behaviour of counter is
begin
    process (Clk)
        variable v_Q: integer := 5; -- Fixed typo and initialized
    begin
        if (Clk'event and Clk = '1') then -- Use '1' for bit type
            if (Reset = '1') then         -- Use '=' for comparison
                v_Q := 5;
            elsif (v_Q /= 15) then
                v_Q := v_Q + 1;           -- Fixed increment
            else
                v_Q := 5;
            end if;
        end if;
        Q <= v_Q;                         -- Use signal assignment
    end process;
end architecture behaviour;