; Print.s
; Student names: change this to your names or look very silly
; Last modification date: change this to the last modification date or look very silly
; Runs on TM4C123
; EE319K lab 7 device driver for any LCD
;
; As part of Lab 7, students need to implement these LCD_OutDec and LCD_OutFix
; This driver assumes two low-level LCD functions
; ST7735_OutChar   outputs a single 8-bit ASCII character
; ST7735_OutString outputs a null-terminated string 

FP 		RN 11
Count 	EQU 0
Num 	EQU 4

    IMPORT   ST7735_OutChar
    IMPORT   ST7735_OutString
    EXPORT   LCD_OutDec
    EXPORT   LCD_OutFix
	PRESERVE8 
    AREA    |.text|, CODE, READONLY, ALIGN=2
    THUMB


;-----------------------LCD_OutDec-----------------------
; Output a 32-bit number in unsigned decimal format
; Input: R0 (call by value) 32-bit unsigned number
; Output: none
; Invariables: This function must not permanently modify registers R4 to R11
; R0=0,    then output "0"
; R0=3,    then output "3"
; R0=89,   then output "89"
; R0=123,  then output "123"
; R0=9999, then output "9999"
; R0=4294967295, then output "4294967295"
LCD_OutDec
	  PUSH{R4-R9, R11, LR}
	  SUB SP, #8 ;allocation
	  MOV FP, SP  ;copy now stack pointer to frame pointer
	  STR R0, [FP, #Num] ; num = R0
	  MOV R4, #0
	  STR R4, [FP, #Count] ;count = 0 initalization
	  MOV R5, #10   ; R5= 10
	  ;initalizations done------------------------------------
loop
	  LDR R4, [FP, #Num]
	  CMP R4, #0
	  BEQ Next  
	  ;if not, Num%10, save it
	  ;r6 = quotient
	  ;r4 = number
	  ;r5 = 10
	  ;r7 = 10*quotient
	  ;r8 = remainder
	  UDIV R6, R4, R5   ;num/10
	  MUL R7, R6, R5   ;R7  = 10*quotient
	  SUB R8, R4, R7   ; R8 = remainder = num - 10*quotient
	  PUSH{R8} ;put the first number of R0 onto the stack
	  STR R6, [FP, #Num]  ;num = num/10, or new quotient
	  LDR R6, [FP, #Count] ; R6 has count, R6 = count
	  ADD R6, #1 ;count++
	  STR R6, [FP, #Count]
	  B loop
Next  
	  LDR R4, [FP, #Count]  
	  CMP R4, #0
	  BEQ Done  ;if count is 0, then finish running this
	  POP{R0}
	  ADD R0, #0x30
	  BL ST7735_OutChar ;call this to output char into LCD screen
	  SUB R4, #1
	  STR R4, [FP, #Count]
	  B Next
Done
	  ADD SP, #8 ;deallocation
	  POP{R4-R9, R11, LR}

      BX  LR
;* * * * * * * * End of LCD_OutDec * * * * * * * *

; -----------------------LCD_OutFix----------------------
; Output characters to LCD display in fixed-point format
; unsigned decimal, resolution 0.001, range 0.000 to 9.999
; Inputs:  R0 is an unsigned 32-bit number
; Outputs: none
; E.g., R0=0,    then output "0.000"
;       R0=3,    then output "0.003"
;       R0=89,   then output "0.089"
;       R0=123,  then output "0.123"
;       R0=9999, then output "9.999"
;       R0>9999, then output "*.***"
; Invariables: This function must not permanently modify registers R4 to R11
LCD_OutFix
	 PUSH{R4-R9, R11, LR}
	 SUB SP, #8 ;allocation
	 MOV FP, SP  ;copy now stack pointer to frame pointer
	 STR R0, [FP, #Num] ; num = R0
	 MOV R4, #0
	 STR R4, [FP, #Count] ;count = 0 initalization
	 MOV R5, #10   ; R5= 10
	  ;initalizations done------------------------------------
loopOut
	 LDR R4, [FP, #Num]
	 CMP R4, #0
	 BEQ NextOut  
	  ;if not, Num%10, save it
	  ;r6 = quotient
	  ;r4 = number
	  ;r5 = 10
	  ;r7 = 10*quotient
	  ;r8 = remainder
	 UDIV R6, R4, R5   ;num/10
	 MUL R7, R6, R5   ;R7  = 10*quotient
	 SUB R8, R4, R7   ; R8 = remainder = num - 10*quotient
	 PUSH{R8} ;put the first number of R0 onto the stack
	 STR R6, [FP, #Num]  ;num = num/10, or new quotient
	 LDR R6, [FP, #Count] ; R6 has count, R6 = count
	 ADD R6, #1 ;count++
	 STR R6, [FP, #Count]
	 B loopOut
NextOut  
	 LDR R4, [FP, #Count]  
	 CMP R4, #5
	 BHS greaterthan4  ;if count >= 5
	 CMP R4, #4
	 BEQ equal4 ;if count == 4
	 ;else
	 MOV R5, #4 ; R5 = 4
	 SUB R5, R4 ; 4 - count, or zeros count
	 SUB R6, R5, #1  ; count (for the zeros) - 1
outzero ;loop for outputting zeros
	 MOV R0, #0x30 ;ascii code for 0
	 BL ST7735_OutChar 
	 SUBS R5, #1 ;decrements counter for zeros
	 CMP R5, R6 ;checks if you need to output a period
	 BEQ outperiod
continue
	 CMP R5, #0
	 BNE outzero
	 CMP R4, #0
	 BEQ DoneOut
outchar ;outputs characters after outputting zeros
	 POP{R0}
	 ADD R0, #0x30
	 BL ST7735_OutChar 
	 SUBS R4, #1
	 CMP R4, #0
	 BNE outchar
	 B DoneOut
	 
outperiod ;outputs period
	 MOV R0, #0x2E ;0x2E is "."
	 BL ST7735_OutChar
	 B continue
	 ;*** error 65: access violation at 0x00017934 : no 'read' permissio
	  
equal4
	 POP {R0}
	 ADD R0, #0x30
	 BL ST7735_OutChar
	 MOV R0, #0x2E ;0x2E is "."
	 BL ST7735_OutChar
	 POP {R0}
	 ADD R0, #0x30
	 BL ST7735_OutChar
	 POP {R0}
	 ADD R0, #0x30
	 BL ST7735_OutChar
	 POP {R0}
	 ADD R0, #0x30
	 BL ST7735_OutChar
	 B DoneOut
	 
greaterthan4  ;output is "*.***"
	 MOV R0, #0x2A ; 0x2A is "*"
	 BL ST7735_OutChar
	 MOV R0, #0x2E ;0x2E is "."
	 BL ST7735_OutChar
	 MOV R0, #0x2A
	 BL ST7735_OutChar
	 MOV R0, #0x2A
	 BL ST7735_OutChar
	 MOV R0, #0x2A
	 BL ST7735_OutChar
popcount
	 POP{R0}
	 SUB R4, #1
	 CMP R4, #0
	 BNE popcount
	 B DoneOut
	 
DoneOut
	 ADD SP, #8 ;deallocation
	 POP{R4-R9, R11, LR}
     BX   LR
 
     ALIGN
;* * * * * * * * End of LCD_OutFix * * * * * * * *

     ALIGN                           ; make sure the end of this section is aligned
     END                             ; end of file
