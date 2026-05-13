use16

main:
    mov ax, es
    mov ds, ax
    mov ax, cs
    mov es, ax

    lea di, [argument]
    mov cx, 11
.read_filename_loop:
    lodsb
    test al, al
    jnz .dont_put_space
    mov al, " "
    jmp .store_as_is
.dont_put_space:
    cmp al, "a"
    jnae .store_as_is
    cmp al, "z"
    jnbe .store_as_is
    and al, 0xdf
.store_as_is:
    stosb
    loop .read_filename_loop

    mov ax, cs
    mov ds, ax

    mov word [argument + 8], "TX"
    mov byte [argument + 10], "T"

    mov ah, 0x01
    lea si, [argument]
    mov bp, 0x6969
    int 0x21
    mov [block], bx
    
    shl bx, 7
    add bx, 0x2000
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

argument db 11 dup(?)
block dw ?