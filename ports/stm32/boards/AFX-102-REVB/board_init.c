#include STM32_HAL_H

#include <systick.h>

void AFX_102_REVB_board_early_init(void) 
{
    __HAL_RCC_GPIOK_CLK_ENABLE();

}

