; This file puts together the individual parts into a final bootable disk image
incbin "Builds/Bootloader"
times 0x0200-($-$$) db 0
incbin "Builds/GPT"
times 0x0400-($-$$) db 0
incbin "Builds/GPTPA"
times 0x1400-($-$$) db 0