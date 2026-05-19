; vga.dev - driver for vga graphics
; uses int 0x30
; for speed purposes, (as these functions are gonna be called lots and lots in graphics programs)
;   the functions are not directly called by the interrupt. instead they will have interrupts
;   that pass the far pointers to the functions, to bypass the interrupt overhead from both
;   passing more on the stack, and having to go through the call table

use16

include 'inc/wrap.inc'

main:
    wrap 0x30, wrapint30h

    mov ah, 0x09
    int 0x21

    retf

; al - color
; cx - column
; dx - row
; thank you so much unnamed author
;   https://www.fysnet.net/modex.htm
; code taken mostly verbatim with just a few optimizations
;   optimizations mostly just removing unneeded memory reads, speeds it up like 1.5x or so
write_pixel_12h:
    push bx
    push dx
    push cx

    push ax ; we save ax seperately to save a memory load later

    mov ax, dx ; calculate offset
    mov dx, 80
    mul dx ; ax = y * 80
    mov bx, cx
    mov cl, bl ; save low byte for below
    shr bx, 3 ; div by 8
    add bx, ax ; bx = offset this group of 8 pixels

    mov dx, 0x3ce ; set to video hardware controller

    and cl, 0x07 ; Compute bit mask from X-coordinates
    xor cl, 0x07 ;  and put in ah
    mov ah, 0x01
    shl ah, cl
    mov al, 0x08 ; bit mask register
    out dx, ax

    mov ax, 0x205 ; read mode 0, write mode 2
    out dx, ax
    
    push es
    mov cx, 0xa000
    mov es, cx

    mov al, [es:bx] ; load to latch register
    pop ax
    mov [es:bx], al ; write to register

    pop es

    pop cx
    pop dx
    pop bx
    retf

; al - color
; cx - column
; dx - row
write_pixel_13h:
    push bx
    push dx
    push es

    mov bx, 0xa000
    mov es, bx

    push ax

    mov ax, dx
    xor dx, dx
    mov bx, 320
    mul bx

    mov bx, ax

    pop ax

    add bx, cx

    mov [es:bx], al

    pop es
    pop dx
    pop bx
    retf

get_write_pixel_12h_ptr:
    mov bx, cs
    mov ax, word write_pixel_12h
    ret

get_write_pixel_13h_ptr:
    mov bx, cs
    mov ax, word write_pixel_13h
    ret

stub:
    ret

wrapint30h:
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
    dw get_write_pixel_12h_ptr, get_write_pixel_13h_ptr
    dw (256-($-.call_table))/2 dup(stub)

offset_original dw 0
segment_original dw 0

call_value dw 0