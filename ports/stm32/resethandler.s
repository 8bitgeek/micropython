/*
 * This file is part of the MicroPython project, http://micropython.org/
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2018 Damien P. George
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

	.if 1

    .syntax unified
    .cpu cortex-m4
    .thumb

    .section .text.Reset_Handler
    .global Reset_Handler
    .type Reset_Handler, %function

Reset_Handler:
    /* Save the first argument to pass through to stm32_main */
    mov  r4, r0

    /* Load the stack pointer */
    ldr  sp, =_estack

    /* Initialise the data section */
    ldr  r1, =_sidata
    ldr  r2, =_sdata
    ldr  r3, =_edata
    b    .data_copy_entry
.data_copy_loop:
    ldr  r0, [r1], #4 /* Should be 4-aligned to be as fast as possible */
    str  r0, [r2], #4
.data_copy_entry:
    cmp  r2, r3
    bcc  .data_copy_loop

    /* Zero out the BSS section */
    movs r0, #0
    ldr  r1, =_sbss
    ldr  r2, =_ebss
    b    .bss_zero_entry
.bss_zero_loop:
    str  r0, [r1], #4 /* Should be 4-aligned to be as fast as possible */
.bss_zero_entry:
    cmp  r1, r2
    bcc  .bss_zero_loop

    /* Initialise the system and jump to the main code */
    bl   SystemInit
    mov  r0, r4
    b    stm32_main

    .size Reset_Handler, .-Reset_Handler

	.else

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
        .cpu cortex-m7
        .fpu softvfp
        @ .fpu fpv4-sp-d16
        .thumb
		.section .init, "ax"

		.global _fpu_init		// initialize the FPU
		.global _bss_init
		.global _cpp_init		
		.global _cpp_deinit		
		.global _core_clock_init
		.global _systick_init
		.global board_init
		.global stm32_main

        .global __main_stack_end__
        .global	_estack

		.global UsageFault_IRQ_Handler
		.global BusFault_IRQ_Handler
		.global _hard_fault
		.global default_interrupt_handler
		.global Reset_Handler
		.type	Reset_Handler, %function
		.code   16
        .align 	2
		.thumb_func
Reset_Handler:
		cpsid	i					// disable interrupts

		ldr r0, =__main_stack_end__
		mov sp, r0

		ldr		r0,=_estack
		msr		psp,r0
		movs	r0,#0x02			// PSP stack, unprivilaged can run in thread mode.
		msr		control,r0
		isb

		// Data initialization.
		ldr		r2, =_bss_init
		blx		r2

		// FPU init
		ldr		r2, =_fpu_init
		blx		r2

		// Call constructors
		ldr		r2, =_cpp_init
		blx		r2

		// Initialize the core clock
		ldr		r2, =_core_clock_init
		blx		r2

		// Initialize the systick timer
		ldr		r2, =_systick_init
		blx		r2

		// Initialize the board
		ldr		r2, =board_init
		blx		r2

start:
		// Jump to main
		movs	r0, #0
		movs 	r1, #0
		mov 	lr, r0
		mov 	r12, sp
		ldr 	r2, =stm32_main
		blx 	r2

		// Call destructors
		ldr		r2, =_cpp_deinit
		blx		r2

		// loop forever.
exit:
_exit:
_halt:
_hard_fault:
default_interrupt_handler:
BusFault_IRQ_Handler:
UsageFault_IRQ_Handler:
		b 		exit

		.end


		.endif

