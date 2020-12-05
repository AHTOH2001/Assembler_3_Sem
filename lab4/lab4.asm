;.386
.model small
.stack 100h
.data
	maxLen        =  128
	newLine       db 10,13,'$'
	initialString db maxLen, maxLen DUP('$')	
	count         db 0
	blockNumber   db ?
	blockCount    db ?
	strLength db ?
.code
writeAX PROC
	                    PUSH DX
	                    PUSH BX
	                    PUSH CX
	                    PUSH AX
	
	                    MOV  BX, 10
	                    XOR  CX, CX
		
	Cycle1:             
	                    XOR  DX, DX
	                    DIV  BX
	                    PUSH DX
	                    INC  CX
	                    CMP  AX, 0
	                    JNE  Cycle1
			
	Cycle2:             
	                    POP  DX
	                    ADD  DL,'0'
	                    MOV  AH, 02h
	                    INT  21h
	                    LOOP Cycle2

	                    POP  AX
	                    POP  CX
	                    POP  BX
	                    POP  DX
	                    RET
writeAX ENDP
	main:               
	                    mov  ax, @data
	                    mov  ds, ax
	                    mov  es, ax
		 
	;Ввод входной строки
	                    XOR  DL, DL
	                    LEA  si, initialString
	                    ;MOV  si, CX
	CycleEnteringString:
	                    MOV  AH, 01h
	                    INT  21h
	                    CMP  AL, 10
	                    JE   ExitCycle
	                    CMP  AL, 13
	                    JE   ExitCycle
	                    MOV  [si+2], AL
	                    INC  DL
	                    INC  si
	                    JMP  CycleEnteringString
	ExitCycle:          
	                    MOV  strLength, DL
	; LEA  DX, initialString
	; MOV  AH, 10
	; INT  21H
	; MOV  DL, initialString+1
	; MOV  strLength, DL
	IncCount:           
	                    INC  count
	                    XOR  AX,AX
	                    MOV  AL, strLength
	                    DIV  count                     	;AL (AH)
	                    CMP  AH, 0                     	;If count is not divider of strLength then inc count
	                    JNE  IncCount

	                    MOV  blockCount, AL
	                    MOV  AL, strLength
	                    CMP  count, AL
	                    JE   ExitProgramm

	                    MOV  blockNumber, 0
	NextPermutation:    
	                    INC  blockNumber
	                    MOV  AL, blockCount
	                    CMP  blockNumber, AL
	                    JE   ExitProgramm              	;if all blocks are valid
	                    MOV  SI, offset initialString+2	;first symbol of str
	                    MOV  DI, offset initialString+2
	                    MOV  AL, count
	                    MUL  blockNumber
	                    ADD  DI, AX
	                    XOR  CX, CX
	                    MOV  CL, count
	                    REPE CMPSB                     	;Comp SI and DI count times
	                    JNE  IncCount                  	;If not equal skip other blocks
	                    JMP  NextPermutation
					
	ExitProgramm:       
	                    XOR  AX, AX
	                    MOV  AL, count
	                    CALL writeAX
	                    mov  ax, 4c00h
		 		 int 21h
	end main