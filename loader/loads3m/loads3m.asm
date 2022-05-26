.386
.MODEL FLAT
.STACK 1000h
JUMPS
.data

Tones           db 'C-C#D-D#E-F-F#G-G#A-A#B-'

Orderpointer    dd 0
Patternpointer  dw 0
INSTRUMENT      db 0
VOLUME_BYTE     db 120
EFFECT          db 0
EFFECT_PARAM    db 0
NOTE            db 0

error_msg       db 'Unrecognized file format.',13,10,'$'
s3m_file        db '2nd_pm.s3m',0
VideoMem        dd ?
Var1            dd ?
row             db ?
pointer         dd ?
filehandle      dw ?
PatLength       dw ?
REMAP           db 32           dup (?)
Packed_Pattern  db 10240        dup (?)
PatternBuffer   db 1024000      dup (?)
SampleBuffer    db 2000000      dup (?)
Parapointers    dw 355          dup (?)
SamplePointer   dd 99           dup (?)
Order_Table     db 256          dup (?)
Channel_Setting db 32           dup (?)
S3M_NAME        db 29           dup (?)
ident           db 4            dup (?)
FILETYPE        db ?
CHANNELS        db ?
NUMBER_OF_INSTR dw ?
NUMBER_OF_PATS  dw ?
SONG_LENGTH     dw ?
GLOBAL_VOLUME   db ?
INITIAL_SPEED   db ?
INITIAL_TEMPO   db ?
MASTER_VOLUME   db ?

Instruments     db 80*99 dup (?)

.code

start:

mov     ax,3
int     10h

jmp     begin

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

INCLUDE procs.inc

begin:

xor     ebx,ebx
xor     eax,eax
Mov     Ax,0EE02h               ; GET DOS32 ADDRESS INFORMATION
Int     31h

mov     edi,0B8000h
sub     edi,ebx
mov     VideoMem,edi

mov     ah,3Dh
xor     al,al
mov     edx,offset s3m_file                     ;open S3M file
int     21h
mov     bx,ax                                   ;filehandle in bx
mov     ah,3Fh
mov     ecx,29                                  ;read 29 bytes
mov     edx,offset S3M_NAME                     ;read into s3m_name array
int     21h

mov     edx,offset FILETYPE
mov     ecx,1
mov     ah,3Fh
int     21h

cmp     FILETYPE,16                             ;16 = ST3 module
jnz     S3M_error

mov     ah,3Fh
mov     ecx,2
mov     edx,offset ParaPointers                 ;length of song in orders
int     21h
mov     ah,3Fh
mov     ecx,2
mov     edx,offset SONG_LENGTH                  ;length of song in orders
int     21h
mov     ah,3Fh
mov     ecx,2
mov     edx,offset NUMBER_OF_INSTR
int     21h
mov     ah,3Fh
mov     ecx,2
mov     edx,offset NUMBER_OF_PATS               ;number of physical patterns
int     21h
mov     ah,3Fh
mov     ecx,6                                   ;read 6 unused bytes,
mov     edx,offset ParaPointers                 ;store them in ParaPointers
int     21h                                     ;(will be overwritten later)
mov     ah,3Fh
mov     ecx,4
mov     edx,offset IDENT                        ;IDENT = SCRM
int     21h

mov     ah,3Fh                                  ;read misc. variables
mov     ecx,1
mov     edx,offset GLOBAL_VOLUME
int     21h
mov     ah,3Fh
mov     ecx,1
mov     edx,offset INITIAL_SPEED
int     21h
mov     ah,3Fh
mov     ecx,1
mov     edx,offset INITIAL_TEMPO
int     21h
mov     ah,3Fh
mov     ecx,1
mov     edx,offset MASTER_VOLUME
int     21h
mov     ah,3Fh
mov     ecx,12                                  ;12 unused bytes
mov     edx,offset ParaPointers
int     21h
mov     ah,3Fh
mov     ecx,32                                  ;32 bytes, 1 for each channel
mov     edx,offset channel_setting              ;read channel settings
int     21h

mov     ah,3Fh
xor     ecx,ecx
mov     cx,SONG_LENGTH
mov     edx,offset Order_Table
int     21h

