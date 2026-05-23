use16

main:
    mov ax, cs
    mov ds, ax
    ;mov ax, 0xa000
    ;mov es, ax

    mov ax, 0x0100
    int 0x30
    test ax, ax
    jz exit_early_no_vga_driver
    mov [write_pixel_13h_off], ax
    mov [write_pixel_13h_seg], bx

    mov ax, 0x0013
    int 0x10

game_loop:
    xor al, al
    mov cx, [last_x]
    mov dx, [last_y]
    call far [write_pixel_13h]

    mov al, 0x0a
    mov cx, [cur_x]
    mov dx, [cur_y]
    call far [write_pixel_13h]

    mov [last_x], cx
    mov [last_y], dx

    xor ah, ah
    int 0x16

    cmp ah, 0x4b
    je left
    cmp ah, 0x4d
    je right
    cmp ah, 0x48
    je up
    cmp ah, 0x50
    je down
    cmp al, ('q' and 0x1f)
    je exit

    jmp game_loop

left:
    dec [cur_x]
    jmp game_loop

right:
    inc [cur_x]
    jmp game_loop

up:
    dec [cur_y]
    jmp game_loop

down:
    inc [cur_y]
    jmp game_loop

exit:
    mov ah, 0x07
    int 0x21
    
    retf

exit_early_no_vga_driver:
    xor ah, ah
    lea si, [msg_err_no_vga_driver]
    int 0x21

    retf

msg_err_no_vga_driver db "No int 30h VGA driver detected!", 0x0a, 0

last_x dw 160
last_y dw 100
cur_x dw 160
cur_y dw 100

label write_pixel_13h
write_pixel_13h_off dw 0
write_pixel_13h_seg dw 0