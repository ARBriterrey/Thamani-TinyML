##############################################################################
# Thamani-TinyML — STM32 Nucleo-F401RE
# Makefile for command-line build using CubeIDE's bundled arm-none-eabi-gcc
##############################################################################

# ── Toolchain (bundled with STM32CubeIDE 2.1.1) ──────────────────────────────
GCC_PATH := C:/ST/STM32CubeIDE_2.1.1/STM32CubeIDE/plugins/com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.14.3.rel1.win32_1.0.100.202602081740/tools/bin
CC       := $(GCC_PATH)/arm-none-eabi-gcc
AS       := $(GCC_PATH)/arm-none-eabi-gcc -x assembler-with-cpp
CP       := $(GCC_PATH)/arm-none-eabi-objcopy
SZ       := $(GCC_PATH)/arm-none-eabi-size

# ── Output ────────────────────────────────────────────────────────────────────
BUILD_DIR := Debug
TARGET    := $(BUILD_DIR)/Demo

# ── Drivers paths ─────────────────────────────────────────────────────────────
HAL_PATH   := Drivers/stm32f4xx-hal-driver-master
CMSIS_PATH := Drivers/CMSIS
CMSIS_DEV  := Drivers/cmsis-device-f4-master

# ── Sources ───────────────────────────────────────────────────────────────────
C_SOURCES := \
  Src/main.c \
  Src/syscalls.c \
  Src/sysmem.c \
  $(HAL_PATH)/Src/stm32f4xx_hal.c \
  $(HAL_PATH)/Src/stm32f4xx_hal_cortex.c \
  $(HAL_PATH)/Src/stm32f4xx_hal_dma.c \
  $(HAL_PATH)/Src/stm32f4xx_hal_dma_ex.c \
  $(HAL_PATH)/Src/stm32f4xx_hal_flash.c \
  $(HAL_PATH)/Src/stm32f4xx_hal_flash_ex.c \
  $(HAL_PATH)/Src/stm32f4xx_hal_flash_ramfunc.c \
  $(HAL_PATH)/Src/stm32f4xx_hal_gpio.c \
  $(HAL_PATH)/Src/stm32f4xx_hal_pwr.c \
  $(HAL_PATH)/Src/stm32f4xx_hal_pwr_ex.c \
  $(HAL_PATH)/Src/stm32f4xx_hal_rcc.c \
  $(HAL_PATH)/Src/stm32f4xx_hal_rcc_ex.c \
  $(HAL_PATH)/Src/stm32f4xx_hal_uart.c \
  $(CMSIS_DEV)/Source/Templates/system_stm32f4xx.c

ASM_SOURCES := \
  $(CMSIS_DEV)/Source/Templates/gcc/startup_stm32f401xe.s

# ── Include paths ─────────────────────────────────────────────────────────────
C_INCLUDES := \
  -IInc \
  -I$(HAL_PATH)/Inc \
  -I$(HAL_PATH)/Inc/Legacy \
  -I$(CMSIS_PATH)/Include \
  -I$(CMSIS_DEV)/Include

# ── Defines ───────────────────────────────────────────────────────────────────
C_DEFS := \
  -DUSE_HAL_DRIVER \
  -DSTM32F401xE \
  -DDEBUG

# ── CPU / FPU flags ───────────────────────────────────────────────────────────
CPU    := -mcpu=cortex-m4
FPU    := -mfpu=fpv4-sp-d16
FLOAT  := -mfloat-abi=hard
MCU    := $(CPU) -mthumb $(FPU) $(FLOAT)

# ── Compiler flags ────────────────────────────────────────────────────────────
CFLAGS := $(MCU) $(C_DEFS) $(C_INCLUDES) -std=gnu11 -g3 -O0 \
           -ffunction-sections -fdata-sections -Wall --specs=nano.specs

ASFLAGS := $(MCU) -g3

# ── Linker flags ──────────────────────────────────────────────────────────────
LDSCRIPT := STM32F401RETX_FLASH.ld
LDFLAGS  := $(MCU) -specs=nano.specs -T$(LDSCRIPT) \
             -Wl,-Map=$(TARGET).map,--cref -Wl,--gc-sections

# ── Build rules ───────────────────────────────────────────────────────────────
OBJECTS := $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))

vpath %.c $(sort $(dir $(C_SOURCES)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

all: $(BUILD_DIR) $(TARGET).elf $(TARGET).bin
	@$(SZ) $(TARGET).elf

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR)
	@echo "CC $<"
	$(CC) -c $(CFLAGS) -MMD -MP -MF"$(BUILD_DIR)/$*.d" -o $@ $<

$(BUILD_DIR)/%.o: %.s Makefile | $(BUILD_DIR)
	@echo "AS $<"
	$(AS) -c $(ASFLAGS) -o $@ $<

$(TARGET).elf: $(OBJECTS) Makefile
	@echo "LD $@"
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@

$(TARGET).bin: $(TARGET).elf
	$(CP) -O binary $< $@

clean:
	rm -rf $(BUILD_DIR)

-include $(wildcard $(BUILD_DIR)/*.d)

.PHONY: all clean
