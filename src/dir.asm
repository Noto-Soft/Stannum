use16

main:
    mov ax, cs
    mov ds, ax
    mov es, ax

    mov ah, 0x4
    int 0x21
    mov [entries], bx
    mov bp, ax
    mov ah, 0x5
    lea bx, [buffer]
    int 0x21

    lea si, [buffer]
    mov cx, [entries]
.loop:
    mov al, [si]
    test al, al
    jz .next_loop
    cmp al, 0xe5
    je .next_loop
    mov byte [si + 11], 0x0d
    mov byte [si + 12], 0x0a
    mov byte [si + 13], 0
    xor ah, ah
    int 0x21
.next_loop:
    add si, 32
    loop .loop

    retf

entries dw ?

label buffer