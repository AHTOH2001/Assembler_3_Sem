.model small
.stack 100h
.data
 a dw 1 
 b dw 3
 c dw 2
 d dw 6
.code
main:
 mov ax, @data
 mov ds, ax
 

 mov bx,a
 add bx,b
 jc not_equal1 ;RE
 xor bx,c
 mov dx,d
 
 cmp bx,dx
 jne not_equal1
 equal1:
	mov ch,0
	mov bx,d
	sub bx,b
		jnc skipFlagForRE1		
		add ch,1
		skipFlagForRE1:
	mov dx,a
	sub dx,c	
		jnc skipFlagForRE2
		add ch,1
		skipFlagForRE2:
	cmp ch,1	
	je not_equal2 ;RE
	
	cmp bx,dx
	jne not_equal2
	equal2:
		mov ax,a
		add ax,b
		add ax,c
		jmp exit2
	not_equal2:
		mov ax,b
		add ax,c
		add ax,d
	exit2:	
	jmp exit1
 not_equal1:
	mov ax,d
	and ax,c
	add ax,b	
 exit1:
  
 mov ax, 4c00h
 int 21h
end main