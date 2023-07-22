; Defs
 [BITS 64]
 [ORG 0]
 [DEFAULT REL]
 %define stack  $$+0x1000
 %define ipmm   $$+0x1000
 %define pml3   $$+0x2000
 %define pml2   $$+0x3000
 %define kernpm $$+0x4000
 %define sdtpm  $$+0x5000
 %define sdt    $$+0x200000
 %define pmm    $$+0x400000

init:
 mov byte [abs 0xB8000], 'a'
 cli
 hlt
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
 test byte [rax+4], 1
 jnz genpat1
genpat0:
 ; Todo - test this code on sample sets
 mov edi, [rax+0x18]
 shl rdi, 12
 xor ecx, ecx
 mov cx, [rdi]
 add rdi, 4
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
 genkpm:
  lea rax, [kernpm]
  lea rbx, $$
  or rbx, 3
  mov ecx, 0
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
  mov rax, 0xFFFFFFFFC0000000+clrpml4
  jmp rax
 clrpml4:
  lea rax, [sdt]
  mov ecx, 511
  clrpml4loop:
   mov qword [rax], 0
   add rax, 8
   loop clrpml4loop
lpic:
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
 prntbuf dd 0xB8000
 str.hex db '0123456789ABCDEF'

%if $-$$ > 0x0F00
 %error "Exceeded current allocation"
 %endif