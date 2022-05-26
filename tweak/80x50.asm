DOSSEG
.MODEL SMALL
.STACK 100h
.data

_80x50          dw 04F01h
                dw 05002h
                dw 05504h
                dw 08105h
                dw 0BF06h
                dw 01F07h
                dw 04709h
                dw 09C10h
                dw 08E11h
                dw 08F12h
                dw 02813h
                dw 01F14h
                dw 09615h
                dw 0B916h
                dw 0A317h

.code

mov     ax,@data
mov     ds,ax
mov     es,ax

mov     ax,3h
int     10h

    mov     dx,3C4h          ; Sequencer Address Register

; === Set dot clock & scanning rate ===
    mov     ax,0100h
    out     dx,ax            ; Stop sequencer while setting Misc Output

    mov     dx,3C2h
    mov     al,63h          ; 0e3h = 227d = 11100011b
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
mov     ax,0204h
out     dx,ax
mov     ax,0101h
out     dx,ax
mov     ax,0003h
out     dx,ax

mov     dx,3CEh
mov     ax,1005h
out     dx,ax
mov     ax,0E06h
out     dx,ax

mov     dx,3D4h
mov     cx,15
mov     si,offset _80x50              ; CHANGE THIS TO _256x256 or _256x240
Send_Values:
lodsw
out     dx,ax
loop    Send_Values

mov     ax,0b800h
mov     es,ax
xor     di,di

mov     ax,1112h                ;<set 50 line mode if previous
mov     bl,0                    ;< by loading double dot chr set
int     10h

mov     ah,15
mov     cx,256
xor     al,al
loopert:
mov     dl,al
mov     ah,02
int     21h
;stosw
inc     al
loop    loopert
mov     ah,00
int     16h

;mov     ax,3
;int     10h

mov     ax,4c00h
int     21h
end
