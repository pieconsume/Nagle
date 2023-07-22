; This file puts together the individual parts into a final bootable disk image
pre:
 incbin "Builds/Bootloader"
 times 0x0200-($-$$) db 0
 incbin "Builds/GPT"
 times 0x0400-($-$$) db 0
 incbin "Builds/GPTPA"
 times 0x1400-($-$$) db 0
 pre.end:
bpb:
 db 0xEB, 0x58, 0x90   ; Jump code
 dq "MSWIN4.1"         ; May need to be "MSWIN4.1" to be recognized by old drivers
 dw 0x0200             ; Bytes per sector
 db 0x01               ; Sectors per cluster
 dw 0x0009             ; Reserved sector count, sectors between the BPB and the FAT
 db 0x02               ; Number of FATs
 dw 0x0000             ; Root entry count, should be 0 on FAT32
 dw 0x0000             ; 16 bit sector count, should be 0 on FAT32
 db 0xF0               ; Media type, typically ignored but should hold some value for compatibility
 dw 0x0000             ; 16 bit fat size, should be 0 on FAT32
 dw 0x0000             ; Sectors per track (Not sure if these need to hold a value)
 dw 0x0000             ; Head count
 dd (pre.end-pre)/512  ; Number of hidden sectors (sectors before the BPB)
 dd 0x0FFFFFFF         ; Sectors in the volume (May need to make this larger for it to be detected as FAT32?)
 dd 0x00000001         ; Sectors per FAT
 dw 0x0000             ; Flags
 dw 0x0000             ; File system version
 dd 0x00000002         ; Root cluster
 dw 0x0001             ; FSInfo location
 dw 0x0006             ; Backup boot sector
 times 12 db 0x00      ; Reserved
 db 0x00               ; Drive number (can be ignored?)
 db 0x00               ; Reserved by Windows NT
 db 0x29               ; Extended boot signature
 dd 0x564FB32A         ; Volume ID
 db 'test       '      ; Volume label
 db "FAT32   "         ; File system type
 bpb.end:
 times 510-(bpb.end-bpb) db 0
 dw 0xAA55
fsi:
 dd 0x41615252         ; Signature
 times 480 db 0        ; Reserved
 dd 0x61417272         ; Signature 2
 dd 0xFFFFFFFF         ; Last known free sector
 dd 0xFFFFFFFF         ; Next free sector
 times 12 db 0         ; Reserved
 dd 0xAA550000         ; Trail signature
 fsi.end:
 times 0x200-(fsi.end-fsi) db 0
pad:
 times 0x200*4 db 0
bpbb:
 db 0xEB, 0x58, 0x90   ; Jump code
 dq "MSWIN4.1"         ; May need to be "MSWIN4.1" to be recognized by old drivers
 dw 0x0200             ; Bytes per sector
 db 0x01               ; Sectors per cluster
 dw 0x0009             ; Reserved sector count, sectors between the BPB and the FAT
 db 0x02               ; Number of FATs
 dw 0x0000             ; Root entry count, should be 0 on FAT32
 dw 0x0000             ; 16 bit sector count, should be 0 on FAT32
 db 0xF0               ; Media type, typically ignored but should hold some value for compatibility
 dw 0x0000             ; 16 bit fat size, should be 0 on FAT32
 dw 0x0000             ; Sectors per track (Not sure if these need to hold a value)
 dw 0x0000             ; Head count
 dd (pre.end-pre)/512  ; Number of hidden sectors (sectors before the BPB)
 dd 0x0FFFFFFF         ; Sectors in the volume (May need to make this larger for it to be detected as FAT32?)
 dd 0x00000001         ; Sectors per FAT
 dw 0x0000             ; Flags
 dw 0x0000             ; File system version
 dd 0x00000002         ; Root cluster
 dw 0x0001             ; FSInfo location
 dw 0x0006             ; Backup boot sector
 times 12 db 0x00      ; Reserved
 db 0x00               ; Drive number (can be ignored?)
 db 0x00               ; Reserved by Windows NT
 db 0x29               ; Extended boot signature
 dd 0x564FB32A         ; Volume ID
 db 'test       '      ; Volume label
 db "FAT32   "         ; File system type
 bpbb.end:
 times 510-(bpbb.end-bpbb) db 0
 dw 0xAA55
fsib:
 dd 0x41615252         ; Signature
 times 480 db 0        ; Reserved
 dd 0x61417272         ; Signature 2
 dd 0xFFFFFFFF         ; Last known free sector
 dd 0xFFFFFFFF         ; Next free sector
 times 12 db 0         ; Reserved
 dd 0xAA550000         ; Trail signature
 fsib.end:
 times 0x200-(fsib.end-fsib) db 0
pad2:
 times 0x200 db 0
