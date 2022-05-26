IDEAL
P386N
MODEL FLAT
STACK 1000h
JUMPS

X       EQU 0
Y       EQU 4
color   equ 8
Z       EQU 8

XCENTER EQU 160
YCENTER EQU 100

DATASEG

video_mem       dd 0A0000h

include "sincos.dw"

Distance        dd 256

Top_X           dd 0
Mid_X           dd 0
Bot_X           dd 0

Top_Y           dd 0
Mid_Y           dd 0
Bot_Y           dd 0

top_col         dd 10
mid_col         dd 30
bot_col         dd 60

col1_fixed      dd 0
col2_fixed      dd 0
col_step        dd 0

X1_Fixed        dd 0
X2_Fixed        dd 0

dc_left         dd 0
dc_right        dd 0

Delta_L         dd 0
Delta_R         dd 0

Xangle          dd 0
Yangle          dd 0
Zangle          dd 0

base_object     dd 0,60,0
                dd -40,-40,-125
                dd 40,-41,-125
                dd 40,40,40
                dd -40,-40,-40
                dd -40,40,-40
                dd -40,-40,40
                dd -40,40,40

rotated_object  dd 3*8 dup (?)

_2D_object      dd 3*8 dup (?)

virtual_screen  db 320*200 dup (?)

CODESEG

include "palette.inc"

start:

mov     ax,13h
int     10h

mov     ax,0EE02h
int     31h

sub     [video_mem],ebx

mov     dx,3c8h
xor     al,al
out     dx,al
xor     ah,ah
inc     dx
mov     esi,offset palette
mov     ecx,768
rep     outsb

main_loop:

mov     edi,offset virtual_screen
xor     eax,eax
mov     ecx,64000/4
rep     stosd

mov     esi,offset base_object
mov     edi,offset rotated_object
mov     ecx,8
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
mov     ecx,8
draw_point:
push    ecx
call    ConvertPoint
add     esi,3*4
add     edi,3*4
pop     ecx
dec     ecx
jnz     draw_point

mov     esi,offset _2D_object
call    DrawFlatPoly

mov     esi,offset virtual_screen
mov     edi,[video_mem]
mov     ecx,64000/4
rep     movsd

call    waitvrt
inc     [xangle]
and     [xangle],255
in      al,60h
dec     al
jz      exit
jmp     main_Loop

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

movsx   ebx,[word ptr cosine + ecx*2]
movsx   ecx,[word ptr sine + ecx*2]

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

movsx   ebx,[word ptr cosine + ecx*2]
movsx   ecx,[word ptr sine + ecx*2]

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

movsx   ebx,[word ptr cosine + ecx*2]
movsx   ecx,[word ptr sine + ecx*2]

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

xor     edx,edx
mov     eax,[dword ptr esi + Y]
neg     eax                             ; because the Y axis grows UPWARDS
jns     short @@calc_it
dec     edx
@@calc_it:
shl     eax,8
mov     ecx,[Distance]
sub     ecx,[dword ptr esi + Z]
idiv    ecx                             ; divide by distance
add     eax,YCENTER                     ; center coordinate on screen
mov     [dword ptr edi + Y],eax

xor     edx,edx
mov     eax,[dword ptr esi + X]
add     eax,edx
jns     short @@calc_it2
dec     edx
@@calc_it2:
shl     eax,8
idiv    ecx                             ; divide by distance
add     eax,XCENTER                     ; center coordinate on screen
mov     [dword ptr edi + X],eax

mov     eax,[dword ptr esi + Z]
add     eax,512
shl     eax,6
shr     eax,8
mov     [dword ptr edi + color],eax

ret
ENDP    ConvertPoint

PROC    DrawFlatPoly

; ESI = pointer to three sets of (X,Y) 2D coordinates

