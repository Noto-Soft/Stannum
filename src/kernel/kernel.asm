use16

macro patch num, handler, rcs {
    mov word [es:num*4], handler
    mov word [es:num*4+2], rcs
}

main:
    mov ax, cs
    mov ds, ax
    mov es, ax

    mov ss, ax
    lea sp, [stack_top]

    call reset_vga_text_mode

    mov [text_attribute], 0x0e
    lea si, [msg_logo]
    call puts
    mov [text_attribute], 0x07
    lea si, [msg_credit]
    call puts

    lea si, [msg_patching]
    call puts

    push es
    xor ax, ax
    mov es, ax
    mov ax, cs
    patch 0x21, int21, ax
    patch 0x22, disk_read_interrupt_wrapper, ax
    patch 0x23, disk_write_interrupt_wrapper, ax
    pop es

    mov [deadly_errors], 0

    xor al, al
    mov cx, MEM_BLOCKS
    lea di, [mem_blocks]
    rep stosb

    call load_fat12_info

    lea si, [msg_loading_a20]
    call puts

    lea si, [file_high_drv]
    call run_program

    mov [text_attribute], 0x07

    lea si, [msg_loading_serial]
    call puts

    lea si, [file_serial_dev]
    call run_program

    mov [text_attribute], 0x07

    lea si, [msg_loading_pcspk]
    call puts

    lea si, [file_pcspk_dev]
    call run_program

    mov [text_attribute], 0x07

    lea si, [msg_loading_vga]
    call puts

    lea si, [file_vga_dev]
    call run_program

    mov ah, 0x02
    mov cl, 1
    int 0x30

    ; done printing startup messages
    ; put newline for spacing idk look good
    lea si, [newline]
    call puts

    lea si, [file_scli_com]
    xor bx, bx
    call run_program

    lea si, [msg_kernel_done]
    call puts

halt:
    cli
    hlt

; cl - amount to allocate
; returns:
;   bx - starting block
allocate_this_much:
    push ax
    push dx
    push cx
    push di
    mov al, cl
    call get_smallest_contiguous_free_memory_above_size
    cmp cl, al
    jnae kernel_panic   ; out of free memory!! panic!!! (there is basically no way to safely recover from this)
                        ; this will get thrown if a file too large to fit into memory is attempted to be allocated, 
                        ; so just very large files CAN set this off, but whatever who cares

    mov cl, al
    dec cl
    mov al, 0xf8 ; 0xf8 is taken block
    lea di, [mem_blocks + bx]
    rep stosb

    mov byte [di], 0xff ; make the final allocated block 0xff [end of chunk]

    pop di
    pop cx
    pop dx
    pop ax
    ret

; bx - block
deallocate_interrupt_wrapper:
    push ax
    push ds
    mov ax, cs
    mov ds, ax
    call deallocate
    pop ds
    pop ax
    ret

; bx - starting block
deallocate:
    push ax
    push bx
    push si
    lea si, [mem_blocks + bx]
    mov al, [si]
    cmp al, 0xf8
    jnae .done
    cmp al, 0xf9
    je .done ; do not mess with resident program! pls!
.deallocate_loop:
    mov al, [si]
    cmp al, 0xff
    je .reached_end
    mov byte [si], 0x00
    inc si
    jmp .deallocate_loop
.reached_end:
    mov byte [si], 0x00
.done:
    pop si
    pop bx
    pop ax
    ret

; cl - desired size
; returns:
;   bx - starting block
;   cl - size
; remember blocks are 2KiB large!
get_smallest_contiguous_free_memory_above_size:
    push ax
    push si
    mov [smallest_mem_block], 0xffff
    mov [smallest_mem_block_size], 0xff
    mov [desired_size], cl

    xor bx, bx ; bx will contain the first contiguous free block
    xor si, si ; si will contain the current one
    xor cl, cl ; cl will contain the size just for simplicity, could be done using maths though (ew)
