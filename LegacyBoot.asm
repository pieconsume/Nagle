;Defs
 [ORG 0x1000]
 [BITS 16]
 %define memmap 0x2000
 %define pml4   0x3000
 %define pml3   0x4000

reginit:
 cli           ;Ensure nothing interferes during initialization
 xor ax,ax     ;Ensure ds and es are initialized to 0
 mov ds,ax
 mov es,ax
 not ax
 mov fs,ax     ;Set fs to 0xFFFF for A20 testing
 mov ax,0xB800
 mov gs,ax     ;Set gs to video memory
 mov [disk],dl ;Save the drive passed over from the bootsector
a20ch:
 cmp byte [fs:a20+0x10],0xAB ;Compare variable with value 1 MiB higher
 jne settarg                 ;If they are different a20 is disabled and nothing needs to be done
 mov ax,0x2401               ;Try enabling a20 via BIOS
 int 0x15
 inc byte [a20]              ;Change the value on the off chance it happened to be the same
 cmp byte [fs:a20+0x10],0xAB ;Check if it is different now
 je noa20                    ;If a20 isn't enabled just give up. Only bother fixing issues with this if/when they occur since legacy loading is mostly irrelevant
settarg:
 mov ax,0xEC00
 mov bl,0x02   ;Set the target to 64 bit
 int 0x15
setvid:
 xor ah,ah
 mov al,0x03 ;Set the video mode to 80x25 text (what it's usually set to)
 int 0x10
remappic:
 mov al,0x11 ;0x11 is the PIC initialization command which accepts 3 inputs after being run
 out 0x20,al ;There's no need to save/restore masks since I wont be using the PIC and they are all masked later in the code
 out 0xA0,al
 mov al,0x20 ;Offsets. 0x20-0x2F or 32 to 47
 out 0x21,al
 mov al,0x28
 out 0xA1,al
 mov al,4    ;Tells the two PICs how they are wired together. I dont fully understand this but I dont really need to
 out 0x21,al
 mov al,2
 out 0xA1,al
 mov al,1    ;Set the mode,1 is 8086 mode. Again not very important since I wont be using the PIC.
 out 0x21,al 
 out 0xA1,al 
getmap:
 ;Note - never set ACPI compatibility bit, fix later?
 mov edi,memmap     ;Basic map getting code. Not sure how reliable it is but it works on my machine
 mov edx,0x534D4150
 xor ebx,ebx
 xor si,si
 maploop:
  mov eax,0xE820
  mov ecx,0x24
  int 0x15
  add edi,24
  inc si
  cmp ebx,0
  jne maploop
  mapend mov [rsrv+0x06],si ;Save the entry count
loadkernel:
 mov si,diskpack ;Load the kernel with int 0x13
 mov ah,0x42
 mov dl,[disk]
 int 0x13
pagemap:
 mov word [pml4],0x4003 ;Identity map first GiB
 mov word [pml3],0x83
longmode:
 ;Uses the direct real to long mode method 
 mov al,0xFF        ;Disable all IRQs
 out 0x21,al
 out 0xA1,al
 lidt [idtr]        ;Load IDT
 mov eax,0b10100000 ;Enable PAE and PGE (Bits 7 and 5)
 mov cr4,eax
 mov eax,pml4       ;Set PML4
 mov cr3,eax
 mov ecx,0xC0000080 ;Set long mode enable
 rdmsr
 or eax,0x100 
 wrmsr
 mov eax,cr0        ;Enter long mode by enable paging and protected mode at the same time
 or eax,1 | (1 << 31)
 mov cr0,eax
 lgdt [gdtr]        ;Load GDT
 jmp 0x08:kerninit  ;Enter long mode by performing a far jump
 [BITS 64]
 kerninit:
 mov ax,0x10        ;Set data segment
 mov ds,ax
 mov eax,rsrv       ;Pass flags to kernel
 jmp 0x40000        ;Jump to the kernel
 
[BITS 16]
noa20:
 mov word [gs:0],0x0F00 | 'a'
 hlt

data:
 disk db 0
 a20  db 0xAB
 diskpack:
  db 0x10   ;Packet size
  db 0      ;0
  dw 0x10   ;Sector count
  dw 0      ;Segment offset
  dw 0x4000 ;Segment (address >> 4)
  dd 0x1A   ;Sector skip low dword
  dd 0      ;Sector skip high dword
 gdtr:
  dw 23
  dq gdt
 idtr:
  dw 0
  dq 0
 gdt:
  dq 0          ;Empty entry
  dd 0          ;Code entry
  db 0
  db 0b10011000 ;Access byte
  db 0b00100000 ;Flags
  db 0
  dd 0          ;Data entry
  db 0
  db 0b10010000 ;Access byte
  db 0
  db 0
 rsrv:
  dd 3    ;0x00 Reserved area count
  db 0    ;0x04 Flags
  db 0    ;0x05 Memory map type
  dw 0    ;0x06 Memory map entries
  ;dword 0 is page offset,dword 1 is size in pages
  dd 0x40 ;0x08 Kernel
  dd 2
  dd 0x03 ;0x10 PML4
  dd 1
  dd 0x02 ;0x18 2 Physical memory map
  dd 1