Erase_Message PROC
mov     di,[MessageWindow_StartPos]
mov     al,214
mov     ah,al
mov     cx,120
erase_horizontal:
push    cx
mov     cx,70
rep     stosw
pop     cx
add     di,180
loop    erase_horizontal
ret
Erase_Message ENDP

Erase_Prev_Char PROC
cmp     CharacterCount,0               ;is there any characters left to erase?
je      get_command                     ;nope, back to start
sub     CharacterPos,10                 ;calculate previous char pos.
mov     di,CharacterPos                 ;do it

mov     cx,20                           ;vertical loop counter
inner_looping:
push    cx
mov     cx,10
mov     al,15                           ;color=black
rep     stosb                           ;erase
add     di,310                          ;get to next position
pop     cx
loop    inner_looping
dec     si                              ;previous char in string (overwrite last one)
dec     CharacterCount                  ;guess :>
ret
Erase_Prev_Char ENDP

DisplayText PROC

call    Erase_Message
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

DisplayFontLetter PROC

push    si cx
cmp     al,' '
je      done_displaying
mov     ax,0a000h
mov     es,ax
lea     si,order                        ;"abcdef" etc...
mov     bx,0                            ;used to calc. startpos in fontdata
mov     Clipping,0                      ;used to calc. max. chars
mov     di,CharacterPos                 
get_font:
cmp     Clipping,38                     ;tried all the chars in order?
je      get_command                     ;if so then it's an illegal keypress
lodsb                                   ;load a byte from order
cmp     Character,al                    ;is it the same as the user's input?
je      display_it
add     bx,10                           ;if not, add 10 pixels (used to calc.
                                        ;the starting position in fontdata)
inc     Clipping                        
jmp     get_font
display_it:
lea     si,fontdata
add     si,bx                           ;this says which letter to display...
mov     cx,20                           ;number of vertical lines
horizontal:
push    cx                              ;save vertical loop counter
mov     cx,10                           ;number of horizontal pixels
do_load11:
lodsb
cmp     al,15
jnz     do_display1
inc     di
loop    do_load11
jmp     next2
do_display1:
stosb
loop    do_load11
next2:
add     di,310                  ;get to next startposition on screen (320-10)
add     si,310                  ;get to next startposition in fontdata (320-10)
pop     cx                              ;restore vertical loop counter
loop    horizontal

done_displaying:
add     CharacterPos,10                 ;calculates the startposition for next
                                        ;font-letter on screen.
pop     cx si                           ;restore string

ret
DisplayFontLetter ENDP

Draw_The_Sprite PROC

;NEEDS:
;SPRITEPOS    = WHERE TO START SPRITEDRAWING
;SI           = OFFSET SPRITE TO BE DRAWN
;SPRITEHEIGHT = NUMBER OF VERTICAL PIXELS PER LINE
;SPRITELENGTH = NUMBER OF HORIZONTAL PIXELS PER LINE

push    si
mov     ax,0a000h
mov     es,ax
mov     di,SpritePos
mov     cx,SpriteHeight
draw_horizontal:
push    cx
mov     ax,SpriteLength
shr     ax,1
mov     cx,ax
inner_loop:
lodsw
cmp     al,0
je      increment_di1
stosb
jmp     do_next_byte
increment_di1:
inc     di
cmp     ah,0
je      increment_di2
do_next_byte:
mov     al,ah
stosb
jmp     done
increment_di2:
inc     di
done:
loop    inner_loop
next:
mov     ax,320
sub     ax,SpriteLength
add     di,ax
pop     cx
loop    draw_horizontal
mov     di,CharacterPos
pop     si
ret

Draw_The_Sprite ENDP

Draw_Location_Line_By_Line PROC

;NEEDS:
;SPRITEPOS    = WHERE TO START SPRITEDRAWING
;SI           = OFFSET SPRITE TO BE DRAWN

push    si
mov     ax,0a000h
mov     es,ax
mov     di,SpritePos
mov     cx,120                          ;h0yden paa bildet
looploop:
push    cx
mov     cx,140                          ;lengden paa bildet
shr     cx,2
rep     movsd
add     di,320-140
call    waitvrt
pop     cx
loop    looploop
mov     di,CharacterPos
pop     si
ret

Draw_Location_Line_By_Line ENDP