mov     eax,[dword ptr esi + Y]         ; first Y coordinate
mov     ebx,[dword ptr esi + Y + 12]     ; second Y coordinate
cmp     eax,ebx                         ; is Y1 < Y2?
jb      short @@top                     ; yep ...
mov     [Top_Y],ebx                     ; no, store Y2 as top Y
mov     [Bot_Y],eax                     ; and Y1 as bottom Y
mov     eax,[dword ptr esi + X + 12]
mov     [Top_X],eax
mov     eax,[dword ptr esi + X]
mov     [Bot_X],eax
mov     eax,[dword ptr esi + color + 12]
mov     [top_col],eax
mov     eax,[dword ptr esi + color]
mov     [bot_col],eax
jmp     short @@p3
@@top:
mov     [Top_Y],eax                     ; store Y1 as top Y
mov     [Bot_Y],ebx                     ; and Y2 as bottom Y
mov     eax,[dword ptr esi + X]
mov     [Top_X],eax
mov     eax,[dword ptr esi + X + 12]
mov     [Bot_X],eax
mov     eax,[dword ptr esi + color]
mov     [top_col],eax
mov     eax,[dword ptr esi + color + 12]
mov     [bot_col],eax
@@p3:
mov     eax,[dword ptr esi + Y + 24]    ; third Y coordinate
cmp     eax,[Top_Y]
jb      short @@smallest
cmp     eax,[Bot_Y]
ja      short @@biggest
mov     [Mid_Y],eax
mov     eax,[dword ptr esi + X + 24]
mov     [Mid_X],eax
mov     eax,[dword ptr esi + color + 24]
mov     [mid_col],eax
jmp     short @@next
@@smallest:
mov     ebx,[Top_Y]
mov     [Mid_Y],ebx
mov     [Top_Y],eax
mov     eax,[Top_X]
mov     [Mid_X],eax
mov     eax,[dword ptr esi + X + 24]
mov     [Top_X],eax
mov     eax,[top_col]
mov     [mid_col],eax
mov     eax,[dword ptr esi + color + 24]
mov     [top_col],eax
jmp     short @@next
@@biggest:
mov     ebx,[Bot_Y]
mov     [Mid_Y],ebx
mov     [Bot_Y],eax
mov     eax,[Bot_X]
mov     [Mid_X],eax
mov     eax,[bot_col]
mov     [mid_col],eax
mov     eax,[dword ptr esi + X + 24]
mov     [Bot_X],eax
mov     eax,[dword ptr esi + color + 24]
mov     [bot_col],eax
@@next:

xor     edx,edx
mov     ebx,[bot_y]
sub     ebx,[top_y]
mov     eax,[bot_col]
sub     eax,[top_col]
jns     @@divide
dec     edx
@@divide:
shl     eax,16
idiv    ebx
mov     [dc_left],eax

xor     edx,edx
mov     ebx,[mid_y]
sub     ebx,[top_y]
inc     ebx
mov     eax,[mid_col]
sub     eax,[top_col]
jns     @@divide2
dec     edx
@@divide2:
shl     eax,16
idiv    ebx
mov     [dc_right],eax

mov     eax,[top_col]
shl     eax,16
mov     [col1_fixed],eax
mov     [col2_fixed],eax

mov     ebx,[Mid_Y]
sub     ebx,[Top_Y]
jnz     short @@calc_delta_l
mov     [Delta_L],0
jmp     short @@done_calc_l

@@calc_delta_l:
xor     edx,edx
mov     eax,[Mid_X]
sub     eax,[Top_X]
jns     short @@calc_it3
dec     edx
@@calc_it3:
shl     eax,16
idiv    ebx
mov     [Delta_L],eax

@@done_calc_l:
mov     eax,[Top_X]
shl     eax,16
mov     [X1_Fixed],eax
mov     [X2_Fixed],eax

xor     edx,edx
mov     eax,[Bot_X]
sub     eax,[Top_X]
jns     short @@calc_it4
dec     edx
@@calc_it4:
mov     ebx,[Bot_Y]
sub     ebx,[Top_Y]
shl     eax,16
idiv    ebx
mov     [Delta_R],eax

