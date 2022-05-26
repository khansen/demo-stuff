IDEAL
MODEL tiny
P386N
dataseg

message db 13,10,'Crappy Lenz Effect (CLE) 1997',13,10
        db 'Use arrow keys to move lens.',13,10,13,10
        db 'Press any key to begin.','$'
bufstuf dw 0040h
picfile db '1.pcx',0
totsize dw 30*30
Xsize   db 30
Ysize   db 30
Start   dw 16100
picture db 53000 dup (?)
palette db 768 dup (?)
area    db 30*30 dup (?)
dest    db 30*30 dup (?)

codeseg

org     100h

prog:

mov     ax,cs
mov     ds,ax
mov     es,ax

mov     ah,09
mov     dx,offset message
int     21h
mov     ah,00
int     16h

mov     ah,3Dh
mov     dx,offset picfile
xor     al,al
int     21h
mov     bx,ax
mov     ah,3Fh
mov     cx,128
mov     dx,offset picture
int     21h
mov     ah,3Fh
mov     cx,53000
mov     dx,offset picture
int     21h

mov     ax,13h
int     10h

mov     ax,0a000h
mov     es,ax
xor     di,di

lea     si,[picture]
xor     dx,dx
displaybytes:
lodsb
mov     bl,al
and     al,11000000b
cmp     al,11000000b
jne     Display_It
mov     al,bl
and     al,00111111b
xor     ah,ah
mov     cx,ax
add     dx,cx
lodsb
rep     stosb
pop     cx
cmp     dx,64000
jae     next
jmp     DisplayBytes
Display_It:
mov     al,bl
stosb
inc     dx
cmp     dx,64000
jae     next
jmp     DisplayBytes

next:

inc     si
push    es
mov     ax,cs
mov     es,ax
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

mov     bx,320
mov     dl,[Xsize]
xor     dh,dh
sub     bx,dx
shr     dl,1

pop     es

main:

push    ds
mov     ds,[bufstuf]
mov     ax,[ds:01ch]            ;sett tail og head equal
mov     [ds:01ah],ax
pop     ds

mov     di,[Start]
lea     si,[area]
mov     cl,[Ysize]
yloop:
push    cx
mov     cl,dl
xloop:
mov     ax,[word ptr es:di]
mov     [word ptr si],ax
add     si,2
add     di,2
loop    xloop
add     di,bx
pop     cx
loop    yloop

mov     ax,cs
mov     es,ax

lea     si,[area]
lea     di,[dest]
mov     cx,[TotSize]
add     si,cx
dec     si
copy:
mov     al,[byte ptr si]
mov     [byte ptr di],al
inc     di
dec     si
loop    copy

lea     si,[dest]
call    DrawLens

lea     si,[area]
waitkey:
in      al,60h
cmp     al,4Bh
je      left
cmp     al,4Dh
je      right
cmp     al,50h
je      up
cmp     al,48h
je      down
cmp     al,1
je      exit
jmp     waitkey

right:
call    waitvrt
call    DrawLens
inc     [Start]
jmp     main
left:
call    waitvrt
call    DrawLens
dec     [Start]
jmp     main
up:
call    waitvrt
call    DrawLens
add     [Start],320
jmp     main
down:
call    waitvrt
call    DrawLens
sub     [Start],320
jmp     main

exit:
mov     ax,3
int     10h
int     20h

INCLUDE "waitvrt.inc"

PROC DrawLens
mov     ax,0a000h
mov     es,ax
mov     di,[Start]
mov     dl,[Xsize]
shr     dl,1
draw_lens:
mov     cl,[Ysize]
loop1:
push    cx
mov     cl,dl
rep     movsw
add     di,bx
pop     cx
loop    loop1
ret
ENDP DrawLens

end     prog
