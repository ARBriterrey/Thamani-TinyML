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

const char* serverInit = "https://edge.thamanihc.com/api/upload/init";
const char* serverChunk = "https://edge.thamanihc.com/api/upload/chunk";
const char* serverFinish = "https://edge.thamanihc.com/api/upload/finish";

// File transfer state
enum TransferState {
  IDLE,
  RECEIVING_CHUNK
};

TransferState state = IDLE;

// Standard SRAM buffer config
#define CHUNK_BUFFER_SIZE 4096
uint8_t chunk_buffer[CHUNK_BUFFER_SIZE];
size_t current_chunk_size = 0;
size_t bytes_received = 0;
String current_chunk_crc = "";

String transfer_id = "";

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

  Serial.println("ESP32 Ready. Waiting for chunk commands over UART2...");
}

// -------------------------------------------------------------
// Cloud API Methods
// -------------------------------------------------------------

bool initCloudTransfer() {
  if (WiFi.status() != WL_CONNECTED) return false;
  
  WiFiClientSecure client;
  client.setCACert(server_ca_cert);      // Verify server cert against ISRG Root X1
  client.setCertificate(client_cert);   // Present device client cert (mTLS)
  client.setPrivateKey(client_priv_key);

  HTTPClient http;
  http.begin(client, serverInit);
  http.addHeader("Content-Type", "application/json");

  int httpCode = http.POST("{\"device_id\":\"ESP32-HARDWARE\"}");
  bool success = false;
  if (httpCode == 200 || httpCode == 202) {
    String resp = http.getString();
    // basic parsing for transfer_id
    int idx = resp.indexOf("\"transfer_id\":\"");
    if (idx > 0) {
      idx += 15;
      int endIdx = resp.indexOf("\"", idx);
      transfer_id = resp.substring(idx, endIdx);
      success = true;
      Serial.println("Init successful. Transfer ID: " + transfer_id);
    }
  } else {
    Serial.printf("Init POST Error: %d %s\n", httpCode, http.getString().c_str());
  }
  http.end();
  return success;
}

bool uploadChunkToCloud() {
  if (WiFi.status() != WL_CONNECTED) return false;
  
  WiFiClientSecure client;
  client.setCACert(server_ca_cert);      // Verify server cert against ISRG Root X1
  client.setCertificate(client_cert);   // Present device client cert (mTLS)
  client.setPrivateKey(client_priv_key);

  HTTPClient http;
  http.begin(client, serverChunk);

  String boundary = "----ESP32Boundary" + String(millis());
  http.addHeader("Content-Type", "multipart/form-data; boundary=" + boundary);

  String bodyStart = "--" + boundary + "\r\n";
  bodyStart += "Content-Disposition: form-data; name=\"transfer_id\"\r\n\r\n";
  bodyStart += transfer_id + "\r\n";
  bodyStart += "--" + boundary + "\r\n";
  bodyStart += "Content-Disposition: form-data; name=\"crc32\"\r\n\r\n";
  bodyStart += current_chunk_crc + "\r\n";
  bodyStart += "--" + boundary + "\r\n";
  bodyStart += "Content-Disposition: form-data; name=\"file\"; filename=\"chunk.bin\"\r\n";
  bodyStart += "Content-Type: application/octet-stream\r\n\r\n";
  
  String bodyEnd = "\r\n--" + boundary + "--\r\n";

  size_t totalLength = bodyStart.length() + current_chunk_size + bodyEnd.length();
  uint8_t* full_post = (uint8_t*)malloc(totalLength);
  if (!full_post) {
      Serial.println("Failed to allocate RAM for multipart request.");
      return false;
  }
  
  memcpy(full_post, bodyStart.c_str(), bodyStart.length());
  memcpy(full_post + bodyStart.length(), chunk_buffer, current_chunk_size);
  memcpy(full_post + bodyStart.length() + current_chunk_size, bodyEnd.c_str(), bodyEnd.length());
  
  int httpCode = http.POST(full_post, totalLength);
  bool success = (httpCode == 200 || httpCode == 202);
  if (!success) {
      Serial.printf("Chunk POST Error: %d %s\n", httpCode, http.getString().c_str());
  }
  
  free(full_post);
  http.end();
  return success;
}

bool finishCloudTransfer(String total_crc, String &responseBody) {
  if (WiFi.status() != WL_CONNECTED) return false;
  
  WiFiClientSecure client;
  client.setCACert(server_ca_cert);      // Verify server cert against ISRG Root X1
  client.setCertificate(client_cert);   // Present device client cert (mTLS)
  client.setPrivateKey(client_priv_key);

  HTTPClient http;
  http.begin(client, serverFinish);
  http.addHeader("Content-Type", "application/json");

  String payload = "{\"transfer_id\":\"" + transfer_id + "\",\"total_crc32\":\"" + total_crc + "\"}";
  int httpCode = http.POST(payload);
  
  bool success = false;
  if (httpCode == 200 || httpCode == 202) {
    success = true;
    responseBody = http.getString();
  } else {
    Serial.printf("Finish POST Error: %d %s\n", httpCode, http.getString().c_str());
  }
  http.end();
  return success;
}

// -------------------------------------------------------------
// Main Loop
// -------------------------------------------------------------

void loop() {
  if (state == IDLE) {
    if (Serial2.available()) {
      String marker = Serial2.readStringUntil('>');
      
      if (marker.startsWith("<INIT:")) {
        Serial.println("Received INIT");
        if (initCloudTransfer()) {
          Serial2.print("<ACK_INIT>");
        } else {
          Serial2.print("<NACK_INIT>");
        }
      } 
      else if (marker.startsWith("<CHUNK:")) {
        // Format: <CHUNK:size:crc>
        int firstColon = marker.indexOf(':');
        int secondColon = marker.indexOf(':', firstColon + 1);
        
        if (firstColon > 0 && secondColon > 0) {
          String sizeStr = marker.substring(firstColon + 1, secondColon);
          current_chunk_crc = marker.substring(secondColon + 1);
          current_chunk_size = sizeStr.toInt();
          
          if (current_chunk_size <= CHUNK_BUFFER_SIZE) {
            bytes_received = 0;
            state = RECEIVING_CHUNK;
            Serial.printf("Receiving CHUNK size: %d, crc: %s\n", current_chunk_size, current_chunk_crc.c_str());
            Serial2.print("<READY>"); // Tell STM32 to send raw bytes
          } else {
             Serial2.print("<NACK_CHUNK_SIZE>");
          }
        }
      }
      else if (marker.startsWith("<FINISH:")) {
        String total_crc = marker.substring(8);
        Serial.println("Received FINISH, total CRC: " + total_crc);
        String serverResponse;
        if (finishCloudTransfer(total_crc, serverResponse)) {
            Serial2.print("<ACK_FINISH:");
            Serial2.print(serverResponse);
            Serial2.print(">");
        } else {
            Serial2.print("<NACK_FINISH>");
        }
      }
    }
  } 
  else if (state == RECEIVING_CHUNK) {
    while (Serial2.available() && bytes_received < current_chunk_size) {
      chunk_buffer[bytes_received++] = Serial2.read();
    }
    
    if (bytes_received >= current_chunk_size) {
      // We have the full chunk, now push it
      Serial.println("Chunk downloaded from STM32, pushing to cloud...");
      if (uploadChunkToCloud()) {
        Serial2.print("<ACK_CHUNK>");
      } else {
        Serial2.print("<NACK_CHUNK>");
      }
      state = IDLE;
    }
  }
}
