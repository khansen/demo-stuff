IDEAL
MODEL tiny
P386N

INV_0           EQU 00000000b
INV_1           EQU 10000001b
INV_2           EQU 10100010b
INV_3           EQU 01000011b
INV_4           EQU 11000100b

DATASEG

score           dw 0

enemy_xpos      db 0
enemy_ypos      db 0
enemy_speed     db 1

num_invaders    db 8*8

_256x240        dw 03F01h
                dw 04002h
                dw 04E04h
                dw 09605h
                dw 00D06h
                dw 03E07h
                dw 04109h
                dw 0EA10h
                dw 0AC11h
                dw 0DF12h
                dw 02013h
                dw 04014h
                dw 0E715h
                dw 00616h
                dw 0E317h

level_data      db INV_1,INV_1,INV_1,INV_1,INV_1,INV_1,INV_1,INV_1
                db INV_1,INV_1,INV_1,INV_1,INV_1,INV_1,INV_1,INV_1
                db INV_2,INV_2,INV_2,INV_2,INV_2,INV_2,INV_2,INV_2
                db INV_2,INV_2,INV_2,INV_2,INV_2,INV_2,INV_2,INV_2
                db INV_3,INV_3,INV_3,INV_3,INV_3,INV_3,INV_3,INV_3
                db INV_3,INV_3,INV_3,INV_3,INV_3,INV_3,INV_3,INV_3
                db INV_4,INV_4,INV_4,INV_4,INV_4,INV_4,INV_4,INV_4
                db INV_4,INV_4,INV_4,INV_4,INV_4,INV_4,INV_4,INV_4

ship            dw 0000001111000000b
                dw 0000001111000000b
                dw 0000001111000000b
                dw 0000001111000000b
                dw 0000011111100000b
                dw 0000111111110000b
                dw 0001111111111000b
                dw 0011111111111100b
                dw 0111111111111110b
                dw 0111111111111110b
                dw 0111111111111110b
                dw 0111111111111110b
                dw 0111111111111110b
                dw 0111111111111110b
                dw 0001111111111000b
                dw 0000001111000000b

invaders        dw 0000000000000000b
                dw 0000000000000000b
                dw 0000000000000000b
                dw 0000000000000000b
                dw 0000000000000000b
                dw 0000000000000000b
                dw 0000000000000000b
                dw 0000000000000000b
                dw 0000000000000000b
                dw 0000000000000000b
                dw 0000000000000000b
                dw 0000000000000000b
                dw 0000000000000000b
                dw 0000000000000000b
                dw 0000000000000000b
                dw 0000000000000000b

                dw 0000000000000000b
                dw 0000000000000000b
                dw 0110000110000110b
                dw 0011001111001100b
                dw 0111111111111110b
                dw 0111011111101110b
                dw 0111101111011110b
                dw 0011111111111100b
                dw 0001111111111000b
                dw 0000110110110000b
                dw 0001100110011000b
                dw 0011000110001100b
                dw 0110000000000110b
                dw 0110000000000110b
                dw 0011000000001100b
                dw 0000000000000000b

                dw 0000000000000000b
                dw 0000000000000000b
                dw 0000011111100000b
                dw 0001111111111000b
                dw 0011111111111100b
                dw 0011111111111100b
                dw 0011001111001100b
                dw 0011111111111100b
                dw 0011111111111100b
                dw 0000001111000000b
                dw 0001111111111000b
                dw 0001100000011000b
                dw 0011000000001100b
                dw 0011000000001100b
                dw 0011000000001100b
                dw 0000000000000000b

                dw 0000000000000000b
                dw 0000000000000000b
                dw 0011000000001100b
                dw 0001111111111000b
                dw 0000111111110000b
                dw 0000111111110000b
                dw 0000111111110000b
                dw 0001111111111000b
                dw 0011101111011100b
                dw 0011111111111100b
                dw 0001111111111000b
                dw 0000111111110000b
                dw 0001100000011000b
                dw 0011000000001100b
                dw 0110000000000110b
                dw 0000000000000000b

                dw 0000000000000000b
                dw 0000000000000000b
                dw 0011000000001100b
                dw 0011000000001100b
                dw 0011000000001100b
                dw 0001100000011000b
                dw 0000110000110000b
                dw 0000011001100000b
                dw 0001111111111000b
                dw 0011101111011100b
                dw 0011100110011100b
                dw 0001111111111000b
                dw 0000111111110000b
                dw 0001011111101000b
                dw 0010001111000100b
                dw 0000000000000000b

fire_status     db 0
fire_pos_x      db 0
fire_pos_y      db 0

ship_pos        db 128-8

CODESEG

org 100h

start:

mov     al,13h
int     10h

mov     ax,cs
mov     ds,ax

push    0A000h
pop     es

;*****************************************************************************
;                           TWEAK MODE TO 256x240
;*****************************************************************************

mov     dx,3C4h          ; Sequencer Address Register

