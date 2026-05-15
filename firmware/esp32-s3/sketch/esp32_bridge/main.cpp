// =============================================================================
//  ESP32-S3 Bridge — Optimized Upload Pipeline
//  Optimizations applied:
//    1. UART baud rate: 115200 → 921600 (~8x faster STM32-to-ESP32 transfer)
//    2. Chunk size: 4096 → 32768 bytes (80 chunks instead of 1024)
//    3. Persistent HTTPS Keep-Alive (one TLS handshake for ALL chunks)
//    4. Double buffering via FreeRTOS tasks on separate cores:
//         Core 1 → UART receive task (fills buf[fill])
//         Core 0 → HTTP upload task  (drains buf[upload])
//       These two operations now overlap, hiding upload latency behind receive time.
// =============================================================================

#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include "certs.h"

// ─────────────────────────────────────────────
// Pin & UART config
// ─────────────────────────────────────────────
#define RXD2      16
#define TXD2      17
#define UART_BAUD 921600  // Step 1: was 115200

// ─────────────────────────────────────────────
// Server endpoints
// ─────────────────────────────────────────────
const char* serverInit   = "https://edge.thamanihc.com/api/upload/init";
const char* serverChunk  = "https://edge.thamanihc.com/api/upload/chunk";
const char* serverFinish = "https://edge.thamanihc.com/api/upload/finish";

// ─────────────────────────────────────────────
// Credentials
// ─────────────────────────────────────────────
const char* ssid     = "Andy's edge 50 pro";
const char* password = "Jahanavee";

// ─────────────────────────────────────────────
// Double-buffer setup — Step 2 + 4
//   Two 32 KB buffers. While one is uploading the other is being filled.
// ─────────────────────────────────────────────
#define CHUNK_BUFFER_SIZE 32768
static uint8_t buf[2][CHUNK_BUFFER_SIZE];

// Metadata per buffer slot
static size_t buf_size[2] = {0, 0};
static String buf_crc[2]  = {"", ""};

// Index of buffer currently being filled by UART task
static volatile int fill_idx   = 0;
// Index of buffer currently being uploaded by HTTP task
static volatile int upload_idx = -1;  // -1 = none ready yet

// ─────────────────────────────────────────────
// FreeRTOS synchronization (Step 4)
// ─────────────────────────────────────────────
SemaphoreHandle_t xUploadReady = NULL;  // UART task signals: buffer is full, start upload
SemaphoreHandle_t xUploadDone  = NULL;  // HTTP task signals: upload finished, buffer is free
static volatile bool lastUploadOk = false;

// ─────────────────────────────────────────────
// Persistent HTTPS connection (Step 3)
//   Opened once in initCloudTransfer(), reused for every chunk POST.
//   Closed only in finishCloudTransfer().
// ─────────────────────────────────────────────
static WiFiClientSecure persistClient;
static HTTPClient        persistHttp;
static bool              httpSessionOpen = false;

String transfer_id = "";

// ─────────────────────────────────────────────
// Transfer state machine
// ─────────────────────────────────────────────
enum TransferState { IDLE, RECEIVING_CHUNK };
static TransferState state      = IDLE;
static size_t        bytes_recv = 0;


// =============================================================================
//  CLOUD API
// =============================================================================

// Called once per transfer session.
// Opens the persistent chunk-upload connection after a successful init.
bool initCloudTransfer() {
  if (WiFi.status() != WL_CONNECTED) return false;

  // Use a short-lived client just for the init POST
  WiFiClientSecure initClient;
  initClient.setInsecure();
  initClient.setCertificate(client_cert);
  initClient.setPrivateKey(client_priv_key);

  HTTPClient initHttp;
  initHttp.begin(initClient, serverInit);
  initHttp.addHeader("Content-Type", "application/json");

  int code = initHttp.POST("{\"device_id\":\"ESP32-HARDWARE\"}");
  bool ok  = false;

  if (code == 200 || code == 202) {
    String resp = initHttp.getString();
    int idx = resp.indexOf("\"transfer_id\":\"");
    if (idx > 0) {
      idx += 15;
      transfer_id = resp.substring(idx, resp.indexOf("\"", idx));
      ok = true;
      Serial.println("Init OK. Transfer ID: " + transfer_id);
    }
  } else {
    Serial.printf("Init failed: HTTP %d\n", code);
  }
  initHttp.end();

  if (ok) {
    // ── Step 3: open persistent connection ──────────────────────────────
    persistClient.setInsecure();
    persistClient.setCertificate(client_cert);
    persistClient.setPrivateKey(client_priv_key);
    persistHttp.setReuse(true);  // tell HTTPClient to keep the TCP connection alive
    persistHttp.begin(persistClient, serverChunk);
    httpSessionOpen = true;
    Serial.println("Persistent HTTPS session open.");
  }

  return ok;
}

