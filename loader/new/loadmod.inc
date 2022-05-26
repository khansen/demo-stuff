LoadMod PROC

mov     ah,3Dh
mov     edx,offset FILE_NAME                    ;open the modfile
xor     al,al                                   ;read only
int     21h
mov     FileHandle,ax                           ;store the filehandle

mov     bx,filehandle
mov     ah,3Fh                                  ;read from file
mov     ecx,1084                                ;read 1084 bytes
mov     edx,offset ModHeader
int     21h

mov     esi,offset ModHeader                    ;source index is ModHeader

;ÄÄÄÄÄÄÄÄÄÄCHECK IF IT REALLY IS A MOD!ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

cmp     dword ptr [esi+1080],'.K.M'     ;check if it's a standard 4chn MOD
je      all_ok
cmp     dword ptr [esi+1080],'NHC6'
je      exit                            ;no support for 6CHN MODs
check_8_chans:
mov     MulRate,11
mov     RowSize,32
mov     Channels,8
cmp     dword ptr [esi+1080],'NHC8'          ;check if it's a 8chn MOD
je      all_ok

mov     ax,3
int     10h
mov     ah,09
mov     edx,offset MOD_ERROR            ;display "Unrecognized file format"
int     21h
mov     ax,4c00h                        ;and quit to DOS
int     21h

all_ok:

mov     edi,offset MODULE_NAME
mov     ecx,10                                  ;write 10*2 bytes
rep     movsw                                   ;do it!

;sample info

mov     dh,31                                   ;get info for 31 samples
xor     ebx,ebx                                 ;ebx used for indexing
store_info:
mov     edi,offset smp_data.SAMPLE_NAME
add     edi,ebx                                 ;sample text for current sample
mov     ecx,11                                  ;22 bytes long
rep     movsw                                   ;store it!
mov     edi,offset smp_data.SAMPLE_LENGTH
add     edi,ebx
movsw                                           ;store sample length in words
mov     edi,offset smp_data.FINE_TUNE
add     edi,ebx
movsb
mov     edi,offset smp_data.VOLUME
add     edi,ebx
movsb
mov     edi,offset smp_data.LOOP_START
add     edi,ebx
movsw             
mov     edi,offset smp_data.LOOP_LENGTH
add     edi,ebx
mov     ax,word ptr [esi]
xchg    ah,al                                   ;make ah=al and al=ah
shl     ax,1                                    ;*2 to get length in bytes
mov     word ptr [edi],ax                       ;store it!
add     edi,2
add     esi,2
add     ebx,size smp_info                       ;next sample
dec     dh                                      ;done all 31 samples yet?
jnz     store_info                              ;if not, do another

lodsb
mov     SONG_LENGTH,al                          ;song length in orders
lodsb                                           ;unused byte

;ÄÄÄÄÄÄÄÄÄÄLOAD ORDER INFORMATIONÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

mov     ch,128                          ;order info is 128 bytes long
mov     edi,offset ORDER                ;this is where we'll store the info
mov     NUMBER_OF_PATS,0
get_order_info:
lodsb                                   ;get a byte (si auto-incremented)
mov     byte ptr [edi],al               ;store it in Order Table
inc     edi                             ;next byte
mov     cl,NUMBER_OF_PATS
cmp     al,cl                           ;is al greater than number_of_pats?
jle     next
mov     NUMBER_OF_PATS,al               ;store as number of physical patterns
next:
dec     ch                              ;done all 128 bytes yet?
jnz     get_order_info                  ;if not, do another

;ÄÄÄÄÄÄÄÄÄÄLOAD PATTERN DATAÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

xor     eax,eax
mov     al,NUMBER_OF_PATS
inc     al                                      ;number of patterns + 1
mov     cl,MulRate
shl     eax,cl                                  ;multiply with 1024
                                                ;(each pattern is 1024 bytes)
