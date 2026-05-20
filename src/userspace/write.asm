use16

main:
    mov ax, es
    mov ds, ax
    mov ax, cs
    mov es, ax

    lea di, [filename]
    mov cx, 12
    rep movsb

    mov ax, cs
    mov ds, ax

    cmp byte [filename], " "
    je error

prompt:
    xor ax, ax
    lea di, [typing_buffer]
    mov cx, 64
    rep stosw

    xor di, di
.typing:
    xor ax, ax
    int 0x16
    cmp al, 0x13 ; ctrl+s
    je write
    cmp al, 0x0d
    je .newline
    cmp al, 0x08
    je .backspace
    cmp di, 128
    jae .typing
    mov [typing_buffer + di], al
    mov ah, 0x05
    int 0x21
    inc di
    jmp .typing
.backspace:
    mov ah, 0x05
    cmp di, 0
    jna .typing
    dec di
    mov byte [typing_buffer + di], 0
    int 0x21
    mov al, " "
    int 0x21
    mov al, 0x08
    int 0x21
    jmp .typing
.newline:
    mov ah, 0x05
    cmp di, 127
    jnbe .typing
    mov al, 0x0a
    mov byte [typing_buffer + di], al
    int 0x21
    inc di
    jmp .typing

write:
    xor si, si
.find_zero:
    mov al, [typing_buffer + si]
    test al, al
    jz .found
    inc si
    jmp .find_zero
.found:
    xor ecx, ecx
    mov cx, si

    mov ah, 0x13
    mov bx, cs
    int 0x21
    mov ah, 0x0c
    add bx, 1
    lea si, [filename]
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

msg_err_supply_filename db "Must supply filename! (.TXT files are good)", 0x0a, 0
filename db 12 dup(0)
align 2048
typing_buffer db 128 dup(0)
db 0