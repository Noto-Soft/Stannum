use16

mov ax, cs
mov ds, ax
xor ah, ah
lea si, [hello]
int 0x21
retf

hello db "Hello, world", 0x0a, 0