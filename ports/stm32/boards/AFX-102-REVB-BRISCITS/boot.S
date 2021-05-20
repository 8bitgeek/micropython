/******************************************************************************
 ________  ________  ___  ________  ________  ___  _________  ________      
|\   __  \|\   __  \|\  \|\   ____\|\   ____\|\  \|\___   ___\\   ____\     
\ \  \|\ /\ \  \|\  \ \  \ \  \___|\ \  \___|\ \  \|___ \  \_\ \  \___|_    
 \ \   __  \ \   _  _\ \  \ \_____  \ \  \    \ \  \   \ \  \ \ \_____  \   
  \ \  \|\  \ \  \\  \\ \  \|____|\  \ \  \____\ \  \   \ \  \ \|____|\  \  
   \ \_______\ \__\\ _\\ \__\____\_\  \ \_______\ \__\   \ \__\  ____\_\  \ 
    \|_______|\|__|\|__|\|__|\_________\|_______|\|__|    \|__| |\_________\
                            \|_________|                        \|_________|

MIT License

Copyright (c) 2021 Mike Sharkey

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

******************************************************************************/
        .syntax unified
        .section .init, "ax"

        .global board_init
        .global main

        .global _fpu_init
        .global _bss_init
        .global _cpp_init		
        .global _cpp_deinit		
        .global _core_clock_init
        .global _systick_init

        .global __main_stack_end__
        .global	_estack

        .global UsageFault_IRQ_Handler
        .global BusFault_IRQ_Handler

        .global default_interrupt_handler
        .global debug_interrupt_handler
        .global Reset_Handler

        .type	Reset_Handler, %function
        .code   16
        .align 	2
        .thumb_func

Reset_Handler:
        cpsid	i		        // disable interrupts

        ldr	r0,=_estack             // get the process stack
        msr	psp,r0                  // set the process stack pointer
        movs	r0,#0x02                // unprivilaged thread mode bit.
        msr	control,r0              // switch to psp stack, unpriv.

        bl      _bss_init               // Data segment initialization.
        bl      _fpu_init               // Enable FPU instructions
        bl      _core_clock_init        // Initialize the core clock
        bl      _cpp_init               // Call C++ constructors
        bl      _systick_init           // Initialize the systick timer
        bl      board_init              // Initialize the board

start:
		movs	r0, #0          // main() arguments
		movs 	r1, #0
		mov 	r12, sp         // main stack frame
		bl      main            // call program entry main()
		bl      _cpp_deinit     // Call destructors
        b       start                   // loop forever.

.size   Reset_Handler, .-Reset_Handler

/**
 * @brief  This is the code that gets called when the processor receives an
 *         unexpected interrupt.  This simply enters an infinite loop, preserving
 *         the system state for examination by a debugger.
 *
 * @param  None
 * @retval : None
*/
    .section    .text.Default_Handler,"ax",%progbits
Default_Handler:
Infinite_Loop:
        b               Infinite_Loop
    .size   Default_Handler, .-Default_Handler

exit:
_exit:
_halt:
BusFault_IRQ_Handler:
UsageFault_IRQ_Handler:
        b 		exit

default_interrupt_handler:
        b               default_interrupt_handler

        .end
