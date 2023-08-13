; I haven't worked on this code in so long I have no idea how anything was designed

; Defs
 [BITS 64]
 [ORG 0]
 [DEFAULT REL]
 %define stack  $$+0x1000   ;Todo - allocate a block for the stack once the palloc function is implemented
 %define ipmm   $$+0x1000
 %define pml3im $$+0x2000   ;PML3 for identity mapping
 %define pml3hh $$+0x3000   ;PML3 for higher half kernel
 %define pml2   $$+0x4000
 %define kernpm $$+0x5000   ;The pm suffix is for PML1 structs
 %define sdtpm  $$+0x6000
 %define pciblk $$+0x7000   ;Temporary block for PCI
 %define atablk $$+0x8000   ;Temporary block for ATA
 %define kern   $$+0x000000 ;Kernel
 %define sdt    $$+0x200000 ;Standard data table
 %define pmm    $$+0x400000 ;Not currently mapped

init:
 ;The loader passes a pointer to kernel flags and reserved sections in rax
 mov [rsrvptr],rax      ;Store reserved sections
 mov ebx,[rax+0x08]
 shl rbx,12
 mov [kernphy],rbx
 mov ebx,[rax+0x10]
 shl rbx,12
 mov [pml4phy],rbx
 mov ebx,[rax+0x18]
 shl rbx,12
 mov [pmmphy],rbx
 lea rsp,[stack]        ;Set the stack
 test byte [rax+0x05],1 ;Get the memory map type from the flags
 jnz genpat1
genpat0:
 ; Todo - recode and add comments
 mov rdi,[pmmphy]
 xor ecx,ecx
 mov cx,[rax+0x06]
 lea rsi,[ipmm+0x08]
 genpatloop:
  genpatloc:
   mov eax,[rdi+0x10]
   cmp eax,1
   jnz genpatnxt
   mov rax,[rdi]
   test rax,0xFFF
   jz genpatlocdiv
   mov edx,0x1000
   mov bx,ax
   and bx,0xFFF
   sub dx,bx
   and rax,0xFFF
   inc rax
   genpatlocdiv:
   shr rax,12
  genpatlen:
   mov rbp,[rdi+0x08]
   cmp rbp,0
   je genpatnxt
   sub rbp,rdx
   jo genpatnxt
   jz genpatnxt
   test rbp,0xFFF
   jz genpatlendiv
   and rbp,0xFFFFFFFFFFFFF000
   genpatlendiv:
   shr rbp,12
  genpatsto:
   inc dword [ipmm]
   add ebp,eax
   mov [rsi+0x00],eax
   mov [rsi+0x04],ebp
   add rsi,0x08
  genpatnxt:
   add rdi,0x18
   loop genpatloop
 respatloop:
 ovrpatloop:
 jmp genpmls
genpat1:
genpmls:
 ;Todo - allocate memory blocks using palloc to avoid touching reserved memory
 genpml4:
  lea rax,[pml3im]
  lea rbx,[pml3hh]
  or rax,0x03
  or rbx,0x03
  mov rcx,[pml4phy]                  ;Reuse the same pml4 passed by the bootloader
  mov [rcx+0x000],rax                ;Map pml3im for identity mapping
  mov [rcx+0xFF8],rbx                ;Map pml3hh for higher half kernel
 genpml3:
  ;The upper 32 bits of each entry may contain spurious values,make sure to explicitly zero those out later
  mov dword [pml3im+0x00],0x00000083 ;Identity map the first 4 GiB
  mov dword [pml3im+0x08],0x40000083
  mov dword [pml3im+0x10],0x80000083
  mov dword [pml3im+0x18],0xC0000083
  lea rax,[pml2]
  or rax,0x03
  mov [pml3hh+0xFF8],rax             ;Map pml2 for highest quarter kernel
 genpml2:
  lea rax,[kernpm]
  or rax,0x03
  mov [pml2+0x00],rax
  lea rax,[sdtpm]
  or rax,0x03
  mov [pml2+0x08],rax
 genkpm:
  lea rax,[kernpm]
  lea rbx,$$
  or rbx,3
  mov ecx,0x10 ;Map 16 pages for the
  genkpmloop:
   mov [rax],rbx
   add rax,8
   add rbx,0x1000
   loop genkpmloop
 genspm:
  mov rax,[pml4phy]
  or rax,0x03
  mov [sdtpm],rax
 jmphh:
  mov rax,0xFFFFFFFFC0000000+endjmp
  jmp rax
  endjmp:
