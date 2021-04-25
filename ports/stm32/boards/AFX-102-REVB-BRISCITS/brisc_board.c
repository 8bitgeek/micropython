#include <brisc_board.h>
#include <brisc_thread.h>
#include <xprintf.h>
#include <stm32f746xx.h>

void board_init( void ) 
{
	cpu_int_enable();
}

extern uint32_t board_clkfreq( void )
{
    return SystemCoreClock;
}
