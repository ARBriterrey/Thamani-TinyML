# STM32 Migration & Execution Roadmap

Author: Andhan Rahul Buddhan Date: 2026-02-27

------------------------------------------------------------------------

## System Context

Current Architecture:

CMC DAC → PIC → UART → ESP32 → WiFi → Cloud

Data Size: - CDQ File: 1.7 MB - USB Buffer: 64 bytes

------------------------------------------------------------------------

# Phase 0 -- Architecture Alignment (Week 1)

## Objectives

-   Fully understand current data pipeline
-   Identify bottlenecks and constraints

## Tasks

-   Document complete data flow
-   Measure transmission frequency
-   Analyze memory usage on PIC
-   Identify UART buffer handling logic

## Deliverables

-   System architecture document (2--3 pages)
-   Bottleneck analysis report

------------------------------------------------------------------------

# Phase 1 -- STM32 Feasibility Study (Week 2)

## Objectives

Evaluate STM32 as PIC replacement.

## Candidate Families

-   STM32F4
-   STM32H7

## Comparison Parameters

-   Flash memory
-   SRAM
-   Clock speed
-   FPU presence
-   DSP capability
-   Peripheral support (UART, SPI, ADC, DMA)

## Deliverables

-   PIC vs STM32 comparison document
-   Selected STM32 family decision

------------------------------------------------------------------------

# Phase 2 -- Firmware Prototype (Week 3)

## Objectives

Replicate PIC functionality on STM32.

## Tasks

-   Setup STM32CubeIDE
-   Configure HAL drivers
-   Implement UART communication
-   Add interrupt-driven transfer
-   Simulate 1.7MB data transfer
-   Measure throughput
-   Implement checksum validation

## Deliverables

-   UART working prototype
-   Throughput benchmark report

------------------------------------------------------------------------

# Phase 3 -- Storage Strategy (Week 4)

## Options

1.  Internal Flash
2.  External Flash
3.  SD Card
4.  ESP32 Storage

## Tasks

-   Estimate binary size requirements
-   Implement chunked writing (4KB buffer)
-   Evaluate write endurance
-   Stress test reliability

## Deliverables

-   Storage strategy decision document

------------------------------------------------------------------------

# Phase 4 -- ML Feasibility (Week 5--6)

## Objectives

Evaluate on-device ML capability.

## Tasks

-   Export small MLP model
-   Quantize to int8
-   Integrate via TensorFlow Lite Micro / STM32Cube.AI
-   Measure:
    -   RAM usage
    -   Flash usage
    -   Inference latency

## Deliverables

-   Working on-device inference demo
-   Resource profiling report

------------------------------------------------------------------------

# Long-Term Goal

Migration from legacy microcontroller architecture to ML-capable
embedded system with cloud fallback architecture.
