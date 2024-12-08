# Sensing_IoT_Project
Smart Tortoise Enclosure End-to-End System, by Jayden Tran

# Scripts

#### It is important to note that script files will not run without the API keys and credentials files. These have not been committed to GitHub.

**Data Collection:**

The data collection directory contains all scripts related to the collection of the two data streams: enclosure DHT22 temperature and humidity levels, and outdoor weather OpenWeather API data.

* `dht22_collection.ino` : Script for collecting temperature and humidity data using a DHT22 sensor and uploading it to ThingSpeak (every 5 minutes)
* `api_collection.ino` : Script for fetching and uploading real-time weather data from OpenWeather API to ThingSpeak (every 10 minutes)
  

CSV files containing the raw data extracted from ThingSpeak DHT22 and OpenWeather API readings:
* `final_data_readings.csv` : Raw time series data collected from DHT22 and OpenWeather API



**Data Analysis:**

Please note, that in these codes, multiple functions have been used within the same script. To run each desired section, highlight the desired code and then run - do not run the whole code!

* `checking_time.R` : Script processesing the raw data by inserting missing timestamps, sorting them in chronological order, then interpolating missing values, and generating visualisations with moving averages.
* `additive_decomposition.R` : Script performs seasonal decomposition for trend analysis.
* `pearson_correlation.R` : Script exploring the correlation between the two data streams.
* `arimax_model.R` : Script predicting the next days energy consumption.
* `sarimax_model.R` : Script attempted to improve forecast quuality by incorperating seasonality, however, this did not perform better due to computational limitations (as explainined in the report).

CSV files containing analysed data readings version with updated timestamps and linearly interpolated missing values:
* `final_data_readings_updated.csv` : Updated dataset, with updated missing timestamps and linearly interpolated values.

**Actuation:**
* `actuation_message.R` : Script that sends Whatsapp messages (that will be used in the web app code)
* `web_app_test.R` : Script for a Shiny web app to monitor, analyse, and forecast humidity in the tortoise enclosure using DHT22 and OpenWeather API data, with real-time notifications and visualizsations. Contains reactive polling and automatic WhatsApp messages if forecasted humidity will drop below 40%
 
#### the project was powered by ThingSpeak and ShinyApps.IO


# Video Presentation
https://youtu.be/rGaLT2xJ87k

# Public Web App
https://mishellsworld.shinyapps.io/mishells_world/
