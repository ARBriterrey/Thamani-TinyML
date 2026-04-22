# Research Notes: ESP32 Large File Upload Strategies

Since we are constrained by the standard ESP32 DevKit V1 (which lacks the PSRAM needed to buffer an entire multi-megabyte binary file), we must chunk the data. Based on industry standards and typical IoT architectures, here are the different ways we can address the problems raised:

## 1. Application-Level Chunked Upload API (Proposed in Implementation Plan)
This approach modifies the server to accept a file in pieces rather than all at once.

*   **How it works**: The server exposes three endpoints (`/init`, `/chunk`, `/finish`). The ESP32 receives a small chunk (e.g., 2KB) from the STM32 via UART, performs an HTTP POST to `/chunk`, gets verification, and asks the STM32 for the next chunk.
*   **Pros**: 
    *   **Extremely resilient** to network drops. If a chunk fails, the ESP32 only retries that specific 2KB block.
    *   Allows arbitrary pauses if the STM32 is busy reading from Flash/LittleFS.
    *   Server logic is highly stateless per request.
*   **Cons**:
    *   High HTTP overhead. Each 2KB chunk requires a full set of HTTP headers (request and response).
    *   Slightly slower overall throughput due to HTTP round-trips.

## 2. Protocol-Level "HTTP Chunked Transfer Encoding"
This leverages a built-in feature of the HTTP/1.1 protocol (`Transfer-Encoding: chunked`).

*   **How it works**: The ESP32 opens a **single** persistent HTTP connection to the Flask server's `/api/process` endpoint. As chunks arrive from the STM32 over UART, the ESP32 forwards them over the open Wi-Fi connection in hex-sized chunk blocks. At the end, it sends a zero-length chunk to close the file.
*   **Pros**:
    *   **Fastest HTTP method**. Only one set of HTTP headers is exchanged. Low latency.
    *   Can potentially reuse the existing server `/api/process` endpoint if the Flask application is configured to stream the incoming request direct-to-disk (using `request.stream`).
*   **Cons**:
    *   **Poor error recovery**. If the Wi-Fi connection drops at 99%, the entire transfer fails and must start over from byte 0.
    *   Requires careful handling in Flask, as Flask's default behavior is to buffer the entire payload into memory or a temporary file *before* giving the code access to it.

## 3. WebSockets (Binary Frames)
Instead of HTTP POST requests, the ESP32 maintains a persistent WebSocket connection to the server.

*   **How it works**: The ESP32 connects to `wss://edge.thamanihc.com/ws`. As the STM32 pushes chunks over UART, the ESP32 routes them as WebSocket Binary Frames.
*   **Pros**:
    *   Extremely low overhead per chunk (only 2-10 bytes of framing overhead compared to ~300 bytes for HTTP headers).
    *   Allows true bi-directional real-time communication (e.g., stopping the transfer from the server side if needed).
*   **Cons**:
    *   Flask is historically synchronous and handles long-lived WebSockets poorly unless paired with `Flask-SocketIO`, `Eventlet`, or switching to an asynchronous framework like `FastAPI`.

## 4. MQTT Protocol
MQTT is the dominant protocol in IoT for passing messages.

*   **How it works**: We deploy an MQTT Broker (like Mosquitto) alongside the Docker Orchestrator. The ESP32 connects to the broker and "publishes" binary chunks to a specific topic (`devices/stm32/upload`). A separate Python worker subscribes to this topic and writes the chunks to disk.
*   **Pros**:
    *   Highly scalable and perfectly suited for microcontrollers.
    *   Built-in Quality of Service (QoS 1) ensures chunks are not lost and are acknowledged.
*   **Cons**:
    *   Introduces a complex new infrastructure component (the MQTT broker).
    *   MQTT is generally optimized for small telemetry messages (under 256KB), not multi-megabyte binary files.

---

## Addressing Data Integrity (Checksums vs. CRC)

Regardless of the transport protocol above, we must guarantee the medical binary file matches bit-for-bit once it hits the server.

1.  **Hardware CRC32 (Recommended)**: The STM32 microcontroller has a built-in Hardware CRC calculation peripheral. It can compute the CRC32 of 2KB chunks incredibly fast with zero CPU penalty. We can append this 4-byte CRC to each UART chunk.
2.  **Software MD5/SHA256**: Cryptographically secure, but computationally expensive for the STM32. It will drastically slow down the reading from LittleFS and the UART transmission. Not recommended for standard file integrity.
3.  **Fletcher16/Adler32**: Fast software checksums, but weaker than CRC32. Since STM32 has hardware CRC, CRC32 is superior.

## Conclusion

The **Application-Level Chunked API (Option 1)** (as proposed in the Implementation Plan) is the most reliable approach for medical data where a network error shouldn't mandate a full re-transmission. However, if sheer speed is the priority over reliability, **HTTP Chunked Transfer Encoding (Option 2)** is the best alternative, provided we update the Flask server to stream the incoming multipart data straight to the shared Docker volume.
