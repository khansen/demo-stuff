DOSSEG
.MODEL SMALL
.386
.STACK 100h
.data

order                   db 'abcdefghijklmnopqrstuvwxyz].,!?()- */":&',0
welcome                 db 'press to watch nice fire effect.$',0

fontfilename            db 'font.raw',0
INCLUDE                 fire.pal

MessageWindow_StartPos  dw 27900
CharacterPos            dw 0
CharacterCount          dw 0
Clipping                dw 0
Multiplier              dw 15
counter                 dw 40

fontdata                db 22400        dup (?)
array                   db 16000        dup (?)

.code

mov     ax,@data
mov     ds,ax
mov     ah,3Dh
xor     al,al
mov     dx,offset fontfilename
int     21h

mov     bx,ax
mov     ah,3Fh
mov     cx,22400
mov     dx,offset fontdata
int     21h

mov     ah,3Eh
int     21h

mov     ax,13h
int     10h

mov     ax,@data
mov     ds,ax
mov     es,ax
mov     dx,3c8h
xor     al,al
out     dx,al
inc     dx
mov     cx,768
lea     si,palette
rep     outsb

mov     ax,0a000h
mov     es,ax
xor     di,di

lea     si,welcome
call    displaytext

mov     ah,00
int     16h

prep:
mov     di,16000
mov     cx,16000
lea     si,array
main_loop:

mov     bl,byte ptr es:[di+320]
xor     bh,bh
shl     bx,4                                  ;gang den med 16  
mov     ax,bx
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
mov     byte ptr ds:[si],al
inc     di
inc     si
loop    main_loop

lea     si,array
mov     cx,4000
mov     di,16000
rep     movsd
dec     counter
jnz     prep

mov     ax,3
int     10h
mov     ax,4c00h
int     21h

DisplayText PROC

mov     ax,[MessageWindow_StartPos]
mov     CharacterPos,ax
add     CharacterPos,3
Prepare:
mov     Clipping,0
lea     di,order
lodsb                                           ;get byte from string
cmp     al,'$'                                  ;$ = string finished
je      Message_Done
cmp     al,'%'
jne     Find_Letter
push    ax
mov     ax,320
add     [multiplier],12
mul     [multiplier]
mov     CharacterPos,ax
pop     ax
add     CharacterPos,166
Find_Letter:
cmp     byte ptr [di],al
je      Disp_It
inc     di
add     Clipping,7
jmp     Find_Letter
Disp_It:
mov     ax,0a000h
mov     es,ax
push    si                                      ;save string position
lea     si,fontdata
add     si,320*20
skip_it_man:
add     si,Clipping
mov     cx,20                                   ;vertical lines
mov     di,CharacterPos                         ;where to disp letter
horiz:
push    cx                                      ;save vertical loop counter
mov     cx,7
do_load1:
lodsb
cmp     al,15                                   ;check if the pixel matches
je      do_display                              ;if not, display it
inc     di                                      ;else, increment di
loop    do_load1
jmp     next1
do_display:
mov     al,255
stosb
loop    do_load1
next1:
add     di,313                                  ;next disp-position
add     si,313                                  ;next line of the letter
pop     cx                                      ;restore vertical loop counter
loop    horiz
add     CharacterPos,7
pop     si                                      ;restore string
jmp     prepare                                 ;and do next letter
Message_Done:
mov     [multiplier],15
mov     CharacterCount,0

ret
DisplayText ENDP

end
