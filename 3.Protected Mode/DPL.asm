DA_32 EQU 4000h; 32-bit
DA_C EQU 98h; Code segment attribute
DA_DRW EQU 92h; Read-write data segment attribute
DA_DRWA EQU 93h; Read-write data segment attribute (accessed)

DA_DPL0 EQU 00h
DA_DPL1 EQU 20h

SA_RPL0 EQU 0
SA_RPL1 EQU 1
SA_RPL2 EQU 2
SA_RPL3 EQU 3

%macro Descriptor 3
    dw %2 & 0FFFFh ; Segment limit 1 (2 bytes)
    dw %1 & 0FFFFh ; Segment base 1 (2 bytes)
    db (%1 >> 16) & 0FFh ; Segment base 2 (1 byte)
    dw ((%2 >> 8) & 0F00h) | (%3 & 0F0FFh) ; Attribute 1 + Segment limit 2 + Attribute 2 (2 bytes)
    db (%1 >> 24) & 0FFh ; Segment base 3
%endmacro

org 0100h ; Available area for DOS debugging
    jmp PM_BEGIN ; Jump to the code segment labeled PM_BEGIN

[SECTION .gdt]
; GDT
PM_GDT: Descriptor 0, 0, 0
PM_DESC_CODE32: Descriptor 0, SegCode32Len - 1, DA_C + DA_32
PM_DESC_DATA: Descriptor 0, DATALen - 1, DA_DRW + DA_DPL1
PM_DESC_STACK: Descriptor 0, TopOfStack, DA_DRWA + DA_32
PM_DESC_TEST: Descriptor 0200000h, 0ffffh, DA_DRW
PM_DESC_VIDEO: Descriptor 0B8000h, 0ffffh, DA_DRW
; End of GDT definition
GdtLen equ $ - PM_GDT
GdtPtr dw GdtLen - 1
dd 0 ; GDT base address

; GDT selectors
SelectoerCode32 equ PM_DESC_CODE32 - PM_GDT
SelectoerDATA equ PM_DESC_DATA - PM_GDT + SA_RPL3
SelectoerSTACK equ PM_DESC_STACK - PM_GDT
SelectoerTEST equ PM_DESC_TEST - PM_GDT
SelectoerVideo equ PM_DESC_VIDEO - PM_GDT
; END of [SECTION .gdt]

[SECTION .data1]
ALIGN 32
[BITS 32]
PM_DATA:
PMMessage: db "Protect Mode", 0;
OffsetPMessage equ PMMessage - $$
DATALen equ $ - PM_DATA
; END of [SECTION .data]

; Global stack segment
[SECTION .gs]
ALIGN 32
[BITS 32]
PM_STACK:
    times 512 db 0
TopOfStack equ $ - PM_STACK - 1
; END of STACK

[SECTION .s16]
[BITS 16]
PM_BEGIN:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0100h

    ; Initialize the 32-bit code segment
    xor eax, eax
    mov ax, cs
    shl eax, 4
    add eax, PM_SEG_CODE32
    mov word [PM_DESC_CODE32 + 2], ax
    shr eax, 16
    mov byte [PM_DESC_CODE32 + 4], al
    mov byte [PM_DESC_CODE32 + 7], ah

    ; Initialize the 32-bit data segment
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, PM_DATA
    mov word [PM_DESC_DATA + 2], ax
    shr eax, 16
    mov byte [PM_DESC_DATA + 4], al
    mov byte [PM_DESC_DATA + 7], ah

    ; Initialize the 32-bit stack segment
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, PM_STACK
    mov word [PM_DESC_STACK + 2], ax
    shr eax, 16
    mov byte [PM_DESC_STACK + 4], al
    mov byte [PM_DESC_STACK + 7], ah

    ; Load GDTR
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, PM_GDT
    mov dword [GdtPtr + 2], eax
    lgdt [GdtPtr]

    ; A20
    cli

    in al, 92h
    or al, 00000010b
    out 92h, al

    ; Switch to protected mode
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp dword SelectoerCode32:0

[SECTION .s32] ; 32-bit code segment
[BITS 32]
PM_SEG_CODE32:
    mov ax, SelectoerDATA ; Load data segment selector into ds register for segment+offset addressing
    mov ds, ax

    mov ax, SelectoerTEST ; Load test segment selector into es register for segment+offset addressing
    mov es, ax

    mov ax, SelectoerVideo
    mov gs, ax

    mov ax, SelectoerSTACK
    mov ss, ax
    mov esp, TopOfStack

    mov ah, 0Ch
    xor esi, esi
    xor edi, edi
    mov esi, OffsetPMessage
    mov edi, (80 * 10 + 0) * 2
    cld

.1:
    lodsb
    test al, al
    jz .2
    mov [gs:edi], ax
    add edi, 2
    jmp .1

.2: ; Display complete

    ; Test segment addressing
    mov ax, 'A'
    mov [es:0], ax
    mov ax, SelectoerVideo
    mov gs, ax
    mov edi, (80 * 15 + 0) * 2
    mov ah, 0Ch
    mov al, [es:0]
    mov [gs:edi], ax

    jmp $
    
SegCode32Len equ $ - PM_SEG_CODE32
