; I haven't worked on this code in so long I have no idea how anything was designed

; Defs
 [BITS 64]
 [ORG 0]
 [DEFAULT REL]
 %define stack  $$+0x1000
 %define ipmm   $$+0x1000
 %define pml3im $$+0x2000   ;PML3 for identity mapping
 %define pml3hh $$+0x3000   ;PML3 for higher half kernel
 %define pml2   $$+0x4000
 %define kernpm $$+0x5000   ;The pm suffix is for PML1 structs
 %define sdtpm  $$+0x6000
 %define kern   $$+0x000000 ; Kernel
 %define sdt    $$+0x200000 ; Standard data table
 %define pmm    $$+0x400000 ; Not currently mapped

init:
 mov [rsrvptr], rax 
 mov ebx, [rax+0x08]
 shl rbx, 12
 mov [kernphy], rbx
 mov ebx, [rax+0x10]
 shl rbx, 12
 mov [pml4phy], rbx
 mov ebx, [rax+0x18]
 shl rbx, 12
 mov [pmmphy], rbx
 lea rsp, [stack]
 test byte [rax+0x05], 1
 jnz genpat1
genpat0:
 ; Todo - test this code on sample sets
 mov rdi, [pmmphy]
 xor ecx, ecx
 mov cx, [rax+0x06]
 lea rsi, [ipmm+0x08]
 genpatloop:
  genpatloc:
   mov eax, [rdi+0x10]
   cmp eax, 1
   jnz genpatnxt
   mov rax, [rdi]
   test rax, 0xFFF
   jz genpatlocdiv
   mov edx, 0x1000
   mov bx, ax
   and bx, 0xFFF
   sub dx, bx
   and rax, 0xFFF
   inc rax
   genpatlocdiv:
   shr rax, 12
  genpatlen:
   mov rbp, [rdi+0x08]
   cmp rbp, 0
   je genpatnxt
   sub rbp, rdx
   jo genpatnxt
   jz genpatnxt
   test rbp, 0xFFF
   jz genpatlendiv
   and rbp, 0xFFFFFFFFFFFFF000
   genpatlendiv:
   shr rbp, 12
  genpatsto:
   inc dword [ipmm]
   add ebp, eax
   mov [rsi+0x00], eax
   mov [rsi+0x04], ebp
   add rsi, 0x08
  genpatnxt:
   add rdi, 0x18
   loop genpatloop
 respatloop:
 ovrpatloop:
 jmp genpmt
genpat1:
genpmt:
 genpml4:
  lea rax, [pml3im]
  lea rbx, [pml3hh]
  or rax, 0x03
  or rbx, 0x03
  mov rcx, [pml4phy]                  ;Reuse the same pml4 passed by the bootloader
  mov [rcx+0x000], rax                ;Map pml3im for identity mapping
  mov [rcx+0xFF8], rbx                ;Map pml3hh for higher half kernel
 genpml3:
  mov qword [pml3im+0x00], 0x00000083 ;Identity map the first 4 GiB
  mov qword [pml3im+0x08], 0x40000083
  mov qword [pml3im+0x10], 0x80000083 ;Nasm will give warnings about number overflow but code functions fine
  mov qword [pml3im+0x18], 0xC0000083
  lea rax, [pml2]
  or rax, 0x03
  mov [pml3hh+0xFF8], rax             ;Map pml2 for highest quarter kernel
 genpml2:
  lea rax, [kernpm]
  or rax, 0x03
  mov [pml2+0x00], rax
  lea rax, [sdtpm]
  or rax, 0x03
  mov [pml2+0x08], rax
 genkpm:
  lea rax, [kernpm]
  lea rbx, $$
  or rbx, 3
  mov ecx, 0x08
  genkpmloop:
   mov [rax], rbx
   add rax, 8
   add rbx, 0x1000
   loop genkpmloop
 genspm:
  mov rax, [pml4phy]
  or rax, 0x03
  mov [sdtpm], rax
 jmphh:
  mov rax, 0xFFFFFFFFC0000000+endjmp
  jmp rax
  endjmp:
getrsdt:
 mov eax, 0x80000 ;Search the first KiB of the EBDA
 mov rbx, 'RSD PTR '
 mov ecx, 0x2000
 rsdploop0:
 cmp [eax], rbx
 add eax, 0x10
 je rsdpfound
 loop rsdploop0
 mov eax, 0x0E0000 ;Search 0x0E0000-0x100000
 mov ecx, 0x2000
 rsdploop1:
 cmp [eax], rbx
 je rsdpfound
 add eax, 16
 loop rsdploop1
 norsdp:
 mov byte [abs 0xB8000], 'r' ;Advanced errorcode printing
 hlt
 rsdpfound:
 mov eax, [eax+0x10] ;Todo - add checksum verification, check xsdt presence (test PC doesnt have one so I havent bothered to yet)
 mov [rsdt], eax
getmadt:
 ;Todo - check for xsdt presence and try parsing that first
 mov eax, [rsdt]
 add eax, 0x24    ;Skip past headers
 mov ecx, [rax+4] ;Get length
 sub ecx, 0x24    ;Subtract headers from length
 shr ecx, 2       ;Divide to get amount of dword entries
 madtloop:
 mov ebx, [eax]
 cmp dword [ebx], 'APIC'
 je madtfound
 add eax, 4
 loop madtloop
 mov byte [abs 0xB8000], 'm'
 hlt
 madtfound:
 mov [madt], ebx
mainloop:
 lidt [idtr]
 mov byte [abs 0xB8000], 'a'
 int 0
 hlt

palloc:
 ; rdi, pointer to ipmm
 push rsi
 mov rsi, rdi
 mov eax, [rdi]
 shl eax, 3
 add rsi, rax
 mov eax, [rsi+4]
 dec dword [rsi+4]
 cmp [rsi], eax
 jne pallocr
 dec dword [rdi]
 mov qword [rsi], 0
 pallocr:
 shl rax, 12
 or al, 0x03
 pop rsi
 ret
pmap:
punmap:
pfree:

int0:
 mov byte [abs 0xB8000], 'i'
 iretq

printeax:
 push rax
 push rbx
 push rcx
 push rdx
 mov edx, [prntbuf]
 mov ecx, 8
 printeax.loop:
  lea rbx, [str.hex]
  mov r8d, eax
  shr r8d, 28
  add rbx, r8
  mov bl, [rbx]
  mov [edx], bl
  add edx, 2
  shl eax, 4
  loop printeax.loop
 add dword [prntbuf], 16
 pop rdx
 pop rcx
 pop rbx
 pop rax
 ret

data:
 align 0x10, db 0
 rsrvptr dq 0
 kernphy dq 0
 pmmphy  dq 0
 pml4phy dq 0
 rsdt    dq 0
 xsdt    dq 0
 madt    dq 0
 prntbuf dd 0xB8000
 str.hex db '0123456789ABCDEF'
 align 0x10, db 0
 idtr:
  dw idt.end-idt-1
  dq 0xFFFFFFFFC0000000+idt ;Hardcoded value for now. Set during init for portability later
 idt:
  dw int0       ;Offset 0-15
  dw 0x08       ;Segment selector
  db 0          ;IST/reserved
  db 0x8E       ;Gatetype(0-3), 0(4), DPL(5-6), present(7)
  dw 0xC000     ;Offset 16-31
  dd 0xFFFFFFFF ;Offset 32-63 ;Hardcoded value for now. Set during init for portability later
  dq 0          ;Reserved
  idt.end:
%if $-$$ > 0x0F00
 %error "Exceeded current allocation"
 %endif