.go_over_blocks:
    cmp si, MEM_BLOCKS
    je .block_taken
    ja .done_looking
    mov al, [mem_blocks + si]
    test al, al
    jnz .block_taken
    inc si
    inc cl
    jmp .go_over_blocks
.block_taken:
    cmp cl, [desired_size]
    jnae .useless_for_my_purposes
    cmp cl, [smallest_mem_block_size]
    jnb .useless_for_my_purposes
    mov [smallest_mem_block], bx
    mov [smallest_mem_block_size], cl
.useless_for_my_purposes:
    inc si
    mov bx, si
    xor cl, cl
    jmp .go_over_blocks
.done_looking:
    mov bx, [smallest_mem_block]
    mov cl, [smallest_mem_block_size]

    cmp bx, 0xffff
    je kernel_panic

    pop si
    pop ax
    ret

; cs - segment of the program wishing to stay resident (the entire program will stay resident. scary)
stay_resident_after_terminate:
    push ax
    push bx

    mov bx, [cs:int_stack]
    mov bx, [ss:bx + 2]
    sub bx, 0x2000
    shr bx, 7
    
.until_found_end:
    mov al, [cs:mem_blocks + bx]
    cmp al, 0xff
    je .found_end
    mov byte [cs:mem_blocks + bx], 0xf9 ; resident program
    inc bx
    jmp .until_found_end
.found_end:
    mov byte [cs:mem_blocks + bx], 0xf9 ; resident program

    pop bx
    pop ax
    ret

; bx - block id
; returns:
;   bx - segment
get_segment_from_block_id:
    shl bx, 7
    add bx, MEM_START
    ret

; bx - segment
; returns:
;   bx - block id
get_block_id_from_segment:
    sub bx, MEM_START
    shr bx, 7
    ret

putc:
    cmp al, 0x0d
    je .done_early
    cmp al, 0x0a
    je .newline
    push bx
    push ax
    push cx
    mov ah, 0x09
    mov al, " "
    xor bh, bh
    mov bl, [cs:text_attribute]
    mov cx, 2
    int 0x10
    pop cx
    pop ax
    push ax
    mov ah, 0x0e
    xor bh, bh
    int 0x10
    pop ax
    pop bx
.done_early:
    ret
.newline:
    push ax
    push bx
    mov ah, 0x0e
    xor bh, bh
    int 0x10
    mov al, 0x0d
    int 0x10
    push cx
    mov ah, 0x09
    mov al, " "
    xor bh, bh
    mov bl, [cs:text_attribute]
    mov cx, 1
    int 0x10
    pop cx
    pop bx
    pop ax
    ret

puts:
    push ax
    push si
.loop:
    lodsb
    test al, al
    jz .done
    call putc
    jmp .loop
.done:
    pop si
    pop ax
    ret

; bl - attribute
set_text_attribute:
    mov [cs:text_attribute], bl
    ret

reset_vga_text_mode:
    pusha
    mov ax, 0x0003
    int 0x10
    mov ax, 0x1112
    xor bl, bl
    int 0x10
    mov ah, 0x02
    mov cl, 1
    int 0x30
    popa
    ret

putm:
    push ax
    push bx
    push dx
    push cx
    push si
    push ds
    mov ax, cs
    mov ds, ax
    lea si, [msg_putm_guide]
    call puts
    pop ds
    xor cx, cx
    xor si, si
.loop:
    mov al, [cs:mem_blocks + si]
; check used
    cmp al, 0xf8
    jne .check_tsr
    mov al, "^"
    jmp .done_setting_al
.check_tsr:
    cmp al, 0xf9
    jne .check_eoc
    mov al, "*"
    jmp .done_setting_al
.check_eoc:
    cmp al, 0xff
    jne .none
    mov al, "$"
    jmp .done_setting_al
.none:
    mov al, "."
.done_setting_al:
    call putc
    cmp cx, 23
    jne .no_newline
    mov al, 0x0d
    call putc
    mov al, 0x0a
    call putc
    xor cx, cx
    jmp .skip_useless_cx_increment_ya
.no_newline:
    inc cx