// Upload the contents of buf[idx] using the persistent connection.
// NO http.end() here — the connection stays open for the next chunk.
bool uploadChunkToCloud(int idx) {
  if (!httpSessionOpen || WiFi.status() != WL_CONNECTED) return false;

  uint32_t t0 = millis();

  String boundary = "----ESP32Boundary";
  persistHttp.addHeader("Content-Type", "multipart/form-data; boundary=" + boundary);

  // Build multipart body in a single malloc'd block to avoid heap fragmentation
  String hdr  = "--" + boundary + "\r\n"
                "Content-Disposition: form-data; name=\"transfer_id\"\r\n\r\n" +
                transfer_id + "\r\n" +
                "--" + boundary + "\r\n"
                "Content-Disposition: form-data; name=\"crc32\"\r\n\r\n" +
                buf_crc[idx] + "\r\n" +
                "--" + boundary + "\r\n"
                "Content-Disposition: form-data; name=\"file\"; filename=\"chunk.bin\"\r\n"
                "Content-Type: application/octet-stream\r\n\r\n";
  String tail = "\r\n--" + boundary + "--\r\n";

  size_t csz   = buf_size[idx];
  size_t total = hdr.length() + csz + tail.length();

  uint8_t* body = (uint8_t*)malloc(total);
  if (!body) {
    Serial.println("ERR: malloc failed for POST body");
    return false;
  }
  memcpy(body,                          hdr.c_str(),  hdr.length());
  memcpy(body + hdr.length(),           buf[idx],     csz);
  memcpy(body + hdr.length() + csz,     tail.c_str(), tail.length());

  int code = persistHttp.POST(body, total);
  free(body);

  bool ok = (code == 200 || code == 202);
  Serial.printf("[buf%d] Upload %s — HTTP %d — %lu ms\n",
                idx, ok ? "OK" : "FAIL", code, millis() - t0);
  return ok;
}

// Called once after all chunks. Closes the persistent session then POSTs finish.
bool finishCloudTransfer(const String& total_crc, String& responseBody) {
  // ── Step 3: close persistent chunk session first ─────────────────────
  if (httpSessionOpen) {
    persistHttp.end();
    httpSessionOpen = false;
    Serial.println("Persistent session closed.");
  }

  if (WiFi.status() != WL_CONNECTED) return false;

  WiFiClientSecure finClient;
  finClient.setInsecure();
  finClient.setCertificate(client_cert);
  finClient.setPrivateKey(client_priv_key);

  HTTPClient finHttp;
  finHttp.begin(finClient, serverFinish);
  finHttp.addHeader("Content-Type", "application/json");

  String payload = "{\"transfer_id\":\"" + transfer_id +
                   "\",\"total_crc32\":\"" + total_crc + "\"}";
  int code = finHttp.POST(payload);

  bool ok = (code == 200 || code == 202);
  if (ok) {
    responseBody = finHttp.getString();
  } else {
    Serial.printf("Finish failed: HTTP %d\n", code);
  }
  finHttp.end();
  return ok;
}


// =============================================================================
//  STEP 4 — HTTP Upload Task (runs on Core 0)
//  Waits for xUploadReady, uploads the buffer identified by upload_idx,
//  then signals xUploadDone.
// =============================================================================
void httpUploadTask(void* pvParams) {
  for (;;) {
    // Block until the UART task has a full buffer ready
    if (xSemaphoreTake(xUploadReady, portMAX_DELAY) == pdTRUE) {
      lastUploadOk = uploadChunkToCloud(upload_idx);
      xSemaphoreGive(xUploadDone);
    }
  }
}


