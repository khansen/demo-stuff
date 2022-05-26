Scope   PROC
mov     si,offset DMAbuffer
xor     bx,bx
xor     dx,dx
mov     cx,1000
Show_Scope2:
mov     al,byte ptr [si]
shr     al,1
add     al,20
mov     byte ptr [si+1000],al
xor     ah,ah
add     bx,320
cmp     bx,1000
jb      skip2
sub     bx,1000
inc     dx
skip2:
shl     ax,8
mov     di,ax
shr     ax,2
add     di,ax
add     di,dx
mov     al,15
mov     byte ptr es:[di],al
inc     si
loop    Show_Scope2

call    waitvrt

mov     si,offset DMAbuffer
add     si,1000
xor     dx,dx
xor     bx,bx
mov     cx,1000
Erase_Scope:
mov     al,byte ptr [si]
xor     ah,ah
add     bx,320
cmp     bx,1000
jb      skip3
sub     bx,1000
inc     dx
skip3:
shl     ax,8
mov     di,ax
shr     ax,2
add     di,ax
add     di,dx
mov     byte ptr es:[di],0
inc     si
loop    Erase_Scope
ret
Scope   ENDP

Disp_String PROC
disp_char:
lodsb
stosw
loop    disp_char
ret
Disp_String ENDP

HexDigit PROC

;converts a 4-bit value (0-15) to ASCII 0-1, A-F

cmp     al,10
jb      normal
add     al,'A'-10
ret
normal:
or      al,"0"                          ;add 30h
ret
HexDigit ENDP

update_text PROC

push    es
mov     ax,0b800h
mov     es,ax

mov     di,110

mov     bx,TextPointer
mov     dl,25
mov     dh,LinePointer
mov     ah,15
disp_loop:
HexDisp dh
xor     al,al
stosw
mov     si,offset smp_data.SAMPLE_NAME
add     si,bx
mov     cx,22
mov     ah,15
call    Disp_String

add     di,110
add     bx,size smp_info
inc     dh
dec     dl
jnz     disp_loop
pop     es
ret
Update_Text ENDP

Update_Pattern PROC

mov     ax,0b800h
mov     es,ax

mov     di,160*8+8

mov     si,offset PatternBuffer
add     si,OrderPointer
add     si,PatternPointer
mov     dl,16
mov     dh,row
prepare:

cmp     dh,64
jl      normal_line
xor     ax,ax
mov     cx,47
rep     stosw
add     di,66
jmp     next_line

normal_line:
mov     ah,15
HexDisp dh
inc     dh

mov     cx,4
push    di
mov     ah,8
mov     al,179
stosw
pat_loop:
cmp     byte ptr [si+1],0
jnz     do_it
mov     al,249
mov     ah,8
stosw
stosw
stosw
jmp     smp_number

do_it:
mov     bl,byte ptr [si+1]
shl     bl,1
xor     bh,bh
push    si
mov     si,offset Tones
add     si,bx
mov     ah,15
lodsb
stosw
lodsb
stosw
lodsb
stosw
pop     si

smp_number:
add     di,2
cmp     byte ptr [si],0
jnz     do_it2
mov     ah,8
mov     al,249
stosw
stosw
jmp     show_effect

do_it2:
mov     ah,11
mov     bh,byte ptr [si]
HexDisp bh

show_effect:
add     di,2
mov     ah,11
mov     al,byte ptr [si+2]
and     al,00001111b
call    HexDigit
stosw
mov     bh,byte ptr [si+3]
HexDisp bh
add     si,4
mov     ah,8
mov     al,179
stosw
loop    pat_loop
pop     di
add     di,156
next_line:
dec     dl
jnz     prepare
ret
Update_Pattern ENDP
