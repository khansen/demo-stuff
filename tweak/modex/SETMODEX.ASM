ideal
p386n
model flat
stack 1000h

SC_INDEX        equ     03c4h   ;Sequence Controller Index
CRTC_INDEX      equ     03d4h   ;CRT Controller Index
MISC_OUTPUT     equ     03c2h   ;Miscellaneous Output register

dataseg

CRTParms        dw      00d06h  ;vertical total
                dw      03e07h  ;overflow (bit 8 of vertical counts)
                dw      04109h  ;cell height (2 to double-scan)
                dw      0ea10h  ;v sync start
                dw      0ac11h  ;v sync end and protect cr0-cr7
                dw      0df12h  ;vertical displayed
                dw      00014h  ;turn off dword mode
                dw      0e715h  ;v blank start
                dw      00616h  ;v blank end
                dw      0e317h  ;turn on byte mode

videomem        dd      ?

codeseg

start:
mov     ax,0ee02h
int     31h
mov     eax,0A0000h
sub     eax,ebx
mov     [videomem],eax

call    _Set320x240Mode
mov     edi,[videomem]
call    _writepixelx
call    _writepixelx
call    _writepixelx
call    _writepixelx
mov     ah,00
int     16h

mov     ax,3
int     10h
mov     ax,4c00h
int     21h

proc    _Set320x240Mode near

        mov     ax,13h  ;let the BIOS set standard 256-color
        int     10h     ; mode (320x200 linear)

        mov     dx,SC_INDEX
        mov     ax,0604h
        out     dx,ax   ;disable chain4 mode
        mov     ax,0100h
        out     dx,ax   ;synchronous reset while switching clocks

        mov     dx,MISC_OUTPUT
        mov     al,0e7h
        out     dx,al   ;select 28 MHz dot clock & 60 Hz scanning rate

        mov     dx,SC_INDEX
        mov     ax,0300h
        out     dx,ax   ;undo reset (restart sequencer)

        mov     dx,CRTC_INDEX ;reprogram the CRT Controller
        mov     al,11h  ;VSync End reg contains register write
        out     dx,al   ; protect bit
        inc     dx      ;CRT Controller Data register
        in      al,dx   ;get current VSync End register setting
        and     al,7fh  ;remove write protect on various
        out     dx,al   ; CRTC registers
        dec     dx      ;CRT Controller Index
        cld
        mov     esi,offset CRTParms ;point to CRT parameter table
        mov     ecx,10 ;# of table entries
SetCRTParmsLoop:
        lodsw           ;get the next CRT Index/Data pair
        out     dx,ax   ;set the next CRT Index/Data pair
        loop    SetCRTParmsLoop

        mov     dx,SC_INDEX
        mov     ax,0f02h
        out     dx,ax   ;enable writes to all four planes
        mov     edi,[videomem]
        sub     ax,ax   ;clear to zero-value pixels
        mov     cx,8000h ;# of words in display memory
        rep     stosw   ;clear all of display memory

        ret
endp    _Set320x240Mode

proc    _WritePixelX near

        mov     ax,0102h
        mov     dx,SC_INDEX ;set the Map Mask to enable only the
        out     dx,ax       ; pixel's plane

        mov     al,15
        stosb
        ret
endp    _WritePixelX

end     start
