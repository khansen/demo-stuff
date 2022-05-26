DOSSEG
MODEL SMALL
STACK 100h
jumps

NumChars        EQU 0080h
FirstChar       EQU 0082h

dataseg

Message         db 13,10,' PCX to RAW converter by Kent Hansen',13,10,' Usage: Pcx2Raw [Filename.PCX]',13,10,'$'
file_error      db 13,10,' ERROR: File not found!',13,10,'$'
picture         db 64200 dup (?)
palette         db 768 dup (?)
NumPixels       dw ?
commandtail     db 128 dup (?)
Xmax            dw ?
Ymax            dw ?

codeseg

push    ds

mov     ax,@data
mov     ds,ax

mov     ah,09
mov     dx,offset message
int     21h

pop     ds

mov     ax,@data
mov     es,ax

mov     cl,[ds:numchars]
jcxz    exit
mov     si,offset [ds:firstchar]
mov     di,offset commandtail
xor     ch,ch
push    cx
rep     movsb

mov     ax,@data
mov     ds,ax

mov     si,offset commandtail
pop     cx
rep     lodsb
dec     si
mov     byte ptr [si],0

mov     ah,3Dh
xor     al,al
mov     dx,offset commandtail
int     21h
jnc     file_ok

mov     ah,09
mov     dx,offset file_error
int     21h
jmp     exit

file_ok:

mov     bx,ax
mov     ah,3Fh
mov     cx,64000
mov     dx,offset picture
int     21h

mov     ax,13h
int     10h

mov     dx,3c8h
xor     al,al
out     dx,al
mov     cx,768
inc     dx
black_pal:
out     dx,al
loop    black_pal

mov     ax,0a000h
mov     es,ax
xor     di,di

mov     si,offset picture
add     si,8
lodsw
inc     ax
mov     Xmax,ax
mov     bx,ax
lodsw
inc     ax
mov     Ymax,ax
mul     bx
mov     [NumPixels],ax

;     Offset  Item          Type      Description comment.
;     ------  ------------  --------  -----------------------------------
;     4       XMin          Word      \  Image dimensions.
;     6       YMin          Word       \ XMin and YMin are usually 0
;     8       XMax          Word       / but in the PCC (PCX Blocks) the
;     10      YMax          Word      /  value is actualy the screen
;                                        coordinates from which the block
;                                        was taken.
;                                        Since counting normally starts
;                                        at 0, XMax and YMax will have
;                                        one less than the number of
;                                        pixels per colum/row.

;--- display .PCX file, set pal

mov     si,offset picture + 128
xor     dx,dx
xor     ah,ah
mov     bx,Xmax
displaybytes:
lodsb
push    ax
and     al,11000000b
cmp     al,11000000b
jne     Display_It
pop     ax
and     al,00111111b
mov     cx,ax
add     dx,cx
lodsb
loopis:
stosb
dec     bx
jnz     ostepop
add     di,320
sub     di,Xmax
mov     bx,[Xmax]
ostepop:
loop    loopis
jmp     check
Display_It:
pop     ax
stosb
inc     dx
dec     bx
check:
cmp     bx,0
jnz     skippert
add     di,320
sub     di,Xmax
mov     bx,[Xmax]
skippert:
cmp     dx,[NumPixels]
jnz     DisplayBytes

inc     si                              ;skip this byte
mov     dx,3c8h
xor     al,al
out     dx,al
inc     dx
mov     cx,768
xor     bx,bx
pal_loop:
lodsb
shr     al,2
out     dx,al
mov     palette[bx],al
inc     bx
loop    pal_loop

mov     si,offset picture
xor     di,di
mov     cx,Ymax
store_loop:
push    cx
mov     cx,Xmax
do_it:
mov     al,byte ptr es:[di]
mov     byte ptr [si],al
inc     di
inc     si
loop    do_it
add     di,320
sub     di,Xmax
pop     cx
loop    store_loop

mov     si,offset commandtail
loopert:
lodsb
cmp     al,'.'
jnz     loopert
mov     word ptr [si],'AR'
mov     byte ptr [si+2],'W'

mov     ah,3Ch
xor     cx,cx
mov     dx,offset commandtail
int     21h

mov     ah,3Dh
mov     al,2
mov     dx,offset commandtail
int     21h
mov     bx,ax

mov     ah,40h
mov     cx,NumPixels
mov     dx,offset picture
int     21h
mov     ah,3Eh
int     21h

mov     si,offset commandtail
loopert2:
lodsb
cmp     al,'.'
jnz     loopert2
mov     word ptr [si],'AP'
mov     byte ptr [si+2],'L'

mov     ah,3Ch
xor     cx,cx
mov     dx,offset commandtail
int     21h
mov     ah,3Dh
mov     al,2
mov     dx,offset commandtail
int     21h
mov     bx,ax
mov     ah,40h
mov     cx,768
mov     dx,offset palette
int     21h

mov     ah,00
int     16h

mov     ax,3
int     10h

exit:
mov     ax,4c00h
int     21h

end
