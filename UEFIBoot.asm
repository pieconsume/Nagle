;Defs
 [BITS 64]
 [DEFAULT REL]
 %define u(x) __?utf16?__(x)
 ;Image handle in rcx
 ;System table in rdx
 ;Pass rcx,rdx,r8,r9,stack

regs:
 mov rbx,[rdx+0x60]
kptr:
 lea rax,[$$+0x1000]
 shr rax,12
 mov [resmem+0x04],eax
pmlp:
 xor ecx,ecx
 mov edx,2
 mov r8d,2
 lea r9, [pmlptr]
 call [rbx+0x28]
 mov rax,[pmlptr]
 shr rax,12
 mov [resmem+0x0C],eax
getm:
 lea rcx,[memsize]
 xor edx,edx
 lea r8,[mapkey]
 lea r9,[dscsize]
 lea rax,[dscver]
 push rax
 call [rbx+0x38]
 mov eax,[memsize]
 and eax,0xFFFFF000
 add eax,0x1000
 mov [memsize],eax
 shr eax,12
 mov [resmem+0x18],eax
 xor ecx,ecx
 mov edx,2
 mov r8d,eax
 lea r9, [mapptr]
 call [rbx+0x28]
 mov rax,[mapptr]
 shr rax,12
 mov [resmem+0x14],eax
 lea rcx,[memsize]
 lea rdx,[mapptr]
 lea r8, [mapkey]
 lea r9, [dscsize]
 lea rax,[dscver]
 push rax
 call [rbx+0x38]
exitb:
setup:
enter:
data:
 pmlptr  dq 0
 mapptr  dq 0
 memsize dd 0
 mapkey  dd 0
 dscsize dd 0
 dscver  dd 0
 resmem:
  dd 3 ;Count
  db 0 ;Flags
  db 1 ;Map type
  dw 0 ;Map entries
  dd 0 ;Kernel
  dd 1
  dd 0 ;pml4
  dd 2
  dd 0 ;pmm
  dd 0

%if $-$$ > 0x1000
 %error "Out of space"
 %endif