; === Set dot clock & scanning rate ===
mov     ax,0100h
out     dx,ax            ; Stop sequencer while setting Misc Output

mov     dx,3C2h
mov     al,0e3h          ; 0e3h = 227d = 11100011b
out     dx,al            ; Select 25 MHz dot clock & 60 Hz scanning rate

mov     dx,3C4h
mov     ax,0300h         ; Index 00h --- 03h = 3d = 00000011b
out     dx,ax            ; Undo reset (restart sequencer)

; === Remove write protection ===
mov     dx,3D4h
mov     al,11h           ; VSync End contains write protect bit (bit 7)
out     dx,al
inc     dx               ; Crt Controller Data register
in      al,dx
and     al,01111111b     ; Remove write protect on various CrtC registers
out     dx,al            ; (bit 7 is 0)

mov     dx,3C4h
mov     ax,0E04h
out     dx,ax
 
mov     dx,3D4h
mov     cl,15
mov     si,offset _256x240              ; CHANGE THIS TO _256x256 or _256x240
Send_Values:
lodsw
out     dx,ax
dec     cl
jnz     Send_Values

;
;
;

main_loop:

cmp     [enemy_ypos],240-20-128
je      exit

mov     ah,[enemy_ypos]
mov     al,[enemy_xpos]
mov     di,ax
xor     ah,ah
mov     si,offset level_data
mov     ch,8
draw_invaders:
mov     cl,8
inner_loop:
lodsb
push    si
mov     si,offset invaders
mov     dl,al
and     al,7
shr     dl,4
shl     al,5
add     si,ax
call    Draw_16x16_Sprite
pop     si
add     di,16
dec     cl
jnz     inner_loop
add     di,(256*15)+128
dec     ch
jnz     draw_invaders

mov     ax,220*256
add     al,[ship_pos]
mov     di,ax
mov     si,offset ship
mov     dl,110b
call    Draw_16x16_Sprite

call    Update_Fire

; wait for vertical retrace

    mov     dx,3dah
Vrt:
    in      al,dx
    test    al,1000b        
    jnz     Vrt            
NoVrt:
    in      al,dx
    test    al,1000b         
    jz      NoVrt         

; do some misc. stuff

mov     al,[enemy_speed]
add     [enemy_xpos],al
cmp     [enemy_xpos],0
je      change_enemy_direction
cmp     [enemy_xpos],256-128
je      change_enemy_direction
jmp     read_kbd

change_enemy_direction:
neg     [enemy_speed]
add     [enemy_ypos],2

read_kbd:

; read keyboard

in      al,60h

cmp     al,4Bh
je      ship_left
cmp     al,4Dh
je      ship_right
cmp     al,2
je      ship_fire
cmp     al,1
je      exit
jmp     main_loop

ship_left:
cmp     [ship_pos],0
je      main_loop
dec     [ship_pos]
jmp     main_loop

ship_right:
cmp     [ship_pos],255-16
je      main_loop
inc     [ship_pos]
jmp     main_loop

ship_fire:
cmp     [fire_status],1
je      main_loop
mov     [fire_status],1
mov     al,[ship_pos]
add     al,8
mov     [fire_pos_x],al
mov     [fire_pos_y],218
jmp     main_loop

exit:

mov     ax,3
int     10h

int     20h

PROC    Update_Fire

cmp     [fire_status],0
je      @@99

mov     ah,[fire_pos_y]
mov     al,[fire_pos_x]
mov     di,ax
mov     [byte ptr es:di],15
mov     [byte ptr es:di+256],15
mov     [byte ptr es:di+512],0
mov     [byte ptr es:di+768],0
sub     [fire_pos_y],2
jz      @@fire_end

cmp     [byte ptr es:di-256],0
je      @@99

sub     ah,[enemy_ypos]
sub     al,[enemy_xpos]

; collision detection

shr     ah,4                            ; Y = Y/16
shl     ah,3                            ; Y = Y*8
shr     al,4                            ; X = X/16
xor     bh,bh
mov     bl,ah
add     bl,al                           ; BX = pointer to enemy slot
mov     [level_data + bx],INV_0
dec     [num_invaders]
jz      exit

@@fire_end:
mov     [fire_status],0
mov     [byte ptr es:di],0
mov     [byte ptr es:di+256],0

@@99:
ret

ENDP    Update_Fire

PROC    Draw_16x16_Sprite

; DL = upper 3 bits of sprite

push    cx di
mov     ch,16
@@10:
mov     ax,[word ptr si]
mov     cl,16
@@20:
rol     ax,1
mov     bl,al
and     bl,1
jz      @@30
or      bl,dl
@@30:
mov     [byte ptr es:di],bl
inc     di
dec     cl
jnz     @@20
add     si,2
add     edi,256-16
dec     ch
jnz     @@10
pop     di cx

ret
ENDP    Draw_16x16_Sprite

end     start
