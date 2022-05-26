DoPic   MACRO
mov     ax,0a000h
mov     es,ax
mov     di,0
lea     si,pic
mov     cx,64000
faentada:
lodsb
stosb
loop    faentada
ENDM

ReadyPalette MACRO
call    waitvrt
mov     ax,@data
mov     ds,ax
mov     es,ax
mov     dx,3c8h
xor     al,al
out     dx,al
lea     di,pal
lea     si,pal
inc     dx
mov     cx,768
ENDM

Fade_Out PROC

mov     bx,63

decpalcolors1:

ReadyPalette

get_b:
lodsb
cmp     al,0
je      out_it
dec     al
out_it:
mov     byte ptr [di],al
inc     di
out     dx,al
loop    get_b

dec     bx
jnz     Decpalcolors1
ret
Fade_Out ENDP

Fade_In    PROC

mov     bx,63

decpalcolors:

ReadyPalette

get_b1:
lodsb
cmp     al,63
je      out_it1
inc     al
out_it1:
mov     byte ptr [di],al
inc     di
out     dx,al
loop    get_b1

dec     bx
jnz     Decpalcolors
ret
Fade_In    ENDP

