[BITS 16]
[ORG 0x7C00]
KERNEL_OFFSET equ 0x1000
start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    mov si, msg_boot
    call print_string
    mov bx, KERNEL_OFFSET
    call disk_load
    mov si, msg_loaded
    call print_string
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08:protected_mode
gdt_start:
    dq 0
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00
gdt_end:
gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start
[BITS 32]
protected_mode:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000
    mov esi, msg_kernel
    call print_string
.hang:
    hlt
    jmp .hang
print_string:
    mov ah, 0x0e
.next:
    lodsb
    or al, al
    jz .done
    int 0x10
    jmp .next
.done:
    ret
disk_load:
    push bx
    mov dl, 0x00
    mov dh, 0
    mov ch, 0
    mov cl, 2
    mov al, 4
    mov ah, 0x02
    int 0x13
    pop bx
    ret
msg_boot:   db 'Booting MyOS...', 13, 10, 0
msg_loaded: db 'Kernel loaded!', 13, 10, 0
msg_kernel: db 'MyOS Kernel v0.1 - Protected Mode Active!', 0
times 510-($-$$) db 0
dw 0xAA55
times 2560-($-$$) db 0