.skip_useless_cx_increment_ya:
    inc si
    cmp si, MEM_BLOCKS
    jae .done
    jmp .loop
.done:
    push ax
    push cx
    mov ah, 0x03
    xor bh, bh
    int 0x10
    pop cx
    pop ax
    test dl, dl
    jz .skip_final_newline
    mov al, 0x0d
    call putc
    mov al, 0x0a
    call putc
.skip_final_newline:
    pop si
    pop cx
    pop dx
    pop bx
    pop ax
    ret

; cl (low half) - nibble
putn:
    push ax
    push cx
    and cl, 0x0f
    cmp cl, 0x09
    jnbe .not_numeric
    mov al, cl
    add al, "0"
    call putc
    pop cx
    pop bx
    pop ax
    ret
.not_numeric:
    mov al, cl
    add al, "a" - 10
    call putc
    pop cx
    pop ax
    ret

; cl - byte
putb:
    push cx
    shr cl, 4
    call putn
    pop cx
    call putn
    ret

; cx - word
putw:
    push cx
    mov cl, ch
    call putb
    pop cx
    call putb
    ret

; prints the prefix followed by the 16 bit hex value, removing the leading byte if it is zero
; "pretty hex"
; cx - hex value
put_hex:
    push ax
    mov al, "0"
    call putc
    mov al, "x"
    call putc
    pop ax
    test ch, ch
    jz .put_byte
    call putw
    ret
.put_byte:
    call putb
    ret

; ds:si - program
; ds:bx - program arguments (null terminated, max 127 characters)
run_program:
    push ds
    push es
    pusha
    mov ax, cs
    mov es, ax
    mov si, bx
    test si, si
    jnz .continue_on
    lea si, [reupload]
.continue_on:
    lea di, [run_program_argument_buffer]
    mov cx, 127
    rep movsb
    mov byte [es:run_program_argument_buffer + 127], 0
    popa
    pusha
    call fat12_read_file
    push bx
    mov ax, cs
    mov es, ax
    push ax
    push word .return
    shl bx, 7
    add bx, 0x2000
    push bx
    push word 0
    lea si, [run_program_argument_buffer]
    mov dl, [es:ebr_drive_number]
    retf
.return:
    mov ax, cs
    mov ds, ax
    pop bx
    call deallocate
    popa
    pop es
    pop ds
    ret

; take in a "broken" filename string and turn it into one we can read from fat12
; example:
;   "huh.com\0"    -> "HUH     COM"
;   "WeIRd   CoM"  -> "WEIRD   COM"
;   "ODD.COM    "  -> "ODD     COM"
;   "EIGHTCHR.TXT" -> "EIGHTCHRTXT"
; essentially: capitalizes and moves extensions back
;               turns zeroes in to spaces
;               if the filename goes over 11 characters than fix it (if even fixable)
; throws error and puts a blank (11 spaces) string if:
;   no extension supplied
filename_fixup:
    push ax
    push cx
    push si
    push di
    ; begin by capitalizing the name and turning any zero bytes into spaces
    mov [fat12_read_file_got_zero], 0
    lea si, [fat12_filename]
    lea di, [fat12_filename]
    mov cx, 12
.capitalize_loop:
    lodsb
    cmp [fat12_read_file_got_zero], 1
    je .put_zero
    test al, al
    jnz .dont_put_space
    mov [fat12_read_file_got_zero], 1
.put_zero:
    mov al, " "
    jmp .store_as_is
.dont_put_space:
    cmp al, "a"
    jnae .store_as_is
    cmp al, "z"
    jnbe .store_as_is
    and al, 0xdf
.store_as_is:
    stosb
    loop .capitalize_loop
    ; next detect if there is a dot character between characters 1 and 8 inclusive
    lea si, [fat12_filename + 1]
    mov cx, 8
