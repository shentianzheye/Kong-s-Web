.MODEL     TINY
EXTRN         Display8:NEAR
;;;;;;;8279;;;;;;
CMD_8279 EQU 0BF01H
DATA_8279 EQU 0BF00H
;;;;;;;8255;;;;;;
COM_ADD EQU 0F003H
PA_ADD EQU 0F000H
PB_ADD EQU 0F001H
PC_ADD EQU 0F002H
;;;;;;;;;;;;8259;;;;;;;;;;;;;;;
I08259_0      EQU        0E000H
I08259_1      EQU        0E001H
;;;;;;;;;;;;;;8253;;;;;;;;;;;;;;;;;
COM_ADDR EQU 0A003H
T0_ADDR	EQU 0A000H
T1_ADDR	EQU 0A001H


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DATA;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.STACK     100
.DATA
;;;;;;;;;;;;;;;;;;8255流水灯;;;;;;;;;;;;;;;;;;;;;
LED_Data DB 00011111B;模式0
   	 DB 00000111B;模式1
	 DB 00000000B;模式2
;;;;;;;;;;;;;;;;;;8279按键数码管;;;;;;;;;;;;;;;;;;;;;;
KEYCOUNT DB ?
LED_TAB	DB 0C0H,0F9H,0A4H,0B0H,99H,92H,82H,0F8H
	DB 080H,90H,88H,83H,0C6H,0A2H,86H,8EH

BUFFER        DB         8 DUP(?)
Counter       DB         ?
ReDisplayFlag DB         0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;CODE;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              .CODE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;主程序;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START:	MOV AX,@DATA
	MOV DS,AX
	NOP
	;;;;;;;8279;;;;;;;;;;
	CALL INIT8279
START1:	CALL SCAN_KEY
	JNC START1
	XCHG AL,KEYCOUNT
	INC AL
	CMP AL,2
	JNZ START2
	JMP START1
START2:	XCHG AL,KEYCOUNT
	CALL KEY_NUM
	CALL MOXUAN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;8279初始化;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT8279 PROC NEAR
	MOV DX,CMD_8279
	MOV AL,34H
	OUT DX,AL
	MOV AL,0
	OUT DX,AL
	MOV AL,0
	OUT DX,AL
	MOV AL,0A0H
	OUT DX,AL
	CALL INIT8279_1
	RET
INIT8279	ENDP

INIT8279_1	PROC NEAR
	CALL CLEAR
	MOV AL,90H
	OUT DX,AL
	RET
INIT8279_1 ENDP
CLEAR	PROC NEAR
MOV DX,CMD_8279
	MOV AL,0DEH
	OUT DX,AL
WAIT1:	IN AL,DX
	TEST AL,80H
	JNZ WAIT1
	RET
CLEAR	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;扫描有无按键输入;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SCAN_KEY PROC NEAR
	MOV DX,CMD_8279
	IN AL,DX
READ_F1F0: AND AL,7
	JZ NO_KEY
READ: 	MOV AL,40H
	OUT DX,AL
	MOV DX,DATA_8279
	IN AL,DX
	STC
SCAN_KEY1: RET
NO_KEY:	CLC
	JMP SCAN_KEY1
SCAN_KEY ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;按键数字数码管显示;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WRITE_DATA	PROC NEAR
	MOV DX,DATA_8279
	OUT DX,AL
	RET
WRITE_DATA	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;按键数字化;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
KEY_NUM	PROC NEAR
	AND AL,3FH
	RET
KEY_NUM	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;模式选择;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOXUAN	PROC NEAR
	CMP AL,0
	JZ P0
	CMP AL,1
	JZ P1
	CMP AL,2
	JZ P2
	JMP START1
P0:	PUSH AX;模式0
	LEA BX,LED_TAB
	XLAT
	CALL WRITE_DATA
	CALL CD0	
P1:	PUSH AX;模式1
	LEA BX,LED_TAB
	XLAT
	CALL WRITE_DATA
	CALL CD1	
P2:	PUSH AX;模式2
	LEA BX,LED_TAB
	XLAT
	CALL WRITE_DATA
	CALL CD2
MOXUAN	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;8255初始化;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
A8255	PROC NEAR
	MOV DX,COM_ADD;端口全输出
	MOV AL,80H
	OUT DX,AL
	MOV DX,PA_ADD;控制灯全灭
	MOV AL,0FFH
	OUT DX,AL
	LEA BX,LED_Data;给表地址
	RET
A8255	ENDP		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;倒计时;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;5秒;;;;;;;;;;;;;;;;;
CD0	PROC NEAR
	NOP
	MOV        Counter,5;十六进制16-十进制10秒
	MOV        ReDisplayFlag,1
	CALL       LedDisplay
	MOV CX,5
LOOP0:	CALL SECOND
	CALL TEST_C3
CD0_1:	CMP        ReDisplayFlag,0
	JZ         CD0_1
	CALL       LedDisplay	  
	MOV        ReDisplayFlag,0
	DEC CX
	CALL SCAN_PW;
	CALL ECD;End of Counting Down
	JNZ	LOOP0
CD0	ENDP
;;;;;;;;;;;;;10秒;;;;;;;;;;;;;;;;;;;
CD1	PROC NEAR
	NOP
	MOV        Counter,16;bcd十六进制10秒-十进制16
	MOV        ReDisplayFlag,1
	CALL       LedDisplay
	MOV CX,10
LOOP1:	CALL SECOND
	CALL TEST_C3
