# STM32 Implementation Plan & Execution Roadmap

**Target Hardware:**
- **Microcontroller**: STM32 Nucleo F401RE
- **WiFi Module**: ESP32-S3-WROOM-1-N16R8

---

## Immediate Objective
Formulate a decision on the final production STM32 specifications based on system performance during file storage, display handling, and data transmission tasks.

---

## Phase 1: Signal Generation & Acquisition
**Goal:** Simulate realistic medical sensor inputs ensuring accurate data collection at required sampling rates.
- **Task 1.1:** Generate 3 dummy signals at 500 Hz (500 samples/sec).
  - **Signal 1:** Analog signal simulating cuff pressure.
  - **Signals 2 & 3:** Digitized outputs simulating two separate PPG channels.
- **Task 1.2:** Configure STM32 Nucleo F401RE peripherals (ADC for analog, relevant digital interfaces for PPG) to receive these signals accurately at 500Hz.

---

## Phase 2: Local Display & External Storage (LittleFS)
**Goal:** Ensure data can be visualized locally in real-time and safely logged to memory without data loss or corruption.
- **Task 2.1 (Display):** Transmit acquired signal data to a local display via the suitable communication protocol (I2C/SPI depending on display choice).
- **Task 2.2 (Storage Setup):** Interface STM32 with external storage (Flash/SD) via SPI or QSPI.
- **Task 2.3 (File System):** Implement **LittleFS** (Little File System) to manage files on the external storage. 
- **Task 2.4 (Data Integrity):** Continuously write incoming dummy data to files while actively checking for file corruption issues or write bottlenecks.

---

## Phase 3: Cloud Communication via ESP32-S3
**Goal:** Establish a robust two-way pipeline to upload recorded files and retrieve processed risk results from the cloud infrastructure.
- **Task 3.1:** Read the stored data files from the external storage using the STM32.
- **Task 3.2 (STM-ESP Link):** Transmit this data from the STM32 to the ESP32-S3-WROOM-1-N16R8 module via **UART**.
- **Task 3.3 (Cloud Upload):** The ESP32-S3 handles the network stack to send the data payload to the Cloud / Main Orchestrator.
- **Task 3.4 (Cloud Download):** The ESP32-S3 receives the processing results (e.g., risk score) from the Cloud and forwards them back to the STM32 over UART.
- **Task 3.5 (Result Visualization):** The STM32 parses the received result and updates the local display.

---

## Phase 4: System Evaluation & Final Spec Decision
**Goal:** Use empirical data gathered from the prototype to define the required specs for the final custom PCB MCU.
- **Task 4.1 (Memory Assessment):** Address the open question: *Should we store some results in memory?* Evaluate RAM vs. Flash usage for caching results.
- **Task 4.2 (Profiling):** Measure CPU load, buffer utilization (especially during 500Hz ADC + QSPI writes + UART TX), and power consumption.
- **Task 4.3 (MCU Decision):** Based on the profiling of file storage and display tasks, officially decide the final STM32 family and required specs (Flash, SRAM, Clock speed, FPU needs) for the production device.

---

## Long-Term Goal (Phase 5)
Transition from this STM32 + ESP32 (Cloud-Reliant) prototype to a fully localized TinyML edge-computing model where the STM32 handles the ML risk-scoring natively, only using the ESP32 to sync final historical records to the server.
