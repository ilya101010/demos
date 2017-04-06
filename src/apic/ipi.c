#include <kernel/ipi.h>
#include <kernel/apic.h>
#include <kernel/debug.h>

#define ICR_LOW 0x30
#define ICR_HIGH 0x31

void ipi_send(uint8_t vector, uint8_t delivery_mode, uint8_t dst_mode, uint8_t level, uint8_t trig, uint8_t dst_sh, uint8_t dst)
{
	uint32_t ICR_low = 0, ICR_high = 0;
	ICR_low |= vector;
	ICR_low |= (delivery_mode & 7) << 8;
	ICR_low |= (dst_mode & 1) << 11;
	ICR_low |= (level & 1) << 14;
	ICR_low |= (trig & 1) << 15;
	ICR_low |= (dst_sh & 3) << 18;
	ICR_high |= dst << 56;
	mbp;
	lapic_reg_write(ICR_HIGH, ICR_high);
	lapic_reg_write(ICR_LOW, ICR_low);
	// god save our souls
}