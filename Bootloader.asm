; Basic bootsector which loads in the legacy loader from a static disk location.
; Defs 
 [BITS 16]
 [ORG 0x7C00]
load:
 mov si,packet ; Send packet
 mov ah,0x42   ; Disk read
 int 0x13
 jmp 0:0x1000
packet:
 db 0x10     ; Packet size
 db 0        ; Padding (I think?)
 dw 1        ; Sector count
 dw 0x1000   ; Write location
 dw 0        ; Segment
 dd 0        ; Sector skip low dword
 dd 0        ; Sector skip high dword
pmbr:
 times 440-($-$$) db 0
 dd 0x51B73312     ; Unique signature
 dw 0              ; 0
 ; Partition 0
 db 0              ; Bootable
 db 0,0x20,0       ; Starting CHS
 db 0xEE           ; Partition type (PMBR)
 db 0xFF,0xFF,0xFF ; Ending CHS
 dd 0x1            ; Starting LBA
 dd 0x1EBFF        ; Length in sectors (this is the exact amount on my boot USB)
 times 6 dq 0      ; Remaining PMBR
 dw 0xAA55 ; Boot identifier