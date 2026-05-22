use16

main:
    mov ax, cs
    mov ds, ax
    mov es, ax

    clc
    mov ax, 0x4f00
    lea di, [vesa_info_block_buffer]
    int 0x10
    cmp ax, 0x004f
    jne fail

    xor ah, ah
    lea si, [msg_success]
    int 0x21

    retf

fail:
    xor ah, ah
    lea si, [msg_failed]
    int 0x21

    retf

msg_success db "This video card supports VESA VBE", 0x0a, 0
msg_failed db "Failed", 0x0a, 0

vesa_info_block_buffer:
.signature db 4 dup(0)
.version dw 0
.oem_name_ptr dd 0
.capabilities dd 0
.video_modes_offset dw 0
.video_modes_segment dw 0
.count_of_64kb_blocks dw 0
.oem_software_revision dw 0
.oem_vendor_name_ptr dd 0
.oem_product_name_ptr dd 0
.oem_product_revision_ptr dd 0
.reserved db 222 dup(0)
.oem_data db 256 dup(0)
