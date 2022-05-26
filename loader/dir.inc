DirEngine PROC

display_dir:

mov     ax,@data
mov     ds,ax
mov     es,ax

mov     num_files,0

mov     PSP,00000800h

;xor     ebx,ebx
;xor     eax,eax
;Mov     Ax,0EE02h               ; GET DOS32 ADDRESS INFORMATION
;Int     31h

;mov     edi,00800h
;sub     edi,ebx
;mov     PSP,edi

mov     edi,offset FileBuffer
mov     ecx,10000
rep     stosb

xor     ebx,ebx
xor     eax,eax
mov     ah,4Eh
mov     ecx,10h
mov     edx,offset defaultspec
jmp     text_next
text_prepare:
mov     ah,4Fh
text_next:
int     21h
jc      done
mov     esi,[ds:PSP] + 21
lodsb
cmp     al,16
jnz     normal_file
mov     esi,[ds:PSP] + 30
mov     edi,offset FileBuffer
add     edi,ebx
mov     byte ptr [edi],1
jmp     save_filename
normal_file:
mov     esi,[ds:PSP] + 30
mov     edi,offset FileBuffer
add     edi,ebx
mov     byte ptr [edi],0
save_filename:
inc     edi
mov     ecx,13
disp_disp:
mov     ah,02
mov     al,byte ptr [esi]
mov     dl,al
int     21h
inc     esi
loop    disp_disp
mov     ah,00
int     16h

mov     ecx,13
rep     movsb
inc     num_files
add     ebx,14
xor     al,al
mov     edi,[ds:PSP] + 30
mov     ecx,13
rep     stosb
jmp     text_prepare

done:

mov     edi,offset currentdir
mov     ecx,64
xor     al,al
rep     stosb

xor     dl,dl
mov     ah,47h
mov     esi,offset currentdir
int     21h

mov     eax,14
xor     ebx,ebx
mov     bx,num_files
mul     ebx
sub     eax,14
mov     _offset,eax

xor     ebx,ebx
xor     eax,eax
Mov     Ax,0EE02h               ; GET DOS32 ADDRESS INFORMATION
Int     31h

mov     edi,0B8000h
sub     edi,ebx
mov     VideoMem,edi

add     edi,160*2
xor     ax,ax
mov     ecx,80*20
rep     stosw

mov     edi,VideoMem
add     edi,160*23
mov     ecx,32
mov     esi,offset file_keys
mov     ah,15
call    disp_string
xor     al,al
mov     ecx,30
rep     stosw

mov     edi,VideoMem
add     di,160*24
mov     ecx,80
mov     esi,offset file_message
mov     ah,16*7+0
call    disp_string

mov     edi,VideoMem
mov     esi,offset currentdir
mov     ecx,64
mov     ah,16*7+0
xor     al,al
stosw
mov     al,'\'
stosw
call    disp_string
mov     ecx,16
mov     ah,16*7
xor     al,al
rep     stosw

mov     screen_pos,166+160
mov     file_pointer,0
mov     pointer,0
refresh_dir:
mov     edi,VideoMem
add     edi,160
mov     al,'É'
mov     ah,8
stosw
mov     al,'Í'
mov     ecx,78
rep     stosw
mov     al,'»'
stosw
mov     ecx,20
mov     edi,VideoMem
add     edi,160+160
draw_frame:
mov     al,'º'
stosw
add     di,156
stosw
loop    draw_frame
mov     al,'È'
stosw
mov     al,'Í'
mov     ecx,78
rep     stosw
mov     al,'¼'
stosw

mov     edi,VideoMem
add     edi,166+160
mov     esi,offset FileBuffer
add     esi,pointer
mov     bx,num_files
cmp     bx,80
jle     file_display
mov     bx,80
mov     ah,15
file_display:
mov     ecx,13
mov     ah,15
lodsb
cmp     al,0
je      hahaha
mov     ah,10
hahaha:
call    disp_string
add     edi,14
dec     bx
jnz     file_display

FILE_wait_key:

mov     edi,VideoMem
xor     eax,eax
mov     ax,screen_pos
add     edi,eax
mov     ecx,13
mov     ah,16*7+0
make_it:
mov     al,byte ptr [edi]
stosw
loop    make_it
mov     ah,00
int     16h
cmp     al,13
je      open_file
cmp     al,27
je      FILE_exit
cmp     ah,4Bh                          ;cursor left
je      FILE_move_left
cmp     ah,4Dh                          ;cursor right
je      FILE_move_right
cmp     ah,50h                          ;cursor down
je      FILE_down_one_line
cmp     ah,48h                          ;cursor up
je      FILE_up_one_line
cmp     ah,51h                          ;page down
je      FILE_next_page
cmp     ah,49h
je      FILE_prev_page                       ;page up
cmp     al,'0'
jl      FILE_wait_key
cmp     al,'9'
ja      FILE_wait_key
sub     al,2Fh
mov     ah,0Eh
mov     dl,al
int     21h
jmp     display_dir

FILE_move_left:
cmp     screen_pos,166+160
je      FILE_wait_key
sub     file_pointer,14
sub     screen_pos,40
jmp     refresh_dir
FILE_move_right:
mov     eax,_offset
cmp     file_pointer,eax
je      FILE_wait_key
cmp     screen_pos,160*21+6+40*3
je      FILE_wait_key
add     screen_pos,40
add     file_pointer,14
jmp     refresh_dir
FILE_down_one_line:
mov     eax,_offset
cmp     eax,14*5
jl      FILE_wait_key
sub     eax,14*4
cmp     file_pointer,eax
ja      FILE_wait_key
cmp     screen_pos,160*21
ja      FILE_wait_key
add     screen_pos,160
add     file_pointer,14*4
jmp     refresh_dir
FILE_up_one_line:
cmp     screen_pos,160+166+160
jl      FILE_wait_key
sub     screen_pos,160
sub     file_pointer,14*4
jmp     refresh_dir
FILE_next_page:
cmp     num_files,80
jle     FILE_wait_key
add     pointer,14*20*4
add     file_pointer,14*20*4
sub     num_files,80
mov     di,160*2
xor     ax,ax
mov     ecx,80*20
rep     stosw
jmp     refresh_dir
FILE_prev_page:
cmp     pointer,14*20*4
jl      FILE_wait_key
sub     pointer,14*20*4
sub     file_pointer,14*20*4
add     num_files,80
jmp     refresh_dir

open_file:
push    es
mov     ax,@data
mov     es,ax
mov     esi,offset FileBuffer
add     esi,file_pointer
inc     esi
mov     edi,offset FILE_NAME
mov     ecx,13
rep     movsb
pop     es

lea     esi,FileBuffer
add     esi,file_pointer
lodsb
cmp     al,1
jnz     op_file

ch_dir:
mov     ah,3Bh
mov     edx,offset FILE_NAME
int     21h
jmp     display_dir

FILE_exit:
mov     ax,3
int     10h
mov     ax,4c00h
int     21h

; open file, read it and store in buffer, close file

op_file:
ret
DirEngine ENDP
