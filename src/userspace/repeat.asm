use16

main:
    mov ax, es
    mov ds, ax
    mov ax, cs
    mov es, ax

    lea di, [argument]
    mov cx, 128
    rep movsb

    mov ax, cs
    mov ds, ax

    mov di, 126
.clear_trailing_spaces:
    mov al, [argument + di]
    cmp al, " "
    jne .done
    mov byte [argument + di], 0
    dec di
    jmp .clear_trailing_spaces
.done:
    xor ah, ah
    lea si, [argument]
    int 0x21
    
    lea si, [newline]
    int 0x21

    retf

newline db 0x0a, 0
argument db 128 dup(0)