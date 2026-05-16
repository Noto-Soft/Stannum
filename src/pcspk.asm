; pcspk.drv - driver for pc speaker
; uses int 0x32

use16

include 'inc/wrap.inc'

main:
    wrap 0x32, wrapint32h

    mov ah, 0x09
    int 0x21

    retf

; bx - frequency
set_freq:
    push dx
    push bx
    push cx
    push eax

    cmp bx, 0
    jz .done

    mov eax, PIT_BASE_FREQ
    xor edx, edx
    div ebx

    cmp eax, 0x10000
    jb  .ok
    mov eax, 0xFFFF
.ok:
    mov cx, ax

    mov al, 10110110b
    out 0x43, al

    mov ax, cx
    out 0x42, al
    mov al, ah
    out 0x42, al
.done:
    pop eax
    pop cx
    pop bx
    pop dx
    ret

speaker_on:
    push ax
    in al, PORT_SPEAKER
    or al, 00000011b
    out PORT_SPEAKER, al
    pop ax
    ret

speaker_off:
    push ax
    in al, PORT_SPEAKER
    and al, 11111100b
    out PORT_SPEAKER, al
    pop ax
    ret

stub:
    sub sp, 2
    jmp far dword [cs:offset_original]

wrapint32h:
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
    dw set_freq, speaker_on, speaker_off
    dw (256-($-.call_table))/2 dup(stub)

offset_original dw 0
segment_original dw 0

call_value dw 0

PORT_SPEAKER = 0x61
PIT_BASE_FREQ = 1193180