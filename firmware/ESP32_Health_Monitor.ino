#include <Wire.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include "MAX30105.h"
#include "heartRate.h"
#include "MAX30100_PulseOximeter.h"
#include "BluetoothSerial.h"

// Data wire for DS18B20 is plugged into pin 2 on the Arduino
#define ONE_WIRE_BUS 4

// Setup a oneWire instance to communicate with any OneWire devices
OneWire oneWire(ONE_WIRE_BUS);

// Pass our oneWire reference to Dallas Temperature sensor 
DallasTemperature sensors(&oneWire);

MAX30105 particleSensor;
PulseOximeter pox;

const byte RATE_SIZE = 4; // Increase this for more averaging. 4 is good.
byte rates[RATE_SIZE]; // Array of heart rates
byte rateSpot = 0;
long lastBeat = 0; // Time at which the last beat occurred

float beatsPerMinute;
int beatAvg;

BluetoothSerial SerialBT; // Object for Bluetooth

void setup() {
  Serial.begin(115200);
  Serial.println("Initializing...");

  // Initialize Bluetooth
  if (!SerialBT.begin("ESP32_Health_Monitor")) {
    Serial.println("An error occurred initializing Bluetooth");
  } else {
    Serial.println("Bluetooth initialized");
  }

  if (!pox.begin()) {
    Serial.println("Failed to initialize pulse oximeter!");
    // Handle failure to initialize the pulse oximeter
  }

  // Start up the library for DS18B20
  sensors.begin();

  // Initialize MAX30105
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) { // Use default I2C port, 400kHz speed
    Serial.println("MAX30105 was not found. Please check wiring/power.");
    while (1);
  }
  Serial.println("Place your index finger on the sensor with steady pressure.");

  particleSensor.setup(); // Configure sensor with default settings
  particleSensor.setPulseAmplitudeRed(0x0A); // Turn Red LED to low to indicate sensor is running
  particleSensor.setPulseAmplitudeGreen(0); // Turn off Green LED
}

void loop() {
  static unsigned long lastTempMeasurement = 0;
  const unsigned long tempMeasurementInterval = 1000; // Measure temperature every 1000 ms (1 second)
  static float temperatureC = 0.0; // Initialize once, use throughout the loop

  // Take temperature measurement at set intervals
  if (millis() - lastTempMeasurement >= tempMeasurementInterval) {
    sensors.requestTemperatures(); 
    temperatureC = sensors.getTempCByIndex(0); // Update the temperatureC variable
    lastTempMeasurement = millis();
  }

  // Update the pulse oximeter
  pox.update();
  
  // Get SpO2 value (assuming a valid reading is available)
  uint8_t spo2 = pox.getSpO2();

  // Read heart rate
  long irValue = particleSensor.getIR();
  bool beatDetected = checkForBeat(irValue);

  if (beatDetected) {
    long delta = millis() - lastBeat;
    lastBeat = millis();

    beatsPerMinute = 60 / (delta / 1000.0);

    if (beatsPerMinute < 255 && beatsPerMinute > 20) {
      rates[rateSpot++] = (byte)beatsPerMinute; // Store this reading in the array
      rateSpot %= RATE_SIZE; // Wrap variable

      // Take the average of readings
      beatAvg = 0;
      for (byte x = 0; x < RATE_SIZE; x++) {
        beatAvg += rates[x];
      }
      beatAvg /= RATE_SIZE;
    }
  }

  // Check if no finger is detected
  if (irValue < 50000) {
    SerialBT.println("No finger detected");
  } else if (beatDetected) {
    // If a finger is detected and a beat is detected, send all the measurements over Bluetooth
    SerialBT.print("Temp: ");
    SerialBT.print(temperatureC);
    SerialBT.print("C, BPM: ");
    SerialBT.print(beatsPerMinute);
    SerialBT.print(", Avg BPM: ");
    SerialBT.print(beatAvg);
    SerialBT.print(", SpO2: ");
    SerialBT.print(spo2);
    SerialBT.println("%");
  }
}

