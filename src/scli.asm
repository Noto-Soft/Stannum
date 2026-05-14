use16

main:
    mov ax, cs
    mov ds, ax
    mov es, ax

    xor ah, ah
    lea si, [msg_scli_startup]
    int 0x21

prompt:
    xor ax, ax
    lea di, [typing_buffer]
    mov cx, 128
    rep stosw

    xor ah, ah
    lea si, [prompt_string]
    int 0x21

    xor bh, bh
    xor di, di
.typing:
    xor ax, ax
    int 0x16
    cmp al, 0x0d
    je parse
    cmp al, 0x08
    je .backspace
    cmp di, 78
    jae .typing
    mov [typing_buffer + di], al
    mov ah, 0x0e
    int 0x10
    inc di
    jmp .typing
.backspace:
    cmp di, 0
    jna .typing
    dec di
    mov byte [typing_buffer + di], 0
    int 0x10
    mov al, " "
    int 0x10
    mov al, 0x08
    int 0x10
    jmp .typing

parse:
    mov ah, 0x0e
    xor bh, bh
    int 0x10
    mov al, 0x0a
    int 0x10

    test di, di
    jz prompt

    xor di, di
.zeroes_to_spaces:
    mov al, [typing_buffer + di]
    test al, al
    jnz .zeroes_to_spaces_skip
    mov byte [typing_buffer + di], " "
.zeroes_to_spaces_skip:
    inc di
    cmp di, 255
    jne .zeroes_to_spaces

    lea si, [typing_buffer]
    lea di, [cmd_string_exit]
    mov cx, 5
    repe cmpsb
    je exit

    lea si, [typing_buffer]
    lea di, [cmd_string_clear]
    mov cx, 6
    repe cmpsb
    je clear

    lea si, [typing_buffer]
    lea di, [cmd_string_dir]
    mov cx, 4
    repe cmpsb
    je dir

    lea si, [typing_buffer]
    lea di, [cmd_string_help]
    mov cx, 5
    repe cmpsb
    je help

    lea si, [typing_buffer]
    lea di, [cmd_string_reboot]
    mov cx, 7
    repe cmpsb
    je reboot

    lea si, [typing_buffer]
    lea di, [cmd_string_shutdown]
    mov cx, 9
    repe cmpsb
    je shutdown

    lea si, [typing_buffer]
    lea di, [cmd_string_mem]
    mov cx, 4
    repe cmpsb
    je mem

    mov al, " "
    lea di, [filename_shenanigans]
    mov cx, 11
    rep stosb

    lea si, [typing_buffer]
    lea di, [filename_shenanigans]
    xor bx, bx
    mov cx, 12
.move_loop_uppercase_if_lower_stop_copy_if_found_space:
    lodsb
    cmp al, " "
    je .stop_copy_if_found_space
    inc bx
    stosb
    loop .move_loop_uppercase_if_lower_stop_copy_if_found_space
.stop_copy_if_found_space:
    mov ah, 0x06
    lea si, [filename_shenanigans]
    int 0x21
    test al, al
    jnz .look_for_first_space_else_zero
    ; autocomplete .com extension
    cmp bx, 8
    ja error_not_file
    mov word [filename_shenanigans + bx], ".C"
    mov word [filename_shenanigans + bx + 2], "OM"

    mov ah, 0x06
    lea si, [filename_shenanigans]
    int 0x21
    test al, al
    jz error_not_file
.look_for_first_space_else_zero:
    lea bx, [typing_buffer]
    xor si, si
.look_for_first_space_else_zero_loop:
    mov al, [typing_buffer + si]
    cmp al, " "
    je .found_space
    inc si
    cmp si, 255
    jne .look_for_first_space_else_zero_loop
    xor si, si
    xor bx, bx
.found_space:
    add bx, si
    inc bx

    lea si, [filename_shenanigans]
    ; bx already populated
    mov ah, 0x06
    int 0x21
    test al, al
    jz error_not_file
    mov ah, 0x02 ; run program
    int 0x21

    jmp prompt

error_not_file:
    xor ah, ah
    lea si, [msg_err_not_file]
    int 0x21

    jmp prompt

clear:
    mov ah, 0x07
    int 0x21

    jmp prompt

help:
    mov ah, 0x07
    int 0x21

    xor ah, ah
    lea si, [msg_help]
    int 0x21

    jmp prompt

mem:
    mov ah, 0x0a
    int 0x21

    jmp prompt

reboot:
    jmp 0xffff:0x0000

shutdown:
    xor ah, ah
    lea si, [msg_safe]
    int 0x21

    cli
    hlt

dir:
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

    jmp prompt

exit:
    retf

msg_scli_startup db "SCLi -- Stannum Command Line", 0x0a, 0x0d, 0
msg_safe db "It is now safe to turn off your computer.", 0

msg_help file 'inc/help.txt'
db 0

msg_err_not_file db "Not a valid command or executable. Run 'help' command", 0x0a, 0x0d, 0

prompt_string db ">", 0

cmd_string_clear db "clear "
cmd_string_dir db "dir "
cmd_string_exit db "exit "
cmd_string_help db "help "
cmd_string_mem db "mem "
cmd_string_reboot db "reboot "
cmd_string_shutdown db "shutdown "

typing_buffer db 256 dup(0)
filename_shenanigans db 12 dup(0)

entries dw 0

buffer db 8192 dup(0)