use16

main:
    mov ax, cs
    mov ds, ax

    xor ax, ax
    int 0x30
    test ax, ax
    jz exit_early_no_vga_driver
    mov [write_pixel_12h_off], ax
    mov [write_pixel_12h_seg], bx

    mov ax, 0x0012
    int 0x10

    xor al, al
    xor cx, cx
    xor dx, dx
.loop:
    call far [write_pixel_12h]
    inc cx
    inc al
    cmp cx, 640
    jb .loop
    xor cx, cx
    inc dx
    cmp dx, 480
    jb .loop

    xor ah, ah
    int 0x16

    mov ah, 0x07
    int 0x21

    retf

exit_early_no_vga_driver:
    xor ah, ah
    lea si, [msg_err_no_vga_driver]
    int 0x21

    retf

msg_err_no_vga_driver db "No int 30h VGA driver detected!", 0x0a, 0

label write_pixel_12h
write_pixel_12h_off dw 0
write_pixel_12h_seg dw 0