// =============================================================================
//  SETUP
// =============================================================================
void setup() {
  Serial.begin(115200);
  while (!Serial) { ; }

  // ── Step 4: create synchronization primitives ────────────────────────
  xUploadReady = xSemaphoreCreateBinary();
  xUploadDone  = xSemaphoreCreateBinary();

  // Launch upload task pinned to Core 0; main loop runs on Core 1
  xTaskCreatePinnedToCore(
    httpUploadTask,   // task function
    "httpUpload",     // name
    8192,             // stack (bytes) — enough for TLS + multipart
    NULL,             // params
    2,                // priority (higher than main loop)
    NULL,             // task handle
    0                 // core 0
  );

  // ── Step 1: increase UART RX software buffer before begin() ─────────
  // 65536 bytes ≈ 2× chunk size; absorbs next chunk while current uploads
  Serial2.setRxBufferSize(65536);
  Serial2.begin(UART_BAUD, SERIAL_8N1, RXD2, TXD2);

  Serial.println("\n----------------------------------");
  Serial.printf("Connecting to Wi-Fi: %s\n", ssid);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.printf("\nWiFi connected — IP: %s  RSSI: %d dBm\n",
                WiFi.localIP().toString().c_str(), WiFi.RSSI());
  Serial.println("ESP32 Ready. Waiting for commands on UART2...");
}


// =============================================================================
//  MAIN LOOP (runs on Core 1) — UART receive + state machine
// =============================================================================
void loop() {

  // ─────────────────────────────────────────────────────────────────────
  //  IDLE: wait for a command from STM32
  // ─────────────────────────────────────────────────────────────────────
  if (state == IDLE) {
    if (!Serial2.available()) return;

    String marker = Serial2.readStringUntil('>');

    // ── INIT ────────────────────────────────────────────────────────────
    if (marker.startsWith("<INIT:")) {
      Serial.println("Received INIT");
      fill_idx   = 0;
      upload_idx = -1;
      if (initCloudTransfer()) {
        Serial2.print("<ACK_INIT>");
      } else {
        Serial2.print("<NACK_INIT>");
      }
    }

    // ── CHUNK header ─────────────────────────────────────────────────
    else if (marker.startsWith("<CHUNK:")) {
      int c1 = marker.indexOf(':');
      int c2 = marker.indexOf(':', c1 + 1);

      if (c1 > 0 && c2 > 0) {
        size_t sz  = (size_t)marker.substring(c1 + 1, c2).toInt();
        String crc = marker.substring(c2 + 1);

        if (sz <= CHUNK_BUFFER_SIZE) {
          buf_size[fill_idx] = sz;
          buf_crc[fill_idx]  = crc;
          bytes_recv         = 0;
          state              = RECEIVING_CHUNK;
          Serial.printf("[buf%d] Expect %u bytes, crc=%s\n", fill_idx, sz, crc.c_str());
          Serial2.print("<READY>");
        } else {
          Serial2.print("<NACK_CHUNK_SIZE>");
        }
      }
    }

    // ── FINISH ───────────────────────────────────────────────────────
    else if (marker.startsWith("<FINISH:")) {
      String total_crc = marker.substring(8);
      Serial.println("Received FINISH, total CRC: " + total_crc);
      String serverResp;
      if (finishCloudTransfer(total_crc, serverResp)) {
        Serial2.print("<ACK_FINISH:");
        Serial2.print(serverResp);
        Serial2.print(">");
      } else {
        Serial2.print("<NACK_FINISH>");
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  //  RECEIVING_CHUNK: drain UART bytes into buf[fill_idx]
  // ─────────────────────────────────────────────────────────────────────
  else if (state == RECEIVING_CHUNK) {
    size_t target = buf_size[fill_idx];

    while (Serial2.available() && bytes_recv < target) {
      buf[fill_idx][bytes_recv++] = Serial2.read();
    }

    if (bytes_recv >= target) {
      // ── Buffer full: hand it off to the upload task (Step 4) ────────
      Serial.printf("[buf%d] Full. Signalling upload task.\n", fill_idx);

      // If a previous upload is still running, wait for it to finish
      // so we can check its result and send the ACK before pipeline swap.
      if (upload_idx != -1) {
        xSemaphoreTake(xUploadDone, portMAX_DELAY);
        // Send ACK/NACK for the buffer that just finished uploading
        Serial2.print(lastUploadOk ? "<ACK_CHUNK>" : "<NACK_CHUNK>");
        Serial.printf("[buf%d] Upload complete — %s\n",
                      upload_idx, lastUploadOk ? "ACK" : "NACK");
      }

      // Start upload of the newly completed buffer
      upload_idx = fill_idx;
      xSemaphoreGive(xUploadReady);  // wake HTTP task on Core 0

      // Swap to the other buffer for the next UART receive
      fill_idx = 1 - fill_idx;

      // Return to IDLE so the main loop can receive the next <CHUNK:...> header.
      // The HTTP task is uploading in parallel on Core 0.
      state = IDLE;
    }
  }
}
