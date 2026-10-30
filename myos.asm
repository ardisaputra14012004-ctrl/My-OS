; ============================================================
; MyOS - Bootloader + Kernel dalam 1 file
; ============================================================

[BITS 16]
[ORG 0x7C00]

KERNEL_OFFSET equ 0x1000

start:
    ; Setup segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    
    ; Cetak pesan boot
    mov si, msg_boot
    call print16
    
    ; Load kernel dari disk (sector 2, 4 sectors = 2KB)
    mov bx, KERNEL_OFFSET
    call disk_load
    
    ; Cetak pesan loaded
    mov si, msg_loaded
    call print16
    
    ; === TRANSISI KE PROTECTED MODE ===
    cli                 ; Disable interrupts
    lgdt [gdt_descriptor] ; Load GDT
    
    ; Set PE bit di CR0
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    ; Far jump ke 32-bit code segment
    jmp 0x08:protected_mode

; === GDT (Global Descriptor Table) ===
gdt_start:
    ; Null descriptor (WAJIB ada)
    dq 0
    
    ; Code segment: base=0, limit=4GB, 32-bit, executable
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b  ; Present, Ring 0, Code, Executable, Readable
    db 11001111b  ; 4KB granularity, 32-bit
    db 0x00
    
    ; Data segment: base=0, limit=4GB, 32-bit, writable
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b  ; Present, Ring 0, Data, Writable
    db 11001111b  ; 4KB granularity, 32-bit
    db 0x00
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Size of GDT
    dd gdt_start                ; Address of GDT

; === 32-BIT PROTECTED MODE CODE ===
[BITS 32]
protected_mode:
    ; Setup segment registers
    mov ax, 0x10      ; Data segment selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Setup stack
    mov esp, 0x90000
    
    ; Cetak pesan dari kernel via VGA
    mov esi, msg_kernel
    call print32
    
    ; Loop selamanya
.hang:
    hlt
    jmp .hang

; === SUBROUTINE: Print 16-bit (pakai BIOS) ===
print16:
    mov ah, 0x0e
.next:
    lodsb
    or al, al
    jz .done
    int 0x10
    jmp .next
.done:
    ret

; === SUBROUTINE: Load dari Disk ===
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

; === SUBROUTINE: Print 32-bit (pakai VGA langsung) ===
print32:
    mov edi, 0xB8000
.next:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0F      ; Putih di hitam
    mov [edi], ax
    add edi, 2
    jmp .next
.done:
    ret

; === DATA ===
msg_boot:   db 'Booting MyOS...', 13, 10, 0
msg_loaded: db 'Kernel loaded!', 13, 10, 0
msg_kernel: db 'MyOS Kernel v0.1 - Protected Mode Active!', 0

; === PADDING ===
times 510-($-$$) db 0
dw 0xAA55

; Kernel code dimulai setelah bootloader
; Pad bootloader sampai 512 bytes sudah dilakukan di atas
; Kernel akan di-load ke 0x1000 oleh bootloader

; Tambahkan padding agar kernel mulai di offset yang benar
; (512 bytes bootloader + padding sampai offset 0x1000 = 4096)
; Tapi karena kita load 4 sectors (2048 bytes), kernel mulai di sector 2
; Jadi kita perlu pad sampai total 2560 bytes (512 + 2048)
times 2560-($-$$) db 0
