use16

mov ax, cs
mov ds, ax
xor ah, ah
lea si, [message]
int 0x21
mov al, "e"
int 0x36
inc ah
int 0x36
mov ah, 0x0e
xor bh, bh
int 0x10
mov al, 0x0d
int 0x10
mov al, 0x0a
int 0x10
retf

message db "On your serial console, you will see a letter outputted.", 0x0d, 0x0a, "Input a character and it will be outputted here,", 0x0d, 0x0a, "and the program will terminate.", 0x0a, 0x0d, 0