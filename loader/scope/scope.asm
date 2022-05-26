DOSSEG
.MODEL SMALL
.386
.STACK 100h
JUMPS
.data

Modident        db 'M.K.',0
FILE_NAME       db 'vist.mod',0
pointer         dw ?

x               dw ?

order_position  dw ?
TextPointer     dw ?
LinePointer     db ?
SONG_LENGTH     db ?
NUMBER_OF_PATS  db ?
row             db ?

Smp_info STRUC
SAMPLE_NAME     db 22 dup (?)
SAMPLE_LENGTH   dw ?
FINE_TUNE       db ?
VOLUME          db ?
LOOP_START      dw ?
LOOP_LENGTH     dw ?
Smp_info ENDS

Smp_data        smp_info 31 dup (<>)

MODULE_NAME     db 20 dup (?)                   ;first 20 chars of the file

BigBuffer       db 40000 dup (?)
PatternBuffer   db 20000 dup (?)
PatternPointer  dw ?
ORDER           db 128 dup (?)
OrderPointer    dw ?

SamplePointer   dw 31 dup (?)

.code

mov     ax,3h
int     10h
mov     ax,@data
mov     ds,ax
mov     es,ax

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

;ÄÄÄÄÄÄÄÄÄÄÄÄERRORSÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

not_mod:
mov     ax,4c00h
int     21h

;ÄÄÄÄÄÄÄÄÄÄÄOPEN FILEÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

continue:

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
movsw
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

;ÄÄÄÄÄÄÄÄÄÄLOAD SAMPLE DATAÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

mov     dx,offset BigBuffer
mov     cx,40000
mov     ah,3Fh
int     21h

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
mov     word ptr [si],ax
mov     word ptr [di],cx
add     cx,ax
add     di,2
add     bx,size smp_info
dec     dh
jnz     load_one_sample

mov     ax,13h
int     10h

mov     si,offset smp_data.SAMPLE_LENGTH
mov     dx,word ptr [si]
shl     dx,1
mov     pointer,0
mov     x,0

svin_loop:
mov     si,offset bigbuffer
add     si,pointer
mov     di,offset patternbuffer
mov     cx,320
pixel_loop:
mov     al,byte ptr [si]
xor     al,128
shr     al,1
mov     byte ptr [di],al
inc     di
inc     si
loop    pixel_loop

done:
push    es
mov     ax,0a000h
mov     es,ax
xor     di,di
xor     ax,ax
mov     cx,32000
rep     stosw

mov     si,offset patternbuffer
mov     cx,320
disp_loop:
lodsb
mov     ah,ah
shl     ax,8
mov     di,ax
shr     ax,2
add     di,ax
add     di,x
mov     byte ptr es:[di],3
inc     x
loop    disp_loop
pop     es

add     pointer,320
mov     x,0
mov     ah,00
int     16h
cmp     al,27
jnz     svin_loop
exit:
mov     ax,3
int     10h
mov     ax,4c00h
int     21h

end
