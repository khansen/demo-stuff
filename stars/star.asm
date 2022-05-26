IDEAL
MODEL tiny
P286N

NumStars        EQU 500

dataseg

_256x224        dw 03F01h
                dw 04002h
                dw 04A04h
                dw 09A05h
                dw 00B06h
                dw 03E07h
                dw 04109h
                dw 0DA10h
                dw 09C11h
                dw 0BF12h
                dw 02013h
                dw 04014h
                dw 0C715h
                dw 00416h
                dw 0E317h

StarCoords      db NumStars*2 dup (?)

codeseg

Org     100h

start:

mov     al,13h
int     10h

mov     ah,0a0h
mov     es,ax

    mov     dx,3C4h          ; Sequencer Address Register

; === Set dot clock & scanning rate ===
    mov     ax,0100h
    out     dx,ax            ; Stop sequencer while setting Misc Output

    mov     dx,3C2h
    mov     al,0e3h          ; 0e3h = 227d = 11100011b
    out     dx,al            ; Select 25 MHz dot clock & 60 Hz scanning rate

    mov     dx,3C4h
    mov     ax,0300h         ; Index 00h --- 03h = 3d = 00000011b
    out     dx,ax            ; Undo reset (restart sequencer)

; === Remove write protection ===
    mov     dx,3D4h
    mov     al,11h           ; VSync End contains write protect bit (bit 7)
    out     dx,al
    inc     dx               ; Crt Controller Data register
    in      al,dx
    and     al,01111111b     ; Remove write protect on various CrtC registers
    out     dx,al            ; (bit 7 is 0)

mov     dx,3C4h
mov     ax,0E04h
out     dx,ax
 
mov     dx,3D4h
mov     cx,15
mov     si,offset _256x224              ; CHANGE THIS TO _256x256 or _256x240
Send_Values:
lodsw
out     dx,ax
loop    Send_Values

;==== generate X and Y coords for <NumStars> number of stars

in      ax,40h                                  ;get a random number

mov     si,offset StarCoords

mov     bx,NumStars                             ;do all stars
rand_loop:
mov     cx,255                                  ;get random X coord (0-319)
call    Random
mov     cx,255                                  ;get random Y coord (0-199)
call    Random
dec     bx
jnz     rand_loop

prepare:
mov     si,offset StarCoords
mov     cx,NumStars
mov     dl,32
draw_stars:
mov     di,[word ptr si]
cmp     dl,32
jnz     skip
mov     dl,22
skip:
mov     [byte ptr es:di],dl
add     si,2
add     dl,2
loop    draw_stars

;==== wait for vertical retrace

    mov     dx,3dah
Vrt:
    in      al,dx
    test    al,8                                ;test 3rd bit
    je      Vrt

;==== wait for vertical retrace

    mov     dx,3dah
Vrt2:
    in      al,dx
    test    al,8                                ;test 3rd bit
    je      Vrt2

mov     si,offset StarCoords
mov     cx,NumStars
mov     dl,6
erase_stars:
mov     di,[word ptr si]
mov     [byte ptr es:di],0
cmp     dl,6
jnz     skip_it
mov     dl,1
skip_it:
add     [byte ptr si],dl
add     [byte ptr si+1],dl
add     si,2
inc     dl
loop    erase_stars

in      al,60h
dec     al
jnz     prepare

mov     ax,3h
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
    mov     [byte ptr si],dl
    inc     si
    pop     ax
    ret
ENDP    Random

end     start
