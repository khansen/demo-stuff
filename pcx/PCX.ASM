IDEAL
P286N
MODEL tiny

dataseg

picfile         db '1.pcx',0
picture         db 65100 dup (?)

codeseg

org     100h

start:  mov     al,13h
        int     10h

mov     bh,0a0h
mov     es,bx
xor     di,di

mov     ax,3D00h
mov     dx,offset picfile
int     21h

mov     bx,ax
mov     ah,3Fh
mov     cx,65100
mov     dx,offset picture
int     21h

;--- display .PCX file, set pal

lea     si,[picture + 128]
xor     dx,dx
xor     ah,ah
displaybytes:
lodsb
push    ax
and     al,11000000b
cmp     al,11000000b
jne     Display_It
pop     ax
and     al,00111111b
mov     cx,ax
add     dx,cx
lodsb
rep     stosb
jmp     check
Display_It:
pop     ax
stosb
inc     dx
check:
cmp     dx,64000
jnz     DisplayBytes

inc     si                              ;skip this byte
mov     dx,3c8h
xor     al,al
out     dx,al
inc     dx
mov     cx,768
pal_loop:
lodsb
shr     al,2
out     dx,al
loop    pal_loop

int     16h

mov     ax,3
int     10h
ret

end     start