getrsdt:
 mov eax,0x80000 ;Search the first KiB of the EBDA
 mov rbx,'RSD PTR '
 mov ecx,0x2000
 rsdploop0:
 cmp [eax],rbx
 add eax,0x10
 je rsdpfound
 loop rsdploop0
 mov eax,0x0E0000 ;Search 0x0E0000-0x100000
 mov ecx,0x2000
 rsdploop1:
 cmp [eax],rbx
 je rsdpfound
 add eax,16
 loop rsdploop1
 norsdp:
 mov byte [abs 0xB8000],'r' ;Advanced errorcode printing
 hlt
 rsdpfound:
 mov eax,[eax+0x10] ;Todo - add checksum verification,check xsdt presence (test PC doesnt have one so I havent bothered to yet)
 mov [rsdt],eax
getmadt:
 ;Todo - check for xsdt presence and try parsing that first
 mov eax,[rsdt]
 add eax,0x24    ;Skip past headers
 mov ecx,[rax+4] ;Get length
 sub ecx,0x24    ;Subtract headers from length
 shr ecx,2       ;Divide to get amount of dword entries
 madtloop:
 mov ebx,[eax]
 cmp dword [ebx],'APIC'
 je madtfound
 add eax,4
 loop madtloop
 mov byte [abs 0xB8000],'m'
 hlt
 madtfound:
 mov [madt],ebx
pciconf:
 ;Note - my laptop doesn't have a multifunction host or PCI-PCI bridges so related code has not been tested
 lea rdi,[pciblk]
 mov ebx,0x80000000
 call funcmulti
 jc multihost
 call checkbus
 jmp pciend
 checkbus:
  mov ecx,0x20 ;32 devices on each bus
  devicecheckloop:
  call funcpresent
  jnc nextdevice
  call funcmulti
  jc multidevice
  call funcstore
  call funcbridge
  nextdevice:
  add ebx,0x800
  loop devicecheckloop
  ret
 multidevice:
  mov bpl,8 ;8 functions on each device
  multideviceloop:
  call funcpresent
  jnc nextfunc
  call funcstore
  call funcbridge
  nextfunc:
  add ebx,0x100
  dec bpl
  jnz multideviceloop
  jmp nextdevice
 multihost:
  mov sil,8        ;Check the 8 functions on the device
  mov r8d,ebx      ;Use r8d to store the function address
  mov r9d,ebx      ;Use r9d to store the bus address
  multihostloop:
  mov ebx,r8d
  call funcpresent
  jnc nextbus
  mov ebx,r9d
  call checkbus
  nextbus:
  add r8d,0x100
  add r9d,0x10000 ;Increment bus
  dec sil
  jnz multihostloop
  jmp pciend
 funcstore:
  call funcclass
  mov [rdi+0x00],eax
  mov [rdi+0x04],ebx
  add rdi,8
  inc dword [pcilen]
  ret
 funcpresent:
  ;Sets the carry flag if the device is present
  mov dx,0xCF8
  xor bl,bl
  mov eax,ebx
  out dx,eax
  mov dx,0xCFC
  in eax,dx
  cmp ax,0xFFFF
  jne isfunc
  clc
  ret
  isfunc:
  stc
  ret
 funcclass:
  ;Returns the function class in eax
  mov dx,0xCF8
  mov bl,0x08
  mov eax,ebx
  out dx,eax
  mov dx,0xCFC
  in eax,dx
  ret
 funcmulti:
  ;Sets the carry flag if the device is multifunction
  mov dx,0xCF8
  mov bl,0x0C
  mov eax,ebx
  out dx,eax
  mov dx,0xCFC
  in eax,dx
  test eax,0x800000
  jnz ismulti
  clc
  ret
  ismulti:
  stc
  ret
 funcbridge:
  ;Checks if the function is a PCI-PCI bridge, if it is the connected bus is checked
  call funcclass
  shr eax,16
  cmp ax,0x0604
  jne notbridge
  mov bl,0x18
  mov dx,0xCF8
  mov eax,ebx
  out dx,eax
  mov dx,0xCFC
  in eax,dx
  and eax, 0x0000FF00 ;Isolate and shift the secondary bus number in eax
  shl eax,8
  push rbx
  push rcx
  push rsi
  mov ebx,eax
  call checkbus
  pop rsi
  pop rcx
  pop rbx
  notbridge:
  ret
 pciend:
