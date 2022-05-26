ideal
p386n
model flat
stack 100h
codeseg

start:

mov     ah,00
int     16h
mov     ebx,16
mov     cl,2
call    NumToASCII
mov     ax,4c00h
int     21h

PROC    NumToASCII
pushad
mov     ch,cl
@@10:
xor     edx,edx
div     ebx
push    edx
dec     cl
jnz     short @@10
mov     ah,02h
@@20:
pop     edx
mov     al,dl
call    HexDigit
mov     dl,al
int     21h
dec     ch
jnz     short @@20
popad
ret
ENDP    NumToASCII

PROC    HexDigit

; converts hex digit (range 0-F) to ASCII char

cmp     al,9
jbe     short @@10
add     al,7
@@10:
add     al,30h
ret
ENDP    HexDigit

end     start
