IDEAL
MODEL SMALL
P386N
STACK 100h
JUMPS
DATASEG

Clip            dw 0
CurrentChar     dw 0
order           db 'abcdefghijklmn%opqrstuvwxyz .',0
scrolltext      db '                drud sends his best regards to the following people...             veivizeren lioz eniac zanti fidgety aricz larry mesonyx                      $'
fontfile        db 'font.raw',0
font            db 16000 dup (?)
buffer          db 400*24 dup (?)

CODESEG

mov     ax,@data
mov     ds,ax
mov     es,ax

mov     di,offset buffer
xor     ax,ax
mov     cx,400*12
rep     stosw

mov     ax,3D00h
mov     dx,offset fontfile
int     21h
mov     bx,ax
mov     ah,3Fh
mov     cx,16000
mov     dx,offset font
int     21h
mov     ah,3Eh
int     21h

mov     ax,13h
int     10h

start_scroll:
mov     si,offset scrolltext
add     si,[currentchar]
mov     di,offset buffer
mov     dl,16
cmp     [byte ptr si],'$'
jnz     main
sub     si,[currentchar]
mov     [currentchar],0
main:
mov     al,[byte ptr si]
push    si
call    GetFontPos
mov     si,offset font
add     si,bx
mov     cx,24
push    di
Vloop:
push    cx
mov     cx,22/2
rep     movsw
add     si,320-22
add     di,400-22
pop     cx
loop    Vloop
pop     di
add     di,22
pop     si
inc     si
dec     dl
jnz     main

mov     si,offset buffer
add     si,[clip]
push    es
mov     ax,0a000h
mov     es,ax
xor     di,di
mov     bl,24
dump_screen:
mov     cx,320/4
rep     movsd
add     si,400-320
dec     bl
jnz     dump_screen
pop     es

inc     [clip]
cmp     [clip],22
jnz     skip_it
mov     [clip],0
inc     [currentchar]
skip_it:
call    waitvrt
in      al,60h
dec     al
jnz     start_scroll

mov     ax,3
int     10h
mov     ax,4c00h
int     21h
INCLUDE "waitvrt.inc"

PROC    GetFontPos
mov     ah,al
mov     si,offset order
xor     bx,bx
get_font_position:
mov     al,[byte ptr si]
cmp     al,'%'
je      addstuff
cmp     al,ah
je      next
add     bx,22
inc     si
jmp     get_font_position
addstuff:
mov     bx,7360
inc     si
jmp     get_font_position
next:
ret
ENDP    GetFontPos

end
