DOSSEG
.MODEL small
.STACK 100h
.386
.data

message db 'Plazma in 100% (t)ASM by Kent Hansen',13,10,'$'
INCLUDE cosine.dat
Flag    db 0
Col     db 0
Y       dw 0
X       dw 0
A       dw 0
palfile db '00000002.pal',0
palette db 768 dup (?)

.code

mov     ax,13h
int     10h

mov     ax,@data
mov     ds,ax
mov     es,ax
mov     ah,3Dh
xor     al,al
mov     dx,offset palfile
int     21h
mov     bx,ax
mov     ah,3Fh
mov     cx,768
mov     dx,offset palette
int     21h
mov     ah,3Eh
int     21h

mov     dx,3c8h
xor     al,al
out     dx,al
inc     dx
mov     cx,768
lea     si,[palette]
rep     outsb

mov     ax,0a000h
mov     es,ax

;Y = Sin( (X)+(A * 2) ) + Sin( (X*2)+(A / 2) ) + Sin( (X/2) + A)

reset:
call    waitvrt
mov     [Y],0
xor     di,di
mov     bx,200
plasmaloop:
mov     [X],0
mov     cx,320
Hloop:
lea     si,[cosine]
add     si,[X]
mov     ax,[A]
shl     ax,1
add     si,ax
add     si,[Y]
lodsb
mov     dl,al
lea     si,[cosine]
mov     ax,[X]
shl     ax,1
add     si,ax
mov     ax,[A]
shr     ax,1
add     si,ax
lodsb
add     dl,al
lea     si,[cosine]
mov     ax,[X]
shr     ax,1
add     si,ax
add     si,[A]
lodsb
add     dl,al
lodsb
add     dl,al
mov     byte ptr es:[di],dl
inc     di
inc     [X]
loop    Hloop
inc     [Y]
dec     bx
jnz     plasmaloop

inc     [A]
cmp     [A],512
jnz     continue
mov     [A],0
continue:
in      al,60h
dec     al
jnz     reset

mov     ax,3
int     10h
mov     dx,offset message
mov     ah,09
int     21h
mov     ax,4c00h
int     21h

INCLUDE waitvrt.inc

end