load_patterns:
mov     ecx,eax
mov     bx,filehandle                           ;MODfile's handle
mov     ah,3Fh                                  ;read from file
mov     edx,offset PatternBuffer                ;read to the pattern buffer
int     21h                                     ;read ECX bytes

;ÄÄÄÄÄÄÄÄÄÄLOAD SAMPLE DATAÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

xor     eax,eax
mov     ecx,2000000                             ;attempt to read 2 MB
mov     bx,FileHandle
mov     edx,offset SampleBuffer                 ;read to samplebuffer
mov     ah,3Fh
int     21h                                     ;read ECX bytes

mov     ecx,eax
mov     esi,offset SampleBuffer
conv_bytes:
xor     byte ptr [esi],128
inc     esi
loop    conv_bytes

mov     ah,3Eh                                  ;close the file,
int     21h                                     ;we don't need it anymore!

;ÄÄÄÄÄÄÄÄÄÄDECODE THE PATTERN DATAÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

mov     esi,offset PatternBuffer
mov     bh,NUMBER_OF_PATS
inc     bh                              ;loop (number of patterns + 1) times
PatternData_loop:
mov     ecx,Channels                    ;256*4 (1024) bytes per pattern
shl     ecx,6
load_one_pattern:

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Byte 0    Byte 1   Byte 2   Byte 3  ³
;³ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ³
;³aaaaBBBB CCCCCCCCC DDDDeeee FFFFFFFFF³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;aaaaDDDD     = sample number
;BBBBCCCCCCCC = sample period value
;eeee         = effect number
;FFFFFFFF     = effect parameters

mov     al,byte ptr [esi]               ;get the byte containing the upper
mov     bl,al                           ; four bits of the sample number
and     al,11110000b                    ;isolate the upper four bits
mov     ah,byte ptr [esi+2]             ;get the byte containing the lower
shr     ah,4                            ; four bits of the sample number
or      al,ah                           ;add them together
mov     byte ptr [esi],al               ;store sample number in byte 0

mov     ah,bl                           ;get the byte containing the upper
and     ah,00001111b                    ; four bits of the period value
mov     al,byte ptr [esi+1]             ;get the lower eight bits

cmp     ax,0
je      skip_find_note

push    esi ecx                           ;save loop counter and pattern pointer
xor     dl,dl
mov     esi,offset PeriodTbl            ;address table containing amiga values
find_note:
mov     cx,word ptr [esi]               ;get a value from the table
cmp     ax,cx                           ;is it the same?
je      found_note                      ;yep, found it
add     dl,2                            ;nope, it must be higher
add     esi,2                           ;next value
jmp     find_note
found_note:
pop     ecx esi                           ;restore loop counter and pattern pointer
mov     byte ptr [esi+1],dl             ;store note number ((0-35)*2)

skip_find_note:

and     byte ptr [esi+2],00001111b      ;store Effect Number in byte 2 (0-F)

add     esi,4                           ;next note
loop    load_one_pattern
dec     bh                              ;done all patterns yet?
jnz     PatternData_Loop                ;if not, do another

;ÄÄÄÄÄÄÄÄÄÄGET MEMORY POINTER FOR ALL 31 SAMPLESÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

mov     dh,31
xor     eax,eax                         ;clear eax,ebx,ecx
xor     ebx,ebx
xor     ecx,ecx
mov     edi,offset SamplePointer        ;address the table of samplepointers
load_one_sample:
mov     esi,offset smp_data.SAMPLE_LENGTH
add     esi,ebx
mov     ax,word ptr [esi]
xchg    ah,al                           ;swap ah and al
shl     ax,1                            ;*2 to get length in bytes
mov     word ptr [esi],ax               ;store new value
mov     dword ptr [edi],ecx             ;store sample pointer
add     ecx,eax                         ;add eax to get make next samplepointer
add     edi,4                           ;next samplepointer
add     ebx,size smp_info               ;next sample
dec     dh                              ;done all samples yet?
jnz     load_one_sample                 ;if not, do another

ret

LoadMod ENDP