mov     edi,offset virtual_screen
mov     eax,[Top_Y]
shl     eax,8
add     edi,eax
shr     eax,2
add     edi,eax

mov     ebp,[Mid_Y]
sub     ebp,[Top_Y]
jz      @@skip_1st_half
@@loop1:
push    edi
mov     eax,[X1_Fixed]
shr     eax,16
mov     ecx,[X2_Fixed]
shr     ecx,16
cmp     ecx,eax
jae     short @@ok
xchg    eax,ecx
@@ok:
add     edi,eax
sub     ecx,eax
inc     ecx

push    ecx edx
xor     edx,edx
mov     eax,[col2_fixed]
shr     eax,16
mov     ebx,[col1_fixed]
shr     ebx,16
sub     eax,ebx
jns     @@divide3
dec     edx
@@divide3:
shl     eax,16
idiv    ecx
mov     [col_step],eax
pop     edx ecx

mov     ebx,[col1_fixed]
@@goraud_loop:
mov     eax,ebx
shr     eax,16
mov     [byte ptr edi],al
inc     edi
add     ebx,[col_step]
dec     ecx
jnz     @@goraud_loop

mov     eax,[dc_left]
add     [col1_fixed],eax
mov     eax,[dc_right]
add     [col2_fixed],eax

mov     eax,[Delta_L]
add     [X1_Fixed],eax
mov     eax,[Delta_R]
add     [X2_Fixed],eax

pop     edi
add     edi,320
dec     ebp
jnz     @@loop1

@@skip_1st_half:

xor     edx,edx
mov     ebx,[bot_y]
sub     ebx,[mid_y]
inc     ebx
mov     eax,[bot_col]
sub     eax,[mid_col]
jns     @@divide4
dec     edx
@@divide4:
shl     eax,16
idiv    ebx
mov     [dc_right],eax

mov     eax,[mid_col]
shl     eax,16
mov     [col2_fixed],eax

mov     ebx,[Bot_Y]
sub     ebx,[Mid_Y]
jnz     short @@calc_delta_l_AGAIN
mov     [Delta_L],0
jmp     short @@done_calc_l_AGAIN

@@calc_delta_l_AGAIN:
xor     edx,edx
mov     eax,[Bot_X]
sub     eax,[Mid_X]
jns     short @@calc_it5
dec     edx
@@calc_it5:
shl     eax,16
idiv    ebx
mov     [Delta_L],eax

@@done_calc_l_AGAIN:
mov     eax,[Mid_X]
shl     eax,16
mov     [X1_Fixed],eax

mov     ebp,[Bot_Y]
sub     ebp,[Mid_Y]
jz      @@skip_2nd_half
@@loop2:
push    edi
mov     eax,[X1_Fixed]
shr     eax,16
mov     ecx,[X2_Fixed]
shr     ecx,16
cmp     ecx,eax
jae     short @@ok2
xchg    eax,ecx
@@ok2:
add     edi,eax
sub     ecx,eax
inc     ecx

push    ecx edx
xor     edx,edx
mov     eax,[col2_fixed]
shr     eax,16
mov     ebx,[col1_fixed]
shr     ebx,16
sub     eax,ebx
jns     @@divide6
dec     edx
@@divide6:
shl     eax,16
idiv    ecx
mov     [col_step],eax
pop     edx ecx

mov     ebx,[col1_fixed]
@@goraud_loop2:
mov     eax,ebx
shr     eax,16
mov     [byte ptr edi],al
inc     edi
add     ebx,[col_step]
dec     ecx
jnz     @@goraud_loop2

mov     eax,[dc_left]
add     [col1_fixed],eax
mov     eax,[dc_right]
add     [col2_fixed],eax

mov     eax,[Delta_L]
add     [X1_Fixed],eax
mov     eax,[Delta_R]
add     [X2_Fixed],eax

pop     edi
add     edi,320
dec     ebp
jnz     @@loop2

@@skip_2nd_half:
ret
ENDP    DrawFlatPoly

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
