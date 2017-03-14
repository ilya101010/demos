format ELF

include 'inc/macro.inc'

; >>>> 16bit code

section '.text16' executable
Use16

org 0x7c00 ; why?! loop problems

public start
start:
	mbp
	cli		     ; disabling interrupts
	mov     ax, cs	  ; segment registers' init
	mov     ds, ax
	mov     es, ax
	mov     ss, ax
	mov     sp, 0x7C00      ; stack backwards => ok

	shl eax,4       ;умножаем на 16
	mov ebx,eax     ;копируем в регистр EBX
	; why?!

	push dx, bx, ax, cx
	mov dx, 0 ; set cursor to top left-most corner of screen
	mov bh, 0 ; page
	mov ah, 0x2 ; ah = 2 => set cursor
	int 0x10 ; moving cursor
	mov cx, 2000 ; print 2000 = 80*45 chars
	mov bh, 0
	mov ah, 0x9
	int 0x10
	pop cx, ax, bx, dx

	; mbp
	; ; loading entry_pm to RAM
	; mov ah, 0x02    ; Read Disk Sectors
	; mov al, 19    ; Read one sector only (512 bytes per sector)
	; mov ch, 0x00    ; Track 0
	; mov cl, 0x02    ; Sector 2
	; mov dh, 0x00    ; Head 0
	; mov dl, 0x00    ; Drive 0 (Floppy 1)
	; mov bx, cs
	; mov es, bx   ; Segment 0x2000
	; mov bx, 0x7e00      ;  again remember segments but must be loaded from non immediate data
	; int 13h
	mbp
	mov si, DAP
	mov ah, 0x42
	mov dl, 0x80 ; Floppy
	int 0x13
	
	mbp
	; memory map
memory_map:
	xor ebx, ebx
	xor bp, bp
	mov edx, 534D4150h
	mov eax, 0xe820
	mov edi, 0xF000-20
	.lp:
		add edi, 20
		mov ecx, 20
		mov edx, 534D4150h
		mov eax, 0xe820
		int 15h
		test ebx, ebx
	jnz .lp

	mbp

	; loading GDT
	lgdt    fword   [GDTR]

	; disable NMI
	in  al,70h
	or  al,80h
	out 70h,al

	; enable a20
	in  al,92h
	or  al,2
	out 92h,al
	
	; get into PM
	mov eax,cr0
	or  al,1     
	mov cr0,eax
	mbp
	; O32 jmp far
	db  66h ; O32
	db  0eah ; JMP FAR
	dd  0x7E00 ; offset
	dw  sel_code32 ; selector

DAP:
	.size:	db 10h
	.zero:	db 0
	.num:	dw 100
	.addr:	dw 0x7e00
			dw 0
	.lba:	dd 1
			dd 0

; the same is done in desc.asm - for better migration to >1MB memspace

GDTTable:   ;таблица GDT
; zero seg
d_zero:		db  0,0,0,0,0,0,0,0     
; 32 bit code seg
d_code32:	db  0ffh,0ffh,0,0,0,10011010b,11001111b,0
; data
d_data:		db	0ffh, 0ffh, 0x00, 0, 0, 10010010b, 11001111b, 0x00
GDTSize     =   $-GDTTable
times 5 db 0,0,0,0,0,0,0,0

GDTR:               ;загружаемое значение регистра GDTR
g_size:     dw  GDTSize-1   ;размер таблицы GDT
g_base:     dd  GDTTable           ;адрес таблицы GDT

; >>>> 32bit code

section '.text32' executable align 100h
; org     0x7E00 - done by ld
use32 ; 32 bit PM

public entry_pm

extrn kernel_start
extrn KERNEL_PHYS_ADDR
extrn PAGING_PHYS_ADDR
extrn KERNEL_VMA_ADDR
extrn KERNEL_SIZE

align   10h         ;код должен выравниваться по границе 16 байт
include 'inc/procedures.inc'
entry_pm:
	; >>> setting up all the basic stuff
	cli		     ; disabling interrupts
	; cs already defined
	mbp
	mov ax, sel_data
	mov ss, ax
	mov     esp, 0x7C00

	mov ax, sel_data
	mov ds, ax
	mov es, ax

	; copying to > 1MB
	mov esi, 0x8000
	mov edi, KERNEL_PHYS_ADDR
	mov ecx, KERNEL_SIZE
	shr ecx, 2
	rep movsd

	; ; now paging mess with kernel
	; making PD
	mov eax, PAGING_PHYS_ADDR+0x1000
	or eax, 1
	mov edi, PAGING_PHYS_ADDR
	mov ecx, 0x400
	.pdlp:
		stosd
		add eax, 0x1000
	loop .pdlp
	mbp
	; > mapping neccessary pages
	; this page
	mov eax, 0x00007003
	mov edi, PAGING_PHYS_ADDR+0x1000+7*4
	stosd
	; kernel pages
	mov edi, KERNEL_VMA_ADDR
	shr edi, 10 ; (edi/2^12)*2^2
	add edi, PAGING_PHYS_ADDR+0x1000
	mov eax, KERNEL_PHYS_ADDR
	or eax, 1 ; only present flag - kernel pages!
	mov ecx, KERNEL_SIZE
	shr ecx, 12
	.ptlp:
		stosd
		add eax, 0x1000
	loop .ptlp
	; PD 1:1
	mov edi, PAGING_PHYS_ADDR
	shr edi, 10 ; (edi/2^12)*2^2
	add edi, PAGING_PHYS_ADDR+0x1000
	mov eax, PAGING_PHYS_ADDR
	or eax, 1 ; only present flag - kernel pages!
	mov ecx, 0x1000+1024*0x1000+0x1000 ; + GDT page
	shr ecx, 12
	.patlp:
		stosd
		add eax, 0x1000
	loop .patlp
	; enabling PD
	mov eax, PAGING_PHYS_ADDR
	mov cr3, eax
	mov eax, cr0
	or eax, 0x80000000
	mov cr0, eax
	mbp
	call kernel_start
	jmp $

addr: times 20 db 0
; >>> селекторы дескрипторов (RPL=0, TI=0)
sel_zero    =   0000000b
sel_code32  =   0001000b
sel_data  	=   0010000b

; >>> colors
green = 0x0A
red = 0x04

; Here goes C flat binary?

; >>> boot sector signature
;finish:
;times 0x1FE-finish+start db 0
;db	 0x55, 0xAA ; ñèãíàòóðà çàãðóçî÷íîãî ñåêòîðà