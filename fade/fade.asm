IDEAL
MODEL tiny
P386N

dataseg

picfile db 'kis2.raw',0
palfile db 'kis2.pal',0
palette2 db 768 dup (?)
picture db 48000 dup (?)
palette db 768 dup (?)

codeseg

Org     100h

start:

mov     ax,cs
mov     ds,ax
mov     es,ax

mov     cx,768
lea     di,[palette2]
xor     al,al
rep     stosb

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
mov     cx,768
inc     dx
blackpal:
out     dx,al
loop    blackpal

mov     ax,0a000h
mov     es,ax
xor     di,di

lea     si,[picture]
mov     cx,12000
rep     movsd

mov     ax,cs
mov     ds,ax
mov     es,ax

mov     bx,63
fade_in:
lea     si,[palette]
lea     di,[palette2]
mov     cx,768
inc_colors:
lodsb
cmp     [byte ptr di],al
je      out_byte
inc     [byte ptr di]
mov     al,[byte ptr di]
out_byte:
out     dx,al
inc     di
loop    inc_colors
call    waitvrt
dec     bx
jnz     fade_in

mov     ah,00
int     16h

mov     bx,63
fade_out:
lea     si,[palette]
lea     di,[palette]
mov     cx,768
dec_colors:
lodsb
cmp     al,0
je      out_byte2
dec     [byte ptr di]
mov     al,[byte ptr di]
out_byte2:
out     dx,al
inc     di
loop    dec_colors
call    waitvrt
dec     bx
jnz     fade_out

mov     ax,3
int     10h
int     20h

INCLUDE "waitvrt.inc"

end     start
