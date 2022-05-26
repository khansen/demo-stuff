IDEAL
MODEL tiny
P286N
DATASEG

array           db 32000 dup (?)

CODESEG

org     100h

start:

mov     dx,3c8h
out     dx,al

mov     al,13h
int     10h

push    0a000h
pop     es

inc     dx

mov     cl,64
pal_loop1:
call    DoPal                                   ;0-63 black
loop    pal_loop1

mov     cl,63
pal_loop2:
call    DoPal                                   ;64-127 red
inc     bl
loop    pal_loop2

mov     cl,63
pal_loop3:
call    DoPal                                   ;128-191 red to yellow
inc     bh
loop    pal_loop3

mov     cl,63
pal_loop4:
call    DoPal                                   ;192-255 yellow to white
inc     ah
loop    pal_loop4

prepare:

mov     cx,31360
mov     si,offset array
main_loop:

;pixel som kalkuleres = ((16*A)+(14*C)+B+D) / 32
;hvor Pixel A = pixel+320, B = Pixel+639, C = Pixel+640, D = Pixel+641
;
;       # <-- Pixel som kalkuleres
;       A
;      BCD
;

mov     al,[byte ptr si+320]
xor     ah,ah
shl     ax,4                                  ;gang den med 16  
mov     bl,[byte ptr si+639]
xor     bh,bh
add     ax,bx                                 ;addes vanlig (pixel B)
mov     bl,[byte ptr si+641]
add     ax,bx                                 ;addes vanlig (pixel D)
mov     bl,[byte ptr si+640]
mov     dl,bl
xor     dh,dh
shl     bx,4                                  ;gang med 16
shl     dx,1                                  ;gang med 2
sub     bx,dx                               ;PixelC*16 - PixelC*2 = PixelC*14
add     ax,bx
shr     ax,5                                  ;skal deles med 32
dec     al

mov     [byte ptr si],al
inc     si
loop    main_loop

in      ax,40h

mov     bx,160
randloop:
mov     cx,65000

    add     ax,1234
    xor     al,ah
    rol     ah,1             ; Rotate left
    add     ax,4321
    ror     al,2             ; Rotate right
    xor     ah,al
    xor     dx,dx
    div     cx

mov     ax,dx
mov     [word ptr si],ax
add     si,2
dec     bx
jnz     randloop

mov     si,offset array
mov     cx,7840*2                               ;31360 / 4
mov     di,32000
rep     movsw

;==== wait for vertical retrace

    mov     dx,3dah
Vrt:
    in      al,dx
    test    al,8                                ;test 3rd bit
    je      Vrt

in      al,60h
dec     al
jnz     prepare

mov     ax,3
int     10h
ret

PROC    DoPal

mov     al,bl
out     dx,al
mov     al,bh
out     dx,al
mov     al,ah
out     dx,al

ret
ENDP    DoPal

end     start
