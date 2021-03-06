_80x50          dw 04F01h
                dw 05002h
                dw 05504h
                dw 08105h
                dw 0BF06h
                dw 01F07h
                dw 04709h
                dw 09C10h
                dw 08E11h
                dw 08F12h
                dw 02813h
                dw 01F14h
                dw 09615h
                dw 0B916h
                dw 0A317h

RowSize         dw 16
MulRate         db 10
Speed           db 6
Channels        dd 4

filehandle      dw 0
outfile         db 'module00.raw',0

;컴컴컴컴컴훃SEFUL VARIABLES컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

Init_ERROR      db 'Could not initialize Soundblaster!',13,10,'$'
MaxPorts        db 6
PortAdr         dw 10h
mix_volume      db 40h

;middle base address jumper setting is excluded from the port addresses

file_keys       db 'ESC quits, keys 0-9 change disk.',0
file_message    db '                     TbK File Selector v1.0 by Kent Hansen                     ',0
FILE_NAME       db 'beyondmu.mod',0
defaultspec     db '*.*',0

Reset_Port              dw 206h
Read_Data_Port          dw 20Ah
Write_Data_Port         dw 20Ch
Data_Available_Port     dw 20Eh

Tones   db 'C-1 '
        db 'C#1 '
        db 'D-1 '
        db 'D#1 '
        db 'E-1 '
        db 'F-1 '
        db 'F#1 '
        db 'G-1 '
        db 'G#1 '
        db 'A-1 '
        db 'A#1 '
        db 'B-1 '
        db 'C-2 '
        db 'C#2 '
        db 'D-2 '
        db 'D#2 '
        db 'E-2 '
        db 'F-2 '
        db 'F#2 '
        db 'G-2 '
        db 'G#2 '
        db 'A-2 '
        db 'A#2 '
        db 'B-2 '
        db 'C-3 '
        db 'C#3 '
        db 'D-3 '
        db 'D#3 '
        db 'E-3 '
        db 'F-3 '
        db 'F#3 '
        db 'G-3 '
        db 'G#3 '
        db 'A-3 '
        db 'A#3 '
        db 'B-3 '

;NSTC:  7159090.5 / (428 * 2) = 8363.42hz

PeriodTbl       dw 856,808,762,720,678,640,604,570,538,508,480,453 ; C-1 to B-1
                dw 428,404,381,360,339,320,302,285,269,254,240,226 ; C-2 to B-2
                dw 214,202,190,180,170,160,151,143,135,127,120,113 ; C-3 to B-3

;컴컴컴컴컴컴TEXT MESSAGES컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

MOD_NAME        db 'Module name:'
ORDER_STRING    db 'Order:'
PATTERN_STRING  db 'Pat:'
MOD_ERROR       db 'Unrecognized file format.$'

;컴컴컴훃NINITIALIZED DATA컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

Channel_Data    db 22*8 dup (0)
VolTable        db 256*65 dup (?)
PSP             dd ?
tick            db ?
outputbyte      db ?

OldSeg        dw ?
OldOfs        dd ?

dtaseg          dw ?
dtaofs          dw ?
dirdata         db 43 dup (?)
currentdir      db 64 dup (?)
file_pointer    dd ?
num_files       dw ?
screen_pos      dw ?
pointer         dd ?
pointer2        dw ?
mempointer      dd ?
_offset         dd ?

order_position  db ?
TextPointer     dw ?
LinePointer     db ?
SONG_LENGTH     db ?
NUMBER_OF_PATS  db ?
row             db ?
VideoMem        dd ?

Value           db ?

STRUC   Info
    _Page        db  ?
    __Offset     dw  ?
    _Length      dw  ?
ENDS

DMAInfo    info 1 dup (<>)

STRUC   Smp_info
SAMPLE_NAME     db 22 dup (?)
SAMPLE_LENGTH   dw ?
FINE_TUNE       db ?
VOLUME          db ?
LOOP_START      dw ?
LOOP_LENGTH     dw ?
DUMMY_WORD      dw ?
ENDS

Smp_data        smp_info 31 dup (<>)

MODULE_NAME     db 20 dup (?)                   ;first 20 chars of the file

DMAbuffer       db 6000 dup (?)
FileBuffer      db 10000 dup (?)
SampleBuffer    db 2000000 dup (?)
PatternBuffer   db 1000000 dup (?)
ModHeader       db 1024 dup (?)

PatternPointer  dw ?
OrderPointer    dd ?

SamplePointer   dd 31 dup (?)
ORDER           db 128 dup (?)