intconf:
 lidt [idtr]
 ;Currently assuming that the addresses are initialized to their standard locations. Get the values from the MADT later
 mov ecx,0xFEE000F0
 mov edx,0xFEC00000
 mov eax,[ecx]             ;Get the mask
 mov eax,0x1FF             ;Set the enable bit
 mov [ecx+0xF0],eax        ;Save values
 mov dword [edx],0x12      ;Register to read/write to
 mov dword [edx+0x10],0x21 ;Interrupt vector
 mov dword [edx],0x20      ;Register to read/write to
 mov dword [edx+0x10],0x28 ;Interrupt vector
rtcconf:
 mov al,0x8B ;Configure RTC
 out 0x70,al ;Select B
 in al,0x71  ;Read from B
 mov bl,al   ;Store B and set bit
 or bl,0x40
 mov al,0x8B ;Select B again
 out 0x70,al
 mov al,bl
 out 0x71,al ;Turn on RTC IRQs 
 int 0x28
ataconf:
 pioconf:
  piobus0:
  xor eax,eax
  mov dx,0x1F6
  mov al,0x0A
  call piochk
  mov [drives+0x00],eax
  cmp al,0xFF
  je piobus1
  mov dx,0x1F6
  mov al,0x0B
  call piochk
  mov [drives+0x04],eax
  piobus1:
  mov dx,0x176
  mov al,0x0A
  call piochk
  mov [drives+0x08],eax
  mov dx,0x176
  mov al,0x0B
  call piochk
  mov [drives+0x08],eax
  cli
  hlt
scrconf:
 mov al,0x0A ; Disable cursor
 mov dx,0x3D4
 out dx,al
 inc dx
 mov al,0x20
 out dx,al
 mov byte [abs 0xB8000+160*0x00+02],'^'
 mov byte [abs 0xB8000+160*0x00+82],'V'
 mov byte [abs 0xB8000+160*0x02+02],'0'
 mov byte [abs 0xB8000+160*0x03+02],'1'
 mov byte [abs 0xB8000+160*0x04+02],'2'
 mov byte [abs 0xB8000+160*0x05+02],'3'
 mov byte [abs 0xB8000+160*0x06+02],'4'
 mov byte [abs 0xB8000+160*0x07+02],'5'
 mov byte [abs 0xB8000+160*0x08+02],'6'
 mov byte [abs 0xB8000+160*0x09+02],'7'
 mov byte [abs 0xB8000+160*0x0A+02],'8'
 mov byte [abs 0xB8000+160*0x0B+02],'9'
 mov byte [abs 0xB8000+160*0x0C+02],'0'
 mov byte [abs 0xB8000+160*0x0D+02],'q'
 mov byte [abs 0xB8000+160*0x0E+02],'w'
 mov byte [abs 0xB8000+160*0x0F+02],'e'
 mov byte [abs 0xB8000+160*0x10+02],'r'
 mov byte [abs 0xB8000+160*0x11+02],'t'
 mov byte [abs 0xB8000+160*0x13+02],'^'
 mov byte [abs 0xB8000+160*0x13+82],'V'
 mov byte [abs 0xB8000+160*0x02+82],'y'
 mov byte [abs 0xB8000+160*0x03+82],'u'
 mov byte [abs 0xB8000+160*0x04+82],'i'
 mov byte [abs 0xB8000+160*0x05+82],'o'
 mov byte [abs 0xB8000+160*0x06+82],'p'
 mov byte [abs 0xB8000+160*0x07+82],'a'
 mov byte [abs 0xB8000+160*0x08+82],'s'
 mov byte [abs 0xB8000+160*0x09+82],'d'
 mov byte [abs 0xB8000+160*0x0A+82],'f'
 mov byte [abs 0xB8000+160*0x0B+82],'g'
 mov byte [abs 0xB8000+160*0x0C+82],'h'
 mov byte [abs 0xB8000+160*0x0D+82],'j'
 mov byte [abs 0xB8000+160*0x0E+82],'k'
 mov byte [abs 0xB8000+160*0x0F+82],'l'
 mov byte [abs 0xB8000+160*0x10+82],'z'
 mov byte [abs 0xB8000+160*0x11+82],'x'
