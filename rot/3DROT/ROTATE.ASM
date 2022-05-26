DOSSEG
.MODEL SMALL
.STACK 100h
JUMPS
.data

Message db '3D Rotation in 100% (t)ASM',13,10,'by Kent Hansen',13,10,'19(c)97',13,10,'$'
INCLUDE sincos.dw

NumPts  EQU 8                            ;number of points to rotate
NPx2    EQU NumPts*2                     ;Y coords start at si+NumPts*2
                                         ;(2 becoz of word)
NPx4    EQU NumPts*4                     ;Z coords start at si+NumPts*2
                                         ;(2 becoz of word)
NPx6    EQU NumPts*6                     ;si+NumPts*6 = here's the startpos
                                         ;for saving old DI values in buffer
                                         ;(used for quick erasing)

Coords  dw 0,0,45,-45,45,45,-45,-45                    ;xcoords
        dw 45,-45,0,0,45,-45,45,-45                    ;ycoords
        dw 45,0,-45,0,-45,0,45,-45                     ;zcoords
        dw NumPts dup (?)                ;DI values, used for erasing

Color   db 15
Angle   dw 0                             ;angle from 0-256
Cos     dw 0                             ;the value corresponding to the angle
Sin     dw 0                             ;taken from SINCOS.DW
Xt      dw 0                             ;the result of the formula
Yt      dw 0
Zt      dw 0
X       dw 0
Y       dw 0
Z       dw 0
ScreenX dw 0
ScreenY dw 0

.code

mov     ax,13h
int     10h

mov     ax,@data
mov     ds,ax
mov     ax,0a000h
mov     es,ax

; Rotate around x-axis
; YT = Y * COS(xang) - Z * SIN(xang) / 256
; ZT = Y * SIN(xang) + Z * COS(xang) / 256
; Y = YT
; Z = ZT

; Rotate around y-axis
; XT = X * COS(yang) - Z * SIN(yang) / 256
; ZT = X * SIN(yang) + Z * COS(yang) / 256
; X = XT
; Z = ZT

; Rotate around z-axis
; XT = X * COS(zang) - Y * SIN(zang) / 256
; YT = X * SIN(zang) + Y * COS(zang) / 256
; X = XT
; Y = YT

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

; Rotate around x-axis
; YT = Y * COS(xang) - Z * SIN(xang) / 256
; ZT = Y * SIN(xang) + Z * COS(xang) / 256
; Y = YT
; Z = ZT

mov     bx,word ptr [si+NPx2]                   ;ycoord in bx
mov     Y,bx
mov     ax,Cos
imul    bx                                      ;Y*COS(í)
mov     Yt,ax
mov     bx,word ptr [si+NPx4]                   ;zcoord in bx
mov     Z,bx
mov     ax,Sin
imul    bx                                      ;(Z*SIN(í)
sub     Yt,ax
mov     ax,Yt
sar     ax,8
mov     Yt,ax

mov     bx,Y                                    ;ycoord in bx
mov     ax,Sin
imul    bx                                      ;Y*SIN(í)
mov     Zt,ax
mov     bx,Z                                    ;zcoord in bx
mov     ax,Cos
imul    bx                                      ;Z*COS(í)
add     Zt,ax
mov     ax,Zt
sar     ax,8
mov     Zt,ax
mov     ax,Yt
mov     Y,ax
mov     ax,Zt
mov     Z,ax

; Rotate around y-axis
; XT = X * COS(yang) - Z * SIN(yang) / 256
; ZT = X * SIN(yang) + Z * COS(yang) / 256
; X = XT
; Z = ZT

mov     bx,word ptr [si]                        ;xcoord in bx
mov     X,bx
mov     ax,Cos
imul    bx                                      ;X*COS(í)
mov     Xt,ax
mov     bx,Z                                   ;zcoord in bx
mov     ax,Sin
imul    bx                                      ;Z*SIN(í)
sub     Xt,ax
mov     ax,Xt
sar     ax,8
mov     Xt,ax

mov     bx,X                                    ;xcoord in bx
mov     ax,Sin
imul    bx                                      ;X*SIN(í)
mov     bx,Z                                    ;zcoord in bx
mov     Zt,ax
mov     ax,Cos
imul    bx                                      ;Z*COS(í)
add     Zt,ax
mov     ax,Zt
sar     ax,8
mov     Zt,ax
mov     ax,Zt
mov     Z,ax
mov     ax,Xt
mov     X,ax

; Rotate around z-axis
; XT = X * COS(zang) - Y * SIN(zang) / 256
; YT = X * SIN(zang) + Y * COS(zang) / 256
; X = XT
; Y = YT

mov     bx,X                                   ;xcoord in bx
mov     ax,Cos
imul    bx                                      ;X*COS(í)
mov     Xt,ax
mov     bx,Y                                   ;ycoord in bx
mov     ax,Sin
imul    bx                                      ;(X*SIN(í)
sub     Xt,ax
mov     ax,Xt
sar     ax,8
mov     Xt,ax

mov     bx,X                                      ;xcoord in bx
mov     ax,Sin
imul    bx                                      ;X*SIN(í)
mov     bx,Y                              ;ycoord in bx
mov     Yt,ax
mov     ax,Cos
imul    bx                                      ;(Y*COS(í)
add     Yt,ax
mov     ax,Yt
sar     ax,8
mov     Yt,ax

;calculate final VGA position
; Xoff*X / Z+Zoff = Screen x
; Yoff*Y / Z+Zoff = Screen y

; Xoff & Yoff = 256

mov     ax,Xt
add     ax,160
mov     ScreenX,ax
mov     ax,Yt
add     ax,100
mov     dx,ax
shl     ax,8
shl     dx,6
add     ax,dx
mov     di,ax
add     di,ScreenX
mov     word ptr [si+NPx6],di
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
add     si,NPx6
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