fat:
 dd 0x0FFFFFF0 ; 0x00, Media type
 dd 0xFFFFFFFF ; 0x01, I forgot (not important)
 dd 0x0FFFFFFF ; 0x02, Root directory
 dd 0x0FFFFFFF ; 0x03, EFI directory
 dd 0x0FFFFFFF ; 0x04, Boot directory
 fat.end:
 times (0x200-(fat.end-fat))/4 dd 0x0FFFFFF7 ; 0x0FFFFFF7 is bad / unusuable cluster 
fatb:
 dd 0x0FFFFFF0 ; 0x00, Media type
 dd 0xFFFFFFFF ; 0x01, I forgot (not important)
 dd 0x0FFFFFFF ; 0x02, Root directory
 dd 0x0FFFFFFF ; 0x03, EFI directory
 dd 0x0FFFFFFF ; 0x04, Boot directory
 fatb.end:
 times (0x200-(fatb.end-fatb))/4 dd 0x0FFFFFF7
root:
 dq "NAGLE64 "       ; Name
 db '   '            ; Extension
 db 0x08             ; Attributes
 db 0                ; NT reserved
 db 0x00             ; MS timestamp
 dw 0x0000           ; Create time
 dw 0x0000           ; Create date
 dw 0x0000           ; Last access date
 dw 0x0000           ; High word of the first cluster
 dw 0x0000           ; Write time
 dw 0x0000           ; Write date
 dw 0x0000           ; Low word of the first cluster
 dd 0x00000000       ; Byte count (0 for directories)
 dq "EFI     "       ; Name
 db '   '            ; Extension
 db 0x10             ; Attributes
 db 0x00             ; NT reserved
 db 0x00             ; MS timestamp
 dw 0x0000           ; Create time
 dw 0x0000           ; Create date
 dw 0x0000           ; Last access date
 dw 0x0000           ; High word of the first cluster
 dw 0x0000           ; Write time
 dw 0x0000           ; Write date
 dw 0x0003           ; Low word of the first cluster
 dd 0x00000000       ; Byte count (0 for directories)
 root.end:
 times 0x200-(root.end-root) db 0
efi:
 dq ".       "       ; Name
 db '   '            ; Extension
 db 0x10             ; Attributes
 db 0x00             ; NT reserved
 db 0x00             ; MS timestamp
 dw 0x0000           ; Create time
 dw 0x0000           ; Create date
 dw 0x0000           ; Last access date
 dw 0x0000           ; High word of the first cluster
 dw 0x0000           ; Write time
 dw 0x0000           ; Write date
 dw 0x0003           ; Low bytes of the first cluster
 dd 0x00000000       ; Byte count (0 for directories)
 dq "..      "       ; Name
 db '   '            ; Extension
 db 0x10             ; Attributes
 db 0x00             ; NT reserved
 db 0x00             ; MS timestamp
 dw 0x0000           ; Create time
 dw 0x0000           ; Create date
 dw 0x0000           ; Last access date
 dw 0x0000           ; High word of the first cluster
 dw 0x0000           ; Write time
 dw 0x0000           ; Write date
 dw 0x0000           ; Low bytes of the first cluster
 dd 0x00000000       ; Byte count (0 for directories)
 dq "BOOT    "       ; Name
 db '   '            ; Extension
 db 0x10             ; Attributes
 db 0x00             ; NT reserved
 db 0x00             ; MS timestamp
 dw 0x0000           ; Create time
 dw 0x0000           ; Create date
 dw 0x0000           ; Last access date
 dw 0x0000           ; High word of the first cluster
 dw 0x0000           ; Write time
 dw 0x0000           ; Write date
 dw 0x0004           ; Low bytes of the first cluster
 dd 0x00000000       ; Byte count (0 for directories)
 efi.end:
 times 0x200-(efi.end-efi) db 0
boot:
 dq ".       "       ; Name
 db '   '            ; Extension
 db 0x10             ; Attributes
 db 0x00             ; NT reserved
 db 0x00             ; MS timestamp
 dw 0x0000           ; Create time
 dw 0x0000           ; Create date
 dw 0x0000           ; Last access date
 dw 0x0000           ; High word of the first cluster
 dw 0x0000           ; Write time
 dw 0x0000           ; Write date
 dw 0x0004           ; Low bytes of the first cluster
 dd 0x00000000       ; Byte count (0 for directories)
 dq "..      "       ; Name
 db '   '            ; Extension
 db 0x10             ; Attributes
 db 0x00             ; NT reserved
 db 0x00             ; MS timestamp
 dw 0x0000           ; Create time
 dw 0x0000           ; Create date
 dw 0x0000           ; Last access date
 dw 0x0000           ; High word of the first cluster
 dw 0x0000           ; Write time
 dw 0x0000           ; Write date
 dw 0x0003           ; Low bytes of the first cluster
 dd 0x00000000       ; Byte count (0 for directories)
 boot.end:
 times 0x200-(boot.end-boot) db 0