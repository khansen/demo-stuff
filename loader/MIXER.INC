Update_Audio PROC

inc     tick
mov     al,speed
cmp     tick,al                         ;is it time to update row yet?
jnz     update_effect                   ;if not, update tick based effects
mov     ax,RowSize
add     patternpointer,ax               ;next row in pattern
inc     row
cmp     row,64                          ;reached end of pattern yet?
jnz     do_pattern                      ;if not, do another row

Change_Pattern:
xor     ebx,ebx
mov     bl,order_position
inc     order_position
mov     al,song_length
inc     al
cmp     al,order_position               ;reached end of song yet?
jnz     new_pattern
mov     order_position,0                ;if so, reset order position
jmp     change_pattern
new_pattern:
xor     eax,eax
mov     al,Order[ebx]
cmp     Channels,6
jnz     shift_it2
mov     ebx,1536
mul     ebx
jmp     set_pointer
shift_it2:
mov     cl,MulRate
shl     eax,cl                          ;multiply by 1024 (each pattern is 1024 bytes)
set_pointer:
mov     OrderPointer,eax                ;store pointer
mov     PatternPointer,0                ;reset patternpointer (top of pattern)
mov     row,0                           ;guess!

do_pattern:
mov     tick,0                          ;reset tick
mov     esi,offset PatternBuffer        ;address pattern buffer
add     esi,OrderPointer                ;current order
xor     eax,eax
mov     ax,PatternPointer               ;pointer to current row
add     esi,eax
mov     edi,offset Channel_Data

;the structure of Channel_Data is as follows:

;        offset  type    description

;        0       word    sample number, pitch
;        2       word    effect and effect parameter
;        4       dword   pointer to start of sample
;        8       dword   pointer to end of sample
;        12      word    error term (used to scale sample)
;        14      byte    channel active flag
;        15      byte    loop flag (1 if loop)
;        16      word    loop length
;        18      word    AMIGA period
;        20      word    frequency

mov     ecx,Channels                    ;loop Channels times
audio_loop:
xor     edx,edx
mov     ax,word ptr [esi+2]             ;get effect and effect parameter
mov     word ptr [edi+2],ax             ;store them

cmp     byte ptr [edi+2],09h
jnz     not_skip_offset
mov     dl,byte ptr [edi+3]
shl     dx,8
jmp     check_channel

not_skip_offset:
cmp     byte ptr [edi+2],0Fh
jnz     no_new_speed
mov     dl,byte ptr [edi+3]
cmp     dl,20h
ja      check_channel
mov     speed,dl
jmp     check_channel

no_new_speed:
cmp     byte ptr [esi+2],0Dh            ;effect = 0D?
jnz     check_channel
mov     row,63

check_channel:

cmp     byte ptr [esi],0                ;if no new sample, skip retrig
je      skip_update
do_update:
mov     ax,word ptr [esi]               ;get sample number + pitch
mov     word ptr [edi],ax               ;store them
mov     word ptr [edi+12],0             ;set error term = 0
mov     byte ptr [edi+15],0             ;loop default = 0 (no loop)
xor     ebx,ebx
mov     bl,byte ptr [esi+1]
mov     ax,PeriodTbl[ebx]
mov     word ptr [edi+18],ax

mov     bl,byte ptr [esi]               ;get sample number
dec     bl                              ;decrease to get pointer from 0-30
shl     bl,2                            ;multiply by 4
mov     mempointer,esi
mov     eax,offset samplepointer[ebx]           ;find sample offset
mov     dword ptr [edi+8],eax                   ;store it again
add     eax,edx
mov     dword ptr [edi+4],eax                   ;store it

push    edx ebx eax
;NSTC:  7159090.5 / (428 * 2) = 8363.42hz
xor     edx,edx
xor     ebx,ebx
mov     eax,7159090
mov     bx,word ptr [edi+18]
shl     bx,1
div     ebx
mov     word ptr [edi+20],ax
pop     eax ebx edx

