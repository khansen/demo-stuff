DOSSEG
.MODEL SMALL
.386
.STACK 100h
jumps
.data
message         db 'Coded in 100% (t)ASM by Kent Hansen',13,10,'19(c)97',13,10,'$'
INCLUDE         randstar.inc
StarPos         dw 0
StarCount       dw 0
StarCol         db 15
Z               dw 0
EraseFlag       db 1
Xcentre         dw 160
Ycentre         dw 100
NumStars        EQU 160
Zvariables      dw NumStars dup (255)
INCLUDE         fire.pal
BufferStuff     dw 0040h

.code
jmp     start

ClearKbBuffer MACRO
push    ds ax
mov     ds,bufferstuff
mov     ax,ds:[01ch]            ;sett tail og head equal
mov     ds:[01ah],ax
pop     ax ds
ENDM

CalculateCoords MACRO

push    si
lea     si,Zvariables
add     si,StarCount
add     si,StarCount
lodsw
mov     z,ax
cmp     EraseFlag,1
jne     skip_color_set
xor     ah,ah
mov     StarCol,255
sub     StarCol,al
skip_color_set:
pop     si

;Ycoord
lodsw
movsx   dx,ah
shl     ax,8
mov     bx,z
idiv    bx
add     ax,Ycentre
cmp     ax,200
jae     Terminate
mov     dx,ax
shl     ax,8
shl     dx,6
add     ax,dx
mov     StarPos,ax

;Xcoord
mov     ax,word ptr [di]
movsx   dx,ah
shl     ax,8
mov     bx,z
idiv    bx
add     ax,Xcentre
cmp     ax,320
jae     Terminate
add     StarPos,ax

ENDM

START:
mov     ax,13h
int     10h
mov     ax,@data
mov     ds,ax
mov     es,ax
mov     dx,3c8h
xor     al,al
out     dx,al
lea     si,palette
inc     dx
mov     cx,768
rep     outsb

PREPARE:
mov     ax,@data
mov     ds,ax
mov     es,ax
mov     cx,NumStars
lea     si,StarCoordsY
lea     di,StarCoordsX
mov     StarCount,0
MAIN_LOOP:
CalculateCoords
add     di,2
push    di
mov     ax,0a000h
mov     es,ax
mov     di,StarPos
mov     al,StarCol
stosb
pop     di
inc     StarCount
loop    main_loop

cmp     EraseFlag,0
jne     erase

ready_Zvalues:
mov     ax,@data
mov     ds,ax
lea     si,Zvariables
mov     cx,NumStars
update_loop1:
dec     word ptr [si]
dec     word ptr [si]
cmp     word ptr [si],0
je      exit
add     si,2
loop    update_loop1

mov     EraseFlag,1
in      al,60h
cmp     al,4Bh
je      left
cmp     al,4Dh
je      right
cmp     al,48h
je      up
cmp     al,50h
je      down
jmp     prepare
right:
inc     Xcentre
lea     si,StarCoordsX
mov     cx,NumStars
loopert1:
dec     word ptr [si]
add     si,2
loop    loopert1
ClearKbBuffer
jmp     Prepare
left:
dec     Xcentre
lea     si,StarCoordsX
mov     cx,NumStars
loopert:
inc     word ptr [si]
add     si,2
loop    loopert
ClearKbBuffer
jmp     Prepare
up:
inc     Ycentre
lea     si,StarCoordsY
mov     cx,NumStars
loopert2:
dec     word ptr [si]
add     si,2
loop    loopert2
ClearKbBuffer
jmp     Prepare
down:
dec     Ycentre
lea     si,StarCoordsY
mov     cx,NumStars
loopert3:
inc     word ptr [si]
add     si,2
loop    loopert3
ClearKbBuffer
jmp     Prepare

erase:
mov     EraseFlag,0
mov     StarCol,0

in      al,60h
cmp     al,1
je      exit

call    waitvrt
jmp     Prepare

Terminate:
push    si
lea     si,Zvariables
add     si,StarCount
add     si,StarCount
mov     word ptr [si],255
pop     si

sub     si,2
jmp     main_loop

exit:
mov     ax,3
int     10h
mov     dx,offset message
mov     ah,09
int     21h
mov     ax,4c00h
int     21h
INCLUDE waitvrt.inc
end
