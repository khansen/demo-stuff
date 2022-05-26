Scope   PROC
mov     esi,offset DMAbuffer
xor     bx,bx
xor     dx,dx
mov     cx,1000
Show_Scope2:
mov     al,byte ptr [esi]
shr     al,1
add     al,20
mov     byte ptr [esi+1000],al
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
inc     esi
loop    Show_Scope2

call    waitvrt

mov     esi,offset DMAbuffer
add     esi,1000
xor     dx,dx
xor     bx,bx
mov     cx,1000
Erase_Scope:
mov     al,byte ptr [esi]
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
inc     esi
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

mov     edi,VideoMem
add     edi,110

xor     ebx,ebx
mov     bx,TextPointer
mov     dl,25
mov     dh,LinePointer
mov     ah,15
disp_loop:
HexDisp dh
xor     al,al
stosw
mov     esi,offset smp_data.SAMPLE_NAME
add     esi,ebx
mov     ecx,22
mov     ah,15
call    Disp_String

add     di,110
add     ebx,size smp_info
inc     dh
dec     dl
jnz     disp_loop
pop     es
ret
Update_Text ENDP

Update_Pattern PROC

mov     edi,VideoMem
add     edi,160*8+8

mov     esi,offset PatternBuffer
add     esi,OrderPointer
xor     eax,eax
mov     ax,PatternPointer
add     esi,eax
mov     dl,16
mov     dh,row
prepare:

cmp     dh,64
jl      normal_line
xor     ax,ax
mov     ecx,47
rep     stosw
add     edi,66
jmp     next_line

normal_line:
push    edi
mov     ah,15
HexDisp dh
inc     dh

mov     ecx,4
mov     ah,8
mov     al,179
stosw
pat_loop:
cmp     byte ptr [esi+1],0
jnz     do_it
mov     al,249
mov     ah,8
stosw
stosw
stosw
jmp     smp_number

do_it:
xor     ebx,ebx
mov     bl,byte ptr [esi+1]
shl     bl,1
mov     ah,15
mov     al,Tones[ebx]
stosw
mov     al,Tones[ebx+1]
stosw
mov     al,Tones[ebx+2]
stosw

smp_number:
add     edi,2
cmp     byte ptr [esi],0
jnz     do_it2
mov     ah,8
mov     al,249
stosw
stosw
jmp     show_effect

do_it2:
mov     ah,11
mov     bh,byte ptr [esi]
HexDisp bh

show_effect:
add     edi,2
mov     ah,11
mov     al,byte ptr [esi+2]
and     al,00001111b
call    HexDigit
stosw
mov     bh,byte ptr [esi+3]
HexDisp bh
add     esi,4
mov     ah,8
mov     al,179
stosw
loop    pat_loop
pop     edi
next_line:
add     edi,160
dec     dl
jnz     prepare
ret
Update_Pattern ENDP