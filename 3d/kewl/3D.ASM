IDEAL
P386N
MODEL FLAT
STACK 1000h
JUMPS

X       EQU 0
Y       EQU 4
Z       EQU 8

XCENTER EQU 160
YCENTER EQU 100

DATASEG

video_mem       dd 0A0000h
keyb_buffer     dd 000400h

include "sincos.dw"

Distance        dd 256

Top_X           dd 0
Mid_X           dd 0
Bot_X           dd 0

Top_Y           dd 0
Mid_Y           dd 0
Bot_Y           dd 0

X1_Fixed        dd 0
X2_Fixed        dd 0

Delta_L         dd 0
Delta_R         dd 0

Xangle          dd 0
Yangle          dd 0
Zangle          dd 0

color           db 0

base_object     dd 0,40,0
                dd -40,-40,100
                dd 40,-40,100

                dd 0,40,0
                dd -40,-40,-100
                dd 40,-40,-100

                dd 0,40,0
                dd 40,-40,-100
                dd 40,-40,100

                dd 0,40,0
                dd -40,-40,-100
                dd -40,-40,100

rotated_object  dd 3*12 dup (?)

_2D_object      dd 2*12 dup (?)

virtual_screen  db 320*200 dup (?)

CODESEG

start:

mov     ax,13h
int     10h

mov     ax,0EE02h
int     31h

sub     [video_mem],ebx
sub     [keyb_buffer],ebx

main_loop:

mov     edi,offset virtual_screen
xor     eax,eax
mov     ecx,64000/4
rep     stosd

mov     esi,offset base_object
mov     edi,offset rotated_object
mov     ecx,12
rotate_point:
push    ecx
mov     ecx,[Xangle]
call    RotYaxis
add     esi,3*4
add     edi,3*4
pop     ecx
dec     ecx
jnz     rotate_point

mov     esi,offset rotated_object
mov     edi,offset _2D_object
mov     ecx,12
draw_point:
push    ecx
call    ConvertPoint
add     esi,3*4
add     edi,2*4
pop     ecx
dec     ecx
jnz     draw_point

mov     esi,offset _2D_object
mov     [color],4
call    DrawPoly
mov     [color],5
add     esi,8*3
call    DrawPoly
mov     [color],6
add     esi,8*3
call    DrawPoly
mov     [color],7
add     esi,8*3
call    DrawPoly

mov     esi,offset virtual_screen
mov     edi,[video_mem]
mov     ecx,64000/4
rep     movsd

call    waitvrt

mov     edi,[keyb_buffer]
mov     ax,[word ptr edi + 1Ah]
mov     [word ptr edi + 1Ch],ax

inc     [xangle]
cmp     [xangle],360
jnz     no_reset
mov     [xangle],0
no_reset:
in      al,60h
cmp     al,48h
je      closer
cmp     al,50h
je      away
dec     al
jz      exit
jmp     main_Loop

closer:
dec     [distance]
jmp     main_loop
away:
inc     [distance]
jmp     main_loop

exit:
mov     ax,3
int     10h

mov     ax,4c00h
int     21h

PROC    RotXaxis

; rotate around X axis
; --------------------
;

push    ecx edx ebp

mov     ebx,[cosine + ecx*4]
mov     ecx,[sine + ecx*4]

mov     eax,[dword ptr esi + Y]
imul    ebx                                     ; Y * COS(Xangle)
mov     ebp,eax
mov     eax,[dword ptr esi + Z]
imul    ecx                                     ; Z * SIN(angle)
sub     ebp,eax
sar     ebp,8
mov     [dword ptr edi + Y],ebp

mov     eax,[dword ptr esi + Y]
imul    ecx                                     ; Y * SIN(angle)
mov     ebp,eax
mov     eax,[dword ptr esi + Z]
imul    ebx                                     ; Z * COS(angle)
add     ebp,eax
sar     ebp,8
mov     [dword ptr edi + Z],ebp

