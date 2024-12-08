// importing required libraries
#include <WiFiClient.h>
#include <ArduinoJson.h>
#include <WiFi.h>
#include <ThingSpeak.h>
#include <Arduino.h>
#include <HTTPClient.h>

// creating a WiFiClient object to establish TCP connection for sending data to ThingSpeak
WiFiClient client;

// defining WiFi credentials
const char* ssid = "CommunityFibrexxxx_xxxxxx";
const char* password = "xxxxxxxxxx";

// defining the OpenWeather API details
const char* api_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"; 
const char* base_url = "http://api.openweathermap.org/data/2.5/weather?";

// defining ThingSpeak channel details
#define CHANNEL_ID xxxxxxx
#define CHANNEL_API_KEY "xxxxxxxxxxxxxxxx"

// defining latitude and longitudinal values for London
const char* latitude_val = "51.507351";
const char* longitude_val = "-0.127758";
const char* city_name = "London";

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
  Serial.println("Wifi connection established");            
  Serial.print("Connected to WiFi network with IP Address: ");
  Serial.println(WiFi.localIP());

}

// function to convert temperature from kelvin to celsius
float kelvin_to_celcius(float kelvin) {
    return kelvin - 273.15;
}


void setup() {
  Serial.begin(115200);             // starting serial monitor
  connectToWiFi();                  // connects to wifi
  ThingSpeak.begin(client);         // initialises ThingSpeak library
}



void loop() {
    // construct full api url with the previosuly defined location and api key
    String full_url = String(base_url) + "lat=" + latitude_val + "&lon=" + longitude_val + "&appid=" + api_key;
    Serial.println("Full URL: " + full_url);

    // Perform the API call and get the weather data
    HTTPClient http;
    http.begin(full_url);
    int httpResponseCode = http.GET();  // make the GET request

    // checks if request was successful and retrieves response payload in JSON format
    if (httpResponseCode > 0) {
        String payload = http.getString();
        Serial.println("Response payload: " + payload);
        
        // parse JSON data
        DynamicJsonDocument doc(1024);
        DeserializationError error = deserializeJson(doc, payload);
        if (error) {
            Serial.println("Failed to parse JSON");
            return;
        }

        // extracting the weather data from JSON response
        const char* city = doc["name"];
        const char* weather_description = doc["weather"][0]["description"];
        float temp_celcius = kelvin_to_celcius(doc["main"]["temp"]);
        float feels_like_celcius = kelvin_to_celcius(doc["main"]["feels_like"]);
        float min_temp_celcius = kelvin_to_celcius(doc["main"]["temp_min"]);
        float max_temp_celcius = kelvin_to_celcius(doc["main"]["temp_max"]);
        int pressure = doc["main"]["pressure"];
        int humidity = doc["main"]["humidity"];
        float wind_speed = doc["wind"]["speed"];
        int clouds = doc["clouds"]["all"];


        // print the extracted data
        Serial.println("City: " + String(city));
        Serial.println("Description: " + String(weather_description));
        Serial.println("Temperature (C): " + String(temp_celcius));
        Serial.println("Feels Like (C): " + String(feels_like_celcius));
        Serial.println("Minimum Temp (C): " + String(min_temp_celcius));
        Serial.println("Maximum Temp (C): " + String(max_temp_celcius));
        Serial.println("Pressure: " + String(pressure));
        Serial.println("Humidity: " + String(humidity));
        Serial.println("Wind Speed: " + String(wind_speed));
        Serial.println("Cloud Coverage: " + String(clouds));

        // set allocated fields in the ThingSpeak channel so that it is organised
        ThingSpeak.setField(1, temp_celcius);
        ThingSpeak.setField(2, humidity);
        ThingSpeak.setField(3, clouds);
        ThingSpeak.setField(4, wind_speed);
        
        // sends data to ThingSpeak (writes all set fields in a single HTTP request) - more efficient
        ThingSpeak.writeFields(CHANNEL_ID, CHANNEL_API_KEY);

        http.end();
    } else {
        Serial.println("Error on HTTP request: " + String(httpResponseCode));
    }
    http.end();

    // delay for 10 mins before the next loop iteration (10 min sampling rate - OpenWeather API limitation)
    delay(600000);
}

