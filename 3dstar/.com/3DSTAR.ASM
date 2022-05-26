IDEAL
MODEL tiny
P386N
jumps

NumStars        EQU 200

DATASEG

R               db 0
G               db 0
B               db 0

Seed            dw ?
StarPos         dw ?
StarCount       dw ?
Z               dw ?
StarCol         db ?
StarCoords      dw NumStars*2 dup (?)
Zvariables      dw NumStars dup (?)
OldPos          dw NumStars dup (?)

CODESEG

Org     100h

START:

mov     ax,13h
int     10h

mov     ax,cs
mov     ds,ax
mov     es,ax

in      ax,40h
mov     [Seed],ax

lea     si,[starcoords]

mov     bx,NumStars/2
mov     cx,159
randloop_x:
call    Random
mov     [word ptr si],dx
add     si,2
call    Random
neg     dx
mov     [word ptr si],dx
add     si,2
dec     bx
jnz     randloop_x


mov     bx,NumStars/4
mov     cx,99
randloop_y:
call    Random
mov     [word ptr si],dx
add     si,2
call    Random
mov     [word ptr si],dx
add     si,2
call    Random
neg     dx
mov     [word ptr si],dx
add     si,2
call    Random
neg     dx
mov     [word ptr si],dx
add     si,2
dec     bx
jnz     randloop_y

lea     di,[Zvariables]
mov     cx,NumStars
mov     ax,255
rep     stosw

mov     dx,3c8h
xor     al,al
out     dx,al

inc     dx

mov     cx,63
pal_loop1:
call    DoPal                                   ;0-63 red
inc     [R]
loop    pal_loop1

mov     cx,63
pal_loop2:
call    DoPal                                   ;64-127 red to yellow
inc     [G]
loop    pal_loop2

mov     cx,63
pal_loop3:
call    DoPal                                   ;128-191 yellow to white
inc     [B]
loop    pal_loop3

mov     cx,63
pal_loop4:
call    DoPal                                   ;192-255 white
loop    pal_loop4

mov     ax,0a000h
mov     es,ax

PREPARE:
mov     cx,NumStars
lea     si,[StarCoords]
lea     di,[OldPos]
mov     [StarCount],0

MAIN_LOOP:

push    si
lea     si,[Zvariables]
add     si,[StarCount]
add     si,[StarCount]
mov     ax,[word ptr si]
mov     [z],ax
mov     [StarCol],255
sub     [StarCol],al
pop     si

;Ycoord
mov     ax,[word ptr si + (NumStars * 2)]
movsx   dx,ah
shl     ax,8
mov     bx,[z]
idiv    bx
add     ax,100
cmp     ax,200
jae     Terminate
mov     dx,ax
shl     ax,8
shl     dx,6
add     ax,dx
mov     [StarPos],ax

;Xcoord
mov     ax,[word ptr si]
movsx   dx,ah
shl     ax,8
mov     bx,[z]
idiv    bx
add     ax,160
cmp     ax,320
jae     Terminate
add     [StarPos],ax

mov     bx,[StarPos]
mov     [word ptr di],bx

mov     al,[StarCol]
mov     [byte ptr es:bx],al

inc     [StarCount]

add     di,2
add     si,2

loop    main_loop

call    waitvrt

lea     si,[OldPos]
mov     cx,NumStars
erase_loop:
mov     bx,[word ptr si]
mov     [byte ptr es:bx],0
add     si,2
loop    erase_loop

ready_Zvalues:
lea     si,[Zvariables]
mov     cx,NumStars
update_loop1:
sub     [word ptr si],2
cmp     [word ptr si],0
je      exit
add     si,2
loop    update_loop1

in      al,60h
cmp     al,1
je      exit

jmp     Prepare

Terminate:
push    si
lea     si,[Zvariables]
add     si,[StarCount]
add     si,[StarCount]
mov     [word ptr si],255
pop     si

jmp     main_loop

exit:
mov     ax,3
int     10h
int     20h

INCLUDE "waitvrt.inc"

PROC    DoPal

mov     al,[R]
out     dx,al
mov     al,[G]
out     dx,al
mov     al,[B]
out     dx,al

ret
ENDP    DoPal

; =================================
;  Random: generates random number
;  Input : cx = range
;  Output: dx = random number
; =================================

PROC    Random NEAR             ; Reasonably random (can be improved)
    mov     ax,[Seed]
    add     ax,1234
    xor     al,ah
    rol     ah,1             ; Rotate left
    add     ax,4321
    ror     al,2             ; Rotate right
    xor     ah,al
    mov     [Seed],ax
    xor     dx,dx
    div     cx
    ret
ENDP    Random

end     start
