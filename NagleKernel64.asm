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
 jmp genpmls
genpat1:
genpmls:
 genpml4:
  lea rax, [pml3im]
  lea rbx, [pml3hh]
  or rax, 0x03
  or rbx, 0x03
  mov rcx, [pml4phy]                  ;Reuse the same pml4 passed by the bootloader
  mov [rcx+0x000], rax                ;Map pml3im for identity mapping
  mov [rcx+0xFF8], rbx                ;Map pml3hh for higher half kernel
 genpml3:
  ;The upper 32 bits of each entry may contain spurious values, make sure to explicitly zero those out later
  mov dword [pml3im+0x00], 0x00000083 ;Identity map the first 4 GiB
  mov dword [pml3im+0x08], 0x40000083
  mov dword [pml3im+0x10], 0x80000083
  mov dword [pml3im+0x18], 0xC0000083
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
  mov ecx, 0x10
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
intconf:
 lidt [idtr]
 ;Currently assuming that the addresses are initialized to their standard locations. Get the values from the MADT later
 mov ecx, 0xFEE000F0
 mov edx, 0xFEC00000
 mov eax, [ecx]             ;Get the mask
 mov eax, 0x1FF             ;Set the enable bit
 mov [ecx+0xF0], eax        ;Save values
 mov dword [edx], 0x12      ;Register to read/write to
 mov dword [edx+0x10], 0x21 ;???
scrconf:
 mov al, 0x0A ; Disable cursor
 mov dx, 0x3D4
 out dx, al
 inc dx
 mov al, 0x20
 out dx, al
 mov byte [abs 0xB8000+160*0x00+02], '^'
 mov byte [abs 0xB8000+160*0x00+82], 'V'
 mov byte [abs 0xB8000+160*0x02+02], '0'
 mov byte [abs 0xB8000+160*0x03+02], '1'
 mov byte [abs 0xB8000+160*0x04+02], '2'
 mov byte [abs 0xB8000+160*0x05+02], '3'
 mov byte [abs 0xB8000+160*0x06+02], '4'
 mov byte [abs 0xB8000+160*0x07+02], '5'
 mov byte [abs 0xB8000+160*0x08+02], '6'
 mov byte [abs 0xB8000+160*0x09+02], '7'
 mov byte [abs 0xB8000+160*0x0A+02], '8'
 mov byte [abs 0xB8000+160*0x0B+02], '9'
 mov byte [abs 0xB8000+160*0x0C+02], '0'
 mov byte [abs 0xB8000+160*0x0D+02], 'q'
 mov byte [abs 0xB8000+160*0x0E+02], 'w'
 mov byte [abs 0xB8000+160*0x0F+02], 'e'
 mov byte [abs 0xB8000+160*0x10+02], 'r'
 mov byte [abs 0xB8000+160*0x11+02], 't'
 mov byte [abs 0xB8000+160*0x13+02], '^'
 mov byte [abs 0xB8000+160*0x13+82], 'V'
 mov byte [abs 0xB8000+160*0x02+82], 'y'
 mov byte [abs 0xB8000+160*0x03+82], 'u'
 mov byte [abs 0xB8000+160*0x04+82], 'i'
 mov byte [abs 0xB8000+160*0x05+82], 'o'
 mov byte [abs 0xB8000+160*0x06+82], 'p'
 mov byte [abs 0xB8000+160*0x07+82], 'a'
 mov byte [abs 0xB8000+160*0x08+82], 's'
 mov byte [abs 0xB8000+160*0x09+82], 'd'
 mov byte [abs 0xB8000+160*0x0A+82], 'f'
 mov byte [abs 0xB8000+160*0x0B+82], 'g'
 mov byte [abs 0xB8000+160*0x0C+82], 'h'
 mov byte [abs 0xB8000+160*0x0D+82], 'j'
 mov byte [abs 0xB8000+160*0x0E+82], 'k'
 mov byte [abs 0xB8000+160*0x0F+82], 'l'
 mov byte [abs 0xB8000+160*0x10+82], 'z'
 mov byte [abs 0xB8000+160*0x11+82], 'x'
funconf:
 lea rax, [crash]
 mov [functable+0x00], rax 
mainloop:
 sti
 lea rdi, [opttable]
 call printlines
 cmp byte [handled], 1
 je nokey
 cmp byte [lastkey], 0x0B
 je callfunc
 mov byte [handled], 1
 nokey:
 hlt
 jmp mainloop
callfunc:
 call [functable]

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
printat:
 ;Print offset in rdi
 ;Zero terminated string in rsi
 printatl:
 mov al, [rsi]
 test al, al
 jz printatend
 mov [rdi], al
 inc rsi
 inc rdi
 inc rdi
 jmp printatl
 printatend ret
printlines:
 ;Print struct in rdi
 xor bh, bh   ;Character index in line
 mov ecx, 2   ;Line
 mov esi, 6   ;Column offset
 plnextline:
 mov eax, 160
 mul ecx
 add eax, 0xB8000
 add eax, esi
 plloop:
  mov bl, [rdi]
  test bl, bl
  jz plnext
  mov [eax], bl
  add eax, 2
  inc rdi
  inc bh
  cmp bh, 37
  je plnexts
  jmp plloop
 plnexts:
  inc rdi
  mov bl, [rdi]
  test bl, bl
  jnz plnexts
 plnext:
  xor bh, bh
  inc rdi
  mov bl, [rdi]
  cmp bl, 3
  je plend
  inc ecx
  cmp ecx, 0x17
  jne plnextline
  add esi, 80
  mov ecx, 2
  jmp plnextline
  plend:
 ret
crash:
 jmp 0

interr:
 mov rdi, 0xB8000+160*24
 mov byte [rdi], 'a'
 lea rsi, [errmsg]
 call printat
 cli
 hlt
int21:
 in al, 0x60           ;Read keyboard input
 mov [lastkey], al     ;Save
 mov byte [handled], 0 ;Clear handled flag
 mov eax, 0xFEE000B0   ;Send EOI
 mov dword [eax], 0
 iretq

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
 lastkey db 0
 handled db 1
 align 0x10, db 0
 idtr:
  dw idt.end-idt-1
  dq 0xFFFFFFFFC0000000+idt ;Hardcoded value for now. Set during init for portability later
 idt:
  %macro idterr 0
   dw interr     ;Offset 0-15 ;0x21 is keyboard
   dw 0x08       ;Segment selector
   db 0          ;IST/reserved
   db 0x8E       ;Gatetype(0-3), 0(4), DPL(5-6), present(7)
   dw 0xC000     ;Offset 16-31
   dd 0xFFFFFFFF ;Offset 32-63 ;Hardcoded value for now. Set during init for portability later
   dd 0          ;Reserved
   %endmacro
  %rep 0x21
   idterr        ;Reserved entries
   %endrep
  dw int21       ;Offset 0-15 ;0x21 is keyboard
  dw 0x08        ;Segment selector
  db 0           ;IST/reserved
  db 0x8E        ;Gatetype(0-3), 0(4), DPL(5-6), present(7)
  dw 0xC000      ;Offset 16-31
  dd 0xFFFFFFFF  ;Offset 32-63 ;Hardcoded value for now. Set during init for portability later
  dd 0           ;Reserved
  idt.end:
 opttable:
  db 'Crash', 0, 3
 errmsg db 'Everything has crashed!', 0
 functable:
  dq 0
  dq 0
%if $-$$ > 0x0F00
 %error "Exceeded current allocation"
 %endif