funconf:
 lea rax,[crash]
 mov [functable+0x00],rax 
mainloop:
 sti
 lea rdi,[opttable]
 call printlines
 cmp byte [handled],1
 je nokey
 cmp byte [lastkey],0x0B
 je callfunc
 mov byte [handled],1
 nokey:
 hlt
 jmp mainloop
callfunc:
 call [functable]
 jmp mainloop

mem:
 palloc:
  ; rdi,pointer to ipmm
  push rsi
  mov rsi,rdi
  mov eax,[rdi]
  shl eax,3
  add rsi,rax
  mov eax,[rsi+4]
  dec dword [rsi+4]
  cmp [rsi],eax
  jne pallocr
  dec dword [rdi]
  mov qword [rsi],0
  pallocr:
  shl rax,12
  or al,0x03
  pop rsi
  ret
 pmap:
 punmap:
 pfree:
atapi:
 pichk:
  ret
atapio:
 ;I currently only have ATAPI hard drives to test with so I'm putting most of this off for later
 ;The piochk function isnt fully tested but it will send back the correct drive type in ax which is good enough for me
 piochk:
  ;Inputs
   ;al,  master(0xA0)/slave(0xB0)
   ;dx,  port base
   ;rdi, result block
  ;Outputs
   ;eax, result
  call pioset  ;0x06->0x07
  cmp al,0xFF  ;If al is 0xFF then the bus is not present
  jz piochkerr
  xor al,al
  sub dx,2     ;0x07->0x05 LBAhi register
  out dx,al
  dec dx       ;0x05->0x04 LBAmid
  out dx,al
  dec dx       ;0x04->0x03 LBAlo
  out dx,al
  dec dx       ;0x03->0x02 Sectorcount
  out dx,al
  add dx,5     ;0x02->0x07 Status/command
  mov al,0xEC  ;IDENTIFY
  out dx,al
  in al,dx
  test al,al   ;If status is 0 then the device is not present
  jz piochkerr
  piopoll0:
  in al,dx     ;Still the status port
  test al,0x80 ;Wait for the BSY bit to clear
  jnz piopoll0
  sub dx,3     ;0x07->0x04 LBAmid
  in al,dx
  shl ax,8
  inc dx       ;0x04->0x05 LBAhi
  in al,dx
  test ax,ax
  jnz piochkerr
  add dx,2     ;0x05->0x07 Status
  piopoll1:
  in al,dx
  test al,0x09 ;Wait until DRQ or ERR sets
  jz piopoll1
  test al,1
  jnz piochkerr
  sub dx,7     ;0x07->0x00 Data
  mov ecx,256
  rep insw     ;Read the block
  or eax,0x10000000
  xor ax,ax
  ret
  piochkerr:
  and eax,0xFFFF
  ret
 piord:
 piowr:
 pioset:
  ;al, master(0xA0)/slave(0xB0)
  ;dx, drive select port
  out dx,al
  inc dx              ;Status register
  times 0x10 in al,dx ;400ns delay
  ret
ints:
 interr:
  mov rdi,0xB8000+160*24
  mov byte [rdi],'a'
  lea rsi,[errmsg]
  call printat
  cli
  hlt
 int21:
  in al,0x60           ;Read keyboard input
  mov [lastkey],al     ;Save
  mov byte [handled],0 ;Clear handled flag
  mov eax,0xFEE000B0   ;Send EOI
  mov dword [eax],0
  iretq
 int28:
  inc byte [abs 0xB8000+160*24+158]
  mov al,0x0C
  out 0x70,al
  in al,0x71
  mov eax,0xFEE000B0   ;Send EOI
  mov dword [eax],0
  iretq
