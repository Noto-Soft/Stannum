org 0x7c00
use16

jmp short main
nop

bdb_oem:                    db 'MSWIN4.1'
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 1
bdb_dir_entries_count:      dw 0x00e0
bdb_total_sectors:          dw 2880
bdb_media_descriptor_type:  db 0x00f0
bdb_sectors_per_fat:        dw 9
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

ebr_drive_number:           db 0
                            db 0
ebr_signature:              db 0x29
ebr_volume_id:              dd 0x12, 0x34, 0x56, 0x78
ebr_volume_label:           db 'STANNUM    '
ebr_system_id:              db 'FAT12   '

main:
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov sp, ax
    mov ax, 0x7000
    mov ss, ax

    mov [ebr_drive_number], dl

    push es
    mov ah, 0x08
    int 0x13
    jc floppy_error
    pop es

    and cl, 0x3f
    xor ch, ch
    mov [bdb_sectors_per_track], cx

    inc dh
    mov byte [bdb_heads], dh
    mov byte [bdb_heads + 1], 0

    call prepare_print
    mov cl, msg_loading_len
    lea bp, [msg_loading]
    int 0x10

    mov ax, [bdb_sectors_per_fat]
    mov bl, [bdb_fat_count]
    xor bh, bh
    mul bx
    add ax, [bdb_reserved_sectors]
    push ax

    mov ax, [bdb_dir_entries_count]
    shl ax, 5
    xor dx, dx
    div word [bdb_bytes_per_sector]

    test dx, dx
    jz .root_dir_after
    inc ax
.root_dir_after:
    mov cl, al
    pop ax
    mov dl, [ebr_drive_number]
    lea bx, [buffer]
    call disk_read

    xor bx, bx
    lea di, [buffer]
.search_kernel:
    lea si, [file_kernel_bin]
    mov cx, 11
    push di
    repe cmpsb
    pop di
    je .found_kernel

    add di, 32
    inc bx
    cmp bx, [bdb_dir_entries_count]
    jl .search_kernel

    jmp kernel_not_found_error
.found_kernel:
    mov ax, [di + 26]
    mov [kernel_cluster], ax

    mov ax, [bdb_reserved_sectors]
    lea bx, [buffer]
    mov cl, [bdb_sectors_per_fat]
    mov dl, [ebr_drive_number]
    call disk_read

    mov bx, KERNEL_LOAD_SEGMENT
    mov es, bx
    mov bx, KERNEL_LOAD_OFFSET
.load_kernel_loop:
    ;mov ax, [kernel_cluster]

    ;add ax, 31 ; FIX THIS
    xor ah, ah
    mov al, [bdb_fat_count]
    mov cx, [bdb_sectors_per_fat]
    mul cx
    mov cx, [bdb_dir_entries_count]
    shr cx, 4
    add ax, cx
    dec ax
    add ax, [kernel_cluster]

    mov cl, 1
    mov dl, [ebr_drive_number]
    call disk_read

    add bx, [bdb_bytes_per_sector]

    mov ax, [kernel_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx

    lea si, [buffer]
    add si, ax
    mov ax, [ds:si]
    
    or dx, dx
    jz .even
.odd:
    shr ax, 4
    jmp .next_cluster_after
.even:
    and ax, 0x0fff
.next_cluster_after:
    cmp ax, 0x0ff8
    jae .read_finish

    mov [kernel_cluster], ax
    jmp .load_kernel_loop
.read_finish:
    mov dl, [ebr_drive_number]

    jmp KERNEL_LOAD_SEGMENT:KERNEL_LOAD_OFFSET

prepare_print:
    push cx
    mov ah, 0x3
    xor bh, bh
    int 0x10

    mov ah, 0x13
    mov al, 0x01
    xor bh, bh
    pop cx
    mov ch, bh
    mov bl, 0x0f
    ret

; Converts an LBA address to a CHS address
; Parameters:
;   - ax: LBA address
; Returns:
;   - cx [bits 0-5]: sector number
;   - cx [bits 6-15]: cylinder
;   - dh: head
lba_to_chs:

    push ax
    push dx

    ; dx = 0
    xor dx, dx
    ; ax = LBA / SectorsPerTrack
    div word [bdb_sectors_per_track]
                                        ; dx = LBA % SectorsPerTrack

    ; dx = (LBA % SectorsPerTrack + 1) = sector
    inc dx
    ; cx = sector
    mov cx, dx

    ; dx = 0
    xor dx, dx
    ; ax = (LBA / SectorsPerTrack) / Heads = cylinder
    div word [bdb_heads]
                                        ; dx = (LBA / SectorsPerTrack) % Heads = head
    ; dh = head
    mov dh, dl
    ; ch = cylinder (lower 8 bits)
    mov ch, al
    push cx
    mov cl, 6
    shl ah, cl
    pop cx
    ; put upper 2 bits of cylinder in CL
    or cl, ah

    pop ax
    ; restore DL
    mov dl, al
    pop ax
    ret


; Reads sectors from a disk
; Parameters:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx: memory address where to store read data
disk_read:

    ; save registers we will modify
    push ax
    push bx
    push cx
    push dx
    push di

    ; temporarily save CL (number of sectors to read)
    push cx
    ; compute CHS
    call lba_to_chs
    ; AL = number of sectors to read
    pop ax

    mov ah, 0x02
    ; retry count
    mov di, 3

.retry:
    ; save all registers, we don't know what bios modifies
    pusha
    ; set carry flag, some BIOS'es don't set it
    stc
    ; carry flag cleared = success
    int 0x13
    ; jump if carry not set
    jnc .done

    ; read failed
    popa ; macro
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    ; all attempts are exhausted
    jmp floppy_error

.done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    ; restore registers modified
    pop ax
    ret

; Resets disk controller
; Parameters:
;   - dl: drive number
disk_reset:
    pusha
    xor ah, ah
    stc
    int 0x13
    jc floppy_error
    popa
    ret

kernel_not_found_error:
    lea bp, [msg_err_missing]
    mov cl, msg_err_missing_len
    jmp error

floppy_error:
    lea bp, [msg_err_floppy]
    mov cl, msg_err_floppy_len

error:
    call prepare_print
    int 0x10

    cli
    hlt

msg_loading db "Loading kernel", 0x0d, 0x0a
msg_loading_len = $-msg_loading

msg_err_floppy db "Disk error"
msg_err_floppy_len = $-msg_err_floppy

msg_err_missing db "Kernel not found"
msg_err_missing_len = $-msg_err_missing

KERNEL_LOAD_SEGMENT = 0x1000
KERNEL_LOAD_OFFSET = 0x0000

file_kernel_bin db "KERNEL  BIN"

db 510-($-$$) dup(0)
dw 0xaa55

kernel_cluster dw ?

label buffer