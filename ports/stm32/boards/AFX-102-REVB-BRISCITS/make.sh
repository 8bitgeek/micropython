#!/bin/bash

if [ "$1" == "start" ]; then

    openocd -f interface/stlink-v2.cfg -f target/stm32f7x.cfg 2> /dev/null > /dev/null &

elif [ "$1" == "stop" ]; then

    killall openocd

elif [ "$1" == "debug" ]; then

    arm-none-eabi-gdb -tui -x boards/AFX-102-REVB-BRISCITS/gdbinit

elif [ "$1" == "flash" ]; then

    make BOARD=AFX-102-REVB-BRISCITS OPENOCD_CONFIG=boards/openocd_stm32f7.cfg  deploy-openocd

else

    #make -j4 BOARD=AFX-102-REVB-BRISCITS OPENOCD_CONFIG=boards/openocd_stm32f7.cfg  deploy-openocd
    #make -j4 BOARD=AFX-102-REVB-BRISCITS OPENOCD_CONFIG=boards/openocd_stm32f7.cfg  $1 $2 $3
    rm -f build-AFX-102-REVB-BRISCITS/../../../briscits/src/brisc_*
    rm -f build-AFX-102-REVB-BRISCITS/../../../briscits//lib/brisc_delay.o
    rm -f build-AFX-102-REVB-BRISCITS/../../../briscits//cpu/arm/cortex-m7/cpu.o
    rm -f build-AFX-102-REVB-BRISCITS/../../../briscits//chip/stm32/bss_init.o
    rm -f build-AFX-102-REVB-BRISCITS/../../../briscits//chip/stm32/cpp_init.o
    rm -f build-AFX-102-REVB-BRISCITS/../../../briscits//chip/stm32/f7/systick_init.o
    rm -f build-AFX-102-REVB-BRISCITS/../../../briscits//chip/stm32/f7/core_clock.o
    make -j4 BOARD=AFX-102-REVB-BRISCITS OPENOCD_CONFIG=boards/openocd_stm32f7.cfg DEBUG=1 V=1 USER_C_MODULES=../../../MicroAMP/micropython_modules $1 $2 $3

fi

exit 0