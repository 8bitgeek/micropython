#ifndef _BRISC_BOARD_H_
#define _BRISC_BOARD_H_

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include <stm32f746xx.h>
#include <core_cm7.h>
#include <cpu.h>

/* MicroPython PendSV and SysTick ISRs */
extern void PendSV_Handler(void);
extern void SysTick_Handler(void);

extern void     brisc_board_init( void );
extern uint32_t brisc_board_clkfreq( void );

#endif
