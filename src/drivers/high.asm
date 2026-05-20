use16

macro patch num, handler, rcs {
    mov word [es:num*4], handler
    mov word [es:num*4+2], rcs
}

main:
    mov ax, cs
    mov ds, ax
    mov es, ax

    push es
    xor ax, ax
    mov es, ax
    mov ax, cs
    patch 0xa2, get_a20_state_int, ax
    pop es

    mov ah, 0x09
    int 0x21

    call get_a20_state
    cmp ax, 1
    je exit_msg

enable_a20_interrupt:
    mov ax, 0x2401
    int 0x15

    call get_a20_state
    cmp ax, 1
    je exit

    ; keyboard controller method is very odd so im just gonna ignore the fact that it exists

    mov ah, 0x0e
    mov bl, 0x0c
    int 0x21

    xor ah, ah
    lea si, [msg_err_not_enabled]
    int 0x21

    jmp exit

enable_a20_keyboard:
    cli

    call a20_wait
    mov dx, 0x64
    mov al, 0xad
    out dx, al

    call a20_wait
    mov al, 0xd0
    out dx, al

    call a20_wait_2
    mov dx, 0x60
    in al, dx
    push ax

    call a20_wait
    mov dx, 0x64
    mov al, 0xd1
    out dx, al

    call a20_wait
    mov dx, 0x60
    pop ax
    or al, 2
    out dx, al

    call a20_wait
    mov dx, 0x64
    mov al, 0xae
    out dx, al

    call a20_wait

    sti

    call get_a20_state
    cmp ax, 1
    je exit

exit_msg:
    mov ah, 0x0e
    mov bl, 0x0a
    int 0x21

    xor ah, ah
    lea si, [msg_already_enabled]
    int 0x21

exit:
    retf

; out:
;  ax - state (0 - disabled, 1 - enabled)
get_a20_state:
    pushf
    push si
    push di
    push ds
    push es
    cli

    mov ax, 0x0000					;	0x0000:0x0500(0x00000500) -> ds:si
    mov ds, ax
    mov si, 0x0500

    not ax						    ;	0xffff:0x0510(0x00100500) -> es:di
    mov es, ax
    mov di, 0x0510

    mov al, [ds:si]					;	save old values
    mov byte [.BufferBelowMB], al
    mov al, [es:di]
    mov byte [.BufferOverMB], al

    mov ah, 1
    mov byte [ds:si], 0
    mov byte [es:di], 1
    mov al, [ds:si]
    cmp al, [es:di]					;	check byte at address 0x0500 != byte at address 0x100500
    jne .exit
    dec ah
.exit:
    mov al, [.BufferBelowMB]
    mov [ds:si], al
    mov al, [.BufferOverMB]
    mov [es:di], al
    shr ax, 8					    ;	move result from ah to al register and clear ah
    pop es
    pop ds
    pop di
    pop si
    popf
    ret
    
.BufferBelowMB:	db 0
.BufferOverMB	db 0

a20_wait:
    mov dx, 0x64
    in al, dx
    test al, 2
    jnz a20_wait
    ret

a20_wait_2:
    mov dx, 0x64
    in al, dx
    test al, 1
    jnz a20_wait_2
    ret

get_a20_state_int:
    call get_a20_state
    iret

msg_already_enabled db "    * The A20 line is already enabled by the BIOS! :)", 0x0a, 0
msg_err_not_enabled db "    * A20 line failed to enable", 0x0a, 0