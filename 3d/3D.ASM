IDEAL
P386N
MODEL FLAT
STACK 1000h
JUMPS

XCENTER EQU 160
YCENTER EQU 100

DATASEG

video_mem       dd 0A0000h

include "sincos.dw"

STRUC   Vertice
Xpos    dd 0
Ypos    dd 0
Zpos    dd 0
ENDS

STRUC   ScreenPoint
Xpos    dd 0
Ypos    dd 0
ENDS

Distance        dw 256

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

Xangle          db 0
Yangle          db 0
Zangle          db 0

base_object     Vertice <0,40,0>
                Vertice <-40,-40,100>
                Vertice <40,-41,100>
                Vertice <40,40,40>
                Vertice <-40,-40,-40>
                Vertice <-40,40,-40>
                Vertice <-40,-40,40>
                Vertice <-40,40,40>

rotated_object  Vertice 8 dup (<>)

_2D_object      ScreenPoint 8 dup (<>)

virtual_screen  db 320*200 dup (?)

CODESEG

include "rotate.inc"

start:

mov     ax,13h
int     10h

mov     ax,0EE02h
int     31h

sub     [video_mem],ebx

main_loop:

mov     edi,offset virtual_screen
xor     eax,eax
mov     ecx,64000/4
rep     stosd

xor     esi,esi
xor     edi,edi
mov     ecx,8
rotate_point:
push    ecx
movzx   ecx,[Xangle]
RotYaxis
add     esi,size Vertice
add     edi,size Vertice
pop     ecx
dec     ecx
jnz     rotate_point

xor     esi,esi
xor     edi,edi
mov     ecx,8
draw_point:
push    ecx
call    ConvertPoint
add     esi,size Vertice
add     edi,size ScreenPoint
pop     ecx
dec     ecx
jnz     draw_point

xor     esi,esi
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

PROC    ConvertPoint

; Converts a set of 3D coordinates (X,Y,Z)
; to a 2D screen offset
; ----------------------------------------
;

xor     edx,edx
mov     eax,[esi + rotated_object.Ypos]
neg     eax                             ; because the Y axis grows UPWARDS
jns     short @@calc_it
dec     edx
@@calc_it:
shl     eax,8
movzx   ecx,[Distance]
sub     ecx,[esi + rotated_object.Zpos]
idiv    ecx                             ; divide by distance
add     eax,YCENTER                     ; center coordinate on screen
mov     [edi + _2D_object.Ypos],eax

xor     edx,edx
mov     eax,[esi + rotated_object.Xpos]
add     eax,edx
jns     short @@calc_it2
dec     edx
@@calc_it2:
shl     eax,8
idiv    ecx                             ; divide by distance
add     eax,XCENTER                     ; center coordinate on screen
mov     [edi + _2D_object.Xpos],eax

ret
ENDP    ConvertPoint

PROC    DrawFlatPoly

; ESI = pointer to three sets of (X,Y) 2D coordinates

mov     eax,[esi + _2D_object.Ypos]     ; first Y coordinate
mov     ebx,[esi + size screenpoint + _2D_object.Ypos]     ; second Y coordinate
cmp     eax,ebx                         ; is Y1 < Y2?
jb      short @@top                     ; yep ...
mov     [Top_Y],ebx                     ; no, store Y2 as top Y
mov     [Bot_Y],eax                     ; and Y1 as bottom Y
mov     eax,[esi + size screenpoint + _2D_object.Xpos]
mov     [Top_X],eax
mov     eax,[esi + _2D_object.Xpos]
mov     [Bot_X],eax
jmp     short @@p3
@@top:
mov     [Top_Y],eax                     ; store Y1 as top Y
mov     [Bot_Y],ebx                     ; and Y2 as bottom Y
mov     eax,[esi + _2D_object.Xpos]
mov     [Top_X],eax
mov     eax,[esi + size screenpoint + _2D_object.Xpos]
mov     [Bot_X],eax
@@p3:
mov     eax,[esi + (size screenpoint*2) + _2D_object.Ypos]    ; third Y coordinate
cmp     eax,[Top_Y]
jb      short @@smallest
cmp     eax,[Bot_Y]
ja      short @@biggest
mov     [Mid_Y],eax
mov     eax,[esi + (size screenpoint*2) + _2D_object.Xpos]
mov     [Mid_X],eax
jmp     short @@next
@@smallest:
mov     ebx,[Top_Y]
mov     [Mid_Y],ebx
mov     [Top_Y],eax
mov     eax,[Top_X]
mov     [Mid_X],eax
mov     eax,[esi + (size screenpoint*2) + _2D_object.Xpos]
mov     [Top_X],eax
jmp     short @@next
@@biggest:
mov     ebx,[Bot_Y]
mov     [Mid_Y],ebx
mov     [Bot_Y],eax
mov     eax,[Bot_X]
mov     [Mid_X],eax
mov     eax,[esi + (size screenpoint*2) + _2D_object.Xpos]
mov     [Bot_X],eax
@@next:

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
mov     ebx,[Delta_L]
mov     edx,[Delta_R]
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
mov     al,5
mov     ah,al
shr     ecx,1
jnc     short @@draw
mov     [byte ptr edi],al
inc     edi
@@draw:
jz      short @@dont_draw
rep     stosw

@@dont_draw:
add     [X1_Fixed],ebx
add     [X2_Fixed],edx

pop     edi
add     edi,320
dec     ebp
jnz     short @@loop1

@@skip_1st_half:
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
mov     ebx,[Delta_L]
mov     edx,[Delta_R]
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
mov     al,5
mov     ah,al
shr     ecx,1
jnc     short @@draw2
mov     [byte ptr edi],al
inc     edi
@@draw2:
jz      short @@dont_draw2
rep     stosw

@@dont_draw2:
add     [X1_Fixed],ebx
add     [X2_Fixed],edx

pop     edi
add     edi,320
dec     ebp
jnz     short @@loop2

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
