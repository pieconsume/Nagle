; EFI System Partition
 dq 0x11D2F81FC12A7328 ; Type GUID
 dq 0x3BC93EC9A0004BBA ; Type GUID
 dq 0x597B5AF330AD94B9 ; Partition GUID
 dq 0xD74DD0EB7A0E0DE6 ; Partition GUID
 dq 0x000000000000000A ; Starting LBA           
 dq 0x0000000000000087 ; Ending LBA
 dq 0x8000000000000000 ; Attributes
 dw 0x54, 0x45         ; 'TEST'
 dw 0x53, 0x54
 times 64 db 0         ; Partition name
 times 0x20*0x80-($-$$) db 0