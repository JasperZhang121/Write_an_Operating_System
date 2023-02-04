mov ax,0xb800 ;pointing memory where in BIOS for displaying text-based graphics
mov es,ax

mov byte [es:0x00],'I'
mov byte [es:0x01],0x07
mov byte [es:0x00],'Z'
mov byte [es:0x01],0x06

jmp $
times 510-($-$$) db 0
db 0x55,0xaa