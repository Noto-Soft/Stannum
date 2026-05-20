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

    cmp byte [argument], " "
    je error

    mov ah, 0x01
    lea si, [argument]
    int 0x21
    mov [block], bx
    
    mov ah, 0x0b
    int 0x21
    mov ds, bx

    mov ax, 0x0013
    int 0x10

    mov ax, 0xa000
    mov es, ax

    xor si, si
    xor di, di
    mov cx, 320 * 200
    rep movsb

    xor ax, ax
    int 0x16

    mov ah, 0x07
    int 0x21

    mov ax, cs
    mov ds, ax

    mov ah, 0x08
    mov bx, [block]
    int 0x21

    retf

error:
    mov ah, 0x0e
    mov bl, 0x0c
    int 0x21

    xor ah, ah
    lea si, [msg_err_supply_filename]
    int 0x21

    retf

msg_err_supply_filename db "Must supply filename! (.RAW images are good)", 0x0a, 0

argument db 12 dup(0)
block dw 0