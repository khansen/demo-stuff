IDEAL
P386N
MODEL FLAT
STACK 1000h

ADDRESS_PORT    EQU 388h                ; register is written to this port
DATA_PORT       EQU 389h                ; data is sent to this port

AMP_MOD         EQU 020h
KEY_SCALING     EQU 040h                ; controls total output level (dB)
ATTACK_RATE     EQU 060h                ; controls fade in / fade out
SUSTAIN_LEVEL   EQU 080h
FREQUENCY       EQU 0A0h                ; lower eight bits of frequency
KEY_ON          EQU 0B0h                ; octave, voice on, upper freq. bits
FEEDBACK        EQU 0C0h
WAVE_SELECT     EQU 0E0h                ; distortion factor (0-3)

dataseg

Voice_Commands  dd Voice_Off
                dd Voice_On
                dd Aftertouch
                dd Control_Change
                dd Program_Change
                dd Channel_Pressure
                dd Pitch_Wheel

nocard          db 'No Adlib compatible card found!',13,10,'$'
adlibreset      db 'Adlib hardware resetted.',13,10,'$'

ADL_NoteTable   DW 363,385,408,432,458,485,514,544,577,611,647,686

OPR_Offset      db 00h,01h,02h,08h,09h,0Ah,10h,11h,12h  ; channel 1-9

midifile        db 'kidicar2.mid',0

MIDI_ID         dd ?                    ; should be 'MThd'
MIDI_length     dd ?                    ; length of header, should be 6
MIDI_filetype   dw ?
MIDI_numtracks  dw ?
MIDI_division   dw ?

MIDI_data       db 32000 dup (?)

codeseg

include "adlib.inc"

start:

;*****************************************************************************
;                        DETECT AND RESET THE ADLIB
;*****************************************************************************

call    Detect_Adlib
cmp     cl,0
je      continue

mov     ah,09
mov     edx,offset nocard
int     21h
jmp     exit

continue:

mov     ah,09
mov     edx,offset nocard + 3           ; skip the word "No" :)
int     21h

call    Reset_Adlib

mov     ah,09
mov     edx,offset adlibreset
int     21h

mov     ah,3Dh
mov     edx,offset midifile
int     21h
mov     bx,ax

;*****************************************************************************
;                            READ THE MIDI HEADER
;*****************************************************************************

mov     ah,3Fh
mov     edx,offset MIDI_ID
mov     ecx,4
int     21h
mov     ah,3Fh
mov     edx,offset MIDI_length
mov     cx,4
int     21h
mov     ah,3Fh
mov     edx,offset MIDI_filetype
mov     cx,2
int     21h
mov     ah,3Fh
mov     edx,offset MIDI_numtracks
mov     cx,2
int     21h
mov     ah,3Fh
mov     edx,offset MIDI_division
mov     cx,2
int     21h

mov     ax,[MIDI_numtracks]
xchg    al,ah
mov     [MIDI_numtracks],ax

mov     ax,[MIDI_division]
xchg    al,ah
mov     [MIDI_division],ax

;*****************************************************************************
;                            READ THE TRACK CHUNKS
;*****************************************************************************

mov     ah,3Fh
mov     cx,32000
mov     edx,offset MIDI_data
int     21h
jmp     exit

;*****************************************************************************
;                               PLAY THE MIDI
;*****************************************************************************

mov     esi,offset MIDI_data

do_MIDI_event:
movzx   eax,[byte ptr esi]
cmp     al,0FFh
je      META_event
test    al,10000000b
je      Voice_Command
inc     esi
jmp     do_MIDI_event

Voice_Command:
movzx   ebx,al
and     bl,00001111b                    ; EBX = channel number
mov     bl,[OPR_offset + ebx]           ; EBX = operator offset for channel
shr     al,4                            ; EAX = command number (8-E)
and     al,00000111b                    ; drop 3rd bit (EAX = 0...7)
jmp     [Voice_Commands + eax*4]

Voice_Off:
add     bl,KEY_ON
mov     al,bl
call    Write_Adlib
jmp     do_MIDI_event

Voice_On:
add     bl,KEY_ON
mov     al,bl
mov     ah,20h
call    Write_Adlib
jmp     do_MIDI_event

Aftertouch:
Control_Change:
Program_Change:
Channel_Pressure:
Pitch_Wheel:

META_event:
cmp     [byte ptr esi+1],2Fh
je      end_of_track

end_of_track:
jmp     do_MIDI_event

call    Reset_Adlib

exit:
mov     ax,4c00h
int     21h

end     start
