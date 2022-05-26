;2D rotation in 100% (t)ASM
;by Kent Hansen

DOSSEG
.MODEL SMALL
.STACK 100h
JUMPS
.data

Message db '2D Rotation in 100% (t)ASM',13,10,'by Kent Hansen',13,10,'19(c)97',13,10,'$'
INCLUDE sincos.dw

NumPts  EQU 4                            ;number of points to rotate
NPx2    EQU NumPts*2                     ;Y coords start at si+NumPts*2
                                         ;(2 becoz of word)

NPx4    EQU NumPts*4                     ;si+NumPts*4 = here's the startpos
                                         ;for saving old DI values in buffer
                                         ;(used for quick erasing)

Coords  dw -45,-45,45,45                 ;xcoords
        dw 45,-45,-45,45                 ;ycoords
        dw NumPts dup (?)                ;DI values, used for erasing

Color   db 15
Angle   dw 0                             ;angle from 0-256
Cos     dw 0                             ;the value corresponding to the angle
Sin     dw 0                             ;taken from SINCOS.DW
Xt      dw 0                             ;the result of the formula
Yt      dw 0


.code

mov     ax,13h
int     10h

mov     ax,@data
mov     ds,ax
mov     ax,0a000h
mov     es,ax

;    Xt = (X*COS(í) - Y*SIN(í)) /256
;    Yt = (X*SIN(í) + Y*COS(í)) /256

main_loop:

mov     cx,NumPts

;get sine & cosine values for angle

lea     si,cosine
add     si,angle
lodsw                                     ;get cosine value for current angle
mov     Cos,ax
lea     si,sine
add     si,angle
lodsw                                     ;get sine value for current angle
mov     Sin,ax

lea     si,Coords

calc_coords:

mov     bx,word ptr [si]                        ;xcoord in bx
mov     ax,Cos
imul    bx                                      ;X*COS(í)
mov     Xt,ax
mov     ax,Sin
imul    bx                                      ;(X*SIN(í)
mov     Yt,ax

mov     bx,word ptr [si+NPx2]                   ;ycoord in bx
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
mov     word ptr [si+NPx4],di
mov     al,Color
mov     byte ptr es:[di],al

add     si,2
loop    calc_coords

cmp     angle,510
jne     skip
mov     angle,0
skip:
add     angle,2

call    waitvrt

lea     si,Coords
add     si,NPx4
mov     cx,NumPts
erase:
lodsw
mov     di,ax
mov     byte ptr es:[di],0
loop    erase

in      al,60h
cmp     al,1
jnz     main_loop

mov     ax,3
int     10h
mov     ah,09
mov     dx,offset message
int     21h
mov     ax,4c00h
int     21h
INCLUDE waitvrt.inc
end