.find_dot_extension:
    lodsb
    cmp al, "."
    je .found_dot
    loop .find_dot_extension
    ; i got nothing
    ; check we indeed HAVE an extension
    mov al, [fat12_filename + 8]
    cmp al, " "
    jne .done ; we do

    ; otherwise we do not and empty out the file so the read fails!!
    mov al, " "
    mov cx, 11
    lea di, [fat12_filename]
    rep movsb
    jmp .done
.found_dot:
    ; now we move the extension back, removing the dot and the first extension
    lea di, [fat12_read_file_extension_buffer]
    ; si already at the start of the extension
    mov cx, 3
    rep movsb ; move extension over to buffer

    mov al, " "
    mov cx, 4
    mov di, si
    sub di, 4 ; remove the 3 bytes we just read, remove the dot too
    rep stosb ; clear .EXT

    lea si, [fat12_read_file_extension_buffer]
    lea di, [fat12_filename + 8]
    mov cx, 3
    rep movsb ; move our new extension back here
.done:
    pop di
    pop si
    pop cx
    pop ax
    ret

; ds:si - filename
; returns:
;   al - exists (0 for no, 1 for yes)
;   si - entry offset
fat12_file_exists:
    pusha

    push ds
    push es
    mov ax, cs
    mov es, ax

    lea di, [fat12_filename]
    mov cx, 12 ; load an extra byte to account for the possibility of a file with an 8 character name AND a dot for readability
    rep movsb

    mov ax, cs
    mov ds, ax

    call filename_fixup

    call get_lba_and_size_of_root_dir
    mov dl, [ebr_drive_number]
    lea bx, [fat12_buffer]
    call disk_read

    xor bx, bx
    lea di, [fat12_buffer]
.search_file:
    lea si, [fat12_filename]
    mov cx, 11
    push di
    repe cmpsb
    pop di
    je .found_file

    add di, 32
    inc bx
    cmp bx, [bdb_dir_entries_count]
    jl .search_file

    jmp .not_found
.found_file:
    sub di, fat12_buffer
    mov [fat12_file_entry_offset], di
    pop es
    pop ds
    popa
    mov al, 0x01
    mov si, [fat12_file_entry_offset]
    ret
.not_found:
    pop es
    pop ds
    popa
    xor al, al
    ret

; ds:si - filename
; returns:
;   ecx - size in bytes
fat12_read_file_size:
    pusha

    push ds
    push es
    mov ax, cs
    mov es, ax

    lea di, [fat12_filename]
    mov cx, 12 ; load an extra byte to account for the possibility of a file with an 8 character name AND a dot for readability
    rep movsb

    mov ax, cs
    mov ds, ax

    call filename_fixup

    call get_lba_and_size_of_root_dir
    mov dl, [ebr_drive_number]
    lea bx, [fat12_buffer]
    call disk_read

    xor bx, bx
    lea di, [fat12_buffer]
.search_kernel:
    lea si, [fat12_filename]
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
    mov [fat12_read_file_file_cluster], ax
    mov ecx, [di + 28]
    mov [fat12_read_file_size_filesize], ecx

    pop es
    pop ds
    popa
    mov ecx, [fat12_read_file_size_filesize]
    ret

; ds:si - filename
; returns:
;   bx - block file was read to (convert it to usable segment with shift left 7 and add 0x2000)
fat12_read_file:
    pusha

    push ds
    push es
    mov ax, cs
    mov es, ax

    lea di, [fat12_filename]
    mov cx, 12 ; load an extra byte to account for the possibility of a file with an 8 character name AND a dot for readability
    rep movsb

    mov ax, cs
    mov ds, ax

    call filename_fixup

    call get_lba_and_size_of_root_dir
    mov dl, [ebr_drive_number]
    lea bx, [fat12_buffer]
    call disk_read

    xor bx, bx
    lea di, [fat12_buffer]
