#include <kernel/irq.h>
#include <kernel/isr.h>
#include <kernel/idt.h>

void ints_install()
{
	idt_init();
	isr_install();
	irq_install();
	idt_flush();
}

void ints_cli()
{
	__asm__ volatile ("cli");
}