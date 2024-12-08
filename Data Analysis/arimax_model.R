# set working directory
setwd("C:\\Users\\jayde\\OneDrive - Imperial College London\\Year 4\\SIoT\\Data Analysis")

# load required libraries
library(tseries)
library(forecast)
library(ggplot2)
library(httr)

# read the new csv with linearly interpolated values
mydata <- read.csv("final_data_readings_updated.csv", header = TRUE)

# ensure 'created_at' is in POSIXct format for date-time handling
mydata$created_at <- as.POSIXct(mydata$created_at, format = "%Y-%m-%d %H:%M:%S")

# splitting 70% of dataset for training
split_point <- floor(0.7 * nrow(mydata))

# defining training and testing sets
train_data <- mydata[1:split_point, ]  # first 70% for training
test_data <- mydata[(split_point + 1):nrow(mydata), ]  # remaining 30% for testing

# confirm the split
nrow(train_data)  # Number of rows in training set
nrow(test_data)   # Number of rows in testing set

# checks if humidity column is stationary (requirement for ARIMAX)
adf_test <- adf.test(train_data$humidity, alternative = "stationary")
print(paste("ADF Test p-value:", adf_test$p.value)) # display the p-value

# fit the ARIMAX model
fit <- auto.arima(train_data$humidity, xreg = train_data$temperature)

# display the model summary
summary(fit)

# forecast humidity using the testing set
temperature_test <- test_data$temperature  # temperature used as the exogenous variable for testing
forecast_humidity <- forecast(fit, xreg = matrix(temperature_test, ncol = 1), h = nrow(test_data))

# generate timestamps for the next 24 hours at 5-minute intervals - for plotting the forecast
last_timestamp <- max(test_data$created_at, na.rm = TRUE)
next_24_hours <- seq(
  from = last_timestamp + 5 * 60,  # start from the last test set timestamp + 5 minutes
  by = "5 min",                    # increment by 5 minutes
  length.out = 288                 # 288 intervals for 24 hours
)

# use the last 24 hours of temperature data as the exogenous variable
last_24_hours_temperature <- tail(test_data$temperature, 288)

# forecast humidity for the next 24 hours
forecast_next_24 <- forecast(
  fit,
  xreg = matrix(last_24_hours_temperature, ncol = 1),
  h = 288
)

forecast_24_df <- data.frame(
  created_at = next_24_hours,            # timestamps for the next 24 hours
  Forecast = as.numeric(forecast_next_24$mean)  # forecasted humidity values
)

# combine training, testing, and forecasted data for plotting
train_plot_df <- data.frame(
  created_at = train_data$created_at,
  Humidity = train_data$humidity,
  Source = "Raw Data"
)



test_plot_df <- data.frame(
  created_at = test_data$created_at,
  Humidity = test_data$humidity,
  Source = "Raw Data"
)

forecast_plot_df <- data.frame(
  created_at = forecast_24_df$created_at,
  Humidity = forecast_24_df$Forecast,
  Source = "Forecast"
)


# all combined
combined_plot_df <- rbind(train_plot_df, test_plot_df, forecast_plot_df)



# evaluating the forecast with the raw data - test set
cat("Comparing forecasted values with raw data...\n")

# create a data frame for comparison
comparison_df <- data.frame(
  created_at = test_data$created_at,      
  Actual = test_data$humidity,              
  Forecast = as.numeric(forecast_humidity$mean) 
)

# column for the error (difference between actual and forecasted values)
comparison_df$Error <- comparison_df$Actual - comparison_df$Forecast

cat("Calculating performance metrics...\n")
# calculate RMSE, MAE, and MAPE
rmse <- sqrt(mean(comparison_df$Error^2, na.rm = TRUE)) 
mae <- mean(abs(comparison_df$Error), na.rm = TRUE)    
mape <- mean(abs((comparison_df$Error) / comparison_df$Actual), na.rm = TRUE) * 100

# display the metrics
cat("Performance Metrics:\n")
cat("  RMSE:", rmse, "\n")
cat("  MAE:", mae, "\n")
cat("  MAPE:", mape, "%\n")




######### plotting test set forecast (refer to Figure 10 in report) ############
# please note: uncomment for this to run. this code is set to plot the 24 hour forecast graph (scroll down)

# # plot the data
# ggplot() +
#   # plot the raw data first
#   geom_line(data = subset(test_forecast_plot_df, Source == "Raw Data"),
#             aes(x = created_at, y = Humidity, color = Source), size = 1) +
#   # plot the ARIMAX model data on top
#   geom_line(data = subset(test_forecast_plot_df, Source == "ARIMAX Model"),
#             aes(x = created_at, y = Humidity, color = Source), size = 1) +
#   labs(
#     title = "Humidity Forecast vs. Raw Data (Test Set)",
#     x = "Time",
#     y = "Humidity"
#   ) +
#   theme_minimal() +
#   theme(
#     axis.text.x = element_text(angle = 0, hjust = 1),
#     legend.title = element_blank(),  
#     legend.position = c(0.88, 0.9),  
#     legend.box.background = element_rect(color = "black", fill = "white", size = 0.5),  
#     legend.key = element_blank(),  
#     legend.text = element_text(size = 10), 
#     legend.margin = margin(t = 2, r = 4, b = 2, l = 4)
#   ) +
#   
#   scale_color_manual(
#     values = c("Raw Data" = "blue", "ARIMAX Model" = "red"),
#     breaks = c("ARIMAX Model", "Raw Data"),  # Order of items in legend
#     labels = c("ARIMAX Model", "Raw Data")  # Match legend labels to example
#   )




############## plotting 24 hour forecast (Figure 12 in report) #################

ggplot(combined_plot_df, aes(x = created_at, y = Humidity, color = Source)) +
  geom_line(size = 1) +
  scale_color_manual(
    values = c(
      "Raw Data" = "blue",   
      "Forecast" = "green"
    ),
    labels = c("Forecast", "Raw Data")
  ) +
  labs(
    title = "Humidity: Next 24-Hour Forecast",
    x = "Time",
    y = "Humidity (%)",
    color = NULL  # Remove legend title
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = c(0.95, 0.95), 
    legend.justification = c(1, 1), 
    legend.background = element_rect(fill = "white", color = "black", size = 0.5), 
    legend.key.size = unit(0.5, "lines"), 
    legend.text = element_text(size = 8),
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold") 
  )

#################### Testing WhatsApp message automation #######################

# checks if any value in the forecast is below 40% humidity
if (any(forecast_24_df$Forecast < 40)) {
  # sends this message
  warning_message <- "ALERT: Forecasted humidity levels will drop below 40%! Please take action to maintain optimal conditions."
  
  # CallMeBot API details
  phone_number <- "+447856787414"
  api_key <- "5510890"  
  encoded_message <- URLencode(warning_message)
  
  # construct the API URL
  api_url <- paste0(
    "https://api.callmebot.com/whatsapp.php?",
    "phone=", phone_number,
    "&text=", encoded_message,
    "&apikey=", api_key
  )
  
  # making GET request to send the WhatsApp message
  response <- GET(api_url)
  
  # check the response
  if (status_code(response) == 200) {
    cat("WhatsApp alert sent successfully!\n")
    print(content(response, "text"))
  } else {
    cat("Failed to send WhatsApp alert. Status code:", status_code(response), "\n")
    print(content(response, "text"))
  }
} else {
  print("All forecasted values are above the threshold. No WhatsApp alert sent.")
}