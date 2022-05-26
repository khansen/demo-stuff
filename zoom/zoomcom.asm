IDEAL
MODEL tiny
P386N
jumps

dataseg

picfile         db 'kis2.raw',0
palfile         db 'kis2.pal',0
ScreenX         dw 0
ScreenY         dw 0
X               dw 0
Y               db 0
Z               dw 256
palette         db 768 dup (?)
picture         db 48000 dup (?)

codeseg

Org     100h

start:

mov     ax,cs
mov     ds,ax
mov     ax,3D00h
mov     dx,offset palfile
int     21h
mov     bx,ax
mov     ah,3Fh
mov     dx,offset palette
mov     cx,768
int     21h
mov     ax,3D00h
mov     dx,offset picfile
int     21h
mov     bx,ax
mov     ah,3Fh
mov     dx,offset picture
mov     cx,48000
int     21h

mov     ax,13h
int     10h

mov     ax,cs
mov     ds,ax
mov     es,ax
mov     dx,3c8h
xor     al,al
out     dx,al
inc     dx
mov     cx,768
lea     si,[palette]
rep     outsb

zoom_pic:
mov     ax,cs
mov     ds,ax
mov     ax,0a000h
mov     es,ax

xor     di,di
lea     si,[picture]
mov     [y],0
setloopcount:
mov     cx,160
mov     [x],0
loopert:

mov     ax,[x]
xor     dx,dx
shl     ax,8
mov     bx,[z]
div     bx
mov     [ScreenX],ax

mov     di,[ScreenX]
add     di,[ScreenY]
movsw
add     [x],2
loop    loopert
inc     [y]
cmp     [y],150
je      inc_z

mov     al,[y]
xor     ah,ah
xor     dx,dx
shl     ax,8
mov     bx,[z]
div     bx

mov     dx,ax
shl     ax,8
shl     dx,6
add     ax,dx
mov     [ScreenY],ax

jmp     setloopcount

inc_z:
in      al,60h
cmp     al,1
je      exit
add     [z],4
cmp     [z],1024
jnz     zoom_pic
exit:
mov     ax,3
int     10h
int     20h

end     start
