#include <Arduino.h>

#define RXD2 16
#define TXD2 17
#define CHUNK_SIZE 1024

uint8_t incoming_buffer[CHUNK_SIZE];
int buffer_index = 0;
int chunks_received = 0;

void setup() {
  // Initialize standard Serial for Mac output
  Serial.begin(115200);
  while (!Serial) { ; } 
  Serial.println("ESP32-S3 Initialized. Waiting for STM32 binary dummy data on UART2...");

  // Initialize UART2 for STM32 communication
  Serial2.begin(115200, SERIAL_8N1, RXD2, TXD2);
}

void loop() {
  // Check if data is available from the STM32
  if (Serial2.available()) {
    while (Serial2.available() && buffer_index < CHUNK_SIZE) {
      incoming_buffer[buffer_index] = Serial2.read();
      buffer_index++;
    }

    // If we've received a full chunk, process/print the summary
    if (buffer_index >= CHUNK_SIZE) {
      chunks_received++;
      Serial.printf("\n--- Chunk %d Received (%d bytes) ---\n", chunks_received, buffer_index);
      
      // Parse the first few samples to prove we got the binary data properly
      Serial.println("First 3 Data Points:");
      for (int i = 0; i < 18; i += 6) { 
          uint16_t analog = incoming_buffer[i] | (incoming_buffer[i+1] << 8);
          uint16_t ppg1 = incoming_buffer[i+2] | (incoming_buffer[i+3] << 8);
          uint16_t ppg2 = incoming_buffer[i+4] | (incoming_buffer[i+5] << 8);
          Serial.printf("  Sample: Analog=%u, PPG1=%u, PPG2=%u\n", analog, ppg1, ppg2);
      }
      
      Serial.println("----------------------------------");
      buffer_index = 0; // Reset for next chunk
    }
  }
}