// //
// #include <Wire.h>
// #include <OneWire.h>
// #include <DallasTemperature.h>
// #include "MAX30105.h"
// #include "heartRate.h"
// #include "MAX30100_PulseOximeter.h"
// #include "BluetoothSerial.h"

// #define ONE_WIRE_BUS 4

// OneWire oneWire(ONE_WIRE_BUS);
// DallasTemperature sensors(&oneWire);
// MAX30105 particleSensor;
// PulseOximeter pox;

// const byte RATE_SIZE = 4;
// byte rates[RATE_SIZE];
// byte rateSpot = 0;
// long lastBeat = 0;
// float beatsPerMinute;
// int beatAvg;

// BluetoothSerial SerialBT;

// void setup() {
//   Serial.begin(115200);
//   Serial.println("Initializing...");

//   // Initialize Bluetooth and check for errors
//   if (!SerialBT.begin("ESP32_Health_Monitor")) {
//     Serial.println("An error occurred initializing Bluetooth");
//     while (1); // Halt execution
//   } else {
//     Serial.println("Bluetooth initialized");
//   }

//   // Check if Bluetooth module is available
//   if (!SerialBT.available()) {
//     Serial.println("Bluetooth not available");
//     while (1); // Halt execution
//   } else {
//     Serial.println("Bluetooth is available");
//   }

//   // Initialize pulse oximeter
//   if (!pox.begin()) {
//     Serial.println("Failed to initialize pulse oximeter!");
//     while (1); // Halt execution
//   }

//   // Initialize temperature sensor
//   sensors.begin();
//   if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
//     Serial.println("MAX30105 was not found. Please check wiring/power.");
//     while (1); // Halt execution
//   }
//   Serial.println("Sensors initialized");

//   // Setup particle sensor
//   particleSensor.setup();
//   particleSensor.setPulseAmplitudeRed(0x0A);
//   particleSensor.setPulseAmplitudeGreen(0);

//   Serial.println("Setup complete. Place your index finger on the sensor with steady pressure.");
// }

// void loop() {
//   static unsigned long lastTempMeasurement = 0;
//   const unsigned long tempMeasurementInterval = 1000;
//   static float temperatureC = 0.0;

//   if (millis() - lastTempMeasurement >= tempMeasurementInterval) {
//     sensors.requestTemperatures();
//     temperatureC = sensors.getTempCByIndex(0);
//     lastTempMeasurement = millis();
//   }

//   pox.update();
//   uint8_t spo2 = pox.getSpO2();
//   long irValue = particleSensor.getIR();
//   bool beatDetected = checkForBeat(irValue);

//   if (beatDetected) {
//     long delta = millis() - lastBeat;
//     lastBeat = millis();
//     beatsPerMinute = 60 / (delta / 1000.0);

//     if (beatsPerMinute < 255 && beatsPerMinute > 20) {
//       rates[rateSpot++] = (byte)beatsPerMinute;
//       rateSpot %= RATE_SIZE;
//       beatAvg = 0;
//       for (byte x = 0; x < RATE_SIZE; x++) {
//         beatAvg += rates[x];
//       }
//       beatAvg /= RATE_SIZE;
//     }
//   }

//   if (irValue < 50000) {
//     SerialBT.println("No finger detected");
//     Serial.println("No finger detected on the sensor");
//   } else if (beatDetected) {
//     SerialBT.print("Temp: ");
//     SerialBT.print(temperatureC);
//     SerialBT.print("C, BPM: ");
//     SerialBT.print(beatsPerMinute);
//     SerialBT.print(", Avg BPM: ");
//     SerialBT.print(beatAvg);
//     SerialBT.print(", SpO2: ");
//     SerialBT.print(spo2);
//     SerialBT.println("%");

//     // Debug print to the serial monitor
//     Serial.print("Data sent - Temp: ");
//     Serial.print(temperatureC);
//     Serial.print("C, BPM: ");
//     Serial.print(beatsPerMinute);
//     Serial.print(", Avg BPM: ");
//     Serial.print(beatAvg);
//     Serial.print(", SpO2: ");
//     Serial.println(spo2);
//   }
// }
// //