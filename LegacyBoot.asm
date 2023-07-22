; Defs
 [ORG 0x1000]
 [BITS 16]
 %include "Globals.asm"
 %define memmap 0x2000
 %define pml4   0x3000
 %define pml3   0x4000

reginit:
 cli
 xor ax, ax
 mov ds, ax
 mov es, ax
 not ax
 mov fs, ax
 mov ax, 0xB800
 mov gs, ax
 mov [disk], dl
a20ch:
 cmp byte [fs:a20+0x10], 0xAB
 jne settarg
 mov ax, 0x2401 ; A20 enable
 int 0x15
 inc byte [a20]
 cmp byte [fs:a20+0x10], 0xAB
 je noa20
settarg:
 mov ax, 0xEC00
 mov bl, 0x02
 int 0x15
setvid:
 xor ah, ah
 mov al, 0x03
 int 0x10
getmap:
 mov edi, memmap
 mov edx, 0x534D4150
 xor ebx, ebx
 xor si, si
 maploop:
  mov eax, 0xE820
  mov ecx, 0x24
  int 0x15
  add edi, 24
  inc si
  cmp ebx, 0
  jne maploop
  mapend mov [rsrv+0x06], si
loadkernel:
 mov si, diskpack
 mov ah, 0x42
 mov dl, [disk]
 int 0x13
pagemap:
 mov word [pml4], 0x4003 ; Memory map first GiB
 mov word [pml3], 0x83
irqmask:
 mov al, 0xFF
 out 0x21, al
 out 0xA1, al
loadidt:
 lidt [idtr]
setpaepge:
 mov eax, 0b10100000 ; Enable PAE and PGE (Bits 7 and 5)
 mov cr4, eax
setpml4:
 mov eax, pml4
 mov cr3, eax
setlme:
 mov ecx, 0xC0000080
 rdmsr
 or eax, 0x100 
 wrmsr
setprotpage:
 mov eax, cr0
 or eax, 1 | (1 << 31)
 mov cr0, eax
loadgdt:
 lgdt [gdtr]
setlong:
 jmp 0x08:kerninit
kerninit:
 [BITS 64]
 mov ax, 0x10
 mov ds, ax
 mov eax, rsrv
 jmp 0x40000
 
[BITS 16]
noa20:
 mov word [gs:0], 0x0F00 | 'a'
 hlt

data:
 disk db 0
 a20  db 0xAB
 diskpack:
  db 0x10     ; Packet size
  db 0        ; 0
  dw dkernsz  ; Sector count
  dw 0        ; Write location
  dw mkernseg ; Segment
  dd dkernloc ; Sector skip low dword
  dd 0        ; Sector skip high dword
 gdtr:
  dw 23
  dq gdt
 idtr:
  dw 0
  dq 0
 gdt:
  dq 0
  dd 0
  db 0
  db 0b10011000
  dw 0b00100000
  dd 0
  db 0
  db 0b10010000
  dw 0
 rsrv:
  dd 3    ; Reserved area count
  dw 0    ; Flags
  dw 0    ; Memory map entries
  dd 0x40 ; 0x08 Kernel
  dd pkernsz
  dd 0x03 ; 0x10 PML4
  dd 1
  dd 0x02 ; 0x18 2 Physical memory map
  dd 1