mov     eax,[dword ptr esi + X]
mov     [dword ptr edi + X],eax

pop     ebp edx ecx

ret
ENDP    RotXaxis

PROC    RotYaxis

; rotate around Y axis
; --------------------
;

push    ecx edx ebp

mov     ebx,[cosine + ecx*4]
mov     ecx,[sine + ecx*4]

mov     eax,[dword ptr esi + X]
imul    ebx                                     ; X * COS(angle)
mov     ebp,eax
mov     eax,[dword ptr esi + Z]
imul    ecx                                     ; Z * SIN(angle)
sub     ebp,eax
sar     ebp,8
mov     [dword ptr edi + X],ebp

mov     eax,[dword ptr esi + X]
imul    ecx                                     ; X * SIN(angle)
mov     ebp,eax
mov     eax,[dword ptr esi + Z]
imul    ebx                                     ; Z * COS(angle)
add     ebp,eax
sar     ebp,8
mov     [dword ptr edi + Z],ebp

mov     eax,[dword ptr esi + Y]
mov     [dword ptr edi + Y],eax

pop     ebp edx ecx

ret
ENDP    RotYaxis

PROC    RotZaxis

; rotate around Z axis
; --------------------
;

push    ecx edx ebp

mov     ebx,[cosine + ecx*4]
mov     ecx,[sine + ecx*4]

mov     eax,[dword ptr esi + X]
imul    ebx                                     ; X * COS(angle)
mov     ebp,eax
mov     eax,[dword ptr esi + Y]
imul    ecx                                     ; Y * SIN(angle)
sub     ebp,eax
sar     ebp,8
mov     [dword ptr edi + X],ebp

mov     eax,[dword ptr esi + X]
imul    ecx                                     ; X * SIN(angle)
mov     ebp,eax
mov     eax,[dword ptr esi + Y]
imul    ebx                                     ; Y * COS(angle)
add     ebp,eax
sar     ebp,8
mov     [dword ptr edi + Y],ebp

mov     eax,[dword ptr esi + Z]
mov     [dword ptr edi + Z],eax

pop     ebp edx ecx

ret
ENDP    RotZaxis

PROC    ConvertPoint

; Converts a set of 3D coordinates (X,Y,Z)
; to a 2D screen offset
; ----------------------------------------
;

mov     eax,[dword ptr esi + Y]
neg     eax                             ; because the Y axis grows UPWARDS
mov     edx,256
imul    edx                             ; multiply by 256
mov     ecx,[Distance]
sub     ecx,[dword ptr esi + Z]
idiv    ecx                             ; divide by distance
add     eax,YCENTER                     ; center coordinate on screen
mov     [dword ptr edi + Y],eax

mov     eax,[dword ptr esi + X]
mov     edx,256
imul    edx                             ; multiply by 256
idiv    ecx                             ; divide by distance
add     eax,XCENTER                     ; center coordinate on screen
mov     [dword ptr edi + X],eax

ret
ENDP    ConvertPoint

PROC    DrawPoly

; ESI = pointer to three sets of (X,Y) 2D coordinates

