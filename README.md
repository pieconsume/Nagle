# Nagle

Current status
 - Restructuring the project for github. Right now nothing is put together and it's just a mess of disjointed code.
 - Most code hasn't even been copied back into the project yet.
 - Working on new stuff (APIC/interrupts atm) instead of porting old code back in.

Things checkmarked aren't necessarily done, it just means I had it in a working state at some point and largely understand how it works.
The circle thingies mean I've worked on it at some point but never completely implemented it or don't fully understand it yet

Todo list
- Bootloader  (Legacy ✅, UEFI 🔄)
- Legacy/Virtual 16-bit support (Optional) ❌
- x86-32 Protected Mode ✅
- x86-64 Long mode ✅
- Paging ✅ 
- Legacy Drivers (Keyboard ✅, Mouse ❌, whatever else ❌)
- Interrupts (Legacy ✅, APIC ✅)
- Threading Core 🔄
- Multicore Threading ❌
- PCI support ✅
- PCIe support 🔄
- Timer Drivers (PIT ✅, RTC ✅, APIC Timer ❌, HPET ❌)
- USB Core ❌
- USB Drivers (Keyboard ❌, Mouse ❌, Speaker ❌, Microphone ❌, HDD ❌)
- Networking Core ❌
- Networking drivers (Ethernet ❌, Wifi ❌)
- File System Core 🔄
- File System Support (FAT 🔄, Ext2 ❌, NTFS ❌)
- Disk Access Drivers (ATA 🔄, ATAPI 🔄, SATA/AHCI 🔄, DMA ❌, NVMe ❌, Legacy floppy support ❌)
- Audio Core ❌
- Video Core ❌
- Video Drivers (Intel Integrated ❌, AMD ❌, NVIDIA 💀)