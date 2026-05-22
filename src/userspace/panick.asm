use16

main:
    mov ax, cs
    mov ds, ax

    mov ah, 0x03
    xor dl, dl
    int 0x21

.forever:
    mov ah, 0x01
    lea si, [file_kernel_bin]
    int 0x21

    jmp .forever

file_kernel_bin db "kernel.bin", 0