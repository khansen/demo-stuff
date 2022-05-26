IDEAL
P386N
MODEL FLAT
STACK 1000h
JUMPS

TEXTURE_HEIGHT  EQU 83

XCENTER         EQU 160
YCENTER         EQU 100

DATASEG

start_pos       dd 0

X1              dd 10
Y1              dd 40
X2              dd 100
Y2              dd 80

y_pos           dd 0
y_step          dd 0

video_mem       dd 0A0000h

include "sincos.dw"
include "fuck.pic"
include "palette.inc"

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

Xangle          db 0
Yangle          db 0
Zangle          db 0

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

mov     dx,3c8h
xor     al,al
out     dx,al
inc     dx
mov     esi,offset palette
mov     ecx,768
rep     outsb

main_loop:
call    DrawWall
inc     [start_pos]
call    waitvrt
in      al,60h
dec     al
jnz     main_loop

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

PROC    MapLine

pushad

mov     esi,offset texture
mov     eax,ebp
sub     eax,[X1]
add     eax,[start_pos]
and     eax,127
add     esi,eax

; ECX = line height
; ESI = pointer to (texture data + X offset)
; EDI = start screen offset

mov     eax,TEXTURE_HEIGHT
shl     eax,16
xor     edx,edx
div     ecx
mov     ebx,eax

@@step_loop:
mov     eax,edx
shr     eax,16
shl     eax,7
mov     al,[byte ptr esi + eax]
mov     [byte ptr edi],al
add     edx,ebx
add     edi,320
dec     ecx
jnz     @@step_loop

popad
ret
ENDP    MapLine

PROC    DrawWall

xor     edx,edx
mov     eax,[Y2]
sub     eax,[Y1]
jns     @@ok
dec     edx
@@ok:
shl     eax,16
mov     ebx,[X2]
sub     ebx,[X1]
idiv    ebx
mov     [y_step],eax

mov     eax,[Y1]
shl     eax,16
mov     [y_pos],eax

mov     ebp,[X1]
mov     ebx,[y_step]
mov     edx,[y_pos]
@@line_loop:
mov     edi,[video_mem]
mov     eax,edx
shr     eax,16
mov     ecx,200
sub     ecx,eax
sub     ecx,eax
shl     eax,8
add     edi,eax
shr     eax,2
add     edi,eax
add     edi,ebp

call    MapLine

add     edx,ebx
inc     ebp
cmp     ebp,[X2]
jnz     @@line_loop

ret
ENDP    DrawWall

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
