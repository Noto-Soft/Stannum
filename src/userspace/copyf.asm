use16

main:
    mov ax, cs
    mov ds, ax
    mov es, ax

    mov ah, 0x14
    int 0x21

    mov [original_drive], dl

    xor ah, ah
    lea si, [msg_start]
    int 0x21

    lea si, [msg_source]
    int 0x21

    xor ah, ah
    int 0x16

    push ax
    mov ah, 0x05
    int 0x21
    mov al, 0x0a
    int 0x21
    pop ax
    
    cmp al, "0"
    je .source_a_drive

    cmp al, "1"
    je .source_b_drive

    jmp exit
.source_a_drive:
    mov [source_drive], 0
    jmp .get_dest
.source_b_drive:
    mov [source_drive], 1
.get_dest:
    xor ah, ah
    lea si, [msg_dest]
    int 0x21

    xor ah, ah
    int 0x16

    push ax
    mov ah, 0x05
    int 0x21
    mov al, 0x0a
    int 0x21
    pop ax

    cmp al, "0"
    je .dest_a_drive

    cmp al, "1"
    je .dest_b_drive

    jmp exit
.dest_a_drive:
    mov [dest_drive], 0
    jmp get_file
.dest_b_drive:
    mov [dest_drive], 1

get_file:
    xor ah, ah
    lea si, [msg_file]
    int 0x21

    xor ax, ax
    lea di, [typing_buffer]
    mov cx, 12/2
    rep stosw

    xor di, di
.typing:
    xor ax, ax
    int 0x16
    cmp al, 0x0d
    je get_new_file
    cmp al, 0x08
    je .backspace
    cmp di, 12
    jae .typing
    mov [typing_buffer + di], al
    mov ah, 0x05
    int 0x21
    inc di
    jmp .typing
.backspace:
    cmp di, 0
    jna .typing
    dec di
    mov ah, 0x05
    mov byte [typing_buffer + di], 0
    int 0x21
    mov al, " "
    int 0x21
    mov al, 0x08
    int 0x21
    jmp .typing

get_new_file:
    mov ah, 0x05
    mov al, 0x0a
    int 0x21

    xor ah, ah
    lea si, [msg_new_file]
    int 0x21

    xor ax, ax
    lea di, [typing_buffer_2]
    mov cx, 12/2
    rep stosw

    xor di, di
.typing:
    xor ax, ax
    int 0x16
    cmp al, 0x0d
    je do_copy
    cmp al, 0x08
    je .backspace
    cmp di, 12
    jae .typing
    mov [typing_buffer_2 + di], al
    mov ah, 0x05
    int 0x21
    inc di
    jmp .typing
.backspace:
    cmp di, 0
    jna .typing
    dec di
    mov ah, 0x05
    mov byte [typing_buffer_2 + di], 0
    int 0x21
    mov al, " "
    int 0x21
    mov al, 0x08
    int 0x21
    jmp .typing

do_copy:
    mov ah, 0x05
    mov al, 0x0a
    int 0x21

    mov ah, 0x03
    mov dl, [source_drive]
    int 0x21

    mov ah, 0x06
    lea si, [typing_buffer]
    int 0x21
    test al, al
    jz error_not_file

    mov ah, 0x01
    lea si, [typing_buffer]
    int 0x21

    mov ah, 0x0f
    int 0x21
    
    mov ah, 0x03
    mov dl, [dest_drive]
    int 0x21

    mov ah, 0x0c
    lea si, [typing_buffer_2]
    int 0x21

    mov ah, 0x03
    mov dl, [original_drive]
    int 0x21

    mov ah, 0x0e
    mov bl, 0x0a
    int 0x21

    xor ah, ah
    lea si, [msg_done]
    int 0x21

exit:
    retf

error_not_file:
    mov ah, 0x0e
    mov bl, 0x0c
    int 0x21

    xor ah, ah
    lea si, [msg_err_not_file]
    int 0x21

    retf

msg_start db "COPYF.COM - file copying utility", 0x0a, 0x0a, 0
msg_source db "Select the drive you want to copy the file off from [0 for A:, 1 for B:] ", 0
msg_dest db "Select the drive you want to copy the file onto [0 for A:, 1 for B:] ", 0
msg_file db "Type the name of the file you wish to copy: ", 0
msg_new_file db "Type the name of the new file: ", 0
msg_done db "Done :)", 0x0a, 0

msg_err_not_file db "Not a file that exists!", 0x0a, 0

original_drive db 0
source_drive db 0
dest_drive db 0

typing_buffer db 12 dup(" ")
typing_buffer_2 db 12 dup(" ")