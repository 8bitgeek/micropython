/****************************************************************************
GNU linker script for STM32F746

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
****************************************************************************/

/***************************************************************************/
/* Stack Size For ARM Interrupt Context                                    */
/***************************************************************************/
__main_stack_size__         = 8K;

MEMORY
{
    FLASH (rx)      : ORIGIN = 0x08000000, LENGTH = 512K

                    /* sector 0, 32K */
    FLASH_ISR (rx)  : ORIGIN = 0x08000000, LENGTH = 32K 

                    /* sectors 1 (32K each) */    
    FLASH_FS (r)    : ORIGIN = 0x08008000, LENGTH = 32K     

                    /* sectors 2-5 2*32Kib 1*128Kib 1*256KiB = 448K */
    FLASH_TEXT (rx) : ORIGIN = 0x08020000, LENGTH = 448K    

                    /* MicroAMP Shared Memory @ DTCM */
    UAMP (rw)       : ORIGIN = 0x20000000, LENGTH = 32K     

                    /* Free DTCM Memory */
    DTCM (rwx)      : ORIGIN = 0x20008000, LENGTH = 32K     

                    /* SRAM1 = 240K, SRAM2 = 16K */
    RAM (xrw)       : ORIGIN = 0x20010000, LENGTH = 256K    
}

/***************************************************************************/
/* produce a link error if there is not this amount of RAM for these       */
/* sections                                                                */
/***************************************************************************/
_minimum_stack_size = 2K;
_minimum_heap_size = 16K;

/***************************************************************************/
/* MICROAMP: Calculate __microamp_shared_ram__                             */
/***************************************************************************/
__microamp_page_size__      = 1K;
__microamp_shared_ram__     = ORIGIN(UAMP);
__microamp_shared_size__    = (ORIGIN(UAMP) + LENGTH(UAMP)) - 
                                __microamp_shared_ram__;
__microamp_pages__          = __microamp_shared_size__ /
                                 __microamp_page_size__;

/***************************************************************************/
/* RAM extents for the garbage collector                                   */
/***************************************************************************/
_ram_start = ORIGIN(RAM);
_ram_end = ORIGIN(RAM) + LENGTH(RAM);
_heap_start = _ebss; /* heap starts just after statically allocated memory */
_heap_end = _sstack;

/***************************************************************************/
/* Define the stack.  The stack is full descending so begins just above    */
/* last byte of RAM. Note that EABI requires the stack to be 8-byte        */
/* aligned for a call. BRISCITS: Reserve __main_stack_size__ for ISR stack */   
/***************************************************************************/
_estack = _ram_end - ( __microamp_shared_size__ + 
                        __main_stack_size__ + _estack_reserve );
_sstack = _estack - 24K; /* tunable */

/***************************************************************************/
/* BRISCITS: Calculate __main_stack base and end                           */
/***************************************************************************/
__main_stack_end__ = _ram_end - _estack_reserve;
__main_stack_base__ = __main_stack_end__ - __main_stack_size__;

/* Memory layout for internal flash storage configuration:

    FLASH_ISR   .vectors

    FLASH_TEXT  .text
    FLASH_TEXT  .data

    RAM         .data
    RAM         .bss
    RAM         .heap
    RAM         .stack
*/

ENTRY(briscits_reset_handler)

/***************************************************************************/
/* define output sections                                                  */
/***************************************************************************/
SECTIONS
{
    /* The startup code goes first into FLASH */
    .vectors :
    {
        . = ALIGN(4);
        KEEP(*(.vectors)) /* Startup code */

        /* This first flash block is 16K annd the isr vectors only take up
           about 400 bytes. So we pull in a couple of object files to pad it
           out. */

        . = ALIGN(4);

        /* NOTE: If you update the list of files contained in .vectors,
                 then be sure to also update smhal/Makefile where it forcibly
           builds each of these files with -Os */

        */ff.o(.text*)
        */vfs_fat_*.o(.text*)
        */py/formatfloat.o(.text*)
        */py/parsenum.o(.text*)
        */py/mpprint.o(.text*)

        . = ALIGN(4);
    } >FLASH_ISR

    /* C++ Constructors */
    constructors : ALIGN(4) SUBALIGN(4)
    {
        PROVIDE(__init_array_start = .);
        KEEP(*(SORT(.init_array.*)))
        KEEP(*(.init_array))
        PROVIDE(__init_array_end = .);
    } > FLASH_TEXT

    /* C++ Destructors */
    destructors : ALIGN(4) SUBALIGN(4)
    {
        PROVIDE(__fini_array_start = .);
        KEEP(*(.fini_array))
        KEEP(*(SORT(.fini_array.*)))
        PROVIDE(__fini_array_end = .);
    } > FLASH_TEXT

    /* The program code and other data goes into FLASH */
    .text :
    {
        . = ALIGN(4);
        *(.text*)          /* .text* sections (code) */
        *(.rodata*)        /* .rodata* sections (constants, strings, etc.) */
    /*  *(.glue_7)   */    /* glue arm to thumb code */
    /*  *(.glue_7t)  */    /* glue thumb to arm code */

        . = ALIGN(4);
        _etext = .;        /* define a global symbol at end of code */
    } >FLASH_TEXT

    /* BRISCITS For C++ exception handling */
    .ARM :
    {
        __exidx_start = .;
        *(.ARM.exidx*)
        __exidx_end = .;
    } >FLASH_TEXT

    /* Used by the start-up code to initialise data */
    _sidata = LOADADDR(.data);

    /* Initialised data section, start-up code will copy it from flash to RAM */
    .data :
    {
        . = ALIGN(4);
        _sdata = .;
        *(.data*)
        . = ALIGN(4);
        _edata = .;
    } >RAM AT> FLASH_TEXT

    /* Zeroed-out data section */
    .bss :
    {
        . = ALIGN(4);
        _sbss = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } >RAM

    /* This is to define the start of the heap, and make sure there is a minimum size */
    .heap :
    {
        . = ALIGN(4);
        . = . + _minimum_heap_size;
        . = ALIGN(4);
    } >RAM

    /* This checks there is enough RAM for the stack */
    .stack :
    {
        . = ALIGN(4);
        . = . + _minimum_stack_size;
        . = ALIGN(4);
    } >RAM

}