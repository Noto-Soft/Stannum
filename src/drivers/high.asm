use16

macro patch num, handler, rcs {
    mov word [es:num*4], handler
    mov word [es:num*4+2], rcs
}

include '../inc/wrap.inc'

main:
    mov ax, cs
    mov ds, ax
    mov es, ax

    xor ah, ah
    lea si, [msg_enabling]
    int 0x21

    push es
    xor ax, ax
    mov es, ax
    mov ax, cs
    patch 0xa2, get_a20_state_int, ax
    pop es

    wrap 0x40, wrapint40h

    mov ah, 0x09
    int 0x21

    call get_a20_state
    cmp ax, 1
    je preenabled

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

exit:
    retf

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

preenabled:
    mov ah, 0x0e
    mov bl, 0x0a
    int 0x21

    xor ah, ah
    lea si, [msg_already_enabled]
    int 0x21

    mov ah, 0x0e
    mov bl, 0x07
    int 0x21

    xor ah, ah
    lea si, [msg_setting]
    int 0x21

    xor ax, ax
    mov es, ax

    lea si, [seg_zero_code_start]
    lea di, [0x2000]
    mov cx, seg_zero_code_size
    rep movsb

    push ds
    push es
    call far [far_call_ptr]
    pop es
    pop ds

    mov byte [fs:0x2000], 69
    mov al, [fs:0x2000]
    cmp al, 69
    jne failed_unknown

    mov ah, 0x0e
    mov bl, 0x0a
    int 0x21

    xor ah, ah
    lea si, [msg_success]
    int 0x21

    retf

failed_unknown:
    mov ah, 0x0e
    mov bl, 0x0c
    int 0x21

    xor ah, ah
    lea si, [msg_failed]
    int 0x21

    cli
    hlt

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

ack:
    jmp far 0x1000:0x0000

; in: cx: size
; out: bx: block start
allocate_this_much:
    push ax
    push dx
    push cx
    push di
    mov ax, cx
    call get_smallest_contiguous_free_memory_above_size
    cmp cx, ax
    jne ack

    mov cx, ax
    dec cx
    mov al, 0xf8 ; 0xf8 is taken block
    lea di, [mem_blocks + bx]
    push es
    push ax
    mov ax, cs
    mov es, ax
    pop ax
    rep stosb
    pop es

    mov byte [cs:di], 0xff ; make the final allocated block 0xff [end of chunk]

    pop di
    pop cx
    pop dx
    pop ax
    ret

; bx - starting block
deallocate:
    push ax
    push bx
    push si
    lea si, [mem_blocks + bx]
    mov al, [cs:si]
    cmp al, 0xf8
    jnae .done
.deallocate_loop:
    mov al, [cs:si]
    cmp al, 0xff
    je .reached_end
    mov byte [cs:si], 0x00
    inc si
    jmp .deallocate_loop
.reached_end:
    mov byte [cs:si], 0x00
.done:
    pop si
    pop bx
    pop ax
    ret

; cx - desired size
; returns:
;   bx - starting block (0xffff if none applicable found)
; remember blocks are 1KiB large!
get_smallest_contiguous_free_memory_above_size:
    push ax
    push cx
    push si
    mov [cs:smallest_mem_block], 0xffff
    mov [cs:desired_size], cx

    xor bx, bx ; bx will contain the first contiguous free block
    xor si, si ; si will contain the current one
    xor cx, cx ; cl will contain the size just for simplicity, could be done using maths though (ew)
.go_over_blocks:
    cmp si, MEM_BLOCKS
    je .block_taken
    ja .done_looking
    mov al, [cs:mem_blocks + si]
    test al, al
    jnz .block_taken
    inc si
    inc cx
    jmp .go_over_blocks
.block_taken:
    cmp cx, [cs:desired_size]
    jnae .useless_for_my_purposes
    mov [cs:smallest_mem_block], bx
    jmp .done_looking
.useless_for_my_purposes:
    inc si
    mov bx, si
    xor cx, cx
    jmp .go_over_blocks
.done_looking:
    mov bx, [cs:smallest_mem_block]

    cmp bx, 0xffff
    jne .whatever
    jmp far 0x1000:0x0000
.whatever:
    pop si
    pop cx
    pop ax
    ret

allocate_pointer:
    xor ebx, ebx
    call allocate_this_much
    shl ebx, 10
    add ebx, MEM_START
    ret

deallocate_pointer:
    push ebx
    sub ebx, MEM_START
    shr ebx, 10
    call deallocate
    pop ebx
    ret

stub:
    ret

wrapint40h:
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
    dw allocate_pointer, deallocate_pointer
    dw (256-($-.call_table))/2 dup(stub)

msg_enabling db "[HIGH.DRV] Enabling high memory", 0x0a, 0
msg_already_enabled db "    * The A20 line is already enabled by the BIOS! :)", 0x0a, 0
msg_err_not_enabled db "    * A20 line failed to enable", 0x0a, 0
msg_setting db "[HIGH.DRV] Setting up flat segment...", 0x0a, 0
msg_success db "    * Successfully enabled flat segment! :3", 0x0a, 0
msg_failed db "    * Unknown failure", 0x0a, 0

label far_call_ptr
dw 0x2000
dw 0x0000

offset_original dw 0
segment_original dw 0

call_value dw 0

MEM_BLOCKS = (0x200000 - 0x100000) / 1024
MEM_START = 0x100000
mem_blocks db MEM_BLOCKS dup(0)

smallest_mem_block dw 0
desired_size dw 0

seg_zero_code_start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax

    cli
    lgdt [(0x2000 + (gdt_desc - seg_zero_code_start))]
    mov eax, cr0
    or eax, 0x01
    mov cr0, eax

    jmp 0x08:(0x2000 + (pmode - seg_zero_code_start))

pmode:
    mov bx, 0x10
    mov fs, bx

    mov eax, cr0
    and eax, not 0x01
    mov cr0, eax

    jmp 0x00:(0x2000 + (unreal - seg_zero_code_start))

unreal:
    sti

    retf   

label gdt

gdt_null:
    dq 0

gdt_code:
    dw 0xffff
    dw 0
    db 0
    db 10011010b
    db 00000000b
    db 0

gdt_data:
    dw 0xffff
    dw 0
    db 0
    db 10010010b
    db 11001111b
    db 0

gdt_desc:
    dw $ - gdt - 1
    dd 0x2000 + (gdt - seg_zero_code_start)

label seg_zero_code_end

seg_zero_code_size = seg_zero_code_end - seg_zero_code_start