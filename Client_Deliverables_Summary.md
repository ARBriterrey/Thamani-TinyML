# Thamani-TinyML Project: Client Deliverables Summary

**Last Updated:** April 22, 2026

## 1. Executive Summary

This document outlines the core technical deliverables and architectural transformations achieved during our engagement on the Thamani-TinyML project. At the onset of the project, the system relied on a tethered, double-board prototype that required a USB connection to an external laptop to execute algorithms and retrieve sensor readings.

Our team has fundamentally modernized this approach, delivering a robust, automated cloud processing pipeline and providing expert consultation to transition the hardware to a compact, wireless, edge-computing model suitable for production.

---

## 2. Deliverable 1: Cloud-Based "Hub and Spoke" Processing Pipeline

We have successfully designed and built a highly scalable, containerized backend processing system to replace the local laptop dependency. This allows the medical device to operate remotely and asynchronously communicate data for analysis.

### System Components Delivered:
*   **Docker Compose Orchestration:** A fully automated multi-container deployment environment (`docker-compose.yml`), enabling effortless installation, scaling, and lifecycle management of the cloud services.
*   **Main Orchestrator Service (The "Hub"):**
    *   Developed a reliable, always-on Python/Flask API gateway.
    *   Handles incoming raw sensor data submissions (`POST /api/process`) from the medical devices in the field.
    *   Manages shared data storage volumes and container orchestration.
*   **Ephemeral processing Workers (The "Spokes"):**
    *   Implemented an on-demand container execution model via the Docker SDK.
    *   When the orchestrator receives data, it dynamically spins up isolated, short-lived worker containers to execute the complex mathematical modeling (e.g., MATLAB risk calculations).
    *   Workers process the raw data, output the risk score, and immediately spin down, ensuring highly efficient resource utilization.
*   **Inter-Container Data Exchange:** Built a secure, volume-based data exchange mechanism ensuring the seamless flow of raw input data and processed risk score outputs between the orchestrator and the worker nodes.
*   **Secure Infrastructure (mTLS & HTTPS):** Deployed an Nginx reverse proxy on the GCP server to enforce Mutual TLS (mTLS) client certificate authentication. Edge devices securely connect via a custom subdomain (`edge.thamanihc.com`) using embedded X.509 certificates to ensure data privacy and authenticity.

---

## 3. Deliverable 2: Hardware Architecture Consulting & Upgrades

To move the physical medical device away from the bulky USB-tethered setup, we provided extensive engineering consultation to redefine the hardware stack.

### Outcomes & Upgrades:
*   **Decoupling the Hardware:** Advised the transition away from the legacy double-board configuration to a modular MCU framework.
*   **Introduction of the STM32 Microcontroller:** Selected the STM32 (Nucleo F401RE class) as the core computational unit. The STM32 was identified as the ideal chip to sit atop the medical device to handle high-frequency (500Hz) analog signal acquisition (e.g., cuff pressure, PPG sensors) and real-time local processing.
*   **Introduction of the ESP32-S3 Network Bridge:** Recommended the ESP32-S3 module specifically for managing the secure Wi-Fi networking stack, establishing the critical wireless link between the medical device and our new Docker server.

---

## 4. Deliverable 3: Firmware & Edge Development (In Parallel)

Working in parallel with the cloud deployment, we are actively developing the firmware logic for the new STM32 hardware layer to ensure it perfectly integrates with the Docker server.

### Current Implementation Scope:
*   **High-Frequency Signal Acquisition:** Configuring the STM32 peripherals (ADC) to read dummy medical signals at 500Hz to guarantee collection stability.
*   **Local Storage & File Management:** Integrating LittleFS (Little File System) natively on the STM32 to safely log sensor data to external flash storage without data corruption during network drops.
*   **Cloud Initialization Pipeline:** Established the UART communication logic between the STM32 and the ESP32-S3 bridge. This allows the STM32 to package the saved patient data and trigger the ESP32 to push the payloads over Wi-Fi directly to the Docker Orchestrator.
*   **Robust Binary File Transfer:** Transitioned from simple JSON-based demo telemetry to a structured, end-to-end binary file transmission pipeline. The ESP32 securely handles the secure chunked transfer of large biomedical payload files to the cloud for MATLAB ingestion.
*   **Two-Way Communication:** Implementing the return loop so the STM32 can receive the processed risk scores from the Docker server and output them to a local display.

---

## 5. Strategic Value & Future Roadmap

By delivering the Docker **Hub and Spoke** model and the **STM32/ESP32 hardware blueprint**, we have transitioned the project from a lab-bound prototype to a field-deployable IoT medical device. 

**Next Steps (TinyML Integration):**
The architecture we have established lays the perfect groundwork for Phase 2. As we finalize the physical STM32 integration, our end end goal remains transitioning from this *cloud-reliant* model to a completely *localized TinyML edge-computing model*. Ultimately, the STM32 will execute the ML risk-scoring algorithms directly on the device, eliminating the need for continuous cloud connectivity altogether.

---

## 6. Addendum: April 22, 2026 Architectural Pivot

In order to optimize hardware costs and simplify the supply chain, the architecture was re-evaluated to transition away from the PSRAM-reliant ESP32-S3 module, pivoting instead to a standard **ESP32 DevKit V1**. 

### Firmware & Orchestrator Upgrades Implemented:
*   **Application-Level Chunk API:** Since the standard ESP32 lacks internal SRAM space to buffer entire multi-megabyte biomedical payloads into memory, we introduced a robust chunk-by-chunk HTTP stream architecture.
*   **ESP32 Memory Standardization:** Purged all dynamic external memory (`ps_malloc`) allocations within the ESP32 code in favor of a rigid, 4096-byte chunk buffer that guarantees crash-free transmission.
*   **STM32 Hardware-Level Pacing:** The STM32 now strictly controls file delivery pacing. It wraps 2KB chunks embedded with software CRC32 validation hashes. If the ESP32 detects network droppage, it returns a NACK, and the STM32 automatically initiates a 3x retry policy for the corrupt block.
*   **Flask Orchestrator Endpoints:** Retrofitted the server to support multi-part chunked payload sessions via new `/api/upload/init`, `/api/upload/chunk`, and `/api/upload/finish` endpoints. The server verifies integrity on-the-fly and seamlessly passes the assembled payload to the MATLAB worker just as before.
