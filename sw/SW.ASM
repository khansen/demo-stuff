DOSSEG
.MODEL SMALL
.386
.STACK 100h
JUMPS
.data

picfile db 'kis2.raw',0
palfile db 'kis2.pal',0
count   dw 0
X       dw 0
Y       dw 0
Y1      dw 0
Dist    dw 0
picture db 48000 dup (?)
palette db 768   dup (?)

.code

mov     ax,@data
mov     ds,ax
mov     es,ax
mov     ah,3Dh
xor     al,al
mov     dx,offset picfile
int     21h
mov     bx,ax
mov     ah,3Fh
mov     cx,48000
mov     dx,offset picture
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

mov     ax,0a000h
mov     es,ax

;   ScreenX := ((X * 256) / Z) + 160
;   ScreenY := ((Y * 256) / Z) + 100

mainloop:
mov     Dist,456
mov     Y,0
lea     si,picture
add     si,count
ResetX:
mov     X,0
mov     cx,160
mov     bx,Dist
Xloop:
mov     ax,X
shl     ax,8
xor     dx,dx
div     bx
mov     di,ax
add     di,Y1
movsw
add     X,2
loop    Xloop
inc     Y
mov     ax,Y
shl     ax,8
xor     dx,dx
div     bx
mov     dx,ax
shl     ax,8
shl     dx,6
add     ax,dx
mov     Y1,ax
dec     Dist
cmp     Dist,256
jnz     skip_it
mov     Dist,512
skip_it:
cmp     Y,150
jnz     ResetX
call    waitvrt
add     count,320
in      al,60h
dec     al
jnz     mainloop

mov     ax,3
int     10h
mov     ax,4c00h
int     21h
INCLUDE waitvrt.inc
end
