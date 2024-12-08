# Set working directory
setwd("C:\\Users\\jayde\\OneDrive - Imperial College London\\Year 4\\SIoT\\Data Analysis")

# load required libraries
library(forecast)

# read the new csv with linearly interpolated values
mydata <- read.csv("final_data_readings_updated.csv", header = TRUE)

# ensure 'created_at' is in POSIXct format for date-time handling
mydata$created_at <- as.POSIXct(mydata$created_at, format = "%Y-%m-%d %H:%M:%S")

# ensure `humidity` and `temperature` are numeric
mydata$humidity <- as.numeric(mydata$humidity)
mydata$temperature <- as.numeric(mydata$temperature)

# splitting 70% of dataset for training
split_point <- floor(0.7 * nrow(mydata))

# defining training and testing sets
train_data <- mydata[1:split_point, ]   # first 70% for training
test_data <- mydata[(split_point + 1):nrow(mydata), ]   # remaining 30% for testing

# define seasonal frequency (every 5 minutes = 288 observations per day)
seasonal_frequency <- 288
humidity_ts <- ts(train_data$humidity, frequency = seasonal_frequency)

# automatically fit the ARIMAX model using auto.arima
cat("Manually fitting SARIMAX model with optimal parameters...\n")
sarimax_fit <- auto.arima(
  y = humidity_ts,                
  xreg = train_data$temperature, 
  seasonal = TRUE,                
  stepwise = TRUE,                
  approximation = FALSE           
)

# display the model summary
summary(sarimax_fit)


######################### forecast for test set data ###########################
cat("Generating forecasts for the test set...\n")
forecast_results <- forecast(sarimax_fit, xreg = test_data$temperature, h = nrow(test_data))

# create a data frame for visualisation
forecast_df <- data.frame(
  created_at = test_data$created_at,
  Forecast = as.numeric(forecast_results$mean),
  Actual = test_data$humidity
)

# # plot forecast vs raw data
# cat("Plotting forecast vs actual for the test set...\n")
# library(ggplot2)
# ggplot(forecast_df, aes(x = created_at)) +
#   geom_line(aes(y = Actual, color = "Raw Data")) +
#   geom_line(aes(y = Forecast, color = "Forecast")) +
#   labs(title = "Forecast vs Actual Humidity (Test Set)", x = "Time", y = "Humidity") +
#   scale_color_manual(values = c("Actual" = "blue", "Forecast" = "red")) +
#   theme_minimal()


# plot forecast vs raw data
cat("Plotting forecast vs actual for the test set...\n")
ggplot(forecast_df, aes(x = created_at)) +
  geom_line(aes(y = Actual, color = "Raw Data"), size = 1) +   # Changed: added size = 1
  geom_line(aes(y = Forecast, color = "Forecast"), size = 1) +   # Changed: added size = 1
  labs(title = "Humidity Forecast vs. Raw Data (Test Set)", x = "Time", y = "Humidity") +  # Changed: adjusted title
  scale_color_manual(values = c("Raw Data" = "blue", "Forecast" = "red")) +  # Changed: updated color labels
  theme_minimal() +
  theme(   # Changed: added theme customizations
    axis.text.x = element_text(angle = 0, hjust = 1),
    legend.title = element_blank(),
    legend.position = c(0.88, 0.9),
    legend.box.background = element_rect(color = "black", fill = "white", size = 0.5),
    legend.key = element_blank(),
    legend.text = element_text(size = 10),
    legend.margin = margin(t = 2, r = 4, b = 2, l = 4)
  )

# 
# 
# 
# ###################### plot forecast for next 24 hours #########################
# cat("Forecasting humidity for the next 24 hours...\n")
# 
# # extract the last 24-hour cycle of temperature
# past_daily_cycle <- tail(train_data$temperature, seasonal_frequency)  # 288 values (one day)
# 
# # repeat the cycle for the next 24 hours
# future_temperature <- rep(past_daily_cycle, length.out = seasonal_frequency)
# 
# # forecast the next 24 hours of humidity
# future_forecast <- forecast(sarimax_fit, xreg = future_temperature, h = seasonal_frequency)
# 
# # creating time sequence for the next 24 hours for plotting
# future_time <- seq(
#   from = max(mydata$created_at) + 5 * 60,  # start 5 minutes after the last timestamp
#   by = "5 min",                            # increment by 5 minutes
#   length.out = seasonal_frequency          # 288 intervals for 24 hours
# )
# 
# # Create a data frame for the next 24 hours forecast
# future_forecast_df <- data.frame(
#   created_at = future_time,
#   Forecast = as.numeric(future_forecast$mean),
#   Lower80 = as.numeric(future_forecast$lower[, 1]),  # 80% lower bound
#   Upper80 = as.numeric(future_forecast$upper[, 1]),  # 80% upper bound
#   Lower95 = as.numeric(future_forecast$lower[, 2]),  # 95% lower bound
#   Upper95 = as.numeric(future_forecast$upper[, 2])   # 95% upper bound
# )
# 
# # Combine the last raw training data and 24-hour forecast
# combined_df <- rbind(
#   data.frame(
#     created_at = tail(train_data$created_at, seasonal_frequency),  # ast raw training data
#     Humidity = tail(train_data$humidity, seasonal_frequency),
#     Source = "Raw Data"
#   ),
#   data.frame(
#     created_at = future_forecast_df$created_at,                   # next 24-hour forecast
#     Humidity = future_forecast_df$Forecast,
#     Source = "Forecast"
#   )
# )
# 
# ############ plot forecast for next 24 hours with previous data ################
# cat("Plotting next 24-hour forecast with previous raw data...\n")
# 
# ggplot(combined_df, aes(x = created_at, y = Humidity, color = Source)) +
#   geom_line() +
#   labs(
#     title = "Next 24-Hour Humidity Forecast with Previous Raw Data",
#     x = "Time",
#     y = "Humidity"
#   ) +
#   scale_color_manual(values = c("Raw Data" = "blue", "Forecast" = "red")) +
#   theme_minimal()

# evaluating performance
cat("Calculating performance metrics...\n")
actual_humidity <- test_data$humidity
predicted_humidity <- as.numeric(forecast_results$mean)

rmse <- sqrt(mean((actual_humidity - predicted_humidity)^2))
mae <- mean(abs(actual_humidity - predicted_humidity))
mape <- mean(abs((actual_humidity - predicted_humidity) / actual_humidity)) * 100

cat("Test RMSE:", rmse, "\n")
cat("Test MAE:", mae, "\n")
cat("Test MAPE:", mape, "%\n")
