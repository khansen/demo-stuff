LoadMod PROC

mov     ax,@data
mov     ds,ax
mov     es,ax

mov     ah,3Dh
mov     dx,offset FILE_NAME
xor     al,al
int     21h

mov     bx,ax

mov     ah,3Fh
mov     cx,1084
mov     dx,offset BigBuffer
int     21h

push    bx

mov     si,offset BigBuffer
mov     di,offset MODULE_NAME
mov     cx,10
rep     movsw

;sample info

mov     dh,31
xor     bx,bx
store_info:
mov     di,offset smp_data.SAMPLE_NAME
add     di,bx
mov     cx,11
rep     movsw
mov     di,offset smp_data.SAMPLE_LENGTH
add     di,bx
movsw
mov     di,offset smp_data.FINE_TUNE
add     di,bx
movsb
mov     di,offset smp_data.VOLUME
add     di,bx
movsb
mov     di,offset smp_data.LOOP_START
add     di,bx
movsw             
mov     di,offset smp_data.LOOP_LENGTH
add     di,bx
mov     ax,word ptr [si]
xchg    ah,al
shl     ax,1
mov     word ptr [di],ax
add     di,2
add     si,2
add     bx,size smp_info
dec     dh
jnz     store_info

lodsb
mov     SONG_LENGTH,al
lodsb                                   ;unused byte

;ÄÄÄÄÄÄÄÄÄÄLOAD ORDER INFORMATIONÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

mov     ch,128
mov     di,offset ORDER
mov     NUMBER_OF_PATS,0
get_order_info:
lodsb
mov     byte ptr [di],al
inc     di
mov     cl,NUMBER_OF_PATS
cmp     al,cl
jle     next
mov     NUMBER_OF_PATS,al
next:
dec     ch
jnz     get_order_info

;ÄÄÄÄÄÄÄÄÄÄCHECK IF IT REALLY IS A MOD!ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

mov     di,offset ModIdent
mov     cx,2
repe    cmpsw
jcxz    all_ok

mov     ax,3
int     10h
mov     ah,09
mov     dx,offset MOD_ERROR
int     21h
mov     ax,4c00h
int     21h

all_ok:

;ÄÄÄÄÄÄÄÄÄÄLOAD PATTERN DATAÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

mov     bl,NUMBER_OF_PATS
inc     bl
cmp     bl,19
ja      exit
xor     bh,bh
mov     ax,1024
mul     bx
mov     cx,ax

pop     bx
mov     ah,3Fh
mov     dx,offset PatternBuffer
int     21h

push    bx

mov     si,offset PatternBuffer
mov     bh,NUMBER_OF_PATS
inc     bh
PatternData_loop:
mov     cx,256
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

;store Sample Number in byte 0

mov     al,byte ptr [si]
mov     bl,al
and     al,11110000b
mov     ah,byte ptr [si+2]
shr     ah,4
or      al,ah
mov     ah,byte ptr [si]
mov     byte ptr [si],al

;store Note Value in byte 1

mov     ah,bl
and     ah,00001111b
mov     al,byte ptr [si+1]

cmp     ax,0
je      skip_find_note

push    si cx
xor     dl,dl
mov     si,offset PeriodTbl
find_note:
mov     cx,word ptr [si]
cmp     ax,cx
je      found_note
add     dl,2
add     si,2
jmp     find_note
found_note:
pop     cx si
mov     byte ptr [si+1],dl

skip_find_note:

;store Effect Number in byte 2

and     byte ptr [si+2],00001111b

add     si,4
loop    load_one_pattern
dec     bh
jnz     PatternData_Loop

;ÄÄÄÄÄÄÄÄÄÄLOAD SAMPLE DATAÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

pop     bx

mov     dx,offset BigBuffer
mov     cx,40000
mov     ah,3Fh
int     21h
cmp     ax,40000
je      exit

mov     ah,3Eh
int     21h

mov     dh,31
xor     bx,bx
xor     cx,cx
mov     di,offset SamplePointer
load_one_sample:
mov     si,offset smp_data.SAMPLE_LENGTH
add     si,bx
mov     ax,word ptr [si]
xchg    ah,al
shl     ax,1
mov     word ptr [si],ax
mov     word ptr [di],cx
add     cx,ax
add     di,2
add     bx,size smp_info
dec     dh
jnz     load_one_sample

;to get the sample length:
;mov    si,offset smp_data.SAMPLE_LENGTH
;add    si,(size smp_info)*sample number (0-30)

;to find the offset in the samplebuffer:
;mov     di,offset samplepointer
;mov     si,offset bigbuffer
;mov     ax,word ptr [di+sample number*2 (0-60)]
;shl     ax,1
;add     si,ax
ret
LoadMod ENDP
