# set working directory
setwd("C:\\Users\\jayde\\OneDrive - Imperial College London\\Year 4\\SIoT\\Data Analysis")

# load required libraries
library(lubridate)

# read the new csv with linearly interpolated values
mydata <- read.csv("final_data_readings_updated.csv", header = TRUE)

# convert 'created_at' to datetime format
mydata$created_at <- dmy_hm(mydata$created_at)

# define the frequency of the time series (every 5 minutes = 288 observations per day)
frequency <- 288


###################### plotting seasonal decomposition #########################
# please note you have to comment out the rest of graphs in order to plot one
# e.g: this code would only plot dht22 humidity decomposition

# dht22 humidity
humidity_ts <- ts(mydata$humidity, frequency = frequency)
humidity_decomposed <- decompose(humidity_ts, type = "additive")
plot(humidity_decomposed)


# # temperature
# temperature_ts <- ts(mydata$temperature, frequency = frequency)
# temperature_decomposed <- decompose(temperature_ts, type = "additive")
# plot(temperature_decomposed)

# # api temperature
# apitemp_ts <- ts(mydata$api_temperature, frequency = frequency)
# apitemp_decomposed <- decompose(apitemp_ts, type = "additive")
# plot(apitemp_decomposed)

# # api humidity
# apihumidity_ts <- ts(mydata$api_humidity, frequency = frequency)
# apihumidity_decomposed <- decompose(apihumidity_ts, type = "additive")
# plot(apihumidity_decomposed)

# # api clouds
# apiclouds_ts <- ts(mydata$api_clouds, frequency = frequency)
# apiclouds_decomposed <- decompose(apiclouds_ts, type = "additive")
# plot(apiclouds_decomposed)

# # api wind speed
# apiwindspeed_ts <- ts(mydata$api_windspeed, frequency = frequency)
# apiwindspeed_decomposed <- decompose(apiwindspeed_ts, type = "additive")
# plot(apiwindspeed_decomposed)

