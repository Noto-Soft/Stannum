; serial.drv - driver for i/o through COM1
; uses 0x36 (0x20 above 0x16)

use16

include '../inc/wrap.inc'

main:
    mov ax, cs
    mov ds, ax

    mov dx, 0x3fb
    mov al, 0x80
    out dx, al

    mov dx, 0x3f8
    mov al, 0x03
    out dx, al
    mov dx, 0x3f9
    mov al, 0x00
    out dx, al

    mov dx, 0x3fb
    mov al, 0x03
    out dx, al

    mov dx, 0x3fa
    mov al, 0xc7
    out dx, al

    mov dx, 0x3fc
    mov al, 0x0b
    out dx, al

    mov ah, 0x0e
    mov bl, 0x0a
    int 0x21

    xor ah, ah
    lea si, [msg_initialized]
    int 0x21

    wrap 0x36, wrapint36h

    mov ah, 0x09
    int 0x21

    retf

read_serial:
    push dx
.wait:
    mov dx, 0x3fd
    in al, dx
    test al, 0x01
    jz .wait

    mov dx, 0x3f8
    in al, dx
    pop dx
    ret

write_serial:
    push dx
    push ax
.wait:
    mov dx, 0x3fd
    in al, dx
    test al, 0x20
    jz .wait

    mov dx, 0x3f8
    pop ax
    out dx, al
    pop dx
    ret

stub:
    sub sp, 2
    jmp far dword [cs:offset_original]

wrapint36h:
    push si
    push ax
    mov al, ah
    xor ah, ah
    mov si, ax
    pop ax
    shl si, 1
    push ax
    mov ax, [cs:.call_table+si]
    mov [cs:call_value], ax
    pop ax
    pop si
    call word [cs:call_value]
    iret
.call_table:
    dw write_serial, read_serial
    dw (256-($-.call_table))/2 dup(stub)

msg_initialized db "    * Port COM1 initialized", 0x0a, 0

offset_original dw 0
segment_original dw 0

call_value dw 0