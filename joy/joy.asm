dosseg
.model small
.stack 100h

JOYSTICKPORT    EQU     201h

.data

found   db 'Joystick/gamepad detected.$'
n_found db 'No joystick/gamepad found!',13,10,'$'
left    db 'left  '
right   db 'right '
middle  db 'middle'
count   dw ?

.code

mov     ax,@data
mov     ds,ax

mov     ax,3
int     10h

mov     dx,JOYSTICKPORT
mov     count,0
out     dx,al
check_joy:
inc     count
cmp     count,0FFFFh
je      not_found
in      al,dx
and     al,00000001b
jnz     check_joy

mov     ah,09
mov     dx,offset found
int     21h

mov     ah,00
int     16h

mov     ax,3
int     10h

mov     ax,0b800h
mov     es,ax

;Joystick position vs. loop count
;
;     x,y--------------------
;     8,8|      330,8       | 980,8
;        |                  |
;        |                  |    delta 330
;        |                  |
;   8,330|      330,330     | 980,330 (y centered)
;        |                  |
;        |                  |    delta 650
;        |                  |
;   8,980|      330,980     | 980,980
;        --------------------
;            (x centered)

;                      ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿
;                      ³ 7 ³ 6 ³ 5 ³ 4 ³ 3 ³ 2 ³ 1 ³ 0 ³
;                      ÀÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÁÄÄÄÙ
;                        ³   ³   ³   ³   ³   ³   ³   ³
;Joystick B, Button 2 ÄÄÄÙ   ³   ³   ³   ³   ³   ³   ÀÄÄÄ Joystick A, X Axis
;Joystick B, Button 1 ÄÄÄÄÄÄÄÙ   ³   ³   ³   ³   ÀÄÄÄÄÄÄÄ Joystick A, Y Axis
;Joystick A, Button 2 ÄÄÄÄÄÄÄÄÄÄÄÙ   ³   ³   ÀÄÄÄÄÄÄÄÄÄÄÄ Joystick B, X Axis
;Joystick A, Button 1 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Joystick B, Y Axis
;
;Reading the status of the joystick buttons is fairly simple. Just read the
;byte from the joystick port and check the status of the appropriate bit. A
;clear bit (0) means the button is pressed, a set bit (1) means it is not
;pressed. Note that the button's are not hardware debounced. Each time a
;button is pressed it's bit may "bounce" between 0 and 1 a couple of times.
;
;Reading the position of the stick positions is a bit more complicated. You
;must first write a dummy byte (any value will do) to the joystick port. This
;will set each axis bit to 1. You must then time how long the bit takes to
;drop back to 0, this time is roughly proportional to the position of
;the joystick axis (see Steve McGowan's discussion below).

readjoypos:

xor     di,di
in      al,60h
cmp     al,1
je      exit

    mov word ptr count, 0
    cli          ; Disable interrupts so they don't interfere with timing }
    mov dx, JOYSTICKPORT   ;Write dummy byte to joystick port }
    out dx, al
    @joystickloop:
    inc count              ; Add one to count }
    in al, dx              ; Get joystick port value }
    and al,00000001b       ; Test the appropriate bit }
    jnz @joystickloop
    @done:
    sti                    ; Enable interrupts again }

cmp     count,20
jle     left2
cmp     count,900
jae     right2
mov     cx,6
mov     ah,30
lea     si,middle
loop1:
lodsb
stosw
loop    loop1
jmp     readjoypos
left2:
mov     cx,6
mov     ah,30
lea     si,left
loop2:
lodsb
stosw
loop    loop2
jmp     readjoypos

right2:
mov     cx,6
mov     ah,30
lea     si,right
loop3:
lodsb
stosw
loop    loop3
jmp     readjoypos

not_found:
mov     ah,09
mov     dx,offset n_found
int     21h

exit:
mov     ax,4c00h
int     21h
end
