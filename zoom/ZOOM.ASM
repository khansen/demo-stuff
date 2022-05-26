DOSSEG
.MODEL SMALL
.386
.STACK 100h
jumps
.data
message         db 'Coded in 100% (t)ASM by Kent Hansen',13,10,'19(c)97',13,10,'$'
picfile         db 'kis2.raw',0
palfile         db 'kis2.pal',0
ScreenX         dw 0
ScreenY         dw 0
X               dw 0
Y               db 0
Z               dw 256
palette         db 768 dup (?)
picture         db 48000 dup (?)

.code
jmp     start

CalcX MACRO
mov     ax,x
xor     dx,dx
shl     ax,8
mov     bx,z
div     bx
mov     ScreenX,ax
ENDM

CalcY   MACRO
mov     al,y
xor     ah,ah
xor     dx,dx
shl     ax,8
mov     bx,z
div     bx

mov     dx,ax
shl     ax,8
shl     dx,6
add     ax,dx
mov     ScreenY,ax
ENDM

START:
mov     ax,@data
mov     ds,ax
mov     ah,3Dh
xor     al,al
mov     dx,offset palfile
int     21h
mov     bx,ax
mov     ah,3Fh
mov     dx,offset palette
mov     cx,768
int     21h
mov     ah,3Eh
int     21h
mov     ah,3Dh
xor     al,al
mov     dx,offset picfile
int     21h
mov     bx,ax
mov     ah,3Fh
mov     dx,offset picture
mov     cx,48000
int     21h
mov     ah,3Eh
int     21h

mov     ax,13h
int     10h

mov     ax,@data
mov     ds,ax
mov     es,ax
mov     dx,3c8h
xor     al,al
out     dx,al
inc     dx
mov     cx,768
lea     si,palette
rep     outsb

zoom_pic:
mov     ax,@data
mov     ds,ax
mov     ax,0a000h
mov     es,ax

xor     di,di
lea     si,picture
mov     y,0
setloopcount:
mov     cx,160
mov     x,0
loopert:
CalcX
mov     di,ScreenX
add     di,ScreenY
movsw
add     x,2
loop    loopert
inc     y
cmp     y,150
je      inc_z
CalcY
jmp     setloopcount

inc_z:
call    waitvrt
call    waitvrt
call    waitvrt
in      al,60h
cmp     al,1
je      exit
add     z,4
cmp     z,1024
jnz     zoom_pic
exit:
mov     ax,3
int     10h
mov     dx,offset message
mov     ah,09
int     21h
mov     ax,4c00h
int     21h
INCLUDE waitvrt.inc
end