misc:
 printeax:
  push rax
  push rbx
  push rcx
  push rdx
  mov edx,[prntbuf]
  mov ecx,8
  printeax.loop:
   lea rbx,[str.hex]
   mov r8d,eax
   shr r8d,28
   add rbx,r8
   mov bl,[rbx]
   mov [edx],bl
   add edx,2
   shl eax,4
   loop printeax.loop
  add dword [prntbuf],16
  pop rdx
  pop rcx
  pop rbx
  pop rax
  ret
 printat:
  ;Print offset in rdi
  ;Zero terminated string in rsi
  printatl:
  mov al,[rsi]
  test al,al
  jz printatend
  mov [rdi],al
  inc rsi
  inc rdi
  inc rdi
  jmp printatl
  printatend ret
 printlines:
  ;Print struct in rdi
  xor bh,bh   ;Character index in line
  mov ecx,2   ;Line
  mov esi,6   ;Column offset
  plnextline:
  mov eax,160
  mul ecx
  add eax,0xB8000
  add eax,esi
  plloop:
   mov bl,[rdi]
   test bl,bl
   jz plnext
   mov [eax],bl
   add eax,2
   inc rdi
   inc bh
   cmp bh,37
   je plnexts
   jmp plloop
  plnexts:
   inc rdi
   mov bl,[rdi]
   test bl,bl
   jnz plnexts
  plnext:
   xor bh,bh
   inc rdi
   mov bl,[rdi]
   cmp bl,3
   je plend
   inc ecx
   cmp ecx,0x17
   jne plnextline
   add esi,80
   mov ecx,2
   jmp plnextline
   plend:
  ret
 crash:
  jmp 0

data:
 align 0x10,db 0
 rsrvptr dq 0
 kernphy dq 0
 pmmphy  dq 0
 pml4phy dq 0
 rsdt    dq 0
 xsdt    dq 0
 madt    dq 0
 drives  times 8 dd 0
 prntbuf dd 0xB8000
 str.hex db '0123456789ABCDEF'
 pcilen  dd 0
 lastkey db 0
 handled db 1
 align 0x10,db 0
 idtr:
  dw idt.end-idt-1
  dq 0xFFFFFFFFC0000000+idt ;Hardcoded value for now. Set during init for portability later
 idt:
  %macro idterr 0
   dw interr     ;Offset 0-15 ;0x21 is keyboard
   dw 0x08       ;Segment selector
   db 0          ;IST/reserved
   db 0x8E       ;Gatetype(0-3),0(4),DPL(5-6),present(7)
   dw 0xC000     ;Offset 16-31
   dd 0xFFFFFFFF ;Offset 32-63 ;Hardcoded value for now. Set during init for portability later
   dd 0          ;Reserved
   %endmacro
  %rep 0x21
   idterr        ;Reserved entries + PIT interrupt
   %endrep
  dw int21       ;Offset 0-15 ;0x21 is keyboard
  dw 0x08        ;Segment selector
  db 0           ;IST/reserved
  db 0x8E        ;Gatetype(0-3),0(4),DPL(5-6),present(7)
  dw 0xC000      ;Offset 16-31
  dd 0xFFFFFFFF  ;Offset 32-63 ;Hardcoded value for now. Set during init for portability later
  dd 0           ;Reserved
  %rep 0x06
   idterr        ; Not using these yet
   %endrep
  dw int28       ;Offset 0-15 ;0x28 is RTC
  dw 0x08        ;Segment selector
  db 0           ;IST/reserved
  db 0x8E        ;Gatetype(0-3),0(4),DPL(5-6),present(7)
  dw 0xC000      ;Offset 16-31
  dd 0xFFFFFFFF  ;Offset 32-63 ;Hardcoded value for now. Set during init for portability later
  dd 0           ;Reserved
  idt.end:
 opttable:
  db 'Crash',0,3
 errmsg db 'Everything has crashed!',0
 functable:
  dq 0
  dq 0
%if $-$$ > 0x0F00
 %error "Exceeded current allocation"
 %endif