.model small
.stack 100h
.data
    a dw 6
    b dw 2
    c dw 2
    d dw 10
.code

get_xor proc C near
arg firstArg: word, secondArg: word
uses ax
    mov ax, [firstArg]
    xor ax, [secondArg]
    mov bx, ax
    ret
get_xor endp

get_sum proc C near
arg firstArg: word, secondArg: word
uses ax
    mov ax, [firstArg]
    add ax, [secondArg]
    mov bx, ax
    ret
get_sum endp

get_and proc C near
arg firstArg: word, secondArg: word
uses ax
    mov ax, [firstArg]
    and ax, [secondArg]
    mov bx, ax
    ret
get_and endp

get_or proc C near
arg firstArg: word, secondArg: word
uses ax
    mov ax, [firstArg]
    or ax, [secondArg]
    mov bx, ax
    ret
get_or endp

main:
    mov ax, @data ; initialize data segment
    mov ds, ax 
    
    main_statement: 
        call get_xor C, a, b
        mov ax, bx
        call get_sum C, c, d
        
        cmp ax, bx
        jnz main_else_statement
        
        ;main statement correct execute commands
        call get_and C, c, a
        mov ax, bx
        call get_or C, b, d
        add ax, bx
        jmp return

    main_else_statement:
        call get_and C, a, b
        mov ax, bx
        call get_sum C, c, d
        
        cmp ax, bx
        jnz secondary_else_statement
        
        ;secondary statement correct execute commands
        mov ax, a
        xor ax, b
        xor ax, c
        xor ax, d
        jmp return
        
        secondary_else_statement: 
            mov ax, a
            or ax, b
            or ax, c
            or ax, d
            jmp return
    return: 
        mov ah, 4ch ; exit interrupt
        int 21h
end main