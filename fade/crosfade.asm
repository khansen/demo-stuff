IDEAL
MODEL tiny
P386N

dataseg

picfile db '1.raw',0
palfile db '1.pal',0
palette2 db 768 dup (?)
picture db 48000 dup (?)
palette db 768 dup (?)

codeseg

Org     100h

start:

mov     ax,cs
mov     ds,ax
mov     es,ax

mov     ax,3D00h
mov     dx,offset palfile
int     21h
mov     bx,ax
mov     ah,3Fh
mov     cx,768
mov     dx,offset palette
int     21h

mov     ax,3D00h
mov     dx,offset picfile
int     21h
mov     bx,ax
mov     ah,3Fh
mov     cx,48000
mov     dx,offset picture
int     21h

mov     ax,13h
int     10h

mov     dx,3c8h
xor     al,al
out     dx,al
inc     dx
lea     si,[palette]
mov     cx,768
rep     outsb

mov     ax,0a000h
mov     es,ax
xor     di,di

lea     si,[picture]
mov     cx,12000
rep     movsd

mov     ah,00
int     16h

mov     ax,cs
mov     ds,ax
mov     es,ax

mov     si,offset palette
mov     di,offset palette2

mov     cx,768/3
make_pal:
mov     al,[byte ptr si]
add     al,[byte ptr si+1]
add     al,[byte ptr si+2]
add     al,63
shr     al,2
stosb
stosb
stosb
add     esi,3
loop    make_pal

mov     bx,63
fade_it:
lea     si,[palette]
lea     di,[palette2]
mov     cx,768
fade_loop:
mov     al,[byte ptr si]
cmp     al,[byte ptr di]
je      done
jl      less
ja      above
less:
inc     al
jmp     done
above:
dec     al
jmp     done
done:
mov     [byte ptr si],al
out     dx,al
inc     si
inc     di
loop    fade_loop
call    waitvrt
call    waitvrt
dec     bx
jnz     fade_it

mov     ah,00
int     16h

mov     ax,3
int     10h
int     20h

INCLUDE "waitvrt.inc"

end     start
