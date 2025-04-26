start   LDR R1 #10
        LDR R2 #20
        ADD R2 R1 R2
        STR R1 result
        NOOP
        JMP end
result  NOOP
end     NOOP
ENDPROG
END