.search_kernel:
    lea si, [fat12_filename]
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
    mov [fat12_read_file_file_cluster], ax
    mov ecx, [di + 28]
    add ecx, 2047
    shr ecx, 11
    call allocate_this_much
    mov [fat12_read_file_block], bx
    xor bx, bx
    mov [fat12_read_file_offtemp], bx
    mov bx, [fat12_read_file_block]
    shl bx, 7
    add bx, 0x2000 ; 0x2000 starts the free space
    mov [fat12_read_file_segtemp], bx
    xor ecx, ecx ; clear higher half of eax just for safety

    call fat12_read_fat

    mov bx, [fat12_read_file_segtemp]
    mov es, bx
    mov bx, [fat12_read_file_offtemp]
.load_kernel_loop:
    call fat12_get_data_start
    add ax, [fat12_read_file_file_cluster]

    mov cl, 1
    mov dl, [ebr_drive_number]
    call disk_read

    add bx, [bdb_bytes_per_sector]

    mov ax, [fat12_read_file_file_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx

    lea si, [fat12_buffer]
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

    mov [fat12_read_file_file_cluster], ax
    jmp .load_kernel_loop
.read_finish:
    pop es
    pop ds
    popa
    mov bx, [cs:fat12_read_file_block]
    ret

get_lba_and_size_of_root_dir:
    push bx
    push dx
    mov ax, [cs:bdb_sectors_per_fat]
    mov bl, [cs:bdb_fat_count]
    xor bh, bh
    mul bx
    add ax, [cs:bdb_reserved_sectors]
    push ax

    mov ax, [cs:bdb_dir_entries_count]
    shl ax, 5
    xor dx, dx
    div word [cs:bdb_bytes_per_sector]

    test dx, dx
    jz .root_dir_after
    inc ax
.root_dir_after:
    mov cl, al
    pop ax
    pop dx
    pop bx
    mov bx, [cs:bdb_dir_entries_count]
    ret

; dl - drive
load_fat12_info:
    pusha
    push ds
    push es
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ah, 0x02
    mov al, 1
    xor ch, ch
    mov cl, 1
    xor dh, dh
    lea bx, [bdb]
    int 0x13
    pop es
    pop ds
    popa
    ret

fat12_read_fat:
    push ax
    push bx
    push dx
    push cx
    call fat12_disk_loc_fat
    call disk_read
    pop cx
    pop dx
    pop bx
    pop ax
    ret

fat12_write_fat:
    push ax
    push bx
    push dx
    push cx
    call fat12_disk_loc_fat
    call disk_write
    pop cx
    pop dx
    pop bx
    pop ax
    ret

fat12_disk_loc_fat:
    mov ax, [bdb_reserved_sectors]
    lea bx, [fat12_buffer]
    mov cl, [bdb_sectors_per_fat]
    mov dl, [ebr_drive_number]
    ret

; ax - starting sector of data
fat12_get_data_start:
    xor ah, ah
    mov al, [bdb_fat_count]
    mov cx, [bdb_sectors_per_fat]
    mul cx
    mov cx, [bdb_dir_entries_count]
    shr cx, 4
    add ax, cx
    dec ax
    ret

; returns offset of the first free entry in si, 0xffff if none
fat12_first_free_entry:
    push ax
    push bx
    push cx
    call get_lba_and_size_of_root_dir
    mov [fat12_first_free_entry_entries], bx
    lea bx, [fat12_buffer]
    mov dl, [ebr_drive_number]
    call disk_read

    xor si, si
    mov cx, [fat12_first_free_entry_entries]
.loop:
    mov al, [fat12_buffer + si]
    test al, al
    jz .done
    cmp al, 0xe5
    je .done
    add si, 32
    loop .loop
    mov si, 0xffff
.done:
    pop cx
    pop bx
    pop ax
    ret

; bx - starting cluster
; ecx - size of file in bytes
; ds:si - filename
fat12_write_file_entry:
    pusha
    push ds
    push es
    push ecx
    mov ax, cs
    mov es, ax
    lea di, [fat12_filename]
    mov cx, 12
    rep movsb
    mov ax, cs
    mov ds, ax
    call filename_fixup
    call fat12_first_free_entry
    mov bp, si
    lea si, [fat12_filename]
    lea di, [fat12_buffer + bp]
    mov cx, 11
    rep movsb
    mov word [fat12_buffer + bp + 26], bx
    pop ecx
    mov dword [fat12_buffer + bp + 28], ecx
    call get_lba_and_size_of_root_dir
    lea bx, [fat12_buffer]
    call disk_write
    pop es
    pop ds
    popa
    ret

; assumes fat is already loaded to buffer
; ax - number of cluster
; returns:
;   ax - cluster value
fat12_get_cluster:
    ; offset = cluster# * 2
    ; value = (cluster# & 0x01) ? table[offset] >> 4 : table[offset] & 0xfff

    push dx
    push si
    mov [fat12_cluster_to_use], ax
    shr ax, 1
    add ax, [fat12_cluster_to_use]
    mov si, ax
    mov ax, word [fat12_buffer + si]
    mov dx, [fat12_cluster_to_use]
    and dx, 0x01
    test dl, dl
    jz .even
.odd:
    shr ax, 4
    pop si
    pop dx
    ret
.even:
    and ax, 0x0fff
    pop si
    pop dx
    ret

; assumes fat is already loaded to buffer
; ax - number of cluster
; dx - cluster value
fat12_set_cluster:
    ; offset = cluster# * 2
    ; out_value = (cluster# & 0x01) ? table[offset] & 0x000f | (in_value << 4) : table[offset] & 0xf000 | (in_value & 0x0fff)

    push ax
    push dx
    push si
    mov [fat12_cluster_to_use], ax
    mov [fat12_new_cluster_value], dx
    shr ax, 1
    add ax, [fat12_cluster_to_use]
    mov si, ax
    mov ax, word [fat12_buffer + si]
    mov dx, [fat12_cluster_to_use]
    and dx, 0x01
    test dl, dl
    jz .even
.odd:
    and ax, 0x000f
    mov dx, [fat12_new_cluster_value]
    shl dx, 4
    or ax, dx
    mov word [fat12_buffer + si], ax
    jmp .end
.even:
    and ax, 0xf000
    mov dx, [fat12_new_cluster_value]
    and dx, 0x0fff
    or ax, dx
    mov word [fat12_buffer + si], ax
.end:
    pop si
    pop dx
    pop ax
    ret

; returns:
;   ax - first free cluster number, 0xffff if none
fat12_get_free_cluster:
    xor ax, ax
.loop:
    push ax
    call fat12_get_cluster
    test ax, ax
    pop ax
    jz .found
    inc ax
    cmp ax, 0x0fff
    jna .loop
    mov ax, 0xffff
.found:
    ret

; bx - starting block of file
; ecx - size in bytes
; ds:si - filename
fat12_write_file:
    pusha
    call fat12_delete_file ; delete file and its clusters if it exists
    push ds
    push es
    mov ax, cs
    mov ds, ax
    mov es, ax

    call get_segment_from_block_id
    mov [fat12_write_file_segment], bx
    mov word [fat12_write_file_offset], 0
    mov [fat12_write_file_file_size], ecx
    xor eax, eax
    mov ax, [bdb_bytes_per_sector]
    dec ax
    add ecx, eax
    mov ax, cx
    shr ecx, 16
    mov dx, cx
    mov bx, [bdb_bytes_per_sector]
    div bx
    add ax, [bdb_sectors_per_cluster]
    dec ax
    xor bh, bh
    mov bl, [bdb_sectors_per_cluster]
    xor dx, dx
    div bx
    xor ah, ah
    ; mov [fat12_write_file_clusters_to_write], al
    xor ecx, ecx
    mov cl, al

    call fat12_read_fat

    call fat12_get_free_cluster
    cmp ax, 0xffff
    je floppy_error
    mov [fat12_write_file_base_cluster], ax
.continue_writing:
    mov dx, ax
    mov ax, [fat12_write_file_last_cluster]
    call fat12_set_cluster
    mov ax, dx
    mov [fat12_write_file_last_cluster], ax
    mov dx, 0x0ff8
    call fat12_set_cluster
    
    pusha
    push es
    mov ax, [fat12_write_file_segment]
    mov es, ax
    call fat12_get_data_start
    add ax, [fat12_write_file_last_cluster]
    mov cl, 1
    mov dl, [ebr_drive_number]
    mov bx, [fat12_write_file_offset]
    call disk_write
    add bx, 512
    mov [fat12_write_file_offset], bx
    pop es
    popa

    dec cl
    test cl, cl
    jz .done
    call fat12_get_free_cluster
    jmp .continue_writing
.done:
    call fat12_write_fat
    mov bx, [fat12_write_file_base_cluster]
    mov ecx, [fat12_write_file_file_size]
    pop es
    pop ds
    call fat12_write_file_entry
    popa
    ret

; ax - starting cluster
fat12_delete_cluster_chain:
    xor dx, dx
    call fat12_read_fat
.loop:
    push ax
    call fat12_get_cluster
    mov [fat12_next_cluster], ax
    pop ax
    cmp [fat12_next_cluster], 0xff8
    jae .done
    call fat12_set_cluster
    mov ax, [fat12_next_cluster]
    jmp .loop
.done:
    call fat12_write_fat
    ret

; ds:si - filename
fat12_delete_file:
    pusha
    push ds
    push es
    mov ax, cs
    mov es, ax
    lea di, [fat12_delete_file_filename_buffer]
    mov cx, 12
    rep movsb
    mov ax, cs
    mov ds, ax
    lea si, [fat12_delete_file_filename_buffer]
    call fat12_file_exists
    test al, al
    jz .done
    mov byte [fat12_buffer + si], 0
    call get_lba_and_size_of_root_dir
    lea bx, [fat12_buffer]
    call disk_write
    mov ax, word [fat12_buffer + si + 26]
    call fat12_delete_cluster_chain
.done:
    pop es
    pop ds
    popa
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
    div word [cs:bdb_sectors_per_track]
                                        ; dx = LBA % SectorsPerTrack

    ; dx = (LBA % SectorsPerTrack + 1) = sector
    inc dx
    ; cx = sector
    mov cx, dx

    ; dx = 0
    xor dx, dx
    ; ax = (LBA / SectorsPerTrack) / Heads = cylinder
    div word [cs:bdb_heads]
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

; same as disk_read but bp is lba instead of ax and drive is always current loaded drive
disk_read_interrupt_wrapper:
    call disk_read
    iret    

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

disk_write_interrupt_wrapper:
    call disk_write
    iret

; Writes sectors to a disk
; Parameters:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx: memory address of data to store
disk_write:

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

    mov ah, 0x03
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
    lea si, [msg_err_missing]
    jmp error

floppy_error:
    lea si, [msg_err_floppy]

error:
    mov ax, cs
    mov ds, ax
    call puts

    mov al, [cs:deadly_errors]
    cmp al, 1
    jne .return

    mov bp, 0x6969
    cli
    hlt
.return:
    mov sp, [cs:int_stack]
    mov ax, [cs:int_ds]
    mov ds, ax
    mov ax, [cs:int_es]
    mov es, ax
    iret

kernel_panic:
    mov ax, cs
    mov ds, ax
    lea si, [msg_err_oom]
    call puts
    call puts
    call puts

    cli
    hlt

stub:
    ret

int21:
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
    mov ax, ds
    mov [cs:int_ds], ax
    mov ax, es
    mov [cs:int_es], ax
    pop ax
    pop si
    mov [cs:int_stack], sp
    call word [cs:call_value]
    iret
.call_table:
    dw puts, fat12_read_file, run_program, load_fat12_info, get_lba_and_size_of_root_dir, putc, fat12_file_exists, reset_vga_text_mode, \
        deallocate_interrupt_wrapper, stay_resident_after_terminate, putm, get_segment_from_block_id, fat12_write_file, fat12_delete_file, \
        set_text_attribute, putb, putw, put_hex, \
        get_block_id_from_segment
    dw (256-($-.call_table))/2 dup(stub)

msg_logo file '../inc/logo.txt'
    db 0
msg_credit file '../inc/credit.txt'
    db 0
msg_kernel_done db "Stannum kernel has somehow finished all jobs, terminating", 0x0a, 0
msg_patching db "Patching the IVT", 0x0a, 0
msg_loading_a20 db "Enabling high memory [HIGH.DRV]", 0x0a, 0
msg_loading_serial db "Loading serial I/O driver [SERIAL.DEV]", 0x0a, 0
msg_loading_pcspk db "Loading PC speaker driver [PCSPK.DEV]", 0x0a, 0
msg_loading_vga db "Loading VGA graphics driver [VGA.DEV]", 0x0a, 0
msg_putm_guide db "each character represents the state of a 2KiB block of memory", 0x0a, "Legend:", 0x0a, ". = free", 0x0a, "^ = taken", 0x0a, "$ = end of chunk", 0x0a, "* = resident", 0x0a, 0x0a, 0

msg_err_floppy db "Disk error", 0x0a, 0
msg_err_missing db "File not found", 0x0a, 0
msg_err_oom db "Kernel panicing: out of memory", 0x0a, 0

file_high_drv db "high.drv", 0
file_serial_dev db "serial.dev", 0
file_pcspk_dev db "pcspk.dev", 0
file_vga_dev db "vga.dev", 0
file_scli_com db "scli.com", 0

newline db 0x0a, 0

db "Notosoft Stannum Kernel", 0x0a, 0x0d
db "i was here 5.12.2026"

reupload db 0

deadly_errors db 1

text_attribute db ?

a20_enabled db ?

int_stack dw ?
int_ds dw ?
int_es dw ?

call_value dw ?

MEM_BLOCKS = (640 - (64 * (1 + 1 + 2))) / 2 
    ; (Low memory [640KiB] - (Segment size [64KiB] * (1 [BDA + bootloader] + 1 [Kernel reserved] + 2 [EBDA])) / 2KiB
    ; Gets the amount of free space left in KiB, divides by 2KiB (the block allocator cluster size)
MEM_START = 0x2000
mem_blocks db MEM_BLOCKS dup(?)

smallest_mem_block dw ?
smallest_mem_block_size db ?
desired_size db ?

fat12_filename db 12 dup(?)
fat12_buffer db 8192 dup(?)

fat12_read_file_segtemp dw ?
fat12_read_file_offtemp dw ?
fat12_read_file_extension_buffer db 3 dup(?)
fat12_read_file_got_zero db ?
fat12_read_file_file_cluster dw ?
fat12_read_file_block dw ?

fat12_read_file_size_filesize dd ?

fat12_first_free_entry_entries dw ?

fat12_write_file_first_free_entry dw ?
fat12_write_file_base_cluster dw ?
fat12_write_file_last_cluster dw ?
fat12_write_file_file_size dd ?
fat12_write_file_segment dw ?
fat12_write_file_offset dw ?

fat12_file_entry_offset dw ?

fat12_cluster_to_use dw ?
fat12_new_cluster_value dw ?
fat12_next_cluster dw ?

fat12_delete_file_filename_buffer db 12 dup(?)

run_program_argument_buffer db 128 dup(?)

label bdb
db 3 dup(?)
bdb_oem:                    db 8 dup(?)
bdb_bytes_per_sector:       dw ?
bdb_sectors_per_cluster:    db ?
bdb_reserved_sectors:       dw ?
bdb_fat_count:              db ?
bdb_dir_entries_count:      dw ?
bdb_total_sectors:          dw ?
bdb_media_descriptor_type:  db ?
bdb_sectors_per_fat:        dw ?
bdb_sectors_per_track:      dw ?
bdb_heads:                  dw ?
bdb_hidden_sectors:         dd ?
bdb_large_sector_count:     dd ?

ebr_drive_number:           db ?
                            db ?
ebr_signature:              db ?
ebr_volume_id:              dd ?
ebr_volume_label:           db 11 dup(?)
ebr_system_id:              db 8 dup(?)

align 16
db 8192 dup(?)
label stack_top