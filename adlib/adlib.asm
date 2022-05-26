DOSSEG
.MODEL SMALL
.STACK 100h

Address_Port    EQU     0388h
Data_Port       EQU     0389h

.data

Value           db ?
Register        db ?

.code

mov     ax,@data
mov     ds,ax

mov     bx,244
mov     Register,01
reset_regs:
mov     al,Register
call    WriteReg
mov     Value,0
call    WriteData
inc     Register
dec     bx
jnz     reset_regs

; |     REGISTER     VALUE     DESCRIPTION
; |        20          01      Set the modulator's multiple to 1
; |        40          10      Set the modulator's level to about 40 dB
; |        60          F0      Modulator attack:  quick;   decay:   long
; |        80          77      Modulator sustain: medium;  release: medium
; |        A0          98      Set voice frequency's LSB (it'll be a D#)
; |        23          01      Set the carrier's multiple to 1
; |        43          00      Set the carrier to maximum volume (about 47 dB)
; |        63          F0      Carrier attack:  quick;   decay:   long
; |        83          77      Carrier sustain: medium;  release: medium
; |        B0          31      Turn the voice on; set the octave and freq MSB

mov     Register,20h
call    WriteReg
mov     Value,01
call    WriteData

mov     Register,40h
call    WriteReg
mov     Value,10h
call    WriteData

mov     Register,60h
call    WriteReg
mov     Value,0Fh
call    WriteData

mov     Register,80h
call    WriteReg
mov     Value,77h
call    WriteData

mov     Register,0A0h
call    WriteReg
mov     Value,98h
call    WriteData

mov     Register,23h
call    WriteReg
mov     Value,01
call    WriteData

mov     Register,43h
call    WriteReg
mov     Value,0
call    WriteData

mov     Register,63h
call    WriteReg
mov     Value,0F0h
call    WriteData

mov     Register,83h
call    WriteReg
mov     Value,77h
call    WriteData

mov     Register,0B0h
call    WriteReg
mov     Value,31h
call    WriteData

waitkey:
mov     ah,00
int     16h
cmp     al,27
je      exit
sub     al,"0"
cmp     al,1
jl      waitkey
cmp     al,9
ja      waitkey
mov     bl,28
mul     bl
mov     Value,al
mov     Register,0A0h
call    WriteReg
call    WriteData
jmp     waitkey

exit:
mov     Register,0B0h
call    WriteReg
mov     Value,11h
call    WriteData

mov     ax,4c00h
int     21h

Delay   PROC
mov     dx,Address_Port
delay_loop:
in      al,dx
loop    delay_loop
ret
Delay   ENDP

WriteReg  PROC
mov     dx,Address_Port
mov     al,Register
out     dx,al
mov     cx,6
call    Delay
ret
WriteReg  ENDP

WriteData PROC
mov     dx,Data_Port
mov     al,Value
out     dx,al
mov     cx,35
call    Delay
ret
WriteData ENDP

end

;     to write to a particular register, send the register number (01-F5) to
;     the address port, and the desired value to the data port.
;
;     After writing to the register port, you must wait twelve cycles before 
;     sending the data; after writing the data, eighty-four cycles must elapse
;     before any other sound card operation may be performed.


; |   First, clear out all of the registers by setting all of them to zero.
; |   This is the quick-and-dirty method of resetting the sound card, but it
; |   works.  Note that if you wish to use different waveforms, you must then
; |   turn on bit 5 of register 1.  (This reset need be done only once, at the
; |   start of the program, and optionally when the program exits, just to 
; |   make sure that your program doesn't leave any notes on when it exits.)
; |
; |   Now, set the following registers to the indicated value:
; |
; |   To turn the voice off, set register B0h to 11h (or, in fact, any value 
; |   which leaves bit 5 clear).  It's generally preferable, of course, to
; |   induce a delay before doing so.

; |   The AdLib manual gives the wait times in microseconds: three point three
; |   (3.3) microseconds for the address, and twenty-three (23) microseconds
; |   for the data.
; |
; |   The most accurate method of producing the delay is to read the register
; |   port six times after writing to the register port, and read the register
; |   port thirty-five times after writing to the data port.



     The sound card is programmed by sending data to its internal registers
     via its two I/O ports:

             0388 (hex) - Address/Status port  (R/W)
             0389 (hex) - Data port            (W/O)

 |   The Sound Blaster Pro is capable of stereo FM music, which is accessed
 |   in exactly the same manner.  Ports 0220 and 0221 (hex) are the address/
 |   data ports for the left speaker, and ports 0222 and 0223 (hex) are the
 |   ports for the right speaker.  Ports 0388 and 0389 (hex) will cause both
 |   speakers to output sound.

