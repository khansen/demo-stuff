DOSSEG
.MODEL SMALL
.STACK 100h
.data

_256x224        dw 03F01h
                dw 04002h
                dw 04A04h
                dw 09A05h
                dw 00B06h
                dw 03E07h
                dw 04109h
                dw 0DA10h
                dw 09C11h
                dw 0BF12h
                dw 02013h
                dw 04014h
                dw 0C715h
                dw 00416h
                dw 0E317h

_256x240        dw 03F01h
                dw 04002h
                dw 04E04h
                dw 09605h
                dw 00D06h
                dw 03E07h
                dw 04109h
                dw 0EA10h
                dw 0AC11h
                dw 0DF12h
                dw 02013h
                dw 04014h
                dw 0E715h
                dw 00616h
                dw 0E317h

_256x256        dw 03F01h
                dw 04002h
                dw 04A04h
                dw 09A05h
                dw 02306h
                dw 0B207h
                dw 06109h
                dw 00A10h
                dw 0AC11h
                dw 0FF12h
                dw 02013h
                dw 04014h
                dw 00715h
                dw 01A16h
                dw 0A317h

_320x400        dw 04F01h
                dw 05002h
                dw 05404h
                dw 08005h
                dw 0BF06h
                dw 01F07h
                dw 04009h
                dw 09C10h
                dw 08E11h
                dw 08F12h
                dw 02813h
                dw 00014h
                dw 09615h
                dw 0B916h
                dw 0E317h

.code

mov     ax,@data
mov     ds,ax
mov     es,ax

mov     ax,13h
int     10h

    mov     dx,3C4h          ; Sequencer Address Register

; === Set dot clock & scanning rate ===
    mov     ax,0100h
    out     dx,ax            ; Stop sequencer while setting Misc Output

    mov     dx,3C2h
    mov     al,0e3h          ; 0e3h = 227d = 11100011b
    out     dx,al            ; Select 25 MHz dot clock & 60 Hz scanning rate

    mov     dx,3C4h
    mov     ax,0300h         ; Index 00h --- 03h = 3d = 00000011b
    out     dx,ax            ; Undo reset (restart sequencer)

; === Remove write protection ===
    mov     dx,3D4h
    mov     al,11h           ; VSync End contains write protect bit (bit 7)
    out     dx,al
    inc     dx               ; Crt Controller Data register
    in      al,dx
    and     al,01111111b     ; Remove write protect on various CrtC registers
    out     dx,al            ; (bit 7 is 0)

mov     dx,3C4h
mov     ax,0E04h
out     dx,ax
 
mov     dx,3D4h
mov     cx,15
mov     si,offset _320x400   ; CHANGE THIS TO _256x256 or _256x240
Send_Values:
lodsw
out     dx,ax
loop    Send_Values

mov     ax,0a000h
mov     es,ax
xor     di,di

mov     bx,15
mov     ax,0101h
draw_loop:
mov     cx,(256*17)/2
rep     stosw
inc     ah
inc     al
dec     bx
jnz     draw_loop

mov     ah,00
int     16h

mov     ax,3
int     10h

mov     ax,4c00h
int     21h
end
