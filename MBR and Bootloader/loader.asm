LOADER_BASE_ADDR equ 0x900
section loader vstart=LOADER_BASE_ADDR

mov ax, 0xb800        ; Load the address 0xB800 into the AX register, which points to the memory area for displaying text-based graphics
mov es, ax            ; Assign the value of the AX register to the ES register, setting ES to point to the segment address of the display memory

mov byte [es:0x00],'o'
mov byte [es:0x01],0x07
mov byte [es:0x02],'k'
mov byte [es:0x03],0x06

jmp $
