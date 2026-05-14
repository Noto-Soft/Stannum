use16

main:
    mov ax, cs
    mov ds, ax
    mov es, ax

    push es
    xor ax, ax
    mov es, ax
    mov ax, [es:0x21 * 4]
    mov [offset_original], ax
    mov ax, [es:0x21 * 4 + 2]
    mov [segment_original], ax
    mov word [es:0x21 * 4], wrapint21h
    mov ax, cs
    mov [es:0x21 * 4 + 2], ax
    pop es

    mov ah, 0x09
    int 0x21

    retf

wrapint21h:
    push ax
    push ds
    push si
    mov ax, cs
    mov ds, ax
    lea si, [annoying_message]
    call puts
    pop si
    pop ds
    pop ax
    jmp far dword [cs:offset_original]

puts:
    push ax
    push bx
    push si
    xor bh, bh
    mov ah, 0x0e
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    pop si
    pop bx
    pop ax
    ret

annoying_message db "Hey ked! this is a test of tsr, see ked you left me but im still here", 0x0d, 0x0a, "gonna have to reboot to make me go away ked! or just keep adding more ked", 0x0a, 0x0d, "LULZ", 0x0a, 0x0d, 0

offset_original dw 0
segment_original dw 0