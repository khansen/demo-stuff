dosseg
.model small
.stack 100h

JOYSTICKPORT    EQU     201h

.data

count   dw ?

.code

mov     ax,3
int     10h

mov     ax,@data
mov     ds,ax
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

;All joystick programming is done via port 201h.
;
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

    mov dx, JOYSTICKPORT   ;Write dummy byte to joystick port }

readjoybutton:

in      al,60h
cmp     al,1
je      exit

xor     di,di

in      al,dx
and     al,00110000b
je      both_buttons
cmp     al,00010000b
je      B_button
cmp     al,00100000b
je      A_button

xor     ax,ax
stosw
jmp     readjoybutton

a_button:
mov     ah,30
mov     al,'A'
stosw
jmp     readjoybutton

b_button:
mov     ah,30
mov     al,'B'
stosw
jmp     readjoybutton

both_buttons:
mov     ah,30
mov     al,'C'
stosw
jmp     readjoybutton

exit:
mov     ax,4c00h
int     21h
end
