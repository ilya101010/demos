/**
 * @file memory.c
 * Low-level memory functions.
 */

#include <memory.h>

/**
 * @brief      Sets memory.
 *
 * @param      dest  The destination
 * @param[in]  c     Value to set
 * @param[in]  n     Number of bytes to be set.
 *
 * @return     End destination
 */
void* memset(void * dest, int c, size_t n) {
	asm volatile("rep stosb"
	             : "=c"((int){0})
	             : "D"(dest), "a"(c), "c"(n)
	             : "flags", "memory");
	return dest;
}