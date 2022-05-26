ideal
model small
codeseg

org     100h

start:

mov     ah,0b8h
mov     es,ax

xor     di,di
main:
mov     cx,[word ptr es:di]
cmp     cl,20h
je      done

push    di
mov     [byte ptr es:di],20h
loopert:
add     di,160
mov     bx,[word ptr es:di]
mov     [word ptr es:di],cx

;==== wait for vertical retrace

    mov     dx,3dah
Vrt:
    in      al,dx
    test    al,1000b        
    jnz     Vrt            
NoVrt:
    in      al,dx
    test    al,1000b         
    jz      NoVrt         

mov     [word ptr es:di],bx

in      al,60h
dec     al
jz      exit

cmp     di,160*24
jb      loopert

mov     [word ptr es:di],cx
pop     di

done:
add     di,2
cmp     di,4000-160
jnz     main

exit:
int     20h
end     start
