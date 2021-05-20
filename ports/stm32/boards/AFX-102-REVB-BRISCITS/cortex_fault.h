#ifndef _CORTEX_FAULT_H_
#define _CORTEX_FAULT_H_

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C"
{
#endif

__attribute__((naked)) void _hard_fault(void);
__attribute__((naked)) void _mem_hard_fault(void);

#ifdef __cplusplus
}
#endif

#endif
