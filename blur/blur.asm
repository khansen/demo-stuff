IDEAL
P386N
MODEL SMALL
STACK 100h
DATASEG

include "palette.inc"

screenbuffer    db 32000 dup (?)

CODESEG

start:

mov     ax,13h
int     10h

mov     ax,@data
mov     ds,ax
mov     ax,0a000h
mov     es,ax

mov     dx,3c8h
xor     al,al
out     dx,al
inc     dx
mov     cx,768
mov     si,offset palette
rep     outsb

mov     si,offset screenbuffer
mov     cx,32000/4
clear_buffer:
mov     [dword ptr si],0
add     si,4
loop    clear_buffer

prepare_blur:
mov     si,offset screenbuffer

mov     ax,3
int     33h
shr     cx,1
shl     dx,8
mov     bx,dx
shr     dx,2
add     bx,dx
add     bx,cx

mov     [dword ptr si+bx],0FFFFFFFFh
mov     [dword ptr si+bx+4],0FFFFFFFFh
mov     [dword ptr si+bx+320],0FFFFFFFFh
mov     [dword ptr si+bx+320+4],0FFFFFFFFh
mov     [dword ptr si+bx+320*2],0FFFFFFFFh
mov     [dword ptr si+bx+320*2+4],0FFFFFFFFh
mov     [dword ptr si+bx+320*3],0FFFFFFFFh
mov     [dword ptr si+bx+320*3+4],0FFFFFFFFh
mov     [dword ptr si+bx+320*4],0FFFFFFFFh
mov     [dword ptr si+bx+320*4+4],0FFFFFFFFh
mov     [dword ptr si+bx+320*5],0FFFFFFFFh
mov     [dword ptr si+bx+320*5+4],0FFFFFFFFh
mov     [dword ptr si+bx+320*6],0FFFFFFFFh
mov     [dword ptr si+bx+320*6+4],0FFFFFFFFh
mov     [dword ptr si+bx+320*7],0FFFFFFFFh
mov     [dword ptr si+bx+320*7+4],0FFFFFFFFh

mov     cx,32000
blur_screen:
xor     ax,ax
add     al,[byte ptr si-1]
add     al,[byte ptr si+1]
adc     ah,0
add     al,[byte ptr si]
adc     ah,0
add     al,[byte ptr si-320]
adc     ah,0
shr     ax,2
mov     [byte ptr si],al
inc     si
loop    blur_screen

    mov     dx,3dah
Vrt:
    in      al,dx
    test    al,1000b        
    jnz     Vrt            
NoVrt:
    in      al,dx
    test    al,1000b         
    jz      NoVrt         

xor     di,di
mov     cx,32000/4
mov     si,offset screenbuffer
rep     movsd

in      al,60h
dec     al
jnz     prepare_blur

mov     ax,3
int     10h

mov     ax,4c00h
int     21h

end     start
