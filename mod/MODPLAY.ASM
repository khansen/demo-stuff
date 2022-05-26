IDEAL
P386N
MODEL FLAT
STACK 1000h
jumps

MIXING_FREQ     EQU 22050

; pointers to channel info

SAMPLE_POINTER  EQU 00h
LOOP_END        EQU 04h                 ; pointer to end of sample
CHN_LOOP_LEN    EQU 08h
MIX_COUNT       EQU 0Ah
MIX_LOSPEED     EQU 0Ch
AMIGA_PERIOD    EQU 0Eh
STATUS          EQU 10h
CHANNEL_VOLUME  EQU 11h
EFFECT_NUMBER   EQU 12h
EFFECT_PARAM    EQU 13h
MIX_HISPEED     EQU 14h

; pointers to sample info

SAMPLE_NAME     EQU 00h
SAMPLE_LENGTH   EQU 16h
FINE_TUNE       EQU 18h
SAMPLE_VOLUME   EQU 19h
LOOP_START      EQU 1Ah
SMP_LOOP_LEN    EQU 1Ch

DATASEG

note_table      db 'תתת',0
                db 'תתת',0
                db 'C-0',0
                db 'C#0',0
                db 'D-0',0
                db 'D#0',0
                db 'E-0',0
                db 'F-0',0
                db 'F#0',0
                db 'G-0',0
                db 'G#0',0
                db 'A-0',0
                db 'A#0',0
                db 'B-0',0
                db 'C-1',0
                db 'C#1',0
                db 'D-1',0
                db 'D#1',0
                db 'E-1',0
                db 'F-1',0
                db 'F#1',0
                db 'G-1',0
                db 'G#1',0
                db 'A-1',0
                db 'A#1',0
                db 'B-1',0
                db 'C-2',0
                db 'C#2',0
                db 'D-2',0
                db 'D#2',0
                db 'E-2',0
                db 'F-2',0
                db 'F#2',0
                db 'G-2',0
                db 'G#2',0
                db 'A-2',0
                db 'A#2',0
                db 'B-2',0

command_table   dd Arpeggio
                dd Porta_Up
                dd Porta_Down
                dd Porta_To_Note
                dd Vibrato
                dd Porta_Volume_Slide
                dd Vibrato_Volume_Slide
                dd Tremolo
                dd Pan
                dd Sample_Offset
                dd Volume_Slide
                dd Jump_To_Pattern
                dd Set_Volume
                dd Pattern_Break
                dd null
                dd Set_Speed

Period_Table    dw 856,808,762,720,678,640,604,570,538,508,480,453 ; C-1 to B-1
                dw 428,404,381,360,339,320,302,285,269,254,240,226 ; C-2 to B-2
                dw 214,202,190,180,170,160,151,143,135,127,120,113 ; C-3 to B-3

file_error      db ' ERROR: Could not open file.',13,10,'$'
format_error    db ' ERROR: Unrecognized file format.',13,10,'$'

video_mem       dd 0B8000h
mix_buffer      dd 80000h
buffer_playing  db 0
num_channels    db 4
mod_id          db 'M.K.'
mix_length      dw 441
mix_pos         dd 0
num_patterns    db 0
order_position  db 0
speed           db 6
BPM             db 125
row             db 0
tick            db ?
file_handle     dw ?
pattern_pointer dd ?
mod_header      db 1084 dup (?)
mod_filename    db 128 dup (?)
module_name     db 20 dup (?)
song_length     db ?
pattern_order   db 128 dup (?)
sample_info     db 31*32 dup (?)
sample_offsets  dd 31*2 dup (?)
channel_info    db 21*32 dup (?)
pattern_data    db 1024*64 dup (?)
volume_table    db 256*65 dup (?)
sample_data     db 1000000 dup (?)

oldintD         df ?

CODESEG

include "dma.inc"

start:

call    ResetDSP

