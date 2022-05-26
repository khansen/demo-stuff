Base_Address            dw 210h

RESET_PORT              EQU 06h
READ_DATA_PORT          EQU 0Ah
WRITE_DATA_PORT         EQU 0Ch
DATA_AVAILABLE_PORT     EQU 0Eh

no_sbcard       db 'Sorry, could not initialize Sound Blaster compatible card.',13,10

PROC    ResetDSP

@@10:

;write a 1 to the RESET PORT (2x6h)

mov     dx,[Base_Address]
add     dx,RESET_PORT
mov     al,1
out     dx,al
mov     cx,6
call    Delay                                   ;wait for 3.3 microseconds

;write a 0 to the RESET PORT (2x6h)

xor     al,al
out     dx,al
mov     cx,6
call    Delay                                   ;wait for 3.3 microseconds

;read the byte from the DATA AVAILABLE PORT (2xEh) until bit 7 = 1.

mov     dx,[Base_Address]
add     dx,DATA_AVAILABLE_PORT
waitbit:
in      al,dx
and     al,10000000b
jz      waitbit

;poll for a ready byte (AAh) from the READ DATA PORT (2xAh)

mov     dx,[Base_Address]
add     dx,READ_DATA_PORT
mov     bx,400
wait_for_ready_byte:
in      al,dx
cmp     al,0AAh
je      init_OK
dec     bx
jnz     wait_for_ready_byte

add     [Base_Address],10h
cmp     [Base_Address],260h             ; tried all base addresses yet?
jbe     @@10

mov     ah,09
mov     edx,offset no_sbcard
int     21h
jmp     terminate

;DSP is now resetted

init_OK:

xor     al,al
out     21h,al

;       - Turn on speaker

mov     bl,0D1h
call    WriteDSP

@@20:
ret
ENDP    ResetDSP

PROC    Delay
push    dx
mov     dx,0388h
@@10:
in      al,dx
loop    @@10
pop     dx
ret
ENDP    Delay

PROC    WriteDSP

;needs: BL = value to write

push    dx
mov     dx,[Base_Address]               ; 2x0h, x = 1...6
add     dx,WRITE_DATA_PORT              ; DX = 2xCh
@@10:
in      al,dx                           ; read port
and     al,10000000b                    ; until bit 7 = 0
jnz     @@10
mov     al,bl
out     dx,al
pop     dx
ret
ENDP    WriteDSP

PROC    SetUpDMA

pushad

;      - Send value 05h to port 0Ah (mask off channel 1)
;      - Send value 00h to port 0Ch (clear the internal DMA flip/flop)
;      - Send value 49h to port 0Bh (playback) or
;                   45h to port 0Bh (recording)

mov     al,05h
out     0Ah,al
xor     al,al
out     0Ch,al
mov     al,59h
out     0Bh,al

;      - Write LSB (bits 0 - 7) of the 20 bit memory address to port 02h
;      - Write MSB (bits 8 - 15) of the 20 bit memory address to port 02h
;      - Write Page (bits 16 -> 19) of the 20 bit memory address to port 83h

mov     ax,0000h
out     02h,al
mov     al,ah
out     02h,al
mov     al,08h
out     83h,al

;      - Send LSB of DATA_LENGTH to port 03h
;      - Send MSB of DATA_LENGTH to port 03h
;      - Send value 01h to port 0Ah (enable channel 1)

mov     ax,[mix_length]
movzx   bx,[speed]
mul     bx
push    ax
shl     ax,1
dec     ax
out     03h,al
mov     al,ah
out     03h,al
mov     al,01h
out     0Ah,al

mov     bl,48h
call    WriteDSP

pop     ax
dec     ax
mov     bl,al
call    WriteDSP
mov     bl,ah
call    WriteDSP

;       - Set frequency (40h followed by time constant)

mov     bl,40h
call    WriteDSP
mov     bl,0D3h
call    WriteDSP

;       - 1Ch = 8-bit sample

mov     bl,1Ch
call    WriteDSP

popad
ret
ENDP    SetUpDMA

PROC    ShutDownSB

pushad

mov     bl,0D0h
call    WriteDSP
mov     bl,0D3h
call    WriteDSP

popad
ret
ENDP    ShutDownSB
