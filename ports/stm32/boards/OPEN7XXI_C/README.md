 export JTAG=olimex

--OR--

$ export JTAG=olimex-tiny

--OR--

$ export JTAG=stlink

--THEN--

$ boards/OPEN7XXI_C/make.sh start
$ boards/OPEN7XXI_C/make.sh debug

etc...

If you don't want to debug, and just want to FLASH, then:

$ boards/OPEN7XXI_C/make.sh start
$ boards/OPEN7XXI_C/make.sh flash
$ boards/OPEN7XXI_C/make.sh stop

or so.

