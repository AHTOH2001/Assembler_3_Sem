.model small
.stack 100h
.data
 a dw ? 
 res1 dw ?
 res2 dw ?
 temp dw ?
 IsFirstZero db 0
 IsBlockZero db 0
 Text1 db "Enter first positive number: ",10,13,'$'
 Text2 db 10,13,"Enter second positive number: ",10,13,'$'
 Text3 db 10,13,"Result: ",'$'
.code
writeAX PROC
	PUSH DX 
	PUSH BX
	PUSH CX
	PUSH AX
	
	MOV BX, 10
	XOR CX, CX		
		
	Cycle1:		
		XOR DX, DX	
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
	
	XOR DX, DX
	MOV AX, a
	MOV BX, 10
	DIV BX
	MOV a, AX
	
	CMP a, 0
	JNE NotZero2
		AND IsFirstZero, 0
	NotZero2:
	
	POP DX
	POP BX
	POP AX
	RET
backspace ENDP
readAX PROC
	PUSH DX 
	PUSH BX
	PUSH CX	
	XOR AX, AX
	MOV a, AX
	MOV BX, 10
	AND IsFirstZero, 0
	
	Cycle3:
		MOV AH, 08h
		INT 21h
		XOR AH, AH	
		
		CMP AL, 08		
		JNE NotBackspace
			CALL backspace
			JMP Cycle3
		NotBackspace:
		
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
				cmp a, 0
				JNE Cycle4
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
		MUL BX
		JNC NotRE1
			MOV AX, a
			CALL backspace
			MOV a, AX
			JMP Cycle3						
		NotRE1:
		ADD AX, temp		
		JNC NotRE2
			MOV AX, a
			CALL backspace
			MOV a, AX
			JMP Cycle3						
		NotRE2:
		MOV a, AX
	
		JMP Cycle3
	ExitCycle3:
	MOV AX,a
	
	POP CX
	POP BX
	POP DX
	RET
readAX ENDP
main:
mov ax, @data
mov ds, ax
;MOV AX, 27982
LEA DX, Text1
MOV AH, 09h
INT 21h
CALL readAX
MOV res1, AX

LEA DX, Text2
MOV AH, 09h
INT 21h
OR IsBlockZero, 1
CALL readAX
MOV res2, AX

LEA DX, Text3
MOV AH, 09h
INT 21h

XOR DX, DX
MOV AX, res1
MOV BX, res2
DIV BX
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
mov ax, 4c00h
int 21h
end main