mov     ax,0EE02h
int     31h
sub     [video_mem],ebx
sub     [mix_buffer],ebx
mov     edi,[mix_buffer]
mov     ecx,8000h
mov     al,128
rep     stosb

movzx   ecx,[byte ptr esi + 80h]        ; get length of command tail
jcxz    terminate
add     esi,81h                         ; ESI points to first character
find_first_char:
cmp     [byte ptr esi],20h              ; space?
jnz     copy_filename                   ; if not, copy ASCII string
inc     esi                             ; next char
dec     cl                              ; tried all?
jz      terminate                       ; yes, end program
jmp     short find_first_char           ; no, try again

copy_filename:
mov     edi,offset mod_filename
rep     movsb
mov     [byte ptr edi],0

mov     ax,3D00h
mov     edx,offset mod_filename
int     21h                             ; attempt to open file
jnc     read_file                       ; if CF not set, it worked

mov     ah,09
mov     edx,offset file_error
int     21h                             ; display error message
jmp     terminate

read_file:

mov     [file_handle],ax
mov     bx,[file_handle]
mov     ah,3Fh
mov     ecx,1084
mov     edx,offset mod_header
int     21h

mov     esi,offset mod_header
mov     edi,offset module_name
mov     ecx,20
rep     movsb

mov     al,31
mov     edi,offset sample_info
load_sample_info:
mov     ecx,30
rep     movsb
add     edi,2
dec     al
jnz     load_sample_info

lodsb
mov     [song_length],al

inc     esi

mov     ecx,128
mov     edi,offset pattern_order
load_order:
lodsb
cmp     al,[num_patterns]
jbe     store_order
mov     [num_patterns],al
store_order:
stosb
loop    load_order

mov     ecx,4
mov     edi,offset mod_id
repe    cmpsb
cmp     ecx,0
je      format_OK

mov     ah,09
mov     edx,offset format_error
int     21h
jmp     terminate

format_OK:

mov     ecx,21*32
mov     edi,offset channel_info
xor     al,al
rep     stosb

;*****************************************************************************
;                       LOAD AND DECODE PATTERN DATA
;*****************************************************************************

inc     [num_patterns]

mov     bx,[file_handle]
mov     ah,3Fh
movzx   ecx,[num_patterns]
shl     ecx,10
mov     edx,offset pattern_data
int     21h

mov     ch,[num_patterns]
mov     esi,offset pattern_data
decode_pattern:
xor     cl,cl
decode_loop:
mov     al,[byte ptr esi]
mov     bh,al
and     al,11110000b                    ; AL = upper 4 bits of sample number
mov     ah,[byte ptr esi+2]
shr     ah,4                            ; BL = lower 4 bits of sample number
or      al,ah                           ; combine them
mov     [byte ptr esi],al               ; store sample number

and     bh,00001111b                    ; isolate upper four bits of period
mov     bl,[byte ptr esi+1]             ; BL = lower 8 bits of period value
cmp     bx,0                            ; no note triggered?
je      short skip_findnote

xor     eax,eax                         ; note number (counter)
find_note:
cmp     bx,[Period_Table + eax*2]       ; do they match?
je      short found_note
inc     al                              ; increase note number
jmp     short find_note
found_note:
mov     [byte ptr esi+1],al             ; store note number (0-35)

skip_findnote:
and     [byte ptr esi+2],00001111b      ; isolate effect number
add     esi,4                           ; advance to next note
dec     cl                              ; done entire pattern?
jnz     short decode_loop               ; nope, do another note
dec     ch                              ; done all patterns?
jnz     short decode_pattern            ; nope, do another

movzx   eax,[pattern_order]             ; physical pattern number
shl     eax,10                          ; * 1024
add     eax,offset pattern_data         ; EAX = mempointer to pattern
mov     [pattern_pointer],eax

;*****************************************************************************
;                            CREATE VOLUME TABLE
;*****************************************************************************

