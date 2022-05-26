MACRO   RotXaxis

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

ENDM

MACRO   RotYaxis

; rotate around Y axis
; --------------------
;

push    ecx edx ebp

mov     ebx,[cosine + ecx*4]
mov     ecx,[sine + ecx*4]

mov     eax,[esi + base_object.Xpos]
imul    ebx                                     ; X * COS(angle)
mov     ebp,eax
mov     eax,[esi + base_object.Zpos]
imul    ecx                                     ; Z * SIN(angle)
sub     ebp,eax
sar     ebp,8
mov     [edi + rotated_object.Xpos],ebp

mov     eax,[esi + base_object.Xpos]
imul    ecx                                     ; X * SIN(angle)
mov     ebp,eax
mov     eax,[esi + base_object.Zpos]
imul    ebx                                     ; Z * COS(angle)
add     ebp,eax
sar     ebp,8
mov     [edi + rotated_object.Zpos],ebp

mov     eax,[esi + base_object.Ypos]
mov     [edi + rotated_object.Ypos],eax

pop     ebp edx ecx

ENDM

MACRO   RotZaxis

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

ENDM
