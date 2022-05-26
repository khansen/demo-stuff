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

include "sincos.dw"

Distance        dd 512

Xt      dd 0
Yt      dd 0
Zt      dd 0

Xangle  dd 0
Yangle  dd 0
Zangle  dd 0

base_object     dd 10,10,0
                dd 10,10,10
                dd 10,10,20
                dd 10,10,30
                dd 10,10,40
                dd 10,10,50
                dd 10,10,60
                dd 10,10,70

rotated_object  dd 3*8 dup (?)

CODESEG

start:

mov     ax,13h
int     10h

mov     ax,0EE02h
int     31h

sub     [video_mem],ebx

mov     edi,[video_mem]
add     edi,160
rept    200
mov     [byte ptr edi],15
add     edi,320
endm

mov     edi,[video_mem]
add     edi,100*320
rept    320
mov     [byte ptr edi],15
inc     edi
endm

main_loop:

mov     edi,[video_mem]
xor     eax,eax
mov     ecx,64000/4
rep     stosd

mov     esi,offset base_object
mov     edi,offset rotated_object
mov     ecx,8
rotate_point:
push    ecx
mov     eax,[dword ptr esi + X]
mov     ebx,[dword ptr esi + Z]
mov     ecx,[Xangle]
call    RotYaxis
mov     [dword ptr edi + X],eax
mov     [dword ptr edi + Z],ebx
mov     eax,[dword ptr esi + Y]
mov     [dword ptr edi + Y],eax
add     esi,3*4
add     edi,3*4
pop     ecx
dec     ecx
jnz     rotate_point

mov     esi,offset rotated_object
mov     ecx,8
draw_point:
push    ecx
mov     eax,[dword ptr esi + X]
mov     ebx,[dword ptr esi + Y]
mov     ecx,[dword ptr esi + Z]
call    ConvertPoint
mov     [byte ptr edi],15
add     esi,3*4
pop     ecx
dec     ecx
jnz     draw_point

call    waitvrt
inc     [xangle]
cmp     [xangle],360
jnz     main_loop
mov     [xangle],0
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
; In:   EAX = Y coordinate
;       EBX = Z coordinate
;       ECX = degrees to rotate
; Out:  EAX = rotated Y coordinate
;       EBX = rotated Z coordinate

push    ecx edx ebp

mov     [Yt],eax
mov     [Zt],ebx

mov     ebx,[cosine + ecx*4]
mov     ecx,[sine + ecx*4]

mov     eax,[Yt]
imul    ebx                                     ; Y * COS(Xangle)
mov     ebp,eax
mov     eax,[Zt]
imul    ecx                                     ; Z * SIN(Xangle)
sub     ebp,eax
sar     ebp,8
push    ebp

mov     eax,[Yt]
imul    ecx                                     ; Y * SIN(Xangle)
mov     ebp,eax
mov     eax,[Zt]
imul    ebx                                     ; Z * COS(Xangle)
add     ebp,eax
sar     ebp,8

mov     ebx,ebp
pop     eax

pop     ebp edx ecx

ret
ENDP    RotXaxis

PROC    RotYaxis

; rotate around Y axis
; --------------------
;
; In:   EAX = X coordinate
;       EBX = Z coordinate
;       ECX = degrees to rotate
; Out:  EAX = rotated X coordinate
;       EBX = rotated Z coordinate

push    ecx edx ebp

mov     [Xt],eax
mov     [Zt],ebx

mov     ebx,[cosine + ecx*4]
mov     ecx,[sine + ecx*4]

mov     eax,[Xt]
imul    ebx                                     ; X * COS(Xangle)
mov     ebp,eax
mov     eax,[Zt]
imul    ecx                                     ; Z * SIN(Xangle)
sub     ebp,eax
sar     ebp,8
push    ebp

mov     eax,[Xt]
imul    ecx                                     ; X * SIN(Xangle)
mov     ebp,eax
mov     eax,[Zt]
imul    ebx                                     ; Z * COS(Xangle)
add     ebp,eax
sar     ebp,8

mov     ebx,ebp
pop     eax

pop     ebp edx ecx

ret
ENDP    RotYaxis

PROC    RotZaxis

; rotate around Z axis
; --------------------
;
; In:   EAX = X coordinate
;       EBX = Y coordinate
;       ECX = degrees to rotate
; Out:  EAX = rotated X coordinate
;       EBX = rotated Y coordinate

push    ecx edx ebp

mov     [Xt],eax
mov     [Yt],ebx

mov     ebx,[cosine + ecx*4]
mov     ecx,[sine + ecx*4]

mov     eax,[Xt]
imul    ebx                                     ; X * COS(Xangle)
mov     ebp,eax
mov     eax,[Yt]
imul    ecx                                     ; Y * SIN(Xangle)
sub     ebp,eax
sar     ebp,8
push    ebp

mov     eax,[Xt]
imul    ecx                                     ; X * SIN(Xangle)
mov     ebp,eax
mov     eax,[Yt]
imul    ebx                                     ; Y * COS(Xangle)
add     ebp,eax
sar     ebp,8

mov     ebx,ebp
pop     eax

push    ebp edx ecx

ret
ENDP    RotZaxis

PROC    ConvertPoint

; Converts a set of 3D coordinates (X,Y,Z)
; to a 2D screen offset
; ----------------------------------------
;
; In:   EAX = X coordinate
;       EBX = Y coordinate
;       ECX = Z coordinate
;
; Out:  EDI = screen offset

mov     [Xt],eax
mov     [Yt],ebx
mov     [Zt],ecx

mov     edi,[video_mem]                 ; EDI points to start of VGA memory

mov     eax,[Yt]
neg     eax                             ; because the Y axis grows UPWARDS
mov     edx,256
imul    edx                             ; multiply by Z coordinate
mov     ecx,[Distance]
idiv    ecx                             ; divide by distance
add     eax,YCENTER                     ; center coordinate on screen
shl     eax,8
add     edi,eax
shr     eax,2
add     edi,eax                         ; EDI = (Y) VGA position

mov     eax,[Xt]
mov     edx,256
imul    edx                             ; multiply Z coordinate
idiv    ecx                             ; divide by distance
add     eax,XCENTER                     ; center coordinate on screen
add     edi,eax                         ; EDI = final (X,Y) VGA position

ret
ENDP    ConvertPoint

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
