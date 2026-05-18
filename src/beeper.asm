use16

main:
    mov ax, es
    mov ds, ax
    mov ax, cs
    mov es, ax

    lea di, [argument]
    mov cx, 12
    rep movsb

    mov ax, cs
    mov ds, ax

    cmp byte [argument], " "
    je error

    mov ah, 0x01
    lea si, [argument]
    int 0x21
    mov [block], bx
    
    mov ah, 0x0b
    int 0x21
    mov ds, bx

    xor si, si
.loop:
    mov bx, [si]
    add si, 2
    test bx, bx
    jz .nothing
    cmp bx, 0xffff
    je .done
    cmp bx, 0xfffe
    je .turn_off
    mov ah, 0x01
    int 0x32
    xor ah, ah
    int 0x32
    jmp .nothing
.turn_off:
    mov ah, 0x02
    int 0x32
.nothing:
    call wait_note
    jmp .loop
.done:
    mov ah, 0x02
    int 0x32

    mov ax, cs
    mov ds, ax

    mov ah, 0x08
    mov bx, [block]
    int 0x21

    retf

error:
    xor ah, ah
    lea si, [msg_err_supply_filename]
    int 0x21

    retf

msg_err_supply_filename db "Must supply filename!", 0x0d, 0x0a, 0

argument db 12 dup(0)
block dw 0

wait_note:
    pusha
    mov ah, 0x86
    mov cx, 0x2
    mov dx, 0x8b0a
    int 0x15
    popa
    ret