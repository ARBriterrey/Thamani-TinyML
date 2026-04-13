#include <WiFi.h>
#include <HTTPClient.h>

#ifndef LED_BUILTIN
  // Fallback to pin 2 if the board package doesn't define the built-in LED
  #define LED_BUILTIN 2 
#endif

// Helper function to blink the LED to show activity
void blinkLED(int times, int delayMs) {
  for(int i=0; i<times; i++) {
    digitalWrite(LED_BUILTIN, LOW);
    delay(delayMs);
    digitalWrite(LED_BUILTIN, HIGH);
    if (i < times - 1) delay(delayMs);
  }
}

// ==============================================================================
// CONFIGURATION
// ==============================================================================
const char* ssid = "Andy's edge 50 pro";           // Replace with your Network SSID
const char* password = "Jahanavee";   // Replace with your Network Password

// Your GCP instance external IP (port 5000)
// e.g., "http://34.47.182.133:5000/api/process"
const char* serverName = "http://34.47.182.133:5000/api/process";

// How often to send data (in milliseconds)
const int postInterval = 15000;
unsigned long previousMillis = 0;

// Variables simulating sensor readings
int hr = 72;
int spo2 = 98;
float temp = 36.6;
int sys = 120;
int dia = 80;

void setup() {
  Serial.begin(115200);
  delay(10);

  // Initialize LED indicator
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW); // Start with light off

  // Connect to Wi-Fi
  Serial.println("\n----------------------------------");
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  bool ledState = false;
  while (WiFi.status() != WL_CONNECTED) {
    ledState = !ledState;
    digitalWrite(LED_BUILTIN, ledState); // Blink while connecting
    delay(500);
    Serial.print(".");
  }

  digitalWrite(LED_BUILTIN, HIGH); // Solid ON when successfully connected

  Serial.println("");
  Serial.println("WiFi connected.");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

void loop() {
  unsigned long currentMillis = millis();

  // Send a POST request every 'postInterval' milliseconds
  if (currentMillis - previousMillis >= postInterval) {
    previousMillis = currentMillis;

    // Simulate small fluctuations in vitals
    hr = 70 + random(-5, +15);
    spo2 = 95 + random(0, 5);
    temp = 36.5 + (random(-5, 10) / 10.0);

    if (WiFi.status() == WL_CONNECTED) {
      HTTPClient http;

      // Begin connection
      http.begin(serverName);

      // Specify content-type header
      http.addHeader("Content-Type", "application/json");

      // Construct JSON payload
      // In production, use the Arduino_JSON library. We use String building here for simplicity.
      String payload = "{";
      payload += "\"device_id\": \"ESP32-HARDWARE-01\",";
      payload += "\"sensor_data\": {";
      payload += "\"heart_rate\": " + String(hr) + ",";
      payload += "\"spo2\": " + String(spo2) + ",";
      payload += "\"temperature\": " + String(temp, 1) + ",";
      payload += "\"systolic_bp\": " + String(sys) + ",";
      payload += "\"diastolic_bp\": " + String(dia);
      payload += "}";
      payload += "}";

      Serial.println("\n>>> Sending POST Data to GCP: " + String(serverName));
      Serial.println(payload);

      // Send the POST request
      long startTime = millis();
      int httpResponseCode = http.POST(payload);
      long stopTime = millis();

      // Handle response
      if (httpResponseCode > 0) {
        Serial.print("<<< HTTP Response code: ");
        Serial.println(httpResponseCode);
        
        String response = http.getString();
        Serial.println("<<< Payload Received:");
        Serial.println(response);
        Serial.print("Latency: ");
        Serial.print(stopTime - startTime);
        Serial.println(" ms");
        
        // Success: 2 quick blinks to indicate data sent and response received
        blinkLED(2, 100);
      } else {
        Serial.print("<<< Error on sending POST: ");
        Serial.println(httpResponseCode);
        Serial.println(http.errorToString(httpResponseCode).c_str());
        
        // Error: 5 slow blinks to indicate failure
        blinkLED(5, 300);
      }

      // Free resources
      http.end();
    } else {
      Serial.println("Error in WiFi connection");
    }
  }
}
