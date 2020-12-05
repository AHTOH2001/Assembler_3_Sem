.model small
.stack 100h
.data
 ;a dw ? 
 devider dw ?
 devidend dw ?
 ;temp dw ?
 IsFirstZero db 0
 IsHasMinus db 0
 IsBlockZero db 0
 Text1 db "Enter first number: ",10,13,'$'
 Text2 db 10,13,"Enter second number: ",10,13,'$'
 Text3 db 10,13,"Result: ",'$'
.code
writeAX PROC
	PUSH DX 
	PUSH BX
	PUSH CX
	PUSH AX
	
	
	
	MOV BX, 10	
	TEST AX, AX
	JNS NotNegative			
		MOV CX, AX		
		MOV DL, '-'
		MOV AH, 02h
		INT 21h
		MOV AX, CX
		NEG AX
	NotNegative:
	XOR CX, CX		
	
	Cycle1:		
		XOR DX, DX	
		;CWD
		DIV BX
		PUSH DX
		INC CX
		CMP AX, 0		
		JNE Cycle1
			
	Cycle2:
		POP DX
		ADD DL,'0'		
		MOV AH, 02h
		INT 21h
		LOOP Cycle2

	POP AX
	POP CX
	POP BX
	POP DX
	RET
writeAX ENDP
readAX PROC
	JMP label1
	 a dw ? 
	 temp dw ?
	label1:

	PUSH DX 
	PUSH BX
	PUSH CX	
	PUSH a
	PUSH temp
	
	
	
	XOR AX, AX
	MOV a, AX
	MOV BX, 10
	AND IsFirstZero, 0
	AND IsHasMinus, 0		
	
	Cycle3:
		MOV AH, 08h
		INT 21h
		XOR AH, AH	
		
		CMP AL, 08		
		JNE NotBackspace
			CALL backspace
			JMP Cycle3
		NotBackspace:		
		
		CMP AL, '-'
		JNE NotMinus
			CMP IsHasMinus, 1
			JE Cycle3
			CMP a, 0
			JNE Cycle3
			CMP IsFirstZero, 1
			JE Cycle3
			OR IsHasMinus, 1
			MOV DL, '-'		
			MOV AH, 02h
			INT 21h
			JMP Cycle3
		NotMinus:

		CMP AL, 13		
		JNE NotEnter
			CMP IsBlockZero, 1
			JNE NotBlock
				CMP a, 0
				JE Cycle3
			NotBlock:
			JMP ExitCycle3
		NotEnter:			


		CMP AL, 27
		JNE NotEscape						
			Cycle4:
				CALL backspace
				CMP a, 0
				JNE Cycle4
				CMP IsHasMinus, 1
				JE Cycle4
			JMP Cycle3
		NotEscape:		
		
		
		CMP AL, '9' 
		JA Cycle3
		CMP AL, '0'
		JB Cycle3
		
		CMP IsFirstZero, 1
			JE Cycle3
		
		CMP AL, '0'
		JNE NotZero1			
			CMP a, 0
			JNE NotFirst								
				CMP IsHasMinus, 1
				JNE Forward
					JMP Cycle3				
				Forward:
				OR IsFirstZero, 1 ;MOV 1				
			NotFirst:
		NotZero1:
				
		
		
		MOV DL, AL		
		MOV AH, 02h
		INT 21h
		SUB AL, '0'
		XOR AH, AH
		MOV temp, AX ;MOV last digit		
		MOV AX, a
		IMUL BX
		JNC NotRE1
			MOV AX, a
			CALL backspace
			MOV a, AX
			JMP Cycle3						
		NotRE1:
		ADD AX, temp		
		JNO NotRE2
			MOV AX, a
			CALL backspace
			MOV a, AX
			JMP Cycle3						
		NotRE2:
		
		
		MOV a, AX
	
		JMP Cycle3
	ExitCycle3:	
	
	CMP a, 0
	JNE NotZeroRes			
		CMP IsHasMinus, 1
		JNE NotMinus2													
			JMP Cycle3
		NotMinus2:
	NotZeroRes:

	MOV AX,a
	CMP IsHasMinus, 1
	JNE NotMinus1
		NEG AX
	NotMinus1:
	POP temp
	POP a
	POP CX
	POP BX
	POP DX
	RET
readAX ENDP
backspace PROC
	PUSH AX
	PUSH BX
	PUSH DX
		
	MOV DL, 08		
	MOV AH, 02h
	INT 21h
	MOV DL,32		
	MOV AH, 02h
	INT 21h	
	MOV DL, 08		
	MOV AH, 02h
	INT 21h
	
	CMP a, 0
	JNE NotZero2
		AND IsFirstZero, 0
		AND IsHasMinus, 0
	NotZero2:

	XOR DX, DX
	MOV AX, a
	MOV BX, 10
	CWD
	IDIV BX
	MOV a, AX	
	
	POP DX
	POP BX
	POP AX
	RET
backspace ENDP
main:
mov ax, @data
mov ds, ax
LEA DX, Text1
MOV AH, 09h
INT 21h
CALL readAX
MOV devidend, AX

LEA DX, Text2
MOV AH, 09h
INT 21h
OR IsBlockZero, 1
CALL readAX
MOV devider, AX

LEA DX, Text3
MOV AH, 09h
INT 21h

XOR DX, DX
MOV AX, devidend
MOV BX, devider
CWD
IDIV BX
CALL writeAX

MOV temp, DX
MOV DL, ' '
MOV AH, 02h
INT 21h
MOV DL, '('
MOV AH, 02h
INT 21h
MOV AX, temp
CALL writeAX

MOV DL, ')'
MOV AH, 02h
INT 21h 

; CALL readAX
; CALL writeAX

mov ax, 4c00h
int 21h
end main