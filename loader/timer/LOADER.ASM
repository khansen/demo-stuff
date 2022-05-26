DOSSEG
.MODEL SMALL
.386
.STACK 100h
JUMPS

filename        EQU     30

.data

filehandle      dw 0
outfile db 'module00.raw',0

INCLUDE data.inc

.code

mov     ax,@data
mov     ds,ax
mov     es,ax

mov     ah,3Ch
xor     cx,cx
mov     dx,offset outfile
int     21h
mov     ah,3Dh
mov     al,2
mov     dx,offset outfile
int     21h
mov     filehandle,ax

push    es
mov     ax,3508h                        ;get vector til int 08h (timer)
int     21h
mov     TimerSeg,es
mov     TimerOfs,bx
pop     es

call    Init_SB

jmp     continue

HexDisp MACRO V1
mov     al,V1
shr     al,4
call    HexDigit
stosw
mov     al,V1
and     al,00001111b
call    HexDigit
stosw
ENDM

INCLUDE waitvrt.inc
INCLUDE mixer.inc
INCLUDE sb.inc
INCLUDE dma.inc
INCLUDE dir.inc
INCLUDE loadmod.inc
INCLUDE procs.inc

;ÄÄÄÄÄÄÄÄÄÄÄÄERRORSÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

not_mod:
mov     ah,09
mov     dx,offset MOD_ERROR
int     21h
mov     ah,00
int     16h
mov     ax,4c00h
int     21h

;ÄÄÄÄÄÄÄÄÄÄÄOPEN FILEÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

continue:

mov     DMAinfo._length,640

;       - Set frequency (40h followed by time constant)

mov     Value,40h
call    WriteDSP
mov     Value,0e1h
call    WriteDSP

;      - Calculate 20 bit address of the memory buffer you are using
;        like this: Segment * 16 + Offset

mov     dx,seg DMAbuffer
mov     ax,offset DMAbuffer
call    MakePage

call    DirEngine

call    LoadMod

;ÄÄÄÄÄÄÄÄDISPLAY MISC INFORMATIONÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

mov     TextPointer,0
mov     LinePointer,1

mov     row,63
mov     order_position,0

push    ds
mov     ax,2508h                                ;set vector
mov     bx,cs
mov     ds,bx
mov     dx,offset Update_Audio          ;den heftige proceduren som skal executes ;)
int     21h
pop     ds

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

mov     tick,0

Show_Pattern:
mov     ax,3
int     10h

mov     ax,0b800h
mov     es,ax
xor     di,di

mov     cx,12
mov     si,offset MOD_NAME
mov     ah,9
call    Disp_String

mov     cx,20
mov     si,offset MODULE_NAME
mov     ah,11
call    Disp_String

add     di,2
mov     cx,6
mov     si,offset ORDER_STRING
mov     ah,9
call    Disp_String
add     di,4
mov     al,'/'
stosw

mov     ah,11
mov     bl,SONG_LENGTH
dec     bl
HexDisp bl

add     di,2
mov     cx,4
mov     si,offset PATTERN_STRING
mov     ah,9
call    Disp_String

call    Update_Text
Show_Pattern2:
call    Update_Pattern
in      al,60h
cmp     al,1
je      exit
cmp     al,51h                          ;page down
je      page_down
cmp     al,49h                          ;page up
je      page_up
cmp     al,50h                          ;cursor down
je      down_one_line
cmp     al,48h                          ;cursor up
je      up_one_line
cmp     al,3
jnz     Show_Pattern2

mov     ax,13h
int     10h
mov     ax,0a000h
mov     es,ax
Show_Scope:
call    Scope

in      al,60h
cmp     al,1
je      exit
cmp     al,2
je      Show_Pattern
jmp     Show_Scope

Up_One_Line:
cmp     TextPointer,0
je      Show_Pattern2
mov     bx,size smp_info
sub     TextPointer,bx
dec     LinePointer
call    Update_Text
jmp     Show_Pattern2

down_one_line:
mov     bx,size smp_info
mov     ax,6
mul     bx
cmp     ax,TextPointer
je      Show_Pattern2
add     TextPointer,bx
inc     LinePointer
call    Update_Text
jmp     Show_Pattern2

page_up:
mov     TextPointer,0
mov     LinePointer,1
call    Update_Text
jmp     Show_Pattern2

page_down:
mov     bx,size smp_info
mov     ax,6
mul     bx
mov     TextPointer,ax
mov     LinePointer,7
call    Update_Text
jmp     Show_Pattern2

exit:

push    ds
mov     ax,2508h
mov     dx,TimerOfs                     ;restore gammel vector
mov     ds,TimerSeg
int     21h
pop     ds

mov     ax,3
int     10h
mov     ax,4c00h
int     21h

end
