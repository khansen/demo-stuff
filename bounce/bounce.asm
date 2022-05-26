IDEAL
P386N
MODEL FLAT
STACK 1000h
JUMPS

DATASEG

video_mem       dd 0A0000h

Xpos    dd 0
Ypos    dd 0

Xspeed  dd 1
Yspeed  dd 1

CODESEG

start:

mov     ax,0EE02h
int     31h

sub     [video_mem],ebx

mov     ax,13h
int     10h

main_loop:
mov     edi,[video_mem]
mov     eax,[Ypos]
shl     eax,8
add     edi,eax
shr     eax,2
add     edi,eax
add     edi,[Xpos]
mov     [byte ptr edi],15

call    waitvrt

mov     [byte ptr edi],0

mov     eax,[Xspeed]
add     [Xpos],eax
mov     eax,[Yspeed]
add     [Ypos],eax

in      al,60h
dec     al
jz      exit

cmp     [Xpos],0
je      bounce_right
cmp     [Xpos],319
je      bounce_left
cmp     [Ypos],0
je      bounce_down
cmp     [Ypos],199
je      bounce_up
jmp     main_loop

bounce_right:
mov     [Xspeed],1
jmp     main_loop
bounce_left:
mov     [Xspeed],-1
jmp     main_loop
bounce_up:
mov     [Yspeed],-1
jmp     main_loop
bounce_down:
mov     [Yspeed],1
jmp     main_loop

exit:

mov     ax,3
int     10h
mov     ax,4c00h
int     21h

PROC    WaitVrt
push    ax dx
    mov     dx,3dah
Vrt:
    in      al,dx
    test    al,1000b        
    jnz     Vrt            
NoVrt:
    in      al,dx
    test    al,1000b         
    jz      NoVrt         
pop     dx ax
    ret
ENDP    WaitVrt

end     start
