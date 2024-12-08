// including relevant libraries
#include <DHT.h>
#include <WiFi.h>
#include <ThingSpeak.h>
#include <Arduino.h>

// WiFi credentials
const char* ssid = "CommunityFibrexxxx_xxxxx";
const char* password = "xxxxxxxxxx";

// ThingSpeak channel details
#define CHANNEL_ID xxxxxxx
#define CHANNEL_API_KEY "XXXXXXXXXXXXXXXXXX"

// creating a WiFiClient object to establish TCP connection for sending data to ThingSpeak
WiFiClient client;

// DHT sensor settings
#define DHTPIN 26           // GPIO pin connected to DHT22 sensor
#define DHTTYPE DHT22       // define the type of DHT sensor (DHT22)
DHT dht(DHTPIN, DHTTYPE);   // initialise the DHT sensor

// connecting ESP32 to the WiFi network - loops until it successfully connects to WiFi
void connectToWiFi(){
  Serial.print("Connecting to ");
  Serial.print(ssid);
  Serial.print(" with password ");
  Serial.println(password);

  WiFi.begin(ssid, password);                                     
  while (WiFi.status() != WL_CONNECTED) {                             
    delay(500);
    Serial.println("Wifi connecting...");
  }
  Serial.println("Wifi connection established");                     // print when successfully connected
  Serial.print("Connected to WiFi network with IP Address: ");
  Serial.println(WiFi.localIP());

}


void setup() {
  dht.begin();                // initialise DHT22 sensor
  delay(2000);                // wait 2s for DHT22 sensor to stabalise 
  Serial.begin(115200);       // starting serial monitor
  connectToWiFi();            // connects to wifi
  ThingSpeak.begin(client);   // initialises ThingSpeak library
}

void loop() {
  // read temperature and humidity data from DHT22 sensor
  float temp = dht.readTemperature(); // returns value in celcius
  float humidity = dht.readHumidity(); // returns a percentage value

  // set fields in the ThingSpeak channel
  ThingSpeak.setField(1, humidity);
  ThingSpeak.setField(2, temp);

  // sends data to ThingSpeak (writes all set fields in a single HTTP request) - more efficient
  ThingSpeak.writeFields(CHANNEL_ID, CHANNEL_API_KEY);

  // print temp and humidity values for verification
  Serial.print("Temp: ");
  Serial.print(temp);
  Serial.print(" C ");
  Serial.print("Humidity: ");
  Serial.print(humidity);
  Serial.println(" % ");

  // delay for 5 mins before the next loop iteration (5 min sampling rate)
  delay(300000);
}
