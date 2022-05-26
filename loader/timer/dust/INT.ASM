ideal
p386n
model flat
stack 1000h
dataseg

flag            db      0
oldint8		df	?		; Holds old interrupt

codeseg

start:

	mov	ax,204h			; f204h i31h - get interrupt
        mov     bl,9                    ; bl=interrupt number
	int	31h			; dpmi call
					; returns cx:edx for the old int
        mov     [dword ptr oldint8],edx  ; save old interrupt
        mov     [word ptr oldint8+4],cx

	mov	ax,205h			; f205h i31h - set interrupt
        mov     bl,9                    ; int num
	mov	cx,cs			; cx=seg - for newint8
        mov     edx,offset newint8      ; edx offset - for newint8
	int	31h

	xor	ah,ah
	int	16h

	mov	ax,205h
        mov     bl,9
        mov     edx,[dword ptr oldint8]  ; set oldint8 back
        mov     cx,[word ptr oldint8+4]
	int	31h

mov     ax,4c00h
int     21h

PROC    newint8
push    dx ax
cmp     [flag],0
jnz     end_it
mov     [flag],1
mov     dl,'A'
mov     ah,02
int     21h
mov     dl,'B'
mov     ah,02
int     21h
mov     dl,'C'
mov     ah,02
int     21h
mov     [flag],0
end_it:
pop     ax dx
iret
ENDP    newint8

end     start
