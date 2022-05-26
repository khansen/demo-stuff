ideal
p386n
model flat
stack 1000h
dataseg

keyboard        db 128 dup (0)
videomem        dd ?
keyboardbuffer  dd ?
oldofs          dd ?
oldseg          dw ?

codeseg

start:

mov     ax,3
int     10h

mov     ax,0EE02h
int     31h
mov     eax,0B8000h
sub     eax,ebx
mov     [videomem],eax
mov     eax,00400h
sub     eax,ebx
mov     [keyboardbuffer],eax
xor     ebx,ebx

mov     ax,204h                 ; f204h i31h - get interrupt
mov     bl,9                    ; bl=interrupt number
int     31h                     ; dpmi call
                                ; returns cx:edx for the old int
mov     [oldofs],edx            ; save old interrupt
mov     [oldseg],cx

mov     ax,205h                 ; f205h i31h - set interrupt
mov     bl,9                    ; int num
mov     cx,cs                   ; cx=seg - for newint9
mov     edx,offset newint9      ; edx offset - for newint9
int     31h

main_loop:
mov     edi,[videomem]
add     edi,160*10+64
mov     esi,offset keyboard
mov     ch,8
outer_loop:
mov     cl,16
inner_loop:
mov     ah,15
lodsb
sub     ah,al
add     al,30h
stosw
dec     cl
jnz     inner_loop
add     edi,128
dec     ch
jnz     outer_loop

cmp     [keyboard + 1],1
jnz     main_loop

mov     ax,205h
mov     bl,9
mov     edx,[oldofs]                    ; set oldint9 back
mov     cx,[oldseg]
int     31h

mov     ax,4c00h
int     21h

PROC    NewInt9

push    ax bx edi

mov     edi,[KeyboardBuffer]
mov     ax,[word ptr edi + 1Ch]
mov     [word ptr edi + 01Ah],ax        ; tail = head (clear kbbuffer)

in      al,60h                          ; read keyboard
xor     bh,bh
mov     bl,al
and     bl,01111111b
and     al,10000000b
rol     al,1
xor     al,1
mov     [Keyboard + ebx],al

mov     al,20h
out     20h,al

pop     edi bx ax

iret
ENDP    NewInt9

end     start
