;.386
.model small
.stack 100h
.data
	initialArray db 101 dup (?)
	n            dw ?
	IsFirstZero  db 0
	IsBlockZero  db 0
	a            dw ?
	temp         dw ?
	i            dw 0
	j            dw 0
	k            dw 0

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
backspace PROC
	             PUSH AX
	             PUSH BX
	             PUSH DX
		
	             MOV  DL, 08
	             MOV  AH, 02h
	             INT  21h
	             MOV  DL,32
	             MOV  AH, 02h
	             INT  21h
	             MOV  DL, 08
	             MOV  AH, 02h
	             INT  21h
	
	             XOR  DX, DX
	             MOV  AX, a
	             MOV  BX, 10
	             DIV  BX
	             MOV  a, AX
	
	             CMP  a, 0
	             JNE  NotZero2
	             AND  IsFirstZero, 0
	NotZero2:    
	
	             POP  DX
	             POP  BX
	             POP  AX
	             RET
backspace ENDP
readAX PROC
	             PUSH DX
	             PUSH BX
	             PUSH CX
	             XOR  AX, AX
	             MOV  a, AX
	             MOV  BX, 10
	             AND  IsFirstZero, 0
	
	Cycle3:      
	             MOV  AH, 01h
	             INT  21h
	             XOR  AH, AH
		
	             CMP  AL, 08
	             JNE  NotBackspace
	             CALL backspace
	             JMP  Cycle3
	NotBackspace:
		
	             CMP  AL, 13
	             JE   TryExit
				 CMP  AL, 10
	             JE   TryExit
	             CMP  AL, 32
	             JE   TryExit
	             JMP  NotExit
	TryExit:     
	             CMP  IsBlockZero, 1
	             JNE  NotBlock
	             CMP  a, 0
	             JE   Cycle3
	NotBlock:    
	             JMP  ExitCycle3
	NotExit:     
			
	             CMP  AL, 27
	             JNE  NotEscape
	Cycle4:      
	             CALL backspace
	             cmp  a, 0
	             JNE  Cycle4
	             JMP  Cycle3
	NotEscape:   
		
	             CMP  AL, '9'
	             JA   Cycle3
	             CMP  AL, '0'
	             JB   Cycle3
		
	             CMP  IsFirstZero, 1
	             JE   Cycle3
		
	             CMP  AL, '0'
	             JNE  NotZero1
	             CMP  a, 0
	             JNE  NotFirst
	             OR   IsFirstZero, 1      	;MOV 1
	NotFirst:    
	NotZero1:    
		
	;MOV  DL, AL
	;MOV  AH, 02h
	;INT  21h
	             SUB  AL, '0'
	             XOR  AH, AH
	             MOV  temp, AX            	;MOV last digit
	             MOV  AX, a
	             MUL  BX
	             JNC  NotRE1
	             MOV  AX, a
	             CALL backspace
	             MOV  a, AX
	             JMP  Cycle3
	NotRE1:      
	             ADD  AX, temp
	             JNC  NotRE2
	             MOV  AX, a
	             CALL backspace
	             MOV  a, AX
	             JMP  Cycle3
	NotRE2:      
	             MOV  a, AX
	
	             JMP  Cycle3
	ExitCycle3:  
	             MOV  AX,a
	
	             POP  CX
	             POP  BX
	             POP  DX
	             RET
readAX ENDP
	main:        
	             MOV  AX, @data
	             MOV  DS, AX
	             MOV  ES, AX
	             CALL readAX 	
	             MOV  n, AX
	             MUL  n
	             MOV  CX, AX
	             LEA  SI, initialArray
@@Cycle1:
	             CALL readAX
	             MOV  initialArray[SI], AL
	             INC  SI
	             LOOP @@Cycle1
	             MOV  i, 0
@@Cycle2:
	             MOV  j, 0
@@Cycle3:
	             MOV  k, 0
@@Cycle4:
	             MOV  AX, n
	             MUL  i
	             MOV  SI, AX
	             ADD  SI, k
	             MOV  AX, n
	             MUL  k
	             MOV  DI, AX
	             ADD  DI, j
	             
	             MOV  CL, initialArray[SI]	;initialArray[n*i+k]
	             ADD  CL, initialArray[DI]	;initialArray[n*k+j]

	             MOV  AX, n
	             MUL  i
	             MOV  SI, AX
	             ADD  SI, j
				
	             MOV  BL, initialArray[SI]	;initialArray[n*i+j]
	             CMP  BL, CL
	             JBE  @@NotChange
	             MOV  initialArray[SI], CL	;d[i][j] = d[i][k] + d[k][j]
@@NotChange:
	             
	             INC  k
	             MOV  CX, k
	             CMP  CX, n
	             JB   @@Cycle4
	             INC  j
	             MOV  CX, j
	             CMP  CX, n
	             JB   @@Cycle3
	             INC  i
	             MOV  CX, i
	             CMP  CX, n
	             JB   @@Cycle2
	


	             MOV  i, 0
@@Cycle5:
	             MOV  j, 0
@@Cycle6:
	             MOV  AX, n
	             MUL  i
	             MOV  SI, AX
	             ADD  SI, j
				
	             MOV  AL, initialArray[SI]	;initialArray[n*i+j]
	             CALL writeAX

	             MOV  DL, 32
				 MOV  AH, 02h
	             INT  21h
	             	             	             
	             INC  j
	             MOV  CX, j
	             CMP  CX, n
	             JB   @@Cycle6
	             MOV  DL, 10
				 MOV  AH, 02h
	             INT  21h
	             MOV  DL, 13
				 MOV  AH, 02h
	             INT  21h
	             INC  i
	             MOV  CX, i
	             CMP  CX, n
	             JB   @@Cycle5
	
	
	             MOV  ax, 4c00h
		 		 INT 21h
	end main