mov     edi,offset Volume_Table
xor     bx,bx
outer_vol_loop:
xor     cl,cl
inner_vol_loop:
mov     ax,bx
movsx   dx,cl
imul    dx
sar     ax,6
stosb
inc     cl
jnz     short inner_vol_loop
inc     bl
cmp     bl,65
jnz     short outer_vol_loop

;*****************************************************************************
;                       CREATE TABLE OF SAMPLE POINTERS
;*****************************************************************************

mov     esi,offset sample_info
mov     edi,offset sample_offsets
mov     ecx,31
mov     ebx,offset sample_data
calc_offset:
mov     [dword ptr edi],ebx
movzx   eax,[word ptr esi + SAMPLE_LENGTH]
xchg    al,ah
shl     eax,1
mov     [word ptr esi + SAMPLE_LENGTH],ax
add     ebx,eax
mov     [dword ptr edi+4],ebx
mov     ax,[word ptr esi + SMP_LOOP_LEN]
xchg    al,ah
shl     eax,1
mov     [word ptr esi + SMP_LOOP_LEN],ax
mov     ax,[word ptr esi + LOOP_START]
xchg    al,ah
shl     eax,1
mov     [word ptr esi + LOOP_START],ax
add     edi,8
add     esi,32
loop    calc_offset

;*****************************************************************************
;                              LOAD SAMPLE DATA
;*****************************************************************************

mov     ah,3Fh
mov     bx,[file_handle]
mov     ecx,1000000
mov     edx,offset sample_data
int     21h

mov     ah,3Eh
int     21h

mov     ax,204h                 ; f204h i31h - get interrupt
mov     bl,0D                   ; bl=interrupt number
int     31h
                                ; returns cx:edx for the old int
mov     [dword ptr oldintD],edx ; save old interrupt
mov     [word ptr oldintD+4],cx

mov     ax,205h                 ; f205h i31h - set interrupt
mov     bl,0Dh                  ; int num
mov     cx,cs                   ; cx=seg - for newint8
mov     edx,offset newintD      ; edx offset - for newint8
int     31h

call    SetUpDMA

;
;
;

mov     ax,3
int     10h

show_pattern:
mov     edi,[video_mem]
mov     esi,[pattern_pointer]
movzx   eax,[row]
shl     eax,4
add     esi,eax
mov     ch,20
show_row:
push    edi
xor     ebx,ebx
show_channel:

mov     ah,15
movzx   edx,[byte ptr esi+1]
inc     dl
mov     al,[note_table + edx*4]
stosw
mov     al,[note_table + edx*4 + 1]
stosw
mov     al,[note_table + edx*4 + 2]
stosw
add     edi,2

mov     al,[byte ptr esi]
cmp     al,0
jnz     show_smp_number
xor     al,al
stosw
stosw
jmp     show_fx_number
show_smp_number:
mov     ah,9
mov     dl,al
shr     al,4
call    HexDigit
stosw
mov     al,dl
and     al,00001111b
call    HexDigit
stosw

show_fx_number:
mov     ah,11
add     edi,2
mov     al,[byte ptr esi+2]
call    HexDigit
stosw
mov     al,[byte ptr esi+3]
mov     dl,al
shr     al,4
call    HexDigit
stosw
mov     al,dl
and     al,00001111b
call    HexDigit
stosw
add     edi,8

add     esi,4
inc     bl
cmp     bl,[num_channels]
jnz     show_channel
pop     edi
add     edi,160
dec     ch
jnz     show_row

in      al,60h
dec     al
jnz     show_pattern

mov     ax,3
int     10h

;
;
;

call    ShutDownSB

mov     ax,205h
mov     bl,0Dh
mov     cx,[word ptr oldintD+4]
mov     edx,[dword ptr oldintD]
int     31h

terminate:
mov     ax,4c00h
int     21h

;*****************************************************************************
;                           NEW INTERRUPT ROUTINE
;*****************************************************************************

PROC    newintD

