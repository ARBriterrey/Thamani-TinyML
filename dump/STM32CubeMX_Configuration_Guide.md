# STM32CubeMX Configuration Guide

Since we are using **STM32CubeMX / STM32CubeIDE** for the STM32 Nucleo F401RE development, you will first need to generate the hardware initialization code (`main.c`, HAL drivers, linker scripts).

Please open STM32CubeMX (or STM32CubeIDE) and create a **New Project**. 
When prompted for the Board Selector, search for and select your exact board: **NUCLEO-F401RE**.
*Tip: Initialize all peripherals with their default state for the Nucleo board when prompted.*

## Required Peripheral Configurations

Based on our `STM32_Execution_Roadmap.md` and Phase 1-3 tasks, here are the exact features you need to enable in the Pinout & Configuration tab:

### 1. 500Hz Signal Acquisition (Phase 1)
To generate the 3 dummy signals at 500 samples per second, we need a precise hardware timer to trigger an interrupt, and an ADC to read the analog simulated cuff pressure.
- **Timer (TIM2 or TIM3):**
  - Enable **TIM2** -> Mode: `Internal Clock`.
  - In Configuration -> Parameter Settings: Set the Prescaler and Counter Period to trigger exactly at 500 Hz (e.g., if clock is 84MHz, Prescaler = `83`, Period = `199999` to get a 500Hz update event).
  - Enable the **TIM2 global interrupt** in the NVIC Settings. We will write our signal generation code inside this interrupt handler (`HAL_TIM_PeriodElapsedCallback`).
- **ADC (Analog to Digital Converter):**
  - Enable **ADC1**.
  - Select an input channel (e.g., `IN0` on pin `PA0`). This will read our "Simulated Cuff Pressure".

### 2. File Storage and Display (Phase 2)
To store files using LittleFS and communicate with the local display, we require an SPI interface (F401RE does not have QSPI hardware, so standard SPI will be used for both an SD card module/flash storage and the display if it's an SPI display).
- **SPI (SPI1 or SPI2):**
  - Enable **SPI1** -> Mode: `Full-Duplex Master` or `Transmit Only Master` (depending on the display/flash memory needs).
  - Hardware NSS Signal: `Disable` (It's usually easier to manually toggle the CS pin using standard GPIO).
- **GPIO (Chip Select / CS Pins):**
  - Click on 2 available GPIO pins in the Pinout View (e.g., `PB6` and `PB7`) and set them to **GPIO_Output**. 
  - One will be used as `CS_FLASH` (for storage), and the other as `CS_DISPLAY` (for the display).

### 3. ESP32-S3 UART Communication (Phase 3)
The Nucleo F401RE already has **USART2** configured by default to communicate through the ST-LINK USB (providing the Virtual COM Port to your PC for `printf` debugging). Therefore, we need a **separate** UART port to talk to the ESP32.
- **UART (USART1 or USART6):**
  - Enable **USART1** or **USART6** -> Mode: `Asynchronous`.
  - In Configuration -> Parameter Settings: Set Baud Rate to `115200` Bits/s.
  - In NVIC Settings: Enable the **USART global interrupt** (we will use interrupt-based reading to catch incoming data from the ESP32 without blocking the main loop).
  - Remember which pins are assigned to TX and RX (e.g., `PA11`/`PA12` for USART1 or `PC6`/`PC7` for USART6). You will physically wire these to the ESP32.

---

## Final Steps before Generating Code
1. Go to the **Clock Configuration** tab window. Allow STM32CubeMX to automatically resolve the clock issues to hit the maximum 84 MHz System Clock frequency.
2. Go to the **Project Manager** tab.
3. **Project Name**: `Thamani-STM32`
4. **Project Location**: Set the folder to `/Users/andhan/Desktop/Sami/Thamani/Thamani-TinyML/firmware/stm32-nucleo`.
5. **Toolchain/IDE**: Select `STM32CubeIDE` or `Makefile` (if you prefer building via terminal/VS Code).
6. Click **Generate Code**.

Once the code is generated, let me know! I will immediately start writing the C code in your newly generated `main.c` file to implement the **Phase 1: 500Hz Signal Acquisition and Dummy Data generation**.
