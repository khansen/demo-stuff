DOSSEG
.MODEL SMALL
.386
.STACK 100h
JUMPS
.data

Message db '2D Rotation in 100% (t)ASM',13,10,'by Kent Hansen',13,10,'19(c)97',13,10,'$'
INCLUDE sincos.dw

X       dw 0
Y       dw 0

Eraseflag db 0
Color   db 15
Angle   dw 0
Cos     dw 0
Sin     dw 0
Xt      dw 0
Yt      dw 0

picfile db 'logo.raw',0
palfile db 'logo.pal',0
palette db 768 dup (?)
picture db 19200 dup (?)

.code

mov     ax,@data
mov     ds,ax
mov     es,ax

mov     ah,3Dh
xor     al,al
mov     dx,offset picfile
int     21h
mov     bx,ax
mov     ah,3Fh
mov     cx,19200
mov     dx,offset picture
int     21h
mov     ah,3Eh
int     21h
mov     ah,3Dh
xor     al,al
mov     dx,offset palfile
int     21h
mov     bx,ax
mov     cx,768
mov     dx,offset palette
mov     ah,3Fh
int     21h
mov     ah,3Eh
int     21h

mov     ax,13h
int     10h

mov     dx,3c8h
xor     al,al
out     dx,al
mov     cx,768
lea     si,palette
inc     dx
rep     outsb

mov     ax,0a000h
mov     es,ax

;    Xt = (X*COS(í) - Y*SIN(í)) /256
;    Yt = (X*SIN(í) + Y*COS(í)) /256

main_loop:

mov     cx,60

;get sine & cosine values for angle

lea     si,cosine
add     si,angle
lodsw
mov     Cos,ax
lea     si,sine
add     si,angle
lodsw
mov     Sin,ax

lea     si,picture

mov     Y,-30

prepare:
push    cx
mov     X,-160
mov     cx,320

calc_coords:
mov     bx,X                                    ;xcoord in bx
mov     ax,Cos
imul    bx                                      ;X*COS(í)
mov     Xt,ax
mov     ax,Sin
imul    bx                                      ;(X*SIN(í)
mov     Yt,ax

mov     bx,Y                                    ;ycoord in bx
mov     ax,Sin
imul    bx                                      ;Y*SIN(í)
sub     Xt,ax                                   ;(X*COS(í) - Y*SIN(í))
mov     ax,Xt
sar     ax,8                                    ;(X*COS(í) - Y*SIN(í)) /256
mov     Xt,ax
mov     ax,Cos
imul    bx                                      ;Y*COS(í)
add     Yt,ax                                   ;(X*SIN(í) + Y*COS(í))
mov     ax,Yt
sar     ax,8                                    ;(X*SIN(í) + Y*COS(í)) /256

;calculate final VGA position
;pixel location = ScreenWidth*Ypos + Xpos = 320 * (Y+AddY) + X + AddX

add     ax,100
mov     dx,ax
shl     ax,8
shl     dx,6
add     ax,dx
mov     di,ax
add     di,Xt
add     di,160
movsb

inc     X
loop    calc_coords

pop     cx
inc     Y
loop    prepare

in      al,60h
cmp     al,1
je      exit
cmp     angle,510
jne     skip
mov     angle,0
skip:
add     angle,2
call    waitvrt
jmp     main_loop

exit:
mov     ax,3
int     10h
mov     ah,09
mov     dx,offset message
int     21h
mov     ax,4c00h
int     21h
INCLUDE waitvrt.inc
end
