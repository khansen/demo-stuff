DOSSEG
.MODEL SMALL
.386
.STACK 100h
JUMPS
.data

Modident        db 'M.K.',0
FILE_NAME       db 'vist.mod',0
struc_size      dw 0
samplepos       dw ?
sample_number   dw ?

x1              dw ?
x               dw ?
y               db ?

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
mov     ax,0a000h
mov     es,ax
xor     di,di
call    DrawGrid

mov     sample_number,0
mov     struc_size,0
mov     y,5
mov     ch,5

prepare:
mov     x1,0
mov     cl,4
svin_loop:
mov     si,offset smp_data.SAMPLE_LENGTH
add     si,struc_size
mov     dx,word ptr [si]
shl     dx,1
cmp     dx,0
je      done

normal:

;to find the offset in the samplebuffer:
;mov     di,offset samplepointer
;mov     si,offset bigbuffer
;mov     ax,word ptr [di+sample number*2 (0-60)]
;shl     ax,1
;add     si,ax

mov     si,offset samplepointer
add     si,sample_number
mov     ax,word ptr [si]
shl     ax,1
mov     si,offset bigbuffer
add     si,ax
mov     x,0
xor     bx,bx                           ;error term

pixel_loop:
;        color=bitmap[source_index]
;        draw_pixel(screen_x,screen_y)
;        error_term = error_term + destination_height
;        if error_term > source_height
;                error_term = error_term - source_height
;                screen_y = screen_y + 1
;        endif
;        source_index = source_index + 1
;} while screen_y < end_y

add     bx,77
cmp     bx,dx
jb      skip
inc     x
cmp     x,77
je      done
sub     bx,dx
skip:
lodsb
xor     ah,ah
xor     al,128
shr     al,3
add     al,y
shl     ax,8
mov     di,ax
shr     ax,2
add     di,ax
add     di,x
add     di,x1
add     di,2
mov     byte ptr es:[di],3
jmp     pixel_loop
done:
mov     ax,size smp_info
add     struc_size,ax
mov     x,0
add     x1,80
add     sample_number,2
dec     cl
jnz     svin_loop

add     y,40
dec     ch
jnz     prepare

mov     ah,00
int     16h
exit:
mov     ax,3
int     10h
mov     ax,4c00h
int     21h

DrawGrid PROC

mov     bx,5
loopert:
mov     cx,160
mov     ah,7
mov     al,ah
rep     stosw
mov     cl,4
prep:
mov     ch,39
loopert2:
mov     byte ptr es:[di],al
add     di,80
dec     ch
jnz     loopert2
dec     cl
jnz     prep
dec     bx
jnz     loopert
sub     di,80*4
mov     cx,160
mov     ah,7
mov     al,ah
rep     stosw
ret
DrawGrid ENDP

end
