macro wrap number, func {
    xor ax, ax
    mov es, ax
    mov ax, [es:number * 4]
    mov [cs:offset_original], ax
    mov ax, [es:number * 4 + 2]
    mov [cs:segment_original], ax
    mov word [es:number * 4], func
    mov ax, cs
    mov [es:number * 4 + 2], ax
}