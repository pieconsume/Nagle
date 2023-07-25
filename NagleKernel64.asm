; I haven't worked on this code in so long I have no idea how anything was designed

; Defs
 [BITS 64]
 [ORG 0]
 [DEFAULT REL]
 %define stack  $$+0x1000
 %define ipmm   $$+0x1000
 %define pml3   $$+0x2000
 %define pml2   $$+0x3000
 %define kernpm $$+0x4000  ;pm suffix is for pml1 structs
 %define sdtpm  $$+0x5000
 %define vidpm  $$+0x6000 
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
  lea rax, [pml3]
  or rax, 0x03
  mov rbx, [pml4phy]
  mov [rbx+0xFF8], rax
 genpml3:
  lea rax, [pml2]
  or rax, 0x03
  mov [pml3+0xFF8], rax
 genpml2:
  lea rax, [kernpm]
  or rax, 0x03
  mov [pml2+0x000], rax
  lea rax, [sdtpm]
  or rax, 0x03
  mov [pml2+0x008], rax
  lea rax, [vidpm]
  or rax, 0x03
  mov [pml2+0x018], rax
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
 mov byte [abs 0xB8000], 'a'
 mov byte [abs 0xB8000+1], 0x0F
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
 rsrvptr dq 0
 kernphy dq 0
 pmmphy  dq 0
 pml4phy dq 0
 rsdt    dq 0
 xsdt    dq 0
 madt    dq 0
 prntbuf dd 0xB8000
 str.hex db '0123456789ABCDEF'

%if $-$$ > 0x0F00
 %error "Exceeded current allocation"
 %endif