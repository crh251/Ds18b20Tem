DSPORT  BIT 	P3.7
ANS1	DATA	30H
ANS2	DATA	31H
ANS3	DATA	32H
DIGIT	DATA	33H
POINT		DATA	34H
INITPARA	DATA	39H	;INIT function return parameter
Delay1msP	DATA	35H	;DELAY1ms	function parameter
WRITE_BYTE	DATA	36H	;Ds18b20 write byte
READ_BYTE	DATA	37H	;Ds18b20 read  byte
IS_NEGATE	DATA	38H
I_PARA		EQU		R1
J_PARA		EQU		R2
ORG	0000H
AJMP	START
ORG	0050H
START:
LCALL	Ds18b20ReadTemp
LCALL	JUDGE_TEMP		;judge temp whether lower to 0
LCALL	MULTIPLY
LCALL	Ds18b20Display
AJMP	START
RET

Ds18b20Display:	
MOV	POINT,	#00H
DIS_START:
LCALL	RUN_START
LCALL	SELECT_LIG
MOV	R1,	POINT
CJNE	R1,	#4,GO_ON_JUDGE
AJMP	LIGHT_4
GO_ON_LIGHT:
LCALL	DELAY
INC	POINT
MOV	R1,	POINT
CJNE	R1,	#8,	LIGHT_END
MOV	POINT,	#00H
RET
LIGHT_END:AJMP	DIS_START

GO_ON_JUDGE:
CJNE	R1,	#7,SIM_LIGHT
AJMP LIGHT_7

SIM_LIGHT:
MOV	A,	DIGIT
MOV	DPTR,	#TAB
MOVC	A,	@A+DPTR
MOV	P0,	A
AJMP	GO_ON_LIGHT

LIGHT_4:
MOV	A,	DIGIT
MOV	DPTR,	#TAB
MOVC	A,	@A+DPTR
ORL	A,	#80H
MOV	P0,	A
AJMP	GO_ON_LIGHT

LIGHT_7:
MOV	R1,	IS_NEGATE
CJNE	R1,	#01H,	NOT_LIGHT
MOV	P0,	#40H
LIGHT_7_END:AJMP	GO_ON_LIGHT

NOT_LIGHT:
MOV	P0,	#00H
AJMP	LIGHT_7_END

SELECT_LIG:
MOV	A,	POINT
RL	A
RL	A
MOV	P2,	A
RET

TAB:	DB	3FH,06H,05BH,04FH,66H,6DH,7DH,07H,7FH,6FH

DELAY:MOV	R6,	#1
LOOP1:	MOV	R7,	#0EEH
LOOP2:	DJNZ	R7,	LOOP2
DJNZ	R6,	LOOP1
RET

JUDGE_TEMP:
MOV	A,	ANS2
ANL	A,	#0F8H
CJNE	A,	#00H,	CHANGE_TEMP
MOV	IS_NEGATE,	#00H
RET

CHANGE_TEMP:
MOV	A,	ANS3
DEC	A
CPL	A
MOV	ANS3,	A
CJNE	A,	#0FFH,	C_T
DEC	ANS2
GO_ON_CT:
MOV	IS_NEGATE,	#01H
RET

C_T:
MOV	A,	ANS2
CPL	A
MOV	ANS2,	A
AJMP	GO_ON_CT

Ds18b20ReadTemp:
LCALL	Ds18b20ChangTemp
LCALL	Ds18b20ReadTempCom
LCALL	Ds18b20ReadByte
MOV		ANS3,	READ_BYTE
LCALL	Ds18b20ReadByte
MOV		ANS2,	READ_BYTE
RET

Ds18b20ChangTemp:
LCALL	Ds18b20Init
MOV		Delay1msP,	#1
LCALL	Delay1ms
MOV		WRITE_BYTE,	#0CCH
LCALL	Ds18b20WriteByte	//WRITE 0XCC
MOV		WRITE_BYTE,	#044H
LCALL	Ds18b20WriteByte	//WRITE	0X44
RET

Ds18b20ReadTempCom:
LCALL	Ds18b20Init
MOV		Delay1msP,	#1
LCALL	Delay1ms
MOV		WRITE_BYTE,	#0CCH
LCALL	Ds18b20WriteByte	//WRITE 0XCC
MOV		WRITE_BYTE,	#0BEH
LCALL	Ds18b20WriteByte	//WRITE	0XBE
RET

Ds18b20Init:
CLR	DSPORT
LCALL	DELAY650US
SETB	DSPORT
MOV	I_PARA,	#00H
LP_Ds18b20:	
JB	DSPORT,	J_Ds18b20	;if DSPORT	is	1, jump to J_Ds18b20.if not, go on
MOV	INITPARA,	#1
END_Ds18b20Init:	RET
J_Ds18b20:MOV	Delay1msP,	#1
ACALL	Delay1ms
INC	I_PARA
CJNE	I_PARA,	#6	,LP_Ds18b20	;if i not equal to 6,jump to LP_Ds18b20
MOV	INITPARA,	#00H
AJMP	END_Ds18b20Init