pushad                                  ; save all registers

mov     dx,[Base_Address]
add     dx,DATA_AVAILABLE_PORT
in      al,dx

mov     [tick],0
mov     [mix_pos],0                     ; start at front of buffer again
xor     [buffer_playing],1
jnz     @@10
movzx   eax,[mix_length]
movzx   ebx,[speed]
mul     ebx
mov     [mix_pos],eax
@@10:

call    Audio_Mixer

inc     [tick]
mov     al,[tick]
cmp     al,[speed]                      ; does tick equal speed?
jnz     @@10                            ; if not, create some more output

mov     al,20h
out     20h,al

popad
iret
ENDP    NewIntD

PROC    Audio_Mixer

cmp     [tick],0
jnz     update_fx

;*****************************************************************************
;                                 UPDATE ROW
;*****************************************************************************

mov     esi,[pattern_pointer]           ; ESI points to current pattern
movzx   eax,[row]
shl     eax,4                           ; * 16 (because each row is 16 bytes)
add     esi,eax                         ; ESI now points to current row
mov     edi,offset channel_info
xor     ebx,ebx                         ; clear channel count
update_row:
push    ebx
movzx   eax,[byte ptr esi]              ; sample number (1-31)
cmp     al,0                            ; if zero, no note has been triggered
je      short no_note

mov     [byte ptr edi + STATUS],1       ; channel = ON
dec     al
mov     ecx,[sample_offsets + eax*8]    ; ECX contains pointer to sampledata
mov     [dword ptr edi + SAMPLE_POINTER],ecx
mov     ecx,[sample_offsets + eax*8 + 4]
mov     [dword ptr edi + LOOP_END],ecx

shl     eax,5                           ; sample number * 32
mov     cl,[sample_info + eax + SAMPLE_VOLUME]
mov     [byte ptr edi + CHANNEL_VOLUME],cl
mov     ax,[word ptr sample_info + eax + SMP_LOOP_LEN]
mov     [word ptr edi + CHN_LOOP_LEN],ax

movzx   eax,[byte ptr esi+1]            ; note number
movzx   ecx,[period_table + eax*2]      ; fetch Amiga period
mov     [word ptr edi + AMIGA_PERIOD],cx
shl     ecx,1                           ; * 2
mov     eax,7159091
xor     edx,edx
div     ecx                             ; 7159091 / (Amigaval * 2)
mov     ecx,MIXING_FREQ                 ; mixing freq = 22050
xor     edx,edx
div     ecx
mov     [byte ptr edi + MIX_HISPEED],al
shl     edx,16
mov     eax,edx
xor     edx,edx
div     ecx
mov     [word ptr edi + MIX_LOSPEED],ax
mov     [word ptr edi + MIX_COUNT],0    ; reset sample-stepping variable

no_note:
mov     al,[byte ptr esi+2]             ; effect number
mov     [byte ptr edi + EFFECT_NUMBER],al
cmp     [byte ptr esi+3],0              ; no effect parameter?
je      short skip_param                ; if not, keep the old one
mov     al,[byte ptr esi+3]
mov     [byte ptr edi + EFFECT_PARAM],al

