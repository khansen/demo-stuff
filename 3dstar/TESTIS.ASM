DOSSEG
.MODEL SMALL
.386
.STACK 100h
.data
include fire.pal
.code
mov     ax,13h
int     10h
mov     ax,@data
mov     ds,ax
mov     es,ax
mov     dx,3c8h
xor     al,al
out     dx,al
mov     si,offset palette
inc     dx
mov     cx,768
rep     outsb

mov     ax,0a000h
mov     es,ax
xor     di,di
mov     cx,255
xor     al,al
loopis:
stosb
inc     al
loop    loopis
mov     ah,00
int     16h
mov     ax,3
int     10h
mov     ax,4c00h
int     21h
end
