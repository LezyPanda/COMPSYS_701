	NOOP					;              31~28 = Packet   27~24 = Addr
	LDR R0 #0x9100			;ADC 	Config 31~28 = 1001, 	27~24 = 0001,	23 = 0
	DATACALL2 R0 #0x0004 	;ADC 	Config 3	 = 0, 		  2~0 = 100
	LDR R0 #0x9280			;Avg 	Config 31~28 = 1001, 	27~24 = 0002,	23 = 1
	DATACALL2 R0 #0x0024 	;Avg 	Config 10~3  = 00000100,  2~0 = 100
	LDR R0 #0xA300          ;CORR 	Config 31~28 = 1010		27~24 = 0003
	DATACALL2 R0 #0x0002    ;CORR 	Config 2~0   = 010
	LDR R0 #0x0000 			;CLEAR
	DATACALL2 R0 #0x0000	;CLEAR
	NOOP
ENDPROG
END