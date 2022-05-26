IDEAL
P386N
MODEL FLAT
STACK 1000h

dataseg

file_error      db 'ERROR: Could not open file.',13,10,'$'
filename        db 128 dup (?)
header          db 128 dup (?)
picture         db 1000000 dup (?)
virtual_screen  db 1000000 dup (?)
Xmax            dw ?
Ymax            dw ?
NumPixels       dd ?

codeseg

start:
mov     ax,0ee02h
int     31h

push    ebx

movzx   ecx,[byte ptr esi + 80h]                ; command tail length
add     esi,81h                                 ; first command tail character
find_first_char:
cmp     [byte ptr esi],20h                      ; is it a space?
jnz     copy_filename                           ; nope, found the parameter
inc     esi                                     ; next char
dec     cl                                      ; scanned entire string?
jz      terminate                               ; yep
jmp     find_first_char                         ; nope, try again

copy_filename:
mov     edi,offset filename
rep     movsb
mov     [byte ptr edi],0

mov     edx,offset filename
mov     ax,3D00h
int     21h
jnc     file_ok

mov     ah,09
mov     edx,offset file_error
int     21h                                     ; display error message
jmp     terminate                               ; and exit

file_ok:
mov     bx,ax
mov     ah,3Fh
mov     edx,offset header
mov     ecx,128
int     21h
mov     ah,3Fh
mov     edx,offset picture
mov     ecx,-1
int     21h

movzx   eax,[word ptr header + 8]
inc     ax
mov     [Xmax],ax
mov     ebx,eax
mov     ax,[word ptr header + 10]
inc     ax
mov     [Ymax],ax
mul     ebx
mov     [NumPixels],eax

mov     esi,offset picture
mov     edi,offset virtual_screen
xor     edx,edx                                   ; pixel-counter
decode_pic:
lodsb
push    ax
and     al,11000000b
cmp     al,11000000b                            ; if bit 7 & 6 are set...
je      haha
pop     ax
stosb                                           ; write original value
inc     edx                                     ; increase pixel-counter
jmp     check
haha:
pop     ax
and     al,00111111b                            ; loop count in lower 6 bits
movzx   ecx,al
add     edx,ecx                                 ; add # to pixel-counter
lodsb                                           ; load data
store_loop:
stosb
dec     cl
jnz     store_loop
check:
cmp     edx,[NumPixels]                          ; done all pixels yet?
jnz     decode_pic                              ; nope, do some more

pop     ebx

mov     edi,0A0000h
sub     edi,ebx

mov     ax,13h
int     10h

inc     esi                              ;skip this byte
mov     dx,3c8h
xor     al,al
out     dx,al
inc     dx
mov     ecx,768
pal_loop:
lodsb
shr     al,2
out     dx,al
loop    pal_loop

movzx   eax,[Xmax]
mov     esi,offset virtual_screen
mov     bx,[Ymax]
cmp     bx,200
jb      display_pic
mov     bx,200
display_pic:
push    esi
mov     cx,[Xmax]
cmp     cx,320
jb      _OK
mov     cx,320
_OK:
rep     movsb
pop     esi
add     esi,eax
cmp     ax,320
jae     _OK2
add     edi,320
sub     edi,eax
_OK2:
dec     bx
jnz     display_pic

mov     ah,00
int     16h
mov     ax,3
int     10h

terminate:
mov     ax,4c00h
int     21h

end     start
