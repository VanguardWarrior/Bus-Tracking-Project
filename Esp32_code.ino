


#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <TinyGPS++.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>  // Gyroscope library

// Wi-Fi Credentials
#define WIFI_SSID "GPS_Project"
#define WIFI_PASSWORD "12345678"

// Firebase Credentials
#define FIREBASE_PROJECT_ID "gps-tracking-4392e"
#define FIREBASE_API_KEY "AIzaSyDifMiBooJhr2ryu4rAqCLYFDCme5VDBSc"
#define USER_EMAIL "saikrishh1001@gmail.com"
#define USER_PASSWORD "sai1234"

// GPS & Firebase Setup
HardwareSerial gpsSerial(1);
TinyGPSPlus gps;
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
bool firebaseAuthenticated = false;

// Gyroscope & Vibration Sensor
Adafruit_MPU6050 mpu;
#define VIBRATION_SENSOR_PIN 2 // Vibration sensor on D2
#define VIBRATION_THRESHOLD_TIME 500 // 500ms threshold for strong vibrations

float lastLatitude = 0.0, lastLongitude = 0.0;
unsigned long lastMovementTime = 0;
unsigned long vibrationStartTime = 0;
bool strongVibrationDetected = false;

void setup() {
    Serial.begin(115200);
    gpsSerial.begin(9600, SERIAL_8N1, 16, 17);
    pinMode(VIBRATION_SENSOR_PIN, INPUT);

    // Connect to Wi-Fi
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\n✅ Wi-Fi Connected!");

    // Firebase setup
    config.api_key = FIREBASE_API_KEY;
    auth.user.email = USER_EMAIL;
    auth.user.password = USER_PASSWORD;
    config.database_url = "https://gps-tracking-4392e.firebaseio.com";
    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);

    // Gyroscope setup
    if (!mpu.begin()) {
        Serial.println("❌ MPU6050 not detected!");
    } else {
        Serial.println("✅ Gyroscope Initialized!");
    }
}

void loop() {
    if (!firebaseAuthenticated && auth.token.uid != "") {
        firebaseAuthenticated = true;
        Serial.println("\n✅ Firebase Authentication Successful!");
    }

    // Read GPS data
    while (gpsSerial.available()) {
        gps.encode(gpsSerial.read());
    }

    if (gps.location.isUpdated()) {
        float latitude = gps.location.lat();
        float longitude = gps.location.lng();

        if (latitude != 0.0 && longitude != 0.0) {
            detectBreakdown(latitude, longitude);
            detectAccident();
            updateFirestore(latitude, longitude);
        }
    } else {
        Serial.println("⏳ Waiting for GPS signal...");
    }

    delay(3000);
}

// 🔴 Breakdown Detection
void detectBreakdown(float latitude, float longitude) {
    if (latitude == lastLatitude && longitude == lastLongitude) {
        // If stationary for more than 5 minutes, check vibration sensor
        if (millis() - lastMovementTime > 150000) { // 5 min
            if (digitalRead(VIBRATION_SENSOR_PIN) == LOW) {  // LOW = No vibration
                Serial.println("🚨 Bus Breakdown Detected!");
                updateFirestoreStatus("Breakdown Detected!");
            }
        }
    } else {
        lastLatitude = latitude;
        lastLongitude = longitude;
        lastMovementTime = millis();  // Reset timer when bus moves
    }
}

// ⚠ Accident Detection (Using Vibration + Gyroscope)
void detectAccident() {
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);

    bool vibrationState = digitalRead(VIBRATION_SENSOR_PIN); // Reads sensor state

    // Detect strong vibrations by checking continuous HIGH state
    if (vibrationState == HIGH) {
        if (vibrationStartTime == 0) {
            vibrationStartTime = millis(); // Start timing vibration
        } else if (millis() - vibrationStartTime > VIBRATION_THRESHOLD_TIME) {
            strongVibrationDetected = true;
        }
    } else {
        vibrationStartTime = 0;
        strongVibrationDetected = false;
    }

    // Detect strong tilt (indicating impact)
    bool abnormalTilt = abs(a.acceleration.x) > 8 || abs(a.acceleration.y) > 8; 

    if (strongVibrationDetected && abnormalTilt) {
        Serial.println("🚨 Accident Detected!");
        updateFirestoreStatus("Accident Detected!");
    }
}

// 📡 Update Firestore with GPS, Vibration Sensor & Gyroscope Data
void updateFirestore(float latitude, float longitude) {
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);

    FirebaseJson data;

    // ✅ Correct way to store GeoPoint
    data.set("fields/location/geoPointValue/latitude", latitude);
    data.set("fields/location/geoPointValue/longitude", longitude);

    // Store sensor values
    FirebaseJson sensorsMap;
    sensorsMap.set("fields/vibration/booleanValue", digitalRead(VIBRATION_SENSOR_PIN) == HIGH);
    sensorsMap.set("fields/accelerationX/doubleValue", a.acceleration.x);
    sensorsMap.set("fields/accelerationY/doubleValue", a.acceleration.y);
    sensorsMap.set("fields/accelerationZ/doubleValue", a.acceleration.z);

    // Add sensor data to the main structure
    data.set("fields/sensors/mapValue", sensorsMap);

    Serial.print("📡 Updating Firestore... ");
    if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", "bustracking/bus1", data.raw(), "location,sensors")) {
        Serial.println("✅ Firestore Updated!");
    } else {
        Serial.println("❌ Firestore Update Failed!");
        Serial.println("Error: " + fbdo.errorReason());
    }
}

// 🔴 Update Firestore with Status Message (Fix for Compilation Error)
void updateFirestoreStatus(String status) {
    FirebaseJson data;
    data.set("fields/status/stringValue", status);

    Serial.print("📡 Updating Firestore Status... ");
    if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", "bustracking/bus1", data.raw(), "status")) {
        Serial.println("✅ Firestore Status Updated!");
    } else {
        Serial.println("❌ Firestore Status Update Failed!");
        Serial.println("Error: " + fbdo.errorReason());
    }
}