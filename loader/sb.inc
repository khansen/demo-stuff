Init_SB PROC

push    es

find_port:

mov     ax,PortAdr

;calculate port values

add     Reset_Port,ax
add     Read_Data_Port,ax
add     Write_Data_Port,ax
add     Data_Available_Port,ax

;=========== reset the DSP ===================================================

;write a 1 to the RESET PORT (2x6h)

mov     dx,Reset_Port
mov     al,1
out     dx,al
push    dx
mov     dx,0388h
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
pop     dx

;write a 0 to the RESET PORT (2x6h)

xor     al,al
out     dx,al
push    dx
mov     dx,0388h
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
in      al,dx
pop     dx

;read the byte from the DATA AVAILABLE PORT (2xEh) until bit 7 = 1.

mov     dx,Data_Available_Port
waitbit:
in      al,dx
and     al,10000000b
cmp     al,10000000b
jnz     waitbit

;poll for a ready byte (AAh) from the READ DATA PORT (2xAh)

mov     dx,Read_Data_Port
mov     bx,500
wait_for_ready_byte:
in      al,dx
cmp     al,0AAh
je      init_OK
dec     bx
jnz     wait_for_ready_byte

dec     MaxPorts
jnz     find_port

mov     edx,offset init_ERROR
mov     ah,09
int     21h
mov     ax,4c00h
int     21h

;DSP is now resetted

init_OK:

;========== turn on speaker ==================================================

;Turn On Speaker (TOS)

mov     Value,0D1h
call    WriteDSP

pop     es
assume  es:@data
ret
Init_SB ENDP