CD1_1:	CMP        ReDisplayFlag,0
	JZ         CD1_1
	CALL       LedDisplay	  
	MOV        ReDisplayFlag,0
	DEC CX
	CALL SCAN_PW
	CALL ECD;End of Counting Down
	JNZ	LOOP1
CD1	ENDP
;;;;;;;;;;;;;;;;15秒;;;;;;;;;;;;;;;;;;;;
CD2	PROC NEAR
	NOP
	MOV        Counter,21;bcd十六进制21-十进制15秒
	MOV        ReDisplayFlag,1
	CALL       LedDisplay
	MOV CX,15
LOOP2:	CALL SECOND
	CALL TEST_C3
CD2_1:	CMP 	   ReDisplayFlag,0
	JZ	CD2_1
	CALL       LedDisplay
	MOV        ReDisplayFlag,0
	DEC	CX
	CALL SCAN_PW
	CALL ECD;End of Counting Down
	JNZ	LOOP2	
CD2	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;数码管显示;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LedDisplay    PROC       NEAR
              MOV        AL,Counter
	      MOV        AH,AL
	      AND        AL,0FH
	      MOV        Buffer,AL
	      AND        AH,0F0H
	      ROR        AH,4
	      MOV        Buffer + 1,AH
			  MOV        Buffer + 2,10H
			  MOV        Buffer + 3,10H
			  MOV        Buffer + 4,10H
			  MOV        Buffer + 5,10H
			  MOV        Buffer + 6,10H
			  MOV        Buffer + 7,10H
			  LEA        SI,Buffer
			  CALL       Display8
			  RET
LedDisplay    ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;8253一秒定时计数器;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SECOND	PROC NEAR	
	MOV DX,COM_ADDR;计数器T0设置在模式2状态，BCD码计数
	MOV AL,35H
	OUT DX,AL
	MOV DX,T0_ADDR
	MOV AL,00H
	OUT DX,AL
	MOV AL,10H
	OUT DX,AL;0.001s
	MOV DX,COM_ADDR;计数器T1设置在模式0状态，BCD码计数
	MOV AL,71H;01110001--71H
	OUT DX,AL
	MOV DX,T1_ADDR
	MOV AL,00H
	OUT DX,AL
	MOV AL,10H
	OUT DX,AL;1秒
	RET
SECOND	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;8255 PC3高电平检查是否经过一秒;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TEST_C3	PROC NEAR
	MOV DX,COM_ADD;8255端口全输出
	MOV AL,93H;10010011
	OUT DX,AL
TEST_C31:	MOV DX,PC_ADD
		IN AL,DX
		CMP AL,01H;00000000看PC0有没有低电平进入
		JNZ TEST_C31 
TEST_C32:	MOV DX,PC_ADD
		IN AL,DX
		CMP AL,01H;00000001看PC0有没有高电平进入
		JNZ TEST_C32  
	MOV ReDisplayFlag,1
	MOV AL,Counter
	SUB AL,1
	DAS
	MOV Counter,AL
	RET
TEST_C3	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;检查有无中断密码输入;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SCAN_PW	PROC NEAR
	CALL Init8259
	CALL WriIntver
	STI
	RET
SCAN_PW	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;检查倒数是否结束;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ECD	PROC NEAR
	MOV AL,COUNTER
	CMP AL,00000000B
	JZ DOWN
	RET
DOWN:	CALL LedDisplay
	POP CX
	POP CX
	JMP LIGHT

ECD	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;爆炸小灯;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LIGHT   PROC NEAR
	CALL A8255
	POP AX
	XLAT
	OUT DX,AL
	CALL DL3S
	MOV DX,PA_ADD;控制灯全灭
	MOV AL,0FFH
	OUT DX,AL
	HLT
LIGHT	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;延时3秒;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DL3S PROC NEAR
	PUSH CX
	MOV CX,6
DL3S1:CALL DL500ms
	LOOP DL3S1
	POP CX
	RET
DL3S ENDP
DL500ms PROC NEAR
	PUSH CX
	MOV CX,60000
DL500ms1:LOOP DL500ms1
	POP CX
	RET
DL500ms ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;8259初始化;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Init8259      PROC       NEAR
              		  MOV        DX,I08259_0
			  MOV        AL,13H
			  OUT        DX,AL
			  MOV        DX,I08259_1
			  MOV        AL,08H
			  OUT        DX,AL
			  MOV        AL,09H
			  OUT        DX,AL
			  MOV        AL,0FEH
			  OUT        DX,AL
			  RET
Init8259      ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;中断向量表写入;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WriIntver     PROC       NEAR
              PUSH       ES
			  MOV        AX,0
			  MOV        ES,AX
			  MOV        DI,20H
			  LEA        AX,INT_0
			  STOSW
			  MOV        AX,CS
			  STOSW
			  POP        ES
			  RET
WriIntver     ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;中断子程序;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INT_0: 	MOV DX,PB_ADD
	IN AL,DX
	CMP AL,80H;10000000
	JZ ORI
	JMP BOOM
ORI:	JMP START
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;直爆程序;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BOOM	PROC NEAR
	CALL A8255
	POP CX
	POP CX
	POP CX
	POP CX
	POP CX;清堆栈
	POP AX
	XLAT
	OUT DX,AL
	CALL DL3S
	MOV DX,PA_ADD;控制灯全灭
	MOV AL,0FFH
	OUT DX,AL
	HLT
BOOM	ENDP
			  END        START
