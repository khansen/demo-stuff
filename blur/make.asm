IDEAL
P386N
MODEL SMALL
STACK 100h
DATASEG

coordfile      db 'coords.raw',0
coordbuffer    db 32000 dup (?)

CODESEG

start:

mov     ax,13h
int     10h

mov     ax,@data
mov     ds,ax
mov     ax,0a000h
mov     es,ax

mov     ax,1
int     33h

mov     si,offset coordbuffer
xor     bp,bp
coord_loop:

    mov     dx,3dah
Vrt:
    in      al,dx
    test    al,1000b        
    jnz     Vrt            
NoVrt:
    in      al,dx
    test    al,1000b         
    jz      NoVrt         

mov     ax,3
int     33h
test    bl,1
jz      coord_loop

shr     cx,1
shl     dx,8
mov     ax,dx
shr     dx,2
add     ax,dx
add     ax,cx
mov     [word ptr si],ax
add     si,2
add     bp,2
test    bl,2
jz      coord_loop

exit:

mov     [dword ptr esi],'KENT'
add     bp,4
mov     ah,3Ch
xor     cx,cx
mov     dx,offset coordfile
int     21h
mov     bx,ax
mov     ah,40h
mov     cx,bp
mov     dx,offset coordbuffer
int     21h

mov     ax,3
int     10h

mov     ax,4c00h
int     21h

end     start
