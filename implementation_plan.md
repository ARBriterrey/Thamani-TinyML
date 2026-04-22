# STM32 to Cloud Chunked Data Transfer via ESP32

This implementation plan addresses the architectural shift from using an ESP32-S3 (with PSRAM) to a standard ESP32 DevKit V1 (without PSRAM) for bridging STM32 sensor data to the cloud orchestrator. 

Because the basic ESP32 does not have enough native internal SRAM to buffer an entire multi-megabyte binary file, we must transition to a **Chunked Streaming Protocol** with **CRC Data Integrity Checking**.

## User Review Required
> [!WARNING]
> This change fundamentally alters the communication protocol between all 3 layers: the STM32 firmware, the ESP32 firmware, and the Python Orchestrator API. Please review the chunking strategy and let me know if a 2KB to 4KB chunk size fits the expected UART speed and HTTP request overhead. 

## Proposed Changes

### Cloud Backend (Flask Orchestrator)

The current server uses `/api/process` to receive an entire multipart POST payload at once. We will introduce new upload endpoints to allow assembling small chunks over time.

#### [MODIFY] `server-deployment/main-orchestrator/app.py`
Add new endpoints to support chunked file ingestion:
- **`POST /api/upload/init`**:
  - Initializes a file transfer session.
  - Generates a unique `transfer_id`.
  - Creates a temporary empty file in the volume.
  - Returns `transfer_id`.
- **`POST /api/upload/chunk`**:
  - Accepts `transfer_id`, `chunk_index`, `crc32` of the chunk, and the raw binary `data`.
  - Verifies the chunk using CRC32. If correct, appends it to the temporary file. If corrupt, returns a `400` error requesting a retry.
- **`POST /api/upload/finish`**:
  - Accepts `transfer_id` and the `total_crc32` for the full file.
  - Validates the overall file integrity.
  - Triggers the MATLAB asynchronous processing worker logic (similar to how `/api/process` operates today).

---

### ESP32 Network Bridge (PlatformIO / Arduino)

We will modify the ESP32 so that it maintains a small fixed window (e.g., 2048 bytes) to ferry chunks instead of hoarding the entire binary.

#### [MODIFY] `firmware/esp32-s3/platformio.ini` (or equivalent build config)
- Change the environment from `esp32-s3` to a standard ESP32 target (e.g., `esp32dev`).
- Ensure no PSRAM compilation flags are strictly required. (Assume the folder will be renamed or reused as the standard ESP32 code).

#### [MODIFY] `firmware/esp32-s3/src/main.cpp`
- **UART Command Set Update**: 
  - Handle `<INIT>` corresponding to `/api/upload/init`. Wait for `transfer_id`.
  - Handle `<CHUNK:index:size:crc>` followed by raw bytes. 
    - Buffer the chunk into a static internal SRAM array.
    - Perform HTTP POST to `/api/upload/chunk`. Returns `<ACK_CHUNK>` or `<NACK_CHUNK>` via UART back to STM32 based on the HTTP status code.
  - Handle `<FINISH:total_crc>`. Calls `/api/upload/finish` to finalize processing on the server and receive the result, ferried back to STM32.
- Remove all references to `ps_malloc()` and `psramFound()`.

---

### Edge Microcontroller (STM32 Firmware)

The STM32 is the data generator (via LittleFS). It must coordinate the pacing.

#### [MODIFY] `firmware/stm32-nucleo/Core/Src/main.c` (or equivalent file handling code)
- Replace basic burst UART submission with a state-machine that pauses after sending each chunk.
- Add a CRC32 generation library or utilize hardware CRC peripheral.
- **Delivery Flow**:
  1. Calculate file size. Send `<INIT:size>`. Wait for `<ACK_INIT>`.
  2. Open file on LittleFS. Loop over file in 2048-byte chunks.
  3. For each chunk: Calculate CRC32. Send UART Header. Send UART data block.
  4. Wait for `<ACK_CHUNK>` from ESP32. If `<NACK_CHUNK>` or timeout, re-send the current chunk (Reliability mechanism).
  5. Close file. Send `<FINISH:total_file_crc>`.
  6. Wait to receive the algorithmic result from the server.

## Open Questions

> [!IMPORTANT]
> 1. **STM32 Hardware CRC**: Does the STM32 code currently use the built-in Hardware CRC calculator (`hcrc`), or should we implement a software CRC32 algorithm for calculating checksums?
> 2. **Retry Policies**: If a chunk upload fails on the ESP32 due to network drop, I've proposed retrying on the STM32 via NACK. How many retries should we permit before aborting the entire transfer?

## Verification Plan

### Automated Tests
- On the server, we will use `curl` to simulate the chunked endpoints (`/init`, `/chunk`, `/finish`) to verify assembly, CRC validation, and eventual processing invocation.

### Manual Verification
- We will instruct you (the developer) to flash the new ESP32 DevKit V1 and STM32 firmwares. 
- You will force a data capture, verify UART messaging via console output (`ACK` and pacing visibility).
- Finally, you will check the `docker-compose` server logs to ensure the chunks append correctly and the MATLAB worker correctly processes the final assembled binary.
