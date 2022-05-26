DOSSEG
.MODEL SMALL
.386
.STACK 100h
JUMPS
.data

fntfile         db 'font.raw',0
palfile         db 'palette.pal',0
scrltxt         db '                                                this is the  wellknown   vertical     scroller                                                                 ',0
           
order           db 'abcdefghijklmn%opqrstuvwxyz .',0
LineNumber      dw 0
CurrentChar     dw 0
MaxChars        dw 0
CharPos         dw 0
count           dw 0
X               dw 0
Y               dw 0
Y1              dw 0
Dist            dw 0
Lines           dw 0
font            db 16000 dup (?)
scrlbuf         db 30720 dup (?)
palette         db 768   dup (?)

.code

mov     ax,@data
mov     ds,ax
mov     es,ax

lea     di,scrlbuf
xor     ax,ax
mov     cx,30720/2
rep     stosw

mov     ah,3Dh
xor     al,al
mov     dx,offset fntfile
int     21h
mov     bx,ax
mov     ah,3Fh
mov     cx,16000
mov     dx,offset font
int     21h
mov     ah,3Eh
int     21h
mov     ah,3Dh
xor     al,al
mov     dx,offset palfile
int     21h
mov     bx,ax
mov     ah,3Fh
mov     cx,768
mov     dx,offset palette
int     21h
mov     ah,3Eh
int     21h

mov     ax,13h
int     10h

mov     dx,3c8h
xor     al,al
out     dx,al
mov     cx,768
inc     dx
lea     si,palette
rep     outsb

mov     CurrentChar,0
mov     LineNumber,7680

mainloop:

mov     CharPos,0
mov     ax,@data
mov     ds,ax
mov     es,ax

update_text:
mov     MaxChars,12
lea     si,scrltxt
add     si,CurrentChar
do_first_line:
lodsb
push    si
call    GetFontPos
lea     di,scrlbuf
add     di,CharPos
lea     si,font
add     si,bx
add     si,count
mov     cx,24
sub     cx,Lines
call    DrawChar
pop     si
dec     MaxChars
jnz     do_first_line

mov     CharPos,0
mov     dx,2
prepare:
mov     MaxChars,12
do_one_line:
lodsb
push    si
call    GetFontPos
lea     di,scrlbuf
add     di,LineNumber
add     di,CharPos
lea     si,font
add     si,bx
mov     cx,24
call    DrawChar
pop     si
dec     MaxChars
jnz     do_one_line
add     CharPos,7736-320
dec     dx
jnz     prepare

mov     MaxChars,12

do_last_line:
lodsb
push    si

call    GetFontPos
lea     di,scrlbuf
add     di,LineNumber
add     di,CharPos
lea     si,font
add     si,bx
mov     cx,Lines
inc     cx
call    DrawChar
pop     si
dec     MaxChars
jnz     do_last_line

disp:

call    waitvrt

mov     ax,0a000h
mov     es,ax

lea     si,scrlbuf
mov     cx,30720/4
xor     di,di
rep     movsd

sub     LineNumber,320
inc     Lines
cmp     Lines,24
jnz     skip_it2
mov     Lines,0
mov     LineNumber,7680
add     CurrentChar,12
cmp     CurrentChar,96
jnz     Skip_It2
mov     CurrentChar,0
skip_it2:
mov     CharPos,0
add     count,320
cmp     count,7680
jnz     continue
mov     count,0
continue:
in      al,60h
dec     al
jnz     mainloop

mov     ax,3
int     10h
mov     ax,4c00h
int     21h
INCLUDE waitvrt.inc

GetFontPos PROC
lea     di,order
xor     bx,bx
find_char:
cmp     byte ptr [di],'%'
je      addstuff
cmp     byte ptr [di],al
je      next
inc     di
add     bx,22
jmp     find_char
addstuff:
mov     bx,7360
inc     di
jmp     find_char
next:
ret
GetFontPos ENDP

DrawChar PROC
do_char:
push    cx
mov     cx,11
rep     movsw
add     di,298
add     si,298
pop     cx
loop    do_char
add     CharPos,22
ret
DrawChar ENDP

end
