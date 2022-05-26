PROC    Write_Adlib

; AL = register
; AH = data

mov     dx,ADDRESS_PORT
out     dx,al
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
mov     dx,DATA_PORT
mov     al,ah
out     dx,al
dec     dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
ret
ENDP    Write_Adlib

PROC    Reset_Adlib

mov     bl,1
@@10:
mov     al,bl
xor     ah,ah
call    Write_Adlib
inc     bl
cmp     bl,244
jnz     @@10

ret
ENDP    Reset_Adlib

MACRO   ReadStatus
mov     dx,ADDRESS_PORT
in      al,dx                   ; read status
ENDM

PROC    Detect_Adlib

; checks if an Adlib-compatible board is installed in the computer

; Output: CL = 0 Adlib found
;              1 Adlib not found

mov     ax,6004h
call    Write_Adlib                ; reset both timers

mov     ax,8004h
call    Write_Adlib                ; enable the interrupts

ReadStatus
mov     bl,al                   ; store result

mov     ax,0FF02h
call    Write_Adlib

mov     ax,2104h
call    Write_Adlib                ; start Timer 1

xor     ax,ax
wait_loop:
dec     ax
jnz     wait_loop

ReadStatus
mov     bh,al                   ; store result

mov     ax,6004h
call    Write_Adlib                ; reset both timers

mov     ax,8004h
call    Write_Adlib                ; enable the interrupts

xor     cl,cl
and     bl,0E0h
jz      @@10
mov     cl,1
@@10:
and     bh,0E0h
cmp     bh,0C0h
jz      @@20
mov     cl,1
@@20:
ret
ENDP    Detect_Adlib
