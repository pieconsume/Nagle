# Nagle

## Project status and todo-list

Current status
 - Most stuff is ported back into the project. The main thing that is missing is disk drivers.
 - Working on the project regularly. Next thing I plan on working on is basic intel graphics drivers.

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

## Structural overview

### Design philosophy

Nagle doesn't have any particularly design philosophy or paridigms, I just code things in the way that makes the most sense to me.

I have made it my goal to not implement any existing protocols or port existing drivers. I want to create something that is entirely my own.
Because of this the project progresses very slowly but I again a solid understanding of any interface I work with.

### Boot overview

#### Legacy MBR booting

Legacy MBR booting uses standard 2-step booting.

The MBR (Bootloader.asm) is as minimal as possible with its only function being to load in the main loader from a hardcoded disk location.

The main loader (LegacyBoot.asm) provides the rest of the functionality such as setting up page maps and entering long mode. This loader is as sparse as possible and most hardware initialization is done in the kernel itself.

Due to MBR being phased out for UEFI booting I have put little effort into this section of the project.

#### UEFI booting

UEFI booting is currently not functional. Since UEFI already starts the system in 64 bit mode the only initializations necessary are getting the memory map and creating a page map.

I plan to move the kernel into the UEFI loader later so that disk loading code is not needed.

#### Kernel loading

The kernel is designed to have minimal initialization required. The requirments are as follows:
 - Loaded in 64 bit long mode
 - RAX contains a pointer to the kernel flags and reserved memory
 - The kernel flags will have the memory map type bit set correctly
 - Index 0 of reserved memory will point to the kernel itself
 - Index 1 will point to the PML4 table (PAE / PML5 is not supported)
 - Index 2 will point to a valid memory map with either the 0xE820 format or UEFI format

The kernel is fully relocatable and can be loaded in / mapped to any memory location. The kernel is currently loaded in at 0x40000 and maps itself to the highest quarter (0xFFFFFFFFC0000000).

### Kernel structure

The kernel is currently barebones and provides no interfaces or abstractions. I am primarily focused on hardware detection/initialization and drivers at the moment.