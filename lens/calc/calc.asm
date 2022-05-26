DOSSEG
.MODEL SMALL
.STACK 100h
jumps
.data

message db 'Calculating transformation array, please wait...$',13,10
filename db 'calc.inc',0

D       dw 50           ;Lens Diameter
R       dw 25           ;Lens Radius
M       dw 5            ;Magnification Factor
S       dw 0
A       dw 0
B       dw 0
X       dw 0
Y       dw 0
Z       dw 0
Check   dw 0
First   dw 0
TFM     db 5000 dup (?)

.code

mov     ax,@data
mov     ds,ax

mov     ah,3Ch
xor     cx,cx
mov     dx,offset filename
int     21h

mov     ax,3
int     10h

mov     ah,09
mov     dx,offset message
int     21h

;PRINT "Magnification factor (0>Mó"; LTRIM$(STR$(R)); ")"; : INPUT M
;
;DIM TFM(D * D)
;
;FOR Y = -R TO -R + D - 1
;    FOR X = -R TO -R + D - 1
;        IF X ^ 2 + Y ^ 2 >= S ^ 2 THEN
;            A = X
;            B = Y
;        ELSE
;            Z = SQR(R ^ 2 - X ^ 2 - Y ^ 2)
;            A = INT(X * M / Z + .5)
;            B = INT(Y * M / Z + .5)
;        END IF
;        TFM(1 + (Y + R) * D + (X + R)) = (B + R) * D + (A + R)
;    NEXT X
;NEXT Y

;S = SQR(R ^ 2 - M ^ 2)

mov     ax,R
mov     bx,ax
imul    bx
mov     S,ax
mov     ax,M
mov     bx,ax
imul    bx
sub     S,ax                    ;OK

mov     Y,-25
lea     si,TFM
mov     cx,D

x_loop:
mov     X,-25
push    cx
mov     cx,D

super_loop:

;        IF X ^ 2 + Y ^ 2 >= S ^ 2 THEN
;            A = X
;            B = Y

mov     ax,X
mov     bx,ax
imul    bx
mov     Check,ax
mov     ax,Y
mov     bx,ax
imul    bx
add     Check,ax
mov     ax,S
mov     bx,ax
imul    bx
mov     bx,Check
cmp     bx,ax
jge     not_changed

changed:

;            Z = SQR(R ^ 2 - X ^ 2 - Y ^ 2)

mov     ax,R
mov     bx,ax
imul    bx
mov     Z,ax
mov     ax,X
mov     bx,ax
imul    bx
sub     Z,ax
mov     ax,Y
mov     bx,ax
imul    bx
sub     Z,ax

;            A = INT(X * M / Z + .5)

mov     ax,X
mov     bx,M
imul    bx
mov     bx,Z
xor     dx,dx
idiv    bx
mov     A,ax

;            B = INT(Y * M / Z + .5)

mov     ax,Y
mov     bx,M
imul    bx
mov     bx,Z
xor     dx,dx
idiv    bx
mov     B,ax
jmp     final_calc

not_changed:
mov     ax,X
mov     A,ax
mov     ax,Y
mov     B,ax

;        TFM(1 + (Y + R) * D + (X + R))

final_calc:

;mov     ax,1
;add     ax,Y
;add     ax,R
;mov     bx,D
;imul    bx
;add     ax,X
;add     ax,R
;mov     First,ax

; (B + R) * D + (A + R)

mov     ax,B
add     ax,R
mov     bx,D
imul    bx
add     ax,A
add     ax,R
mov     word ptr [si],ax
add     si,2

inc     X
loop    super_loop
inc     Y
pop     cx
loop    x_loop

exit:

mov     ah,3Dh
mov     al,2
mov     dx,offset filename
int     21h

mov     bx,ax
mov     ah,40h
mov     cx,5000
mov     dx,offset TFM
int     21h

mov     ax,4c00h
int     21h

;        TFM(1 + (Y + R) * D + (X + R)) = (B + R) * D + (A + R)
;    NEXT X
;NEXT Y

end
