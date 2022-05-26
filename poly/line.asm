DOSSEG
.MODEL SMALL
.STACK 100h
jumps

COORDS  STRUC
X       dw      0
Y       dw      0
COORDS  ENDS

.data

DeltaX  dw 0
color   db 4
XposFixed       dw 0

P1      COORDS  <10,0>                           ;1st point
P2      COORDS  <120,40>                          ;2nd point

.code

Start:

mov     ax,13h
int     10h

mov     ax,@data
mov     ds,ax
mov     ax,0a000h
mov     es,ax

;deltaX

mov     ax,[P2.X]
sub     ax,[P1.X]
shl     ax,7
mov     bx,[P2.Y]
sub     bx,[P1.Y]
xor     dx,dx
div     bx
mov     DeltaX,ax

mov     ax,[P1.X]
shl     ax,7
mov     XposFixed,ax
mov     cx,[P2.Y]
sub     cx,[P1.Y]
xor     dx,dx
line_loop:
mov     di,dx
mov     ax,XposFixed
shr     ax,7
add     di,ax
mov     byte ptr es:[di],5
mov     ax,XposFixed
add     ax,DeltaX
mov     XposFixed,ax
add     dx,320
loop    line_loop

mov     ah,00
int     16h

mov     ax,3
int     10h
mov     ax,4c00h
int     21h
end     Start