mov     eax,[dword ptr esi + Y]         ; first Y coordinate
mov     ebx,[dword ptr esi + Y + 8]     ; second Y coordinate
cmp     eax,ebx                         ; is Y1 < Y2?
jb      @@top                           ; yep ...
mov     [Top_Y],ebx                     ; no, store Y2 as top Y
mov     [Bot_Y],eax                     ; and Y1 as bottom Y
mov     eax,[dword ptr esi + X + 8]
mov     [Top_X],eax
mov     eax,[dword ptr esi + X]
mov     [Bot_X],eax
jmp     @@p3
@@top:
mov     [Top_Y],eax                     ; store Y1 as top Y
mov     [Bot_Y],ebx                     ; and Y2 as bottom Y
mov     eax,[dword ptr esi + X]
mov     [Top_X],eax
mov     eax,[dword ptr esi + X + 8]
mov     [Bot_X],eax
@@p3:
mov     eax,[dword ptr esi + Y + 16]    ; third Y coordinate
cmp     eax,[Top_Y]
jb      @@smallest
cmp     eax,[Bot_Y]
ja      @@biggest
mov     [Mid_Y],eax
mov     eax,[dword ptr esi + X + 16]
mov     [Mid_X],eax
jmp     @@next
@@smallest:
mov     ebx,[Top_Y]
mov     [Mid_Y],ebx
mov     [Top_Y],eax
mov     eax,[Top_X]
mov     [Mid_X],eax
mov     eax,[dword ptr esi + X + 16]
mov     [Top_X],eax
jmp     @@next
@@biggest:
mov     ebx,[Bot_Y]
mov     [Mid_Y],ebx
mov     [Bot_Y],eax
mov     eax,[Bot_X]
mov     [Mid_X],eax
mov     eax,[dword ptr esi + X + 16]
mov     [Bot_X],eax
@@next:

mov     eax,[Mid_X]
sub     eax,[Top_X]
mov     ebx,[Mid_Y]
sub     ebx,[Top_Y]
inc     ebx
mov     edx,128
imul    edx
idiv    ebx
mov     [Delta_L],eax

mov     eax,[Top_X]
shl     eax,7
mov     [X1_Fixed],eax
mov     [X2_Fixed],eax

mov     eax,[Bot_X]
sub     eax,[Top_X]
mov     ebx,[Bot_Y]
sub     ebx,[Top_Y]
mov     edx,128
imul    edx
idiv    ebx
mov     [Delta_R],eax

mov     edi,offset virtual_screen
mov     eax,[Top_Y]
shl     eax,8
add     edi,eax
shr     eax,2
add     edi,eax
mov     edx,edi

mov     ebp,[Mid_Y]
sub     ebp,[Top_Y]
inc     ebp
@@loop1:
mov     edi,edx
mov     eax,[X1_Fixed]
shr     eax,7
mov     ecx,[X2_Fixed]
shr     ecx,7
cmp     ecx,eax
jae     @@ok
xchg    eax,ecx
@@ok:
add     edi,eax
sub     ecx,eax
inc     ecx
mov     al,[color]
rep     stosb

mov     eax,[Delta_L]
add     [X1_Fixed],eax
mov     eax,[Delta_R]
add     [X2_Fixed],eax

add     edx,320
dec     ebp
jnz     @@loop1

push    edx

mov     eax,[Bot_X]
sub     eax,[Mid_X]
mov     ebx,[Bot_Y]
sub     ebx,[Mid_Y]
inc     ebx
mov     edx,128
imul    edx
idiv    ebx
mov     [Delta_L],eax

pop     edx

mov     eax,[Mid_X]
shl     eax,7
mov     [X1_Fixed],eax

mov     ebp,[Bot_Y]
sub     ebp,[Mid_Y]
inc     ebp
@@loop2:
mov     edi,edx
mov     eax,[X1_Fixed]
shr     eax,7
mov     ecx,[X2_Fixed]
shr     ecx,7
cmp     ecx,eax
jae     @@ok2
xchg    eax,ecx
@@ok2:
add     edi,eax
sub     ecx,eax
inc     ecx
mov     al,[color]
rep     stosb

mov     eax,[Delta_L]
add     [X1_Fixed],eax
mov     eax,[Delta_R]
add     [X2_Fixed],eax

add     edx,320
dec     ebp
jnz     @@loop2

ret
ENDP    DrawPoly

PROC    WaitVrt
push    ax dx
    mov     dx,3dah
Vrt:
    in      al,dx
    test    al,1000b        
    jnz     Vrt            
NoVrt:
    in      al,dx
    test    al,1000b         
    jz      NoVrt         
pop     dx ax
    ret
ENDP    WaitVrt

end     start
