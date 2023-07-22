; Partition array entries
 ; EFI System Partition (FAT32)
  dq 0x11D2F81FC12A7328 ; 0x00-0x07 ; The ESP GUID is C12A7328-F81F-11D2-BA4B-00A0C93EC93B
  dq 0x3BC93EC9A0004BBA ; 0x08-0x0F ; The first 3 segments are big endian and should be reversed, the next two should remain the same
  dq 0x597B5AF330AD94B9 ; 0x10-0x17 ; Partition GUID (may be pasted wrong but i do not care)
  dq 0xD74DD0EB7A0E0DE6 ; 0x17-0x1F
  dq 0x000000000000000A ; 0x20-0x27 ; Starting LBA
  dq 0x000000000000001F ; 0x28-0x2F ; Ending LBA
  dq 0x8000000000000000 ; 0x30-0x37 ; Attributes
  dw 0x0054, 0x0045, 0x0053, 0x0054 ; 'TEST'
  times 64 db 0                     ; Partition name
 ; Nagle boot partition
  dq 0x4F46B6084157147B ; 4157147B-B608-4F46-A57A-7D204FEF9704
  dq 0x0497EF4F207D7AA5
  dq 0x41D788D40DB58141 ; 0DB58141-88D4-41D7-A60E-F25550536940
  dq 0x4069535055F20EA6
  dq 0x0000000000000020 ; Starting LBA
  dq 0x000000000000002F ; Ending LBA
  dw 0x004E, 0x0042  ; 'NB'
  times 68 db 0         ; Partition name
 times 0x200*8-($-$$) db 0

; GPT Header backup
 dq 0x5452415020494645 ; Signature
 dd 0x00010000         ; Version 1.0 (UEFI 2.9 and below)
 dd 0x0000005C         ; Header size, 92
 dd	0x0F385566         ; CRC
 dd 0x00000000         ; Reserved
 dq 0x000000000001EBFF ; Current LBA
 dq 0x0000000000000001 ; Backup LBA, final sector should be 125951
 dq 0x000000000000000A ; First usuable LBA (Bootsector + GPT header + partition entry array)
 dq 0x000000000001EBF6 ; Last usuable LBA  (Last sector - (GPT header + partition entry array))
 dq 0x4F9FF3FCE0C1CA6D ; GUID
 dq 0xC933841302B1D9A6
 dq 0x000000000001EBF7 ; Partition entry array LBA
 dd 0x00000020         ; Number of partition entries (32)
 dd 0x00000080         ; Partition entry size (128)
 dd	0x2B3A5352 	       ; Partition entry array CRC
 ; Remaining is reserved
 times 0x200*9-($-$$) db 0