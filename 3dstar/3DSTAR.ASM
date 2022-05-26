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
Xcentre         dw 160
Ycentre         dw 100
NumStars        EQU 160
Zvariables      dw NumStars dup (255)
INCLUDE         fire.pal
OldPos          dw NumStars dup (?)

.code
jmp     start

CalculateCoords MACRO

push    si
lea     si,Zvariables
add     si,StarCount
add     si,StarCount
lodsw
mov     z,ax
mov     StarCol,255
sub     StarCol,al
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
mov     es,ax
mov     cx,NumStars
lea     si,StarCoordsY
lea     di,StarCoordsX
xor     bp,bp
mov     StarCount,0
MAIN_LOOP:
CalculateCoords
add     di,2
push    es di
lea     di,OldPos
add     di,bp
add     bp,2
mov     ax,StarPos
mov     word ptr [di],ax
mov     di,ax
mov     ax,0a000h
mov     es,ax
mov     al,StarCol
mov     byte ptr es:[di],al
pop     di es
inc     StarCount
loop    main_loop

call    waitvrt

mov     ax,0a000h
mov     es,ax

lea     si,OldPos
mov     cx,NumStars
erase_loop:
lodsw
mov     di,ax
mov     byte ptr es:[di],0
loop    erase_loop

ready_Zvalues:
lea     si,Zvariables
mov     cx,NumStars
update_loop1:
sub     word ptr [si],2
cmp     word ptr [si],0
je      exit
add     si,2
loop    update_loop1

in      al,60h
cmp     al,1
je      exit

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
