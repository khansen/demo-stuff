PROC    DMA_out

;      - Send value 05h to port 0Ah (mask off channel 1)
;      - Send value 00h to port 0Ch (clear the internal DMA flip/flop)
;      - Send value 49h to port 0Bh (playback) or
;                   45h to port 0Bh (recording)

mov     al,05h
out     0Ah,al
xor     al,al
out     0Ch,al
mov     al,49h
out     0Bh,al

;      - Write LSB (bits 0 - 7) of the 20 bit memory address to port 02h
;      - Write MSB (bits 8 - 15) of the 20 bit memory address to port 02h
;      - Write Page (bits 16 -> 19) of the 20 bit memory address to port 83h

mov     ax,[DMAinfo.__offset]
out     02h,al
mov     al,ah
out     02h,al
mov     al,[DMAinfo._page]
out     83h,al

;      - Send LSB of DATA_LENGTH to port 03h
;      - Send MSB of DATA_LENGTH to port 03h
;      - Send value 01h to port 0Ah (enable channel 1)

mov     ax,[DMAinfo._length]
out     03h,al
mov     al,ah
out     03h,al
mov     al,01h
out     0Ah,al

;       - 14h = 8-bit sample

mov     Value,14h
call    WriteDSP

;       - Write data length - 1 to the DSP (low byte first)

mov     ax,[DMAinfo._length]
dec     ax
mov     Value,al
call    WriteDSP
mov     Value,ah
call    WriteDSP
ret
ENDP    DMA_out

    컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
    ; IN: DX:AX = segment/offset address of memory area
    ;
    ;OUT: DH = Page (0-F)  (DL is destroyed)
    ;     AX = Offset
    컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
PROC    MakePage
    push    bx

    mov     bl,dh
    shr     bl,4    ;isolate upper 4 bits of segment

    shl     dx,4    ;make segment into ABS address
    add     ax,dx   ;add the offset and put it in AX
    adc     bl,0    ;complete the addition

    mov     dh,bl   ;put the PAGE where it goes

mov     [DMAinfo._Page],dh
mov     [DMAinfo.__Offset],ax

    pop     bx      ; DH:AX is now the PAGE:OFFSET address
    ret
ENDP    MakePage

PROC    Delay
push    dx
mov     dx,0388h
Delay_Loop:
in      al,dx
loop    Delay_Loop
pop     dx
ret
ENDP    Delay

PROC    ReadDSP

;returns: AL = value from card

mov     dx,Data_Available_Port
wait_for_set_bit:
in      al,dx
and     al,10000000b
cmp     al,10000000b
jnz     wait_for_set_bit
mov     dx,Read_Data_Port
in      al,dx
ret
ENDP    ReadDSP

PROC    WriteDSP

;needs: VALUE = value to write

mov     dx,Write_Data_Port
waitwrite:
in      al,dx
and     al,10000000b
jnz     waitwrite
mov     al,Value
out     dx,al
ret
ENDP    WriteDSP
