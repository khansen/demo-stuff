DoPic   MACRO
mov     ax,0a000h
mov     es,ax
mov     di,0
lea     si,pic
mov     cx,64000
rep     movsb
ENDM


Ready_Palette MACRO
call    waitvrt
mov     ax,cs
mov     ds,ax
mov     es,ax
mov     dx,3c8h
xor     al,al
out     dx,al
lea     di,pal
lea     si,pal
inc     dx
mov     cx,768
ENDM

;=============================================================================
;
;                      "Fade Out" (c) 1997 Kent Hansen / TbK
;
; SIMPLE routine to fade the screen to black... it doesn't get any easier than
; this, so if you can't figure it out, then perhaps ASM is not for you... :)
;
;=============================================================================

Fade_Out PROC

mov     bx,63                   ;to guarantee that all colors are faded:
                                ;it will take 63 loops to fade total white
                                ;to total black.

decpalcolors1:

ready_palette                   ;set up the palette, see macro above

get_b:
lodsb                           ;load a byte from the palette (located at si)
                                ;into al
cmp     al,0                    ;check if it is 0 (black)
je      out_it                  ;if it is, then out it to the write register
dec     al                      ;otherwise, decrease the value => fade color
out_it:
mov     byte ptr [di],al        ;first, save the colorvalue from al into di
inc     di                      ;get to next cell: next color-value
out     dx,al                   ;send value to register
loop    get_b                   ;and loop this 256*3=768 times

dec     bx                      ;decrement bx to see if we have looped the
                                ;fading 63 times: the maximum value a color
                                ;can have is 63

jnz     Decpalcolors1           ;if not, continue 
ret
Fade_Out ENDP                   ;AND THAT'S IT!!!

;=============================================================================
;
; That was the cool fade-out procedure... and here is a procedure to fade a
; picture from its original colors to total white! If you understood the Fade-
; Out procedure then you should be able to figure this one out by yourself...
; only two lines have to be modified =:)
;
;=============================================================================

Fade_In    PROC

mov     bx,63

decpalcolors:
ready_palette
get_b1:
lodsb
cmp     al,63                           ;check if value = 63 = white
je      out_it1
inc     al                              ;if not, then increase it!
out_it1:
mov     byte ptr [di],al
inc     di
out     dx,al
loop    get_b1

dec     bx
jnz     Decpalcolors
ret
Fade_In    ENDP

;=============================================================================
;
; We'll finish it all off by doing a simple procedure which fades the screen       
; from black to the picture's original colors:
;
;=============================================================================

FadeToOriginalColors PROC

BLACK_SCREEN:
mov     ax,cs
mov     ds,ax
mov     es,ax
mov     dx,3c8h
xor     al,al
out     dx,al
inc     dx
mov     cx,768
looping:
out     dx,al
loop    looping

dopic

mov     bx,63
fader:
call    waitvrt
mov     ax,cs
mov     ds,ax
mov     es,ax
mov     dx,3c8h
xor     al,al
out     dx,al
lea     si,pal
lea     di,pal2
inc     dx
mov     cx,768
get_byte:
lodsb
cmp     byte ptr [di],al
je      out_byte
inc     byte ptr [di]
mov     al,byte ptr [di]
out_byte:
inc     di
out     dx,al
loop    get_byte
dec     bx
jnz     fader
ret
FadeToOriginalColors ENDP