;Store Parapointers:
;=========================
;To use the parapointers as a relevant value for the offset in the file,
;multiply it by 16, or shift it left 4 bits, and that is where the start of
;the data for that particular instrument or pattern is!

mov     ah,3Fh
xor     ecx,ecx
mov     cx,NUMBER_OF_INSTR
add     cx,NUMBER_OF_PATS
shl     cx,1                                    ;each parapointer is a word,
                                                ;so to get the number of bytes
                                                ;to read, multiply x2
mov     edx,offset Parapointers
int     21h                                     ;read all parapointers

mov     esi,offset channel_setting
mov     edi,offset REMAP
mov     ecx,32                                  ;32 channels to examine
xor     ah,ah                                   ;channel counter
Map_Channels:
mov     dl,66
mov     al,byte ptr [esi]
cmp     al,16                                   ;channel active?
ja      skip                                    ;if not, jump
mov     dl,ah
inc     ah                                      ;increment channel counter
skip:
mov     byte ptr [edi],dl
inc     si
inc     di
loop    Map_Channels

mov     CHANNELS,ah

mov     esi,offset Order_Table
mov     edi,offset Order_Table
xor     ecx,ecx
mov     cx,SONG_LENGTH
xor     al,al
Load_Order:
mov     ah,byte ptr [esi]
cmp     ah,254                                   ;skip pattern markers
jae     ignore
mov     byte ptr [edi],ah
inc     edi
inc     al
ignore:
inc     esi
loop    Load_Order

xor     ah,ah
mov     SONG_LENGTH,ax

xor     eax,eax
mov     pointer,0
mov     ax,NUMBER_OF_INSTR
mov     esi,offset ParaPointers
load_instrument_info:
push    eax
xor     edx,edx
mov     dx,word ptr [esi]                       ;get a parapointer
shl     edx,4                                   ;multiply it with 16
mov     ah,42h                                  ;function 42h = file seek
xor     al,al                                   ;seek from beginning of file
int     21h                                     ;position internal filepointer
jc      s3m_error                               ;exit if error
mov     ah,3Fh
mov     edx,offset instruments
add     edx,pointer                             ;current instrument
mov     ecx,80                                  ;instrument info = 80 bytes
int     21h                                     ;read into buffer
add     si,2                                    ;next parapointer
add     pointer,80                              ;next instrument
pop     eax                                     ;restore loop counter
dec     ax                                      ;done all instruments yet?
jnz     load_instrument_info                    ;if not, do another

xor     ecx,ecx
mov     cx,NUMBER_OF_INSTR
mov     pointer,0
mov     esi,offset Instruments
mov     edi,offset SamplePointer
LOAD_SAMPLES:
push    ecx
xor     edx,edx

;The first byte is the upper part of the value, while the next 2 bytes are the
;lower word of the value.
;To get the real offset in bytes use the following method.
;
;1. read a BYTE into PART1
;2. read a WORD into PART2
;3. sample_pos = (PART1 SHL 16) + PART2

xor     edx,edx
mov     dl,byte ptr [esi+13]                    ;upper byte of parapointer
shl     edx,16                                  ;make it upper
mov     dx,word ptr [esi+14]                    ;add lower word of parapointer
shl     edx,4                                   ;x16
xor     al,al                                   ;seek from beginning of file
mov     ah,42h
int     21h                                     ;position file pointer
jc      s3m_error

mov     ecx,pointer
mov     dword ptr [edi],ecx
mov     edx,offset SampleBuffer
add     edx,pointer
xor     ecx,ecx
mov     cx,word ptr [esi+16]                    ;get sample length
add     pointer,ecx
mov     ah,3Fh
int     21h                                     ;load sample
add     esi,80                                  ;next instrument
add     edi,4
pop     ecx
loop    LOAD_SAMPLES

mov     edi,offset patternbuffer
mov     ecx,204800
xor     ax,ax
clear_pats:
mov     word ptr [edi],ax
mov     byte ptr [edi+2],120
mov     word ptr [edi+3],ax
add     edi,5
loop    clear_pats

