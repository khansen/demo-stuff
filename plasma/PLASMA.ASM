IDEAL
MODEL tiny
P386N
DATASEG

message db 'Plazma by SnowBro',13,10,'$'
INCLUDE "cosine.dat"
Col     db 0
palfile db '00000002.pal',0
palette db 768 dup (?)

CODESEG

Org     100h

Start:

mov     ax,13h
int     10h

mov     ax,cs
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

xor     bp,bp
reset:
call    waitvrt
xor     di,di
mov     bx,200
plasmaloop:
mov     cx,320
Hloop:
mov     si,offset cosine
add     si,cx
mov     ax,bp
add     ax,ax
add     si,ax
mov     dl,[byte ptr si+bx]
mov     si,offset cosine
mov     ax,cx
add     ax,ax
add     si,ax
mov     ax,bp
shr     ax,1
add     si,ax
add     dl,[byte ptr si]
mov     si,offset cosine
mov     ax,cx
shr     ax,1
add     si,ax
add     si,bp
add     dl,[byte ptr si]
add     dl,[byte ptr si+1]
mov     [byte ptr es:di],dl
inc     di
loop    Hloop
dec     bx
jnz     plasmaloop

inc     bp
and     bp,511
in      al,60h
dec     al
jnz     reset

mov     ax,3
int     10h
mov     dx,offset message
mov     ah,09
int     21h
int     20h

INCLUDE "waitvrt.inc"

end     Start