skip_param:
mov     al,[byte ptr edi + EFFECT_NUMBER]
cmp     al,09h
je      command_900h
cmp     al,0Bh
je      command_B00h
cmp     al,0Ch
je      command_C00h
cmp     al,0Dh
je      command_D00h
cmp     al,0Fh
je      command_F00h
jmp     next_channel
command_900h:
movzx   eax,[byte ptr edi + EFFECT_PARAM]
shl     eax,8
add     [dword ptr edi + SAMPLE_POINTER],eax
jmp     next_channel
command_B00h:
movzx   eax,[byte ptr edi + EFFECT_PARAM]
mov     [order_position],al
movzx   eax,[pattern_order + eax]       ; physical pattern number
shl     eax,10                          ; * 1024
add     eax,offset pattern_data         ; EAX = mempointer to pattern
mov     [pattern_pointer],eax
mov     [row],-1
jmp     next_channel
command_C00h:
mov     al,[byte ptr edi + EFFECT_PARAM]
mov     [byte ptr edi + CHANNEL_VOLUME],al
jmp     next_channel
command_D00h:
inc     [order_position]
movzx   eax,[order_position]
mov     al,[pattern_order + eax]        ; physical pattern number
shl     eax,10                          ; * 1024
add     eax,offset pattern_data         ; EAX = mempointer to pattern
mov     [pattern_pointer],eax
mov     [row],-1
;mov     al,[byte ptr edi + EFFECT_PARAM]
;mov     [row],al
;mov     [row],0
jmp     next_channel
command_F00h:
mov     al,[byte ptr edi + EFFECT_PARAM]
cmp     al,20h
jae     new_bpm
mov     [speed],al
jmp     next_channel
new_bpm:
mov     [bpm],al

; calc new mix_length
mov     eax,MIXING_FREQ
mov     ecx,10
mul     ecx
movzx   ecx,[bpm]
xor     edx,edx
div     ecx
shr     eax,2
mov     [mix_length],ax

next_channel:
add     esi,4
add     edi,15h
pop     ebx
inc     bl
cmp     bl,[num_channels]
jnz     update_row

inc     [row]
cmp     [row],64
jnz     mix_audio

;*****************************************************************************
;                    SET PATTERN POINTER TO NEXT PATTERN
;*****************************************************************************

mov     [row],0                         ; reset row variable
movzx   ebx,[order_position]            ; 0...127
inc     bl
cmp     bl,[song_length]
jb      short not_EOS
xor     bl,bl
mov     [order_position],bl
not_EOS:
movzx   eax,[pattern_order + ebx]       ; physical pattern number
shl     eax,10                          ; * 1024
add     eax,offset pattern_data         ; EAX = mempointer to pattern
mov     [pattern_pointer],eax
inc     [order_position]
jmp     mix_audio

;*****************************************************************************
;                         UPDATE TICK-BASED EFFECTS
;*****************************************************************************

update_fx:
mov     edi,offset channel_info
xor     ebx,ebx                         ; clear channel count
update_channel:
mov     al,[byte ptr edi + EFFECT_NUMBER]
cmp     al,01h
je      command_100h
cmp     al,02h
je      command_200h
cmp     al,0Ah
je      command_A00h
jmp     update_next_channel
command_100h:
movzx   ax,[byte ptr edi + EFFECT_PARAM]
sub     [word ptr edi + AMIGA_PERIOD],ax
movzx   ecx,[word ptr edi + AMIGA_PERIOD]
shl     ecx,1                           ; * 2
mov     eax,7159091
xor     edx,edx
div     ecx                             ; 7159091 / (Amigaval * 2)
mov     ecx,MIXING_FREQ                 ; mixing freq = 22050
xor     edx,edx
div     ecx
mov     [byte ptr edi + MIX_HISPEED],al
shl     edx,16
mov     eax,edx
xor     edx,edx
div     ecx
mov     [word ptr edi + MIX_LOSPEED],ax
jmp     update_next_channel
command_200h:
movzx   ax,[byte ptr edi + EFFECT_PARAM]
add     [word ptr edi + AMIGA_PERIOD],ax
movzx   ecx,[word ptr edi + AMIGA_PERIOD]
shl     ecx,1                           ; * 2
mov     eax,7159091
xor     edx,edx
div     ecx                             ; 7159091 / (Amigaval * 2)
mov     ecx,MIXING_FREQ                 ; mixing freq = 22050
xor     edx,edx
div     ecx
mov     [byte ptr edi + MIX_HISPEED],al
shl     edx,16
mov     eax,edx
xor     edx,edx
div     ecx
mov     [word ptr edi + MIX_LOSPEED],ax
jmp     update_next_channel
command_A00h:
mov     al,[byte ptr edi + EFFECT_PARAM]
and     al,00001111b
jnz     fade_out
cmp     [byte ptr edi + CHANNEL_VOLUME],40h
je      update_next_channel
mov     al,[byte ptr edi + EFFECT_PARAM]
shr     al,4
add     [byte ptr edi + CHANNEL_VOLUME],al
cmp     [byte ptr edi + CHANNEL_VOLUME],40h
jbe     update_next_channel
mov     [byte ptr edi + CHANNEL_VOLUME],40h
jmp     update_next_channel
fade_out:
cmp     [byte ptr edi + CHANNEL_VOLUME],00h
je      update_next_channel
sub     [byte ptr edi + CHANNEL_VOLUME],al
cmp     [byte ptr edi + CHANNEL_VOLUME],00h
jge     update_next_channel
mov     [byte ptr edi + CHANNEL_VOLUME],00h
mov     [byte ptr edi + STATUS],0
jmp     update_next_channel
update_next_channel:
add     edi,15h
inc     bl
cmp     bl,[num_channels]
jnz     update_channel

