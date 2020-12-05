;.386
.model small
.stack 100h
.data
	shiftForEncoding      db 0
	oldHook               dw ?, ?
	flagExit              db 0
	scanTableLetters      db 30, 48, 46, 32, 18, 33, 34, 35, 23, 36, 37, 38, 50, 49, 24, 25, 16, 19, 31, 20, 22, 47, 17, 45, 21, 44
	scanTableDigits       db 11, 2, 3, 4, 5, 6, 7, 8, 9, 10
	EscScanCode           db 1
	lShiftScanCode        db 42
	rShiftScanCode        db 54
	lShiftScanCodeRelease db 170
	rShiftScanCodeRelease db 182
	isShiftPressed        db 0
	BackspaceScanCode 	  db 14
.code
calcShiftAL PROC
	                        PUSH  BX
	                        PUSH  CX
	                        PUSH  DX
	                        PUSH  SI
				 
	                        MOV   SI, 81h
	                        XOR   DX, DX
							
	                        XOR   BX, BX
	                        XOR   CX, CX
	                        MOV   BL, 10
@@cycle:
	                        MOV   CL,  ES:[SI]
	                        CMP   CL, '0'
	                        JB    @@NotDigit
	                        CMP   CL, '9'
	                        JA    @@NotDigit
	                        SUB   CL, '0'
	                        OR    DX, 1
	                        MUL   BL                         	; *10
	                        ADD   AL, CL
	                        INC   SI
	                        JMP   @@cycle
@@NotDigit:
	                        INC   SI
	                        CMP   DX, 0
	                        JE    @@cycle
	                        POP   SI
	                        POP   DX
	                        POP   CX
	                        POP   BX
	                        RET
calcShiftAL ENDP
shiftAL PROC
	                        PUSH  BX
	                        PUSH  CX
	                        PUSH  DX


	                        MOV   CX, 1                      	; shiftForEncoding cycle

	                        CMP   AL, 'a'
	                        JL    @@NotSmall
	                        CMP   AL, 'z'
	                        JA    @@NotSmall
	                        MOV   BL, 'a'
	                        SUB   AL, 'a'
	                        MOV   CX, 26
@@NotSmall:

	                        CMP   AL, 'A'
	                        JL    @@NotBig
	                        CMP   AL, 'Z'
	                        JA    @@NotBig
	                        MOV   BL, 'A'
	                        SUB   AL, 'A'
	                        MOV   CX, 26
@@NotBig:

	                        CMP   AL, '0'
	                        JL    @@NotNumber
	                        CMP   AL, '9'
	                        JA    @@Notnumber
	                        MOV   BL, '0'
	                        SUB   AL, '0'
	                        MOV   CX, 10
@@NotNumber:

	                        CMP   CX, 1
	                        JE    @@Nothing
	                        XOR   AH, AH
	                        XOR   DX, DX
	                        ADD   AL, shiftForEncoding
	                        DIV   CX
	                        MOV   AL, DL                     	; AL = DX:AX % CX
	            
	                        ADD   AL, BL                     	; back to char
				
@@Nothing:

	                        POP   DX
	                        POP   CX
	                        POP   BX
	                        RET
shiftAL ENDP
WriteSymbolDl proc
	                        PUSH  AX
	                        MOV   ah, 02h
	                        INT   21h
	                        POP   AX
	                        RET
WriteSymbolDl endp
	;Return ascii code of letter or digit or 0 otherwise
FromAlScanCodeToAxAscii PROC
	                        PUSH  bx cx dx di
	                        PUSH  es ds                      	; temporary mov es, ds for REP
	                        POP   es
	                        CMP   al, lShiftScanCode
	                        JE    @@ShiftPressed
	                        CMP   al, rShiftScanCode
	                        JE    @@ShiftPressed
	                        JMP   @@NotShiftPressed
@@ShiftPressed:
	                        MOV   isShiftPressed, 1
