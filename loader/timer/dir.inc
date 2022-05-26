DirEngine PROC

display_dir:

mov     ax,@data
mov     ds,ax
mov     es,ax

push    es
mov     ah,2Fh
int     21h
mov     dtaseg,es
mov     dtaofs,bx
pop     es

mov     num_files,0

xor     al,al
mov     di,offset dirdata + filename
mov     cx,13
rep     stosb

mov     di,offset bigbuffer
mov     cx,500
rep     stosb

mov     dx,offset dirdata
mov     ah,1Ah
int     21h

xor     bx,bx
mov     ah,4Eh
mov     cx,10h
mov     dx,offset defaultspec
jmp     text_next
text_prepare:
mov     ah,4Fh
text_next:
int     21h
jc      done
lea     si,dirdata + 21
lodsb
cmp     al,16
jnz     normal_file
lea     si,dirdata + Filename
lea     di,bigbuffer
add     di,bx
mov     byte ptr [di],1
jmp     save_filename
normal_file:
lea     si,dirdata + Filename
lea     di,bigbuffer
add     di,bx
mov     byte ptr [di],0
save_filename:
inc     di
mov     cx,13
rep     movsb
inc     num_files
add     bx,14
xor     al,al
mov     di,offset dirdata + filename
mov     cx,13
rep     stosb
jmp     text_prepare

done:
push    ds
mov     ds,dtaseg
mov     dx,dtaofs
mov     ah,1Ah
int     21h
pop     ds

mov     di,offset currentdir
mov     cx,64
xor     al,al
rep     stosb

xor     dl,dl
mov     ah,47h
mov     si,offset currentdir
int     21h

mov     ax,14
mov     bx,num_files
mul     bx
sub     ax,14
mov     _offset,ax

mov     ax,0b800h
mov     es,ax

mov     di,160*2
xor     ax,ax
mov     cx,80*20
rep     stosw

mov     di,160*23
mov     cx,32
mov     si,offset file_keys
mov     ah,15
call    disp_string
xor     al,al
mov     cx,30
rep     stosw

mov     di,160*24
mov     cx,80
mov     si,offset file_message
mov     ah,16*7+0
call    disp_string

xor     di,di
mov     si,offset currentdir
mov     cx,64
mov     ah,16*7+0
xor     al,al
stosw
mov     al,'\'
stosw
call    disp_string

xor     al,al
mov     cx,15
rep     stosw

mov     screen_pos,166+160
mov     file_pointer,0
mov     pointer,0
refresh_dir:
mov     di,160
mov     al,'É'
mov     ah,8
stosw
mov     al,'Í'
mov     cx,78
rep     stosw
mov     al,'»'
stosw
mov     cx,20
mov     di,160+160
draw_frame:
mov     al,'º'
stosw
add     di,156
stosw
loop    draw_frame
mov     al,'È'
stosw
mov     al,'Í'
mov     cx,78
rep     stosw
mov     al,'¼'
stosw

mov     di,166+160
lea     si,bigbuffer
add     si,pointer
mov     bx,num_files
cmp     bx,80
jle     file_display
mov     bx,80
mov     ah,15
file_display:
mov     cx,13
mov     ah,15
lodsb
cmp     al,0
je      hahaha
mov     ah,10
hahaha:
call    disp_string
add     di,14
dec     bx
jnz     file_display

FILE_wait_key:

mov     di,screen_pos
mov     cx,13
mov     ah,16*7+0
make_it:
mov     al,byte ptr es:[di]
stosw
loop    make_it
mov     ah,00
int     16h
cmp     al,13
je      open_file
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
cmp     al,27
je      exit
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
mov     ax,_offset
cmp     file_pointer,ax
je      FILE_wait_key
cmp     screen_pos,160*21+6+40*3
je      FILE_wait_key
add     screen_pos,40
add     file_pointer,14
jmp     refresh_dir
FILE_down_one_line:
mov     ax,_offset
cmp     ax,14*5
jl      FILE_wait_key
sub     ax,14*4
cmp     file_pointer,ax
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
mov     cx,80*20
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
mov     si,offset bigbuffer
add     si,file_pointer
inc     si
mov     di,offset FILE_NAME
mov     cx,13
rep     movsb
pop     es

lea     si,bigbuffer
add     si,file_pointer
lodsb
cmp     al,1
jnz     op_file

ch_dir:
mov     ah,3Bh
mov     dx,offset FILE_NAME
int     21h
jmp     display_dir

; open file, read it and store in buffer, close file

op_file:
xor     di,di
mov     cx,32000
xor     ax,ax
rep     stosw
ret
DirEngine ENDP
