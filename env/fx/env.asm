DOSSEG
.MODEL SMALL
.386
.STACK 100h
.data

palfile db '00000003.pal',0
tall    dw 0
Katet   dw 0
Yline   dw 0
X       dw 0
Y       dw 0
K1      dw 0
K2      dw 0
color   db 0
palette db 768 dup (?)

.code

mov     ax,13h
int     10h

mov     ax,@data
mov     ds,ax
mov     es,ax

mov     ah,3Dh
xor     al,al
mov     dx,offset palfile
int     21h
mov     bx,ax
mov     ah,3Fh
mov     cx,768
mov     dx,offset palette
int     21h
mov     ah,3Eh
int     21h

mov     dx,3c8h
xor     al,al
out     dx,al
inc     dx
mov     cx,768
lea     si,palette
rep     outsb

mov     ax,0a000h
mov     es,ax
xor     di,di

mov     y,-100
mov     cx,200
yloop:
push    cx
mov     cx,320
mov     x,-160
mov     ax,y
cmp     ax,0
jae     skip
neg     ax
skip:
mov     bx,ax
mul     bx
mov     Yline,ax                        ;1. katet
xloop:
mov     ax,x
cmp     ax,0
jae     skip2
neg     ax
skip2:
mov     bx,ax
mul     bx                              ;2. katet

add     ax,Yline
shr     ax,8
mov     tall,ax
mov     ax,189
sub     ax,tall                 ;st0rste verdien "tall" kan ha SKAL vaere 189

mov     byte ptr es:[di],al
inc     di
inc     x
loop    xloop

inc     y
pop     cx
loop    yloop

mov     color,0
mov     ax,@data
mov     ds,ax
mov     es,ax
palrot:
mov     dx,3c8h
mov     al,color
out     dx,al
inc     dx
mov     cx,768
lea     si,palette
rep     outsb

inc     color
call    waitvrt
in      al,60h
cmp     al,1
jnz     palrot

mov     ax,3
int     10h
mov     ax,4c00h
int     21h
INCLUDE waitvrt.inc
end