DELAY650US:
MOV R6,#42H
DL650us0:
MOV R5,#03H
DJNZ R5,$
DJNZ R6,DL650us0
RET

Delay1ms:  
DL1ms1:
MOV R6,#8EH
DL1ms0:
MOV R5,#02H
DJNZ R5,$
DJNZ R6,DL1ms0
DJNZ Delay1msP,DL1ms1
RET

Ds18b20ReadByte:
MOV      R5,#0x08
MOV      R4,#0x00
READ_FUN_1:CLR      DSPORT
INC      R7
CJNE     R7,#0x00,READ_FUN_2
READ_FUN_2:SETB     DSPORT
INC      R7
CJNE     R7,#0x00,READ_FUN_3
READ_FUN_3:INC      R7
CJNE     R7,#0x00,READ_FUN_4
READ_FUN_4:MOV      C,DSPORT
CLR      A
RLC      A
SWAP     A
RLC      A
RLC      A
RLC      A
ANL      A,#P0
MOV      R3,A
MOV      A,R1
CLR      C
RRC      A
ORL      A,R3
MOV      R1,A
MOV      R6,#0x00
MOV      R7,#0x04
READ_FUN_5:MOV      A,R7
DEC      R7
MOV      R2,0x06
JNZ      READ_FUN_6
DEC      R6
READ_FUN_6:ORL      A,R2
JNZ      READ_FUN_5
MOV      A,R5
DEC      R5
JNZ      READ_FUN_7
DEC      R4
READ_FUN_7:MOV      A,R5
ORL      A,R4
JNZ      READ_FUN_1
MOV      READ_BYTE,R1
RET


Ds18b20WriteByte:	
MOV	I_PARA,	#9
Ju_I_lower_to_8:	DJNZ	I_PARA,	WRITE_BIT
RET
WRITE_BIT:	CLR	DSPORT
INC	J_PARA
MOV	A,	WRITE_BYTE
ANL	A,	#01H
CJNE	A,	#01H,	SEND_0
AJMP	SEND_1
GO_ON_WRITE:
LCALL	DELAY68US
SETB	DSPORT
MOV	A,	WRITE_BYTE
RR	A
MOV	WRITE_BYTE,	A
AJMP	Ju_I_lower_to_8
SEND_1:SETB	DSPORT
AJMP	GO_ON_WRITE
SEND_0:CLR	DSPORT
AJMP	GO_ON_WRITE

DELAY68US:  
MOV R6,#09H
DL68us0:
MOV R5,#02H
DJNZ R5,$
DJNZ R6,DL68us0
RET

MULTIPLY:
MOV      R3,ANS3
MOV      R2,ANS2
MOV      R1,#00H
MOV      R0,#00H
MOV      R7,#71H
MOV      R6,#02H
MOV      R5,#00H
MOV      R4,#00H
MOV      A,R0
MOV      B,R7
MUL      AB
XCH      A,R4
MOV      B,R3
MUL      AB
ADD      A,R4
MOV      R4,A
MOV      A,R1
MOV      B,R6
MUL      AB
ADD      A,R4
MOV      R4,A
MOV      B,R2
MOV      A,R5
MUL      AB
ADD      A,R4
MOV      R4,A
MOV      A,R2
MOV      B,R6
MUL      AB
XCH      A,R5
MOV      R0,B
MOV      B,R3
MUL      AB
ADD      A,R5
XCH      A,R4
ADDC     A,R0
ADD      A,B
MOV      R5,A
MOV      A,R1
MOV      B,R7
MUL      AB
ADD      A,R4
XCH      A,R5
ADDC     A,B
MOV      R4,A
MOV      A,R3
MOV      B,R6
MUL      AB
MOV      R6,A
MOV      R1,B
MOV      A,R3
MOV      B,R7
MUL      AB
XCH      A,R7
XCH      A,B
ADD      A,R6
XCH      A,R5
ADDC     A,R1
MOV      R6,A
CLR      A
ADDC     A,R4
MOV      R4,A
MOV      A,R2
MUL      AB
ADD      A,R5
XCH      A,R6
ADDC     A,B
MOV      R5,A
CLR      A
ADDC     A,R4
MOV      R4,A
MOV      ANS3,R7
MOV      ANS2,R6
MOV      ANS1,R5
RET

