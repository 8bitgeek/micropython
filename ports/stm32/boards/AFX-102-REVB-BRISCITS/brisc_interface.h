#ifndef _BRISC_INTERFACE_H_
#define _BRISC_INTERFACE_H_

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

typedef struct _brisc_interface_
{
    uint32_t sstack;                         
    uint32_t estack;
    uint32_t low_stack_limit;
} brisc_interface_t;

#endif