;*****************************************************************************
;                            ACTUAL AUDIO MIXING
;*****************************************************************************

mix_audio:
movzx   ecx,[mix_length]
mov     edi,[mix_buffer]
add     edi,[mix_pos]
mov     al,128
push    edi
rep     stosb                           ; clear output buffer
pop     edi

mov     edx,offset channel_info
xor     ebx,ebx                         ; clear channel count
mix_channel:
push    ebx edi
cmp     [byte ptr edx + STATUS],0       ; is channel off?
je      short skip_mix                  ; if so, there's nothing to mix

mov     esi,[dword ptr edx]             ; ESI points to sample data
mov     cx,[mix_length]                 ; number of bytes to mix
movzx   ebx,[byte ptr edx + MIX_HISPEED]
mov     bp,[word ptr edx + MIX_COUNT]
mov     ah,[byte ptr edx + CHANNEL_VOLUME] ; volume of current channel
mix_loop:
mov     al,[byte ptr esi]               ; sample data
mov     al,[volume_table + eax]         ; get volume-scaled value
add     [byte ptr edi],al               ; add to output buffer
inc     edi
add     bp,[word ptr edx + MIX_LOSPEED] ; carry flag is set on overflow
adc     esi,ebx                         ; add MIX_HISPEED & possible overflow
cmp     esi,[dword ptr edx + LOOP_END]
jb      short not_end
mov     ax,[word ptr edx + CHN_LOOP_LEN]
cmp     ax,0
je      short channel_off
sub     esi,eax
mov     ah,[byte ptr edx + CHANNEL_VOLUME] ; volume of current channel
jmp     short not_end
channel_off:
mov     [byte ptr edx + STATUS],al       ; channel = OFF
jmp     short skip_mix
not_end:
dec     cx
jnz     short mix_loop
mov     [dword ptr edx],esi
mov     [word ptr edx + MIX_COUNT],bp

skip_mix:
add     edx,15h
pop     edi ebx
inc     bl                              ; next channel
cmp     bl,[num_channels]               ; done all channels yet?
jnz     mix_channel                     ; if not, do another

movzx   eax,[mix_length]
add     [mix_pos],eax

ret

ENDP    Audio_Mixer

Arpeggio:
Porta_Up:
Porta_Down:
Porta_To_Note:
Vibrato:
Porta_Volume_Slide:
Vibrato_Volume_Slide:
Tremolo:
Pan:
Sample_Offset:
Volume_Slide:
Jump_To_Pattern:
Set_Volume:
Pattern_Break:
null:
Set_Speed:

PROC    HexDigit

;converts a 4-bit value (0-15) to ASCII 0-1, A-F

cmp     al,10
jb      normal
add     al,'A'-10
ret
normal:
or      al,"0"                          ;add 30h
ret
ENDP    HexDigit

end     start
