DOSSEG
.MODEL SMALL
.STACK 100h
jumps

COORDS  STRUC
X       dw      0
Y       dw      0
COORDS  ENDS

.data

DeltaR  dw 0
DeltaL  dw 0
Rpos    dw 0
Lpos    dw 0
Color   db 1

P1      COORDS  <0,-60>
P2      COORDS  <60,20>
P3      COORDS  <-40,80>

TOP     COORDS  <>
MID     COORDS  <>
BOT     COORDS  <>

array   dw 200*2 dup (?)

stuff   dw 40 dup (?)

.code

Start:

mov     ax,13h
int     10h

mov     ax,@data
mov     ds,ax
mov     es,ax

mov     ax,[P1.Y]
mov     dx,[P1.X]
mov     bx,[P2.Y]
mov     cx,[P2.X]
cmp     ax,bx
jg      Store_In_BOT
mov     [BOT.Y],bx
mov     [BOT.X],cx
mov     [TOP.Y],ax
mov     [TOP.X],dx
jmp     next
Store_In_BOT:
mov     [BOT.Y],ax
mov     [BOT.X],dx
mov     [TOP.Y],bx
mov     [TOP.X],cx

next:

mov     ax,[P3.Y]
mov     dx,[P3.X]
cmp     ax,[BOT.Y]
jg      Biggest
cmp     ax,[TOP.Y]
ja      P3_Greater_than_TOP
cmp     ax,[TOP.Y]
jb      Smallest

P3_Greater_than_TOP:
cmp     ax,[BOT.Y]
jg      Biggest

mov     [MID.Y],ax
mov     [MID.X],dx
jmp     interpolate

Biggest:
mov     bx,ax
mov     ax,[BOT.Y]
mov     cx,[BOT.X]
mov     [MID.Y],ax
mov     [MID.X],cx
mov     [BOT.Y],bx
mov     [BOT.X],dx
jmp     interpolate

Smallest:
mov     bx,ax
mov     ax,[TOP.Y]
mov     cx,[TOP.X]
mov     [MID.Y],ax
mov     [MID.X],cx
mov     [TOP.Y],bx
mov     [TOP.X],dx

interpolate:

;deltaR

mov     ax,[BOT.X]
cmp     ax,[TOP.X]
jl      top_is_biggest
sub     ax,[TOP.X]
jmp     calc2
top_is_biggest:
mov     ax,[TOP.X]
sub     ax,[BOT.X]
calc2:
sal     ax,7                    ;gang avstanden mellom BOT.X-TOP.X med 128
mov     bx,[BOT.Y]              
sub     bx,[TOP.Y]              ;den lengste linja
xor     dx,dx
idiv    bx                      ;deltaX/deltaY
mov     bx,[TOP.X]
cmp     bx,[BOT.X]
jl      skip3
neg     ax
skip3:
mov     DeltaR,ax       ;gjennomsnittlig stigningshastighet til linja * 128

;deltaL

mov     ax,[MID.X]
cmp     ax,[TOP.X]
jl      top_is_biggest2
sub     ax,[TOP.X]
jmp     calc1
top_is_biggest2:
mov     ax,[TOP.X]
sub     ax,[MID.X]
calc1:
sal     ax,7                    ;gang avstanden mellom BOT.X-MID.X med 128
mov     bx,[MID.Y]
sub     bx,[TOP.Y]              ;linja fra TOP.Y til MID.Y
xor     dx,dx
idiv    bx                      ;deltaX/deltaY
mov     bx,[TOP.X]
cmp     bx,[MID.X]
jl      skip1
neg     ax
skip1:
mov     DeltaL,ax       ;gjennomsnittlig stigningshastighet til linja * 128

;  RPOS=TOP.X
;  LPOS=TOP.X
;  FOR NR=TOP.Y TO MID.Y DO
;    HLINE(RPOS,LPOS,NR,COLOR)
;    RPOS=RPOS+EBR
;    LPOS=LPOS+EBL
;  NEXT NR

mov     ax,[TOP.X]
sal     ax,7                            ;gang start-X verdien med 128
mov     Lpos,ax                         ;begge linjene tegnes
mov     Rpos,ax                         ;fra dette punktet
mov     cx,[MID.Y]
sub     cx,[TOP.Y]                      ;loop fra top.y til mid.y
lea     si,array
mov     bx,DeltaR
mov     dx,DeltaL
call    GetCoords

;deltaL maa kalkuleres paa nytt

mov     ax,[MID.X]
cmp     ax,[BOT.X]
jl      bot_is_biggest
sub     ax,[BOT.X]
jmp     calc
bot_is_biggest:
mov     ax,[BOT.X]
sub     ax,[MID.X]
calc:
sal     ax,7                    ;gang avstanden mellom BOT.X-MID.X med 128
mov     bx,[BOT.Y]
sub     bx,[MID.Y]              ;linja fra TOP.Y til MID.Y
xor     dx,dx
idiv    bx                      ;deltaX/deltaY
mov     bx,[MID.X]
cmp     bx,[BOT.X]
jl      skip
neg     ax
skip:
mov     DeltaL,ax       ;gjennomsnittlig stigningshastighet til linja * 128

mov     cx,[BOT.Y]
sub     cx,[MID.Y]
call    GetCoords

mov     ax,0a000h
mov     es,ax

mov     bp,[BOT.Y]
sub     bp,[TOP.Y]                 ;no. of vertical lines to draw

mov     ax,[P1.Y]
add     ax,100
mov     dx,ax
sal     ax,8
sal     dx,6
add     dx,ax
add     dx,[P1.X]
add     dx,160
lea     si,array

fill_polygon:                           ;fill'em all!

mov     di,dx                      ;Y
lodsw
add     di,ax
mov     bx,ax
lodsw
mov     cx,ax
inc     cx
sub     cx,bx
mov     al,color
fill_it:
mov     byte ptr es:[di],al
inc     di
loop    fill_it

add     dx,320

dec     bp
jnz     fill_polygon

inc     color

in      al,60h
cmp     al,1
jnz     interpolate

mov     ax,3
int     10h
mov     ax,4c00h
int     21h

GetCoords PROC

mov     bx,DeltaR
mov     dx,DeltaL
line_loop:
mov     ax,Rpos
sar     ax,7
mov     word ptr [si],ax
add     si,2
mov     ax,Lpos
sar     ax,7
mov     word ptr [si],ax
add     si,2
add     Rpos,bx
add     Lpos,dx
loop    line_loop
ret
GetCoords ENDP

end     Start
