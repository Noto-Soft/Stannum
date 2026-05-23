use16

main:
    mov ax, cs
    mov ds, ax

    mov ah, 0x03
    xor dl, dl
    int 0x21

.forever:
    mov ah, 0x01
    lea si, [file_panick_com]
    int 0x21

    jmp .forever

file_panick_com db "panick.com", 0