[BITS 16]
[ORG 0x7C00]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    
    mov si, msg_real
    call print
    
    cli
    lgdt [gdt_desc]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08:pmode

gdt:
    dq 0
    dw 0xFFFF, 0, 0x9A00, 0xCF00
    dw 0xFFFF, 0, 0x9200, 0xCF00
gdt_end:

gdt_desc:
    dw gdt_end - gdt - 1
    dd gdt

[BITS 32]
pmode:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x90000
    
    mov edi, 0xB8000
    mov esi, msg_protected
    call print32

hang:
    hlt
    jmp hang

print:
    mov ah, 0x0e
.next:
    lodsb
    or al, al
    jz .done
    int 0x10
    jmp .next
.done:
    ret

print32:
.next:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0F
    mov [edi], ax
    add edi, 2
    jmp .next
.done:
    ret

msg_real: db 'Real Mode OK', 13, 10, 0
msg_protected: db 'Protected Mode Active!', 0

times 510-($-$$) db 0
dw 0xAA55
