#include <kernel/idt.h>
#include <kernel/memory.h>

volatile static struct idt_header idtr;
int delimit;
volatile static struct idt_entry IDT[IDT_ENTRIES];

void idt_init()
{
	delimit = 0xffff;
	idtr.base = &IDT;
	idtr.limit = sizeof(struct idt_entry)*IDT_ENTRIES;
	//memset(&IDT,0,idtr.limit);
}

void idt_flush()
{
	__asm__("lidt (%0)"
		:
		: "r" ((uint32_t)&idtr)
	);
}

void idt_set_gate(char i, uint32_t off, uint16_t sel, uint8_t flags)
{
	delimit = 0x2a2a;
	IDT[i].offset_low = off & 0xffff;
	IDT[i].offset_high = off >> 16;
	IDT[i].selector = sel;
	IDT[i].flags = flags;
	IDT[i].always0 = 0;
}