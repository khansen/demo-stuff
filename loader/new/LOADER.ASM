IDEAL
P386N
MODEL FLAT
STACK 1000h
JUMPS

dataseg

INCLUDE "data.inc"

codeseg

start:

;calculate volumetable

mov     [Pointer],65
mov     esi,offset voltable
xor     ebx,ebx
volume_ready:
mov     [OutputByte],0
mov     ecx,256
calc_volume:
xor     ah,ah
mov     al,[OutputByte]
mul     bx
shr     ax,6
mov     [byte ptr esi],al
inc     esi
inc     [OutputByte]
loop    calc_volume

inc     bx
dec     [Pointer]
jnz     volume_ready

mov     ax,3
int     10h

xor     ebx,ebx
xor     eax,eax
Mov     Ax,0EE02h               ; GET DOS32 ADDRESS INFORMATION
Int     31h

mov     edi,0B8000h
sub     edi,ebx
mov     [videomem],edi

call    Init_SB

jmp     continue

MACRO   HexDisp V1
mov     al,V1
shr     al,4
call    HexDigit
stosw
mov     al,V1
and     al,00001111b
call    HexDigit
stosw
ENDM

INCLUDE "waitvrt.inc"
INCLUDE "mixer.inc"
INCLUDE "sb.inc"
INCLUDE "dma.inc"
INCLUDE "dir.inc"
INCLUDE "loadmod.inc"
INCLUDE "procs.inc"

;ÄÄÄÄÄÄÄÄÄÄÄÄERRORSÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

not_mod:
mov     ah,09
mov     edx,offset MOD_ERROR
int     21h
mov     ah,00
int     16h
mov     ax,4c00h
int     21h

;ÄÄÄÄÄÄÄÄÄÄÄOPEN FILEÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

continue:

mov     [DMAinfo._length],640
        
;       - Set frequency (40h followed by time constant)

mov     [Value],40h
call    WriteDSP
mov     [Value],0e1h
call    WriteDSP

;      - Calculate 20 bit address of the memory buffer you are using
;        like this: Segment * 16 + Offset

;mov     edx,seg DMAbuffer
;mov     eax,offset DMAbuffer
;call    MakePage

;call    DirEngine

call    LoadMod

mov     ah,3Ch
xor     cx,cx
mov     edx,offset outfile
int     21h
mov     ah,3Dh
mov     al,2
mov     edx,offset outfile
int     21h
mov     [filehandle],ax

;ÄÄÄÄÄÄÄÄDISPLAY MISC INFORMATIONÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

mov     [TextPointer],0
mov     [LinePointer],1

mov     [row],63
mov     [order_position],0
mov     [orderpointer],0
mov     [patternpointer],0

;How do you set the system timer's speed? if we want 50hz, we have to use
;a divisor to calculate the right rate like so.
;
;Hz = 50
;PCTimerRate = 1193180/Hz    ;<- 1193180 is the divisor using Hz as the rate
;
;Then use the below code to set the PC timer's rate to the desired speed.
;Below tells us how to convert BPM to HZ.

;ASSEMBLER:
;==========
    mov dx, 043h
    mov al, 036h
    out dx, al
    mov dx, 040h
;    mov ax, PCTimerRate     ; here's the PCTimerRate variable
mov     ax,23864
    out dx, al              ; write the lower 8 bits of the value
    shr ax, 8
    out dx, al              ; now write the upper 8 bits of the value

mov     [tick],0

call    SetMode80x50

mov     ax,204h                 ; f204h i31h - get interrupt
mov     bl,1Ch                  ; bl=interrupt number
int     31h                     ; dpmi call
                                ; returns cx:edx for the old int
mov     [oldofs],edx            ; save old interrupt
mov     [oldseg],cx

mov     ax,205h                 ; f205h i31h - set interrupt
mov     bl,1Ch                  ; int num
mov     cx,cs                   ; cx=seg - for newint9
mov     edx,offset update_audio ; edx offset - for newint9
int     31h

looop:
call    update_pattern
in      al,60h
cmp     al,1
jnz     looop

exit:

mov     ax,205h
mov     bl,9
mov     edx,[oldofs]                    ; set oldint9 back
mov     cx,[oldseg]
int     31h

mov     ax,3
int     10h
mov     ax,4c00h
int     21h

end     start
