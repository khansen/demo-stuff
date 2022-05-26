IDEAL
P386N
MODEL FLAT
STACK 1000h
dataseg

video_mem       dd 0A0000h

tunnel_ofs      dd 0

include         "tunnel.inc"
include         "palette.inc"
include         "texture.inc"

creditz         db 13,10,' SnowBro 19(c)98',13,10,'$'

codeseg

start:

mov     ax,0EE02h
int     31h
sub     [video_mem],ebx

mov     ax,13h
int     10h

mov     dx,3c8h
xor     al,al
out     dx,al
inc     dx
mov     ecx,768
mov     esi,offset palette
rep     outsb

main_loop:
mov     esi,offset tunnel
mov     edi,[video_mem]
mov     ecx,64000/2
disp_loop:
movzx   eax,[word ptr esi]
add     eax,[tunnel_ofs]
and     eax,65535
mov     bl,[texture + eax]
add     esi,2
movzx   eax,[word ptr esi]
add     eax,[tunnel_ofs]
and     eax,65535
mov     bh,[texture + eax]
add     esi,2
mov     [word ptr edi],bx
add     edi,2
dec     ecx
jnz     disp_loop

call    waitvrt

add     [tunnel_ofs],256
in      al,60h
dec     al
jnz     main_loop

mov     ax,3
int     10h

mov     ah,09
mov     edx,offset creditz
int     21h

mov     ax,4c00h
int     21h

PROC    WaitVrt
    mov     dx,3dah
Vrt:
    in      al,dx
    test    al,1000b        
    jnz     Vrt            
NoVrt:
    in      al,dx
    test    al,1000b         
    jz      NoVrt         
    ret
ENDP    WaitVrt

end     start
