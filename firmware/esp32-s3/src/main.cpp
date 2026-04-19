#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include "certs.h"

#define RXD2 16
#define TXD2 17

// ==============================================================================
// CONFIGURATION
// ==============================================================================
const char* ssid = "Andy's edge 50 pro";
const char* password = "Jahanavee";
const char* serverName = "https://edge.thamanihc.com/api/process";

// File transfer state
enum TransferState {
  WAITING_FOR_START,
  RECEIVING_DATA,
  WAITING_FOR_END
};

TransferState state = WAITING_FOR_START;

uint8_t* psram_buffer = nullptr;
size_t expected_file_size = 0;
size_t bytes_received = 0;

void setup() {
  Serial.begin(115200);
  while (!Serial) { ; }
  
  Serial2.begin(115200, SERIAL_8N1, RXD2, TXD2);
  
  Serial.println("\n----------------------------------");
  Serial.printf("Connecting to Wi-Fi: %s\n", ssid);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected. IP:");
  Serial.println(WiFi.localIP());

  // Check if PSRAM is available
  if (psramFound()) {
    Serial.printf("PSRAM initialized. Total usable PSRAM: %d bytes\n", ESP.getPsramSize());
  } else {
    Serial.println("WARNING: PSRAM not found. Large file transfers may fail.");
  }
  
  Serial.println("ESP32-S3 Ready. Waiting for <START_BIN:size> over UART2...");
}

// Function to perform the HTTP Multipart Data Upload
void uploadFileToCloud(uint8_t* payload, size_t payload_size) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected. Cannot upload.");
    return;
  }
  
  WiFiClientSecure client;
  client.setInsecure(); // Let's Encrypt certificates are trusted by ignoring server checks or you can provide setCACert
  client.setCertificate(client_cert);
  client.setPrivateKey(client_priv_key);

  HTTPClient http;
  http.begin(client, serverName);

  String boundary = "----ESP32Boundary" + String(millis());
  http.addHeader("Content-Type", "multipart/form-data; boundary=" + boundary);

  String bodyStart = "--" + boundary + "\r\n";
  bodyStart += "Content-Disposition: form-data; name=\"device_id\"\r\n\r\n";
  bodyStart += "ESP32-S3-HARDWARE\r\n";
  bodyStart += "--" + boundary + "\r\n";
  bodyStart += "Content-Disposition: form-data; name=\"file\"; filename=\"upload.bin\"\r\n";
  bodyStart += "Content-Type: application/octet-stream\r\n\r\n";
  
  String bodyEnd = "\r\n--" + boundary + "--\r\n";

  size_t totalLength = bodyStart.length() + payload_size + bodyEnd.length();
  
  WiFiClient* stream = http.getStreamPtr();
  int httpResponseCode = 0;
  
  Serial.println("Starting multipart POST...");
  
  // Connect explicitly to send using chunked/streamed payload safely 
  // For multipart, it's safer to pre-allocate memory and send directly if it's in PSRAM, 
  // but HTTPClient has limitations on huge memory blocks over single String.
  // Instead, we will construct a continuous byte array.
  
  uint8_t* full_post = (uint8_t*)ps_malloc(totalLength);
  if (!full_post) {
      Serial.println("Failed to allocate PSRAM for POST request.");
      http.end();
      return;
  }
  
  memcpy(full_post, bodyStart.c_str(), bodyStart.length());
  memcpy(full_post + bodyStart.length(), payload, payload_size);
  memcpy(full_post + bodyStart.length() + payload_size, bodyEnd.c_str(), bodyEnd.length());
  
  httpResponseCode = http.POST(full_post, totalLength);

  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.printf("<<< HTTP Response code: %d\n", httpResponseCode);
    Serial.println("<<< Payload Received:");
    Serial.println(response);
    
    // Relay to STM32
    Serial2.print("<RESPONSE:");
    Serial2.print(response);
    Serial2.print(">");
  } else {
    Serial.printf("<<< HTTP POST Error: %d %s\n", httpResponseCode, http.errorToString(httpResponseCode).c_str());
    Serial2.print("<ERROR:SERVER_FAILED>");
  }

  free(full_post);
  http.end();
}

void loop() {
  if (state == WAITING_FOR_START) {
    if (Serial2.available()) {
      String marker = Serial2.readStringUntil('>');
      if (marker.startsWith("<START_BIN:")) {
        String sizeStr = marker.substring(11);
        expected_file_size = sizeStr.toInt();
        
        Serial.printf("\n--- File Transfer Started: %d bytes expected ---\n", expected_file_size);
        
        if (psram_buffer != nullptr) {
          free(psram_buffer);
        }
        
        psram_buffer = (uint8_t*)ps_malloc(expected_file_size);
        if (psram_buffer == nullptr) {
          Serial.println("ERROR: Could not allocate PSRAM for file.");
          Serial2.print("<ERROR:MEM>");
          // Fallback, drain buffer to avoid hang
        } else {
          bytes_received = 0;
          state = RECEIVING_DATA;
          
          // Ack to STM32 to start streaming raw bytes
          Serial2.print("<ACK_START>");
        }
      }
    }
  } 
  else if (state == RECEIVING_DATA) {
    while (Serial2.available()) {
      psram_buffer[bytes_received++] = Serial2.read();
      
      // Print progress
      if (bytes_received % 102400 == 0) {
        Serial.printf("Received %d / %d bytes...\n", bytes_received, expected_file_size);
      }
      
      if (bytes_received >= expected_file_size) {
        state = WAITING_FOR_END;
        Serial.println("All bytes received, waiting for <END_BIN> marker.");
        break;
      }
    }
  } 
  else if (state == WAITING_FOR_END) {
    if (Serial2.available()) {
      String endMarker = Serial2.readStringUntil('>');
      if (endMarker.indexOf("<END_BIN") >= 0) {
        Serial.println("--- End Transfer Marker Received ---");
        
        // Initiate Upload
        uploadFileToCloud(psram_buffer, expected_file_size);
        
        // Reset state
        free(psram_buffer);
        psram_buffer = nullptr;
        expected_file_size = 0;
        state = WAITING_FOR_START;
        Serial.println("\nWaiting for next transfer...");
      } else {
         Serial.println("Warning: End marker garbled, attempting recovery...");
      }
    }
  }
}
