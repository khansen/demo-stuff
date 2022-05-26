IDEAL
MODEL tiny
P286N
jumps
dataseg

startup                 db 13,10,' eLiTe converter v 1.0 by SnowBro',13,10
                        db ' Syntax: Elite <infile> <outfile>',13,10,'$'
error                   db 13,10,'ERROR: File not found.',13,10,'$'
done_converting         db 13,10,'Done.',13,10,'$'
numbytes                dw ?
InputFileHandle         dw ?
OutputFileHandle        dw ?
tempbuffer              db 64000 dup (?)
commandtail             db 128 dup (?)
outfile                 db 13 dup (?)
infile                  db 13 dup (?)

codeseg

org     100h

start:

mov     ax,cs
mov     es,ax

mov     si,offset 0080h
mov     di,offset commandtail
mov     cx,128/2
rep     movsw

mov     ax,cs
mov     ds,ax

mov     dx,offset startup
mov     ah,09
int     21h

mov     si,offset commandtail + 1
mov     di,offset infile
find_first_char:
cmp     [byte ptr si],0
je      terminate
cmp     [byte ptr si],' '
jnz     copy_filename
inc     si
jmp     find_first_char
copy_filename:
movsb
cmp     [byte ptr si],0
je      terminate
cmp     [byte ptr si],' '
jnz     copy_filename
mov     [byte ptr di],0

mov     di,offset outfile
find_first_char2:
cmp     [byte ptr si],0
je      terminate
cmp     [byte ptr si],' '
jnz     copy_filename2
inc     si
jmp     find_first_char2
copy_filename2:
movsb
cmp     [byte ptr si],0
jnz     copy_filename2
mov     [byte ptr di],0

mov     ax,3D00h
mov     dx,offset infile
int     21h
jc      file_error
mov     [InPutFileHandle],ax

mov     ah,3Ch
xor     cx,cx
mov     dx,offset outfile
int     21h
mov     ax,3D02h
mov     dx,offset outfile
int     21h
mov     [OutputFileHandle],ax

entry_point:

mov     bx,[InputFileHandle]
mov     ah,3Fh
mov     dx,offset tempbuffer
mov     cx,64000
int     21h
cmp     ax,0
je      done
mov     [numbytes],ax

mov     si,offset tempbuffer
mov     di,offset tempbuffer
mov     cx,[numbytes]

convert_if_necessary:
mov     al,[byte ptr si]
cmp     al,'z'
ja      write_byte
cmp     al,'A'
jb      write_byte
cmp     al,'z'
jbe     lower_case
cmp     al,'A'
jae     upper_case
jmp     write_byte
LOWER_CASE:
cmp     al,'a'
jb      upper_case
cmp     al,'a'
je      write_byte
cmp     al,'e'
je      write_byte
cmp     al,'i'
je      write_byte
cmp     al,'o'
je      write_byte
cmp     al,'u'
je      write_byte
sub     al,32
jmp     write_byte
UPPER_CASE:
cmp     al,'Z'
ja      write_byte
cmp     al,'A'
je      convert_to_lowercase
cmp     al,'E'
je      convert_to_lowercase
cmp     al,'I'
je      convert_to_lowercase
cmp     al,'O'
je      convert_to_lowercase
cmp     al,'U'
je      convert_to_lowercase
jmp     write_byte
convert_to_lowercase:
add     al,32
WRITE_BYTE:
mov     [byte ptr di],al
inc     si
inc     di
loop    convert_if_necessary

mov     ah,40h
mov     dx,offset tempbuffer
mov     bx,[OutputFileHandle]
mov     cx,[numbytes]
int     21h
jmp     entry_point

file_error:
mov     dx,offset error
mov     ah,09
int     21h
jmp     terminate

done:

mov     dx,offset done_converting
mov     ah,09
int     21h

terminate:
int     20h

end     start
