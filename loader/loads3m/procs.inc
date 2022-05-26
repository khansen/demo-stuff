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
mov     ecx,59
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
cmp     byte ptr [esi],0
jnz     do_it
mov     al,249
mov     ah,8
stosw
stosw
stosw
jmp     smp_number

do_it:
xor     ebx,ebx
cmp     byte ptr [esi],0FEh
jnz     normal_note
mov     ah,12
mov     al,'Í'
stosw
stosw
stosw
jmp     smp_number
normal_note:
mov     ah,15
mov     bl,byte ptr [esi]
and     bl,00001111b
shl     bl,1
mov     al,Tones[ebx]
stosw
mov     al,Tones[ebx+1]
stosw
mov     al,byte ptr [esi]
shr     al,4
or      al,"0"
stosw
smp_number:
add     edi,2
cmp     byte ptr [esi+1],0
jnz     do_it2
mov     ah,8
mov     al,249
stosw
stosw
jmp     show_volume

do_it2:
mov     ah,11
mov     bh,byte ptr [esi+1]
HexDisp bh

show_volume:
add     edi,2
cmp     byte ptr [esi+2],120
jnz     do_it3
mov     ah,8
mov     al,249
stosw
stosw
jmp     show_effect

do_it3:
mov     bh,byte ptr [esi+2]
mov     ah,9
hexdisp bh

show_effect:
add     edi,2
mov     ah,11
mov     al,byte ptr [esi+3]
and     al,00001111b
call    HexDigit
stosw
mov     bh,byte ptr [esi+4]
HexDisp bh
add     esi,5
mov     ah,8
mov     al,179
stosw
loop    pat_loop
pop     edi
add     esi,5*4
next_line:
add     edi,160
dec     dl
jnz     prepare
ret
Update_Pattern ENDP
