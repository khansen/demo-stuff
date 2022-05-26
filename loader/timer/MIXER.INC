Update_Audio PROC

push    ax bx cx dx ds es di si
mov     ax,@data
mov     ds,ax
mov     es,ax

inc     tick
cmp     tick,6
jnz     update_effect
add     patternpointer,16
inc     row
cmp     row,64
jnz     do_pattern

Change_Pattern:
mov     si,offset Order
mov     bx,order_position
add     si,bx
inc     order_position
mov     al,song_length
xor     ah,ah
inc     ax
cmp     ax,order_position
jnz     new_pattern
mov     order_position,0
jmp     change_pattern
new_pattern:
mov     al,byte ptr [si]
mov     bx,1024
mul     bx
mov     OrderPointer,ax
mov     PatternPointer,0
mov     row,0

do_pattern:
mov     tick,0
mov     si,offset PatternBuffer
add     si,OrderPointer
add     si,PatternPointer
mov     di,offset Channel_Data

;the structure of Channel_Data is as follows:

;        offset  type    description

;        0       word    sample number, pitch
;        2       word    effect and effect parameter
;        4       word    pointer to start of sample
;        6       word    pointer to end of sample
;        8       word    error term (used to scale sample)
;        10      byte    channel active flag
;        11      byte    loop flag (1 if loop)
;        12      word    loop length

mov     cx,4
audio_loop:
mov     ax,word ptr [si+2]
mov     word ptr [di+2],ax
cmp     byte ptr [si+2],0Dh
jnz     no_break
mov     row,63
no_break:
cmp     byte ptr [si],0
je      skip_update
do_update:
mov     ax,word ptr [si]
mov     word ptr [di],ax
mov     word ptr [di+8],0
mov     byte ptr [di+11],0
mov     bl,byte ptr [si]
dec     bl
xor     bh,bh
shl     bl,1
mov     pointer2,si
mov     si,offset samplepointer                 ;find sample offset
add     si,bx
mov     ax,word ptr [si]
mov     word ptr [di+4],ax                   ;store it
mov     word ptr [di+6],ax

mov     si,offset smp_data.VOLUME
shr     bx,1
mov     ax,size smp_info
mul     bx
mov     bx,ax
add     si,bx
mov     dl,byte ptr [si]
mov     byte ptr [di+10],dl
mov     si,offset smp_data.SAMPLE_LENGTH
add     si,bx
mov     ax,word ptr [si]
add     word ptr [di+6],ax
mov     si,offset smp_data.LOOP_LENGTH
add     si,bx
cmp     word ptr [si],0
je      skippy
mov     ax,word ptr [si]
mov     word ptr [di+12],ax
mov     byte ptr [di+11],1
skippy:
mov     si,pointer2
skip_update:
add     di,14
add     si,4
loop    audio_loop

update_effect:
mov     cx,640                                  ;create a 500*4 bytes buffer
mov     di,offset DMAbuffer                     ;where to store processed data
mov     pointer2,di
xor     bh,bh
prepare_mix:
mov     pointer,0                               ;start with data from chn 1
mov     outputbyte,0
mov     value,4
mix_audio:
mov     di,offset Channel_Data
add     di,pointer
cmp     byte ptr [di+10],0
je      skip_mix

mov     bl,byte ptr [di+1]
mov     dx,freqtbl[bx]

add     word ptr [di+8],dx
cmp     word ptr [di+8],32000
jb      skip
inc     word ptr [di+4]
sub     word ptr [di+8],32000
mov     ax,word ptr [di+6]
cmp     word ptr [di+4],ax
jnz     skip
mov     dl,byte ptr [di+10]
mov     byte ptr [di+10],0
cmp     byte ptr [di+11],0
je      skip_mix
mov     byte ptr [di+10],dl
mov     ax,word ptr [di+12]
sub     word ptr [di+4],ax
skip:
mov     ax,word ptr [di+4]
mov     si,offset bigbuffer
add     si,ax                                   ;this is the byte we want
mov     al,byte ptr [si]

cmp     byte ptr [di+2],0Ch
jnz     full_volume
mov     dl,byte ptr [di+3]
mov     byte ptr [di+10],dl
full_volume:

imul    byte ptr [di+10]   ;perform SIGNED multiply by vol. scale
add_to_output:
add     OutputByte,ah         ;then ADD it to the output byte
                                       ;NOTE: add AH register NOT AL
skip_mix:
add     pointer,14
dec     value
jnz     mix_audio
mov     di,pointer2
mov     al,outputbyte
xor     al,128
mov     byte ptr [di],al
inc     pointer2
loop    prepare_mix

mov     cx,640
mov     bx,filehandle
mov     ah,40h
mov     dx,offset dmabuffer
int     21h

end_it:
pop     si di es ds dx cx bx ax
iret
Update_Audio ENDP
