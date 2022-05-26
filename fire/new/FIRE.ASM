DOSSEG
.MODEL SMALL
.STACK 100h
.386
JUMPS
.DATA

palfile         db '00000002.pal',0

INCLUDE         rand.lst
Message         db 'Fire effect by Kent Hansen',13,10,'19(c)97$'
RandCount       dw 0
Var             db 0
palette         db 768 dup (?)
array           db 48000 dup (?)

;Optimiza for speeden sin skyld! (hva ellers? 8-))
;derfor rimelig kryptisk

.CODE

mov     ax,13h
int     10h
mov     ax,@data
mov     ds,ax
mov     es,ax

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

lea     di,array
mov     cx,24000
mov     ah,180
mov     al,ah
rep     stosw

mov     dx,3c8h
xor     al,al
out     dx,al
inc     dx
mov     cx,768
lea     si,palette
rep     outsb

lea     di,array
add     di,47680                              ;nest nederst
mov     cx,160                                ;tegn ei gul linje helt nederst
mov     al,250                                ;(henter fargeverdier derfra)
mov     ah,al
rep     stosw

prepare:
lea     di,array
add     di,47360                              ;nest nederst
lea     si,rand                               ;tegn "random" pixels
add     si,RandCount
mov     cx,320                                 ;80 * 4 = 320 pixels
randloop:
mov     al,byte ptr [si]
mov     byte ptr [di],al
inc     di
mov     al,Var
add     byte ptr [si],al
inc     si
loop    randloop

lea     di,array
mov     cx,47360
lea     si,array
main_loop:

;pixel som kalkuleres = ((16*A)+(14*C)+B+D) / 32
;hvor Pixel A = pixel+320, B = Pixel+639, C = Pixel+640, D = Pixel+641
;
;       # <-- Pixel som kalkuleres
;       A
;      BCD
;

mov     al,byte ptr es:[di+320]
xor     ah,ah
shl     ax,4                                  ;gang den med 16  
mov     bl,byte ptr es:[di+639]
xor     bh,bh
add     ax,bx                                 ;addes vanlig (pixel B)
mov     bl,byte ptr es:[di+641]
add     ax,bx                                 ;addes vanlig (pixel D)
mov     bl,byte ptr es:[di+640]
mov     dl,bl
xor     dh,dh
shl     bx,4                                  ;gang med 16
shl     dx,1                                  ;gang med 2
sub     bx,dx                               ;PixelC*16 - PixelC*2 = PixelC*14
add     ax,bx
shr     ax,5                                  ;skal deles med 32
dec     al

mov     byte ptr [si],al
inc     di
inc     si
loop    main_loop

push    es
mov     ax,0a000h
mov     es,ax
lea     si,array
mov     cx,11840                               ;31360 / 4
mov     di,16000
rep     movsd
pop     es

in      al,60h
cmp     al,1
je      exit
;call    waitvrt
inc     RandCount
cmp     RandCount,319
jnz     continue
mov     RandCount,0
continue:
add     Var,200
jmp     prepare

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