mov     esi,offset smp_data.VOLUME
shr     bl,2                                    ;divide by 4
mov     eax,size smp_info
mul     ebx
mov     ebx,eax
add     esi,ebx
mov     dl,byte ptr [esi]
mov     byte ptr [edi+14],dl
mov     esi,offset smp_data.SAMPLE_LENGTH
add     esi,ebx
xor     eax,eax
mov     ax,word ptr [esi]
add     dword ptr [edi+8],eax
mov     esi,offset smp_data.LOOP_LENGTH
add     esi,ebx
cmp     word ptr [esi],0
je      skippy
mov     ax,word ptr [esi]
mov     word ptr [edi+16],ax
mov     byte ptr [edi+15],1
skippy:
mov     esi,mempointer
skip_update:
add     edi,22
add     esi,4
loop    audio_loop

update_effect:
cmp     tick,0
je      mix_start

mov     ecx,Channels
mov     edi,offset Channel_Data                 ;buffer containing chn info

;update tick based effects: 1,2,3,4,5,6,7,A

update_effect2:
cmp     byte ptr [edi+2],0Ah                    ;command = 0Ah?
je      volume_slide                            ;if not, next channel
cmp     byte ptr [edi+2],06h
jnz     next_channel
volume_slide:
cmp     byte ptr [edi+3],10h                    ;increase or decrease volume?
jae     inc_volume
mov     dl,byte ptr [edi+3]
cmp     byte ptr [edi+14],dl
jl      next_channel
sub     byte ptr [edi+14],dl
jmp     next_channel
inc_volume:
mov     dl,byte ptr [edi+3]
cmp     byte ptr [edi+14],60
jae     next_channel
shr     dl,4
add     byte ptr [edi+14],dl

next_channel:
add     edi,22
loop    update_effect2

mix_start:
mov     ecx,640                                 ;number of bytes to mix
mov     edi,offset DMAbuffer                    ;where to store processed data
mov     mempointer,edi                          ;save this pointer
xor     ebx,ebx
prepare_mix:
mov     pointer,0                               ;start with data from chn 1
mov     outputbyte,0
mov     eax,Channels
mov     value,al                                 ;four channels
mix_audio:
mov     edi,offset Channel_Data                 ;buffer containing chn info
add     edi,pointer                             ;current channel
cmp     byte ptr [edi+14],0                     ;channel active?
je      skip_mix                                ;nope, skip mix

mov     dx,word ptr [edi+20]                    ;dx now holds frequency

add     word ptr [edi+12],dx                    ;add frequency to error term
cmp     word ptr [edi+12],32000                 ;was there an overflow?
jb      skip                                    ;if not, don't increase
inc     dword ptr [edi+4]                       ;increase samplepointer
sub     word ptr [edi+12],32000                 ;subtract mixfreq
mov     edx,dword ptr [edi+8]
cmp     dword ptr [edi+4],edx                   ;reached end of sample?
jnz     skip
mov     dl,byte ptr [edi+14]
mov     byte ptr [edi+14],0                     ;set channel = not active
cmp     byte ptr [edi+15],0                     ;is the sample looped?
je      skip_mix                                ;nope
mov     byte ptr [edi+14],dl                    ;yes, restore volume
mov     ax,word ptr [edi+16]
sub     dword ptr [edi+4],eax                   ;and subtract loop length
skip:
mov     esi,offset SampleBuffer
add     esi,dword ptr [edi+4]                   ;this is the byte we want
mov     al,byte ptr [esi]                       ;grab it

cmp     byte ptr [edi+2],0Ch                    ;effect 0C?
jnz     full_volume
mov     dl,byte ptr [edi+3]                     ;yes, set new volume
mov     byte ptr [edi+14],dl                    ;do it!
full_volume:

imul    byte ptr [edi+14]               ;perform SIGNED multiply by vol. scale
add_to_output:
add     OutputByte,ah                   ;then ADD it to the output byte
                                        ;NOTE: add AH register NOT AL
skip_mix:
add     pointer,22
dec     value                                   ;done all 4 channels yet?
jnz     mix_audio                               ;if not, do another
mov     edi,mempointer                          ;restore pointer to buffer
mov     al,outputbyte                           ;get the outputbyte
xor     al,128                                  ;unsign it (range 0-255)
mov     byte ptr [edi],al                       ;store it in buffer
inc     mempointer                              ;increase DMAbuffer pointer
loop    prepare_mix                             ;loop MixLength times

mov     ecx,640
mov     bx,filehandle
mov     edx,offset DMAbuffer
mov     ah,40h
int     21h

end_it:
ret
Update_Audio ENDP
