zBOARD_DIR=$(PWD)/boards/$(BOARD)
LIB_DIR=$(PWD)/../../lib
MCU_SERIES = f7
CMSIS_MCU = STM32F746xx
AF_FILE = boards/stm32f746_af.csv
TEXT0_ADDR = 0x08000000
# TEXT1_ADDR = 0x08020000

# Target Linker script and vectors.
LD_FILES =$(BOARD_DIR)/stm32f746xE-BRISCITS-MicroAMP.ld
# STARTUP_FILE = $(BOARD_DIR)/startup_stm32f746xx.o

# MicroPython settings
MICROPY_PY_LWIP = 0
MICROPY_PY_USSL = 0
MICROPY_SSL_MBEDTLS = 0


# BRISCITS Setup
BRISCITS_SRC=$(LIB_DIR)/briscits
STARTUP_FILE = $(BOARD_DIR)/vectors.o	\
				$(BOARD_DIR)/boot.o

MCU_CHIP	 	= stm32f7xx
MCU_CORE     	= cortex-m7
MCU_FLOAT    	= softfp
MCU_FPU 		= fpv4-sp-d16

CFLAGS += -D__BRISCITS__ -D__MICROAMP__ -DHSE_VALUE=8000000
CFLAGS += -DSTM32F746xx
#CFLAGS += -DBRISC_THREAD_MAX=6 -DARM_FVP_LAZY_STACKING 
CFLAGS += -DBRISC_THREAD_MAX=6

# ASFLAGS += -fshort-enums -fsigned-char -mlittle-endian -mthumb -mthumb-interwork -mcpu=$(MCU_CORE) -mfloat-abi=$(MCU_FLOAT) -mfpu=$(MCU_FPU)
# CFLAGS += -fshort-enums -fsigned-char -mlittle-endian -mthumb -mthumb-interwork -mcpu=$(MCU_CORE) -mfloat-abi=$(MCU_FLOAT) -mfpu=$(MCU_FPU)
# LDFLAGS += -fshort-enums -fsigned-char -mlittle-endian -mthumb -mthumb-interwork -mcpu=$(MCU_CORE) -mfloat-abi=$(MCU_FLOAT) -mfpu=$(MCU_FPU)

CFLAGS += -I $(BOARD_DIR)
CFLAGS += -I $(BRISCITS_SRC)/src
CFLAGS += -I $(BRISCITS_SRC)/lib
CFLAGS += -I $(BRISCITS_SRC)/cpu/arm/cortex-m7

SRC_C += $(BOARD_DIR)/brisc_board.c
# SRC_C += $(BOARD_DIR)/examplemodule.c

USERMOD_DIR=$(LIB_DIR)/MicroAMP/micropython_modules

SRC_C += $(BRISCITS_SRC)/src/brisc_sched.c
SRC_C += $(BRISCITS_SRC)/src/brisc_irq.c
SRC_C += $(BRISCITS_SRC)/src/brisc_swi.c
SRC_C += $(BRISCITS_SRC)/src/brisc_thread.c
SRC_C += $(BRISCITS_SRC)/src/brisc_mutex.c
SRC_C += $(BRISCITS_SRC)/lib/brisc_delay.c
SRC_C += $(BRISCITS_SRC)/cpu/arm/cortex-m7/cpu.c
SRC_C += $(BRISCITS_SRC)/chip/stm32/bss_init.c
SRC_C += $(BRISCITS_SRC)/chip/stm32/cpp_init.c
SRC_C += $(BRISCITS_SRC)/chip/stm32/f7/systick_init.c
SRC_C += $(BRISCITS_SRC)/chip/stm32/f7/core_clock.c