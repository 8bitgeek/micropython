#!/bin/bash

BOARD=OPEN7XXI_C
OPENOCD_DIR=boards/$BOARD/openocd
OPENOCDCONFIG=$OPENOCD_DIR/openocd-$JTAG.cfg

if [ "$1" == "start" ]; then

    openocd -f $OPENOCDCONFIG 2> /dev/null > /dev/null &

elif [ "$1" == "stop" ]; then

    killall openocd

elif [ "$1" == "debug" ]; then

    make -j6 BOARD=$BOARD OPENOCD_CONFIG=$OPENOCDCONFIG DEBUG=1 V=1 USER_C_MODULES=../../lib/MicroAMP/micropython_modules $1 $2 $3
    arm-none-eabi-gdb -tui -x boards/OPEN7XXI_C/gdbinit

elif [ "$1" == "flash" ]; then

    make -j6 BOARD=$BOARD OPENOCD_CONFIG=$OPENOCDCONFIG DEBUG=1 V=1 USER_C_MODULES=../../lib/MicroAMP/micropython_modules $1 $2 $3
    arm-none-eabi-gdb -x boards/OPEN7XXI_C/gdbinit-flash

elif [ "$1" == "clean" ]; then

    rm -rf build-$BOARD

else

    make -j6 BOARD=$BOARD OPENOCD_CONFIG=$OPENOCDCONFIG DEBUG=1 V=1 USER_C_MODULES=../../lib/MicroAMP/micropython_modules $1 $2 $3

fi

exit 0