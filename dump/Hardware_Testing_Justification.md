# Hardware Testing Justification: ESP32 and STM32 Modules

## Introduction
This document outlines the necessity, testing methodologies, and stress-testing capabilities for the ESP32 and STM32 microcontroller modules purchased for the Thamani-TinyML project. The project follows a two-phase implementation approach for medical data processing, transitioning from a cloud-reliant orchestrator model to a fully localized edge-computing (TinyML) model.

## 1. Justification for Hardware Procurement

### Phase 1: ESP32 as a Connectivity Bridge
In the first phase, our architecture requires transmitting raw sensor data from the medical chip (which records and stores patient data) to the main containerized server for processing via an ephemeral MATLAB worker.
*   **Why ESP32?**: The medical chip itself often lacks robust, secure, and configurable networking capabilities required to transmit high-frequency sensor data payloads over Wi-Fi or Bluetooth.
*   **Role**: The ESP32 acts as the crucial IoT gateway. It interfaces with the medical chip via standard protocols (Serial/I2C/SPI), buffers the incoming raw data, and manages the network stack to reliably `POST` this data to the `main-orchestrator` container's REST API (`/api/process`).
*   **Necessity for Testing**: We must physically test the ESP32 to validate data transmission rates, connection stability, payload integrity, and power consumption during continuous Wi-Fi transmission.

### Phase 2: STM32 for Localized TinyML Processing
Phase 2 shifts the computational burden from the cloud/server back to the edge to achieve real-time, localized processing without relying on constant network availability.
*   **Why STM32?**: STM32 microcontrollers possess the computational throughput, hardware floating-point units (FPU), and memory capacity needed to run compiled MATLAB algorithms (via MATLAB Coder) or TinyML models directly on the device.
*   **Role**: The STM32 will execute the medical risk-scoring ML model locally. It will process the raw sensor data in real-time, generate the risk score, and then periodically share these processed records (a much smaller data payload) via the ESP32 to the main server for long-term storage and clinician review.
*   **Necessity for Testing**: Translating server-grade MATLAB code to an embedded C environment requires rigorous testing of execution time, memory utilization (RAM/Flash), floating-point accuracy, and thermal performance under load.

---

## 2. Planned Testing Methodologies

The physical testing phase is critical to ensure the reliability and safety of the medical data processing pipeline. We will perform the following categories of tests on both modules:

### A. Connectivity and Pipeline Integration Testing (Focus: ESP32)
*   **End-to-End Latency Tests**: Measuring the delay from the moment the medical chip generates data, through the ESP32, over the network, to the main orchestrator, and back.
*   **Network Resilience Tests**: Simulating dropped Wi-Fi connections, high latency, and network jitter to ensure the ESP32 correctly caches data and retransmits without loss upon reconnection.
*   **Protocol Verification**: Validating the REST/HTTP structures, ensuring headers, JSON payload formatting, and security (e.g., TLS encryption) meet the backend's expectations.

### B. Computational and Model Verification Testing (Focus: STM32)
*   **Algorithm Equivalence Testing**: Feeding identical raw sensor datasets to the server-based MATLAB container (Phase 1) and the STM32 model (Phase 2) to ensure the outputs match within an acceptable floating-point tolerance margin.
*   **Real-Time Processing Profiling**: Measuring the exact microsecond execution time of the risk-score algorithm on the STM32 to guarantee it meets the real-time constraints of high-frequency incoming medical data.
*   **Memory Profiling**: Monitoring stack and heap usage dynamically to ensure the STM32 does not encounter memory leaks or stack overflows during continuous operation.

### C. System-Level Integration Testing (Combined)
*   **Inter-IC Communication**: Testing the I2C/SPI/UART bus stability and signal integrity between the medical chip, the STM32, and the ESP32.
*   **Power Sequencing**: Ensuring that all modules boot up correctly, initialize in the right order, and establish handshakes flawlessly.

---

## 3. Stress Testing Capabilities and Protocols

To guarantee system stability in a medical context, we must push the hardware beyond its designed operational limits. Using the acquired physical hardware allows us to perform extensive stress and boundary testing:

### Data Flood and Throughput Stress (ESP32)
*   **High-Frequency Polling**: We will force the medical chip emulator to output data at 5x to 10x the normal sampling rate.
*   **Buffer Overflow Testing**: We will evaluate how the ESP32 handles network outages while data continuously floods its internal RAM, testing our buffer management and data-dropping fail-safes.
*   **Expected Outcome**: Identify the maximum sustained payload frequency the ESP32 can transmit before thermal throttling, watchdog resets, or packet loss occurs.

### Computational Stress and Edge Cases (STM32)
*   **Continuous Maximum Load**: The STM32 will be fed artificial, highly volatile sensor data without pauses to keep the CPU utilization at 100% for extended durations (e.g., 48-72 hours).
*   **Mathematical Edge Cases**: We will inject `NaN` (Not a Number), infinite values, and extreme out-of-bounds sensor readings into the STM32 to test the resilience of the generated TinyML/C code against math faults or divisions by zero.
*   **Expected Outcome**: Validation of the C code's exception handling and the MCU’s thermal and computational stability under chaotic input conditions.

### Power and Environmental Stress (Combined)
*   **Voltage Sag (Brownout) Testing**: Gradually lowering the supply voltage to trigger the ESP32 and STM32 Brownout Detectors (BOD). We will test if the system can cleanly halt operations and prevent data corruption.
*   **Long-Term Soak Testing**: Operating the integrated system under simulated normal conditions for highly extended periods to expose slow memory leaks or timing drifts that do not appear in short performance tests.

---
## Conclusion
The procurement of the ESP32 and STM32 modules is a mandatory step for transitioning the Thamani-TinyML project from a containerized, server-reliant prototype to a robust, decentralized edge-computing platform. By conducting the outlined connectivity, computational, and extreme stress tests, we can guarantee that the final medical device is reliable, accurate, and capable of operating continuously in real-world scenarios.