@@NotShiftPressed:

	                        CMP   al, lShiftScanCodeRelease
	                        JE    @@ShiftReleased
	                        CMP   al, rShiftScanCodeRelease
	                        JE    @@ShiftReleased
	                        JMP   @@NotShiftReleased
@@ShiftReleased:
	                        MOV   isShiftPressed, 0
@@NotShiftReleased:
	                        
	                        MOV   cx, 27
	                        LEA   di, scanTableLetters
	                        REPNE SCASB
	                        DEC   di
	                        SUB   di, offset scanTableLetters
	                        CMP   di, 26
	                        JL    LetterFound

	                        MOV   cx, 11
	                        LEA   di, scanTableDigits
	                        REPNE SCASB
	                        DEC   di
	                        SUB   di, offset scanTableDigits
	                        CMP   di, 10
	                        JL    DigitFound
	                        
	                        MOV   al, 0
	                        JMP   ExitProc
	LetterFound:            
	                        MOV   ax, di
	                        CMP   isShiftPressed, 1
	                        JNE   @@ShiftNotPressed
	                        ADD   al, 65
	                        JMP   ExitProc
@@ShiftNotPressed:
	                        ADD   al, 97
	                        JMP   ExitProc
	DigitFound:             
	                        MOV   ax, di
	                        ADD   al, 48
	ExitProc:               
	                        POP   es
	                        POP   di dx cx bx
	                        RET
FromAlScanCodeToAxAscii ENDP
MyHook proc
	                        PUSH  ax bx cx dx es ds si di
	                        CLI
	                        XOR   ah, ah
	                        IN    al, 60h

	                        CMP   al, EscScanCode
	                        JNE   @@notEsc
	                        OR    flagExit, 1
	                        JMP   @@FinishKeyModifying
@@notEsc:

	                        CMP   al, BackspaceScanCode
	                        JNE   @@NotBackspace
	                        MOV   dl, 8
	                        CALL  WriteSymbolDl
	                        MOV   dl, 32
	                        CALL  WriteSymbolDl
	                        MOV   dl, 8
	                        CALL  WriteSymbolDl
	                        JMP   @@FinishKeyModifying
@@NotBackspace:

	                        CALL  FromAlScanCodeToAxAscii
	                        CMP   al, 0
	                        JE    @@WrongSymbol
	                        CALL  shiftAL
	                        MOV   dl, al
	                        CALL  WriteSymbolDl
@@WrongSymbol:
	; or    al,10000000B           	;установить бит разрешения для клавиатуры
	; out   61H,al                 	; и вывести его в управляющий порт
	; xchg  ah,al                  	;извлечь исходное значение порта
	; out   61H,al                 	; и записать его обратно

	             

@@FinishKeyModifying:
	             
	                        MOV   al, 100000B
	                        OUT   100000B, al
	                        POP   di si ds es dx cx bx ax
	                        IRET
MyHook endp
initMyHook PROC
	                        MOV   ax, 3509h
	                        INT   21h
	                        MOV   word ptr oldHook, bx
	                        MOV   word ptr oldHook+2, es

	                        PUSH  ds
	                        MOV   ax, 2509h
	                        MOV   dx, @code
	                        MOV   ds, dx
	                        LEA   dx, MyHook
	                        INT   21h
	                        POP   ds
	                        RET
initMyHook ENDP
deleteMyHook PROC
	                        PUSH  ds
	                        MOV   ax, 2509h
	                        MOV   dx, word ptr oldHook
	                        MOV   bx, word ptr oldHook+2
	                        MOV   ds, bx
	                        INT   21h
	                        POP   ds
	                        RET
deleteMyHook ENDP
	main:                   
	                        CALL  calcShiftAL
	                        MOV   dx, @data
	                        MOV   ds, dx
	                        MOV   es, dx

	                        MOV   shiftForEncoding, al
	                        CALL  initMyHook
@@cycle2:
	                        CMP   flagExit, 1
	                        JNE   @@cycle2

	                        CALL  deleteMyHook

	                        MOV   ax, 4c00h
	                        INT   21h
	end main