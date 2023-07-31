;GPT header
 ;Use https://simplycalc.com/crc32-file.php to calculate CRCs. Do GPTPA then GPT with CRC zeroed
 dq 0x5452415020494645 ;Signature
 dd 0x10000            ;Version 1.0 (UEFI 2.9 and below)
 dd 0x0000005C         ;Header size, 92
 dd	0x3EB6D49E         ;CRC
 dd 0                  ;Reserved
 dq 0x0000000000000001 ;Current LBA
 dq 0x000000000001EBFF ;Backup LBA, final sector should be 125951
 dq 0x000000000000000A ;First usuable LBA (Current LBA + full GPT size)
 dq 0x000000000001EBF6 ;Last usuable LBA  (Last sector - (GPT header + partition entry array))
 dq 0x4F9FF3FCE0C1CA6D ;GUID
 dq 0xC933841302B1D9A6 ;GUID
 dq 0x0000000000000002 ;Partition entry array LBA
 dd 0x00000020         ;Number of partition entries
 dd 0x00000080         ;Partition entry size (128)
 dd 0x29B5560C 	       ;Partition entry array CRC