xor     eax,eax
mov     pointer,0
mov     ax,NUMBER_OF_INSTR
mov     esi,offset ParaPointers
add     esi,eax
add     esi,eax
LOAD_PATTERNS:
push    esi
xor     edx,edx
mov     dx,word ptr [esi]
shl     edx,4
xor     al,al
mov     ah,42h
int     21h
jc      s3m_error

mov     ah,3Fh
mov     edx,offset PatLength
mov     ecx,2
int     21h

mov     cx,PatLength
mov     ah,3Fh
mov     edx,offset Packed_Pattern
int     21h

mov     row,0
mov     esi,offset Packed_Pattern
mov     Var1,0
xor     eax,eax
xor     ecx,ecx
Decode_Pattern:

;        So to unpack, first read one byte. If it's zero, this row is
;        done (64 rows in entire pattern). If nonzero, the channel
;        this entry belongs to is in BYTE AND 31. Then if bit 32
;        is set, read NOTE and INSTRUMENT (2 bytes). Then if bit
;        64 is set read VOLUME (1 byte). Then if bit 128 is set
;        read COMMAND and INFO (2 bytes).

mov     al,byte ptr [esi]                       ;get-a-byte
inc     esi                                     ;next byte
cmp     al,0                                    ;check if byte is 0
je      next_row                                ;if so, row is done
mov     dl,al                                   ;save byte in dl
and     al,31                                   ;00011111b
mov     cl,REMAP[eax]                           ;find channel number
mov     al,dl                                   ;restore byte
and     al,32                                   ;00100000b
jz      skip_note                               ;if not set, skip
mov     al,byte ptr [esi]                       ;get note
mov     NOTE,al
mov     al,byte ptr [esi+1]                     ;get instrument
mov     INSTRUMENT,al
add     esi,2
skip_note:
mov     al,dl
and     al,64                                   ;01000000b
jz      skip_vol                                ;if bit not set, jump
mov     al,byte ptr [esi]                       ;get volume byte
mov     VOLUME_BYTE,al
inc     esi
skip_vol:
mov     al,dl
and     al,128                                  ;10000000b
jz      skip_effect                             ;if bit not set, jump
mov     al,byte ptr [esi]                       ;get effect
mov     EFFECT,al
mov     al,byte ptr [esi+1]                     ;get effect parameter
mov     EFFECT_PARAM,al
add     esi,2
skip_effect:
mov     edi,offset PatternBuffer
add     edi,pointer                             ;pointer to current pattern
add     edi,Var1                                ;pointer to current row
add     edi,ecx
add     edi,ecx
add     edi,ecx
add     edi,ecx
add     edi,ecx                                 ;current channel
mov     al,NOTE
mov     byte ptr [edi],al                       ;store note
mov     al,INSTRUMENT
mov     byte ptr [edi+1],al                     ;store instrument
mov     al,VOLUME_BYTE
mov     byte ptr [edi+2],al                     ;store volume byte
mov     al,EFFECT
mov     byte ptr [edi+3],al                     ;store effect
mov     al,EFFECT_PARAM
mov     byte ptr [edi+4],al                     ;store effect parameter
mov     NOTE,0                                  ;reset variables
mov     INSTRUMENT,0
mov     VOLUME_BYTE,120
mov     EFFECT,0
MOV     EFFECT_PARAM,0
jmp     decode_pattern

next_row:
xor     eax,eax
mov     al,Channels
add     Var1,eax
add     Var1,eax
add     Var1,eax
add     Var1,eax
add     Var1,eax
inc     row
cmp     row,64
jnz     Decode_Pattern

xor     eax,eax
mov     al,Channels
xor     ecx,ecx
mov     ecx,320
mul     ecx
add     pointer,eax
pop     esi
add     esi,2
dec     NUMBER_OF_PATS
jnz     LOAD_PATTERNS

mov     row,0
loopert:
call    update_pattern
mov     ah,00
int     16h
cmp     al,27
je      exit
mov     al,5
mov     bl,Channels
mul     bl
xor     ah,ah
add     patternpointer,ax
inc     row
cmp     row,64
jnz     loopert
add     orderpointer,2560
mov     patternpointer,0
mov     row,0
jmp     loopert

s3m_error:
mov     edx,offset error_msg
mov     ah,09
int     21h

exit:
mov     ax,4c00h
int     21h
end     start
