use16

main:
    mov ax, es
    mov ds, ax
    mov ax, cs
    mov es, ax

    lea di, [argument]
    mov cx, 12
    rep movsb

    mov ax, cs
    mov ds, ax

    mov ah, 0x01
    lea si, [argument]
    int 0x21
    mov [block], bx
    
    mov ah, 0x0b
    int 0x21
    mov ds, bx

    xor ah, ah
    xor si, si
    int 0x21

    mov ax, cs
    mov ds, ax

    mov ah, 0x08
    mov bx, [block]
    int 0x21

    retf

argument db 12 dup(0)
block dw 0