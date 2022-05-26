DOSSEG
.MODEL SMALL
.386
.STACK 100h
.data
INCLUDE sintab1.inc
message                 db 'Coded in 100% (t)ASM by Kent Hansen',13,10,'19(c)97',13,10,'$'
picturelength           dw 0
pictureheight           dw 0
picfile                 db 'kis2.pic',0
pic                     db 48000 dup (?)
pal                     db 768 dup (?)
.code

mov     ax,@data
mov     ds,ax
mov     es,ax

mov     ah,3Dh
mov     al,0
mov     dx,offset picfile
int     21h
jc      exit
mov     bx,ax
mov     dx,offset pal
mov     ah,3Fh
mov     cx,768
int     21h
mov     dx,offset pic
mov     ah,3Fh
mov     cx,48000
int     21h

mov     ax,13h
int     10h

lea     si,pal
mov     al,0
mov     dx,3c8h
out     dx,al
inc     dx
mov     cx,768
rep     outsb

mov     ax,0a000h
mov     es,ax
mov     PictureLength,320
mov     PictureHeight,150
xor     ah,ah
xor     bx,bx
main_loop:
xor     dx,dx
mov     cx,PictureHeight
mov     si,offset pic
push    bx
vertical_loop:
push    cx
mov     al,sinus[bx]
mov     di,ax
add     di,dx
add     dx,320
sub     di,100
mov     cx,PictureLength
rep     movsb
inc     bl
pop     cx
loop    vertical_loop
call    waitvrt
pop     bx
add     bl,2
in      al,60h
cmp     al,1
jnz     main_loop

exit:
mov     ax,3
int     10h
mov     ah,09
mov     dx,offset message
int     21h
mov     ax,4c00h
int     21h
INCLUDE waitvrt.inc
end
