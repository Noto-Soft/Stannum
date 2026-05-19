use16

main:
    mov ax, cs
    mov ds, ax

    mov ax, 0x0100
    int 0x30
    test ax, ax
    jz exit_early_no_vga_driver
    mov [write_pixel_13h_off], ax
    mov [write_pixel_13h_seg], bx

    mov ax, 0x0013
    int 0x10

    xor al, al
    xor cx, cx
    xor dx, dx
.loop:
    inc al
    call far [write_pixel_13h]
    inc cx
    call far [write_pixel_13h]
    dec cx
    inc dx
    call far [write_pixel_13h]
    inc cx
    call far [write_pixel_13h]
    dec dx
    inc cx
    cmp cx, 320
    jb .loop
    xor cx, cx
    add dx, 2
    cmp dx, 200
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

label write_pixel_13h
write_pixel_13h_off dw 0
write_pixel_13h_seg dw 0