RUN_START:
MOV      R7,ANS3
MOV      R6,ANS2
MOV      R5,ANS1
MOV      R4,#0x00
MOV      R3,#0x0A
MOV      R2,#00H
MOV      R1,#00H
MOV      R0,#00H
LCALL    RUN_FUN
MOV	DIGIT,	0X03
MOV	ANS1,	R5
MOV	ANS2,	R6
MOV	ANS3,	R7
RET

RUN_FUN:
CLR      F0
MOV      A,R0
MOV      A,R4
LCALL    RUN_SUB_FUN
RET

RUN_JMP_1:MOV      B,#0x08
MOV      DPL,#0x00
RUN_JMP_4:MOV      A,R7
ADD      A,R7
MOV      R7,A
MOV      A,R6
RLC      A
MOV      R6,A
XCH      A,R5
RLC      A
XCH      A,R5
XCH      A,R4
RLC      A
XCH      A,R4
XCH      A,DPL
RLC      A
XCH      A,DPL
SUBB     A,R3
MOV      A,R5
SUBB     A,R2
MOV      A,R4
SUBB     A,R1
MOV      A,DPL
SUBB     A,R0
JC       RUN_JMP_5
MOV      DPL,A
MOV      A,R6
SUBB     A,R3
MOV      R6,A
MOV      A,R5
SUBB     A,R2
MOV      R5,A
MOV      A,R4
SUBB     A,R1
MOV      R4,A
INC      R7
RUN_JMP_5:DJNZ     B,RUN_JMP_4
CLR      A
XCH      A,R6
MOV      R3,A
CLR      A
XCH      A,R5
MOV      R2,A
CLR      A
XCH      A,R4
MOV      R1,A
MOV      R0,DPL
RET      


RUN_SUB_FUN:
CJNE     R0,#0x00,RUN_JMP_1
CJNE     R1,#0x00,RUN_JMP_2
CJNE     R2,#0x00,RUN_JMP_3
MOV      A,R4
MOV      B,R3
DIV      AB
XCH      A,R7
XCH      A,R6
XCH      A,R5
MOV      R4,A
MOV      A,B
XCH      A,R3
MOV      R1,A
MOV      R0,#0x18
RUN_JMP_6:MOV      A,R7
ADD      A,R7
MOV      R7,A
MOV      A,R6
RLC      A
MOV      R6,A
MOV      A,R5
RLC      A
MOV      R5,A
MOV      A,R4
RLC      A
MOV      R4,A
MOV      A,R3
RLC      A
MOV      R3,A
JBC      CY,RUN_JMP_12
SUBB     A,R1
JC       RUN_JMP_13
RUN_JMP_12:MOV      A,R3
SUBB     A,R1
MOV      R3,A
INC      R7
RUN_JMP_13:DJNZ     R0,RUN_JMP_6
CLR      A
MOV      R1,A
MOV      R2,A
RET    


RUN_JMP_2:MOV      B,#0x10
RUN_JMP_10:MOV      A,R7
ADD      A,R7
MOV      R7,A
MOV      A,R6
RLC      A
MOV      R6,A
MOV      A,R5
RLC      A
MOV      R5,A
XCH      A,R4
RLC      A
XCH      A,R4
XCH      A,R0
RLC      A
XCH      A,R0
JBC      CY,RUN_JMP_8
SUBB     A,R3
MOV      A,R4
SUBB     A,R2
MOV      A,R0
SUBB     A,R1
JC       RUN_JMP_9
RUN_JMP_8:MOV      A,R5
SUBB     A,R3
MOV      R5,A
MOV      A,R4
SUBB     A,R2
MOV      R4,A
MOV      A,R0
SUBB     A,R1
MOV      R0,A
INC      R7
RUN_JMP_9:DJNZ     B,RUN_JMP_10
CLR      A
XCH      A,R5
MOV      R3,A
CLR      A
XCH      A,R4
MOV      R2,A
CLR      A
XCH      A,R0
MOV      R1,A
RET 

RUN_JMP_3:MOV      R0,#0x18
RUN_JMP_7:MOV      A,R7
ADD      A,R7
MOV      R7,A
MOV      A,R6
RLC      A
MOV      R6,A
MOV      A,R5
RLC      A
MOV      R5,A
MOV      A,R4
RLC      A
MOV      R4,A
XCH      A,R1
RLC      A
XCH      A,R1
JBC      CY,RUN_JMP_14
SUBB     A,R3
MOV      A,R1
SUBB     A,R2
JC       RUN_JMP_11
RUN_JMP_14:MOV      A,R4
SUBB     A,R3
MOV      R4,A
MOV      A,R1
SUBB     A,R2
MOV      R1,A
INC      R7
RUN_JMP_11:DJNZ     R0,RUN_JMP_7
CLR      A
XCH      A,R1
MOV      R2,A
CLR      A
XCH      A,R4
MOV      R3,A
RET 

END

