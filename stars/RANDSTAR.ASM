IDEAL
MODEL tiny
P286N

NumStars        EQU 500

dataseg

StarCoords      dw NumStars*3 dup (?)

codeseg

Org     100h

start:

mov     al,13h
int     10h

mov     ax,0a000h
mov     es,ax

;==== generate X and Y coords for <NumStars> number of stars

in      ax,40h                                  ;get a random number

lea     si,[StarCoords]

mov     bx,NumStars                             ;do all stars
rand_loop:
mov     cx,319                                  ;get random X coord (0-319)
call    Random
mov     cx,199                                  ;get random Y coord (0-199)
call    Random
dec     bx
jnz     rand_loop

PREPARE:
mov     cx,NumStars                             ;do all stars
push    cx                                      ;save cx, we need it later too
lea     si,[StarCoords]
mov     bp,1                                    ;speed of 1st level
mov     ah,100                                  ;no. of stars per level
mov     al,22                                   ;color of 1st level

;==== draw stars

MAIN_LOOP:
mov     bx,[word ptr si + NumStars*2]           ;Y coord (*2 because of word)
mov     di,bx
shl     di,6                                    ;Y*64
shl     bx,8                                    ;Y*256
add     di,bx                                   ;Y*64 + Y*256 = Y*320

add     di,[word ptr si]                        ;add X coord
                                                ;bx = screenpos = 320*Y + X
add     [word ptr si],bp                        ;add speed

mov     [word ptr si + NumStars*2*2],di         ;save starpos (for erasing)

stosb

cmpsw                                           ;advance si (next star)

dec     ah                                      ;done all stars of current
                                                ;level yet?
jnz     skip                                    ;if not, skip following code

                                                ;ADVANCE TO NEXT LEVEL:
inc     bp                                      ;increment speed of stars
mov     ah,100                                  ;no. of stars per level
add     al,2                                    ;make starcolor a bit brighter
skip:
loop    main_loop

;==== wait for vertical retrace

    mov     dx,3dah
Vrt:
    in      al,dx
    test    al,8                                ;test 3rd bit
    je      Vrt

;==== erase stars

pop     cx                                      ;cx = NumStars
lea     si,[StarCoords + NumStars*2*2]          ;old star positions
erase:
lodsw                                           ;get starpos in ax
mov     di,ax                                   ;put it in destination index
xor     ax,ax                                   ;color 0 = black
stosb                                           ;erase star
loop    erase                                   ;do all stars

in      al,60h
cmp     al,1                                    ;was ESC pressed?
jnz     prepare                                 ;if not, start over

mov     al,3                                    ;standard textmode
int     10h
ret

; =================================
;  Random: generates random number
;  Input : cx = range
;  Output: dx = random number
; =================================

PROC    Random NEAR             ; Reasonably random (can be improved)
    add     ax,1234
    xor     al,ah
    rol     ah,1             ; Rotate left
    add     ax,4321
    ror     al,2             ; Rotate right
    xor     ah,al
    push    ax
    xor     dx,dx
    div     cx
    mov     [word ptr si],dx
    cmpsw                       ;slower than "add di,2; add si,2" but saves a couple of bytes
    pop     ax
    ret
ENDP    Random

end     start
